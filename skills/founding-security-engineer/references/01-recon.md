# Recon: Environment Discovery Playbook

> **Load when:** you need to build an accurate technical picture of an unfamiliar company, stack, or cloud estate, at any level of access, including none. Load this after `references/00-cold-start.md` on day one, and re-load it any time you gain a new access grant and need to know what to look at first.

## What this file is for

You are going to be asked "how secure are we?" long before anyone gives you the access to answer that. This playbook lets you produce a real answer from whatever access you have right now, and to say precisely what you cannot see yet.

The organising idea is **tiers of access**. Start at the tier you actually have. Do not stall waiting for credentials. Every tier produces rows in `SECURITY-STATE.md`, and every gap produces a specific, copy-pasteable access request logged in `ACCESS-LOG.md`.

**The single most important rule in this file: anything you have not verified with your own eyes is recorded as `unknown`, never as `none` and never as `done`.** "The Chief Technology Officer said we have multi-factor authentication (MFA) everywhere" is `unknown` with a note. A screenshot of the identity provider showing 41 of 41 users enrolled is `done` with evidence.

### Before you inventory anything: is someone already inside?

This file answers "what do we have, and how is it configured". It does not answer "is there an intruder in here right now". That second question belongs to `references/dr-0-compromise-assessment.md`.

**Which runs first, and why.** The compromise assessment runs first whenever there is any trigger: a reported incident, an alert nobody closed out, a departure that felt wrong, a vendor breach notification naming a product you use, a credential found in a public place, or a human saying some version of "we think something happened last year". The reason is retention, not importance. Inventory does not expire: the cloud account, the repositories, and the identity provider will still be there next month and will describe themselves identically. Evidence does expire. Cloud audit trails, identity provider sign-in logs, code host audit logs, and chat platform logs are commonly retained for thirty or ninety days on the plans a startup buys, and some are shorter. Every day you spend cataloguing assets is a day of the oldest evidence rolling off the end of the window, permanently.

Absent any trigger, run recon first: you cannot investigate an estate you cannot describe. But carry one rule from the compromise assessment into Tier 2 below. The moment you learn that a log source has a short retention window (seven days, thirty days), stop inventorying that platform and run the compromise-assessment queries for it before the window closes. Then come back and finish the inventory.

If recon itself turns up evidence of an active compromise, for example a verified live secret in a public place, an unrecognised administrator account, or an unexplained third-party OAuth (Open Authorization) grant with broad scopes, recon stops. Switch to `references/dr-0-compromise-assessment.md` and then `references/dr-1-incident-response-plan.md`, and push the recon frame onto `CONTEXT-STACK.md` per `references/04-interrupts.md` so you can resume it later.

## Rules of engagement (read before running anything)

These are not optional and they protect the human's job as much as the company.

1. **Read-only by default.** Every command in Tier 0 through Tier 2 is read-only. Anything that writes, deletes, rotates, revokes, or costs money is prefixed with `MUTATES:` in this file and requires an explicit human yes before you run it. See the STOP protocol below.
2. **Only touch assets the company owns.** Passive observation of public records (Domain Name System records, certificate transparency logs, public code repositories, job postings) is fine and legal. Active probing (port scanning, vulnerability scanning, credential stuffing, fuzzing, directory brute forcing) is **not** fine without written authorisation, even against your own employer's systems, and even on your first day.
3. **Get authorisation in writing before any active testing.** The bar is an email or ticket from someone with authority (Chief Technology Officer, VP Engineering, or General Counsel) naming the in-scope hosts, the time window, and the techniques allowed. Store the authorisation reference in `DECISION-LOG.md`. If you do not have it, you do recon, not testing.
4. **Never touch third-party systems.** Your Software as a Service (SaaS) vendors, your cloud provider's shared infrastructure, and your customers' systems are out of scope no matter how curious you are. Scanning a vendor is a contract violation and sometimes a crime.
5. **Assume everything you run is logged and attributed to the human.** Behave accordingly. If a command would look alarming in an audit log six months from now, write a one-line note in `DECISION-LOG.md` first explaining why you ran it.
6. **Do not exfiltrate.** When you find a secret, a customer data export, or a credential dump, do not copy it into chat, into a state file, or into a ticket. Record the location and the class of data, never the value. `SECURITY-STATE.md` should say "AWS access key ID committed in `infra/deploy.sh` line 14, prefix AKIA…, still valid per last-used date", not the key.

### STOP protocol for mutating actions

Before any command marked `MUTATES:` you must print this block and wait for a human yes:

```
STOP. This changes live state.
Command: <the exact command>
What it does: <one sentence>
Blast radius: <who or what breaks if this goes wrong>
Reversible: <yes, and how / no>
Proceed? yes or no.
```

Log the answer in `DECISION-LOG.md` with the date and the name of the person who approved.

---

## Tier 0: zero access, local only

You are sitting in a directory. Maybe it has code, maybe it does not. This tier costs nothing, alerts nobody, and routinely finds the worst problem in the company.

### 0.1 Establish where you are

```bash
pwd
ls -la
git rev-parse --is-inside-work-tree 2>/dev/null && echo "in a git repo" || echo "not a git repo"
```

If this is not a repository and the directory is empty, you are in the "no code" case. Skip to Tier 1 and set the state directory to `~/security-program/<org-slug>/`, then come back here when you get a repository checkout.

### 0.2 Repository shape and remotes

The remote tells you which code host you are dealing with, which drives half the later playbook.

```bash
git remote -v
git log --oneline -15
git log -1 --format='%ci'          # how fresh is this checkout
git branch -a | head -50
git shortlog -sne --all | head -30 # who actually writes the code
```

**Good result:** a single remote on a known host, recent commits, a small identifiable set of committers.
**Bad result:** remotes pointing at a personal account rather than an organisation, commits from personal email addresses (indicates people committing from unmanaged machines), or a `git log` that stops two years ago (dead code still deployed is a classic).

If the remote belongs to a personal account, a development agency, or a contractor rather than a company-controlled organisation, that is not a style problem, it is an ownership problem, and it changes what you are able to fix at all. Do not try to move it yourself. Record it and read `references/09-outsourced-engineering.md`, then work the full ownership checklist in section 1.9 below.

Record the code host in `SECURITY-STATE.md` under `## Environment facts`. Branch the rest of the playbook on it: GitHub, GitLab, Bitbucket, self-hosted, or unknown.

### 0.3 Language, framework, and dependency manifests

```bash
# Find every manifest and lockfile in one pass
find . -maxdepth 4 \( -name node_modules -o -name .git -o -name vendor -o -name dist \) -prune -o \
  -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name 'pnpm-lock.yaml' \
  -o -name 'yarn.lock' -o -name 'requirements*.txt' -o -name 'Pipfile.lock' -o -name 'poetry.lock' \
  -o -name 'uv.lock' -o -name 'go.mod' -o -name 'go.sum' -o -name 'Gemfile.lock' \
  -o -name 'Cargo.lock' -o -name 'composer.lock' -o -name 'pom.xml' -o -name 'build.gradle*' \
  -o -name '*.csproj' -o -name 'mix.lock' \) -print
```

Then, per ecosystem, count the real dependency surface:

```bash
# Node: direct vs total
[ -f package.json ] && jq -r '.dependencies // {} | keys[]' package.json | wc -l
[ -f package-lock.json ] && jq -r '.packages | keys | length' package-lock.json
# Node: which packages are allowed to run install scripts today
[ -f package.json ] && jq -r '.scripts // {} | to_entries[] | "\(.key): \(.value)"' package.json
# Python
[ -f requirements.txt ] && wc -l requirements.txt
# Go: total hash lines in the lockfile, then direct and indirect requires separately
[ -f go.sum ] && grep -c '' go.sum
[ -f go.mod ] && grep -c '// indirect' go.mod
[ -f go.mod ] && awk '/^\t/ && !/\/\/ indirect/' go.mod | wc -l
```

A note on the Go numbers, because they are easy to misread. Every line of `go.sum` is `module version hash`, and there are normally two lines per module (one for the module archive, one for its `go.mod`), so `grep -c ''` overcounts modules by roughly a factor of two. It is still the right number to write down as "hash lines in the lockfile". The two `go.mod` counts are the ones that describe intent: indirect requires are pulled in by your dependencies, direct requires are what your engineers chose.

**What you are looking for and why it matters:** in 2026 the majority of a startup's attack surface is code nobody at the company wrote. A lockfile with 1,400 transitive packages and no install-script controls means a single malicious `postinstall` reaches a developer laptop or a build runner at install time, before any scanner sees it. Note the total transitive count in `SECURITY-STATE.md` row `M-1` (see `references/07-modern-cells.md`).

**Good result:** lockfiles committed for every manifest, a private registry configured in `.npmrc` / `pip.conf` / `.netrc`, few or no install scripts.
**Bad result:** manifests with no lockfile (non-reproducible builds), lockfiles pointing at `http://` registries, or a `.npmrc` with a plaintext auth token in the repository.

### 0.4 Container and build definitions

```bash
find . -maxdepth 4 -type f \( -name 'Dockerfile*' -o -name '*.dockerfile' \
  -o -name 'docker-compose*.y*ml' -o -name 'compose.y*ml' \) -print
grep -rn --include='Dockerfile*' -E '^(FROM|USER|COPY|ADD|RUN curl|RUN wget)' . | head -40
```

**Good result:** pinned base image digests (`FROM node@sha256:...`), a non-root `USER` directive, no `curl | sh` in a `RUN` line.
**Bad result:** `FROM ubuntu:latest`, no `USER` (so the container runs as root), secrets passed as `ARG` (they persist in image layers), or `ADD` fetching a remote URL over plain HTTP.

### 0.5 Continuous integration and deployment workflow definitions

This is the highest-yield ten minutes in Tier 0. Continuous Integration and Continuous Deployment (CI/CD) is usually the most privileged identity at a startup and nobody has ever read its configuration.

```bash
# Locate pipeline definitions across all common hosts
ls -la .github/workflows/ 2>/dev/null
ls -la .gitlab-ci.yml .circleci/ .buildkite/ .drone.yml Jenkinsfile azure-pipelines.yml 2>/dev/null
find . -maxdepth 3 -path ./node_modules -prune -o -type f \
  \( -name '*.yml' -o -name '*.yaml' \) -print | grep -Ei 'workflow|pipeline|ci|cd' | head -30
```

Then read them for the four things that matter:

```bash
# 1. Third-party actions pinned to a mutable tag rather than a full commit hash
grep -rnE 'uses:\s+[^ ]+@(v?[0-9]|main|master)' .github/workflows/ 2>/dev/null

# 2. The dangerous trigger that runs on untrusted forks with secrets available
grep -rn 'pull_request_target\|workflow_run' .github/workflows/ 2>/dev/null

# 3. Long-lived cloud credentials in CI rather than short-lived federated identity
grep -rniE 'AWS_ACCESS_KEY_ID|AWS_SECRET|GOOGLE_CREDENTIALS|AZURE_CLIENT_SECRET|NPM_TOKEN|DOCKER_PASSWORD' \
  .github/workflows/ .gitlab-ci.yml .circleci/ 2>/dev/null

# 4. Whether OpenID Connect federation is in use (the good pattern)
grep -rn 'id-token:\|permissions:' .github/workflows/ 2>/dev/null
grep -rn 'id_tokens:\|CI_JOB_JWT' .gitlab-ci.yml 2>/dev/null
```

**Why this matters, in plain terms:** a workflow tag like `@v4` is a pointer the action's author can move at any time. In March 2025 the `tj-actions/changed-files` action, used by more than twenty thousand repositories, had its tag repointed to a payload that dumped runner memory (including secrets) into public build logs. Pinning to a full forty-character commit hash removes that entire class of attack.

**Good result:** every third-party action pinned to a full commit hash, no `pull_request_target`, no static cloud keys, `permissions:` set explicitly and narrowly, `id-token: write` present indicating OpenID Connect federation.
**Bad result:** any of the four greps returning hits. Each hit is a row in `RISK-REGISTER.md`.

### 0.6 Infrastructure as code

```bash
find . -maxdepth 4 -type f \( -name '*.tf' -o -name '*.tfvars' -o -name 'cdk.json' \
  -o -name 'serverless.y*ml' -o -name 'template.y*ml' -o -name 'Pulumi.y*ml' \
  -o -name 'kustomization.y*ml' -o -name 'Chart.yaml' \) | head -40

# Which cloud, and which services
grep -rhoE 'provider\s+"(aws|google|azurerm|cloudflare|kubernetes)"' --include='*.tf' . | sort | uniq -c
grep -rhoE 'resource\s+"[a-z_]+' --include='*.tf' . | sort | uniq -c | sort -rn | head -30

# Terraform state location: is it remote and encrypted, or on someone's laptop
grep -rn -A6 'backend\s*"' --include='*.tf' . | head -40

# Classic misconfigurations, textual pass only
grep -rnE '0\.0\.0\.0/0|::/0' --include='*.tf' . | head -20
grep -rniE 'publicly_accessible\s*=\s*true|acl\s*=\s*"public|allUsers|allAuthenticatedUsers' --include='*.tf' . | head -20
grep -rniE 'encrypted\s*=\s*false|skip_final_snapshot\s*=\s*true' --include='*.tf' . | head -20
```

**Good result:** remote state in an encrypted bucket with locking, no `0.0.0.0/0` on anything except a load balancer on ports 80 and 443, encryption enabled explicitly.
**Bad result:** `terraform.tfstate` committed to the repository (it contains secrets in plaintext, this is a same-day finding), security groups open to the world on database ports, storage with public access control lists.

```bash
# MUTATES NOTHING but is worth checking: is state committed?
git log --all --name-only --pretty=format: | grep -E 'tfstate|\.tfstate\.backup' | sort -u
```

### 0.7 Environment example files and configuration

```bash
find . -maxdepth 4 -type f \( -name '.env*' -o -name '*.env' -o -name 'config*.y*ml' \
  -o -name 'appsettings*.json' -o -name '*.properties' \) -not -path '*/node_modules/*' | head -40

# Real .env files should never exist in a repo. Check whether they are ignored.
cat .gitignore 2>/dev/null | grep -nE '\.env|secret|credential|\.pem|\.key'
git check-ignore -v .env 2>/dev/null || echo ".env is NOT ignored"
```

The `.env.example` file is a gift: it is a list of every secret the application expects, which is your secret inventory for free. Every variable name that ends in `_KEY`, `_SECRET`, `_TOKEN`, `_PASSWORD`, or `_DSN` is one row in the secrets inventory that `references/se-3-secrets-and-keys.md` will ask for.

### 0.8 Vendor stack fingerprinting from the code

You do not need to ask which vendors the company uses. The code will tell you, and the answer drives which branch of every later section applies.

```bash
grep -rhoiE '(stripe|twilio|sendgrid|mailgun|postmark|resend|segment|amplitude|mixpanel|datadog|sentry|newrelic|honeycomb|snowflake|databricks|auth0|okta|clerk|workos|firebase|supabase|planetscale|mongodb|redis|elasticsearch|cloudflare|fastly|akamai|salesforce|hubspot|zendesk|intercom|slack|pagerduty|opsgenie|openai|anthropic|bedrock|vertexai|pinecone|weaviate|langchain|llamaindex)' \
  --include='*.json' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' \
  --include='*.rb' --include='*.tf' --include='*.yaml' --include='*.yml' . 2>/dev/null \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -40

# Hardcoded endpoints reveal internal architecture and forgotten environments
grep -rhoE 'https?://[a-zA-Z0-9._-]+\.[a-z]{2,}[a-zA-Z0-9/._-]*' \
  --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.tf' . 2>/dev/null \
  | sed -E 's|(https?://[^/]+).*|\1|' | sort | uniq -c | sort -rn | head -40
```

Each vendor found is a potential OAuth grant, a potential data processor for your privacy record, and a questionnaire answer. Write the list to `SECURITY-STATE.md` under `## Vendor and grant register`, setting `How discovered` to `code` on each row, and mark the register as partial, because code only shows engineering vendors, not the ones sales and finance bought on a credit card.

If you see `openai`, `anthropic`, `bedrock`, `vertexai`, or any agent framework, jump to the AI section of `references/07-modern-cells.md` after recon: you need to know whether the deployed agent has private data access, untrusted input, and an outbound channel at the same time.

### 0.9 Committed secrets

Two passes: a fast textual pass you can always run, and a proper tool pass.

```bash
# Fast pass over current working tree only
grep -rnE '(AKIA|ASIA)[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|ghp_[0-9A-Za-z]{36}|github_pat_[0-9A-Za-z_]{22,}|glpat-[0-9A-Za-z_-]{20}|xox[baprs]-[0-9A-Za-z-]{10,}|sk-(proj|svcacct|admin)?-?[A-Za-z0-9_-]{20,}|sk-ant-api03-[A-Za-z0-9_-]{50,}|xai-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -40
```

A note on the model-provider patterns, because they changed and most copied-around regexes did not. The old `sk-` followed by a run of letters and digits no longer matches the keys a 2026 startup actually holds: OpenAI now issues `sk-proj-...` and `sk-svcacct-...`, which contain hyphens and underscores, Anthropic issues `sk-ant-api03-...`, and xAI issues `xai-...`. The pattern above covers all of them, at the cost of some false positives on any string beginning `sk-`. Accept the noise. Model-provider keys are frequently the most expensive credential in the repository, because they are billed by usage and a stolen one is monetised by strangers within hours. If the vendor fingerprinting in section 0.8 turned up a provider not listed here, add its documented key prefix to the pattern rather than guessing at one.

The working tree is the easy case. Secrets live in history, and deleting a file does not remove it. Use a real scanner for that:

```bash
# gitleaks: fast, no server, scans full history. brew install gitleaks
gitleaks detect --source . --redact --no-banner
# trufflehog: slower, but it VERIFIES whether a found credential is still live
trufflehog git file://. --only-verified --no-update
```

**Tool notes, without overclaiming:**
- `gitleaks` is a regex and entropy scanner over git history. It is fast and has a low setup cost. It produces false positives on test fixtures and does not tell you whether a key still works.
- `trufflehog` overlaps heavily but its differentiator is verification: for supported providers it calls the provider's API to check whether the credential is still valid. `--only-verified` output is the list you escalate today.
- Neither tool covers secrets that were never in git: those live in the CI/CD secret store, the identity provider, and people's shell history.

**Good result:** zero verified live secrets, and a pre-commit or server-side secret scanning control already in place.
**Bad result:** any verified live secret. That is not a recon finding, that is an incident. Stop recon, open `RISK-REGISTER.md`, and follow the rotation path in `references/se-3-secrets-and-keys.md`. Rotation is `MUTATES:` and needs the owning engineer in the loop.

### 0.10 What the code says about data classes

You cannot write a data inventory (grid cell CO-4) without knowing what personal data the product touches. The schema tells you.

```bash
# Database schema and model definitions
find . -maxdepth 4 -type f \( -name '*.prisma' -o -name 'schema.rb' -o -name 'models.py' \
  -o -name '*.sql' -o -path '*migrations*' -name '*.py' \) -not -path '*/node_modules/*' | head -30

# Column and field names that signal regulated data classes
grep -rhoiE '\b(email|phone|ssn|social_security|tax_id|date_of_birth|dob|passport|drivers_license|address|zip_?code|postal|ip_address|credit_card|card_number|cvv|iban|routing_number|password_hash|mfa_secret|api_key|health|diagnosis|patient|medical|salary|compensation)\b' \
  --include='*.prisma' --include='*.sql' --include='*.rb' --include='*.py' --include='*.ts' . 2>/dev/null \
  | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -30
```

Map hits to classes: personal data (any of the identity fields, triggers the European Union General Data Protection Regulation and the California Consumer Privacy Act), payment data (card fields, triggers Payment Card Industry Data Security Standard scope, though using a hosted checkout usually removes most of it), health data (triggers the United States Health Insurance Portability and Accountability Act if you serve covered entities), and authentication material.

Record the classes in `SECURITY-STATE.md` row `CO-4` with status `partial` and the note "derived from schema, not confirmed with engineering".

### 0.11 Object-level authorization and the tenancy model

The likeliest route to a customer data breach in a multi-tenant product is a broken authorization check, not a misconfigured bucket, and it is invisible to every scanner. It is also free to look for. `references/se-2-understand-the-tech-stack.md` owns the full treatment; this is the day-one pass.

Three questions, answerable from the code alone:

1. **Where does the tenant identifier enter a request?** A subdomain, a claim inside the session token, a header, or a path segment. Grep the routing layer and the authentication middleware.
2. **Does the data layer scope by it centrally, or does every query have to remember?** A global query filter, row level security in the database, or a repository base class means one place to get right. Per-query scoping means every single query is a chance to get it wrong. This is the single most important architectural answer you will get all week.
3. **Which paths bypass it?** Look for single-record reads fetching by primary key with no tenant predicate, and for route handlers whose middleware list differs from their neighbours.

```bash
# Single-record reads with no tenant predicate. Tune the table names to the stack.
grep -rniE "where +id *= *[\$:?]|findById|findOne\(|get\(id|\.find\(pk" --include='*.{js,ts,py,rb,go,java,cs,php}' . | head -40

# Queries that DO scope, for contrast. If this set is much smaller than the set above, that is the finding.
grep -rniE "tenant_id|org_id|account_id|workspace_id|company_id" --include='*.{js,ts,py,rb,go,java,cs,php}' . | head -40

# Route handlers whose middleware differs from their neighbours. Read the output, do not count it.
grep -rnE "(app|router)\.(get|post|put|patch|delete)\(" --include='*.{js,ts}' . | head -60
```

Read the third output with your eyes. An endpoint missing the authentication middleware its siblings all have is not a subtle bug, and it is the kind of thing a scanner will never tell you about. Anything under `/admin`, `/internal`, `/impersonate`, `/export`, or `/debug` gets read twice.

A `TODO` admitting the gap counts as confirmed, not suspected. Someone already knew.

Record what you find as a risk, not as a fix. **Do not test it.** Proving a cross-tenant read requires two tenants and written authorisation on a non-production environment, and that procedure lives in `references/se-1-sdlc-and-design-reviews.md`. Reading the code is free. Exercising the bug is not.

### Tier 0 exit criteria

Add this one, because it is the one people skip: **you can state the tenancy model in four lines and name which code paths bypass it, or that row is recorded as `unknown`.** Not blank. Not assumed fine.

You can name: the code host, the cloud provider, the primary language, the CI/CD system, the top ten third-party vendors, whether secrets are in history, and which regulated data classes exist. If you cannot name one of those, it is a row with status `unknown` and a specific question in `references/02-intake-questions.md`.

---

## Tier 1: public only, no credentials

This is what an attacker sees on day zero. It is entirely passive, entirely legal, and it frequently finds a forgotten staging environment with no authentication.

### 1.1 The ethical line, stated once and enforced

Everything in this tier reads **public records that third parties publish**: DNS, certificate transparency logs, package registries, code hosts, job boards. You are not sending traffic to company systems beyond ordinary web requests a customer would make.

Do **not**, in this tier or any other, without written authorisation: run a port scanner, run a web vulnerability scanner, attempt login with any credential, fuzz an Application Programming Interface (API), enumerate object identifiers, or test any host you cannot prove the company owns. Subdomain enumeration frequently surfaces hosts owned by a vendor or a former employee: confirm ownership before you so much as curl it.

### 1.2 Domain and DNS

```bash
# Start from the domains you know. Ask the human for the full list of owned domains.
D=example.com

dig +short A "$D"; dig +short AAAA "$D"
dig +short NS "$D"
dig +short MX "$D"
dig +short TXT "$D"
dig +short CNAME "www.$D"

# Email authentication posture, three separate records
dig +short TXT "$D" | grep -i 'v=spf1'
dig +short TXT "_dmarc.$D"
dig +short TXT "default._domainkey.$D"    # selector varies by provider; also try google, selector1, s1, k1
```

**Why:** Sender Policy Framework (SPF), DomainKeys Identified Mail (DKIM), and Domain-based Message Authentication, Reporting and Conformance (DMARC) are the three records that stop anyone on the internet sending mail as your CEO. A missing DMARC policy is the cheapest high-impact finding you will ever make, and fixing it costs one DNS record.

**Good result:** SPF ending in `-all`, DKIM present, DMARC at `p=reject` or at minimum `p=quarantine` with a reporting address.
**Bad result:** no DMARC record at all, or `p=none` with no `rua=` (meaning nobody is even collecting the reports). Record as `CS-4` and `DR-2` in `SECURITY-STATE.md`.

The MX record also tells you the email and identity platform: `google.com` or `googlemail.com` means Google Workspace, `outlook.com` or `protection.outlook.com` means Microsoft 365, anything else means ask.

### 1.3 Certificate transparency for subdomain discovery

Every publicly trusted Transport Layer Security (TLS) certificate is logged in public append-only logs. This is the highest-signal, zero-touch way to find infrastructure the company forgot about.

Fetch the log once and cache it. Certificate transparency search is rate-limited, and an organisation with a long wildcard history can return thousands of names, so never re-fetch it inside a loop.

```bash
curl -s "https://crt.sh/?q=%25.${D}&output=json" \
  | jq -r '.[].name_value' \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/^\*\.//' \
  | sort -u > /tmp/subs.txt
wc -l /tmp/subs.txt
head -100 /tmp/subs.txt
```

Then, and only then, resolve them passively to see which are live. Bound the loop before it runs, not after: each iteration is a Domain Name System query, and an unbounded loop over a large certificate history is thousands of lookups against your resolver.

```bash
head -80 /tmp/subs.txt | while read -r h; do
  ip=$(dig +short "$h" | tail -1); [ -n "$ip" ] && echo "$h -> $ip"
done
```

If `/tmp/subs.txt` has more names than the bound, work it in batches (`sed -n '81,160p' /tmp/subs.txt`) rather than removing the limit.

**Good result:** a small set of hosts you can each name and attribute to a team.
**Bad result:** hostnames like `staging.`, `dev.`, `old-admin.`, `jenkins.`, `grafana.`, `test-` that resolve to a live address. Each one is a `RISK-REGISTER.md` row with the question "is this authenticated, and who owns it?" Do not probe it yourself: ask the owning engineer to tell you, or get authorisation first.

Also look for **dangling CNAME records**, where a hostname points at a vendor domain that no longer exists. That is subdomain takeover, and it is exploitable by anyone who registers the vendor resource. Detect it by resolving a CNAME to a vendor domain that returns `NXDOMAIN` or a "no such app" page.

### 1.4 Public code host presence

**If GitHub:**
```bash
ORG="<org-slug>"
gh api "orgs/$ORG" --jq '{login,public_repos,created_at,two_factor_requirement_enabled}'
gh repo list "$ORG" --visibility public --limit 200 --json name,updatedAt,description
gh api "orgs/$ORG/members" --paginate --jq '.[].login' | wc -l   # only visible if you are a member
# Public members are visible to anyone
curl -s "https://api.github.com/orgs/$ORG/public_members" | jq -r '.[].login'
```

**If GitLab:**
```bash
GROUP="<group-path>"
curl -s "https://gitlab.com/api/v4/groups/$GROUP" | jq '{name,visibility,id}'
curl -s "https://gitlab.com/api/v4/groups/$GROUP/projects?visibility=public&per_page=100" \
  | jq -r '.[] | "\(.path_with_namespace)  \(.last_activity_at)"'
```

**If you do not know the code host:** search the package registries and the job postings below, they will tell you.

**Good result:** a small number of intentional public repositories, `two_factor_requirement_enabled: true`.
**Bad result:** a public repository that was clearly meant to be private (internal tooling, infrastructure code, a `docs` repo with architecture diagrams). Also bad: many employees with public organisation membership, which hands an attacker a ready-made phishing target list.

### 1.5 Package registry namespaces

If the company publishes packages, that namespace is a supply chain liability pointing outward at your customers.

```bash
# npm scope and per-package maintainers
npm view "@<scope>/<package>" maintainers versions dist-tags 2>/dev/null
curl -s "https://registry.npmjs.org/-/org/<org>/package" | jq .   # requires the org to be public
# PyPI
curl -s "https://pypi.org/pypi/<package>/json" | jq '{name:.info.name, author:.info.author, version:.info.version}'
# crates.io, Go modules, RubyGems have equivalent public JSON endpoints
```

**What to check:** how many maintainer accounts exist, whether they have two-factor authentication (npm shows this on the profile page, not the API), whether publishing happens from CI with trusted publishing / provenance or from a laptop with a long-lived token.

**Good result:** publishing only from CI with provenance attestation, few maintainers, all with hardware-backed two-factor authentication.
**Bad result:** a personal account with a classic token can publish. That means one phished engineer poisons every downstream customer, and you own an outbound supply chain incident. This is the exact mechanism the self-replicating npm worm campaigns of 2025 and 2026 used to spread from victim to victim.

Also check for **namespace squatting risk**: names similar to yours already registered by someone else.

### 1.6 Job postings, status pages, and trust pages

Job postings are a free, accurate, current inventory of the stack, and attackers read them first.

- Search the company careers page and the major job boards for engineering, security, and information technology roles. Extract every named technology, cloud, and tool. Compare against what you found in Tier 0. Differences mean either a second stack you have not seen or an aspirational posting.
- Check for a status page (`status.<domain>`, or a hosted status vendor). It reveals architecture, dependencies, and incident history. Read the last twelve months of incidents: those are your real failure modes.
- Check for a trust or security page (`<domain>/security`, `<domain>/trust`, `trust.<domain>`, `<domain>/.well-known/security.txt`). Its presence or absence is grid cell CO-1.

```bash
curl -sI "https://$D/.well-known/security.txt"
curl -s "https://$D/.well-known/security.txt"
curl -sI "https://$D" | grep -iE 'strict-transport|content-security-policy|x-frame-options|x-content-type|server|x-powered-by'
```

**Good result:** a `security.txt` with a working contact, security headers present, no `Server` or `X-Powered-By` header leaking exact versions.
**Bad result:** no security contact anywhere (researchers will email the CEO or tweet), missing Strict-Transport-Security, verbose version banners.

### 1.7 Credential exposure for company domains

Employees reuse passwords, and infostealer malware harvests browser session cookies wholesale. Checking for known exposure is passive and free.

- Have I Been Pwned domain search: requires proving domain ownership via a DNS record or a well-known file, and a subscription for the domain-wide API. Free for a single address. This is the most reliable public source.
- Google Workspace and Microsoft 365 both surface leaked-credential signals natively in their admin consoles if you have the right licence tier. Check there once you reach Tier 2.
- Do **not** buy, download, or search underground credential dumps. That creates legal exposure for the company and puts stolen data on a company laptop. If a vendor offers this, route it through legal.

Record as `CS-1` evidence. If exposure is confirmed for a real employee address, that is a forced password reset plus a session revocation, both `MUTATES:` and both requiring the identity administrator.

### 1.8 Free tooling worth running at Tier 1

Honest scope statements, so you do not oversell them:

| Tool | What it actually does | What it does not do |
| --- | --- | --- |
| `dig`, `whois` | Authoritative DNS and registration facts | Nothing about the application |
| `crt.sh` (web or JavaScript Object Notation output) | Certificate transparency subdomain discovery | Does not find hosts that never had a public certificate |
| `subfinder`, `amass` (passive mode only) | Aggregate many passive sources for subdomains | Their active modes send traffic. Use `-passive` and nothing else without authorisation |
| `gitleaks`, `trufflehog` | Secrets in git history, verification for supported providers | Not secrets outside git |
| `testssl.sh` | TLS configuration and cipher assessment of a host | This sends traffic to the host. Only run against hosts you have written authorisation for, even though it is not an exploit |

Anything that performs port scanning, directory brute forcing, or vulnerability probing belongs in an authorised test, not in recon.

### 1.9 Ownership verification: whose name is actually on the asset

Every control in this playbook assumes the company can administer its own assets. That assumption is wrong more often than anyone expects at a startup, especially where the first version of the product was built by an agency, a contractor, or a technical co-founder who has since moved on. A domain registered on a founder's personal account, a cloud account whose root identity is an agency's shared mailbox, or an app store listing owned by a former contractor are all cases where the correct security control exists on paper and cannot be applied in practice, and where the real risk is not misconfiguration but loss of the asset.

Answer these six, name by name, and write each answer into `SECURITY-STATE.md` under `## Environment facts`. All of the checks below are read-only.

1. **Domain registrar.** Who is the registrant of record, which registrar holds the domain, who can log in, when does it expire, and is the transfer lock on?
   ```bash
   whois "$D" | grep -iE 'registrar|registrant|admin email|expiry|expiration|status'
   ```
   Registrant details are usually redacted by privacy services, so treat `whois` as a starting point and confirm with the person who pays the renewal invoice. Finance can answer this faster than engineering can.
2. **Authoritative Domain Name System zone.** The nameservers tell you which account controls the records. Whoever holds that login can redirect your mail and issue certificates in your name.
   ```bash
   dig +short NS "$D"
   ```
3. **Cloud root identity.** The account that cannot be locked out and cannot be limited by any policy.
   - Amazon Web Services: `aws organizations describe-organization --query 'Organization.MasterAccountEmail' --output text`, then ask who receives mail at that address and who holds its multi-factor device.
   - Google Cloud Platform: `gcloud organizations get-iam-policy <org-id> --flatten='bindings[].members' --filter='bindings.role=roles/resourcemanager.organizationAdmin' --format='value(bindings.members)'`
   - Microsoft Azure: console path, Entra admin centre, then Roles and administrators, then Global Administrator, then Assignments.
   - If you have no cloud access yet, this is a question for the person who pays the cloud bill, not a command.
4. **Code host organisation.** Who are the owners, and is the organisation itself owned by the company or by an individual?
   - GitHub: `gh api "orgs/$ORG/members?role=admin" --paginate --jq '.[].login'` plus the billing email in Organisation settings, then Billing.
   - GitLab: `glab api "groups/$GROUP/members/all" | jq -r '.[] | select(.access_level==50) | .username'` for group owners.
5. **App store accounts.** For a mobile product these are single points of failure and they cannot be recovered by argument. Apple: App Store Connect, then Users and Access, and separately the Apple Developer Program Account Holder, which is one named person and is the account that matters. Google: Play Console, then Users and permissions, and the account marked Owner. Confirm the membership is an organisation enrolment rather than an individual one.
6. **Package namespace.** If the company publishes, who can publish?
   ```bash
   npm owner ls <package>
   npm view <package> maintainers
   curl -s "https://pypi.org/pypi/<package>/json" | jq -r '.info.author, .info.maintainer'
   ```

**Good result:** every one of the six sits on a company-controlled identity with at least two administrators, and you can name both of them.
**Bad result, and it is common:** one or more sits on an agency account, a contractor's personal account, a departed founder's personal address, or a shared mailbox nobody monitors. That is a `RISK-REGISTER.md` row in its own right, phrased as a business failure scenario rather than a technical one ("if the agency stops answering email, we cannot renew the domain and the product goes dark"). The recovery path, including how to ask for a transfer without souring the relationship and what to do when the holder is unresponsive, is in `references/09-outsourced-engineering.md`.

Do not attempt a transfer, a role change, or an account recovery yourself. Every one of those is mutating, several are irreversible, and a botched registrar transfer takes the company offline. They require an explicit human yes and the current holder in the loop, per the STOP protocol above.

### Tier 1 exit criteria

You can hand the human a one-page "here is what the internet knows about us" summary: domains, subdomains and which look forgotten, email authentication posture, public repositories, published packages, security contact presence, whether known credential exposure exists, and, for each of the six assets in section 1.9, the named party who actually controls it or an explicit `unknown`.

---

## Tier 2: read-only credentials

Now you can answer questions instead of inferring. Request access in this order, because this is the order of risk-reduction per hour: cloud read-only, identity provider read-only, code host owner-or-read, then the top three SaaS admin consoles.

Every grant goes into `ACCESS-LOG.md` with the date requested, who granted it, the exact role name, and the scope. Copy-pasteable request text lives in `references/02-intake-questions.md`.

### 2.1 Cloud: account and organisation inventory

**Why first:** the cloud is where a single misconfiguration becomes a customer notification with no attacker skill required.

This section is the home of general cloud enumeration for the whole skill. Other reference files carry only the few commands specific to their own question and point back here, so if you are reading a cell file and want the full inventory sweep, it is this section, not that one.

**If Amazon Web Services** (ask for the `SecurityAudit` managed policy plus `ViewOnlyAccess`, via single sign-on, not an access key):
```bash
aws sts get-caller-identity
aws organizations list-accounts --output table            # fails if not in an organisation, that itself is a finding
aws iam list-users --output table
aws iam list-access-keys --user-name "<user>"               # repeat per user
# The credential report is generated asynchronously. Kick it off, then poll until it is served.
aws iam generate-credential-report >/dev/null
for i in $(seq 1 12); do
  out=$(aws iam get-credential-report --query Content --output text 2>/dev/null) \
    && { printf '%s' "$out" | base64 -d | head -50; break; }
  sleep 5
done
aws iam list-roles --query 'Roles[].RoleName' --output text
aws s3api list-buckets --query 'Buckets[].Name' --output text
aws cloudtrail describe-trails --output table
aws guardduty list-detectors
aws accessanalyzer list-analyzers
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?IpPermissions[?contains(to_string(IpRanges),`0.0.0.0/0`)]].[GroupId,GroupName]' --output table
aws ec2 describe-regions --query 'Regions[].RegionName' --output text   # then re-check key items per region
```

**If Google Cloud Platform** (ask for `roles/iam.securityReviewer` plus `roles/browser` at the organisation node, and then service-specific viewer roles such as `roles/compute.viewer` or `roles/logging.viewer` only where you need them):
```bash
gcloud auth list
gcloud organizations list
gcloud projects list
gcloud config set project "<project>"
gcloud projects get-iam-policy "<project>" --format=json | jq '.bindings[] | {role, members}'
gcloud iam service-accounts list
gcloud iam service-accounts keys list --iam-account "<sa-email>"   # user-managed keys are the finding
gcloud logging sinks list
gcloud storage buckets list --format='value(name)'
gcloud scc sources list --organization="<org-id>"   # requires Security Command Center enabled
```

**If Microsoft Azure** (ask for the `Reader` plus `Security Reader` roles at the management group):
```bash
az account show
az account list --output table
az account management-group list --output table
az ad signed-in-user show
az role assignment list --all --output table
az storage account list --query '[].{name:name, publicAccess:allowBlobPublicAccess}' --output table
az monitor diagnostic-settings subscription list
az security setting list -o table
az security pricing list --output table    # which Microsoft Defender for Cloud plans are on
```
Azure note: the older auto-provisioning setting has been superseded by per-plan extension settings, so a query against it no longer describes the current agent deployment posture even where the command still exists. Read it in the portal instead: Microsoft Defender for Cloud, then Environment settings, then the subscription, then Defender plans, and the Settings and monitoring pane beside it.

**A word on what these read-only roles can actually see.** None of the cloud roles named above are as harmless as the word "read-only" sounds, and you should say so out loud when you ask for them. The Amazon Web Services `ReadOnlyAccess` policy includes `s3:Get*` and `dynamodb:Scan`, and the Google Cloud `roles/viewer` role includes `storage.objects.get`, so both allow bulk reading of customer data, not just configuration. That is why the asks above are `SecurityAudit` plus `ViewOnlyAccess` and `roles/iam.securityReviewer` plus `roles/browser` instead: they describe configuration and identity without handing you the data itself. Microsoft Azure `Reader` genuinely is control plane only, and pairing it with `Security Reader` is the right ask there. Requesting the narrower role is both easier to get approved and better for you, because the first time customer data is mishandled you want your own access to be provably incapable of it.

**If you do not know which cloud, or there are several:** ask the closed question "which cloud accounts exist, who pays the bill, and is there an organisation or management group above them?" The billing owner is the fastest route to a complete list, because forgotten accounts still generate invoices.

**Good result:** an organisation or management group exists with guardrail policies, zero long-lived user access keys, audit logging on in every region and delivered to a separate account, no storage open to the public, no security group open to the world on a database port.
**Bad result, in priority order:** any `AKIA` style long-lived key belonging to a human; audit logging off, single-region, or writable by the same account; publicly readable storage; a role with a wildcard permission on a data store; no organisation at all so no guardrail can be enforced centrally.

### 2.2 Cloud posture tooling

```bash
# Prowler: open source, multi-cloud, hundreds of checks mapped to frameworks
prowler aws --severity critical high
prowler gcp --severity critical high
prowler azure --severity critical high

# ScoutSuite: open source, produces a browsable HyperText Markup Language (HTML) report, good for a first pass
scout aws
scout gcp --project-id "<project>"
scout azure --cli
```

Confirm the exact subcommand with `prowler --help` before running, since the command surface changes between major versions. The same applies to ScoutSuite. If a flag in this file does not exist in your installed version, take the tool's own help output over this file, and do not guess at a replacement flag.

Both are read-only. Both produce far too many findings on a first run. **The rule: do not present the raw report to anyone.** Take the critical and high findings, deduplicate them into at most ten themes, and put those in `RISK-REGISTER.md`. The score is meaningless. The value of these tools is the weekly **diff**, not the absolute number.

Paid alternatives exist (cloud-native posture management from the cloud providers themselves at roughly tens to low hundreds of dollars per month for a small estate, and full cloud-native application protection platforms in the tens of thousands per year). Do not ask for budget until the free tool's findings are fixed, because the first question you will be asked is "what did you do with the free one?"

### 2.3 Code host organisation settings

**If GitHub** (ask for organisation `owner`, or `read:org` plus repository admin read if they will not grant owner):
```bash
gh api "orgs/$ORG" --jq '{two_factor_requirement_enabled, default_repository_permission, members_can_create_public_repositories}'
gh api "orgs/$ORG/actions/permissions" --jq .
gh api "orgs/$ORG/actions/permissions/workflow" --jq .   # can workflows write to the repo, can they approve pull requests
gh api "orgs/$ORG/installations" --paginate --jq '.installations[].app_slug'   # installed GitHub Apps
gh api "orgs/$ORG/repos" --paginate --jq '.[] | select(.archived==false) | .full_name' > /tmp/repos.txt
while read -r r; do
  db=$(gh api "repos/$r" --jq .default_branch 2>/dev/null)
  echo "== $r ($db)"
  code=$(gh api "repos/$r/branches/$db/protection" --silent -i 2>/dev/null | head -1 | awk '{print $2}')
  case "$code" in
    200) gh api "repos/$r/branches/$db/protection" --jq \
           '{reviews:.required_pull_request_reviews.required_approving_review_count, checks:.required_status_checks.contexts, admins:.enforce_admins.enabled}' ;;
    404) echo "  NONE (no protection on the default branch)" ;;
    403) echo "  UNKNOWN (your token has no admin read on this repo)" ;;
    *)   echo "  UNKNOWN (HTTP ${code:-no response})" ;;
  esac
done < /tmp/repos.txt
gh api "orgs/$ORG/dependabot/alerts" --paginate --jq 'length' 2>/dev/null
gh secret list --org "$ORG" 2>/dev/null    # names only, never values
```

The `case` statement above exists for one reason, and it is the rule at the top of this file. The branch protection endpoint returns `404` when protection genuinely does not exist and `403` when your token simply lacks administrator read on that repository. A naive `|| echo "NO BRANCH PROTECTION"` collapses both into the same answer and records a fully protected repository as unprotected, which is exactly the `none` versus `unknown` confusion that later gets repeated to a customer. `404` is `none`. `403` is `unknown`, and it is also an access request for `ACCESS-LOG.md`.

**If GitLab** (ask for group `Owner` or at least `Maintainer` read):
```bash
glab api "groups/$GROUP" | jq '{require_two_factor_authentication, default_branch_protection}'
glab api "groups/$GROUP/projects?per_page=100" | jq -r '.[].path_with_namespace' > /tmp/projects.txt
while read -r p; do
  enc=$(printf '%s' "$p" | jq -sRr @uri)
  echo "== $p"
  glab api "projects/$enc/protected_branches" | jq -r '.[] | "\(.name) push:\(.push_access_levels[0].access_level) merge:\(.merge_access_levels[0].access_level)"'
done < /tmp/projects.txt
glab api "groups/$GROUP/variables" | jq -r '.[] | "\(.key) protected:\(.protected) masked:\(.masked)"'
```

**Good result:** two-factor authentication required organisation-wide, default repository permission of `read` or `none` (not `write`), branch protection on every default branch with `enforce_admins` true, secret scanning and push protection on, third-party application access restricted, CI variables masked and protected.
**Bad result:** any repository with no branch protection, admins allowed to bypass, `default_repository_permission: write` (everyone can push to everything), unmasked CI variables, or a long list of installed applications nobody can account for.

Record branch protection coverage as a fraction (for example "protection on 6 of 31 active repositories, 4 of 31 not readable with current access") in `SECURITY-STATE.md` row `SE-1`. Fractions are more honest than "partial" and they make progress visible later. Keep the unreadable repositories in a third bucket rather than folding them into either side of the fraction.

### 2.4 Identity provider

**Why this is now the most important section:** the dominant breach path for a startup in 2026 is infostealer malware on a laptop, stolen session cookie, straight into SaaS, then into cloud. Multi-factor authentication that can be phished does not stop it. Where 2019 treated corporate identity as back-office hygiene, treat it as the primary perimeter.

**If Google Workspace** (ask for a role with `Users: Read`, `Security Center: Read`, and reporting access, not full Super Admin):
```bash
# GAM (Google Apps Manager, a community command line tool) or its GAMADV-XTD3 fork, read-only invocations
gam print users fields primaryemail,suspended,isadmin,agreedtoterms,lastlogincount,creationtime
gam print users fields primaryemail,isenrolledin2sv,isenforcedin2sv
gam print admins
gam print tokens                 # third-party OAuth grants per user: this is the SaaS sprawl inventory
gam report admin                 # admin activity log
gam print groups members
```
Console paths where a command is uncertain: Admin console → Security → Authentication → 2-step verification (enforcement state); Security → API controls → App access control (third-party application policy); Reporting → Audit and investigation → OAuth log events.

**If Microsoft 365 / Entra ID** (ask for the `Global Reader` plus `Security Reader` roles):
```bash
az ad user list --query '[].{upn:userPrincipalName, enabled:accountEnabled}' --output table
az ad app list --all --query '[].{name:displayName, appId:appId}' --output table
az ad sp list --all --query '[].{name:displayName, type:servicePrincipalType}' --output table
# Microsoft Graph PowerShell, read-only scopes
# Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All","AuditLog.Read.All"
# Get-MgUser -All -Property UserPrincipalName,AccountEnabled
# Get-MgPolicyConditionalAccessPolicy | Select DisplayName,State
# Get-MgOauth2PermissionGrant -All
```
Console paths: Entra admin centre → Protection → Conditional Access (policies and their state); Identity → Users → Per-user MFA; Identity → Enterprise applications → Consent and permissions (user consent settings).

**If Okta, JumpCloud, or another dedicated identity provider:** ask for a read-only administrator role and export the user list, the application assignment list, the multi-factor policy, and the administrator list. The four questions are identical regardless of vendor.

**The four questions to answer, whatever the vendor:**
1. How many accounts exist, how many are active, and how many are service or shared accounts?
2. What fraction have phishing-resistant multi-factor authentication (a hardware security key or a passkey) as opposed to a one-time code or a push notification, which can be phished or fatigued?
3. Who holds administrator rights, and can you justify every one of them by name?
4. Can any employee grant a third-party application access to company data without an administrator approving it?

Question four is the Salesloft Drift lesson from August 2025: attackers stole OAuth refresh tokens for a widely-installed integration and used them to query data across more than seven hundred organisations. No password was cracked, no endpoint was touched, and multi-factor authentication was irrelevant because refresh tokens survive it. Restricting third-party application installation to administrator approval takes about twenty minutes in each platform's console and is default-open almost everywhere.

**Good result:** phishing-resistant multi-factor for all administrators and ideally everyone, fewer than four administrators, third-party application installation restricted to administrator approval, conditional access or context-aware access requiring a managed device for administrative actions.
**Bad result:** shared logins, a former employee still active, administrator accounts without hardware-backed factors, unrestricted application installation, and no idea how many OAuth grants exist.

### 2.5 SaaS admin inventories

Ask for read-only administrator access to whatever the company actually uses, in this order: the code host (covered above), the chat platform, the document platform, the customer relationship management system, the data warehouse, and the incident or ticketing system.

**If Slack** (workspace or organisation owner view): Admin → Manage apps for the installed application list and their scopes; Settings → Permissions for who can install applications; the audit logs API is Enterprise Grid only, so on lower plans note that as a detection gap in `SECURITY-STATE.md` row `DR-3`.

**If Microsoft Teams:** application governance lives in the Microsoft 365 admin centre and Entra enterprise applications, so it is the same inventory as section 2.4. Check Teams admin centre → Teams apps → Permission policies for who can add applications.

For every platform, build one table with: application name, scopes granted, who approved it, business owner, what data it can reach, and the date. Those rows go into the single `## Vendor and grant register` in `SECURITY-STATE.md`, the same table the vendors go in, because a vendor and a grant are the same object seen from two angles. Review it quarterly and revoke anything nobody claims (revocation is `MUTATES:`).

Cheap shadow-IT discovery that costs nothing: the corporate card statement from finance, and the OAuth audit log from the identity provider, read once a month. A SaaS security posture management product is worth money later. These two are worth more now.

### 2.6 Logging and detection configuration

You are answering grid cells DR-2 and DR-3: what signals exist, and can anyone actually query them?

Check, per platform, three things: is the log being generated, is it retained somewhere the producing account cannot delete, and can a human query it in under five minutes during an incident.

```bash
# AWS
aws cloudtrail get-trail-status --name "<trail>"
aws cloudtrail describe-trails --query 'trailList[].{name:Name,multiRegion:IsMultiRegionTrail,orgTrail:IsOrganizationTrail,bucket:S3BucketName}'
aws logs describe-log-groups --query 'logGroups[].{name:logGroupName,retention:retentionInDays}' --output table
# GCP
gcloud logging sinks list
gcloud logging buckets list --location=global
# Azure
az monitor diagnostic-settings subscription list
az monitor log-analytics workspace list --output table
```

**Good result:** cloud audit logs on in all regions, delivered to a separate account or project with restricted deletion, retention of at least ninety days and ideally a year, and at least one query the human has actually run.
**Bad result:** logging on but nobody has ever opened it, retention of seven days (too short to investigate anything), or logs stored in the same account an attacker would compromise.

Detection and response is the hardest quadrant to show progress in, and it feels like nothing is working until suddenly it is. Do not try for full coverage. Pick the two or three signals with the highest ratio of attack visibility to effort: cloud API key usage anomalies, identity provider sign-in and administrative events, and code host events on workflow files and branch protection settings. Those three cover most realistic startup compromise paths.

### Tier 2 exit criteria

Every cell in `SECURITY-STATE.md` is in one of three defensible positions: it has a status set from something you observed yourself, or it carries a named and dated access request in `ACCESS-LOG.md` explaining why it is still `unknown`, or it is closed as `n/a` with a written reason (a consumer account cell at a company with no consumer accounts, for example). All three are finished work. What is not finished is a cell nobody has thought about.

Filling in a row is not the same as doing something about it. Recon produces status, and status feeds the plan, but nothing in the grid entitles a cell to your time. The next thing you work on is whatever the findings point at.

---

## Tier 3: full read plus limited write

You now have enough access to change things. This tier is about **verification** and **the smallest safe changes**, not about a rebuild.

### 3.1 What you can now verify

Verification means you produced evidence, not that someone told you. Acceptable evidence: command output you ran yourself, a screenshot the human confirms is from the live console, or a test that fails when the control is removed.

- Multi-factor coverage: export the user list with the enrolment field and count. Evidence is the count, not the policy document.
- Branch protection: attempt is not needed, read the protection object per repository and record the fraction.
- Logging: run one real query for a known event (your own sign-in from ten minutes ago). If you cannot find yourself, the logging pipeline is broken regardless of what the configuration says.
- Secret rotation: check the credential's last-used timestamp after rotation. `aws iam get-access-key-last-used --access-key-id <id>` proves the old key is dead.
- Offboarding: pick one person who left in the last six months and check every system for them. This single test tells you more about grid cell CS-3 than any policy.

### 3.2 The smallest safe changes, in order

Each of these is `MUTATES:` and each requires the STOP block and a human yes. They are ordered by risk-reduction per unit of blast radius.

1. `MUTATES:` Turn on secret scanning and push protection on the code host. Low blast radius, blocks new secrets at commit time. On GitHub this is an organisation security setting; on GitLab it is a group-level Secret Detection setting.
2. `MUTATES:` Restrict third-party application installation to administrator approval in the identity provider and the chat platform. Blast radius: an employee who tries to install something gets a request flow instead of a grant. Announce it in the company channel first, which is grid cell DR-4 working for you.
3. `MUTATES:` Add a DMARC record starting at `p=none` with a reporting address, read reports for two weeks, then move to `p=quarantine`. Going straight to `p=reject` without observing reports will drop legitimate mail from marketing tools, so do not.
4. `MUTATES:` Enable audit logging where it is off, in every region. Costs money at scale, so price it first and tell the person who owns the bill.
5. `MUTATES:` Add branch protection to the default branch of the top five repositories by deploy frequency. Pair with the engineering lead so the first person to hit it is not surprised.

Do not, in your first weeks: rotate a credential without the owning engineer present, delete a user account, change a network rule, or enable a blocking control on a deploy path. Every one of those has caused a self-inflicted outage that ended a security hire's credibility in week two. Corporate identity can be fixed in a few quarters. Production takes years. Start where the fix is cheap and the blast radius is small.

---

## Writing recon output into SECURITY-STATE.md

One row per grid cell, always the same shape. Overwrite the row when you learn more, and never delete the evidence column.

Before the format, the point of the format. This table is bookkeeping so that you, and the agent working alongside you, do not lose track of an entire area (corporate identity is the usual casualty, because the codebase is more interesting). It is not a work queue and it is not read out to the human cell by cell. Nothing gets worked because a row says `unknown`. Things get worked because a finding in this company makes them urgent, and a finding that matches no row at all is still real work: record it in `RISK-REGISTER.md` and do it.

```markdown
| Cell | Name | Status | Evidence | Owner | Last checked |
| --- | --- | --- | --- | --- | --- |
| SE-1 | SDLC and design reviews | partial | Branch protection on 6/31 active repos, `gh api` output 2026-03-04. No design review process found. | eng lead | 2026-03-04 |
| SE-2 | Understand the tech stack | partial | Node 20 monorepo, Terraform on AWS, 1,412 transitive npm deps. From Tier 0 recon. | me | 2026-03-04 |
| SE-3 | Secrets and keys | none | gitleaks found 3 verified live secrets in history, see RISK-REGISTER R-002. | unassigned | 2026-03-04 |
| CS-1 | Identity and access | unknown | No Workspace admin access yet. Requested 2026-03-04, see ACCESS-LOG. | unassigned | 2026-03-04 |
```

**Status vocabulary, used exactly:**
- `unknown`: you have not looked, or you looked and could not see. This is the default for every cell before recon and it is not a failure, it is an honest starting point.
- `none`: you looked and the control does not exist.
- `partial`: the control exists but coverage is incomplete. Always quantify the fraction.
- `done`: the control exists, coverage is complete, and you hold verification evidence you produced yourself.

**The unverified rule, restated because it is the one people break:** a statement from a colleague, a line in a policy document, a vendor's marketing page, and a configuration setting you did not read yourself are all `unknown`. Write the claim in the evidence column prefixed with "claimed:" so you can come back and confirm it. When a chief executive later asks "did we have that control?" the difference between `unknown (claimed: yes, per CTO 2026-03-04)` and `done` is the difference between a manageable conversation and a career event.

Alongside the cell rows, recon should populate:
- `## Environment facts` in `SECURITY-STATE.md`: cloud provider or providers, code host, identity provider, chat platform, primary languages, deploy mechanism, number of employees, number of engineers, business-to-business or business-to-consumer. Business model first: it is the single biggest driver of what you prioritise.
- `## Vendor and grant register` in `SECURITY-STATE.md`, one table covering both purchased vendors and standing application grants.
- One row in `RISK-REGISTER.md` per critical or high finding, with severity, the plain-language failure scenario, a named owner, and either a fix date or an explicit acceptance with the name of the person who accepted it.
- One row in `ACCESS-LOG.md` per access request, with the date, the exact role name requested, the reason, and the outcome.
- If recon is interrupted mid-tier, push the tier and the last completed section onto `CONTEXT-STACK.md` before switching, per `references/04-interrupts.md`.

---

## Recon of the non-technical environment

The technical picture tells you what is broken. This tells you what you are allowed to fix, and it is the part that gets skipped and then decides whether the program survives. Gather it through conversation, not commands. Two or three fifteen-minute conversations in the first week beat a month of scanning.

### The eight questions, and why each one earns its place

1. **Who decides?** Name the person who can say yes to a control that slows engineers down. It is usually the Chief Technology Officer or VP Engineering, occasionally the Chief Executive at fewer than fifty people, rarely the person who hired you. If two people both think they decide, that conflict will surface at your first difficult change, so find it now.
2. **Who has budget, and what is the cycle?** A first security hire typically has no budget line. Find out whose budget tools would come out of and when that budget is set. If the annual plan closes in six weeks, your tool ask has a deadline you did not know about.
3. **What was the last incident?** Security programs almost always start a few months after something bad happened. Ask directly: "what happened, what did we tell customers, what did we promise we would change?" That promise is your mandate, in writing, already approved. It is also the most likely thing an auditor or a customer asks about.
4. **What has sales already committed to?** It is extremely common for the business to promise a compliance milestone before anyone qualified was in the room. "We will have SOC 2 Type 2 in three months" (System and Organization Controls 2, a third-party audit report on your security controls) is a sentence that has ended careers. Find out today, because if it exists you are renegotiating a date rather than starting a program. Log it in `SECURITY-STATE.md` row `CO-3` and in `DECISION-LOG.md`.
5. **What is in the sales pipeline that needs security?** Ask sales for the deals currently blocked or slowed by a security questionnaire, a penetration test request, or a compliance requirement, with dollar values and close dates. This converts your work from a cost centre into revenue support and it is the single most effective argument you will ever have for headcount or budget.
6. **What does engineering already hate?** Ask engineers what previous security or compliance work cost them. Usual answers: a scanner that files noisy tickets, a mandatory training module, a review gate that added days, an agent that ate laptop battery. Whatever they name, do not do it in your first quarter. You get roughly one unpopular change per quarter of credibility, so spend it deliberately.
7. **What is the culture around saying no?** Some companies expect security to be a gate. Most startups will route around a gate within a week. Assume you are advisory until proven otherwise, and get your leverage from owning the paved road (the repository template, the infrastructure module, the reusable pipeline, the identity policy) rather than from reviewing things one at a time. Code volume per engineer has risen sharply with artificial intelligence assisted development, and a human review gate is no longer a rate limiter you can stand at.
8. **Who are your allies?** Find the one engineer who already cares, the one person in operations or finance who owns the vendor list and the corporate card, and the one person in sales who fills in questionnaires today. Those three people give you the tech stack, the vendor inventory, and the compliance pressure without any access grant at all.

### How to run these conversations

- Fifteen minutes, one-to-one, no slides. Say plainly: "I am new, I want to understand how things work before I change anything, and I want to know what previous security work annoyed you."
- Ask what is broken that they already know about. Engineers usually hand you the top three risks in the first five minutes and are relieved someone asked.
- Do not commit to anything in the meeting. Say "let me look into it and come back with an option."
- Write every commitment anyone else made (dates, promises to customers, promises to auditors) into `DECISION-LOG.md` with the source and the date.

### Recording it

Add a `## Organisational facts` section to `SECURITY-STATE.md` covering: decision maker, budget owner and cycle, last incident and its date, outstanding compliance commitments and their promised dates, blocked pipeline value, engineering's stated pain points, and named allies. Mark unanswered items `unknown` and put the specific question in the next session's opening.

---

## What to do the moment recon ends

Do not present a findings dump. Nobody at a twelve-person startup will read forty findings, and presenting them makes you look like a cost.

Produce three things, in this order:
1. The **top three risks**, each with a one-sentence plain-language failure scenario ("a stolen laptop session gives an attacker our customer database because there is no device requirement on the identity provider"), a named owner, and a fix that takes under a week.
2. The **top three unknowns**, each with the exact access grant that would resolve it, ready to paste into a message.
3. One **recommended next action**, singular, with a go or no-go question.

Then stop and wait for the answer. Everything else goes into `RISK-REGISTER.md` and comes out when it is that item's turn. The 90 day plan in `references/03-90-day-plan.md` is where the sequencing lives, and it is gated deliberately so that you never dump the whole plan on the human at once.
