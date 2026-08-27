# CO-1: Public facing security docs

> **Grid coordinate:** CO-1, Compliance domain, cell 1.
> **Original 2019 wording:** "Public facing security docs" (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019, slide 18).
> **Load when:** sales or the founders ask for a security page, a trust page, or a security one pager; a prospect or researcher cannot find how to report a vulnerability; a customer asks for the subprocessor list or a Data Processing Agreement; the security person is being pulled into every sales call to answer the same five questions; the human says "we need to look credible on security" or "the website says we are SOC 2 compliant and I do not think we are".

## Why this cell exists

Every deal above a certain size triggers the same handful of questions: where does our data live, is it encrypted, who else touches it, are you certified, and what happens when you get breached. If the answers only live in your head, you get pulled into every sales call and you become the bottleneck on revenue. Publishing the answers once, in public, turns a recurring 45 minute meeting into a link.

The second reason is inbound. Security researchers, customers' security teams, and eventually attackers all try to figure out how to talk to you. If there is no published contact path, a researcher who finds a real bug either gives up, posts it publicly, or emails your CEO's personal address. A single well known file fixes that for an afternoon of work.

The third reason is the one nobody warns a first security hire about: your public security page is a legal artifact. Marketing will write "bank grade encryption" and "SOC 2 compliant" because it converts. If you are not actually SOC 2 certified, that sentence is a misrepresentation that regulators, customers, and plaintiffs can point at later. Owning this page is how you stop that.

There is a fourth reason, and it is about you rather than the company. Once you own this page, you are the named author of every security claim on it. If a claim turns out to be false, the company carries the commercial and regulatory exposure, and you personally carry the professional exposure, because you are the person who was supposed to know. In a dispute, in a regulatory response, or in a post-incident review, the security person is the one produced as the author of the security statement. That is not a reason to avoid owning the page. It is the reason to own the wording absolutely, to refuse a sentence you cannot evidence, and to make the refusal in writing. The procedure for doing that without wrecking the relationship, including the ready-to-paste alternative wording that usually gets accepted, is `08-when-it-is-not-working.md`, Part B. Read it before the first time you need it, not during.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A single public security or trust page exists at a stable URL (for example `https://<yourdomain>/security` or `https://trust.<yourdomain>`), linked from the site footer.
- [ ] The page covers, at minimum: data handling, encryption in transit and at rest, hosting provider and regions, subprocessor list (or a link to it), certification status stated honestly, availability and status page link, vulnerability disclosure contact, and a general security contact address.
- [ ] `https://<yourdomain>/.well-known/security.txt` exists, returns HTTP 200, is served as plain text, and has a non-expired `Expires` field per RFC 9116.
- [ ] A subprocessor list is published with the vendor name, purpose, data categories, and hosting region for each entry, plus a stated change notification mechanism customers can subscribe to.
- [ ] A privacy policy exists and matches reality (it names the same subprocessors and the same regions as your security page).
- [ ] A Data Processing Agreement (DPA) exists as a downloadable or click through document, with current transfer mechanism language (Standard Contractual Clauses and any applicable framework), even if a lawyer wrote it from a template.
- [ ] A public FAQ or the trust page itself pre-answers the twenty most common questionnaire items, so a buyer's security reviewer can self serve.
- [ ] A public status page exists with a subscribe option.
- [ ] A one page security overview in PDF form exists that sales can attach to an email, and it is generated from the same source of truth as the web page.
- [ ] Every claim on the page has an owner and a named piece of evidence recorded in `SECURITY-STATE.md`.
- [ ] A calendar reminder exists for a quarterly accuracy review with a named human owner.

Explicitly **not** required at this stage: a hosted trust center product, a customer login gated document portal, an ISO 27001 or SOC 2 report to link, a bug bounty program, a whitepaper longer than two pages, a penetration test summary letter, third party risk ratings badges, or a compliance automation vendor. All of those are fine later. None of them is the thing that unblocks a deal this quarter.

## Discovery

Everything here is read only and safe to run. Replace `example.com` with the company domain. If you do not know the primary domain yet, that is the first question in the next section.

**Step 1: does anything already exist?**

```bash
DOMAIN=example.com
for p in /security /trust /security-policy /privacy /privacy-policy /legal/privacy /dpa /legal/dpa /subprocessors /legal/subprocessors /.well-known/security.txt /.well-known/gpc.json; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 10 "https://$DOMAIN$p")
  echo "$code  https://$DOMAIN$p"
done
```

Anything returning 200 is an existing artifact you now own. Read it before writing anything new. Anything returning 404 is a gap.

**Step 2: check `security.txt` in detail.**

```bash
curl -sS -D - -L --max-time 10 https://example.com/.well-known/security.txt
```

Look for: HTTP 200, `content-type: text/plain`, a `Contact:` line, and an `Expires:` line with a date in the future. RFC 9116 requires both `Contact` and `Expires`. An expired file is worse than no file because it signals abandonment.

**Step 3: what does the site already claim?**

```bash
curl -sS -L --max-time 10 https://example.com/security \
  | tr '<' '\n' | sed -n 's/^[^>]*>//p' | grep -iE 'soc ?2|iso ?27001|hipaa|pci|gdpr|fedramp|certif|compliant|bank[- ]grade|military[- ]grade|256|encrypt' | sort -u
```

Every hit is a claim you must be able to defend. Do the same for the marketing home page and the pricing page, because claims leak there too. Also search the repository if you have one:

```bash
grep -rniE 'soc ?2|iso ?27001|hipaa|pci[- ]dss|fedramp|bank[- ]grade|military[- ]grade' \
  --include='*.md' --include='*.mdx' --include='*.html' --include='*.tsx' --include='*.jsx' --include='*.json' . | head -50
```

**Step 4: confirm the transport claims you are about to make are true.**

```bash
# Certificate issuer and validity window
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -issuer -subject -dates

# Security headers, including HTTP Strict Transport Security
curl -sSI -L --max-time 10 https://example.com | grep -iE 'strict-transport-security|content-security-policy|x-frame-options|x-content-type-options'

# Does plain HTTP redirect to HTTPS?
curl -sS -o /dev/null -w '%{http_code} -> %{redirect_url}\n' --max-time 10 http://example.com
```

If you cannot produce a clean result here, do not write "all traffic is encrypted in transit" yet. Fix the transport first, then write the claim.

**Step 5: find the hosting and region facts, branched by cloud provider.**

- **Amazon Web Services (AWS):** `aws sts get-caller-identity` to confirm which account you are in, then `aws ec2 describe-regions --query 'Regions[].RegionName' --output text` for enabled regions, and `aws s3api list-buckets --query 'Buckets[].Name' --output text` plus `aws s3api get-bucket-location --bucket <name>` for where data actually sits. Console path if you have no command line access: Billing and Cost Management, then Cost Explorer, group by Region.
- **Google Cloud Platform (GCP):** `gcloud projects list`, then `gcloud storage buckets list --format='value(name,location)'` and `gcloud sql instances list --format='value(name,region)'`. Console path: Cloud Console, then the resource list for each service.
- **Microsoft Azure:** `az account show`, then `az resource list --query '[].{name:name,location:location,type:type}' -o table`. Console path: Azure Portal, then All Resources, add the Location column.
- **Platform as a Service (Vercel, Netlify, Render, Fly, Heroku, Railway):** the region is in the project settings page. Note that the underlying hyperscaler and region belong on the subprocessor list, not just the platform name.
- **No cloud access yet:** you can still infer a lot from public data. `dig +short example.com` and `dig +short app.example.com` then map the resulting addresses or CNAME targets. `curl -sSI https://example.com | grep -iE 'server|x-vercel|x-amz|x-goog|cf-ray|via'` often names the platform outright. Treat all of this as a hypothesis to confirm with a human, never as a fact to publish.

**Step 6: enumerate candidate subprocessors without any cloud access.** The fastest sources, in order of yield:

1. The corporate card or accounting export. Every recurring software charge is a candidate subprocessor. Ask finance for a twelve month vendor list by name and amount.
2. The identity provider's application list (Okta, Google Workspace, Microsoft Entra ID, JumpCloud). This shows what employees actually sign in to.
3. The frontend of your own product. Third party scripts are subprocessors that customers can see: `curl -sS -L https://app.example.com | grep -oiE 'src="https?://[^"]+"' | sort -u`.
4. The application dependency manifests for hosted services: search the codebase for vendor SDK names, for example `grep -rniE 'stripe|sendgrid|twilio|segment|datadog|sentry|intercom|mixpanel|openai|anthropic|algolia' --include='package.json' --include='requirements.txt' --include='go.mod' --include='Gemfile' .`

**Step 7: if you have no access to anything at all.** You can still do useful work in one sitting: read the public site, list every claim it makes, list every third party script it loads, check `security.txt`, and check the certificate. That is enough to produce a one page gap list and a specific access request. Write the gap list into `SECURITY-STATE.md` under CO-1 with status `unknown` and record the blocked access request in `ACCESS-LOG.md`.

## Ask the human

Ask these as closed questions, one at a time, and stop when you have enough to write a first draft. Do not ask an open ended "what should the page say".

1. What is the exact primary domain and the exact product domain?
2. Do we sell to businesses, to consumers, or both? (This decides whether the page is a sales tool or a legal artifact.)
3. Who owns the marketing website today, by name, and what is it built on (a content management system, a static site in the app repo, a website builder)?
4. Do we have a lawyer or outside counsel we already use for customer contracts? Name and email.
5. Has anyone ever told a customer, in writing, that we are SOC 2, ISO 27001, HIPAA, or PCI compliant, or that we will be by a specific date?
6. Do we have European Union or United Kingdom customers or users today, yes or no?
7. Do we process health data, payment card data, or data about children?
8. Is there an existing status page, and who gets paged when it goes red?
9. What email address, if any, currently receives security reports, and who reads it?
10. Which of these do we already pay for: a compliance automation platform, a trust center product, a status page product?

**Copy-pasteable message to the person who owns the website:**

> Hi, I am putting together a public security page so that sales stops routing security questions through me one at a time. I need three things from you: (1) the ability to publish a page at /security and a plain text file at /.well-known/security.txt on the main domain, (2) five minutes to tell me how content gets published and who approves it, and (3) a heads up on any existing page or marketing copy that mentions security, encryption, or compliance so I can check it for accuracy. I will write all the content, I just need the publishing path. Can we do 15 minutes this week?

**Copy-pasteable message to finance or operations for the subprocessor list:**

> Hi, I need to publish the list of vendors that touch customer data, which is a standard requirement for our business customers and a legal one under the European Union General Data Protection Regulation. Could you export the last 12 months of software and cloud vendor spend (vendor name and rough annual amount, no invoices needed)? I will filter it down to the ones that actually touch customer data and confirm each one with the owning team before anything is published.

**Copy-pasteable message to the founders about a claim you cannot support:**

> Quick flag before this becomes a problem. Our website currently says we are [exact quoted claim]. As far as I can tell we do not have [certification], we have not started the audit, and we have no report to hand a customer who asks. Public claims like this are relied on in purchasing decisions, which makes an inaccurate one a misrepresentation risk, not just a marketing problem. My recommendation is to change the wording to describe what we actually do today and to state the roadmap separately and clearly. I have a replacement sentence ready. Can I make the change this week?

If the answer is no and the claim stays up, do not let the exchange end there and do not simply drop it. Follow the four steps in `08-when-it-is-not-working.md`, Part B: put the disagreement in writing once and factually, supply the accurate alternative sentence, ask the person who wants the original wording to confirm that decision in their own words, and record it in `DECISION-LOG.md` under their name with a `RISK-REGISTER.md` row for the underlying gap marked accepted by them. This is not an act of hostility. It is how a claim you did not write stops being a claim you authored.

## The walk

**Step 1: publish `security.txt`.**
- **Goal:** any researcher who finds a bug can reach a human in under a minute. This is the smallest artifact with the largest credibility return.
- **Do:** create or reuse a monitored address (`security@yourdomain`, a distribution list, not a personal mailbox). Publish this file at `/.well-known/security.txt`, served over HTTPS as `text/plain`:

  ```
  Contact: mailto:security@example.com
  Expires: 2027-01-31T00:00:00.000Z
  Preferred-Languages: en
  Canonical: https://example.com/.well-known/security.txt
  Policy: https://example.com/security/disclosure
  ```

  Keep `Expires` under one year out. Add `Encryption:` only if you actually publish a key and will actually decrypt with it.
- **Verify:** `curl -sS -D - https://example.com/.well-known/security.txt` returns 200 with `content-type: text/plain`, and a test email sent to the contact address lands somewhere a human sees within a day.
- **Time:** 1 to 3 hours including getting the mailbox created.
- **Who else:** whoever owns the website deploy, and whoever administers email groups.

**Step 2: inventory every existing public claim and correct the false ones.**
- **Goal:** stop the bleeding before you build anything new. A wrong claim already published is a live liability; a missing page is only a missed opportunity.
- **Do:** run the Discovery step 3 greps. Put every claim in a table: claim text, page URL, is it true, evidence, owner. For each claim that is not true today, draft the honest replacement sentence and take it to the founders with the message above.
- **Verify:** the table has zero rows where "is it true" is blank or "no", and you can name the evidence for every remaining claim.
- **Time:** half a day.
- **Who else:** marketing or the website owner for the edits; a founder for approval on anything customer facing.

**Step 3: build the subprocessor list.**
- **Goal:** answer "who else touches our data" once, permanently. Business customers with GDPR obligations are contractually required to know this, and many DPAs give them a right to object to new subprocessors.
- **Do:** start from the finance export and the identity provider app list. For each vendor ask: does it store, process, or transmit customer data? If no, it is a vendor but not a subprocessor and it does not go on the list. If yes, capture the fields in the template below. Confirm each entry with the team that owns the tool before publishing.
- **Verify:** every third party script loaded by your product frontend appears on the list or has a documented reason it does not. Every entry has a named internal owner.
- **Time:** 1 to 2 days for a first pass.
- **Who else:** finance, engineering leads, and whoever runs marketing analytics (they often add tools nobody else knows about).

**Step 4: write the trust page.**
- **Goal:** one URL that answers the top twenty questionnaire items. Use the outline below verbatim as a starting point.
- **Do:** draft it, then walk it line by line with an engineer who can confirm the technical claims and with the person who owns sales. Publish with a "Last reviewed" date in the footer.
- **Verify:** hand the URL to the salesperson who complains most about security questions and ask them to answer their last three prospect questions using only the page. Every question they cannot answer is a section you are missing.
- **Time:** 1 to 2 days of writing, 1 week of elapsed time for review.
- **Who else:** an engineer, a salesperson, and a founder for the compliance status wording.

**Step 5: publish or fix the privacy policy and the DPA.**
- **Goal:** the legal layer that the security page points at. You do not write these; you supply the facts and check the output.
- **Do:** if there is counsel, send them the subprocessor list, the region facts, the data categories, and the retention periods, and ask for a privacy policy review and a customer facing DPA. If there is no counsel and no budget, a reputable template plus a paid one-time lawyer review (typically in the low thousands of dollars) is the honest minimum for a business to business company. Never publish a privacy policy copied from a competitor: it will name their subprocessors and their regions, which is both wrong and embarrassing.
- **Verify:** the vendor names, regions, and retention periods in the privacy policy match the trust page exactly. Mismatch between these two documents is the single most common finding in a buyer's legal review.
- **Time:** your part is 1 day. Counsel turnaround is 1 to 4 weeks.
- **Who else:** legal counsel, a founder, and the sales lead who will actually send the DPA.

**Step 6: stand up a status page.**
- **Goal:** customers can self serve availability questions, and you have a public channel that already exists when you need it during an incident.
- **Do:** pick the cheapest option that supports subscriptions and a custom domain. Free or near free tiers exist from several hosted providers; a static page in your own repository is an acceptable stopgap if someone owns updating it. Link it from the trust page and from the product.
- **Verify:** post a test maintenance notice, confirm a subscribed test address receives it, then delete the notice.
- **Time:** 2 to 4 hours.
- **Who else:** whoever is on call, since they will be the ones posting updates. Coordinate with [DR-4](./dr-4-company-comms-channel.md) so the status page is named in the incident communications flow.

**Step 7: produce the one page PDF for sales.**
- **Goal:** sales can attach something to an email without asking you. Many buyers want a document, not a link.
- **Do:** generate it from the trust page content, not separately. Keep it to one page: what we do, where data lives, encryption, access control, subprocessors link, compliance status, contact. Put a version number and a date in the footer. Store it where sales already looks for collateral.
- **Verify:** the PDF and the web page say the same thing. Set a rule that the PDF is regenerated whenever the page changes.
- **Time:** 2 to 3 hours.
- **Who else:** sales lead for distribution, marketing for the layout if you want it to look decent.

**Step 8: set the review cadence and name the owner.**
- **Goal:** the page stays true. An out of date trust page is a slow moving misrepresentation.
- **Do:** create a recurring quarterly task owned by a named human (usually you). The review checklist is: every claim still true, subprocessor list still complete, `security.txt` `Expires` still in the future, certification statuses current, contact addresses still monitored, any published recovery or restore-testing claim still backed by a drill run within the last twelve months per `m-6-backups-and-recovery.md`, and "Last reviewed" date updated. Add a trigger based review too: any new subprocessor, any new region, any change in certification status, and any incident that changes a stated practice.
- **Verify:** the recurring task exists in a calendar or ticket system with a due date and an assignee, not in your head.
- **Time:** 1 hour to set up, half a day per quarter to execute.
- **Who else:** nobody, but tell the sales lead the cadence so they know when to expect updates.

## Decision points

**Hosted trust center product versus a plain page on your own site.**
DEFAULT: a plain page on your own site. It costs nothing, it is indexed by search engines, and it is under your control. Change this if you are already paying for a compliance automation platform that bundles a trust center at no extra cost, or if you are fielding more than roughly five document requests per week and the gating and access-request workflow would genuinely save you a day a month. Standalone trust center products typically land in the five figure annual range, which is real money for a seed stage company.

**Gated documents versus fully public.**
DEFAULT: everything on the trust page is public and ungated; only the audit report, the penetration test letter, and anything containing architecture detail sits behind a request. Gating the basics costs you deals because a buyer's reviewer will not fill in a form to learn whether you encrypt at rest. Change this only if a customer contract obliges you to restrict distribution of a specific document.

**Publish the subprocessor list publicly, or only in the DPA.**
DEFAULT: publish publicly with an email subscription for changes. It is a competitive non-issue (your buyers already assume you use a major cloud), and it removes an entire class of inbound request. Change this only if a specific subprocessor relationship is under a confidentiality obligation, in which case list the category and region rather than dropping the entry entirely.

**How to state compliance status when you are mid-audit.**
DEFAULT: state the exact truth in one sentence with a status word and no date, for example "SOC 2 Type II: audit in progress. We expect to make the report available to customers under a non-disclosure agreement when it is issued." Never write "compliant", "certified", or "attested" unless a report exists. Change this only when the report is in your hand.

**Who writes the privacy policy and DPA.**
DEFAULT: a lawyer writes them, you supply the facts and review for factual accuracy. Change this only if there is no legal budget at all, in which case use a reputable template, keep the factual sections minimal and true, and put "get counsel review of privacy policy and DPA" in `RISK-REGISTER.md` as an accepted risk with a named accepter. Do not let the security person become the de facto lawyer permanently.

**Advertising a vulnerability disclosure process without a bug bounty.**
DEFAULT: publish a disclosure policy and `security.txt`, offer no money, offer public acknowledgment and a commitment to respond within a stated number of business days. This gets you most of the signal without the cost and noise. See [SE-4](./se-4-bug-bounty-and-disclosure.md) before you consider paying anyone.

## Danger zone

Require an explicit human yes before any of these.

- **Editing live marketing pages.** You can break the site or trigger a stale cache. Get the website owner to make the change or to watch you do it. What breaks if you get it wrong: a broken or blank homepage, which is customer visible within minutes.
- **Removing a compliance claim that sales is actively using.** This is correct, and it will still cost a deal in flight. Bring the replacement wording and a founder to the conversation. Never quietly delete it and let sales find out from a prospect.
- **Publishing a subprocessor list that names a vendor nobody approved you to name.** Confirm each entry with its owning team first. What breaks: a contractual confidentiality problem with that vendor, and an internal trust problem with the team.
- **Publishing regions, architecture detail, or internal tool names that are not already public.** Detail is not credibility. Naming your data store, your identity provider, and your exact internal admin tooling on a public page hands an attacker a target list for free. State categories and providers, not versions and hostnames.
- **Adding a `security.txt` with a contact address nobody monitors.** What breaks: a researcher reports a real, exploitable bug, gets no answer for three weeks, and publishes it. Confirm the mailbox has a live human reader before publishing.
- **Committing to a response time you cannot meet.** "We respond to security reports within 24 hours" becomes a stick you get beaten with. Say five business days if that is what one person can actually do.
- **Publishing any recovery or backup-testing claim before a drill exists.** STOP. A recovery time objective, a recovery point objective, or the sentence "restores are tested" requires a measured number and a date from `m-6-backups-and-recovery.md`. What breaks if you get it wrong: the claim is disproved on the worst day the company has had, in public, and the page is the evidence.
- **Publishing a claim after you have told someone in writing that it is not accurate.** STOP, and do not publish it yourself under any circumstance. Follow `08-when-it-is-not-working.md`, Part B: state the disagreement in writing once, offer the accurate alternative wording, and make whoever wants the inaccurate version own the decision by name in `DECISION-LOG.md`. What breaks if you get it wrong: the company carries the misrepresentation, and you carry authorship of it.
- **Publishing a status page and then never updating it during a real outage.** A green status page during a customer visible outage is worse than no status page, and customers screenshot it.
- **Publishing a Data Processing Agreement with an auto accept clause without legal review.** You may be signing up to audit rights, breach notification windows measured in hours, and liability terms that nobody at the company has read. Cost: potentially unbounded. Get counsel.

## Do not do this yet

- Do not build a full trust center with document request workflows, automated non-disclosure agreement signing, and access logging before you have a plain page that answers the basics.
- Do not write a twenty page security whitepaper. Nobody reads it, and every page is another claim you must keep true.
- Do not chase a compliance certification because the trust page looks thin without one. Certification is [CO-3](./co-3-existing-commitments.md) and [CO-4](./co-4-data-inventory-and-framework.md) work, driven by customer demand, not by page aesthetics.
- Do not launch a paid bug bounty program at the same time as the disclosure policy. Evan Johnson's original advice on the 2019 slide was literally "hold off if you can", and the reason still holds: you will drown in low quality reports before you have the triage capacity.
- Do not add trust badges, third party security rating widgets, or "certified secure" seals. Sophisticated buyers discount them, and they can be actively misleading.
- Do not promise a customer notification window for breaches that is shorter than your actual detection capability. Check [DR-1](./dr-1-incident-response-plan.md) before writing any notification commitment.
- Do not publish a penetration test report. Publish at most a one paragraph summary letter from the testing firm, and only under a non-disclosure agreement if it names findings.

## Evidence to capture

Write into `SECURITY-STATE.md`, section `CO-1 Public facing security docs`:

- Each artifact (trust page, `security.txt`, subprocessor list, privacy policy, DPA, public FAQ, status page, one page PDF) as its own row with status `unknown` / `none` / `partial` / `done`, the live URL, the named owner, and the last reviewed date.
- The claim inventory table from walk step 2: claim text, URL, true or false, evidence, owner.
- The full subprocessor table (below), which doubles as the source for the published page.

Write into `RISK-REGISTER.md`:

- Any public claim you could not substantiate, with severity, the owner, and the decision (corrected, removed, or accepted with a named accepter).
- "No legal review of privacy policy and DPA" if that is the case, with the accepting founder named.
- "Security contact mailbox unmonitored" if you published a contact before confirming a reader.

Write into `DECISION-LOG.md`, dated, with reasoning and approver: the choice of self hosted page versus hosted trust center, the public versus gated document policy, the exact compliance status wording, and the committed disclosure response time.

Write into `ACCESS-LOG.md`: the request for website publishing access, the request for the finance vendor export, and the request for identity provider application listing, each with date requested, granted or denied, and by whom.

Update `90-DAY-PLAN.md` when CO-1 moves state, and if you are interrupted mid-walk, push the current step into `CONTEXT-STACK.md` per [the interrupt protocol](./04-interrupts.md).

**Artifacts a future auditor or enterprise customer will ask for by name:** the published trust page URL, the subprocessor list with its change notification mechanism, the signed customer DPA template, the privacy policy, the vulnerability disclosure policy, and evidence of the periodic accuracy review (a dated ticket or calendar record showing the review happened).

## Trust page outline with suggested wording

Use this structure. Replace bracketed text. Delete any section you cannot substantiate rather than softening it.

**Header:** "Security at [Company]" with a one sentence positioning line and a "Last reviewed: [date]" stamp.

**1. Overview.** "[Company] provides [one sentence product description]. This page describes how we protect the data our customers trust us with. If you have a question this page does not answer, email [security@example.com]."

**2. Data handling.** State what categories of customer data you process, what you explicitly do not collect, how long you retain data, and what happens on account deletion. Suggested wording: "We process [categories, for example account information, usage telemetry, and content that customers upload]. We do not collect [for example payment card numbers, which are handled entirely by our payment processor]. Customer data is retained for the life of the account and deleted within [N] days of account closure."

**3. Encryption.** "All data transmitted between customers and [Company] is encrypted in transit using Transport Layer Security (TLS) 1.2 or higher. Customer data is encrypted at rest using AES-256 through our cloud provider's managed encryption." Only claim what you have verified with the Discovery commands. Do not write "bank grade" or "military grade": those phrases mean nothing and signal inexperience to the security reviewer reading the page.

**4. Hosting and regions.** "[Company] runs on [cloud provider] in the [region names] regions. [If applicable: customer data does not leave these regions.]" Name the provider and the region, not the account structure or the service names.

**5. Access control.** "Access to production systems requires single sign-on with multi-factor authentication. Access is granted on a least privilege basis, reviewed [cadence], and revoked as part of our offboarding process." Confirm each clause against [CS-1](./cs-1-identity-and-access.md) and [CS-3](./cs-3-onboarding-offboarding.md) before publishing it.

**6. Application security.** "Changes to production code are reviewed by a second engineer before merge. We run automated dependency and static analysis scanning in our build pipeline. Significant changes receive a security design review." Confirm against [SE-1](./se-1-sdlc-and-design-reviews.md).

**7. Availability and resilience.** Link the status page. State the backup frequency and whether restores are tested. Do not publish an uptime percentage as a commitment unless it is already in a customer contract, and if it is, make the page match the contract exactly.

  **The recovery-claim rule, which is a hard stop.** No claim on this page about backups, restore testing, recovery time objective, or recovery point objective is published before a timed restore drill has produced a measured number and a date. The drill is run and recorded per `m-6-backups-and-recovery.md`. Before a drill exists, the page may state only what you have verified in a console and can screenshot: that automated backups are enabled, the retention window in days, and whether point-in-time recovery is on. Suggested wording before a drill: "Customer data is backed up automatically with `[N]` days of retention and point-in-time recovery." Suggested wording after a drill: "We test restoration of customer data from backup and last completed a restore test on `[date]`." Round any recovery time upward and conservatively before it goes public, because the drill happened on a good day. "Restores are tested" with no test behind it is the most commonly published untrue sentence on startup trust pages, and it is one that an incident converts into evidence.

**8. Subprocessors.** One line plus a link: "A current list of the third parties that process customer data on our behalf is available at [link]. Customers may subscribe to notifications of changes at [link]."

**9. Compliance status.** The honesty rule lives here. Use exactly one of these four forms per framework, and nothing else:
  - "We hold [certification], issued [date] by [auditor]. The report is available to customers under a non-disclosure agreement."
  - "[Certification]: audit in progress. We will make the report available to customers under a non-disclosure agreement once it is issued."
  - "[Framework]: we have aligned our controls to [framework] but have not undergone a third party audit."
  - "[Framework]: not currently in scope for us."
  Never use "compliant", "certified", "attested", or "audited" without a report in hand. Never state a future certification date on a public page, even if a founder promised one on a sales call: dates slip, and the page becomes the evidence.

**10. Privacy.** Link the privacy policy and the DPA. If you offer the DPA on request rather than as a download, say so and give the address.

**11. Vulnerability disclosure.** "We welcome reports from security researchers. Send reports to [security@example.com]. We will acknowledge within [N] business days. We ask that you do not access other customers' data, do not degrade our service, and give us [N] days before public disclosure. We do not currently operate a paid bug bounty program, but we credit researchers on this page with their permission." Add a short safe harbour statement if counsel approves one.

**12. Contact.** A monitored email address for security questions, and a separate one for privacy or data subject requests if you have EU or UK users.

## Subprocessor table template

Publish these columns. Keep the internal version with two extra columns (internal owner and DPA on file) that you do not publish.

| Subprocessor | Purpose | Data categories processed | Processing location | Website | Added |
|---|---|---|---|---|---|
| [Cloud provider] | Infrastructure hosting, compute and storage | All customer data | [Region, for example EU (Ireland)] | [url] | [YYYY-MM-DD] |
| [Email delivery provider] | Transactional email delivery | Name, email address | [Region] | [url] | [YYYY-MM-DD] |
| [Payment processor] | Billing and payments | Name, email address, billing address | [Region] | [url] | [YYYY-MM-DD] |
| [Error monitoring] | Application error and performance monitoring | Technical logs, may include user identifiers | [Region] | [url] | [YYYY-MM-DD] |
| [Support desk] | Customer support ticketing | Name, email address, support content | [Region] | [url] | [YYYY-MM-DD] |
| [Analytics] | Product usage analytics | Usage events, device and browser data | [Region] | [url] | [YYYY-MM-DD] |
| [AI or model provider] | [Specific product feature] | [Exactly what is sent, and whether it is used for training] | [Region] | [url] | [YYYY-MM-DD] |

Internal-only columns to keep in `SECURITY-STATE.md`: internal owner, DPA signed (yes or no, with date), data deletion mechanism, and whether the vendor supports single sign-on.

Below the table, publish the change notification commitment: "We will post changes to this list here and notify subscribers at least [30] days before a new subprocessor begins processing customer data. To subscribe, [mechanism]." Thirty days advance notice with a right to object is the market norm in business to business DPAs. Do not promise a shorter or longer window than your DPA states.

## Cost and effort

- **Total first pass:** 4 to 7 working days spread over 2 to 3 weeks, most of the elapsed time being waiting on other people.
- **Free path (recommended to start):** the trust page as a page on your existing website, `security.txt` as a static file, the subprocessor list as a table on that page, a status page on a free tier or a static page you maintain, and the PDF exported from a document editor. Dollar cost: zero.
- **Legal:** a one-time template review of a privacy policy and DPA by outside counsel typically runs in the low thousands of dollars. This is the one line item worth paying for at seed stage if you sell to businesses.
- **Status page products:** free tiers exist and are adequate; paid tiers with custom domains and subscriber management are commonly in the tens of dollars per month range. Do not spend more than that at this stage.
- **Hosted trust center products:** typically five figures annually, often bundled with a compliance automation platform. Skip until document requests are a measurable drain on your week.
- **Ongoing:** half a day per quarter for the accuracy review, plus a few minutes per subprocessor change.

## 2026 notes

The 2019 slide treated this cell as sales enablement. Four things have changed.

**Subprocessor lists became mandatory, not polite.** In 2019 a subprocessor list was a nice to have. Under the EU General Data Protection Regulation Article 28, a processor needs authorisation to engage a subprocessor and must inform the controller of changes with an opportunity to object. Buyers now check for the list and for the notification mechanism, and their legal teams will hold up a signature over it. Publish it with a subscribe option and you have removed a recurring deal blocker.

**Fourth party risk is now the question behind the question.** After a run of incidents where attackers compromised a widely installed third party integration and reached hundreds of downstream organisations at once, buyers no longer ask only "who are your vendors". They ask what those vendors can reach and how fast you can revoke them. Your subprocessor list should be backed by an internal register of authorisation grants and a tested revocation path. That work lives in [07-modern-cells](./07-modern-cells.md) under SaaS and OAuth sprawl, but the public page is where it becomes visible.

**Artificial intelligence subprocessors are the new question on every questionnaire.** Buyers now ask, specifically: which model providers do you send customer data to, is that data used to train models, is it retained, and can a customer opt out. Answer this explicitly on the trust page. A vague answer here loses deals faster than a missing certification. If you use a model provider, name it in the subprocessor table with the exact data categories sent and an explicit statement on training and retention.

**Trust pages are machine read now.** Procurement platforms, security rating services, and increasingly the buyer's own language model assistant will parse your page before a human ever reads it. Structure matters: clear headings, plain statements, no marketing adjectives, no claims buried in prose. A page that reads like a specification outperforms a page that reads like a brochure.

**The honesty rule got sharper teeth.** Regulators in multiple jurisdictions have pursued companies for overstated security claims in public materials, and inaccurate statements about security practices have featured in enforcement actions and shareholder suits. "Bank grade encryption" on a marketing page is no longer just a cringe: it is a statement a plaintiff can quote. Treat the page as regulated speech.

## Failure modes

**The page overpromises and becomes a contractual problem.** Early tell: sales quotes the trust page in a contract, or a customer's Master Services Agreement incorporates "Supplier's published security standards" by reference. Recovery: pull every current claim, confirm each against evidence, correct the page, and tell counsel which customers may have relied on the old wording. Prevention: never write a claim on the page that you have not verified, and add "does this become a contractual commitment" to your review checklist.

**A certification claim outruns reality.** Early tell: a founder says "we will have SOC 2 in three months" on a sales call, and it appears on the website the next week. This is exactly the situation Evan Johnson flagged in 2019, and it is still the most common way this cell goes wrong. Recovery: replace the claim with the honest status form, record the commitment in [CO-3](./co-3-existing-commitments.md), and get a real timeline from whoever is running the audit. Prevention: you own the wording of every compliance sentence on the public site, full stop, and that ownership is written into `DECISION-LOG.md`.

**The page rots.** Early tell: the "Last reviewed" date is more than six months old, or a new subprocessor was added and the list did not change. Recovery: run the full review checklist, republish, and reset the cadence. Prevention: the quarterly recurring task with a named human owner, plus the trigger based reviews.

**The security contact address is a black hole.** Early tell: a researcher posts publicly that they tried to reach you. Recovery: apologise, respond substantively, fix the routing, and consider a public acknowledgment. Prevention: send a test report to your own address quarterly as part of the review, and confirm a human replied.

**The subprocessor list is incomplete and a customer finds a vendor you did not list.** Early tell: a prospect asks about a tool by name that is not on your list, usually because they saw it in your product's network requests. Recovery: add it, notify subscribers, and check whether the omission breached a notification clause in any signed DPA. Prevention: re-run the frontend script enumeration and the finance vendor export each quarter, not just once.

**You become the questionnaire desk anyway.** Early tell: the trust page exists but sales still forwards you every questionnaire. This means the page answers the wrong questions. Recovery: take the last five questionnaires, count which questions the page failed to answer, and add exactly those sections. Then move to [CO-2](./co-2-questionnaire-knowledge-base.md), because the page alone is not the whole answer. Evan Johnson's original warning applies: your highest and best use is not completing questionnaires.

**Marketing edits the page without telling you.** Early tell: you find a superlative on the page you did not write. Recovery: correct it and set a rule. Prevention: if the site lives in version control, add yourself as a required reviewer on the security page path. If it lives in a content management system, ask for change notifications on that page and check it during the quarterly review.

## Related cells

- [CO-2: Knowledge base for questionnaires](./co-2-questionnaire-knowledge-base.md), the private twin of this page. Work it next only if this company is actually receiving questionnaires or has a deal stalled on one. If it is not, the trust page stands alone and your next piece of work is wherever your findings point.
- [CO-3: Understand existing commitments](./co-3-existing-commitments.md), for promises already made in contracts and on sales calls that constrain what this page can say.
- [CO-4: Data inventory, privacy commitments, and framework choice](./co-4-data-inventory-and-framework.md), the source of truth for the data handling and region sections.
- [SE-4: Bug bounty and disclosure](./se-4-bug-bounty-and-disclosure.md), for the disclosure policy this page links to.
- [DR-1: Basic incident response plan](./dr-1-incident-response-plan.md), because any breach notification wording on this page must match what you can actually do.
- [DR-4: Establish a communication channel with the rest of the company](./dr-4-company-comms-channel.md), for status page and customer communication during an incident.
- [CS-1: Identity and Access Management](./cs-1-identity-and-access.md) and [CS-3: On-boarding and off-boarding](./cs-3-onboarding-offboarding.md), which supply the access control claims.
- [M-6: Backups and recovery](./m-6-backups-and-recovery.md), the only source of a recovery time objective, a recovery point objective, or the sentence "restores are tested" that this page is allowed to publish.
- [08: When it is not working](./08-when-it-is-not-working.md), Part B, for the refusal procedure when someone wants a claim published that the evidence does not support, and for what that means for your own exposure as its named author.
- [07: Modern cells](./07-modern-cells.md), for SaaS and OAuth sprawl, which is what backs an accurate subprocessor list in 2026.
- [05: Metrics and comms](./05-metrics-and-comms.md), for reporting the deal unblocking value of this work upward.
