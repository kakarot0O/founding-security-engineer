# CO-4: Data inventory, privacy commitments, and framework choice (the blank cell, filled)

> **Grid coordinate:** CO-4, Compliance domain, fourth cell.
> **Original 2019 wording:** blank. On slide 18 of Evan Johnson's "Starting Security at a Startup" (OWASP AppSec California 2019) the fourth Compliance cell is literally empty. Three slides later, when the Compliance column gets its own emphasis slide, he fills it in as "GDPR & Current laws". So the cell was never meant to stay blank: it was a placeholder for "the legal and data obligations you inherit whether you like it or not".
> **How we fill it:** data inventory and data map, the privacy commitments that follow from it, and the framework decision (SOC 2 Type I, SOC 2 Type II, ISO 27001, or none yet).
> **Load when:** a customer or prospect asks which compliance certification you hold, sales says a deal is blocked on SOC 2 or ISO 27001, someone asks "where does customer data live", a data subject access or deletion request arrives, a privacy regulation (GDPR, CCPA/CPRA, or a state or national equivalent) is raised, a data processing agreement or subprocessor list is requested, you are about to sign a contract with a compliance-automation vendor, or the product touches a regulated area (health data, cardholder data, a government buyer, a supervised financial institution, European network and information security rules, European financial-sector operational resilience rules, or an artificial intelligence use case that Europe may treat as high risk), in which case go to "Regulated from day one" in this file first.

## Why this cell exists

Every other compliance activity is a form of telling people things: publishing a trust page, answering a questionnaire, honoring a commitment sales already made. None of those are possible, or honest, if you do not know what data you actually hold, where it sits, and who can read it. The data inventory is the single artifact that every auditor, every enterprise customer, every privacy regulator, and every incident responder will ask you for, and it is the one almost no startup has.

The second half of this cell is a decision, not a document. Choosing whether to pursue SOC 2 Type I, SOC 2 Type II, ISO 27001, or nothing yet will consume between one and nine months of a first security hire's time and between fifteen thousand and eighty thousand dollars of a company that may not have it. Getting that decision wrong is the most expensive mistake available to you in your first ninety days, because a certification pursued too early burns the budget and the goodwill you need for the controls that actually reduce risk.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A data inventory exists as a single table (spreadsheet or markdown), covering every system that stores customer data, employee data, or anything a regulator would call personal data. It has fewer than 60 rows. It is dated and has a named owner.
- [ ] A one-page data flow diagram shows where customer data enters, where it is stored at rest, and which third parties receive it. Data stores are labeled with who can read them.
- [ ] A subprocessor list exists and is published or ready to publish. Every vendor that touches customer data is on it.
- [ ] Retention is written down per data category, even if the answer for some rows is honestly "indefinite, and we know that is a gap".
- [ ] A data subject request (access, deletion, export, correction) runbook exists and has been tested once end to end against a test account, with a recorded elapsed time.
- [ ] The lawful basis for processing is written down per category if you have European or United Kingdom users, and the cross-border transfer mechanism is named if data leaves those regions.
- [ ] Breach notification obligations are written down: which regulators, which customers, and what clock (contractual hours plus statutory hours), so that no one is reading contracts during an incident.
- [ ] The regulated-regime trigger tests in "Regulated from day one" have all been run and answered yes, no, or unknown, with a date, and every "yes" has its required contract artifact either in hand or on the risk register with an owner.
- [ ] A framework decision is recorded in `DECISION-LOG.md` with the reasoning, the deals it unblocks, the cost, the timeline, and who approved it. "Not yet, revisit at N enterprise deals or date D" is a valid and often correct decision.

Explicitly **not** required at this size: a full Article 30 record of processing activities in regulator-ready format, a Data Protection Impact Assessment for every feature, an appointed Data Protection Officer (only required in specific cases such as large-scale systematic monitoring or large-scale special-category processing), an automated data discovery or Data Security Posture Management tool, a privacy engineering team, ISO 27701, HIPAA or PCI DSS unless you actually handle protected health information or cardholder data, and a data classification scheme with more than three tiers.

## Discovery

Goal: build the first draft of the inventory from evidence rather than from interviews, then use interviews to fill the gaps. Everything below is read-only.

**Step 0, cheapest signal first.** Read the public surface. It often contradicts reality, and the contradiction is your first finding.

```bash
# Look for existing privacy and legal text in the repo or docs site
grep -ril -e "privacy policy" -e "subprocessor" -e "data processing" -e "GDPR" -e "CCPA" -e "retention" . 2>/dev/null | head -50
```

Then fetch, in a browser, these paths on the company's marketing domain: `/privacy`, `/legal`, `/dpa`, `/subprocessors`, `/security`, `/trust`. Note the last-updated date. A privacy policy that promises deletion within 30 days is a commitment you now own.

**Find the data stores in code.**

```bash
# Connection strings and data store hints, read-only
grep -rniE "(postgres|mysql|mongodb|redis|snowflake|bigquery|redshift|dynamodb|clickhouse|elasticsearch)://" \
  --include="*.env*" --include="*.yml" --include="*.yaml" --include="*.tf" --include="*.json" . 2>/dev/null | head -40

# Infrastructure as code is the highest-signal place to find storage
grep -rlE "aws_(s3_bucket|rds|dynamodb_table)|google_(storage_bucket|sql_database|bigquery)|azurerm_(storage_account|mssql|cosmosdb)" . 2>/dev/null | head -40

# Field names that indicate personal data in schemas and migrations
grep -rniE "\b(email|phone|ssn|social_security|date_of_birth|dob|address|ip_address|passport|tax_id|full_name|credit_card|card_number)\b" \
  --include="*.sql" --include="*.prisma" --include="*.rb" --include="*.py" --include="*.ts" . 2>/dev/null | head -60
```

**Cloud, branched by provider.** These list storage and databases so you can reconcile against code. All are read-only.

- Amazon Web Services (AWS): `aws s3api list-buckets`, `aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Engine,PubliclyAccessible]' --output table`, `aws dynamodb list-tables`. If Macie is already enabled, `aws macie2 get-findings-statistics --group-by type` gives a sensitive-data view; do not enable Macie without approval, it is billed per gigabyte scanned.
- Google Cloud Platform (GCP): `gcloud storage buckets list --format="table(name,location)"`, `gcloud sql instances list`, `bq ls --format=pretty`. Sensitive Data Protection (formerly Data Loss Prevention) inspection jobs cost money; do not start one without approval.
- Microsoft Azure: `az storage account list -o table`, `az sql server list -o table`, `az cosmosdb list -o table`.
- **No cloud access at all:** stop and request it (template below). In the meantime, build the inventory from the billing statement. Ask finance for a vendor list with monthly spend; every data store and every software-as-a-service tool that holds data appears there.

**Software-as-a-service systems, which is where most personal data actually lives.** The single best free discovery source is the identity provider's application list plus the corporate card statement.

- Google Workspace: Admin console at admin.google.com, then Security, then Access and data control, then API controls, then Manage third-party app access. This lists every application with an OAuth grant.
- Microsoft 365 or Entra ID: Entra admin center, Applications, Enterprise applications, filter to all applications, and review Permissions per application.
- Okta or another standalone identity provider: Admin, Applications, Applications, and export the list.
- **No identity provider access:** ask for read-only administrator or a one-time export (template below).

**Code hosting and analytics leakage.** Ask where product analytics and error tracking go. Error trackers and session replay tools are the most common place personal data ends up without anyone deciding it should.

```bash
grep -rniE "(sentry|datadog|segment|amplitude|mixpanel|posthog|fullstory|logrocket|hotjar|heap|rudderstack)" \
  --include="*.json" --include="*.ts" --include="*.js" --include="*.py" --include="*.rb" . 2>/dev/null | head -30
```

**When you have zero access to anything.** You can still finish this cell. The inventory can be built entirely from: the vendor spend list from finance, the signed customer contracts from sales or legal, the published privacy policy, and a 45-minute whiteboard session with one backend engineer. Record in `SECURITY-STATE.md` under CO-4 that the inventory status is `partial` with evidence "built from interviews, not verified against infrastructure", and open an access request in `ACCESS-LOG.md`.

## Ask the human

Closed questions, in this order. Do not ask more than three at a time.

1. Do we have paying customers in the European Union or the United Kingdom right now: yes, no, or unsure?
2. Do we sell to consumers, to businesses, or both?
3. Has any customer contract we have already signed named a specific certification or a specific breach notification deadline: yes, no, or unsure?
4. Is there a published privacy policy, and who wrote it: outside counsel, a template, or a founder?
5. Do we store any of these: health data, payment card numbers, government identifiers, children's data, biometric data, or precise location? Yes or no for each.
6. How many deals in the current pipeline are blocked on a certification, and what is their combined annual contract value?
7. Who is the executive sponsor for compliance: the chief executive, the chief technology officer, the head of sales, or nobody yet?
8. Do we have outside counsel or a fractional privacy lawyer we can ask a question of: yes, no, or unsure?

Copy-pasteable message to sales leadership (this is the message that decides the framework):

> Hi, I am putting together our compliance plan and I want to build it around real revenue, not guesses. Three questions. First, which deals in the current pipeline have asked for SOC 2 or ISO 27001, and what is the annual contract value of each? Second, for those deals, did the buyer say "in place today" or did they accept "in progress with a target date"? Third, are any of them European or United Kingdom based, because that usually shifts the ask toward ISO 27001 and toward a data processing agreement. I would rather spend the money once on the right thing than twice on the wrong one. If you can send me the deal names and amounts I will come back within a week with a recommendation, a cost, and a date.

Copy-pasteable message to whoever administers cloud or the identity provider:

> Hi, I need read-only access to build our data inventory, which is the artifact every enterprise customer and every auditor asks for first. Specifically I need: read-only (Viewer or SecurityAudit level) on our cloud accounts, read-only administrator on our identity provider so I can list applications and their permissions, and read access to the billing or vendor spend list. I will not change any settings. If read-only access is not something you can grant this week, a one-time export of the application list and a 30-minute screen share also works. Which is easier for you?

Copy-pasteable message to legal or the founder who signs contracts:

> Hi, before I recommend a compliance path I need to know what we have already promised. Can you send me any signed customer agreement that includes a security exhibit, a data processing agreement, or a breach notification clause, plus anything where we committed to a certification by a date? I am not looking to relitigate anything. I am looking to make sure we do not miss a deadline we already agreed to.

## The walk

**Step 1. One-page data map from a single conversation.**
Goal: have something real by end of day one. Do: sit with one backend engineer for 45 minutes and draw where customer data enters, where it is stored, and where it leaves. Name the data stores. Circle the ones holding personal data. Verify: the engineer looks at it and says it is correct, and a second engineer looks at it and does not add a store you missed. Time: half a day. Who else: one backend engineer, ideally the longest-tenured.

**Step 2. Turn the map into the inventory table.**
Goal: a queryable inventory instead of a picture. Do: create the table using the schema below, one row per system, not per field. Verify: every data store on the diagram has a row, and every row has a named owner. Time: one day. Who else: nobody, but circulate for correction.

**Step 3. Reconcile the inventory against infrastructure.**
Goal: find the systems nobody mentioned. Do: run the cloud and identity provider discovery commands above and diff the results against the table. Every bucket, database, and connected application that is not in the table is either a new row or a decommission candidate. Verify: the diff is empty or every difference has a written explanation. Time: one day. Who else: whoever grants read-only access.

**Step 4. Write down retention, and be honest.**
Goal: know how long you keep things. Do: for each row, record the retention period and whether it is enforced by a mechanism or only by intention. "Indefinite, no deletion job exists" is a legitimate and useful entry. Verify: for at least one row claiming enforced retention, find the actual job, lifecycle rule, or setting that enforces it. Time: half a day. Who else: one engineer per data store.

**Step 5. Build and test the data subject request runbook.**
Goal: be able to answer a deletion request without a fire drill. Do: write the runbook using the outline below, then run it end to end against a test account you created yourself. Verify: the test account's data is gone from primary stores, and you have written down what remains in backups and why. Time: two days. Who else: one engineer, plus support to agree on the intake path.

**Step 6. Collect the existing commitments and cross-check them against reality.**
Goal: know what you already promised. Do: gather signed agreements, the published privacy policy, and any sales collateral making security claims. List every promise with a deadline or a numeric commitment. Verify: each promise is either met, or logged in `RISK-REGISTER.md` with a severity and an owner. Time: one day. Who else: legal or the contract signer. This overlaps heavily with CO-3; do it once and share the output.

**Step 7. Run the framework decision.**
Goal: a written, sponsored decision. Do: use the decision tree below with the sales numbers from your message above. Produce a one-page recommendation with cost, timeline, scope, and what you will stop doing to make room. Verify: the executive sponsor says yes or no in writing, and the decision lands in `DECISION-LOG.md`. Time: two days including the meeting. Who else: chief executive or chief technology officer, plus sales leadership.

**Step 8. If the answer is a framework, scope it before you buy anything.**
Goal: prevent the audit from swallowing the company. Do: write the scope statement (which product, which environments, which entities, which trust services criteria or which Annex A controls) before talking to a vendor. Verify: a peer or advisor reads the scope and cannot find a system in it that is not needed for the customer ask. Time: one day. Who else: the executive sponsor.

## Decision points

**Data inventory granularity: per system or per field?**
DEFAULT: per system, with a data-category list inside each row. Field-level inventories at this size take months and are stale on arrival. Change this if you process special-category data under European rules, health data, or payment card data, where regulators and auditors expect field-level precision for those specific categories only.

**Build the inventory manually or buy a discovery tool?**
DEFAULT: manually, in a spreadsheet or markdown table. Under about 60 systems a human plus grep beats a scanner, and the act of building it teaches you the architecture. Change this above roughly 150 employees, or when you have more than a handful of production databases nobody can fully enumerate; then evaluate cloud-native options first (Amazon Macie, Google Sensitive Data Protection, Microsoft Purview) before a standalone Data Security Posture Management vendor.

**SOC 2 Type I or straight to Type II?**
DEFAULT: go straight to Type II if you can wait three months for the observation window, because Type I is a point-in-time snapshot that sophisticated buyers increasingly discount. Change this if a specific named deal will close on a Type I this quarter and will not wait; then do Type I with an explicit, written commitment to Type II within the following two quarters, and expect to pay for two audits.

**SOC 2 or ISO 27001?**
DEFAULT: SOC 2 if your buyers are predominantly North American, ISO 27001 if they are predominantly European, United Kingdom, Japanese, Australian, or Middle Eastern. Change this if a single large deal dictates the answer, or if you are already doing one and a customer will accept a mapping. Doing both from a standing start in year one is a scope trap. Doing the second one twelve to eighteen months later, reusing the same controls, is cheap by comparison.

**Buy a compliance automation platform or do it with spreadsheets?**
DEFAULT: buy one, once you have decided to pursue a framework. Since 2019 this market matured enough that the evidence-collection grind is genuinely cheaper to rent than to build, and the platform's control library also functions as a checklist you do not have to write. Change this if you are pursuing nothing yet (buy nothing) or if you have fewer than about fifteen employees and one cloud account, where the spreadsheet genuinely wins. Critically: the platform does not manufacture controls you do not have. It tells you they are missing and then waits for you.

**Do the framework now or defer?**
DEFAULT: defer until either (a) named pipeline deals worth more than roughly ten times the total audit cost are blocked on it, or (b) an existing contract already commits you to a date. Change this if you are about to raise a round where the certification is a diligence item, or if your buyer segment is regulated (financial services, healthcare, government) where the ask is universal and immediate.

**Lawful basis for a business-to-business software-as-a-service product.**
DEFAULT: contract necessity for the data you process to deliver the service, and legitimate interests for security logging and fraud prevention, with consent reserved for marketing communications and non-essential cookies. Change this on the advice of counsel; this is the one area where the correct move is to buy two hours of a privacy lawyer's time rather than reason from first principles.

## Danger zone

Stop and get an explicit human yes before any of these.

- **Executing a deletion request against production.** Irreversible by design. If the request is fraudulent, or the account matching is wrong, you have destroyed a paying customer's data. Require: identity verification of the requester, a written confirmation from the account owner where the account is a business account, and a dry run that outputs the row counts to be deleted before anything is deleted.
- **Enabling a sensitive-data scanning service.** Amazon Macie, Google Sensitive Data Protection, and Microsoft Purview scanning all bill by volume scanned. Running one across every bucket can produce a five-figure surprise. Require: a cost estimate based on stored bytes and a spend cap or budget alert configured first.
- **Publishing a privacy policy, a subprocessor list, or a data processing agreement.** These are binding public commitments. Publishing a 30-day deletion promise you cannot meet creates the violation. Require: legal review, and a verification that every promise in the text maps to a mechanism you have tested.
- **Signing a data processing agreement or a security exhibit.** These commonly contain breach notification windows as short as 24 hours, audit rights, and liability carve-outs. Require: someone reads the notification clause out loud and you confirm you can meet it operationally.
- **Signing a compliance automation platform contract.** Typical annual commitments range from roughly seven thousand to thirty thousand dollars, often multi-year, plus a separate audit fee. Require: the framework decision approved first, and a scope statement written first.
- **Deleting data to "clean up" the inventory.** Data may be subject to a litigation hold, a tax retention requirement, or a customer contract. Require: legal confirmation that no hold applies.
- **Telling a customer or a regulator that you hold a certification.** Claiming a certification you do not have is fraud, not a marketing shortcut. Correct the sales deck the same day you find it. If someone senior asks you to state it anyway, or to describe an audit as further along than it is, that is the refusal procedure in `08-when-it-is-not-working.md`, Part B: the disagreement in writing once, the accurate alternative wording offered, and the decision owned by name in `DECISION-LOG.md`. Do not write, sign, or send the inaccurate version yourself, because the author of a false compliance statement is the person the company will produce later, and that person is you.
- **Sending a data subject request response, an export, or a deletion confirmation to a requester whose identity you have not verified.** Require the verification step in the runbook to be complete and recorded. What breaks if you get it wrong: you have either handed a person's data to an impersonator, which is a breach you caused while trying to comply, or you have destroyed a real user's account at a stranger's request.

## Do not do this yet

- Do not start a SOC 2 or ISO 27001 audit in your first thirty days. You will spend the budget documenting controls that do not exist, and the auditor will write exceptions that you then carry publicly.
- Do not build a data classification taxonomy with five tiers and a labeling policy. Three tiers (public, internal, sensitive or restricted) is enough, and even that can wait until the inventory exists.
- Do not do a Data Protection Impact Assessment for every feature. Reserve it for genuinely high-risk processing: systematic monitoring, special-category data at scale, or automated decisions with legal effects.
- Do not appoint a Data Protection Officer reflexively. The role carries independence requirements and is only mandated in specific circumstances. Ask counsel before creating it.
- Do not buy a data discovery scanner before you have manually listed the systems. You will not be able to tell whether its output is right.
- Do not chase HIPAA, PCI DSS, or FedRAMP unless a real deal requires it. Each is an order of magnitude more work than SOC 2, and FedRAMP in particular is a multi-year, seven-figure commitment.
- Do not let the inventory become a quarterly manual re-survey. Attach it to a moment that already happens (new vendor approval, new data store creation) so it updates itself.

## Evidence to capture

- `SECURITY-STATE.md`, section **CO-4**: status of `unknown` / `none` / `partial` / `done` for each of the three parts (inventory, privacy commitments, framework decision), with the path to the inventory file, its last-updated date, and its owner.
- `DECISION-LOG.md`: the framework decision, dated, with the pipeline dollar figure that drove it, the alternative rejected, the cost approved, and the approver's name. Also log the lawful-basis decision and the retention decisions.
- `RISK-REGISTER.md`: every gap the inventory exposed. Typical entries are "no enforced retention on the events table", "analytics vendor receives raw email addresses with no data processing agreement", "backups retain deleted customer data for N days beyond the deletion promise", and "privacy policy promises deletion in 30 days, tested runbook takes 6 days but only covers primary stores". Each needs a severity, an owner, and an accepted-by name if the company chooses to accept it.
- `ACCESS-LOG.md`: the read-only cloud, identity provider, and billing access you requested, when, from whom, and the outcome.
- `90-DAY-PLAN.md`: if a framework was chosen, the audit window dates and the scope statement; if deferred, the exact revisit trigger.

Artifacts a future auditor or enterprise customer will ask for by name: the data flow diagram, the system or asset inventory, the subprocessor list, the retention schedule, the data processing agreement, the record of processing activities (the inventory in a different shape), evidence that a data subject request was serviced within the promised window, and the breach notification procedure.

## Data inventory schema

One row per system. Keep it to these columns; more columns is the main reason these documents die.

| Column | What goes in it | Example |
| --- | --- | --- |
| System | Name of the store or software-as-a-service tool | Primary application database |
| Purpose | Why it exists, one clause | Serves the product |
| Data categories | From a fixed list: account, contact, authentication, billing, content, usage, support, employee, special-category | account, contact, authentication, content |
| Personal data | yes / no / pseudonymous | yes |
| Volume band | under 1k / 1k to 100k / 100k to 1M / over 1M subjects | 100k to 1M |
| Location | Cloud provider and region, or vendor and hosting region | provider region eu-west-1 |
| Owner | A named human, not a team | first-name last-name |
| Who can read it | Roles or groups, plus a count of humans | on-call engineers (4), data team (2) |
| Access mechanism | How access is granted and revoked | identity provider group, reviewed quarterly |
| Retention | Period plus enforced or intended | 7 years, intended, no job exists |
| Encryption at rest | provider-managed / customer-managed / none | provider-managed |
| Third-country transfer | Regions data leaves to, or none | none |
| Transfer mechanism | Standard contractual clauses, adequacy decision, or not applicable | not applicable |
| Deletion path | The exact step that removes a subject's data here | cascade from users table |
| Backups | Retention of backups holding this data | 35 days, point-in-time restore |
| Subprocessor | yes if a third party, with contract status | yes, data processing agreement signed |
| Last verified | ISO date and by whom | 2026-08-25, first-name |

Fixed data category list, so rows stay comparable: **account** (identifiers, org membership), **contact** (name, email, phone, address), **authentication** (password hashes, tokens, multi-factor secrets), **billing** (payment tokens, invoices, tax identifiers), **content** (whatever customers upload or create), **usage** (events, logs, internet protocol addresses, device identifiers), **support** (tickets, transcripts, attachments), **employee** (human resources and payroll data), **special-category** (health, biometric, precise location, government identifiers, children's data, anything a regulator treats as elevated).

## Data subject request runbook outline

Write this as its own file and link it from the inventory. Test it once before you publish any promise about it.

**Business-to-consumer changes this section more than any other part of the cell.** In a business-to-business product the request almost always arrives through the customer, who is the controller, and your job is to assist them. In a consumer product the request arrives directly from the individual, through support, through an in-product link, through a privacy address, or occasionally through a lawyer or a bulk-submission service, and there is no customer administrator standing between you and the clock. Three practical consequences. Volume is orders of magnitude higher, so a manual runbook that is fine at three requests a quarter falls over at thirty a week, and self-service export and deletion inside the product stops being a nice feature and becomes the only affordable answer. Identity verification is now your problem alone and it is genuinely hard, because both over-verification (demanding identity documents you then have to store, which creates a new data class) and under-verification (handing an account's data to whoever asks) are failures. And the requester is frequently also an account holder in distress, which means account recovery, account takeover, and privacy requests arrive through the same door and get confused for one another. Build the intake so those paths are distinguished at the front, and cross-reference `se-5-consumer-account-security.md`, which owns consumer account recovery and the verification design that has to be consistent with what you do here.

1. **Intake.** A single named channel, typically `privacy@` the company domain, plus an in-product path. Every other channel (support ticket, a founder's inbox, a sales rep) must forward to it within one business day. Record the arrival timestamp; the clock starts here.
2. **Acknowledge.** Send a receipt within 72 hours stating the request type and the target completion date. Under European rules the default response window is one month, extendable by two further months for complex requests. Several United States state laws use 45 days with a 45-day extension. Your contracts may be shorter than either. Use the shortest applicable clock.
3. **Verify identity.** For consumer accounts, verification through the authenticated session or an email challenge to the account address, and see the consumer note above plus `se-5-consumer-account-security.md`: use the strongest signal the account already has rather than collecting new identity documents, and never let a privacy request become an undocumented account recovery path. For business accounts, route through the customer's designated administrator, because in most business-to-business arrangements you are the processor and the customer is the controller, and the customer decides.
4. **Determine the role.** If you are the processor, your job is to forward the request to the controller and assist, not to act unilaterally. Getting this backwards is how you delete a customer's records at the request of that customer's disgruntled ex-employee.
5. **Locate.** Walk the inventory, top to bottom, using the Deletion path column. The inventory is what makes this take hours instead of weeks.
6. **Act.** For access and portability, export in a structured, machine-readable format. For deletion, run a dry run that prints affected row counts first, get the approval named in the Danger zone section, then execute.
7. **Handle backups and derived data honestly.** Backups typically cannot be surgically edited. The accepted approach is to document that deleted data persists in backups for the backup retention period, that it is not restored into production selectively, and that it ages out. Also handle analytics warehouses, error trackers, search indexes, caches, and email marketing tools. These are where "we deleted the user" quietly fails.
8. **Respond and record.** Send the response, then log the request in a register with request date, type, subject, systems touched, completion date, and elapsed days. That register is the evidence an auditor or regulator will ask for.
9. **Measure.** Track elapsed days per request. If the median is creeping toward your promised window, that is a `RISK-REGISTER.md` entry, not a fact of life.

## Framework decision tree

Start at 1 and stop at the first match.

1. **Do you handle protected health information for a covered entity, or store or transmit cardholder data, or fall under any of the regimes in "Regulated from day one" below?** If yes, that regime is not optional and is not a choice you make on commercial grounds. Work the matching one-pager in the next section first, get counsel involved, and treat SOC 2 as a later, separate question. Otherwise continue.
2. **Does a signed contract already commit you to a named certification by a named date?** If yes, that decision was made for you. Your job is a realistic plan and, if the date is impossible, an immediate conversation with the counterparty rather than a silent miss. Log it in `RISK-REGISTER.md` today. Otherwise continue.
3. **How many pipeline deals are blocked, and what are they worth?** If the blocked annual contract value is less than about ten times the all-in first-year cost (audit plus platform plus your time), defer. Write the deferral in `DECISION-LOG.md` with a numeric revisit trigger such as "revisit when blocked annual contract value exceeds X or on date D". Otherwise continue.
4. **Where are those buyers?** Predominantly North America, choose SOC 2. Predominantly Europe, United Kingdom, Japan, Australia, or Middle East, choose ISO 27001. Genuinely split, choose the one attached to the larger blocked amount now and plan the second for twelve to eighteen months later, reusing the same controls.
5. **Type I or Type II, if SOC 2?** If the blocking deal will accept a target date, go straight to Type II with a three-month observation window. If it will not, do Type I now and commit publicly to Type II.
6. **Do the underlying controls exist?** Before scheduling any audit, confirm you have: centralized identity with multi-factor authentication (see CS-1), onboarding and offboarding with evidence (CS-3), managed endpoints (CS-2), change management with code review, logging and alerting (DR-2 and DR-3), an incident response plan that has been exercised (DR-1), vendor review, and access reviews. If more than two of these are missing, fix them first. The audit will otherwise produce exceptions that you must disclose to every customer who reads the report. This is the single most common and most expensive mistake in this cell.

Scoping rules that keep the audit from swallowing the company: scope to the production environment that serves the product, not the corporate environment beyond identity and endpoints; scope to one product or platform, not the whole roadmap; for SOC 2 include Security (the common criteria) and add Availability or Confidentiality only if a customer asked, and add Privacy only with a strong reason, because it is materially more work; for ISO 27001 write a tight Statement of Applicability and justify exclusions rather than claiming everything applies.

## Regulated from day one

Everything above treats compliance as a decision driven by pipeline value. For some companies it is not a decision at all. If the product touches health data, cardholder data, a government buyer, a supervised financial institution, certain European infrastructure sectors, or an artificial intelligence use case Europe treats as high risk, obligations attach the moment the first record is processed, whether or not anyone has ever mentioned a certification. A certification is how you eventually prove you meet an obligation. The obligation exists first, and it is already running.

**When to work this section.** Run the trigger tests below in your first week, at the same time as CO-3, before the architecture diagram is finished. If one hits, the finding it produces (for example, a covered relationship operating with no business associate agreement in place) outranks anything else on your plan, because it is already happening every day and every day adds to it. If none hits, close this section with a written "no regime applies, tested on `<date>`, retest when we enter a new market or a new data class" in `SECURITY-STATE.md` under CO-4, and move on without spending another hour here.

**Two rules that apply to every regime below.** First, the single question for counsel is a real question to a real lawyer, not a rhetorical device. Buying one to three hours of a specialist is the cheapest risk reduction available in this whole cell, and asking a general commercial lawyer a sector question wastes both your money and their time. Second, you are gathering facts and writing them down, not issuing a legal opinion. Where you cannot tell, the register entry is "ambiguous, needs counsel", exactly as in CO-3.

### HIPAA (Health Insurance Portability and Accountability Act, United States)

- **Trigger test:** does the company create, receive, maintain, or transmit protected health information on behalf of a covered entity (a healthcare provider, health plan, or clearinghouse) or another business associate? Note that this is about the relationship, not the data type. Wellness data a consumer types into your own consumer app is usually not protected health information, while the same field received from a clinic under contract usually is. If you host, process, or even just have persistent access to that data, being a "conduit" is a narrow exception that most software companies do not qualify for.
- **What attaches immediately, certification or not:** a signed business associate agreement is required before the data flows, in both directions of the chain (with your customer, and with every subcontractor who touches the data, including your cloud provider and any model provider). The Security Rule requires an accurate and thorough risk analysis, which is a written artifact, not a posture. The Breach Notification Rule gives a business associate an outer limit of 60 days from discovery to notify the covered entity, and contracts routinely shorten that to days or hours, so CO-3 governs the real number.
- **Required contract artifact:** the business associate agreement (BAA), plus a subcontractor business associate agreement with each downstream processor. Confirm your cloud provider's BAA is actually executed and that you are using only the services it covers, since the covered-service list is narrower than the full catalogue on every major cloud.
- **The single question for counsel:** "Given exactly this data flow, are we a business associate, and for which of our customer relationships, and has the company been operating without an executed business associate agreement in any of them?" There is no separate HIPAA certification to buy. Anyone selling you one is selling an audit against their own criteria.
- **Note on movement:** the Security Rule has been the subject of a proposed update that would tighten and make mandatory several practices that have long been treated as optional. Ask counsel what the current status is rather than assuming the version you read about is in force.

### PCI DSS (Payment Card Industry Data Security Standard)

- **Trigger test:** does cardholder data ever touch a system you control, including transiently in memory, in a log, in a support ticket, or in a form field on a page you serve? The whole game is answering this precisely. If payments are handled entirely by a hosted payment page or an iframe from the processor and card numbers never reach your servers, your scope is dramatically smaller. If your own form collects the number and posts it onward, you are in full scope.
- **What attaches immediately, certification or not:** the obligation flows from your merchant agreement and your processor, not from a regulator, and it applies from the first transaction. Never store the card verification value, and never log full card numbers, which are the two failures that turn a small scope into a large incident. Whichever self-assessment path applies, the annual attestation is due whether or not anyone has asked you for it.
- **Required contract artifact:** the self-assessment questionnaire matching your actual flow, plus an Attestation of Compliance (AOC). Collect the AOC from your payment processor and any other in-scope service provider as well, because your own attestation depends on theirs. The eligibility criteria for the lightest self-assessment path have been revised in recent versions of the standard, so read the current questionnaire's eligibility text directly from the PCI Security Standards Council rather than a summary.
- **The single question for counsel or your acquirer:** "Given this exact payment flow, which self-assessment questionnaire applies to us, and does our merchant agreement require anything beyond it?" Your acquiring bank or processor will answer this for free and is the more authoritative source than a lawyer here.

### FedRAMP, StateRAMP, and defense contracting (United States government buyers)

- **Trigger test:** is a United States federal agency going to use the product as a cloud service, is a state or local agency asking for a state-level authorisation, or will you handle controlled unclassified information under a defense contract or subcontract?
- **What attaches immediately, certification or not:** these are gates, not gradients. Without the authorisation, the agency generally cannot buy, so the honest early answer to a federal prospect is a timeline and a cost, not a promise. Authorisation requires a sponsoring agency or an equivalent path, a defined system boundary, use of authorised underlying infrastructure (a government cloud region rather than the commercial one is common), and United States person requirements for support staff in some programs, which is a hiring constraint, not a control. For defense work, the relevant program for controlled unclassified information is phasing into contracts, so the clause in the specific contract is what binds you.
- **Required contract artifact:** an agency sponsorship or the applicable program's authorisation package, plus flow-down clauses in the prime contract. The state-level program has changed its name in recent years, so confirm the current name and requirements from the program itself.
- **The single question for counsel:** "Which specific authorisation does this contract require, and is there a lower path (a memorandum of understanding, a pilot, a subcontract under an already-authorised prime) that gets this deal done without a multi-year program?"
- **Sizing, so nobody promises a date:** a full federal authorisation is a multi-quarter to multi-year effort with costs that begin in the mid six figures of United States dollars and rise from there. It is the single most common way a small company commits itself into an unwinnable position. Do not let it be discussed as though it were comparable to SOC 2.

### Supervised financial services (your customer is a bank, insurer, broker, or a sponsor-bank fintech)

- **Trigger test:** is the buyer a regulated financial institution, or a fintech operating under a sponsor bank? If yes, you are inside their third-party risk program, which means their regulator reaches you through their contract even though you are not directly supervised.
- **What attaches immediately, certification or not:** expect a right to audit and a right to examine, mandatory security questionnaires with genuine consequences, and contractual incident notification measured in hours. United States bank service providers have a statutory duty to notify their bank customers of a computer-security incident that materially disrupts services, and the bank itself has a short regulatory clock, which is why the number in your contract will be aggressive. Institutions in New York state and several other jurisdictions push their own cybersecurity regulation's requirements down to vendors through the contract. Expect a business continuity and exit plan requirement, which is where the recovery numbers from `m-6-backups-and-recovery.md` become contractual rather than aspirational.
- **Required contract artifact:** the customer's vendor security addendum, an incident notification clause you have read out loud and can actually meet, and evidence packages on a recurring cadence rather than once.
- **The single question for counsel:** "Which of our customers' regulatory obligations flow down to us through the signed contract, and what is the shortest notification clock in that set?" That number goes straight into CO-3 and into the incident response plan.

### NIS2 (European Union network and information security directive)

- **Trigger test:** does the company operate in the European Union in one of the listed sectors, which include digital infrastructure, cloud computing service providers, data centre services, managed service providers, and several others, and does it meet the size thresholds (broadly medium-sized or larger, with some entity types in scope regardless of size)? Because it is a directive rather than a regulation, the binding text is each member state's national transposition, and those differ. A startup can be in scope directly, which surprises people who assume it only affects utilities.
- **What attaches immediately, certification or not:** registration with the national competent authority where required, a set of risk-management measures that must be documented, and an incident reporting regime with a very short early-warning stage (an initial notification within 24 hours of becoming aware of a significant incident, a fuller notification within 72 hours, and a final report about a month later). Management bodies carry explicit accountability, which means a founder, not you, is the accountable person, and they should be told that in writing.
- **Required contract artifact:** none inherently, but customers in scope will push obligations down to you contractually, so read their addendum.
- **The single question for counsel:** "In which member states are we in scope, under which national transposition, and are we an essential or an important entity?"

### DORA (Digital Operational Resilience Act, European Union financial sector)

- **Trigger test:** do you supply information and communication technology services to European Union financial entities (banks, insurers, investment firms, payment institutions, crypto-asset service providers)? You do not have to be a financial entity yourself to be affected. If any customer is one, you are an ICT third-party service provider to them.
- **What attaches immediately, certification or not:** the customer must include specific contractual provisions with you, so expect a mandatory addendum covering audit and access rights, subcontracting restrictions, incident cooperation, service levels, and a documented exit strategy. The customer must also list you in their register of information, so expect requests for precise entity identifiers and service descriptions. Providers deemed critical at European level can be brought under direct oversight, which is unlikely for a startup but shapes the paper you are handed.
- **Required contract artifact:** the DORA-aligned addendum or the equivalent clauses inserted into the master agreement, plus your exit and continuity documentation.
- **The single question for counsel:** "Which of the mandatory contractual provisions can we actually meet today, and which do we need to negotiate or build toward before signing?"

### EU Artificial Intelligence Act

- **Trigger test:** three questions in order. Do you place an artificial intelligence system on the European Union market, or is its output used in the Union? Is your use case in the prohibited list (which includes practices such as social scoring and certain biometric categorisation)? Is it in the high-risk list, which centres on areas like employment and worker management, education, credit scoring, essential services, and biometrics? A startup selling a hiring or credit product into Europe is far more likely to be high risk than one selling developer tooling.
- **What attaches immediately, certification or not:** prohibited practices are prohibited outright. Transparency duties apply broadly and cheaply: tell people when they are interacting with an artificial intelligence system, and mark synthetic content. Obligations differ sharply depending on whether you are the provider of the system or the deployer of someone else's, and the answer determines who carries the documentation burden, so establish it early. If you are high risk, expect a risk management system, data governance, technical documentation, logging, human oversight, and a conformity assessment, which is a genuine multi-quarter program.
- **Required contract artifact:** provider-to-deployer documentation and instructions for use, plus terms with your own model providers that let you meet your obligations. This overlaps with the subprocessor and no-training-on-our-data work already in this cell.
- **The single question for counsel:** "Are we a provider or a deployer for this specific system, and is it prohibited, high risk, limited risk, or minimal risk?"
- **Note on movement:** the phase-in schedule has been the subject of amendment proposals since the act entered into force, so confirm the current dates with counsel rather than relying on any date written in a file, including this one.

### United States Securities and Exchange Commission cyber disclosure

- **Trigger test:** is the company a United States public company or a foreign private issuer? If it is private, this does not apply to you directly. It still matters twice: your enterprise customers are frequently public companies, and an incident at your company can start their disclosure clock, which is why their contracts demand notification measured in hours; and if the company is preparing to go public, diligence will ask for the governance and process the rules expect.
- **What attaches immediately for an issuer:** disclosure of a material cybersecurity incident on the prescribed form within four business days of determining that it is material (the clock runs from the materiality determination, not from discovery, and that determination must be made without unreasonable delay), plus annual disclosure of cybersecurity risk management, strategy, and governance.
- **Required contract artifact:** none, but a public-company customer will push a fast notification clause and specific cooperation duties into the agreement. Treat that as a CO-3 obligation.
- **The single question for counsel:** for an issuer, "who makes the materiality determination and how is it documented"; for a private company, "which of our customers are issuers, and what have we contractually agreed to do for them on notification".

### Recording the outcome

For each regime, write one row in `SECURITY-STATE.md` under CO-4: regime, in scope yes or no or unknown, the evidence for that answer, the date tested, and the contract artifact status. Every "in scope" with a missing artifact (a covered relationship with no business associate agreement, an unsigned addendum, an attestation nobody has produced) is a `RISK-REGISTER.md` row with a named owner and a date, and it goes to the same executive conversation CO-3 step 8 sets up rather than into a separate meeting nobody has time for. Every counsel question you ask and the answer you get goes in `DECISION-LOG.md`, because the answer is a decision the company relies on.

## Cost and effort

- Data inventory, first complete version: 3 to 5 days of your time, plus roughly 3 hours total from engineers. Cost: zero. Tools: a spreadsheet, or markdown in the repo.
- Data flow diagram: half a day. Free options include draw.io, Excalidraw, and Mermaid checked into the repo so it lives next to the code.
- Data subject request runbook, written and tested: 2 to 3 days, plus a few engineering hours to build the export or deletion path if none exists. Cost: zero to a few engineering days.
- Privacy policy, data processing agreement, and subprocessor list: 1 to 2 days of your time to gather facts. Legal review from outside counsel typically runs two thousand to eight thousand dollars for a startup package; a specialist privacy lawyer at two to five hours is often enough and is money well spent.
- Compliance automation platform: roughly seven thousand to thirty thousand dollars per year depending on employee count and framework count, often discounted heavily at seed and Series A. Free or cheap alternatives first: a spreadsheet plus the framework's own control list, and open-source cloud posture scanners such as Prowler or ScoutSuite to produce the technical evidence.
- SOC 2 Type I audit fee: roughly seven thousand to twenty thousand dollars. SOC 2 Type II: roughly twelve thousand to forty thousand dollars, higher with extra trust services criteria.
- ISO 27001 certification (stage 1 plus stage 2 audit): roughly fifteen thousand to forty thousand dollars for a small company, with surveillance audits annually and recertification every three years.
- Penetration test, which most buyers and some auditors expect alongside either framework: roughly eight thousand to twenty-five thousand dollars for a focused application test.
- Your own time for a first framework: expect 30 to 50 percent of a first security hire for three to six months. Budget it explicitly, and say out loud what you will not be doing during that period.

## 2026 notes

- The 2019 slide filled this cell with "GDPR & Current laws", which was correct then and is incomplete now. The regulatory surface grew: the California Consumer Privacy Act as amended by the California Privacy Rights Act, plus a growing set of other United States state privacy laws, plus Brazil's LGPD, Canada's PIPEDA, and India's Digital Personal Data Protection Act. The practical consequence is that you cannot enumerate every law, so you build one inventory and one set of mechanisms (access, deletion, export, correction, retention, transfer, notification) that satisfy the strictest applicable regime, and you keep a short list of the jurisdictions that actually apply to your customer base.
- Cross-border transfer mechanics changed twice since 2019. Privacy Shield was invalidated in 2020, standard contractual clauses were reissued in 2021 with a transfer impact assessment expectation, and a new European Union to United States framework followed in 2023 which itself remains subject to legal challenge. Do not hardcode a mechanism into a template you will not revisit. Record which mechanism you rely on, and treat it as something to re-check annually.
- Compliance automation platforms did not meaningfully exist as a category for startups in 2019 and are now the default. This genuinely changed the calculus: evidence collection is cheaper, the control library gives you a checklist, and auditor introductions are bundled. It did not change the underlying truth. A platform showing a red dashboard is a list of controls you have not built. Buying earlier does not make the certification arrive earlier.
- The biggest 2026 addition to this cell is artificial intelligence data flow. If any customer data is sent to a model provider, that provider is a subprocessor and belongs on the list, the contract needs a no-training-on-our-data term, and the privacy policy needs to reflect it. If engineers paste production data into a chat assistant, that is an undisclosed transfer. If you fine-tune on customer data, deletion becomes genuinely hard because the data is now in weights, and you should decide that policy before someone does it, not after. Add an "AI or model provider" flag to the inventory.
- The other addition is the data warehouse and the analytics stack. In 2019 the inventory question was mostly about the production database. In 2026 the copy of every customer record usually sits in a warehouse with broader access, weaker controls, and no deletion path, alongside error trackers and session replay tools capturing far more personal data than anyone intended. Inventory the warehouse and the observability stack with the same seriousness as production.
- Buyer behavior shifted too. Enterprise buyers increasingly ask for the SOC 2 report itself rather than the logo, read the exceptions, and check the report date and the scope. A stale report, a narrow scope, or a page of exceptions is now visible. This raises the cost of certifying before the controls exist.

## Failure modes

**The inventory is built once and never touched again.** Early tell: the Last verified column is more than six months old, or a new data store appears in a design review that is not in the table. Recovery: attach inventory updates to an event that already happens, typically the vendor approval step and the infrastructure pull request template, and put a single calendar reminder on a quarterly ten-minute reconciliation rather than a full re-survey.

**The certification is pursued before the controls exist.** Early tell: the automation platform dashboard is mostly red thirty days in, and you find yourself writing policy documents describing practices nobody follows. Recovery: pause the audit, tell the sponsor the honest date, spend the quarter on CS-1, CS-3, and DR-1, then restart. A three-month delay is far cheaper than a report full of exceptions that every prospect reads.

**Scope creep swallows the company.** Early tell: the audit scope now includes the internal tooling, a second product line, and the corporate network, and engineers are being asked for evidence weekly. Recovery: rewrite the scope statement to the narrowest set that satisfies the actual customer ask, get the sponsor to re-approve it, and communicate the reduction as a decision rather than a retreat.

**The privacy policy promises something the product cannot do.** Early tell: a deletion request arrives and the answer takes three weeks against a thirty-day published promise, or nobody can say where analytics data goes. Recovery: test the runbook, measure the real elapsed time, then either build the missing deletion path or amend the policy with counsel. Do not leave a public promise you know is false.

**You become the questionnaire and privacy help desk.** Early tell: more than a quarter of your week is spent answering the same questions for sales. This is the exact failure the 2019 talk warned about: your highest and best use is not completing questionnaires. Recovery: push the answers into the knowledge base (CO-2), publish the trust page (CO-1), and hand sales a self-service path.

**Compliance work displaces risk reduction entirely.** Early tell: a full quarter of tickets are documentation, and no technical control shipped. Recovery: hold a fixed floor, for example one day per week reserved for engineering controls regardless of audit pressure, and report both streams separately to the executive team so the tradeoff is visible rather than silent.

**Nobody owns the inventory after you move on to the next thing.** Early tell: the Owner column has team names instead of humans, or the owner has left the company. Recovery: assign a named human per row and confirm each one acknowledged it in writing. An owner who did not agree to be the owner is not an owner.

## Related cells

- [CO-1: public facing security docs](co-1-public-security-docs.md), which publishes the subprocessor list and the trust page this cell produces the facts for.
- [CO-2: questionnaire knowledge base](co-2-questionnaire-knowledge-base.md), which is fed almost entirely by the inventory and the framework status.
- [CO-3: understand existing commitments](co-3-existing-commitments.md), the closest neighbor; step 6 of the walk is shared work.
- [SE-3: secrets and keys](se-3-secrets-and-keys.md), because credentials in the inventory are their own asset class.
- [DR-1: incident response plan](dr-1-incident-response-plan.md), which consumes the breach notification obligations recorded here.
- [DR-3: logging consumption model](dr-3-logging-consumption-model.md), because logs contain personal data and are subject to the retention decisions made here.
- [CS-1: identity and access management](cs-1-identity-and-access.md), which supplies the "who can read it" column and is a prerequisite control for any framework.
- [CS-3: onboarding and offboarding](cs-3-onboarding-offboarding.md), the other prerequisite control every auditor tests first.
- [SE-5: consumer account security](se-5-consumer-account-security.md), which owns account recovery and verification for consumer products and has to agree with the identity verification step in the data subject request runbook.
- [M-6: backups and recovery](m-6-backups-and-recovery.md), because the backup carve-out in a deletion promise and any contracted recovery objective both depend on measured facts from there.
- [08: when it is not working](08-when-it-is-not-working.md), Part B, for the refusal procedure when the company wants a compliance claim the evidence does not support.
- [Modern cells](07-modern-cells.md) for software-as-a-service and OAuth sprawl and for artificial intelligence data flow, both of which add rows to this inventory.
- [2019 to 2026 delta](06-2019-to-2026-delta.md) for why the compliance domain was framed as documentation rather than as data.
