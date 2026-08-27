# SE-2: Understanding your tech stack by engineering

> **Grid coordinate:** SE-2, Security Engineering domain.
> **Original 2019 wording (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019):** "Understanding your tech stack by engineering."
> **Load when:** the human is in their first two weeks, or at any point when the agent cannot answer the question "what does this company actually run, and where does customer data live?" from `SECURITY-STATE.md`. Also load when a design review, an incident, a questionnaire, or a cloud posture task stalls because the underlying architecture is unknown.

## Why this cell exists

You cannot protect something you cannot draw. Every other cell in the grid quietly depends on this one: an incident response plan needs to know which systems exist, a data inventory needs to know where the database is, a design review needs to know what "normal" looks like, and a security questionnaire will ask you to describe your architecture in writing. Evan Johnson's original framing was blunt about the method: "If you want to learn about how your tech stack works at a deep level, you need to build software." The point is that reading a wiki gives you the architecture somebody intended two years ago, while pairing with an engineer for an hour gives you the architecture that is actually deployed today.

This is also the cheapest political capital you will ever buy. Asking an engineer to explain their own system, listening carefully, and drawing it back to them accurately is the single fastest way to stop being "the security person who says no" and start being someone engineers bring problems to.

## Definition of done

Good enough for a 20 to 100 person startup means all of the following exist as files, not as knowledge in one person's head:

- [ ] A one page architecture diagram showing every component that processes or stores customer data, with trust boundaries drawn (internet to edge, edge to application, application to data store, application to third party).
- [ ] An asset inventory listing: cloud accounts and projects, code repositories, data stores, internet-facing hostnames, and third parties that receive customer data. Each entry has an owner (a human name, not a team).
- [ ] A crown jewels list: the five systems or data sets whose compromise would materially threaten the company, ranked, with one sentence each on why.
- [ ] One request traced end to end in writing: a real user action, from browser or client through to the database write and back, naming every hop.
- [ ] A named list of every place customer data is stored, and for each one, the list of humans and machine identities that can read it.
- [ ] If the product is multi-tenant: the tenancy model is written down in four lines (where the tenant identifier comes from, whether the data layer scopes by it centrally or per query, which mechanism does it, and which code paths bypass it). If the product is not multi-tenant, that sentence is written down instead, with the reason.
- [ ] At least two engineers have read the diagram and confirmed it is correct, by name and date, recorded in `SECURITY-STATE.md`.

Explicitly **not** required at this stage: a CMDB (configuration management database, the enterprise tool that tracks every asset), an automated asset discovery product, a formal threat model document per service, a full data flow diagram in a modelling tool, network diagrams with IP ranges, or completeness. A diagram that covers the 80 percent of traffic that touches customer data beats a complete diagram that took six weeks.

## Discovery

Run read-only commands first, ask humans second. Everything below is read-only unless explicitly marked. If the agent has no cloud or code access at all, skip to "Ask the human" and to the external-only section at the end of this block.

### Step 0: what is in front of you

If the working directory contains a repository, start there. These are safe and fast:

```bash
git remote -v
git log --oneline -20
ls -la
cat README.md 2>/dev/null | head -60
find . -maxdepth 3 -name 'docker-compose*.y*ml' -o -maxdepth 3 -name 'Dockerfile*' -o -maxdepth 3 -name '*.tf' -o -maxdepth 3 -name 'serverless.y*ml' -o -maxdepth 3 -name 'Chart.yaml' 2>/dev/null | head -40
```

Language and framework fingerprints tell you what the runtime is: `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile`, `pom.xml`, `build.gradle`, `Cargo.toml`, `composer.json`. Infrastructure as code fingerprints tell you what the cloud is: `*.tf` and `.terraform/` for Terraform, `cdk.json` for the Amazon Web Services (AWS) Cloud Development Kit, `template.yaml` with `AWSTemplateFormatVersion` for CloudFormation, `main.bicep` for Azure Bicep, `pulumi.yaml` for Pulumi, `k8s/` or `kustomization.yaml` or `Chart.yaml` for Kubernetes.

If the directory is empty, that is fine and expected. This skill is designed to work from zero. Go straight to the human questions.

### Cloud: AWS

Confirm identity first so you know whose eyes you are looking through.

```bash
aws sts get-caller-identity
aws organizations list-accounts --output table          # only works from the management account
aws ec2 describe-regions --query 'Regions[].RegionName' --output text
```

Then enumerate the surface. Repeat the regional ones for each region actually in use.

```bash
aws s3api list-buckets --query 'Buckets[].Name' --output text
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Engine,PubliclyAccessible,Endpoint.Address]' --output table
aws dynamodb list-tables
aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,Scheme,DNSName]' --output table
aws apigateway get-rest-apis --query 'items[].[name,id]' --output table
aws lambda list-functions --query 'Functions[].FunctionName' --output text
aws ecs list-clusters
aws eks list-clusters
aws route53 list-hosted-zones --query 'HostedZones[].Name' --output text
aws cloudfront list-distributions --query 'DistributionList.Items[].[DomainName,Aliases.Items]' --output json
```

The two fields that matter most on first pass are `Scheme: internet-facing` on load balancers and `PubliclyAccessible: true` on databases. Anything with both is a finding worth writing down immediately.

### Cloud: Google Cloud Platform (GCP)

```bash
gcloud auth list
gcloud projects list
gcloud config set project PROJECT_ID          # changes local config only, not cloud state
gcloud asset search-all-resources --scope=projects/PROJECT_ID --format='table(assetType,name)' | head -100
gcloud compute instances list
gcloud compute forwarding-rules list
gcloud storage buckets list --format='table(name,location)'
gcloud sql instances list
gcloud run services list
gcloud container clusters list
gcloud dns managed-zones list
```

`gcloud asset search-all-resources` is the highest-yield single command in GCP because it crosses service boundaries. It requires the Cloud Asset API to be enabled and the `roles/cloudasset.viewer` role. If it fails, fall back to the per-service `list` commands above.

### Cloud: Microsoft Azure

```bash
az account show
az account list --output table
az resource list --output table | head -100
az storage account list --query '[].[name,allowBlobPublicAccess]' --output table
az sql server list --query '[].[name,fullyQualifiedDomainName,publicNetworkAccess]' --output table
az network public-ip list --query '[].[name,ipAddress]' --output table
az webapp list --query '[].[name,defaultHostName]' --output table
az aks list --query '[].[name,fqdn]' --output table
```

### If you do not know which cloud

Ask. But you can also infer it from the Domain Name System (DNS): run `dig +short www.<company>.com` and `dig +short api.<company>.com`, then look at where the address resolves. A CNAME ending in `.amazonaws.com` or `.cloudfront.net` means AWS, `.googleusercontent.com` or `.run.app` means GCP, `.azurewebsites.net` or `.cloudapp.azure.com` means Azure, `.vercel-dns.com` or `.netlify.app` or `.herokudns.com` means a platform-as-a-service provider sits in front. Multiple answers usually means multiple clouds, which is normal and worth noting.

### Code hosting: GitHub

```bash
gh auth status
gh repo list ORG --limit 200 --json name,visibility,pushedAt,isArchived
gh api "orgs/ORG" --jq '{login,plan:.plan.name,two_factor_requirement_enabled}'
gh api "orgs/ORG/repos?per_page=100" --paginate --jq '.[] | select(.visibility=="public") | .full_name'
gh workflow list --repo ORG/REPO
gh secret list --repo ORG/REPO          # names only, values are never readable
```

Sort repos by `pushedAt` and read the top ten. Those are the systems that are alive. Everything else is archaeology and can wait.

### Code hosting: GitLab

```bash
glab auth status
glab repo list --group GROUP --per-page 100
glab api "groups/GROUP/projects?per_page=100&order_by=last_activity_at"
glab api "projects/:id/variables"        # names and (if you are owner) values, treat output as sensitive
```

If neither CLI is installed or authenticated, the web console paths are: GitHub at `https://github.com/orgs/<org>/repositories` sorted by "Recently pushed", and GitLab at `https://gitlab.com/groups/<group>/-/projects` sorted by "Last updated".

### Internet-facing surface: DNS and certificate transparency

Certificate transparency logs are public records of every Transport Layer Security (TLS) certificate ever issued for your domains. They are the single best free way to find the staging environment nobody told you about. This is passive and touches nothing you own.

```bash
curl -s "https://crt.sh/?q=%25.example.com&output=json" | python3 -c "import sys,json;print('\n'.join(sorted({r['name_value'] for r in json.load(sys.stdin)})))"
dig +short example.com ANY
dig +short NS example.com
dig +short TXT example.com
dig +short MX example.com
```

The `TXT` records are quietly informative: they name your email provider, your identity provider, and often several SaaS vendors that asked you to prove domain ownership. Write every one of them down as a lead for the third-party inventory.

For each hostname you find, check whether it answers and what it is:

```bash
curl -sI -m 10 https://staging.example.com | head -20
```

Do not scan, brute force, or run vulnerability tools against anything before SE-4 and before written authorisation. Passive enumeration and a plain HTTPS HEAD request to your own company's hostname are fine. Anything more aggressive belongs in the danger zone below.

### Containers and Kubernetes

```bash
kubectl config get-contexts
kubectl auth can-i --list
kubectl get namespaces
kubectl get ingress --all-namespaces
kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer
kubectl get pods --all-namespaces -o wide
kubectl get secrets --all-namespaces          # names only; do not print values
```

`kubectl auth can-i --list` is the honest answer to "how much power does this credential have", and it is worth running as the very first Kubernetes command. If it returns a wildcard on `*`, you are holding cluster admin and should say so out loud.

For images, `docker images` and `docker ps` on a developer machine tell you the local runtime. Where images come from matters more than what is in them right now: find the registry (Amazon ECR, Google Artifact Registry, Azure Container Registry, Docker Hub, GitHub Container Registry) and note whether any repository in it is public.

### When you have no access at all

You can still make real progress in one session:

1. Certificate transparency and DNS give you the external footprint with zero credentials.
2. The company's public job listings name the stack precisely, because they have to.
3. The public status page names the regions and often the sub-services.
4. The public trust or security page (if any) names the sub-processors, which is your third-party list.
5. The engineering blog names the databases and the queueing system.

Record all of this in `SECURITY-STATE.md` under the SE-2 section with status `partial` and evidence `external only, no internal access as of <date>`. Then file the access request in `ACCESS-LOG.md` and ask.

## Tenant isolation and object-level authorization

Read this section when the product is multi-tenant, which for a business-to-business software company it almost always is. Multi-tenant means one running system serves many customer organisations out of shared infrastructure, and usually out of shared database tables. Object-level authorization means the check that the specific record being returned belongs to the organisation the caller is in. When that check is missing, changing an identifier in a request returns another customer's data. The industry name for the flaw is IDOR (insecure direct object reference), and the broader family, broken access control, has been the number one entry in the OWASP (Open Worldwide Application Security Project) Top 10 since 2021.

This matters more than its length here suggests. For a multi-tenant business-to-business product, the likeliest route to a customer data breach is not a misconfigured storage bucket. It is one endpoint that forgot the tenant predicate. It is also the first thing a serious enterprise buyer asks about, the first thing an external researcher tests, and the one class of bug that no scanner you can afford will find for you, because only you know what a tenant is in your product.

Everything in this section is read-only reading of your own source code, configuration, and database catalog. It is discovery, not testing. The procedure that actually proves isolation holds is the authorized cross-tenant access test in `se-1-sdlc-and-design-reviews.md`. It requires written authorisation, it runs on staging against tenants you created, and it is never run against production or against a real customer's tenant.

### Question 0: is it multi-tenant, and in what shape?

Answer this in one sentence before going further, because the rest of this section changes meaning depending on it.

- **Shared database, shared tables, a tenant column.** The most common shape and the one where this section applies at full strength. Every table holding customer data carries a column such as `tenant_id`, `account_id`, `org_id`, `organization_id`, `workspace_id`, or `company_id`.
- **Shared database, one schema or one database per tenant.** The connection or the search path is selected at the start of each request. The failure mode moves from "a query forgot the predicate" to "the wrong connection was selected", which is rarer and fails completely when it happens.
- **One deployment per customer.** Isolation is infrastructural. The remaining risk sits in the shared control plane and the deploy pipeline that can reach every deployment, see `07-modern-cells.md`.
- **Business-to-consumer, where the tenant is a single user account.** The same object-level check applies, per user rather than per organisation, and the grep passes below work unchanged if you read `tenant` as `user`. See `se-5-consumer-account-security.md`.

If nobody at the company can answer this in one sentence, that is itself the finding, and it goes into `RISK-REGISTER.md` the same day.

### Question 1: where does the tenant identifier enter the request?

Find the exact place. There are only a few possibilities and they carry very different risk.

| Where it comes from | Looks like | Can the caller change it? |
|---|---|---|
| A claim inside the signed session token or a server-side session record | `org_id` in a JSON Web Token (JWT) payload, or a row in a sessions table | No, provided the signature or the session store is checked on every request |
| The subdomain, read from the `Host` header | `acme.app.example.com` | Yes, freely |
| A request header | `X-Org-Id: 42` | Yes, freely |
| A path segment | `/api/orgs/42/invoices/1001` | Yes, freely |
| A query parameter or a body field | `?account=42` | Yes, freely |

The rule worth writing directly on the architecture diagram: a tenant identifier that the client supplies is a request parameter, not an identity. It is only safe when the server compares it against the tenant on the authenticated session and rejects a mismatch. The specific pattern to look for, because it is common and it looks correct in code review, is a system that reads the tenant from the path or the subdomain, uses it to scope every single query properly, and never checks that the logged-in user actually belongs to that tenant. Every query is scoped, and every one of them is scoped to whichever tenant the attacker typed into the address bar.

Locate where the request-scoped tenant is established. It is nearly always in middleware, a filter, an interceptor, or a base controller.

```bash
# Read-only. Run at the root of a checkout of your own source code.
grep -rniE 'current_(tenant|account|org|organization|workspace)|set_current_tenant|tenant_?id|with_?tenant' \
  --include='*.py' --include='*.rb' --include='*.go' --include='*.java' --include='*.cs' \
  --include='*.ts' --include='*.js' --include='*.php' . 2>/dev/null \
  | grep -viE 'node_modules|/vendor/|/dist/|/build/|\.min\.js|spec/|/tests?/' | head -60
```

Read the twenty results closest to the request entry point, not all of them. You are looking for one function that answers "who is this request for", and for whether anything downstream can reach the database without passing through it.

### Question 2: does the data layer scope by tenant centrally, or does every query do it itself?

This is the single most important architectural question in this cell. Ask it out loud in the whiteboard session in step 1 of the walk. There are two answers and their risk profiles are not close.

**Central enforcement.** The tenant predicate is applied in one place that every query passes through, so an engineer cannot forget it. The mechanisms that actually count, by stack:

- PostgreSQL row level security (RLS), where the database itself refuses to return rows outside the current session setting.
- A global filter in the ORM (object relational mapper): `HasQueryFilter` in Entity Framework Core, a custom manager plus a request-scoped current tenant in Django, `default_scope` or the `acts_as_tenant` gem in Rails, `@Filter` in Hibernate, a client extension or `$extends` query override in Prisma, `defaultScope` in Sequelize, global scopes in GORM, a global scope on the base model in Laravel.
- A repository or data access layer that every query must go through, which takes the tenant from a request-scoped context object and injects the predicate itself.
- One database, one schema, or one connection per tenant, selected once at the start of the request.

**Per-query discipline.** Every engineer writes the tenant predicate into every query by hand. The control is human memory. It holds until the fourth engineer joins, or a hurried Friday, or somebody adds an internal reporting endpoint. The failure is silent: the query returns rows, the page renders, the tests pass, and nothing looks wrong until a customer or a researcher finds it.

There is no third answer. "Different services do it differently" means the per-query half is where you look first.

Record which one it is in `SECURITY-STATE.md` under SE-2. If the answer is per-query discipline, that fact by itself belongs in `RISK-REGISTER.md` with a real severity, because it makes every future feature a fresh opportunity for the same bug.

Two follow-up questions separate real central enforcement from the appearance of it:

1. **What happens on a miss?** A central mechanism makes a cross-tenant fetch return "not found", because the row was never visible. If the answer is "we return 403 Forbidden", the check is happening after the row has already been loaded, which usually means it is per-query after all, and it means anything that loads the row and skips the check leaks it.
2. **Which code paths bypass it?** Every central mechanism has escape hatches. Get the written list. Question 4 below is the list you should expect.

If the database is PostgreSQL and the claimed mechanism is row level security, verify it, because row level security that looks enabled is very often inert:

```sql
-- Read-only catalog queries. They return schema metadata, no customer rows.
SELECT schemaname, tablename, rowsecurity FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY 1, 2;

SELECT * FROM pg_policies;

SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class
  WHERE relkind = 'r' AND relnamespace::regnamespace::text = 'public' ORDER BY relname;

SELECT current_user, session_user;
```

The trap: row level security does not apply to the table's owning role unless somebody has run `ALTER TABLE ... FORCE ROW LEVEL SECURITY`, and it never applies to a superuser. Most startups connect their application as the owning role. A schema full of policies, plus `relforcerowsecurity` false, plus an application that connects as the owner, adds up to no isolation at all while every dashboard says row level security is on. That is a genuine and common finding.

Connecting to a production database at all requires an explicit human yes, see the Danger zone below. Prefer a development database, a staging replica, or asking an engineer to run these four queries and paste you the output.

### Question 3: the read-only grep pass for unscoped fetches

Goal: find queries that fetch a record by its primary key with no tenant predicate. This runs against a checkout of your own source code, it reads nothing but files, and it changes nothing. It produces leads, not verdicts. Every hit needs a human to look at the surrounding function and decide whether the scope is applied somewhere else. Expect many false positives and expect two or three real ones.

Run the block that matches the stack. If you do not know the stack yet, go back to step 0 of Discovery.

**Prisma (TypeScript or JavaScript).**

```bash
grep -rnE '\.(findUnique|findUniqueOrThrow|update|delete|upsert)\(' \
  --include='*.ts' --include='*.js' . 2>/dev/null | grep -v node_modules | head -60
```

`findUnique` can only filter on unique fields, so it cannot carry a tenant predicate at all unless the unique index is composite, for example `@@unique([tenantId, id])`. Every `findUnique` on a bare `id` is therefore a lead by construction. The safe replacement is `findFirst({ where: { id, tenantId } })`.

**TypeORM and Sequelize (TypeScript or JavaScript).**

```bash
grep -rnE 'findByPk\(|\.findOne\(|findOneBy\(|findOneOrFail\(|\.getRepository\(' \
  --include='*.ts' --include='*.js' . 2>/dev/null | grep -v node_modules | head -60
```

`findByPk` in Sequelize takes a primary key and nothing else. It is the single highest-signal pattern in a Sequelize codebase.

**Django (Python).**

```bash
grep -rnE '\.objects\.(get|filter)\(\s*(pk|id)\s*=' --include='*.py' . 2>/dev/null | head -60
grep -rn 'get_object_or_404(' --include='*.py' . 2>/dev/null | head -40

# Django REST Framework: a class-level queryset with no get_queryset override
# means every detail route resolves by primary key across all tenants.
grep -rnE 'queryset\s*=\s*[A-Za-z_]+\.objects\.all\(\)' --include='*.py' . 2>/dev/null | wc -l
grep -rn 'def get_queryset' --include='*.py' . 2>/dev/null | wc -l
```

Compare those last two counts. A codebase with thirty class-level querysets and four `get_queryset` overrides has twenty six detail routes to look at.

**SQLAlchemy (Python).**

```bash
grep -rnE '\.query\([A-Za-z_]+\)\.get\(|session\.get\(|filter_by\(\s*id\s*=' \
  --include='*.py' . 2>/dev/null | head -60
```

**Rails and ActiveRecord (Ruby).**

```bash
grep -rnE '\.find\(params\[|^\s*[A-Z][A-Za-z:]*\.(find|find_by_id)\(' --include='*.rb' app/ 2>/dev/null | head -60

# The scoped form is the safe one. Compare the two counts.
grep -rncE 'current_(user|account|tenant|organization)\.[a-z_]+\.find' --include='*.rb' app/ 2>/dev/null | head
```

`Thing.find(params[:id])` is the canonical version of this bug. `current_account.things.find(params[:id])` is the fix, and it fails closed with a `RecordNotFound`.

**Laravel and Eloquent (PHP).**

```bash
grep -rnE '::(find|findOrFail)\(' --include='*.php' . 2>/dev/null | grep -v '/vendor/' | head -60

# Route model binding resolves a model by primary key before your controller runs.
grep -rnE 'Route::(get|post|put|patch|delete)\(.*\{[a-zA-Z_]+\}' routes/ 2>/dev/null | head -40
```

**Go with GORM.**

```bash
grep -rnE '\.(First|Take|Last)\(&[A-Za-z]+' --include='*.go' . 2>/dev/null | head -60
grep -rnE 'Where\("id = \?"' --include='*.go' . 2>/dev/null | head -40
```

**C# with Entity Framework.**

```bash
grep -rnE '\.(Find|FindAsync)\(' --include='*.cs' . 2>/dev/null | head -60
grep -rn 'HasQueryFilter' --include='*.cs' . 2>/dev/null | head -20   # the central mechanism, if present
grep -rn 'IgnoreQueryFilters' --include='*.cs' . 2>/dev/null | head -20  # every deliberate bypass
```

**Raw SQL, any language.** This is the highest-yield single command in this section, because raw SQL bypasses whatever the ORM does centrally.

```bash
grep -rnEi "select[^;]*from[^;]*where[^;]*\bid\s*=" \
  --include='*.sql' --include='*.py' --include='*.rb' --include='*.go' --include='*.php' \
  --include='*.java' --include='*.cs' --include='*.ts' --include='*.js' . 2>/dev/null \
  | grep -viE 'node_modules|/vendor/|tenant|account_id|org(anization)?_id|workspace_id|customer_id|company_id' \
  | head -60
```

Every surviving line is a query that selects by identifier and mentions no tenant column anywhere on the same line. Some are lookups on tenant-independent tables (a feature flag, a country list, a pricing plan) and those are fine. The rest are leads.

**What to do with the hits.** Do not open tickets during discovery, per the "Do not do this yet" section below. Build one table: file and line, the endpoint or job it serves, whether the scope is applied elsewhere in the call path, and confidence. Take the three highest-confidence rows to the engineer who owns that code and ask, without accusation, "where does the tenant scope come from here?". Their answer is worth more than your reading of it. Then park the whole table in `RISK-REGISTER.md` as one entry with the count, and use it as the input to the authorized test in `se-1-sdlc-and-design-reviews.md`.

One note on identifiers while you read the hits. If record identifiers are sequential integers, a missing check is trivially discoverable by anyone who can count. If they are random and long, for example a version 4 UUID (universally unique identifier) or a ULID (universally unique lexicographically sortable identifier), the same missing check is much harder to stumble into. Write this down as context for severity, and do not write it down as a control. An unguessable identifier is not an authorization check. It leaks in referrer headers, in shared links, in support tickets, in logs, and in exports, and the check is still missing when it does.

### Question 4: the paths that skip the check even when the central mechanism is real

Ask for these by name. Every one of them is a place where a correct central mechanism is routinely bypassed, and they are where the real findings live in a company that already got the main request path right.

- **Background jobs, queue workers, and scheduled tasks.** They run with no request, so there is no request-scoped tenant for a middleware to set. Ask what the tenant context is inside a job.
- **Admin tooling, internal support tools, and impersonation.** These exist precisely to cross the boundary. Ask who can use them, whether the action is logged with both the operator and the target tenant, and whether the tool is reachable from the public internet.
- **Bulk export, reporting, and analytics endpoints.** Written under time pressure, usually in raw SQL, usually by somebody senior enough not to be reviewed.
- **Search.** A single search index holding every tenant's documents with the tenant filter applied only in the query is one typo away from a full cross-tenant read. Ask whether the filter is enforced at index level, at query level, or by an index per tenant.
- **Object storage and file downloads.** Predictable object keys, long-lived pre-signed URLs, and buckets shared across tenants. The database check being correct does not help if the file is fetched directly.
- **Caches.** A cache key that omits the tenant serves one tenant's response to another. This one presents as an intermittent bug report, not as a security report.
- **Webhook receivers and public callback endpoints.** They frequently authenticate the sender and then trust an identifier in the payload to decide which tenant to write to.
- **The data warehouse and any business intelligence tool.** Isolation almost never survives the pipeline into analytics, and the analytics tool has its own access model. See `07-modern-cells.md`.
- **Database migrations and one-off scripts.** They run as the owning role, which is exactly the role that row level security does not constrain.

### What to write down

In `SECURITY-STATE.md` under SE-2, in four lines: the tenancy shape, where the tenant identifier comes from, whether enforcement is central or per-query and by which mechanism, and the named list of bypass paths from question 4. If the product is not multi-tenant, write that sentence and the reason, and move on.

In `RISK-REGISTER.md`: per-query discipline as its own entry if that is the answer; row level security that is enabled but not forced; any bypass path with no compensating check; and the count of unscoped fetch leads from question 3 with the three you have the most confidence in named.

## Ask the human

Ask these as closed questions, one at a time, and record every answer in `SECURITY-STATE.md` under SE-2. Do not ask "tell me about the architecture". That returns a monologue you cannot act on.

1. Which cloud providers do we have accounts with today? (Answer options: AWS, GCP, Azure, other, more than one, I do not know yet.)
2. Where is the main production database, and what kind is it?
3. What is the name of the repository that contains the main customer-facing application?
4. Is there a staging or demo environment, and is it reachable from the public internet?
5. Which single engineer would you call at 2am if production was down?
6. Do we have any customer data outside the main database? (Common answers: object storage buckets, the data warehouse, the analytics tool, the support ticketing tool, log files.)
7. Is the product multi-tenant, and if so, does one database hold more than one customer's data in the same tables?
8. Show me one query in the code that fetches a record by its identifier. Where does the tenant scope come from, and is that the same everywhere?
9. Does anyone have an architecture diagram, even a bad one, even on a whiteboard photo?
10. Who is the first engineer I should ask for one hour of their time?

Copy-pasteable message the human can send to the engineer who owns the main service:

> Hi, I have just joined to work on security and I am trying to build an accurate picture of what we actually run, rather than guessing from the wiki. Could I book 45 minutes with you this week to whiteboard the architecture of the main service? I will drive, you correct me, and I will send you the diagram afterwards so you can tell me what I got wrong. No prep needed, and I am not reviewing anything or looking for problems. I just want to be useful faster.

Copy-pasteable message for read-only cloud access:

> Hi, to do security work I need read-only visibility into our cloud accounts. I am asking for the built-in security review roles, not admin, and deliberately not the broad viewer roles. On Amazon Web Services that is the `SecurityAudit` and `ViewOnlyAccess` managed policies. On Google Cloud it is `roles/iam.securityReviewer` plus `roles/browser`, plus a service-specific viewer role for each service I actually need to look at. On Microsoft Azure it is `Reader` plus `Security Reader`. None of these lets me change or delete anything, and this combination is narrower than `ReadOnlyAccess` on Amazon Web Services or `roles/viewer` on Google Cloud, both of which would let me read customer data straight out of storage and the databases, which I do not want and should not have. If read-only is not possible this week, could you instead run three commands and paste me the output? I will send the exact commands.

Copy-pasteable message for code access:

> Could I get read access to the organisation in GitHub or GitLab? Read is enough. I do not need write or admin, and I will not be pushing anything. If org-wide read is a problem, read on the top five most active repositories is a good start.

## The walk

Each step below is small enough to finish in one sitting. Do them in order. After each one, tell the human what you did, what you found, and name the single next step.

**Step 1: The whiteboard session.**
*Goal:* get one engineer to explain the main service out loud while you draw it.
*Do:* book 45 minutes. Draw as they talk. Ask exactly these questions in order: Where does a request first hit our infrastructure? What sits in front of the application? How does the application authenticate a user? Which data stores does it read and write? If we serve more than one customer organisation, what stops a query returning another organisation's rows, and is that one mechanism or a habit? What runs on a schedule or a queue rather than on a request? Which third parties does it call? What is the one part of this system that scares you? Draw it in whatever is fastest: paper, a whiteboard photo, Excalidraw, Mermaid in a text file.
*Verify:* send the drawing to the engineer within 24 hours and ask "what did I get wrong?". Do not proceed until you get a correction or a confirmation.
*Time:* 1 hour with the engineer, 1 hour to redraw.
*Who else is needed:* one senior engineer who owns the main service.

**Step 2: Trace one real request end to end.**
*Goal:* replace the block diagram with a concrete narrative, because the gaps in your understanding only appear when you follow a specific path.
*Do:* pick the most security-relevant action in the product (a login, a payment, an export, a permission change). Write down every hop in order, naming the actual component: DNS resolves to which edge, which load balancer or content delivery network (CDN), which TLS terminator, which service, which authentication check, which authorisation check, which database query, which cache, which audit log entry, which response. Where you do not know a hop, write `UNKNOWN` and keep going.
*Verify:* show the trace to the engineer and count the `UNKNOWN` entries that they can fill in on the spot. If more than three survive, book a second session.
*Time:* 2 to 3 hours.
*Who else is needed:* the same engineer, plus 15 minutes of a platform or infrastructure engineer if there is one.

**Step 3: Draw the trust boundaries on the diagram.**
*Goal:* turn a systems diagram into a security diagram. A trust boundary is any line where the level of trust in the data or the caller changes.
*Do:* draw a line at each of these places, and label what crosses it: the public internet to your edge, your edge to your application, your application to your database, your application to any third party, your corporate network or laptops to production, and your build pipeline to production. For each line, write one sentence: who can send data across it, and what checks it.
*Verify:* every arrow that crosses a boundary has a named authentication mechanism next to it, or is marked `NONE` in red.
*Time:* 1 hour.
*Who else is needed:* nobody, but review with the engineer from step 1.

**Step 4: Enumerate the internet-facing surface.**
*Goal:* know every hostname, endpoint, and bucket that the public can reach, including the ones nobody remembers creating.
*Do:* run the certificate transparency query, the DNS queries, and the cloud load balancer and bucket listings above. Build one table: hostname, what it is, is it meant to be public, who owns it, does it require authentication. Pay specific attention to hostnames containing `staging`, `dev`, `test`, `demo`, `old`, `legacy`, `internal`, `admin`, `grafana`, `kibana`, `jenkins`, `metabase`, `airflow`.
*Verify:* for each hostname you believe requires authentication, run `curl -sI` and confirm the status code is 401, 403, or a redirect to a login page rather than 200.
*Time:* half a day.
*Who else is needed:* nobody to discover. An engineer to confirm ownership of anything surprising.

**Step 5: Map where customer data lives and who can reach it.**
*Goal:* answer "where is the data" precisely, because every compliance cell and every incident depends on this answer.
*Do:* list every data store from steps 1 to 4. For each: what customer data is in it, is it encrypted at rest, who can read it (humans by name, machine identities by role name), and how would you know if someone did. Include the non-obvious ones: the data warehouse, the analytics product, the customer support tool, the error tracker (which frequently captures full request bodies), log aggregation, backups, and any spreadsheet an operations person maintains.
*Verify:* pick one data store and enumerate its readers with a real command. On AWS, look at the bucket policy and the identity and access management (IAM) roles with access. On GCP, run `gcloud storage buckets get-iam-policy gs://BUCKET`. On Azure, check role assignments in the portal under the storage account's Access Control. Compare the machine answer to the human answer. The gap is the finding.
*Time:* 1 day.
*Who else is needed:* whoever runs data or analytics, and the customer support lead.

**Step 6: The crown jewels exercise.**
*Goal:* force a ranking, because "everything is important" is the same as "nothing is important" and you cannot sequence work without one.
*Do:* ask the founder or CTO this exact question: "Name the five things that, if an attacker got them, would end this company." Write their five down. Then write your own five from steps 1 to 5. Compare the lists in a 30 minute meeting. The disagreements are the most valuable output of this entire cell.
*Verify:* the agreed list of five is written in `SECURITY-STATE.md` and each item names the system it lives in from step 5.
*Time:* 1 hour of prep, 30 minutes of meeting.
*Who else is needed:* the CTO or founder. This must not be delegated.

**Step 7: Map every third party that receives customer data.**
*Goal:* your security boundary includes every vendor your application talks to, and every one of them will appear on a customer questionnaire as a sub-processor.
*Do:* three sources, combined. From code: grep for outbound base URLs and SDK imports. From DNS: the `TXT` verification records from the discovery step. From finance: ask for the corporate card statement and the accounts payable list for the last twelve months. For each vendor, record: what data it receives, whether that includes personal data, who owns the relationship, and whether the integration uses an API key or an OAuth grant.
*Verify:* cross-check your list against the company's published sub-processor list if one exists. Every mismatch is either a missing disclosure (a compliance problem) or shadow IT (a security problem).
*Time:* 1 day.
*Who else is needed:* finance or operations for the card statement, 20 minutes.

**Step 8: Publish the asset inventory and the explain-it-back loop.**
*Goal:* make the model durable and get it validated by someone who was not in the room.
*Do:* write the diagram, the trace, the surface table, the data store table, the crown jewels list, and the vendor list into `SECURITY-STATE.md`. Then run the explain-it-back loop: present the architecture to a second engineer who did not help you build it, from memory, out loud, in under ten minutes. Ask them to interrupt whenever you say something wrong.
*Verify:* record in `SECURITY-STATE.md` the names and dates of the two engineers who confirmed the model. Two independent confirmations is the bar. One is a shared misunderstanding.
*Time:* half a day plus one 30 minute session.
*Who else is needed:* a second engineer, ideally from a different team.

## Decision points

**How deep do you go before moving on?**
DEFAULT: stop at the level of "every component that touches customer data, named, with its trust boundaries". Do not model internals of individual services. Change this if the company is a single monolith with fewer than ten components, in which case go one level deeper because it is cheap.

**Do you write code to learn the stack?**
Evan Johnson's original advice was that to influence how software is built, you should build software. DEFAULT for a hands-on first security engineer: yes, ship one small real thing in the first month, ideally a security-useful tool that runs in the company's own pipeline, because it teaches you the build system, the review culture, and the deploy path in a way no meeting will. Change this if the human was hired as a head of security or CISO with executive scope, in which case the same time is better spent on the crown jewels conversation and on relationships. Johnson said this directly: "If you're hired as a CISO, it might not be the best thing for you to spend your time on."

**Diagram tool?**
DEFAULT: a Mermaid diagram in a markdown file inside the repository, because it is version controlled, diffable, reviewable in a pull request, and free. Change this if the company already standardises on a diagramming tool that engineers actually open, in which case use theirs. Never let the choice of tool delay the diagram by more than a day.

**Automated asset discovery tooling?**
DEFAULT: no, not yet. The cloud provider's own inventory (AWS Resource Explorer, GCP Cloud Asset Inventory, Azure Resource Graph) plus certificate transparency covers most of the surface for free. Change this if the company has more than five cloud accounts or more than three clouds, where the manual approach stops scaling and an attack surface management product starts paying for itself.

**How far do you take the tenant isolation question in this cell?**
DEFAULT: document only. Write down the tenancy shape, the enforcement mechanism, and the bypass list, take the three highest-confidence unscoped-fetch leads to the engineer who owns the code, and stop. Redesigning a data access layer is a quarter of engineering work and it is not yours to start in week two. Change this if enforcement turns out to be per-query discipline across a schema small enough that a central mechanism is genuinely cheap (fewer than roughly twenty tenant-scoped tables, one service, one team), in which case propose the central mechanism as a design review item through `se-1-sdlc-and-design-reviews.md` rather than doing it yourself. Proving isolation actually holds is a separate, authorised activity and it also lives in SE-1.

**Do you fix what you find while discovering?**
DEFAULT: no. Write it in `RISK-REGISTER.md` and keep discovering. Changing things while you are still learning the system is how a new hire causes an outage in week one. Change this only for an actively exploitable public exposure, for example an unauthenticated admin panel or a public bucket containing customer data, which becomes an incident and follows the DR-1 process rather than this one.

## Danger zone

Every action here requires an explicit human yes before running. State the stop, name the risk, wait.

- **Scanning, probing, or brute-forcing hostnames, including your own company's.** Risk: you trip your own alerting and become the incident, you breach a cloud provider's acceptable use policy, or you take down a fragile staging environment. Also, if a hostname turns out to belong to a customer or a vendor rather than to you, this becomes unauthorised access to someone else's system. Get written authorisation from the CTO first, in a message you keep.
- **Trying a cross-tenant request to see whether the check is really missing.** Even one substituted identifier against a live system is an access attempt, and against production it is an access attempt on real customer data using an account that has your name on it. It will look identical to an attack in the logs, it may be a reportable event, and if the tenant you reached belongs to a customer it is unauthorised access to their data regardless of who owns the server. Everything in the tenant isolation section above is source code reading precisely so that it does not require this. The only sanctioned way to actually test is the authorized cross-tenant access test in `se-1-sdlc-and-design-reviews.md`: two tenants you created yourself, on staging, with written authorisation recorded first. STOP and get a yes.
- **Assuming a production role, running any command that writes, or changing IAM policy to grant yourself access.** Risk: outage, and a permanent trust cost. Ask for the access instead of taking it, and log the request in `ACCESS-LOG.md`.
- **Running `kubectl` against a production context when your terminal defaults to it.** Risk: a mistyped `get` becomes a `delete`. Confirm the context with `kubectl config current-context` before every session, and prefer a read-only kubeconfig.
- **Dumping or querying production data to "see what is in there".** Risk: you have now personally exfiltrated customer data to a laptop, which is a reportable event under most privacy regimes and will look identical to an attacker's activity in the logs. Ask for a schema and a redacted sample instead.
- **Enabling cloud services during discovery.** Enabling AWS GuardDuty, GCP Security Command Center Premium, or Azure Defender for Cloud costs real money, sometimes thousands of dollars a month at data volume. These are good controls and belong in DR-2, but the enable button is a spend decision that needs a human yes.
- **Publishing the architecture diagram or the crown jewels list somewhere broadly readable.** Risk: you have just written an attacker's target list and put it in a public Notion page or a shared drive with link sharing on. Store these in a restricted location and note where in `SECURITY-STATE.md`.
- **Naming the "scariest part of the system" in a channel where the engineer who built it can read it out of context.** Risk: you lose the person whose cooperation this entire cell depends on. Aggregate and de-personalise before anything leaves your notes.

## Do not do this yet

- Do not build a formal threat model per service. STRIDE workshops for eight services will consume a month and produce a document nobody reads. One diagram with trust boundaries gets you 80 percent of the value.
- Do not buy an attack surface management or cloud security posture product in week one. You do not yet know enough to evaluate one, and a tool bought before understanding produces a dashboard of findings you cannot triage.
- Do not try to reach completeness. The long tail of dormant repositories, retired subdomains, and abandoned cloud projects is real and worth cleaning eventually, but it is not what will breach you this quarter.
- Do not open findings as tickets on engineering teams during discovery. You will burn your first impression on a bug tracker flood. Collect, rank in `RISK-REGISTER.md`, and bring the top three with a proposed fix.
- Do not write a 40 page architecture document. Nobody will read it and it will be wrong in six weeks. One page, in the repository, updated when things change.
- Do not rely on the existing wiki. Read it, then verify every claim in it against a live command or a human. Stale documentation is worse than none because it is confidently wrong.

## Evidence to capture

Write into `SECURITY-STATE.md`, section `SE-2 Understanding your tech stack`:
- Status per sub-item (architecture diagram, request trace, internet-facing surface, data store map, crown jewels, third-party map) as `unknown`, `none`, `partial`, or `done`.
- The path or link to the diagram, and the date of its last verification.
- The names and dates of the two engineers who confirmed the model (the explain-it-back loop).
- The tenancy model in four lines: shape, where the tenant identifier comes from, central or per-query enforcement and by which mechanism, and the named bypass paths. Or the written sentence that the product is not multi-tenant, with the reason.
- The asset inventory tables themselves, or a link to where they live if they are too large.

Write into `RISK-REGISTER.md`: every exposure found during discovery, with severity, the system it affects, the owner, and whether it is accepted or open. Publicly reachable non-production environments, publicly readable buckets, and databases with `PubliclyAccessible: true` go straight to the top.

Write into `DECISION-LOG.md`: the crown jewels ranking, dated, with the name of the executive who agreed to it. This is the decision that justifies your sequencing for the next two quarters, and you will be asked to defend it.

Write into `ACCESS-LOG.md`: each access request made, the exact role or permission requested, who approved or denied it, and the date.

Artifacts a future auditor or enterprise customer will ask for, by name: a current network or architecture diagram, a data flow diagram showing where personal data goes, an asset inventory, and a sub-processor list. All four are direct outputs of this cell, which is why doing it in week one pays for itself twice.

## Cost and effort

Four to seven working days of your time spread over the first two weeks, plus roughly three hours of other people's time in total (one 45 minute whiteboard, two 30 minute reviews, one 30 minute crown jewels meeting, and 20 minutes from finance).

Dollar cost: zero. Every tool in this cell is free or already paid for. The cloud provider inventory services (AWS Resource Explorer, GCP Cloud Asset Inventory, Azure Resource Graph) are included. Certificate transparency search via crt.sh is free. Mermaid and Excalidraw are free. `dig`, `curl`, and the cloud CLIs are free.

If you later want to spend: a cloud security posture management product with asset inventory built in runs roughly 1,000 to 5,000 US dollars a month at startup scale, and an external attack surface management product roughly 500 to 2,000 US dollars a month. Neither is justified before you have done the manual version once, and the free alternatives (Prowler or ScoutSuite for cloud posture, certificate transparency plus DNS for external surface) are genuinely adequate at 20 to 100 people.

## 2026 notes

The 2019 cell said "understanding your tech stack" and meant the code your engineers wrote. Four things changed that widen the scope of this cell without changing its method:

1. **The build pipeline is part of the stack, and it is usually the most privileged thing you own.** When you enumerate components, include the continuous integration system as a first-class component with its own trust boundary. It executes third-party code by design, holds deploy credentials, and has no human watching it. Ask explicitly: what can our build system deploy to, and who can change what it runs? See `07-modern-cells.md`.
2. **Most of the code you run is code you did not write.** The dependency tree is part of the stack. Note the package manager, the registry, and whether there is any private proxy between developers and the public registry, because that is your only kill switch when a malicious package ships.
3. **Your crown jewels are probably not in your database.** For most startups in 2026 the highest-value data sits in software-as-a-service tools: the customer relationship management system, the support desk, the data warehouse, the shared drive, the chat archive. Your architecture diagram must include these, and the OAuth grants that connect them to each other, or it describes a system that stopped being where the risk is. See `07-modern-cells.md` and `cs-1-identity-and-access.md`.
4. **If the product calls a language model, the model is a trust boundary.** Mark on the diagram: what untrusted text reaches the model, what private data the model can read, and what outbound channels it can use. Any two of those three is usually manageable. All three together is an exfiltration path. Also enumerate internal agent tooling, because an agent with tool access is a new class of privileged identity that no asset inventory template from 2019 accounts for.

One thing did not change: the fastest route to an accurate model is still an hour with an engineer and an honest question, not a document.

## Failure modes

**You document the intended architecture instead of the deployed one.** Early tell: your diagram has no boxes labelled "legacy", "the old one", or "we are migrating off this". Every real company has at least one. Recovery: ask "what is the oldest thing still running in production?" and follow the answer.

**The engineer performs the architecture rather than describing it.** Early tell: everything sounds clean, every service has a clear owner, and there are no embarrassing parts. Recovery: ask "what would you fix if you had a free month?" and "what breaks most often?". People describe reality when you ask about pain rather than about design.

**You gather everything and publish nothing.** Early tell: it is day fifteen and the diagram is still in your notes because it is not finished. Recovery: publish the incomplete version today with `UNKNOWN` markers visible. An incomplete diagram in a shared place attracts corrections. A perfect diagram in your notebook helps nobody.

**Discovery becomes a permanent activity.** Early tell: week five and you are still enumerating, with no risk in `RISK-REGISTER.md` assigned an owner. Recovery: hard-stop the discovery at the end of week two and move to the highest-ranked crown jewel, per `03-90-day-plan.md`.

**You find something bad and react at the wrong volume.** Early tell: you posted a public bucket finding in the company-wide channel before telling the owner. Recovery is expensive and mostly social. Prevention: tell the owner first, give them a fix window, then escalate through `dr-4-company-comms-channel.md` if the window passes.

**You document the tenant model and treat that as isolation.** Early tell: `SECURITY-STATE.md` says row level security is enabled and nobody has ever confirmed that a request for another tenant's record actually fails. Documentation records what the code intends. Recovery: run the authorized cross-tenant access test in `se-1-sdlc-and-design-reviews.md` on staging, with authorisation recorded first, and attach the result as the evidence. Until then the status of this sub-item is `partial`, not `done`.

**You mistake the diagram for security.** Early tell: the diagram is beautiful and nothing has changed. The output of this cell is not the diagram, it is the ranked crown jewels list that tells you where to work next. If step 6 has not happened, this cell is not done.

## Related cells

- [SE-1: SDLC and design reviews](se-1-sdlc-and-design-reviews.md), the relationship this cell builds is what makes design reviews possible, and the authorized cross-tenant access test that proves the isolation this cell only documents.
- [SE-3: Secrets and keys](se-3-secrets-and-keys.md), the asset inventory tells you where secrets need to exist.
- [SE-4: Bug bounty and disclosure](se-4-bug-bounty-and-disclosure.md), never open a program before you know your own internet-facing surface, and broken object-level authorization is the report you are most likely to receive.
- [SE-5: Consumer account security](se-5-consumer-account-security.md), where the per-user version of the object-level authorization question lives.
- [09: Outsourced engineering](09-outsourced-engineering.md), when the stack knowledge and the source code live inside an agency rather than inside the company.
- [DR-1: Incident response plan](dr-1-incident-response-plan.md), the diagram is the map you will use at 2am.
- [DR-2: Top security signals](dr-2-top-security-signals.md), you cannot choose signals without knowing the components.
- [CO-4: Data inventory and framework choice](co-4-data-inventory-and-framework.md), the data store map is the first half of the data inventory.
- [CS-1: Identity and access management](cs-1-identity-and-access.md), the "who can reach it" half of step 5 lives here too.
- [07: Modern cells](07-modern-cells.md), supply chain, build pipeline, cloud posture, software-as-a-service sprawl, and language model surface.
- [06: 2019 to 2026 delta](06-2019-to-2026-delta.md), why the domain boundaries moved.
- [01: Recon](01-recon.md), the general environment discovery playbook this cell specialises.
- [03: The 90 day plan](03-90-day-plan.md), where this cell sits in the sequence (week one).
