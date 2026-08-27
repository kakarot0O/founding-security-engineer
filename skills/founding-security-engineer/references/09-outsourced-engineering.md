# When engineering is an agency: contractors, vendors, and who actually owns the environment

> **Cross-cutting protocol file, not a grid cell.** Every cell in this skill quietly assumes three things that are false here: that engineers are employees, that owners are named humans who are still around in six months, and that the company controls its own cloud accounts, repositories, and pipeline.
> **Load when:** the company has no internal engineers, or fewer internal engineers than external ones; a development agency, offshore team, fractional chief technology officer, or single long-term contractor builds and deploys the product; the human says "our devs are an agency", "we outsourced the build", "the contractor set that up", "I do not think we have the login for that"; recon in `references/01-recon.md` finds a cloud account, code host organisation, or domain registered to a party that is not the company; or a named owner in `RISK-REGISTER.md` turns out to be someone who bills hourly.

## Why this file exists

A very common seed-stage and small-company reality is that a development agency holds the cloud root account, owns the code host organisation, and is the only party with production access. The company owns the idea, the customers, and the revenue. It does not own the machinery. Nobody made a bad decision to get here. In the first eighteen months there was no one to hold the accounts, the agency needed them to work, and creating everything under the agency's existing identity was faster than waiting for a founder to set up billing.

This becomes a security problem in two directions at once. Outward, every control you build sits on assets you do not own, so any control can be removed by a third party at any time without telling you. Inward, the ownership rule this skill teaches everywhere else, that a risk has a named human owner and never a team, is unusable when that named human bills hourly and rotates off in six weeks.

Treat this file as a prerequisite, not an appendix. If the company does not own its own name, its own code, and its own ability to deploy, then multi-factor authentication (MFA) rollouts, logging pipelines, and questionnaire answers are all built on rented ground.

## The ownership substitution rule

State this out loud, early, to the human, and put it in `DECISION-LOG.md` the first time it applies.

**With no internal engineer, the accountable owner of a risk is the executive who owns the vendor relationship. It is never the contractor.**

The reasoning is not bureaucratic. A contractor cannot accept risk on behalf of the company, because a contractor does not carry the consequence. If the agency's engagement lead says "we are comfortable with that", nothing has been accepted: they will not be here when it fires, they do not sign the customer contracts that the risk breaches, and they cannot authorise spending to fix it. Writing their name in the Owner column produces a register that looks complete and is actually empty.

So the substitution is mechanical:

- Owner of a risk: the chief executive, chief technology officer, chief operating officer, or head of product who signs the statement of work. One named person, by name, not "leadership".
- Accepted by, when a risk is accepted: the same executive, in writing, in `RISK-REGISTER.md`, with a review date.
- Assigned to, meaning who does the work: this may be the agency, and that is fine. Doing is delegable. Accountability is not.

If the human resists ("the agency is the one who understands it"), the answer is that understanding and accountability are different jobs, and the register only tracks the second one. If no executive will take the Owner column for an asset, that fact is itself the top risk in the register, and you write it that way.

---

# Part A: The ownership map

Run this in week one. It is roughly one to two days of work, it needs no access to anything the agency controls, and it produces the single most valuable artifact you will make in your first month at a company like this.

## The rule that governs Part A

For every asset, you are looking for the **registered owner**, meaning whose identity the account exists under and whose recovery email and payment method are attached to it. You are not looking for who uses it day to day. Those are different questions and the daily user will answer the wrong one confidently.

**Do not ask the agency first.** Two reasons, and neither of them assumes bad faith. First, asking tips your hand: an account holder who learns that the client is auditing ownership can change facts before you look at them, and even an entirely honest agency will start managing the conversation rather than answering it. Second, and much more common, the answer you get is wrong rather than dishonest. The person you ask is a project manager or a senior engineer who genuinely believes the client owns everything, because that is what they were told when they joined. The engineer who created the accounts left eighteen months ago.

The sequence that works: gather the passive evidence first, write it down, then have **the executive who owns the vendor relationship** ask the agency directly, with the evidence already in hand. Not you. That conversation is a commercial conversation, not a technical one.

## What is safe to run, and what needs a yes

The checks below are split deliberately.

**Passive lookups** query public registries and third-party infrastructure (domain registration data, the public Domain Name System through a public resolver, certificate transparency logs, public app store metadata). They send nothing to any system the company operates. They are safe, but still tell the human what you are about to run and log the batch in `ACCESS-LOG.md`, because the courtesy costs nothing and the log protects you.

An unauthenticated `GET` of a page any customer could load in a browser (the homepage, its response headers, `/security`, `/privacy`, `/.well-known/security.txt`) is free discovery and needs no permission. `references/00-cold-start.md` draws that boundary and owns it. What **does** require an explicit human yes first is any authenticated read against a cloud account, code host, or software as a service (SaaS) console, any method other than `GET`, and any path enumeration beyond that fixed short list. The same rule applies to a host the agency operates on the company's behalf: it being someone else's infrastructure makes the boundary more important, not less.

**Nothing in this file authorises a scan, a probe, or a test of any kind**, against the company or against the agency, ever, without written authorisation. Checking who owns a domain is not scanning. Checking what is running on it is.

## A.1 The domain registrar account

This is the root of everything. Whoever controls the registrar account controls the DNS zone, which controls email delivery, certificate issuance, and the ability to point the company's name at anything at all.

```bash
# Passive. Registration Data Access Protocol (RDAP), the modern replacement for WHOIS.
curl -s https://rdap.org/domain/example.com | python3 -m json.tool

# Passive. Older protocol, often more readable, sometimes more complete.
whois example.com
```

Read these fields:

- **Registrar** (the "Registrar:" line, or `entities[].roles` containing `registrar`). This tells you which company the account lives at: GoDaddy, Namecheap, Cloudflare Registrar, Google Domains successor accounts now at Squarespace, Gandi, MarkMonitor, and so on. Write it down. An agency-flavoured registrar (a reseller account, a hosting company that also builds sites) is a soft signal.
- **Registrant organisation and email.** Usually redacted for privacy, which is normal and not suspicious. When it is not redacted and it names the agency, you have your answer immediately.
- **Creation date.** Compare it to the company's founding date. A domain created before the company existed was bought by someone else. A domain created the week the agency engagement started was very likely created by the agency.
- **Status codes.** `clientTransferProhibited` means a registrar lock is on, which is good hygiene and also means a transfer will need it removed. `pendingDelete`, `redemptionPeriod`, or an expiry date inside sixty days is an emergency, not a finding.
- **Expiry date.** If nobody at the company knows whose credit card renews this, the company is one lapsed card away from losing its name.

The check that does not require asking the agency: **ask finance, not engineering.** Registrar renewals appear on a card statement or in an accounts payable system. If the company has never paid a registrar, the company does not hold the registrar account. This one question to a finance or operations person resolves ownership for the registrar, the app store programs, the error tracking tool, and the email sending vendor in a single conversation, and it does not touch the agency at all.

## A.2 The DNS zone

The registrar account and the zone are often at different providers, and they can be owned by different parties.

```bash
# Passive. Who is authoritative for the zone.
dig NS example.com +short

# Passive. The Start of Authority record names the zone's administrative contact
# mailbox, encoded with the first dot standing in for the "@" sign.
dig SOA example.com +short

# Passive. What the zone actually contains, record by record.
dig A example.com +short
dig MX example.com +short
dig TXT example.com +short
dig CAA example.com +short
dig TXT _dmarc.example.com +short
```

Interpretation:

- Nameservers pointing at a hosting company, a website builder, or a small managed service provider usually mean the zone lives inside an account that provider or the agency created.
- Nameservers at Cloudflare, AWS Route 53, Google Cloud DNS, or Azure DNS tell you the platform but not the account holder. The next question is which account, and that is answered in the cloud section below.
- The `rname` field of the SOA record sometimes contains a real mailbox. If it is `admin.someagency.com`, that is a finding you got for free.
- A DMARC record whose `rua=` aggregate report address points at an address at the agency's domain, or at a report-processing vendor account the agency holds, means the agency currently receives the company's email authentication telemetry.

## A.3 The cloud account or organisation, and specifically the root identity

This is the highest-stakes cell of the map. What you want is not "who has access" but "who holds the identity that can never be removed": the AWS account root user, the Google Cloud organisation and billing account, the Microsoft Entra tenant Global Administrator.

**Passive check for Microsoft, which is genuinely useful and touches nothing the company owns:**

```bash
# Passive. Returns the Entra ID tenant that owns a domain, if any.
curl -s "https://login.microsoftonline.com/example.com/.well-known/openid-configuration" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['issuer'])"

# Run the same command against the agency's domain and compare the tenant identifier.
curl -s "https://login.microsoftonline.com/agency.example/.well-known/openid-configuration" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['issuer'])"
```

If both return the same tenant identifier, the company's identities live inside the agency's Microsoft tenant. That is a top-of-register finding and you found it without logging in to anything.

**Authenticated reads, each requiring an explicit human yes before you run it.** Ask like this: "May I run read-only cloud inventory commands? They list configuration and change nothing. I will paste each command here before running it."

AWS:
```bash
aws sts get-caller-identity                       # read-only: which account am I in
aws iam list-account-aliases                      # read-only
aws organizations describe-organization           # read-only: names the management account and its email
aws organizations list-accounts                   # read-only: every member account
aws iam get-account-summary                       # read-only: includes AccountMFAEnabled for the root user
```
`describe-organization` returns `MasterAccountEmail`. If that address is at the agency's domain, the agency owns the organisation and your account is a member of it. `AccountMFAEnabled: 0` in the account summary means the root user of that account has no second factor.

Console path when the command line is not available: the AWS console, Account settings, shows the root user email address and the alternate contacts (billing, operations, security). Billing, then Bills, shows whether charges are consolidated into a payer account you do not control.

Google Cloud:
```bash
gcloud organizations list                                   # read-only
gcloud projects list                                        # read-only
gcloud projects get-ancestors PROJECT_ID                    # read-only: shows the parent organisation
gcloud projects get-iam-policy PROJECT_ID --format=json      # read-only: look for roles/owner
gcloud billing accounts list                                # read-only
```
The organisation resource is bound to a Cloud Identity or Google Workspace domain. If `gcloud organizations list` returns a display name that is the agency's domain, the projects live in the agency's organisation.

Azure:
```bash
az account show                        # read-only: subscription and tenant identifier
az account tenant list                 # read-only
az role assignment list --role Owner --scope /subscriptions/SUBSCRIPTION_ID -o table   # read-only
```

**A required accuracy note on read-only roles, because the wrong ask here reads customer data.** AWS `ReadOnlyAccess` includes `s3:Get*` and `dynamodb:Scan`, and Google Cloud `roles/viewer` includes `storage.objects.get`. Both of those grant bulk read of customer data. Do not ask for them and do not accept them. The correct minimal asks are:

- AWS: `SecurityAudit` plus `ViewOnlyAccess`.
- Google Cloud: `roles/iam.securityReviewer` plus `roles/browser`, plus specific service viewer roles only where you need them.
- Azure: `Reader` plus `Security Reader`. Azure `Reader` alone is genuinely control plane only.

## A.4 The code host organisation

```bash
# Local and free. What does the working copy actually point at.
git remote -v
git log -1 --format='%an <%ae>' && git log --format='%ae' | sort -u | head -30
```
The commit author email domains tell you who has been writing the code. A repository where every author address is at the agency's domain, or at Gmail addresses belonging to agency staff, is a repository the company has never touched.

GitHub, authenticated reads, explicit yes required:
```bash
gh api /orgs/ORG --jq '{login,name,created_at,email,is_verified}'      # read-only
gh api "/orgs/ORG/members?role=admin" --jq '.[].login'                 # read-only: the owners
gh repo view OWNER/REPO --json owner,isPrivate,createdAt,visibility    # read-only
gh api /orgs/ORG/installations --jq '.installations[].app_slug'        # read-only: installed GitHub Apps
```
GitLab:
```bash
glab api /groups/GROUP --method GET                                    # read-only
glab api /groups/GROUP/members/all --method GET                        # read-only: access_level 50 is Owner
```

What you are looking for: whether the repositories sit under a company-named organisation or under an agency organisation or an individual's personal account. A personal account is the worst case, because it dies with the person's employment at the agency and there is no administrator above them.

Console path: GitHub, the organisation, People, then filter by Owners. GitLab, the group, Manage, Members, then filter by the Owner role.

## A.5 The app store developer accounts

This one is legendarily painful to recover, so check it in week one even if the company is not shipping mobile apps this quarter. An Apple Developer Program account is tied to a legal entity and a D-U-N-S number. If the agency enrolled under their own entity, the company's app is legally published by the agency.

```bash
# Passive. Apple's public lookup service returns the seller name on the listing.
curl -s "https://itunes.apple.com/lookup?bundleId=com.example.app" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['results'][0];print(d['sellerName'],'|',d['artistName'],'|',d['bundleId'])"
```
If `sellerName` is the agency's legal entity, you have your answer, publicly, in one command. For Google Play, open the public store listing in a browser: Play requires developer name and contact details to be displayed, and the developer page lists every other app published by the same account. Seeing a dozen unrelated client apps beside yours means the account belongs to the agency.

Console paths for the authoritative answer, which needs a login the company may not have: Apple, developer.apple.com, Account, Membership details, shows the Entity Name and the Account Holder. App Store Connect, Users and Access, shows everyone else. Google Play Console, Setup, then the account details page, shows the developer account owner and the payments profile.

The bundle identifier prefix matters too. A bundle identifier of `com.agencyname.clientapp` rather than `com.company.app` is a strong signal and creates its own future pain.

## A.6 The package registry namespace

If the company publishes libraries, a software development kit, or internal packages, the namespace is an asset and it is often owned by whoever ran `npm publish` first.

```bash
# Passive, npm.
curl -s https://registry.npmjs.org/PACKAGE_NAME \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print([m['name'] for m in d.get('maintainers',[])])"

# Passive, PyPI.
curl -s https://pypi.org/pypi/PACKAGE_NAME/json \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['info'];print(d.get('author'),d.get('maintainer'))"

# Passive, container images on Docker Hub.
curl -s https://hub.docker.com/v2/repositories/NAMESPACE/REPO/ \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('namespace'),d.get('is_private'))"
```
For a Maven `groupId` derived from a domain, ownership of the namespace follows domain verification, which means it follows the registrar account from A.1.

## A.7 The payment processor

Follow the money, and do it through finance rather than engineering. The questions are: which legal entity is the merchant of record, which bank account receives payouts, and who holds the owner or administrator role in the processor's dashboard.

Checks that do not involve the agency: look at a customer receipt or the hosted checkout page and read the business name shown to the customer. Ask finance which bank account payouts land in, and ask them to name the person who receives the processor's monthly statements.

If the processor account was created under the agency's legal entity, **stop and escalate to the chief executive and finance the same day.** This is not a configuration issue. Customer money is settling into another company's merchant account, which raises tax, revenue recognition, and financial crime questions well outside your remit. Your job is to write it down accurately and hand it to the people whose remit it is.

## A.8 Analytics and error tracking

These leak more than people expect: error trackers hold stack traces, request payloads, and sometimes personal data, and whoever owns the account can read all of it forever, including after the engagement ends.

Look at the front end bundle, which the human can view in their own browser without any request you initiate:

- A Sentry Data Source Name (DSN) has the shape `https://KEY@oORGID.ingest.sentry.io/PROJECTID`. The organisation identifier in the hostname tells you which Sentry organisation receives the data.
- A Google Analytics measurement identifier looks like `G-XXXXXXXXXX`. The property behind it is administered from an Analytics account, and Admin, then Account access management, lists who holds Administrator.
- Datadog, New Relic, LogRocket, PostHog, Hotjar, and Amplitude all follow the same pattern: an identifier in the page, an account somewhere, an owner you have not met.

For each, the question for finance is the same: are we paying for this? A tool the company does not pay for is a tool the company does not own.

## A.9 The email sending domain and its authentication records

Losing this means the company cannot send email that arrives, which for most businesses is indistinguishable from being offline.

```bash
# Passive. Sender Policy Framework (SPF), which lists who may send as this domain.
dig TXT example.com +short | grep -i spf

# Passive. Domain-based Message Authentication, Reporting and Conformance (DMARC).
dig TXT _dmarc.example.com +short

# Passive. DomainKeys Identified Mail (DKIM). Selector names vary by vendor;
# common ones are s1, s2, google, k1, selector1, selector2, mail, dkim.
dig TXT s1._domainkey.example.com +short
dig TXT google._domainkey.example.com +short
```
Read the SPF `include:` mechanisms. `include:sendgrid.net`, `include:amazonses.com`, `include:mailgun.org`, `include:spf.protection.outlook.com`, `include:_spf.google.com` each name a vendor whose account someone holds. Every include is an account to place. Note also that SPF permits at most ten DNS-resolving mechanisms, so a record already near the limit constrains what you can add during a migration.

## A.10 Certificate issuance

```bash
# Passive. Certificate transparency logs, a public record of every certificate issued.
curl -s "https://crt.sh/?q=%25.example.com&output=json" \
  | python3 -c "import sys,json;[print(r['not_before'][:10], r['issuer_name'][:60], r['name_value'].replace(chr(10),' ')) for r in json.load(sys.stdin)[:40]]"

# Passive. Which certificate authorities are permitted to issue for this domain.
dig CAA example.com +short
```
Free automated certificates from Let's Encrypt or ZeroSSL imply an ACME (Automatic Certificate Management Environment) account key sitting on a server or in a platform account. If that platform account is the agency's, certificate renewal stops when the relationship stops, and the site goes down with a browser trust error roughly ninety days later. Paid certificates imply a certificate authority portal account with a billing contact, which is another account to place. Certificate transparency also reveals subdomains and staging hosts you did not know existed, which feeds `references/01-recon.md`.

## Recording the result of Part A

Write the map into `SECURITY-STATE.md` under a heading of `## Ownership map`, as a table with these columns: Asset, Platform, Registered owner (company / agency / individual / unknown), Evidence (the exact command or console path and its date), Recovery email, Payer, and Blast radius if lost.

Then, and this is the part people get wrong: **every asset whose registered owner is not the company becomes its own row in `RISK-REGISTER.md`, at the top, not a footnote in a summary.** Use the register's normal scoring. Most of these land at high or critical, because the likelihood arm is not "an attacker succeeds", it is "a commercial relationship ends", which happens to most agency engagements eventually.

Write the failure mode into the Description field concretely, in the language an executive will act on. Not "ownership risk", but this:

> The relationship ends badly, or the agency is acquired or goes out of business. On that day the company cannot deploy a fix to production, cannot receive email at its own domain, cannot publish an app update to fix a crash, cannot renew the certificate that keeps the website loading, and cannot prove to a court or a customer that it owns its own name. Recovery from that position takes weeks to months and depends on the goodwill of a party the company has just fallen out with.

---

# Part B: The transition of control

The goal is that every asset lives in an identity the company controls, and that production keeps deploying throughout. Those two goals fight each other, which is why the order matters more than the mechanics.

## Sequencing rules that keep production alive

1. **Add before you remove.** Every step adds a company-controlled identity alongside the agency's, verifies it works, and only then removes the agency's. There is a dual-access window on every asset and that window is a feature.
2. **Prove independence with a real action, not a login.** The company can deploy when the company has actually deployed a trivial, no-op change through its own identity. A successful login proves nothing.
3. **Build the recovery foundation first.** Before any transfer, the company needs company-controlled role mailboxes that account recovery can flow to: `domains@`, `billing@`, `security@`, `developer@`, `dns@`. Make each one a group or distribution list with at least two members, never a single person's mailbox, and never a personal Gmail address. Every recovery path in Part B terminates in an inbox, and if that inbox belongs to a founder who later leaves, you have moved the problem rather than solved it.
4. **Start the slowest items first even though they finish last.** Apple entity verification and D-U-N-S registration take weeks of calendar time and almost no working time. Begin the paperwork in week one and let it run in the background.
5. **One asset at a time, with a rollback plan for each.** Never move DNS and email and the code host in the same week.

## The order

| # | Asset | Why here |
| --- | --- | --- |
| 0 | Company role mailboxes and a company identity provider tenant | Everything recovers through email. Nothing else can start safely first. |
| 1 | Domain registrar account | The root of name, mail, and certificates. Take account control without changing nameservers, so nothing moves yet. |
| 2 | App store paperwork begins (D-U-N-S, entity verification) | Long calendar lead time, near zero working time. Runs in the background from here on. |
| 3 | DNS zone | Now that the registrar account is yours, the zone can move with the ability to point nameservers back if it goes wrong. |
| 4 | Code host organisation | Cheap, reversible, low blast radius, and it gives the company the code even if everything after this stalls. |
| 5 | Cloud account or organisation, plus billing | The hardest and most varied. Billing often moves first and separately, which is useful leverage and useful visibility. |
| 6 | Email sending vendor and DKIM | Reputation-sensitive, so it needs a slow parallel-send migration. |
| 7 | Certificates and the ACME account | Follows DNS and cloud. Verify renewal actually happens once before you relax. |
| 8 | Package registry namespaces | Low urgency unless the company publishes public packages that customers install. |
| 9 | Analytics, error tracking, payment processor | Mostly administrative, except the payment processor, which is a finance escalation rather than a security task. |

## Per-asset mechanics and traps

**Domain registrar.** Two different moves exist and the cheap one is usually right. An **account push**, moving the domain between accounts at the same registrar, is fast, usually free, and generally avoids the transfer lock. A **registrar transfer**, moving to a different registrar, needs the domain unlocked, an authorisation code (the EPP or auth code) that only the current account holder can produce, and it triggers a sixty day period during which the domain cannot be transferred again. A change of registrant contact can trigger a similar sixty day lock at many registrars. Newly registered domains cannot be transferred at all for their first sixty days. Do the push if the registrar supports it, and only do a full transfer if the company genuinely wants to leave that registrar. Never let a domain expire while a transfer is in flight, and note that a transfer normally adds a year of registration, which is a cost, not a saving. **Requires agency cooperation** for the auth code or the account push. **Effectively irreversible for sixty days** once done.

**DNS zone.** Export the zone from the current provider (a zone file export, or a scripted read of every record). Recreate it at the destination. Then verify record by record against both sets of nameservers before you change anything at the registrar:

```bash
# Read-only. Compare the old and new authoritative servers answer for answer.
for r in A AAAA MX TXT CNAME NS SOA CAA; do
  echo "== $r"
  dig @old-ns.example.net example.com $r +short
  dig @new-ns.example.net example.com $r +short
done
```
Lower the time to live (TTL) on the records to 300 seconds at least forty eight hours before the cutover, so a mistake is minutes of damage rather than a day of it. Keep the old zone live and unchanged for at least a week after the nameserver change, because resolvers and corporate caches lag. The records people forget are the ones that are not for the website: MX records, DKIM selectors, SPF, DMARC, domain verification TXT records for Google Workspace, Microsoft 365, Atlassian, Stripe, Slack, and every SaaS tool that ever asked for one, plus CNAMEs pointing at vendor-hosted subdomains. If the provider offers an apex ALIAS or ANAME record, check the destination supports the equivalent before you commit. If the site is currently proxied through Cloudflare or a similar content delivery network, moving DNS off it exposes the origin address and can break TLS termination. That is its own project, not a step in this one. **Mutating and customer-visible. Explicit human yes required, with a stated cutover window.**

**Code host organisation.** GitHub: add the company's account as an organisation Owner, verify by having them open Settings on the organisation, then remove the agency owners. If repositories live under an individual's personal account, transfer each one into the organisation through Settings, then Danger zone, then Transfer ownership. Traps: repository and organisation secrets do not follow a transfer, so continuous integration breaks silently until you re-add them; deploy keys, webhooks, branch protection rules, environment protection rules, and GitHub App installations all need re-checking after the move; existing forks stay with whoever forked them, so an agency employee's fork remains a full copy of your code forever. GitLab: transfer the group or project through Settings, then Advanced, then Transfer. The namespace path changes, which changes container registry image paths and any CI configuration that hardcodes them. **Reversible.** **Requires agency cooperation** to promote a company owner in the first place.

**Cloud, AWS.** If your account is a member of the agency's AWS Organization, you cannot simply take it. Removing a member account from an organisation requires the account to have its own payment method, its own root user credentials, and to have accepted the AWS Customer Agreement, and the removal is performed by the management account or by the member account itself once those conditions are met. Changing the root user email address requires access to the current root inbox and the current root MFA device, which is exactly what the agency holds. Warn finance before any of this: leaving a consolidated billing family changes the effective price, because volume tiers, Reserved Instances, Savings Plans, and any negotiated discount live at the payer account. The alternative, building a fresh company-owned account and migrating workloads, is weeks of engineering and is sometimes still the faster path when the existing account is a shared mess. **Removing an account from an organisation is not casually reversible**, and rejoining requires an invitation.

**Cloud, Google.** Projects live under an organisation resource bound to a Cloud Identity or Workspace domain. Moving a project between organisations needs cooperative permissions on both sides and is not clean for every service, so treat it as a project with testing. One useful and much easier early step is billing: linking a project to a company-owned billing account is a separate operation from organisation membership, it gives the company visibility of spend immediately, and it establishes commercial control before technical control. **Mutating. Explicit human yes required.**

**Cloud, Azure.** The trap here is severe and specific: changing the directory (tenant) of a subscription **removes all role assignments**, and managed identities stop working, which breaks any application that authenticates using one. Key vault access policies bound to the old tenant break too. Plan this as an outage with a rebuild of access afterwards, or migrate resources into a new subscription in the company tenant instead. **Effectively irreversible in practice, because rebuilding the old state is manual.**

**Email sending vendor.** Create the company's own account at the vendor. Add the new DKIM selectors and the new SPF include **alongside** the existing ones, never as a replacement, and check the SPF record still resolves within the ten lookup limit. Move traffic gradually and watch delivery and bounce rates, because sending reputation attaches to the account and the sending addresses, and a cold account can see worse inbox placement for a couple of weeks. Only after thirty days of zero traffic on the old account do you remove the old include and the old selectors. **Customer-visible if rushed.**

**Certificates.** Once DNS and the hosting platform are company-controlled, ensure certificate issuance runs from a company-controlled ACME account or a company-held certificate authority portal account. Then wait for one real renewal to happen and verify it, because a renewal path that has never actually renewed is a hypothesis. Add or update a CAA record to name the authorities you intend to use.

**Package registries.** npm: `npm owner add <company-account> <package>` then `npm owner rm <agency-account> <package>`. **Both commands are mutating.** Do them in that order and never the reverse, because removing the last owner you control loses the package. Check whether publishing requires two-factor authentication and which human's automation token the pipeline currently publishes with, because that token is a person, not a company. For a scoped package, the scope belongs to a user or organisation, so the fix is organisation ownership rather than per-package ownership.

**App stores.** Apple supports transferring an app between developer accounts, and the app keeps its reviews, ratings, and existing users, who continue to receive updates. The recipient must accept the transfer within a stated window (sixty days at the time of writing) and must have the relevant agreements in place. Transfers are commonly blocked by App Groups, iCloud entitlements, Apple Pay merchant identifiers, Sign in with Apple, wildcard or shared bundle identifier prefixes, and pending agreements. The blocking list changes, so read Apple's current documentation rather than trusting any list including this one, and check the specific app in App Store Connect, under the app, then App Information, where the Transfer App option either offers itself or explains why it cannot. Google Play supports an app transfer between developer accounts using a transfer token, with both accounts required to be in good standing and the destination account required to have a payments profile for paid apps or apps with in-app purchases; the current path is in Play Console under the app's setup and advanced settings, and it moves as Google reorganises the console. If a transfer is genuinely blocked, the fallback is publishing a new app under the company account and migrating users, which loses ratings, reviews, ranking history, and a meaningful share of the installed base. That is why this item starts in week one. **App store transfers are irreversible without a second transfer, and they require full agency cooperation to initiate from the source account.**

**Analytics and error tracking.** Usually the easy ones: add a company owner, remove the agency. The real question is historical data. Some tools move a property between accounts cleanly, and some do not, in which case you create a new account, point the code at it, and export the old data before access ends. Decide explicitly whether the history matters and record the decision, rather than discovering the answer after access is gone.

**Payment processor.** Do not attempt to transfer a merchant account between legal entities as a technical task. If the account is under the agency's entity, the company opens its own account under its own entity and migrates. Card data can generally be migrated between processor accounts through the processor's own support-driven migration process rather than by exporting it yourself, so ask the processor, and never handle raw card numbers. Finance owns this. You document it.

## Irreversibility and cooperation, at a glance

| Step | Irreversible | Needs the agency to cooperate |
| --- | --- | --- |
| Create company role mailboxes | No | No |
| Registrar account push or transfer | Locked for 60 days | Yes, for the auth code or push |
| DNS zone move | Reversible by pointing nameservers back | Only if the zone lives in their account |
| Code host owner add and remove | No | Yes, to promote the first company owner |
| Repository transfer from a personal account | Reversible, but secrets and hooks are lost | Yes |
| AWS account removal from an organisation | Not casually reversible | Yes |
| AWS root email change | Reversible, needs both inboxes | Yes |
| Azure subscription directory change | Role assignments and managed identities are destroyed | Yes |
| Google project move between organisations | Difficult | Yes |
| Apple or Google Play app transfer | Yes | Yes |
| npm owner removal | Yes, if the last owned account is removed | Yes |
| Email vendor migration | No, if run in parallel | No |
| New payment processor account | No | No |

---

# Part C: The contractual layer

With no internal engineers, the contract is not paperwork sitting beside your security program. It is the only real control surface you have. You cannot mandate a laptop configuration for someone else's employee, you cannot force a code review culture on a team you do not manage, and you cannot revoke an account you do not administer. You can write terms, and you can decline to renew.

You will usually have no leverage until the next statement of work (SOW) or master services agreement (MSA) renewal. Work with that: draft a one page security addendum now, get the executive who owns the relationship to sign it as a side letter if the agency will accept it, and get the full text into the next SOW. **The executive signs it and the executive raises it. Not you.** A security hire negotiating commercial terms directly with a vendor is how a security hire becomes the reason a project is late.

## Terms to put in the next SOW or MSA

1. **Named security contacts on both sides.** One named person at the agency who receives security notifications and can act, plus a named backup, plus a monitored shared mailbox. Same on your side. Personal mobile numbers for both, for incidents outside business hours.
2. **Breach notification to you within a stated window.** Pick the number by arithmetic, not habit. If a customer contract obliges the company to notify within 24 hours (check `COMMITMENT-REGISTER.md`, owned by `references/co-3-existing-commitments.md`), then the vendor window must be strictly shorter, because the company's clock starts when the vendor tells it. Twenty four hours to you is a reasonable default when your own obligations are 72 hours, and twelve when they are 24. Define what counts as a reportable event: any suspected unauthorised access to company data, systems, code, or credentials, whether or not it is confirmed, and whether or not it originated in their environment.
3. **Notification when their staff leave your account.** Within one business day of anyone joining or leaving the engagement, by name. Without this, you are guessing about your own access list forever.
4. **No shared accounts and no shared credentials.** Every person gets an individual, named identity in your systems. No `dev@agency.example` logging in as five people. No credential sharing over chat, email, or a shared password entry. This is the single term that makes every other control possible, because attribution is the foundation of both offboarding and investigation.
5. **Delivery into your organisation, not theirs.** Code is committed to the company's code host organisation, infrastructure is created in the company's cloud accounts, and packages are published to the company's namespace. State it as a delivery requirement, because after Part B you do not want to run Part B again in eighteen months.
6. **Credential handover and access revocation on termination.** On the last day of the engagement, or on the termination of any individual's involvement: all credentials handed over, all their access revoked, all copies of company data and code deleted from their systems including local development environments and personal devices, and written confirmation of deletion within a stated number of days. Say explicitly that copies retained for backup purposes must be scoped and time limited, because otherwise everyone claims backups as an exemption.
7. **A right to review their access list.** Quarterly at minimum, on request at any time: a current list of every individual with access to company systems or data, and every non-human credential their side holds. A vendor who will not provide a roster is a vendor whose access you cannot manage, and that becomes a row in `RISK-REGISTER.md` rather than an argument.
8. **Subprocessor disclosure.** Every third party they use that touches your data or your systems, named, with notice before any change. This includes offshore subcontractors, staffing partners, and hosted development environments. It also includes AI coding tools and any service that receives your source code, which is now a routine and frequently undisclosed subprocessor relationship. Get their list and compare it to your own policy.
9. **Secure development expectations, proportionate to the work.** Do not paste an enterprise appendix onto a five person shop, because unenforceable terms get signed and ignored, which is worse than no terms. A realistic baseline: MFA on every account used for your work; no secrets committed to repositories; automated dependency scanning enabled on your repositories; every change reviewed by a second person before it reaches production; production access limited to named individuals on your access list; no production data copied into development environments; and a stated patching expectation for the components they choose.
10. **Data protection terms where personal data is involved.** A data processing agreement, processing only on documented instructions, confidentiality obligations on their staff, security measures, assistance with data subject requests, and deletion or return at the end. This is a legal deliverable, so route it through whoever handles the company's contracts, and align it with `references/co-4-data-inventory-and-framework.md`.
11. **Incident support obligation.** Named availability during a security incident, including out of hours, and an agreed rate or an included allowance. Without this term, your incident response plan contains a step that reads "wait for a purchase order", which is exactly the failure `references/dr-1-incident-response-plan.md` exists to prevent.
12. **Insurance and liability, if the engagement is material.** Professional indemnity and cyber cover at a level proportionate to the contract value. Finance and legal own the numbers here.

## Offboarding an individual contractor

This is a routine event that should be boring. The distinguishing feature is that there is no human resources system to trigger it, so the trigger must be contractual (term 3 above) plus a monthly reconciliation you run yourself.

1. Revoke their named identities: identity provider guest or member account, code host seat, cloud single sign-on user, chat guest account, ticketing, design tools, error tracker, and anything else on the system list from `references/cs-3-onboarding-offboarding.md`.
2. Check for credentials that belong to them personally rather than to a role: personal access tokens, SSH keys, deploy keys registered under their account, cloud access keys, and any API key whose name contains their name.
3. Revoke their sessions and refresh tokens, not just the account, because a suspended account with a live session is not offboarded.
4. Check what breaks. **If disabling one contractor's account breaks a build, a deploy, or a scheduled job, that is a finding, not an inconvenience.** It means production depends on a specific human's personal credential. Record it in `RISK-REGISTER.md` and fix it with a service identity owned by the company.
5. Do not rotate shared production credentials for a routine departure unless that person actually held them. If they did hold them, they should not have, which is again a finding.
6. Write the dated record: who, what was revoked, by whom, when, verified how.

## Offboarding the entire agency

This is a different class of event. It is a project, and if the separation is not friendly it is a project with an adversary who knows the environment better than you do.

1. **Before anything is revoked, prove the company can operate.** A real deploy through a company-controlled path. A real certificate renewal. A real database restore test. If any of those fail, you are not ready to revoke.
2. **Freeze new access immediately.** No new agency accounts, no new grants, from the moment the decision is made.
3. **Inventory every identity and every non-human credential** they created, held, or could have seen. Not just their user accounts: service accounts, API keys, webhooks, CI runners, deploy keys, third-party OAuth grants, and any credential that has ever appeared in a repository or a chat message.
4. **Plan the revocation as a single window with a rollback plan**, and get an explicit written yes from the executive owner before executing. Mass revocation is a production-affecting change.
5. **Assume they retain copies of everything they ever had access to**, because in practice they do, and rotate accordingly: every credential, every key, every token. This is the point at which `references/se-3-secrets-and-keys.md` becomes a multi-week programme rather than a cell.
6. **Handle the data separately from the access.** They may hold production data extracts, database dumps, customer exports, and logs on laptops you cannot see. Invoke the deletion and confirmation term. If personal data is involved and the handling was improper, this may create a notification obligation, which is a legal question, not a judgement call for you to make alone.
7. **If the separation is hostile, treat it as a potential incident from the start**, not after something happens. Run `references/dr-0-compromise-assessment.md` over the period of the engagement, and stand up the monitoring in `references/dr-2-top-security-signals.md` before revocation day, not after, so you can see what happens.

## How CS-3 applies when the person is not an employee

`references/cs-3-onboarding-offboarding.md` still applies in full. Three adaptations make it work:

- **The trigger changes.** There is no payroll event, so access is granted with a mandatory end date recorded at the moment of grant, defaulting to the SOW end date, and it expires by default rather than persisting by default. Renewal is a decision, not an oversight.
- **The list of record changes.** The vendor's roster is the list, and it is only as current as your last reconciliation. Run a monthly diff between the roster and your actual access list, and treat every unexplained account as an incident-adjacent finding until it is explained.
- **The owner changes.** The joiner and leaver checklist for a contractor is owned by the executive who owns the vendor relationship, per the ownership substitution rule, and executed by whoever administers the systems. Never owned by the agency's own project manager, no matter how helpful they are.

---

## Plan adaptation: what changes in the 90 day sequencing

The gates in `references/03-90-day-plan.md` still hold, and this situation changes what goes in them. The reason is single and simple: **ownership recovery jumps ahead of almost everything, because every other control you build sits on assets you do not own.** Enabling MFA on an identity provider inside the agency's tenant is a control the agency can remove without telling you.

- **Gate A, Understand.** Add Part A of this file as a first-week deliverable, sitting alongside SE-2. It is discovery, it is read-only, and it produces the map that changes the rest of the plan. Also pull `references/co-3-existing-commitments.md` forward hard, because the agency contract is itself a commitment document and the customer contracts may already promise things about subprocessors that the company is not meeting.
- **Gate B, Stop the bleeding.** Every asset registered to the agency is Gate B work. The specific order is Part B's order, starting with role mailboxes and the registrar. This will consume most of Gate B, and that is correct, not a failure of scope.
- **Gate C, Build the floor.** Contractual terms land here, aimed at the next SOW. So does the monthly roster reconciliation habit. So does the first company-run deploy, which is the proof that the company is no longer captive.
- **SE-1 changes meaning entirely.** There is no internal engineering culture to embed design reviews into, so `references/se-1-sdlc-and-design-reviews.md` becomes contract-driven: security requirements written into the SOW, plus a review checkpoint at delivery, plus a threat conversation before each major feature with whoever the agency puts in the room. Do not try to run an internal secure development lifecycle programme for a team that does not work for you.
- **SE-2 changes its source.** The tech stack knowledge lives in the agency's heads. Require an architecture handover document and a recorded walkthrough as a contractual deliverable, and treat the absence of one as a risk with a real severity, because a business whose architecture exists only in a vendor's memory cannot survive that vendor leaving.
- **DR-1 changes its assumptions.** Your incident response depends on a party who bills hourly and who may be the source of the incident. That needs the incident support term and a named out of hours contact before you can call the plan real.
- **DR-0 gains weight.** You cannot assume the build environment was ever clean, because you have never seen it. Run the compromise assessment in `references/dr-0-compromise-assessment.md` earlier than you otherwise would.
- **CS-2 becomes contractual plus compensating.** You cannot manage laptops you do not own, so `references/cs-2-endpoint-security.md` for agency staff becomes a stated baseline in the contract plus access-side controls: browser-based access where possible, no production data in development environments, and short-lived credentials instead of long-lived ones.
- **CS-1 may need to be rebuilt rather than fixed.** If the identity provider tenant belongs to the agency, no amount of configuration inside it is durable. Standing up a company tenant is the fix, and it is Gate B, not Gate C.

## Danger zone

Every item here requires an explicit human yes from the executive owner before you act. None of them are pre-authorised by anything in this file.

- **Any DNS change, including nameserver changes and record edits.** A wrong record takes the website and all email down at once, and TTL means the mistake persists after you fix it. Customer-visible within minutes.
- **Any registrar transfer or registrant change.** Sixty day lock, and a failed transfer during an expiry window can lose the domain entirely.
- **Removing an AWS account from an organisation, changing an Azure subscription directory, or moving a Google project between organisations.** Each one destroys or changes access in ways that break running services, and each one changes the bill.
- **Any credential rotation that production uses.** Rotating the agency's deploy credential before the company has a working deploy path means nobody can deploy, including during the incident your rotation just caused.
- **Any mass revocation of agency access.** This is a production change with an outage risk and a relationship consequence. It needs a window, a rollback plan, and a signature.
- **Any app store transfer.** Irreversible, and a bungled one can leave the app unpublishable while both parties argue.
- **Any communication to the agency about ownership findings.** This is a commercial conversation with contractual consequences, and it belongs to the executive. A security hire who raises it directly can trigger the exact breakdown the register is trying to prevent.
- **Any statement to a customer that the company controls its own infrastructure**, when Part A has not confirmed that it does. Do not answer a questionnaire question about subprocessors or infrastructure ownership from assumption.
- **Enabling a log source or a monitoring tool inside the agency's cloud account.** It is their bill, and a surprise charge on a vendor's account is a bad way to open a negotiation.
- **Anything against the agency's own systems.** Never. Their infrastructure is not in scope for anything, ever, under any circumstance, including during an incident you believe originated there. That is a legal and law enforcement question, not a technical one.

## Do not do this yet

- **Do not demand the agency be replaced.** You do not know the relationship, the economics, or the alternatives, and a first security hire who opens with "fire your engineering team" is finished. Your job is to make the ownership visible and the risk owned, not to pick vendors.
- **Do not build a vendor risk management programme.** No vendor tiering model, no annual questionnaire process, no third-party risk platform. One agency, one contract, one page of terms.
- **Do not try to fix the agency's internal security.** Their laptop management, their password manager, and their hiring checks are not yours to run. Set the access boundary and the contractual expectation and stop there.
- **Do not audit the agency's code as your first act.** A findings dump on a team that does not report to you and is billing by the hour produces an invoice, an argument, and no fixes. Ownership first, then a small number of ranked findings with a named owner.
- **Do not start Part B before Part A is written down.** Moving assets you have not fully mapped is how the DKIM record gets left behind and email quietly stops authenticating three weeks later.
- **Do not treat the payment processor finding as your problem to solve.** Document it, escalate it the same day, hand it to finance and the chief executive.

## Evidence to capture

- `SECURITY-STATE.md`: the ownership map table from Part A, under `## Ownership map`, with the evidence and date for every row. Status values follow the standard vocabulary of `unknown`, `none`, `partial`, `done`, `n/a`. A row moves to `done` only when the company-controlled identity has been used successfully, not when the transfer was requested.
- `RISK-REGISTER.md`: one row per asset not owned by the company, with the executive named in the Owner column, the concrete failure description, and a review date. One row for any dependency on an individual contractor's personal credential. One row if the agency will not supply a roster.
- `DECISION-LOG.md`: the ownership substitution rule the first time it is applied and by whose agreement. Whether historical analytics data is worth preserving. Whether the company migrates the cloud account or rebuilds it. Any risk the executive accepts rather than fixes, with their name.
- `ACCESS-LOG.md`: every access request you made, every yes and every no, with dates. In this situation the log is doubly important, because the pattern of what you were refused is itself the finding you present in month two.
- `COMMITMENT-REGISTER.md` (owned by `references/co-3-existing-commitments.md`): every obligation the agency contract creates on either side, especially notification windows, deletion obligations, and subprocessor terms.
- **What a future auditor or customer will ask for.** A list of subprocessors and vendors with access to production or customer data. Evidence that access is removed when a contractor's engagement ends, usually a sample of recent leavers with dated revocation records. A signed agreement containing security and data protection terms with any vendor that processes personal data. Evidence that the company, not a vendor, controls its production environment. Have the answers before the question arrives, because "our agency handles that" is the answer that loses deals.

## Cost and effort

- **Part A, the ownership map:** one to two days of your time, zero dollars. This is the highest return work available to you in week one.
- **Part B, transition of control:** five to fifteen days of your time spread across a quarter, plus real calendar time waiting on third parties. Direct costs are small: a domain registrar transfer is roughly 10 to 25 US dollars and usually adds a year, an Apple Developer Program membership is 99 US dollars per year, a Google Play developer account is a 25 US dollar one-time fee, and a D-U-N-S number is free but slow. The genuine cost risk is cloud billing: leaving a consolidated billing family can raise the effective rate by a meaningful percentage, so have finance model it before you move.
- **Part C, contractual terms:** half a day to draft the addendum, plus legal review. If the company has no lawyer, a small commercial firm will review a one page security addendum for a few hundred to about 1,500 US dollars, and a full MSA review costs more. The cheaper path is to write the terms in plain language yourself and have the executive negotiate them into the next SOW.
- **Agency time is billable.** Every cooperation step in Part B costs the company money at the agency's rate. Budget it explicitly with the executive up front, because an unbudgeted handover request is the one that gets deprioritised forever.

## Failure modes

- **The map is built from what people told you.** The early tell is an ownership map with no Evidence column filled in. Recovery: re-run Part A and record the command or console path for every row. Reported is not verified.
- **You ask the agency first and the facts change.** The tell is an account whose registered details were updated within days of your first conversation. Recovery: you cannot undo it, so preserve what you captured, note the timeline factually without accusation, and escalate to the executive.
- **You start a transfer and stall halfway.** The tell is a dual-access window that has been open for two months. This is the worst state to sit in, because now two parties can change things and neither is accountable. Recovery: finish or revert, and put a date on it.
- **DNS moves and something invisible breaks.** The tell is not the website; it is a support ticket three weeks later about password reset emails, or a SaaS integration that quietly stopped verifying. Recovery: keep the exported original zone file, diff it against live, restore the missing record.
- **Revocation happens before independence is proven.** The tell is the phrase "we will figure out deploys after we cut them off". Recovery is expensive and public. Prevention is the no-op deploy in Part B.
- **The contract terms get signed and ignored.** The tell is that no staff-change notifications have arrived in three months while the roster has obviously changed. Recovery: the monthly reconciliation catches it, so run the reconciliation. Terms without a verification habit are decoration.
- **The executive will not take the Owner column.** The tell is a register full of rows owned by "the agency" or "TBD". Recovery: escalate once, in writing, with the specific consequence stated, then record the refusal itself as the top risk. An honest empty register beats a dishonest full one.
- **You become the agency's project manager.** The tell is that your week is full of chasing their deliverables. Recovery: hand the delivery chasing back to whoever owns the relationship, and return to controls and evidence. It is a real trap, because you are the only person paying attention, and that is exactly why it swallows the quarter.

## Related cells

- [CS-3: On-boarding and off-boarding](cs-3-onboarding-offboarding.md): the joiner and leaver mechanics that Part C adapts for non-employees.
- [CS-1: Identity and Access Management](cs-1-identity-and-access.md): what to do when the identity provider tenant itself belongs to the vendor.
- [CS-2: Endpoint security](cs-2-endpoint-security.md): why contractor devices need a contractual baseline plus access-side compensating controls.
- [SE-3: Secrets, API keys, customer secrets](se-3-secrets-and-keys.md): the rotation programme that a full agency offboarding triggers.
- [SE-1: SDLC and security design reviews](se-1-sdlc-and-design-reviews.md): how design review becomes a contractual checkpoint when the engineers are not yours.
- [SE-2: Understanding your tech stack](se-2-understand-the-tech-stack.md): why an architecture handover document becomes a deliverable here.
- [DR-0: Compromise assessment](dr-0-compromise-assessment.md): run this earlier than usual, because you have never seen the build environment clean.
- [DR-1: Basic incident response plan](dr-1-incident-response-plan.md): the incident support term that keeps the plan from depending on a purchase order.
- [CO-3: Understand existing commitments](co-3-existing-commitments.md): the agency contract is a commitment document, and customer contracts may already constrain subprocessors.
- [CO-4: Data inventory, privacy commitments, framework choice](co-4-data-inventory-and-framework.md): the data processing terms and the subprocessor list both live here.
- [CO-2: Knowledge base for questionnaires](co-2-questionnaire-knowledge-base.md): where the honest answer to "who operates your infrastructure" gets written down once.
- [M-6: Backups and recovery](m-6-backups-and-recovery.md): the restore test that is part of proving the company can operate independently.
- [Modern cells](07-modern-cells.md): software supply chain, continuous integration and deployment security, cloud posture, and third-party application grants, all of which the agency currently controls.
- [Recon](01-recon.md): the discovery pass that usually surfaces this situation in the first place.
- [The 90 day plan](03-90-day-plan.md): where the sequencing changes described above are applied.
- [Cold start](00-cold-start.md): the state directory, the access ask, and the read authorisation rules that govern every command in this file.
