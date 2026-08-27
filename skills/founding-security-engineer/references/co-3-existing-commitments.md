# CO-3: Understand existing commitments

> **Grid coordinate:** CO-3, Compliance domain, cell 3.
> **Original 2019 wording (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019, slide 18):** "Understand existing commitments".
> **Speaker's framing (verbatim from the deck's speaker notes):** "Before security folks join a startup it's really common for the business to make commitments to future compliance standards that they might not be ready for... 'We will have SOC2 Type2 in 3 months'. That's not a good situation to be in."
> **Load when:** the human is in their first 30 days, or a customer contract or auditor or insurer has just raised a requirement nobody knew about, or the human is about to build a roadmap and needs to know what is already owed, or someone says "we already told the customer we do that".

## Why this cell exists

Before you were hired, your company signed things. Sales people answered questionnaires, founders signed contracts, marketing published pages, and an insurance broker got a filled-in application form. Every one of those is a promise that a court, an auditor, a customer, or an insurer can hold you to, and almost none of it was written by someone who understood the security implications. You are now the person responsible for keeping promises you did not make and have not read.

This cell is the cheapest high-value work available to a first security hire, because it converts unknown obligations into a written list. That list then tells you what your roadmap must contain, which risks you must formally accept, and where the company is already technically in breach. Most first security hires skip this and spend a quarter building controls nobody asked for while a signed contract quietly requires 24 hour breach notification that the company cannot meet.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A **commitment register** exists as a file in the state directory, listing every discovered obligation with source document, clause reference, obligation text summary, owner, current status (met / partially met / not met / unknown), and deadline if any.
- [ ] You have read the **security exhibit, data protection addendum, and service level terms** of the company's top 10 customers by annual contract value, plus any customer flagged by sales or legal as "the one we cannot lose".
- [ ] You have read the company's **standard contract templates** (the master services agreement or terms of service the company offers by default, and the data processing addendum) and know what they commit to on every future deal.
- [ ] You know the **shortest breach notification window** the company has agreed to anywhere, and that number is written into the incident response plan (see `dr-1-incident-response-plan.md`).
- [ ] You know every **compliance certification or framework** the company has publicly or contractually promised, with the promised date and who promised it.
- [ ] You have read the **cyber insurance policy** (if one exists) including its conditions, exclusions, and required controls, and you know what would void coverage.
- [ ] Every obligation currently **not met** appears in `RISK-REGISTER.md` with a named owner and either a remediation date or an explicit written acceptance by an executive.
- [ ] The **CEO or the person who owns revenue has seen the list**, specifically the not-met rows. This is a single meeting, not a program.

Explicitly **not required** at this stage:

- A contract lifecycle management tool or any purchased software.
- A legal review of every historical contract. Top 10 by value plus every enterprise-tier customer plus templates is enough.
- A formal obligations-to-controls traceability matrix. That is a SOC 2 or ISO 27001 artifact and it comes later, in `co-4-data-inventory-and-framework.md`.
- Renegotiating anything. You are reading, not fixing, in this cell.
- Reading vendor contracts where the company is the buyer, in the first pass. That matters (see The walk, step 7) but it is second-priority behind commitments the company made outbound.

## Discovery

Almost none of this lives in a code repository. Expect to spend most of this cell asking humans for access rather than running commands. Start with what you can read without asking anyone.

**Public surfaces you can read with zero access, right now.** These are commitments too, and they are the ones the company most often forgets it made.

```bash
# Replace example.com with the company domain. All read-only.
curl -sL https://example.com/security     | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/privacy      | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/terms        | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/dpa          | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/sla          | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/trust        | sed 's/<[^>]*>//g' | tr -s '\n'
curl -sL https://example.com/sitemap.xml  | grep -Eio '<loc>[^<]+</loc>' | grep -Ei 'secur|privac|trust|complian|terms|dpa|sla|gdpr|hipaa|sub-?process'
```

Then check the archived versions, because a page that was quietly removed is still a promise made to whoever read it and is still in someone's procurement file. Open `https://web.archive.org/web/*/example.com/security*` in a browser and compare against today.

**Search the code and documentation you do have access to.** Contracts leak into repositories more often than people expect: sales engineers commit questionnaire answers, and legal terms end up in the marketing site repo.

```bash
# Run from the repo root, or from a directory containing several cloned repos. Read-only.
grep -rIn --exclude-dir=.git -Ei \
  'soc ?2|iso ?27001|hipaa|pci[ -]?dss|fedramp|gdpr|ccpa|cpra|hitrust|business associate|\bBAA\b' . \
  | head -50

grep -rIn --exclude-dir=.git -Ei \
  'uptime|99\.9|service level|breach notif|within [0-9]+ (hours|business days)|right to audit|penetration test' . \
  | head -50

# Marketing sites often hold the legal pages as content files.
find . -type f \( -iname '*terms*' -o -iname '*privacy*' -o -iname '*dpa*' -o -iname '*sla*' -o -iname '*security*' \) \
  \( -name '*.md' -o -name '*.mdx' -o -name '*.html' \) 2>/dev/null | head -40
```

**Where the contracts actually live, by tool.** Ask which of these the company uses; do not guess.

- **Dedicated contract or e-signature tools:** DocuSign, Dropbox Sign, PandaDoc, Ironclad, Juro, Adobe Acrobat Sign. The completed-agreements folder in the e-signature tool is usually the most complete record that exists at a startup. Console path in DocuSign: Agreements, then Completed, then filter by date range. You need at least a read-only or "shared folder viewer" role.
- **The customer relationship management system:** Salesforce, HubSpot, Pipedrive, Attio. Signed order forms and redlined agreements are attached to the closed-won opportunity record. In Salesforce, ask for read access to the Opportunity object and the Files related list, filtered to `StageName = Closed Won`. In HubSpot, look at Deals in the Closed Won stage and their Attachments.
- **Shared drives:** Google Drive (a "Legal" or "Contracts" shared drive), Microsoft SharePoint or OneDrive, Dropbox, Box, Notion. Ask for viewer access to the specific folder, not the whole drive.
- **The billing system:** Stripe, Chargebee, Recurly, or the invoicing spreadsheet. This gives you the ranked customer list by revenue, which is how you decide which contracts to read first.
- **Nowhere at all.** At a 20 person company it is common for signed PDFs to live in the CEO's or the head of sales' email. In that case the fastest route is a single question to that person, not a search.

**If you have no access to any of it,** do not stall. You can still complete roughly 40 percent of this cell from public pages, the standard templates (usually published on the website), the sales collateral (ask a sales rep for the current security one-pager and the last three questionnaire responses), and the insurance policy (ask the finance or operations lead, who has it because they pay for it). Record every access gap in `ACCESS-LOG.md` with the date requested and the person asked, then move on to the parts you can do.

## Ask the human

Closed questions. Ask them in this order, one at a time, and record the answers in `SECURITY-STATE.md` under the CO-3 section.

1. Who signs customer contracts today: the chief executive, a head of sales, or outside counsel?
2. Is there a lawyer involved, and is it in-house counsel, a retained law firm, or nobody?
3. Where do signed customer agreements get stored? Name the specific tool or folder.
4. Does the company have a standard master services agreement and data processing addendum it offers, or does it sign the customer's paper?
5. Has anyone ever committed in writing to a compliance certification (SOC 2, ISO 27001, HIPAA, PCI DSS, FedRAMP) with a date attached? If yes, who made the commitment and when is it due?
6. Does the company carry cyber liability insurance? Who is the broker and where is the policy document?
7. Are there customers in the European Union, the United Kingdom, or California? Are there customers who send us health data, payment card data, or data about children?
8. Has a customer ever asked to perform a penetration test or an on-site audit of us?
9. Has any customer contract ever been escalated because we failed to meet a security or availability term?
10. Did a founder sign any side letter, letter of intent, or email promise outside the standard contract process?

**Copy-pasteable message to get contract access.** Send to whoever owns legal or revenue operations.

> Hi. I have just started as the first security hire, and my first job is to find out what we have already promised customers so I do not build the wrong things. Could you give me read-only access to where signed customer agreements live (the completed folder in our e-signature tool, or the contracts folder in the shared drive)? If read-only access to everything is too broad, I would settle for exported copies of our top 10 customers by annual contract value plus our standard master services agreement, data processing addendum, and service level terms. Specifically I am looking for the security exhibits and any clause about breach notification, audit rights, and certifications we promised. Happy to sign whatever confidentiality paperwork you need. If it is easier, we can do it in a 30 minute screen share and I will take notes rather than getting standing access.

**Copy-pasteable message to sales.** Send to the head of sales or the sales engineer who fills in questionnaires.

> Quick ask. I am building the list of security commitments we have already made, so I can make sure our roadmap actually covers them. Could you send me: (1) the last three security questionnaires we filled in and returned, (2) the current security slide or one-pager we send to prospects, and (3) any deal where we told the customer we would have a certification or a specific control by a date. I am not auditing anyone. I would rather find out from you than find out from a customer's auditor.

**Copy-pasteable message to finance or operations about insurance.**

> Do we carry cyber liability insurance? If so, could you send me the full policy document and the application form we submitted when we bought it? Insurers ask for specific controls on the application, and if we answered yes to something we do not actually do, a claim can be denied. I want to check that before we ever need to file one.

## The walk

Do these in order. Each step should end with something written into a state file. Do not start step 2 until step 1 has produced a real artifact.

**Step 1: Read the public pages and write down what they promise.**
- **Goal:** Have five to fifteen concrete public commitments in writing within the first hour, with zero dependency on anyone else.
- **Do:** Run the `curl` commands in Discovery. For each page, extract any sentence that makes a factual claim about a control ("all data is encrypted at rest", "we undergo annual penetration testing", "we are SOC 2 Type II certified", "99.9 percent uptime"). Create `COMMITMENT-REGISTER.md` in the state directory using the template below and enter one row per claim, source `Public website`, status `unknown`.
- **Verify:** The register has at least one row per public page that exists. For each row you can quote the exact sentence from the page.
- **Time:** 1 to 2 hours.
- **Who else is needed:** Nobody. This is the day-one value delivery step.

**Step 2: Get access to the contract store.**
- **Goal:** Read-only visibility into signed customer agreements.
- **Do:** Send the copy-pasteable legal message above. Record the request in `ACCESS-LOG.md` with date, person, system, and scope requested. If the answer is "we do not have one place", ask instead for the top 10 customers by annual contract value as PDF exports.
- **Verify:** You can open at least one signed customer agreement and see a signature page with a date.
- **Time:** 15 minutes to send, 1 to 5 days to land.
- **Who else is needed:** Legal, revenue operations, or the chief executive.

**Step 3: Read the standard templates first, not the individual deals.**
- **Goal:** Understand the baseline the company offers on every future deal, which is a bigger lever than any single signed contract.
- **Do:** Read the standard master services agreement or terms of service, the data processing addendum, the security exhibit, and the service level agreement. Run each through the clause extraction checklist below. Add one register row per extracted obligation, source `Standard template`.
- **Verify:** You can state, without looking, the breach notification window, the uptime commitment, and the liability cap in the standard paper.
- **Time:** Half a day.
- **Who else is needed:** Whoever can answer "is this actually the current version". Templates rot; ask.

**Step 4: Read the top 10 signed customer agreements, worst-case first.**
- **Goal:** Find the negotiated terms that are stricter than the template, because those are the ones that will bite.
- **Do:** For each, apply the clause extraction checklist. Pay attention to redlines: an enterprise customer's legal team almost always tightened breach notification, added audit rights, or added a data residency requirement. Record every obligation that differs from the template as its own register row with the customer name.
- **Verify:** For each of the ten, the register has either at least one row or an explicit row saying "no security-specific terms beyond template, reviewed on <date>".
- **Time:** 1 to 2 days.
- **Who else is needed:** Legal or the account owner if a clause is ambiguous. Do not guess at legal meaning; ask.

**Step 5: Compute the binding worst case and hand it to incident response.**
- **Goal:** Turn a pile of clauses into the three numbers your incident response plan actually needs.
- **Do:** Across all contracts, find (a) the shortest breach notification window, (b) the broadest definition of what counts as a reportable "security incident" (some contracts require notifying on any unauthorised access attempt, not just a confirmed breach), and (c) the customers who must be notified in writing to a named contact rather than by email blast. Write these three findings into `SECURITY-STATE.md` under CO-3, and hand them to DR-1 to be written into the incident response plan itself. The incident response plan is DR-1's document, not a file this cell creates: `dr-1-incident-response-plan.md` tells you where it lives, and whichever location the company chooses (a wiki page, a document, or a file next to the state directory) is recorded once in `SECURITY-STATE.md` under DR-1 so that every cell that needs to link to it links to the same place. If that location is not recorded yet, record it now, because three separate cells write to this document and none of them can do so if it has no address.
- **Verify:** The incident response plan states a specific number of hours and cites the contract it came from, and `SECURITY-STATE.md` names the location of that plan.
- **Time:** 2 hours.
- **Who else is needed:** Nobody, but tell the chief executive the number.

**Step 6: Read the cyber insurance policy and its application form.**
- **Goal:** Know the conditions that would void coverage, before a claim.
- **Do:** Read the policy for: required controls (multi-factor authentication on email and remote access is the most common condition in current policies), notification deadlines to the insurer (often much shorter than to customers, sometimes 72 hours or "as soon as practicable"), the approved incident response vendor panel (using an unapproved forensics firm can reduce or void reimbursement), sublimits for ransomware and social engineering fraud, and retroactive date. Then read the application form the company submitted and check every yes answer against reality.
- **Verify:** For every control the application claimed, you have either confirmed it exists or opened a `RISK-REGISTER.md` row. If the application claimed multi-factor authentication everywhere and it is not, that is a top-of-register item.
- **Time:** Half a day.
- **Who else is needed:** Finance or operations for the documents, the broker for interpretation. Brokers answer these questions free.

**Step 7: Sweep the second-tier sources.**
- **Goal:** Catch the commitments that do not live in customer contracts.
- **Do:** In one pass, collect: past questionnaire responses (every answered questionnaire is a written representation), sales decks and one-pagers, request for proposal responses, any letter of intent or side letter, vendor contracts where the company is the customer (their breach notification duty to you, their sub-processor rights, their data deletion terms, and the flow-down obligations you inherited), open source license obligations for anything the company ships or distributes (copyleft licenses such as GPL and AGPL create distribution and source-availability obligations, and attribution licenses such as MIT and Apache 2.0 create notice obligations), and regulatory scope. On regulatory scope, determine plainly: does the company process personal data of people in the European Union or United Kingdom (General Data Protection Regulation applies), California residents (California Consumer Privacy Act as amended by the California Privacy Rights Act), protected health information on behalf of a covered entity (Health Insurance Portability and Accountability Act, which requires a signed business associate agreement), or payment card data (Payment Card Industry Data Security Standard, and the scope depends heavily on whether card data ever touches your systems or goes straight to a payment processor).
- **Verify:** Every source category above has either register rows or a written "checked, none found, date".
- **Time:** 1 to 2 days.
- **Who else is needed:** Sales for collateral, engineering for the payment flow question, the chief executive for side letters.

**Step 8: Rank, assign, and hold the one uncomfortable meeting.**
- **Goal:** Get executive acknowledgement of the gaps in one sitting, so they become the company's problem and not just yours.
- **Do:** Filter the register to rows with status `not met` or `unknown`. Rank by (contract value at risk) times (likelihood the gap is discovered) and put anything with a hard deadline at the top. Bring a one page list, not the register. For each row propose one of three outcomes: fix by a date, renegotiate the clause, or formally accept the risk. Do not bring a fourth option.
- **Verify:** Every row leaves the meeting with an owner name and one of the three outcomes, recorded in `DECISION-LOG.md` with the date and the approver's name.
- **Time:** 2 hours to prepare, 1 hour meeting.
- **Who else is needed:** Chief executive, head of sales, legal if it exists.

## Decision points

**Do you read every contract, or sample?**
DEFAULT: sample. Read the standard templates in full, plus the top 10 customers by annual contract value, plus any customer explicitly named as strategic, plus any customer in a regulated industry regardless of size. That is typically 12 to 20 documents and it captures the overwhelming majority of real obligation. Change this if the company sells only a handful of very large deals (then read all of them) or if a specific customer is already in dispute (read that one first).

**Do you tell the chief executive about a broken promise immediately, or after you have a fix plan?**
DEFAULT: tell them within one business day of confirming it, with a proposed plan attached but explicitly labelled as a draft. Delay converts a shared problem into a personal cover-up. Change this only if the promise is already legally in dispute, in which case route it through counsel first so the conversation stays privileged.

**Do you push to renegotiate a clause the company cannot meet, or fix the gap?**
DEFAULT: fix the gap if it is achievable in under a quarter, renegotiate at renewal if it is not. Renegotiating mid-term signals weakness to the customer and burns account team goodwill you will need later. Change this if the clause is genuinely impossible (for example a 24 hour notification duty at a company with no monitoring at all and no plan to build any), in which case raise it before you are in breach rather than after.

**Do you buy a contract management tool?**
DEFAULT: no. A markdown table in the state directory or a shared spreadsheet is correct until roughly 200 customers. Change this if the company already owns a contract lifecycle tool through legal, in which case use their instance rather than building a shadow copy.

**Who owns the commitment register long term?**
DEFAULT: you own it for the first two quarters, then hand it to legal or revenue operations with security keeping a review right on new security clauses. Change this if in-house counsel already exists and wants it on day one, in which case give it to them and ask to be a required reviewer on any contract containing a security exhibit.

**Do you gate future deals on a security review of the paper?**
DEFAULT: yes, but lightly. Ask to be looped in on any agreement containing a security exhibit, a data protection addendum, or a promised certification date. Do not ask to review every contract; you will become the bottleneck and sales will route around you within a month.

## Danger zone

These need an explicit human yes before you act, and in most cases the yes must come from the chief executive or counsel, not from your manager.

- **Telling a customer directly that the company is out of compliance with their contract.** This can trigger contractual notification duties, termination rights, and refund obligations. It may also be the legally correct thing to do. Route it through the chief executive and counsel. Never send this yourself.
- **Writing "we are in breach of the Acme contract" in a durable document.** This is discoverable in litigation. Use neutral factual language ("Control X described in Exhibit B is not currently implemented; owner Y; target date Z") and ask counsel whether the register should be kept under attorney-client privilege. This is a real question with a real answer at most companies; ask it once, early.
- **Contacting the insurance broker or insurer about a gap in the application answers.** Insurers can rescind a policy for material misrepresentation. Do not open this conversation without the chief executive and finance in the room, and prefer to correct the record at renewal with counsel's guidance.
- **Removing or changing a public security or trust page** because it overclaims. Changing it is often right, but marketing and legal must approve, the change is archived publicly by third parties anyway, and a customer may have relied on the old text. Propose the edit, do not make it.
- **Committing to a certification date yourself.** A SOC 2 Type II report requires an observation window (commonly three to twelve months) after controls are operating, plus auditor fieldwork. If you say "we will have it by March" and you are wrong, that becomes the next commitment in this register. Give ranges and dependencies, and put the promise in `DECISION-LOG.md` with who approved it.
- **Requesting broad standing access to the customer relationship management system or the full shared drive.** Over-broad access to commercial and personal data creates the exact risk you are hired to reduce, and it looks bad in your own access review later. Request the narrowest scope that works and log it in `ACCESS-LOG.md`.

Cost and outage risk in this cell is low, because you are reading. The real risk is reputational and legal: a badly worded finding, sent to the wrong person, can cost the company a customer.

## Do not do this yet

- **Do not build an obligations-to-controls traceability matrix.** It is the right artifact eventually and the wrong one now. You do not yet know what controls exist. Finish the register first, then let `co-4-data-inventory-and-framework.md` drive the mapping.
- **Do not try to fix the gaps while you are still finding them.** Discovery and remediation are different modes. If you start fixing at document three, you will never read document eleven, and document eleven is where the 24 hour notification clause is.
- **Do not read every historical contract back to incorporation.** Diminishing returns after the top tier, and expired contracts usually still bind you only on surviving clauses (confidentiality, data deletion, indemnity), which you can check in one pass at the end.
- **Do not audit vendor contracts in depth in the first pass.** Note them, then handle them properly once you have a vendor list from `co-4-data-inventory-and-framework.md`. Inbound promises you made outrank outbound promises made to you.
- **Do not turn this into a legal opinion.** You are extracting and summarising obligations, not interpreting enforceability. When a clause is ambiguous, write "ambiguous, needs counsel" in the register and move on. Guessing at contract law is how a first security hire loses credibility with the one lawyer they need.
- **Do not build a questionnaire response process yet.** That is `co-2-questionnaire-knowledge-base.md` and it will be far better once you know what the contracts actually say.

## Evidence to capture

Write to these exact files and sections.

| What | Where |
| --- | --- |
| The commitment register itself | `COMMITMENT-REGISTER.md` in the state directory (default `./.security/`, or `~/security-program/<org-slug>/` when there is no repo) |
| CO-3 status (`unknown` / `none` / `partial` / `done`) plus which sources have been reviewed and which are still blocked | `SECURITY-STATE.md`, section "CO-3 Existing commitments" |
| Every obligation with status `not met` or `unknown`, with severity, owner, and decision | `RISK-REGISTER.md`, one row per obligation, tagged `source: CO-3` |
| Every decision from the step 8 meeting: fix, renegotiate, or accept, with date and approver name | `DECISION-LOG.md` |
| Every access request made for contracts, the customer relationship management system, the drive, or the insurance policy, with date, scope, and outcome | `ACCESS-LOG.md` |
| The shortest breach notification window and the broadest incident definition | `SECURITY-STATE.md` under CO-3, and copied into the incident response plan at whatever location `SECURITY-STATE.md` records under DR-1 |
| Any deadline-bearing commitment (a promised certification date) | `90-DAY-PLAN.md`, as a fixed anchor the plan must route around |

**Artifacts a future auditor or enterprise customer will ask for:** the commitment register or its equivalent (auditors call this a register of contractual and regulatory obligations and it is an expected input to a SOC 2 or ISO 27001 scoping exercise), evidence that obligations are reviewed periodically (a dated review note is enough), and evidence that gaps are tracked to closure or formally accepted by management. The last one is the part startups miss, and a signed acceptance in `DECISION-LOG.md` satisfies it.

### Commitment register template

Create `COMMITMENT-REGISTER.md` with this table. One row per obligation, not per contract.

```markdown
# Commitment Register

Last updated: YYYY-MM-DD
Owner: <name>
Review cadence: quarterly, and on every new contract containing a security exhibit

| ID | Source document | Clause ref | Counterparty | Obligation (plain English) | Type | Deadline | Status | Owner | Evidence | Notes |
|----|-----------------|-----------|--------------|----------------------------|------|----------|--------|-------|----------|-------|
| C-001 | Acme MSA, signed 2024-11-02 | Exhibit B, 3.2 | Acme Corp | Notify Acme in writing within 24 hours of confirmed unauthorised access to their data | Breach notification | Ongoing | not met | Head of Security | none | Shortest window in the portfolio. Drives DR-1. |
| C-002 | Public /security page | n/a | Everyone | "All customer data is encrypted at rest and in transit" | Public claim | Ongoing | unknown | Head of Security | pending | Need to confirm for the analytics data store |
| C-003 | Standard MSA v3 | 9.1 | All future customers | 99.9% monthly uptime with service credits | Availability | Ongoing | partial | VP Engineering | status page | Not a security control but security incidents consume the budget |
| C-004 | Cyber policy, 2025 renewal | Conditions, 4(c) | Insurer | Multi-factor authentication on all remote access and email | Insurance condition | Ongoing | not met | Head of IT | none | Failing this can void a claim. Top of risk register. |

Status values: met / partial / not met / unknown / accepted / renegotiated.
Type values: breach notification / audit right / pen test right / availability / data residency /
deletion and return / subprocessor notice / certification deadline / encryption / insurance
condition / liability / regulatory / open source license / public claim / other.
```

### Contract clause extraction checklist

For each document, look for and record each of these. Absence is a finding too; write "silent" rather than leaving it blank.

1. **Breach or security incident notification.** How many hours or days, from what trigger (discovery, confirmation, or reasonable belief), to whom, in what form, and with what required content. The trigger matters more than the number.
2. **Definition of a reportable incident.** Some contracts define it broadly enough to include failed access attempts or a lost laptop with no data on it.
3. **Audit rights.** Can the customer audit you, how often, with how much notice, at whose cost, and can they send a third party? Look for "on-site" specifically.
4. **Right to perform penetration testing.** Whether the customer may test your production systems, with what notice, and whether they may publish results.
5. **Uptime, availability, and service credits.** The commitment, the measurement method, the exclusions, and the credit formula.
6. **Data residency and cross-border transfer.** Must data stay in a named country or region? Are standard contractual clauses referenced or attached? Does the addendum name a specific transfer mechanism?
7. **Deletion and return of data on termination.** How many days, in what format, and whether certification of deletion is required. Check whether backups are carved out, because they usually are not and that is a real engineering problem.
8. **Sub-processor rights.** Must you publish a sub-processor list, give advance notice of changes (commonly 30 days), and allow the customer to object? Adding a new vendor may be a contractual event.
9. **Certification and framework commitments.** SOC 2 Type I or Type II, ISO 27001, HITRUST, PCI DSS, FedRAMP, with dates and whether you must share the report.
10. **Encryption requirements.** Specific algorithms, key lengths, key management requirements, or customer-managed key obligations.
11. **Personnel requirements.** Background checks, security awareness training, confidentiality agreements, and whether subcontractors and offshore staff are permitted.
12. **Insurance minimums.** Required coverage types and dollar limits the company must carry and evidence on request.
13. **Liability cap and its carve-outs.** Whether a data breach is carved out of the cap or has a super-cap. This single clause determines how much a breach actually costs and belongs in `RISK-REGISTER.md` verbatim.
14. **Indemnity for data breach.** Who defends and pays when the customer's customers sue.
15. **Vulnerability remediation timelines.** Some enterprise exhibits commit you to fixing critical vulnerabilities within a fixed number of days.
16. **Business continuity and disaster recovery objectives.** Recovery time objective and recovery point objective, stated as numbers. Record the contracted numbers exactly as written, then compare them against the measured drill result from `m-6-backups-and-recovery.md`. If no drill has been run, the register status for that row is `unknown`, never `met`. A contracted recovery time nobody has ever measured is one of the most common not-met rows in this whole register, and it is invisible until the day it matters.
17. **Regulatory hooks.** A business associate agreement (health data), payment card obligations, or references to a specific regulation.
18. **Assignment and change of control.** Rarely security-relevant, but a customer's right to terminate on acquisition can make an unresolved gap suddenly urgent during diligence.

## Cost and effort

- **Total effort for a first pass:** 4 to 8 working days spread over 2 to 3 weeks, because most of the elapsed time is waiting on access. Steps 1 and 3 alone deliver most of the value and take under two days.
- **Ongoing:** roughly half a day per quarter to review, plus 30 minutes per new contract with a security exhibit.
- **Free options, use these first:** the register as a markdown file or a shared spreadsheet, read-only access to existing tools you already pay for, and the insurance broker's free interpretation of your own policy. Total cost zero.
- **Outside counsel review** of the standard templates and the security exhibit: roughly 2 to 6 billable hours, commonly in the 500 to 3,000 US dollar band depending on firm and market. Worth it once, for the templates only, not for individual deals.
- **Contract lifecycle management software** (Ironclad, Juro, and similar): typically low tens of thousands of US dollars per year. Do not buy this as a security hire. If legal wants it, that is their budget line and their decision.
- **Compliance automation platforms** (Vanta, Drata, Secureframe, or the free-tier open source project Comply): typically 8,000 to 30,000 US dollars per year at startup scale. They help with `co-4`, not with this cell. They do not read your contracts.

## 2026 notes

The 2019 slide treated this cell mainly as "the business promised SOC 2 too early". That failure mode is still the most common one, and it is worse now because compliance automation vendors sell a story where a certification is a few weeks of dashboard work, which encourages founders to promise dates that ignore the observation window a Type II report requires.

Four things have changed materially since the original talk:

1. **Data protection addendums are now standard on almost every business-to-business deal, not just European ones.** The General Data Protection Regulation made them normal, and the California Privacy Rights Act, plus a growing set of United States state privacy laws with contractual requirements for service providers, made them near-universal. The practical effect is that the average startup now has sub-processor notice obligations it does not know about, and adding a new vendor or a new model provider can be a contractual event requiring customer notice. Check clause 8 of the checklist before your team adopts a new tool, not after.

2. **Cyber insurance became conditional.** Policies in the current market commonly require multi-factor authentication on remote access, email, and privileged accounts as a condition of coverage, not a discount. Application forms ask specific control questions and insurers have denied claims on the basis of inaccurate answers. Reading the application form the company already submitted is now one of the highest-value hours in this cell, and it did not exist as a concern in 2019.

3. **Artificial intelligence clauses are appearing in customer paper.** Enterprise customers increasingly add terms prohibiting the use of their data to train models, requiring disclosure of which model providers are used as sub-processors, requiring human review of automated decisions, or requiring notice before adding an artificial intelligence feature. If engineering has wired a large language model provider into a product path, check whether any signed contract forbids it. This is a live source of accidental breach at startups right now, because the engineering change is a one-line configuration and the contract review is nobody's job.

4. **Breach notification windows have compressed and multiplied.** Contractual windows of 24 to 72 hours are common, regulatory windows vary by jurisdiction and sector, and insurers impose their own. The number that matters is the shortest one across all three, and you cannot know it without doing this cell. See `dr-1-incident-response-plan.md`, which should consume this number rather than inventing one.

## Failure modes

**You find nothing because you searched files instead of asking people.**
*Early tell:* your register has only public website rows after a week. *Recovery:* stop searching, send the two copy-pasteable messages in Ask the human, and book 30 minutes with the head of sales. At a startup this information is in people's heads and inboxes, not in a system.

**You build a beautiful register nobody acts on.**
*Early tell:* the register has 60 rows and `DECISION-LOG.md` has none. *Recovery:* run step 8 immediately. Cut the list to the five rows that could cost a customer or void insurance and bring only those. A register with no executive decisions attached is a document, not a control.

**You surface a broken promise in a way that gets you labelled as the department of no.**
*Early tell:* sales stops inviting you to deal calls. *Recovery:* change the framing. Bring every finding with a proposed fix, a rough date, and an explicit statement of what you are not asking for. Say "here is what we owe Acme and here is how we get there by June", never "we are in breach". Ask the account owner to review your wording before it goes anywhere near the customer.

**Legal blocks your access and the cell stalls.**
*Early tell:* two weeks of "I will get to it". *Recovery:* drop the standing-access ask and offer the 30 minute screen share instead. Reading over someone's shoulder and taking notes gets you 80 percent of the value with none of the access-control debate. Log the outcome in `ACCESS-LOG.md` either way.

**You discover a certification promise with an impossible date and freeze.**
*Early tell:* you find the commitment and do not raise it for a week. *Recovery:* raise it within one business day with three options: accelerate with outside help and a stated cost, deliver a narrower scope first (a Type I report or a narrower system boundary), or go back to the customer early with a revised date. Customers accept a revised date given three months' notice far more often than they accept a missed one given three days'.

**The company signs a new contract with a stricter clause while you are still reading the old ones.**
*Early tell:* a customer name appears in a deal announcement that is not in your register. *Recovery:* accept that the register is a living file, and add the lightweight gate from Decision points: ask to be looped in on any agreement containing a security exhibit. One Slack or Teams channel and one clear trigger is enough. Do not build an approval workflow.

## Related cells

- [`co-1-public-security-docs.md`](co-1-public-security-docs.md) - the public claims you find here become the source of truth for what the trust page may say.
- [`co-2-questionnaire-knowledge-base.md`](co-2-questionnaire-knowledge-base.md) - past questionnaire answers are commitments; the register is the input to a truthful knowledge base.
- [`co-4-data-inventory-and-framework.md`](co-4-data-inventory-and-framework.md) - the framework choice should be driven by what customers already contractually require, not by what is fashionable.
- [`dr-1-incident-response-plan.md`](dr-1-incident-response-plan.md) - consumes the shortest breach notification window and the notification contact list.
- [`m-6-backups-and-recovery.md`](m-6-backups-and-recovery.md) - the only source for a measured recovery time objective, which is what turns a contracted recovery clause from an assumption into a status you can defend.
- [`se-4-bug-bounty-and-disclosure.md`](se-4-bug-bounty-and-disclosure.md) - customer rights to penetration test and to receive results interact with your disclosure posture.
- [`03-90-day-plan.md`](03-90-day-plan.md) - deadline-bearing commitments are fixed anchors the plan must route around.
- [`05-metrics-and-comms.md`](05-metrics-and-comms.md) - the not-met list is the strongest budget argument a first security hire has.
- [`02-intake-questions.md`](02-intake-questions.md) - the broader intake question bank, of which the CO-3 questions here are a subset.
