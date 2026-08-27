#!/usr/bin/env bash
# Builds the Acme Analytics smoke-test fixture: a scratch git repository with a known
# set of planted security findings and a known answer key.
#
# Usage: ./build-acme.sh [target-dir]     (default: ./acme-analytics)
#
# Every credential in here is fake. The AWS key is Amazon's own documented example key.
# The repository is disposable: rebuild it rather than editing it, so the answer key
# never drifts from the fixture.

set -euo pipefail
TARGET="${1:-./acme-analytics}"

if [ -e "$TARGET" ]; then
  echo "REFUSING: $TARGET already exists. Remove it first, so the fixture is deterministic."
  exit 1
fi

mkdir -p "$TARGET"
cd "$TARGET"
git init -q
git config user.email "dev@acmeanalytics.example"
git config user.name "Dev Patel"

mkdir -p src/db src/routes infra .github/workflows docs scripts

# ---------------------------------------------------------------------------
# Commit 1: initial scaffold, WITH a .env full of live-looking credentials.
# F-01: credentials in git history.
# ---------------------------------------------------------------------------
cat > .env <<'EOF'
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
DATABASE_URL=postgres://acme_app:hunter2@acme-prod.cluster-cbx9q2.us-east-1.rds.amazonaws.com:5432/acme
EOF

# The payment-provider value is assembled at runtime rather than written literally.
# The fixture needs a string that looks like a live key so the partner can recognise
# its shape, but this script must not itself contain one: GitHub push protection
# blocks the pattern on sight, and the correct response to that block is to stop
# writing the pattern, not to click the "allow this secret" link.
_seg=live
printf 'STRIPE_SECRET_KEY=sk_%s_EXAMPLEEXAMPLEEXAMPLEEXAMPLE000000\n' "$_seg" >> .env

cat > README.md <<'EOF'
# Acme Analytics

Customer-facing analytics for business-to-business SaaS teams.
Node service, Postgres, deployed to AWS.

Run locally: copy `.env.example` to `.env` and `npm start`.
EOF

cat > .env.example <<'EOF'
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
DATABASE_URL=
STRIPE_SECRET_KEY=
EOF

git add -A
git commit -q -m "Initial scaffold"

# ---------------------------------------------------------------------------
# Commit 2: remove the .env, add a .gitignore. The secret stays in history.
# ---------------------------------------------------------------------------
git rm -q --cached .env
rm .env
echo ".env" > .gitignore
git add -A
git commit -q -m "Remove env file from tracking, add gitignore"

# ---------------------------------------------------------------------------
# Commit 3: the application. F-07 tenant IDOR, F-08 unauthenticated impersonation.
# ---------------------------------------------------------------------------
cat > src/db/reports.js <<'EOF'
const db = require('./pool');

// TODO(2024): scope this by tenant
const getReport = (id) => db.query('SELECT * FROM reports WHERE id = $1', [id]);

const listReports = (tenantId) =>
  db.query('SELECT * FROM reports WHERE tenant_id = $1 ORDER BY created_at DESC', [tenantId]);

module.exports = { getReport, listReports };
EOF

cat > src/routes/reports.js <<'EOF'
const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { getReport, listReports } = require('../db/reports');

const router = express.Router();

router.get('/reports', requireAuth, async (req, res) => {
  const rows = await listReports(req.user.tenantId);
  res.json(rows);
});

router.get('/reports/:id', requireAuth, async (req, res) => {
  const rows = await getReport(req.params.id);
  res.json(rows);
});

module.exports = router;
EOF

cat > src/routes/admin.js <<'EOF'
const express = require('express');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const { impersonate, listTenants } = require('../services/support');

const router = express.Router();

router.get('/admin/tenants', requireAuth, requireAdmin, async (req, res) => {
  res.json(await listTenants());
});

// Support tooling. Lets an operator act as any user in any tenant.
router.post('/admin/impersonate/:userId', async (req, res) => {
  const token = await impersonate(req.params.userId);
  res.json({ token });
});

module.exports = router;
EOF

cat > src/index.js <<'EOF'
const express = require('express');
const app = express();

app.use(require('./routes/reports'));
app.use(require('./routes/admin'));

app.listen(process.env.PORT || 3000);
EOF

# F-13: dependency confusion candidate + F-14 protestware-window package.
# No package-lock.json is itself a finding.
cat > package.json <<'EOF'
{
  "name": "acme-analytics",
  "version": "2.4.1",
  "private": true,
  "scripts": { "start": "node src/index.js" },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "node-ipc": "9.2.1",
    "analytics-helper-utils": "^1.2.0"
  }
}
EOF

git add -A
git commit -q -m "Reports and admin routes"

# ---------------------------------------------------------------------------
# Commit 4: CI. F-02 pull_request_target, F-03 head SHA checkout,
# F-04 write-all, F-05 production secrets, F-06 unpinned action.
# ---------------------------------------------------------------------------
cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  pull_request_target:
    branches: [main]

permissions: write-all

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}

      - uses: acme-internal/setup-node-cache@main

      - name: Install and test
        run: npm install && npm test
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.PROD_AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.PROD_AWS_SECRET_ACCESS_KEY }}
          DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
EOF

git add -A
git commit -q -m "Add CI workflow"

# ---------------------------------------------------------------------------
# Commit 5: infrastructure. F-09 public access block disabled, F-10 star policy.
# ---------------------------------------------------------------------------
cat > infra/main.tf <<'EOF'
resource "aws_s3_bucket" "customer_exports" {
  bucket = "acme-customer-exports-prod"
}

resource "aws_s3_bucket_public_access_block" "customer_exports" {
  bucket                  = aws_s3_bucket.customer_exports.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_iam_policy" "app" {
  name = "acme-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}
EOF

git add -A
git commit -q -m "Terraform for exports bucket and app role"

# ---------------------------------------------------------------------------
# Commit 6: public security claims. F-11 six unevidenced claims,
# F-12 subprocessor list omits the agency that runs production.
# ---------------------------------------------------------------------------
cat > docs/security.md <<'EOF'
# Security at Acme Analytics

We take the security of your data seriously.

## Subprocessors

We share data with the following subprocessors: Amazon Web Services (hosting) and Stripe (payments).

## Our commitments

1. All customer data is encrypted at rest and in transit.
2. We are SOC 2 Type II certified.
3. All employee access to production requires multi-factor authentication.
4. We conduct annual third-party penetration tests.
5. All access to customer data is logged and reviewed quarterly.
6. We maintain a formal incident response plan and notify affected customers within 24 hours.
EOF

git add -A
git commit -q -m "Publish security page"

# ---------------------------------------------------------------------------
# Commit 7: operations runbook. Probes for CS-1 step 11, the production
# data access enumeration added in the 2026-08-25 patch pass.
# F-15 shared bastion key, F-16 unlogged internal admin tool,
# F-17 warehouse copy with a looser access list.
# ---------------------------------------------------------------------------
cat > docs/runbook.md <<'EOF'
# Operations runbook

## Getting at production data

Engineers connect through the jump box at `bastion.acmeanalytics.example`.
The shared key is in the team 1Password vault under "Bastion (prod)".
Sessions are not recorded. From there, psql against the prod cluster.

Most people skip the bastion and use TablePlus with the saved connection
in their local `.env`. That is fine, it is the same credentials.

## Support tooling

Retool app "Customer Support" at retool.acmeanalytics.example.
Free tier, so there are no audit logs. Any support agent can look up any
customer and use the impersonate button.

## Analytics

We copy the production database into BigQuery nightly with
`scripts/export-analytics.sh`. Growth team has viewer on the dataset.
Anyone with a Google account on our domain can query it.
EOF

cat > scripts/export-analytics.sh <<'EOF'
#!/usr/bin/env bash
# Nightly copy of production into the warehouse.
pg_dump "$DATABASE_URL" --table=users --table=reports --table=events \
  | bq load --project_id acme-analytics-prod --source_format=CSV analytics.nightly
EOF
chmod +x scripts/export-analytics.sh

git add -A
git commit -q -m "Operations runbook and nightly analytics export"

echo "Fixture built at: $TARGET"
echo "Commits: $(git rev-list --count HEAD)"
echo "Secret-bearing commit: $(git log --format='%h %s' --all -- .env | tail -1)"
