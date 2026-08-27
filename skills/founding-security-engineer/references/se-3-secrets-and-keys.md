# SE-3: How you manage secrets, API keys, and customer secrets

> **Grid coordinate:** SE-3, Security Engineering domain.
> **Original 2019 wording (Evan Johnson, OWASP AppSec California 2019, "Starting Security at a Startup"):** "How you manage secrets, api keys, customer secrets." His speaker note for this cell: "take inventory on all of your really critical assets... If you run on AWS, do you have engineers with AWS API Keys running on their laptops? Holy cow."
>
> **Load when:** the human asks about secrets, application programming interface (API) keys, credentials, `.env` files, a secrets manager, key rotation, a leaked key, a secret found in git, hardcoded credentials, HashiCorp Vault, a key management service (KMS), encryption of customer credentials, or when recon (see `01-recon.md`) found a `.env` file, a `credentials` file, a continuous integration (CI) secret store, or a static cloud access key.
>
> **Boundary with M-1 (software supply chain, in `07-modern-cells.md`):** both cells deal with leaked credentials, so use the exposure path to decide which one is loaded. **This file owns a credential exposed by something a person wrote or committed:** a key in a commit, in a `.env` file, in a configuration file, in a client-side bundle, in a chat message, in a secret store that is too widely readable, or on a laptop. **M-1 owns a credential exposed by a dependency or a build step:** a malicious or compromised package that harvested the environment during install, a poisoned build action or continuous integration step that read the runner's secrets, a stolen package-registry publishing token, or a compromised upstream maintainer account. The distinction matters because the response differs: a committed key is rotated and the commit path is fixed, while a dependency-harvested key means every other secret that was present in that same environment is also assumed stolen, the package or action itself has to be dealt with, and there may be an outbound disclosure duty to your own customers. When both are true, and they often are, work the rotation here and the supply chain containment in M-1 at the same time. If the credential's exposure path is not yet known, start here, and hand over the moment a dependency or a build step turns out to be the source.

## Why this cell exists

A secret is any string that lets whoever holds it act as you. A database password, a cloud access key, a Stripe key, a signing key, a customer's own credentials that they handed you so your product could log into their systems. Almost every startup breach that becomes a public story starts with one of these strings being somewhere it should not be: in a git commit, in a Slack message, in a laptop's home directory, in a JavaScript bundle a stranger can download.

The reason this is the third cell and not the first is that it is the cell where a founding security hire can produce a real, measurable, non-political win in about a week, without needing anyone's permission and without breaking anything. Nobody argues that a live production key in a public repository is fine.

Three problems get conflated under the word "secrets" and they have different owners, different fixes and very different stakes. Keep them separate in your head and in your writing:

- **(a) Our own secrets.** Credentials to our own infrastructure: database, cache, cloud, signing keys. If leaked, we get breached.
- **(b) Credentials to third parties.** Our keys to Stripe, Twilio, SendGrid, an email provider, a data warehouse. If leaked, we get billed, spoofed, or used as a spam relay, and the third party may cut us off.
- **(c) Secrets our customers gave us to hold.** Their cloud keys, their OAuth refresh tokens, their SFTP passwords, so our product can act on their behalf. If leaked, **we breached them**, we owe notification, and we probably violated a contract. This is a materially higher bar than (a) and (b) and needs encryption design, not just a password manager.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] One written inventory of every secret store in use, with an owner per store, recorded in `SECURITY-STATE.md` under SE-3.
- [ ] Full git history of every repository scanned for secrets at least once, with results triaged into "live", "dead", "false positive".
- [ ] Every secret confirmed live from that scan is rotated, and the rotation is verified, not assumed.
- [ ] Secret scanning runs on every push or pull request, and blocks or at least alerts. Free tier is fine.
- [ ] A pre-commit hook available to engineers who want it. Optional adoption is acceptable at this size; the server-side check is the one that has to be mandatory.
- [ ] No long-lived static cloud access keys in continuous integration. Continuous integration authenticates to the cloud with short-lived federated credentials.
- [ ] Human engineers get cloud access through single sign-on with short-lived sessions, not through a static key file on a laptop.
- [ ] One chosen secrets manager per environment, documented, with a written "how do I add a new secret" paragraph an engineer can follow without asking you.
- [ ] Zero secrets in client-side code: web bundles, mobile app binaries, published source maps.
- [ ] If you hold customer secrets: they are encrypted with a key you do not store next to them (envelope encryption), access to decrypt is logged, and you can answer "who decrypted tenant X's credential last month" in under an hour.
- [ ] A one-page leaked-key runbook that a non-security engineer can execute at 2am.

Explicitly **not** required at this stage: HashiCorp Vault with dynamic database credentials; a hardware security module; per-request secret leasing; automated rotation of every secret on a 30 day timer; a formal cryptographic key management policy document; secrets scanning of Slack and Jira history; a paid secret scanning platform. Every one of those is a real control, and every one of them is a trap for a solo hire in the first quarter.

## Discovery

Start read-only. Nothing in this section changes state.

### Step 1: find secret stores in the repository you are standing in

```bash
# What are we even looking at
ls -la
git rev-parse --is-inside-work-tree 2>/dev/null && git log -1 --format='%H %ad %an' 

# Files that usually hold secrets, tracked or not
find . -maxdepth 4 \( -name '.env*' -o -name '*.pem' -o -name '*.key' -o -name '*.p12' \
  -o -name 'credentials' -o -name 'secrets.y*ml' -o -name '*serviceaccount*.json' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null

# Are any of them actually committed (this is the bad case)
git ls-files | grep -Ei '(^|/)(\.env|credentials|secrets?)(\.|$)|\.(pem|p12|pfx|key)$'

# Is .gitignore doing its job
grep -nE '\.env|\.pem|credentials' .gitignore 2>/dev/null || echo "no .gitignore protection"
```

### Step 2: scan history with a free scanner

Deleting a file in a later commit does not remove it from history. `git log -p` still shows it, GitHub still serves it by commit SHA, and every clone on every laptop still has it. History scanning is therefore mandatory, and history rewriting is almost never the fix. Rotation is the fix. Say this to engineers every single time, because "I deleted it" is the most common wrong answer you will hear.

```bash
# gitleaks (free, MIT licensed). Newer versions (v8.19+) prefer 'git'/'dir' subcommands.
gitleaks git . --report-format json --report-path /tmp/gitleaks.json --redact
# Older versions:
gitleaks detect --source . --report-format json --report-path /tmp/gitleaks.json --redact
jq -r '.[] | "\(.RuleID)\t\(.File):\(.StartLine)\t\(.Commit[0:8])\t\(.Date)"' /tmp/gitleaks.json | sort | uniq

# TruffleHog (free, AGPL). Its differentiator is live credential verification.
# Detection only, no network calls to any provider. Safe to run anywhere, on anything.
trufflehog git file://. --no-verification --json > /tmp/th-detected.json
jq -r '.DetectorName + "\t" + .SourceMetadata.Data.Git.file' /tmp/th-detected.json | sort -u

# STOP before adding --only-verified. Verification is an authenticated call to the
# provider using the found credential, so it is NOT passive and it lands in someone's
# audit log. Run it only after the ownership check in the "I found a key" decision tree
# below, only against credentials that are ours, and only with an explicit human yes.
trufflehog git file://. --only-verified --json > /tmp/th.json
jq -r '.DetectorName + "\t" + (.Verified|tostring) + "\t" + .SourceMetadata.Data.Git.file' /tmp/th.json

# detect-secrets (Yelp, free) if the org already uses pre-commit
detect-secrets scan --all-files > /tmp/baseline.json
```

Run both gitleaks and TruffleHog. gitleaks has better regex coverage and speed; TruffleHog can tell you whether the credential still works, which is the main thing that determines urgency.

Be precise about which half of TruffleHog is passive. Detection is passive: it reads your repository and matches patterns, and nobody outside the company learns anything. Verification is not passive: TruffleHog calls the provider with the found credential to see whether it authenticates, which is a live network call made with an identity that may not be yours. Run detection first, always and freely. Run verification only after step 2 of the decision tree below has established that the credential belongs to your own company, and never against a credential belonging to a customer, a vendor, or an unknown owner without written permission from that owner. If in doubt, skip verification and treat the credential as live.

### Step 3: enumerate cloud and CI secret stores, branched by vendor

**Amazon Web Services (AWS)**

```bash
aws sts get-caller-identity                       # who am I right now
aws iam list-users --query 'Users[].UserName' --output text
# Static keys are the thing you are hunting. Any output here is a finding.
for u in $(aws iam list-users --query 'Users[].UserName' --output text); do
  aws iam list-access-keys --user-name "$u" \
    --query 'AccessKeyMetadata[].[UserName,AccessKeyId,Status,CreateDate]' --output text
done
aws iam get-access-key-last-used --access-key-id AKIAEXAMPLE   # is it actually used
aws secretsmanager list-secrets --query 'SecretList[].[Name,LastAccessedDate]' --output text
aws ssm describe-parameters --query 'Parameters[?Type==`SecureString`].Name' --output text
```

**Google Cloud Platform (GCP)**

```bash
gcloud auth list
gcloud projects list
gcloud iam service-accounts list --project PROJECT_ID
gcloud iam service-accounts keys list --iam-account SA@PROJECT.iam.gserviceaccount.com \
  --managed-by=user     # user-managed keys are downloadable JavaScript Object Notation (JSON) files. These are the risk.
gcloud secrets list --project PROJECT_ID
```

**Microsoft Azure**

```bash
az account show
az keyvault list --query '[].{name:name,rg:resourceGroup}' -o table
az keyvault secret list --vault-name VAULTNAME -o table     # requires data-plane permission
az ad app credential list --id APP_ID_OR_OBJECT_ID -o table  # client secrets and their expiry
```

**GitHub**

```bash
gh auth status
gh secret list --repo ORG/REPO                     # names only, values are never readable
gh secret list --org ORG
gh variable list --repo ORG/REPO                   # people put secrets in variables. Check.
gh api /repos/ORG/REPO/actions/secrets --jq '.secrets[].name'
# Is secret scanning actually ON for this repository (not a billing question, an enablement question)
gh api "/repos/ORG/REPO" --jq '.security_and_analysis'   # secret_scanning and secret_scanning_push_protection status
```
Console path for secret scanning status: Repository or Organization, Settings, Code security. Look for "Secret scanning" and "Push protection".

**GitLab**

```bash
glab auth status
glab variable list --repo GROUP/PROJECT
glab api "projects/:id/variables" | jq -r '.[].key'
glab api "groups/GROUP_ID/variables" | jq -r '.[].key'
```
Console path: Project, Settings, CI/CD, Variables. Check the "Masked" and "Protected" columns. Unmasked variables print into job logs.

**Platform-as-a-service and hosting**

```bash
vercel env ls                       # Vercel
netlify env:list                    # Netlify
heroku config -a APP                # Heroku, prints values, use in private terminal only
fly secrets list -a APP             # Fly.io, names only
railway variables                   # Railway
kubectl get secrets -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,TYPE:.type
```
Note on Kubernetes: `kubectl get secret X -o yaml` returns base64, which is encoding, not encryption. If anyone tells you Kubernetes secrets are encrypted, ask whether encryption at rest for etcd was explicitly enabled. It usually was not on a self-managed cluster.

### Step 4: client-side exposure check

```bash
# Web bundle: build first, then grep the output directory, not the source
grep -rEo '(AKIA[0-9A-Z]{16}|sk_live_[A-Za-z0-9]{10,}|AIza[0-9A-Za-z_-]{35}|ghp_[A-Za-z0-9]{36})' dist/ build/ .next/ 2>/dev/null | sort -u
# Framework prefixes that mean "this WILL ship to the browser"
grep -rEn '(NEXT_PUBLIC_|VITE_|REACT_APP_|PUBLIC_|EXPO_PUBLIC_|NUXT_PUBLIC_)[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD)' . --include='*.env*' --include='*.ts' --include='*.js' 2>/dev/null
# Are source maps published
find dist build .next -name '*.map' 2>/dev/null | head
# Mobile: strings on the built artifact
unzip -p app.apk classes.dex 2>/dev/null | strings | grep -Ei 'api[_-]?key|secret|bearer ' | head
strings MyApp.app/MyApp 2>/dev/null | grep -Ei 'sk_live|AKIA|api[_-]?key' | head
```

### If you have no access at all

You will often be in an empty directory or on day two with no cloud console. Do not stall. Do this instead:

1. Ask for read-only access using the template below and log the request in `ACCESS-LOG.md`.
2. Meanwhile, do the paper version: sit with one engineer for 30 minutes and have them narrate how a secret gets from a person's head into production. Write down every hop. That flow diagram is the deliverable, and it is often more revealing than a scan.
3. Record every unanswered question as status `unknown` in `SECURITY-STATE.md` under SE-3. Unknown is a legitimate, honest status. Fabricated confidence is not.

## Ask the human

Closed questions, in this order. Do not ask more than three at a time.

1. Where does production get its database password from today: environment variables set by the hosting platform, a cloud secrets manager, a file on the server, or nobody knows?
2. Does any engineer have a long-lived cloud access key file on their laptop right now (`~/.aws/credentials`, a downloaded service account JSON, an `az` client secret)? Yes, no, or unsure?
3. Does our product store credentials that customers give us so we can act on their systems? Yes or no. If yes, name the single most sensitive type.
4. Has anyone ever scanned the git history of our repositories for secrets? Yes, no, or unsure?
5. If we had to rotate the main database password right now, who would do it, and would production go down while they did?
6. Is secret scanning enabled on our source host, and does it block pushes or only send an email?

Copy-pasteable message for the human to send to the engineering lead or head of platform:

> Hi, I am doing the first inventory of how we handle secrets and API keys. Three small asks, all read-only, nothing changes:
>
> 1. Read-only access to the cloud account so I can list identities and secret stores myself instead of interrupting you. Please use the narrow security-review roles rather than a blanket read-only role: on Amazon Web Services `SecurityAudit` plus `ViewOnlyAccess`; on Google Cloud `roles/iam.securityReviewer` plus `roles/browser` plus any service-specific viewer role I turn out to need; on Azure `Reader` plus `Security Reader`. I am deliberately not asking for the broad read-only roles, because `ReadOnlyAccess` on AWS and `roles/viewer` on Google Cloud both include bulk read of object storage and database contents, which means they would let me read customer data. I do not need that and I would rather not have it.
> 2. Read access to all repositories, and confirmation of whether secret scanning and push protection are turned on.
> 3. Fifteen minutes to walk me through how a new secret gets added to production today, start to finish.
>
> What I am trying to prevent is the boring version of a breach: a key committed a year ago that still works. I am not auditing anyone, and I will bring you findings before I bring them to anyone else.

Copy-pasteable message when a live key has been found (send to the owning engineer, not to a broad channel):

> I found a credential that appears to still be live: [provider], committed [date], in [repo]. It needs to be rotated today. I am not going to touch it, because you know the blast radius and I do not. Can we get 20 minutes in the next few hours to rotate it together? I will drive the checklist and write it up so the next one is faster. Please do not delete the commit; that does not fix anything, and it makes the timeline harder to reconstruct.

## The walk

**Step 1. Scan one repository and produce a triaged list.**
Goal: have a real finding in hand on day one instead of an opinion. Do: run gitleaks and TruffleHog per Discovery on the single most important repository. Verify: you have a list where each row is classified live, dead, or false positive, and you can name the top three by blast radius. Time: 2 to 4 hours. Who else: nobody.

**Step 2. Rotate the worst confirmed-live secret, with its owner.**
Goal: prove the rotation path works before you need it in an incident. Do: follow the rotation runbook below with the engineer who owns the system. Verify: the old credential returns an authentication error, the new one works, and the application is healthy. Time: half a day. Who else: the owning engineer, and whoever can roll back a deploy.

**Step 3. Turn on server-side secret scanning with push protection.**
Goal: stop the bleeding so you are not scanning forever. Do: GitHub, Settings, Code security, enable Secret scanning and Push protection (free on public repositories; on private repositories this is the paid GitHub Secret Protection product). GitLab Ultimate, Settings, Security and Compliance, enable Secret push protection. If neither is licensed, add gitleaks as a CI job on pull requests. Verify: push a branch containing a deliberately fake but correctly formatted test token (use a documented canary value, never a real one) and confirm it is blocked or flagged. Time: 1 to 3 hours. Who else: whoever owns the source host organization settings.

**Step 4. Write the inventory and the "how do I add a secret" paragraph.**
Goal: make the right path the easy path. Do: one page in the engineering wiki naming the one place secrets go per environment, and the exact three commands to add one. Verify: an engineer who has never done it adds a secret using only your page. Time: 2 hours. Who else: one engineer to test it.

**Step 5. Kill static cloud keys in continuous integration by moving to short-lived federated credentials.**
Goal: remove the single most valuable long-lived credential in the company. Do: see the OpenID Connect (OIDC) federation section below. Verify: the deploy job succeeds, and the static key it used to use is deleted and confirmed dead. Time: 1 day. Who else: whoever owns CI and cloud identity and access management (IAM). This is the highest-value single day of work in this whole cell.

**Step 6. Kill static cloud keys on laptops.**
Goal: an infostealer on a laptop should not yield production. Do: move engineers to single sign-on based cloud access (`aws configure sso` then `aws sso login`; `gcloud auth login` with short-lived tokens; `az login`). Deactivate then delete the old keys after a soak period. Verify: `aws iam list-access-keys` returns nothing for human users. Time: 2 to 4 days across the team. Who else: every engineer, so socialise it a week ahead.

**Step 7. Client-side sweep.**
Goal: nothing secret ships to a browser or a phone. Do: run the client-side checks above against a real build artifact. Verify: zero matches, and any provider key that must ship is confirmed to be a publishable key with server-side restrictions. Time: half a day. Who else: a frontend or mobile engineer.

**Step 8. Only if the product holds customer secrets: envelope encryption review.**
Goal: raise the bar on the class of secret whose loss means notifying other companies. Do: see the customer-secrets section below. Verify: you can show where the key encryption key lives, that it is not in the same database as the ciphertext, and that decryption is logged. Time: 2 to 5 days of engineering, not yours. Who else: a backend engineer and the product owner.

**Step 9. Write the leaked-key runbook and rehearse it once for 20 minutes.**
Goal: at 2am, nobody improvises. Do: one page, the decision tree below, per-provider rotation links. Verify: an engineer who was not involved can read it and describe the first three actions. Time: 3 hours. Who else: one engineer for the rehearsal.

## Rotation: why it is harder than detection, and the safe ordering

Finding a secret takes a scanner. Rotating it takes knowing every consumer of it, and nobody has that list. The classic outage is: security rotates a key at 4pm, a nightly batch job that nobody remembered still has the old value, and the data pipeline is silently broken until Monday.

Use this ordering. It is designed so that no step alone can take production down.

1. **Enumerate consumers before touching anything.** Grep the whole organization for the secret's variable name, not its value: `gh search code --owner ORG "STRIPE_SECRET_KEY"` or `glab api "search?scope=blobs&search=STRIPE_SECRET_KEY"`. Ask in the engineering channel: "who reads STRIPE_SECRET_KEY?" Assume you missed one.
2. **Create the new credential alongside the old one.** Almost every provider supports two live credentials at once. AWS allows two access keys per user. Stripe supports rolling a key with a grace period. This is what makes the whole thing safe.
3. **Deploy the new value to every consumer.** Include the ones you found in step 1 and the surprises from step 2.
4. **Watch, do not delete.** Give it one full business cycle, usually 24 hours, so nightly jobs run.
5. **Disable the old credential, do not delete it.** AWS: `aws iam update-access-key --access-key-id AKIA... --status Inactive --user-name USER` (mutating). GCP: `gcloud iam service-accounts keys disable KEY_ID --iam-account SA@...` (mutating). Disabling is instantly reversible; deletion is not.
6. **Wait, then delete.** Another 24 to 72 hours, then `aws iam delete-access-key` / `gcloud iam service-accounts keys delete` (both mutating and irreversible).
7. **Verify the old one is dead.** Try to use it. `AWS_ACCESS_KEY_ID=old AWS_SECRET_ACCESS_KEY=old aws sts get-caller-identity` must fail. If you did not try, you did not verify.
8. **Record it.** Date, secret, reason, who rotated, verification evidence, into `DECISION-LOG.md`, and flip the SE-3 row in `SECURITY-STATE.md`.

The one exception to this careful ordering is a credential that is confirmed live and confirmed publicly exposed. Then you invert it: disable first, apologise for the outage second. Say that out loud to the owning engineer before you do it, and get a yes.

## The "I found a key" decision tree

Run this in order. Do not skip to rotation.

1. **Is it real, or a test fixture, example, or placeholder?** Look at the value: `sk_test_`, `AKIAIOSFODNN7EXAMPLE`, `changeme`, `xxxx`. If placeholder, mark false positive in the scan baseline and stop.
2. **STOP before you test it: whose credential is this?** Testing a credential is not a passive act. It makes an authenticated call to the provider using someone's identity, and it lands in someone's audit log, from your address, at a timestamp you will later have to explain. Establish ownership first, from the value's shape, the file path, the variable name, and the surrounding code:
   - **Ours** (category (a) or (b) from the top of this file, our own infrastructure or our own third party account): you may test it, using the read-only calls in step 3.
   - **A customer's** (category (c), a credential a customer gave us, or any credential whose account belongs to another company): **do not test it.** A live call into another company's system with a credential you were not authorised to use is at best a contract violation and in several jurisdictions a criminal one. `01-recon.md` states the same rule: never touch third-party systems.
   - **A vendor's, a partner's, or you cannot tell:** treat it exactly as a customer's. Unknown ownership means do not test.

   For anything you must not test, assume it is live, do not verify, escalate to the engineer who owns that integration, and get written permission from the credential's owner before any verification. Written permission means an email or a ticket you can point at later, from someone at the owning company with the authority to give it, naming the credential and the check. If permission is not forthcoming, that is fine: an unverified credential of unknown liveness is simply treated as live, which is the safe assumption anyway, and the finding proceeds to rotation coordinated with the owner. Record the ownership determination and the decision in `DECISION-LOG.md`.

3. **Is it live?** Only for credentials you have established are ours, or for which you hold written permission. Verify with a harmless read-only call: AWS `aws sts get-caller-identity`, Stripe `curl -s -u "KEY:" https://api.stripe.com/v1/balance`, GitHub `curl -s -H "Authorization: token KEY" https://api.github.com/user`, Slack `curl -s -d token=KEY https://slack.com/api/auth.test`. If it fails, mark dead, record it, stop. Do not spend the team's afternoon on a dead key. Note that even a successful read-only call is a logged event: expect to see your own verification in the audit log you read in step 6 below, and label it so you do not later mistake your own check for an attacker.
4. **Where was it exposed?** Public repository or public package or public bundle means treat as compromised immediately. Private repository means treat as compromised if the repository has ever had contractors, ex-employees, or a broad access grant. Local file never committed means it is a hygiene problem, not an incident.
5. **What is the blast radius?** Read-only analytics key with no personal data is low. Anything that can read customer data, spend money, send email as your domain, or grant further access is high. Anything that is a **customer's** credential is automatically high and triggers a possible contractual notification obligation. Check `co-3-existing-commitments.md` for what you already promised.
6. **What did this credential actually do?** Do this before you decide how urgent rotation is, because the answer changes the whole shape of the response. A key that has never been used outside your own deployment pipeline is a hygiene finding. A key that authenticated from an address nobody recognises is a breach, and breaches are worked differently and by different people. All of these reads are read-only and safe.
   - **AWS:** `aws cloudtrail lookup-events --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIA... --start-time 2026-07-01` (adjust the date to at least cover the period since the credential was exposed). Also `aws iam get-access-key-last-used --access-key-id AKIA...` for a fast first answer.
   - **GCP:** `gcloud logging read 'protoPayload.authenticationInfo.principalEmail="SA@PROJECT.iam.gserviceaccount.com"' --limit 50 --freshness 30d`.
   - **Azure:** Microsoft Entra ID sign-in logs filtered by the application, plus the Azure activity log for the subscription.
   - **GitHub:** Organization, Settings, Audit log, filter by actor and by token. **GitLab:** Group, Settings, Audit events.
   - **Software as a service providers (Stripe, Twilio, SendGrid, and similar):** the dashboard has a request or API log. Look at source addresses and at what was called.

   Read three things: the source addresses, the calls made, and the times. Compare them against where your own infrastructure runs and when your jobs run. Remember to exclude your own verification call from step 3. **What you are looking for:** any use from an address or region that is not yours, any call the legitimate consumer never makes (enumeration, bulk reads, creating new identities, changing permissions, disabling logging), any use outside the credential's normal schedule, and any use at all if the credential was never supposed to be used yet.

   If the log is missing or its retention does not reach back to the exposure date, say so plainly. "We cannot tell" is an honest and important answer, and it means you treat the credential as used. Record the gap in `RISK-REGISTER.md` and fix the retention through `dr-3-logging-consumption-model.md`.

   **If it looks like it was used by someone else, this stops being a secrets task.** Do not keep working it as cleanup. Declare an incident under `dr-1-incident-response-plan.md`, and use `dr-0-compromise-assessment.md` to answer the question that actually matters, which is no longer "is this key bad" but "what else did they reach, and how long have they been here". One leaked credential with confirmed unfamiliar use is one of the strongest triggers for a compromise assessment there is, because a credential is a foothold and a foothold is rarely used once. Containment does not wait for that assessment: rotate or disable per the ordering above while the assessment runs in parallel, and preserve the logs by exporting them before any retention window closes.

7. **Rotate now or coordinate?** Rotate now, without waiting, if: public exposure plus live plus high blast radius, or any evidence of use you cannot explain. Coordinate on a same-day call if: private exposure, live, high blast radius. Schedule within the week if: live, low blast radius, private exposure. Note the ordering exception: if the exposure is public, the credential is live, and the blast radius is high, you do not wait for step 6 to finish. Containment first, log reading in parallel, because an attacker reading the same public repository is not waiting either.
8. **Record.** Every finding, even the dead ones, gets a row in `RISK-REGISTER.md` with severity and owner. Every rotation gets a `DECISION-LOG.md` entry.

## Decision points

**Where do secrets live at runtime?**
DEFAULT: use the secret store that is already built into the platform you deploy on. Cloud native manager (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault) if you deploy to that cloud directly; the platform's own store (Vercel, Fly, Railway, Heroku, Render) if you deploy to a platform. Change this only if you have a real multi-cloud footprint, need dynamic short-lived database credentials, or an auditor has explicitly required a dedicated system. Do not deploy HashiCorp Vault as the first security hire. It is excellent and it will consume your quarter, and it introduces a new production dependency that you will be paged for.

**Secrets manager cost sanity check.** AWS Secrets Manager is roughly 0.40 US dollars per secret per month plus API calls; AWS Systems Manager Parameter Store SecureString is free at standard tier and is the correct choice for a startup with a hundred parameters. GCP Secret Manager is a few cents per secret version per month. Azure Key Vault is fractions of a cent per ten thousand operations. Self-hosted Vault is free as software and expensive as operations. Price is almost never the deciding factor here; operational burden is.

**Pre-commit hooks or server-side scanning?**
DEFAULT: server-side is mandatory, pre-commit is offered. Pre-commit hooks are trivially bypassed with `--no-verify` and cannot be enforced on a laptop you do not manage. Ship both, but never claim a control is in place based on a pre-commit hook alone.

**Rewrite git history or just rotate?**
DEFAULT: rotate, do not rewrite. Rewriting history with `git filter-repo` or the BFG Repo-Cleaner breaks every open pull request, invalidates every local clone, and does not touch forks, caches, or the copies already scraped by bots. Rewrite only when the content is a compliance-relevant artifact rather than a credential (customer personal data, a private key you cannot rotate such as a code signing key with a long trust chain), and only with the engineering lead's explicit agreement and a scheduled window.

**Environment variables or mounted files?**
DEFAULT: environment variables injected at runtime by the platform, never a `.env` file committed or baked into a container image. Environment variables have a real weakness: they leak into crash dumps, child processes, logs, and error-tracking payloads. So pair them with scrubbing rules in your error tracker and never log the whole environment. Choose mounted files instead when a secret is large or structured, such as a private key or a service account JSON document.

**One shared secret store for all environments, or one per environment?**
DEFAULT: separate stores or at minimum separate paths and separate access policies for production and non-production, from day one. The most common lateral movement path in a small company is a staging credential that happens to work in production.

## Danger zone

Every action here requires an explicit human yes before you run it. State the risk out loud and wait.

- **Deleting or deactivating any credential.** Can take production down instantly if a consumer you did not find is still using it. Always prefer disable over delete, and always follow the rotation ordering above.
- **Rotating a shared cloud root or organization owner credential.** Can lock every person out of the cloud account. Never do this without a tested break-glass path and a second person present.
- **Rewriting git history.** Breaks everyone's clone and every open pull request. Requires a scheduled window and an announcement.
- **Turning on push protection in blocking mode on a Friday.** Blocks legitimate work. Announce first, enable Monday morning.
- **Verifying any credential you have not established is your own company's.** This covers TruffleHog's `--only-verified` mode and every manual `curl` check. It is a live authenticated call into another organisation's system using a credential you were not authorised to use. That is a contract violation and in several jurisdictions a criminal one, and it puts your address in their audit log. Establish ownership first (decision tree step 2), and for anything that is not ours, do not verify without written permission from the owner. When in doubt, do not verify and treat the credential as live.
- **Posting a found secret value into Slack, a ticket, or a pull request comment.** You have just leaked it again, into a system with a different retention policy and a broader audience. Reference the location and the last four characters only.
- **Deleting the commit or the file "to clean up".** Destroys evidence you may need for the incident timeline, and does not remove the secret.
- **Bulk-disabling all static access keys at once.** Enumerate consumers first, one key at a time, or you will cause a multi-service outage and lose the political capital that funds the rest of your program.

## Do not do this yet

- Do not deploy HashiCorp Vault, dynamic database credentials, or a hardware security module in your first quarter.
- Do not attempt automated rotation of every secret on a schedule before you can manually rotate one secret without an outage.
- Do not buy a commercial secret scanning platform before you have run the free scanners and triaged the output. The free tools will find the same findings; your bottleneck will be remediation, not detection, and no product fixes that.
- Do not scan Slack, Jira, Notion and Confluence for secrets in month one. The volume is enormous, the false positive rate is high, and you have no remediation capacity yet.
- Do not write a Cryptographic Key Management Policy document. Write the one-page runbook instead. The policy can be generated from the runbook later when an auditor asks (see `co-4-data-inventory-and-framework.md`).
- Do not chase every low-severity finding to zero. Rank by blast radius in `RISK-REGISTER.md` and accept the tail explicitly, with a named accepter.
- Do not build your own encryption for customer secrets. Use the cloud key management service.

## Customer-held secrets: the higher bar

If the product stores credentials belonging to customers, this is no longer key hygiene, it is a cryptographic design question, and the failure mode is that you become the source of someone else's breach.

**Target design, plainly.** Do not encrypt every customer's data with one key. Instead: generate a unique data encryption key per tenant (or per secret), use it to encrypt the credential, then encrypt that data encryption key with a master key encryption key that lives in the cloud key management service and never leaves it. Store the encrypted data key next to the ciphertext. This is called envelope encryption. The property you get: the database alone is useless, because the master key is in a different system with a different access policy and its own audit log.

- AWS: `aws kms generate-data-key --key-id alias/tenant-secrets --key-spec AES_256` returns a plaintext key and a ciphertext blob. Use the plaintext key in memory, store the blob, and discard the plaintext immediately. Decrypt with `aws kms decrypt --ciphertext-blob fileb://blob`. Use an encryption context containing the tenant identifier so a blob for tenant A cannot be decrypted while claiming to be tenant B.
- GCP: Cloud KMS, `gcloud kms keys create` then the encrypt and decrypt API, with additional authenticated data carrying the tenant identifier.
- Azure: Key Vault or Managed HSM as the key encryption key, with the same envelope pattern.

**Non-negotiables for this class.**

1. The application role can call decrypt, but no human role can, outside of a documented break-glass path.
2. Every decrypt is logged with tenant identifier, actor, and reason. Cloud key management services emit these to CloudTrail, Cloud Audit Logs, or Azure Monitor by default. Route them into your log store (see `dr-3-logging-consumption-model.md`) and alert on volume anomalies, because bulk decryption is the exfiltration signature.
3. Prefer not holding the secret at all. If the third party supports OAuth, take a scoped, revocable token instead of a password. If they support a delegated role such as an AWS cross-account role with an external identifier, take that instead of an access key. The best-managed secret is the one you never received.
4. Scope what you ask for. If you only need read access to one bucket, do not accept an administrator key because it was easier for the customer.
5. Have a documented per-tenant revocation path, and be able to re-encrypt (rotate the key encryption key) without downtime. Test it once.

## Continuous integration: from static keys to short-lived federated credentials

A long-lived cloud key sitting in your CI secret store is the single most valuable credential in most startups: it can deploy to production, it has no multi-factor authentication, no session limit, and it is exposed to every dependency and every third-party action your build executes. OpenID Connect federation removes it entirely. The CI system presents a signed identity token describing exactly which repository and which branch is running, and the cloud exchanges it for a session that lasts minutes.

- **GitHub Actions to AWS:** create an IAM OIDC identity provider for `token.actions.githubusercontent.com`, create a role whose trust policy conditions on `token.actions.githubusercontent.com:sub` equal to `repo:ORG/REPO:ref:refs/heads/main`, then in the workflow set `permissions: id-token: write` and use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`. Condition on the exact ref, not a wildcard, or any fork or feature branch inherits deploy rights.
- **GitHub Actions to GCP:** Workload Identity Federation pool and provider, `gcloud iam workload-identity-pools create`, with an attribute condition restricting `assertion.repository`.
- **GitHub Actions to Azure:** an app registration with a federated credential whose subject matches the repository and ref, then `azure/login` with `client-id`, `tenant-id` and no client secret.
- **GitLab CI to any of the three:** the `id_tokens:` keyword issues a JSON Web Token (JWT) with a configurable audience; the cloud side is the same as above, with the subject claim referencing the project path and ref.

Verify by running the deploy job and confirming the cloud audit log shows an assumed role session rather than a long-lived key identifier, then disabling the old key per the rotation ordering. Full CI hardening (pinning third-party actions to a full commit hash rather than a tag, splitting build and deploy identities, controlling runner outbound network access) lives in `07-modern-cells.md`.

## Evidence to capture

- `SECURITY-STATE.md`, SE-3 section: every secret store, its owner, status of unknown / none / partial / done, plus the evidence line (the exact command run and the date). Include a one-line count: number of repositories scanned, findings by severity, findings rotated.
- `RISK-REGISTER.md`: one row per live or plausible exposure, with blast radius, owner, decision, and accepted-by if you are accepting it.
- `DECISION-LOG.md`: the secrets manager choice with the reason, the rewrite-or-rotate call, every rotation with its verification evidence.
- `ACCESS-LOG.md`: cloud read-only access requested and granted, source host organization access, secret store read permissions.
- Artifacts an auditor or an enterprise customer will ask for later: proof that secret scanning runs on every pull request (a screenshot of a blocked push, or a CI log), the written secrets management procedure, evidence that customer-held credentials are encrypted at rest with a named key management service, key access logs for a sampled month, and a rotation record showing at least one completed rotation. Prepare these once and reuse them in `co-2-questionnaire-knowledge-base.md`.

## Cost and effort

- Scanning, triage, and the inventory: 3 to 5 days of your time. Cost: zero. gitleaks, TruffleHog and detect-secrets are free.
- Server-side scanning: free on public repositories with GitHub. On private repositories, GitHub Secret Protection is priced per active committer per month (budget roughly 15 to 20 US dollars per committer per month; confirm current pricing before quoting it to a founder). GitLab secret push protection requires Ultimate. Free alternative that is genuinely good enough: gitleaks as a required CI job, which costs only CI minutes.
- Secrets manager: AWS Parameter Store standard tier is free. AWS Secrets Manager is about 0.40 US dollars per secret per month. GCP and Azure are similar or cheaper. For a hundred secrets you are looking at tens of dollars a month, not thousands.
- OIDC federation for CI: about 1 day of engineering time, zero dollars, and it is the best value item in this file.
- Envelope encryption for customer secrets: 2 to 5 days of backend engineering, plus key management service costs of roughly 1 US dollar per key per month plus a fraction of a cent per ten thousand operations.
- Commercial secret scanning and rotation platforms (GitGuardian, Doppler, Infisical, 1Password Secrets Automation, HashiCorp Vault Cloud) start in the low hundreds of US dollars per month. Note that Infisical and Doppler have usable free or cheap starter tiers. Revisit at 100 people or at the first enterprise deal that demands it, not before.

## 2026 notes

- **The credential you lose is increasingly a publishing or build credential, not a database password.** The npm worm campaigns starting in September 2025 harvested developer and CI tokens from laptops and runners and used them to publish poisoned packages. That means a leaked npm token or source-host personal access token is not just your problem: it makes you the origin of a supply chain incident with outbound disclosure duties to your own customers. Add "package registry publish tokens" to your inventory as a first-class category and prefer trusted publishing with OIDC over long-lived publish tokens. See `07-modern-cells.md`.
- **Static keys are now a deliberate anomaly, not a default.** In 2019, an access key file on a laptop was normal. In 2026 the correct baseline is zero long-lived cloud keys anywhere: single sign-on for humans, workload identity for services, OIDC federation for CI. An `AKIA` prefix existing in your organization is itself a finding.
- **Infostealer malware changed the laptop threat model.** Commodity malware sweeps `~/.aws/credentials`, `~/.config/gcloud`, `.env` files, browser cookies and session tokens within seconds of execution. This is why short-lived credentials beat "keep the key file safe", and why this cell is tightly coupled to `cs-2-endpoint-security.md`.
- **AI coding assistants raised secret commit volume.** More code per engineer, more configuration files generated with placeholder-shaped values that sometimes get filled with real ones, and more copy-paste from working examples. Server-side blocking matters more than it did, and your scanner baseline will need pruning more often.
- **Model provider keys are a new spend risk.** A leaked LLM API key is not primarily a data breach, it is a bill. Set hard spend limits at the provider, use per-service keys, and alert on spend anomalies. Treat it like a payment credential.
- **Machine-to-machine secrets for agents and Model Context Protocol servers.** If the company runs internal agents with tool access, those agents hold credentials with human-scale permissions and no human sitting at the keyboard. Inventory them alongside CI. See `07-modern-cells.md`.

## Failure modes

- **You scan, you report, nothing gets rotated.** Early tell: a findings spreadsheet with no owner column, and a second scan a month later showing identical results. Recovery: stop scanning. Pick the top three by blast radius, name an owner per finding in `RISK-REGISTER.md`, and personally sit with each owner until rotated. Three rotated beats three hundred reported.
- **The rotation causes an outage and you lose credibility for a quarter.** Early tell: you skipped consumer enumeration because you were confident. Recovery: post a blameless note describing exactly what you missed, then add "enumerate consumers" as step zero of the runbook. Do not go quiet; going quiet is what actually costs the credibility.
- **You rewrite history and it does not help.** Early tell: someone says "we removed the commit, we are fine." Recovery: rotate anyway, and say explicitly that history rewriting is not a remediation.
- **Push protection was enabled but everyone learned to bypass it.** Early tell: the bypass reason field is full of "false positive" on real detections. Recovery: review bypasses weekly, make the bypass require a second person, and fix whatever legitimate workflow is forcing the bypass. Usually a test fixture that looks like a real key.
- **The scanner has hundreds of false positives and engineers ignore it.** Early tell: the CI job is marked as non-blocking "temporarily" and never restored. Recovery: invest one day in a tuned `.gitleaks.toml` allowlist and a committed detect-secrets baseline. Signal quality is a prerequisite for enforcement.
- **Customer secrets are encrypted with a single application-wide key stored in the same database.** Early tell: the code reads the key from the same environment as the database connection string. Recovery: this is a real engineering project, not a config change. Put it in `RISK-REGISTER.md` at high severity with a named owner and a date, and be honest with the founder about the cost of not doing it.
- **You cannot answer "who decrypted this" during an incident.** Early tell: key management audit logs exist but are not routed anywhere queryable. Recovery: route them per `dr-3-logging-consumption-model.md` and add a bulk-decrypt alert.

## Related cells

- [SE-2: understand the tech stack](se-2-understand-the-tech-stack.md) tells you where secrets are consumed.
- [SE-1: SDLC and design reviews](se-1-sdlc-and-design-reviews.md) is where you catch a new secret before it is committed.
- [DR-1: incident response plan](dr-1-incident-response-plan.md) takes over the moment a leaked key shows unexplained use.
- [DR-0: compromise assessment](dr-0-compromise-assessment.md) answers the question that follows a used credential, which is what else the holder reached and how long they have been there.
- [DR-2: top security signals](dr-2-top-security-signals.md) covers alerting on key usage, which Evan Johnson names as one of the highest-value starting signals.
- [DR-3: logging consumption model](dr-3-logging-consumption-model.md) is where key management and cloud audit logs need to land.
- [CS-1: identity and access management](cs-1-identity-and-access.md) is how humans stop needing static keys at all.
- [CS-2: endpoint security](cs-2-endpoint-security.md) covers the infostealer threat to credential files on laptops.
- [CO-3: existing commitments](co-3-existing-commitments.md) tells you what you already promised customers about encryption and key handling.
- [CO-4: data inventory and framework](co-4-data-inventory-and-framework.md) is where customer-held secrets get classified as a data type.
- [Modern cells](07-modern-cells.md) covers CI/CD hardening, package publishing tokens, and agent credentials in depth. M-1 there owns a credential exposed by a dependency or a build step; this file owns one exposed by a commit or a person.
- [2019 to 2026 delta](06-2019-to-2026-delta.md) for the wider context on why the perimeter is now an identity policy.
