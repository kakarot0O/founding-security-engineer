# CO-2: Knowledge base for questionnaires

> **Grid coordinate:** CO-2, Compliance domain, cell 2.
> **Original 2019 wording:** "Knowledge base for questionnaires" (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019, slide 18). His speaker note on this cell is the whole thesis: "Your highest and best use is not completing questionaires for sales teams. You need to figure a way to make it self service, to use a tool so that folks can complete them theirselves. If you spend all your time on questionaires then you will have issues making real strides forward."
> **Load when:** the human mentions a security questionnaire, a vendor security review, a SIG (Standardized Information Gathering questionnaire), CAIQ (Consensus Assessments Initiative Questionnaire), or VSA (vendor security assessment) spreadsheet, a customer security addendum, a sales deal blocked on security, a "quick security review" from a prospect, or asks how to answer a customer's security questions. Also load when CO-1 (public security docs) is being built, because the knowledge base and the public trust page share a source of truth.

## Why this cell exists

When a startup starts selling to companies bigger than itself, those companies send a spreadsheet of security questions before they will sign. Someone has to answer it, and by default that someone is you, because you are the only person who knows the answers. Each spreadsheet takes between four hours and three days, they arrive with no warning, and they always arrive attached to revenue, which means they always feel urgent. If you answer each one from scratch you will spend your entire first year as a very expensive spreadsheet clerk and the actual security of the company will not improve by one inch.

The fix is boring and it works: answer each question exactly once, store the answer somewhere reusable with an owner and a date and a link to proof, and make the sales team the one who does the copying. You become the reviewer and the escalation path, not the typist.

## Definition of done

For a 20 to 100 person startup, this cell is done when all of the following are true:

- [ ] Every inbound questionnaire arrives through **one named intake path** (one email alias such as `trust@` or `security@`, plus a thread in the single security channel that DR-4 established), and no one is answering them in a private direct message any more.
- [ ] A **request log** exists listing every questionnaire: customer, deal size if known, date received, date returned, format, hours spent, who answered.
- [ ] An **answer library** exists with at least 100 question and answer pairs, each with an owner, a last-reviewed date, an evidence link, and a confidence level.
- [ ] The library is **readable by sales and solutions engineering without asking you**, and at least one non-security person has completed a questionnaire draft using it.
- [ ] A written **answer style guide** exists (three to five rules) so answers are consistent across authors.
- [ ] A written **escalation rule** exists for questions you must answer no to, and every no is logged.
- [ ] Every **commitment made to a customer** ("we will have this by Q3") is logged in one place and fed to CO-3 (existing commitments).
- [ ] **Median hours per questionnaire has fallen** across at least three questionnaires. The number matters less than the direction.
- [ ] A **deflection asset** exists that you offer before filling out the spreadsheet: a trust page, a completed CAIQ or SIG Lite, or an audit report under non-disclosure agreement.

Explicitly **not required** at this stage: a paid compliance automation platform, a paid trust portal, artificial-intelligence questionnaire autofill, a full Standardized Information Gathering (SIG) Core completed pre-emptively, a dedicated compliance hire, or a formal customer-facing service level agreement for questionnaire turnaround.

## Discovery

Goal: find out how many questionnaires the company has already received, who answered them, and where those answers went. Almost every startup already has three to ten completed questionnaires scattered in Google Drive, SharePoint, email attachments, or a sales tool. Those are your seed corpus. You are not starting from zero, you are starting from unindexed.

**If you have no access to anything yet**, skip to "Ask the human". This cell is document archaeology, not command-line work, and you will get further with three questions than with any tool.

**Document storage.** Search for filenames and content, read-only:

- Google Workspace: Drive search box, query `security questionnaire`, then `SIG`, then `CAIQ`, then `vendor security`, then `VSA` (vendor security assessment). Also use the admin Drive audit if you are a Workspace admin. Console path: `admin.google.com` then Reporting then Audit and investigation then Drive log events.
- Microsoft 365: SharePoint or OneDrive search for the same terms. Console path: `admin.microsoft.com`, or use Microsoft Purview Content search if you have compliance-admin rights.
- Dropbox or Box: use the web search bar with the same terms.
- Local repository (if the company keeps docs in git):
  ```bash
  # read-only: find likely questionnaire artifacts anywhere in the tree
  grep -ril --include='*.md' --include='*.txt' --include='*.csv' \
    -e 'questionnaire' -e 'CAIQ' -e 'SIG Lite' -e 'vendor security' .
  find . -iname '*questionnaire*' -o -iname '*CAIQ*' -o -iname '*SIG*' 2>/dev/null
  ```

**Customer relationship management (CRM) system.** Questionnaires usually ride along on an opportunity record.

- Salesforce: search for `security questionnaire` in global search, then look at Files on closed-won opportunities from the last twelve months. Console path: Setup then Files then Files and Content Report.
- HubSpot: Library then Documents, and Attachments on Deal records. Search `security`.
- Pipedrive or Attio or Close: use the global search box for the same terms.
- If you do not have CRM access, ask for read-only. See the copy-paste message below.

**Email and chat.** These are where the true answer archaeology lives.

- Slack: search `questionnaire`, `SIG`, `CAIQ`, `pen test report`, `SOC 2 report` with `in:#sales in:#sales-eng` scoping. Console path for admin-level export requires Business Plus or Enterprise, do not attempt without approval.
- Microsoft Teams: search the same terms; org-wide search requires eDiscovery rights in Purview.
- Email: if you have a shared alias such as `security@` or `compliance@`, search it before asking anyone anything.

**Existing trust or compliance tooling.** Check whether a tool is already paid for and unused, which is common:

- Look at the corporate card statement or the finance tool's vendor list for: Vanta, Drata, Secureframe, Sprinto, Thoropass, SafeBase, Conveyor, Whistic, TrustCloud, OneTrust. If any of these appear, you may already own a trust portal and an answer library and nobody told you.

**Output of discovery:** a list of every past completed questionnaire with a link. Record it in `SECURITY-STATE.md` under the `CO-2` row with status `unknown` / `none` / `partial` / `done` and the evidence links.

## Ask the human

Ask these as closed questions, one at a time, and propose an answer for each so the human can just confirm or correct.

1. "How many security questionnaires has the company received in the last six months? My guess based on what I found is N. Is that roughly right?"
2. "Who has been answering them so far: you, a founder, a sales engineer, or nobody yet?"
3. "Do you have read access to the CRM system? Yes or no. If no, I will draft the request."
4. "Is there a deal blocked on a questionnaire right now? If yes, that one is our worked example and we build the library out of it."
5. "Has anyone ever promised a customer a certification, a penetration test report, or a feature by a date, in writing? Yes, no, or unsure."
6. "Are we already paying for any of: Vanta, Drata, Secureframe, Sprinto, SafeBase, Conveyor, Whistic? Yes or no."
7. "Who is allowed to say no to a customer on our behalf: you, the account executive, the head of sales, or a founder?" This one determines your escalation path and you cannot design the process without it.

**Copy-paste message to get CRM and past questionnaires (send to head of sales or revenue operations):**

> Hi, I am building a reusable answer library so security questionnaires stop being a bottleneck on deals. Two asks:
>
> 1. Read-only access to the CRM so I can find questionnaires attached to past opportunities. Read-only is enough, I do not need to edit anything.
> 2. Any completed security questionnaires, vendor assessments, or customer security addenda from the last twelve months, even partial or messy ones. Drop them in a folder and send me the link.
>
> The outcome I am aiming for is that your team can answer 80 percent of a questionnaire without me, and I only touch the hard 20 percent. Happy to walk through it once it exists.

**Copy-paste message to get past answers from an engineer or founder who has been doing this ad hoc:**

> Quick one: have you filled out any customer security questionnaires or vendor security reviews? If yes, can you send me the files or links, including the ones you are not proud of? I am not auditing the answers, I am building a library so neither of us has to answer the same question twice. Old and wrong is still useful to me, it tells me what we have already told customers.

## The walk

Baby steps. Do them in this order. Step 1 produces something useful on day one even if you stop there.

### Step 1: Create the intake path and the request log

- **Goal:** stop questionnaires arriving through private direct messages so you can see the volume.
- **Do:** create one intake path, and do not create a new chat channel for it. DR-4 (see `dr-4-company-comms-channel.md`) establishes exactly one public security channel and one private report path, and a second security channel splits the audience and dilutes both. The intake path is an email alias, `trust@` or `security@` on the company domain, plus a thread in the single security channel that DR-4 already created. Post one message in that channel and pin it or link it from the channel description: "Send every customer security questionnaire to trust@<domain>, and drop a note in this thread with the customer name and the deal close date. Do not answer one yourself yet." Then create `QUESTIONNAIRE-LOG.md` inside the state directory with columns: ID, customer, date received, due date, format, deal size band, status, hours spent, answered by.
- **Verify:** ask the head of sales to confirm in the security channel that this is now the path. Screenshot the pinned or linked message. If a questionnaire arrives through the old path in the next two weeks, the rollout did not land and you repeat the announcement.
- **Time:** 1 hour.
- **Who else:** head of sales or revenue operations, to endorse the path publicly in the security channel. Your endorsement alone will not change behaviour. Whoever administers email has to create the alias, which is a mutating change to the mail system, so ask them to make it or to approve it explicitly rather than doing it yourself.

### Step 2: Harvest the existing corpus

- **Goal:** turn scattered past answers into raw material.
- **Do:** run the Discovery searches above. Put every completed questionnaire you find into one folder. Read them. Note every place where two answers to the same question disagree, because those are your highest-risk items: you have told two customers two different things.
- **Verify:** you can name the number of past questionnaires and list them in `SECURITY-STATE.md` under `CO-2`. Contradictions are logged as risks in `RISK-REGISTER.md`.
- **Time:** 2 to 4 hours.
- **Who else:** nobody, if you got access in step 1.

### Step 3: Build the knowledge base schema and seed it

- **Goal:** one structured file that answers questions once.
- **Do:** create `QUESTIONNAIRE-KB.md` in the state directory using the schema below. Seed it with the twenty starter questions below, filling in only the answers you actually know. Mark everything else `UNKNOWN` explicitly. An honest `UNKNOWN` is more valuable than a guess, because it becomes a work item.
- **Verify:** every entry has an owner and a last-reviewed date. Count the entries. Count the `UNKNOWN` entries. Both numbers go in `SECURITY-STATE.md`.
- **Time:** 4 to 8 hours for the first hundred entries.
- **Who else:** an engineer for the infrastructure answers (encryption, hosting region, backup), an operations or people lead for the human resources answers (background checks, security training, offboarding).

### Step 4: Answer the live questionnaire end to end, out loud

- **Goal:** validate the library against a real deal and produce a worked example.
- **Do:** take the currently blocked questionnaire and run the end-to-end process below. Narrate what you are doing so the sales person watching learns the pattern. Every question you answer, write the answer back into the knowledge base before you paste it into the spreadsheet. This is the discipline that makes the library compound.
- **Verify:** the questionnaire is returned, and the knowledge base grew by the number of new questions in it.
- **Time:** 4 to 16 hours for the first one.
- **Who else:** the account executive on the deal, for customer context and tone.

### Step 5: Write the answer style guide and the escalation rule

- **Goal:** other people can now write answers that do not create legal or security problems.
- **Do:** write a one-page style guide (rules are below) and the escalation rule for a `no` answer. Put it at the top of `QUESTIONNAIRE-KB.md`.
- **Verify:** hand it plus the library to a sales engineer, give them a questionnaire, and see how far they get without you. Measure the percentage they completed unaided. That percentage is your headline metric for this cell.
- **Time:** 2 hours.
- **Who else:** a founder or head of sales must agree to the escalation rule, because it constrains what they can promise.

### Step 6: Publish the deflection assets

- **Goal:** get some customers to accept a document instead of a spreadsheet.
- **Do:** publish a public trust page (see CO-1) and complete one standard format pre-emptively. Recommended default: the Cloud Security Alliance Consensus Assessments Initiative Questionnaire (CAIQ), because it is free, downloadable from the Cloud Security Alliance, and widely accepted. Offer it in the first reply to any questionnaire request.
- **Verify:** track the deflection rate in `QUESTIONNAIRE-LOG.md`: of questionnaires received, how many were satisfied by the trust page or the pre-filled CAIQ alone.
- **Time:** 1 to 2 days for the CAIQ, plus CO-1 work.
- **Who else:** marketing or web, to host the trust page.

### Step 7: Review and prune quarterly

- **Goal:** prevent the library from lying on your behalf.
- **Do:** every quarter, filter for entries with a last-reviewed date older than 180 days and re-verify them. Any answer whose evidence link is dead is automatically stale.
- **Verify:** zero entries older than 180 days after the review. Log the review date in `DECISION-LOG.md`.
- **Time:** 2 to 4 hours per quarter.
- **Who else:** the named owner of each stale entry.

## The knowledge base schema

Use this exact structure. It is plain markdown so it works with no tooling, and it maps cleanly onto a spreadsheet or a compliance platform later if you buy one.

```markdown
### KB-042: Do you encrypt customer data at rest?

- **Canonical answer:** Yes. All customer data at rest is encrypted using AES-256 via
  the managed encryption of our cloud provider's storage and database services.
- **Short answer (for yes/no cells):** Yes
- **Owner:** platform engineering lead
- **Last reviewed:** 2026-08-25
- **Confidence:** high
- **Evidence:** link to the console screenshot or infrastructure-as-code line proving
  encryption is enabled, plus the control identifier if you have a framework
- **Aliases:** "is data encrypted at rest", "storage encryption", "AES-256", "CC6.1"
- **Do not say:** do not claim customer-managed keys or a hardware security module
  unless engineering confirms it. Managed provider keys are not the same thing.
- **Commitment flag:** none
```

Field rules:

- **Canonical answer** is written for a stranger who will read it out of context. No internal jargon, no product code names.
- **Short answer** exists because half of all questionnaire cells only accept Yes, No, Partial, or Not Applicable.
- **Owner** is a person or a role who can re-verify the fact. If nobody owns it, the answer will rot.
- **Last reviewed** is an ISO date. Anything older than 180 days is stale and must be re-verified before reuse.
- **Confidence** is high, medium, or low. Low-confidence answers must not be sent without your review, even by trained sales staff.
- **Evidence** is a link. The evidence link is what turns your knowledge base into audit-ready material for CO-4 and CO-3 later, at zero extra cost.
- **Aliases** are the phrasings customers actually use. This is what makes the library searchable by a non-security person.
- **Do not say** captures the overclaim you are worried about. This field prevents more incidents than any other.
- **Commitment flag** records whether answering this question has ever created a forward-looking promise. If yes, it links to the entry in CO-3.

## The twenty most common questions with model answers

These twenty appear in essentially every questionnaire regardless of format. Seed the library with them first. The model answers below are **templates with placeholders in angle brackets**, not facts about your company. Fill each one in from evidence, and if you cannot find evidence, write `UNKNOWN` and open a work item.

1. **Do you encrypt data in transit?** "Yes. All data in transit between clients and our service is encrypted using TLS 1.2 or higher. `<state whether TLS 1.0 and 1.1 are disabled and where you verified it>`."
2. **Do you encrypt data at rest?** "Yes. Customer data at rest is encrypted with AES-256 using `<cloud provider>` managed encryption on `<storage and database services>`."
3. **Do you have a SOC 2 report or ISO 27001 certificate?** If you do: "Yes. `<Type 1 or Type 2>`, covering `<trust services criteria>`, report period `<dates>`, available under a mutual non-disclosure agreement." If you do not: "Not yet. We are `<in observation window / scoping / not currently pursuing>`. In the meantime we can share `<trust page, penetration test summary, this completed CAIQ>`." Never write "in progress" without a defensible meaning behind it. See the escalation rules below.
4. **Where is customer data hosted, and in which regions?** "`<Provider>`, in `<regions>`. `<State whether data can leave the region, and whether sub-processors are in other regions>`."
5. **Do you use sub-processors, and do you publish the list?** "Yes, our current sub-processors are listed at `<public URL>`. We notify customers `<N>` days before adding a new one." If there is no published list, this is a fast win: publishing it converts a recurring question into a link.
6. **Do you enforce multi-factor authentication (MFA) for employees?** "Yes. Multi-factor authentication is enforced for all employees on `<identity provider>` for all applications behind single sign-on. `<State whether phishing-resistant methods such as hardware keys or passkeys are required or optional.>`"
7. **Do you enforce single sign-on (SSO) internally, and do you offer it to customers?** Two separate questions that appear as one. Answer both explicitly. If customer-facing single sign-on is a paid tier, say so plainly rather than answering "yes". If the product does not offer it at all, that is a roadmap item rather than a control gap, and it belongs in the enterprise readiness section below.
8. **How do you manage access to production, and do you review it?** "Access to production is granted via `<mechanism>` on a least-privilege basis and reviewed `<frequency>`. `<Link to the last review evidence.>`" Do not paste that sentence before you hold the artifact behind it, which is the production data access path table and the dated sentence produced by **Step 11 of [cs-1-identity-and-access.md](cs-1-identity-and-access.md)**. That step counts every path a human uses to reach production customer data, including the ones a role list never shows (a bastion or tunnel, a desktop database client, a connection string saved in someone's `.env`, an internal admin tool, support impersonation, the analytics copy, and a restored backup), and records for each whether the use is logged and for how long. Answering from identity provider group membership alone understates the real number every time, and the buyer's follow-up ("how would you know who read a customer record last Tuesday?") is what exposes it. A named gap with a date survives that follow-up. "Least-privilege" with no evidence behind it does not.
9. **Do you have a documented incident response plan, and have you tested it?** "Yes, we maintain a documented incident response plan reviewed `<frequency>` and last exercised on `<date>`." If untested, say "documented but not yet exercised; our first tabletop exercise is scheduled for `<date>`." Cross-reference DR-1.
10. **What is your breach notification commitment?** "We will notify affected customers without undue delay and within `<N>` hours of confirming a breach affecting their data." Do not invent a number. Check the existing contracts first, because the shortest number in any signed contract is now your real answer. Cross-reference CO-3.
11. **Do you perform penetration testing, and how often?** "`<Annually / not yet>`, by `<firm>`, last performed `<date>`. We share an executive summary under a mutual non-disclosure agreement." Never share the full report with raw findings.
12. **Do you scan for vulnerabilities in your code and dependencies, and what are your remediation timelines?** "Yes. `<Tooling>` runs on `<every pull request / nightly>`. Our remediation targets are `<critical N days, high N days, medium N days>`." Only state timelines you actually meet.
13. **Do you perform background checks on employees?** "`<Yes/No>`, `<scope, and for which roles and jurisdictions>`." This is a people-operations answer, not a security answer. Get it from them and put their name in the owner field.
14. **Do employees receive security awareness training?** "Yes, at onboarding and `<annually>`, covering `<phishing, data handling, secure development for engineers>`. Completion is tracked in `<system>`."
15. **What is your offboarding process for departing employees?** "Access is revoked within `<N>` hours of the termination event via `<identity provider deprovisioning>`, and devices are `<returned or remotely wiped>`." Cross-reference CS-3.
16. **Do you have a business continuity and disaster recovery plan, with a recovery time objective and recovery point objective?** "`<Yes/No>`. Recovery time objective `<N hours>`, recovery point objective `<N hours>`, last tested `<date>`." Every number in that sentence must come from a timed restore drill recorded per `m-6-backups-and-recovery.md`, and the entry in the knowledge base must cite the drill date. If no drill has been run, the honest answer is "we have automated backups with `<retention>` retention and point-in-time recovery `<enabled or not>`. We have not yet completed a timed restore drill, so we are not stating a recovery time objective. Our first drill is scheduled for `<date>`." Untested backups are the single most commonly overstated control in questionnaires. See the recovery-claim rule below.
17. **How long do you retain customer data, and how is it deleted on request?** "`<Retention period>`. On written request or contract termination we delete customer data within `<N>` days, including backups within `<N>` days as backups age out." Cross-reference CO-4.
18. **Do you support customer audit rights or on-site audits?** Default answer: "We satisfy audit requirements through `<our SOC 2 report / this completed CAIQ / our trust page>` rather than customer-specific on-site audits." Agreeing to on-site audits for every customer does not scale and is a contractual commitment, so escalate rather than answering yes casually.
19. **Do you use artificial intelligence or machine learning, and is customer data used to train models?** "`<Yes/No>`. Customer data `<is not used>` to train models. We use `<providers>` under `<zero-retention / standard>` terms." This question is now in roughly every questionnaire and is one of the most common places startups accidentally lie, because someone on the team enabled a feature nobody told security about.
20. **Do you carry cyber liability insurance, and at what limit?** "`<Yes/No>`, `<limit>` with `<carrier>`, policy year `<dates>`." Finance owns this answer. Get it once, log the owner, and stop guessing.

## The recovery-claim rule (hard stop)

A template sentence containing a recovery time objective and a recovery point objective is easy to write and impossible to defend, because those two numbers cannot be reasoned out from an architecture diagram or copied from a cloud provider's marketing page. They come from a measured drill, and nowhere else.

**No answer about backups, restore testing, recovery time objective, or recovery point objective leaves this company before a timed restore drill has produced a number and a date.** That applies to a questionnaire cell, an email to a prospect, a sales one-pager, a contract exhibit, and the public trust page in CO-1 equally. The drill procedure, the scratch-environment requirement, and the recording format are in `m-6-backups-and-recovery.md`.

How to apply it in practice:

- If a drill exists, the knowledge base entry states the measured wall-clock time, rounded upward and conservatively, and cites the drill date in the evidence field. An unrounded drill number becomes a promise you will miss on the bad day, because the drill happened on a good day with the right person awake.
- If no drill exists, you may still state facts you have verified: whether automated backups are on, the retention window in days, and whether point-in-time recovery is enabled. Those are configuration facts you can screenshot. A recovery time is not.
- A recovery point objective derived from configuration alone (for example "daily snapshots imply up to 24 hours of loss") may be stated only if it is labelled as derived from configuration and not yet drill tested. Do not label a derived number as tested.
- A customer who insists on a number before a drill exists gets a date by which they will have a measured one, escalated through the Tier 3 rule below, not a number invented on the call.
- If someone senior asks you to state a recovery time you cannot evidence, that is the refusal procedure in `08-when-it-is-not-working.md`, Part B, not a judgement call to make alone at speed.

## Answer style rules

Put these five rules at the top of the knowledge base. They are the difference between a library that speeds you up and a library that creates liabilities.

1. **Answer the question that was asked.** If the question is "do you encrypt data at rest", the answer starts with Yes or No. Do not open with a paragraph of context and bury the answer. Reviewers on the other side are scanning, and a buried answer reads as evasion.
2. **Never lie, and never let a hopeful reading count as truth.** "We plan to" is not "we do". If you would not be comfortable with the answer being read out during an incident post-mortem or a lawsuit, do not write it. A false questionnaire answer is a misrepresentation attached to a signed contract, and it converts a security problem into a legal one.
3. **Use compensating-control language honestly.** When the exact control asked about does not exist, name what does exist and say plainly that it is different. Good: "We do not use a hardware security module. Encryption keys are managed by our cloud provider's managed key service with access restricted to two production roles and all key usage logged." Bad: "Yes, keys are securely managed." The first is a real answer a reviewer can accept. The second is a non-answer that triggers a follow-up call.
4. **Say "not applicable" and explain why, rather than leaving a blank.** A blank cell reads as "we did not bother" or "we are hiding something". "Not applicable: we do not process payment card data; card payments are handled entirely by `<processor>` and card numbers never reach our systems" closes the question permanently and often removes a whole section of the questionnaire.
5. **Write once, reuse forever.** Every answer you type into a customer's spreadsheet must be written into the knowledge base in the same sitting. If it is not in the library, it did not happen, and you will type it again next month.

A sixth rule for whoever else uses the library: **if the library says confidence low, or the question is not in the library at all, stop and route it to security.** Do not improvise. This one rule is what makes delegation safe.

## The escalation rule: turning a no into a roadmap without creating a contract

You will hit questions where the honest answer is no. This is normal, and reviewers expect some. What kills deals is not the no, it is an evasive or inconsistent no.

The rule, in three tiers:

- **Tier 1, answer no and move on.** The control is genuinely not applicable or not expected at your size. Example: no dedicated 24/7 security operations centre at 40 people. Say no, name the compensating control, done. You do not need approval for this.
- **Tier 2, answer no plus a factual statement of current state.** "No. This is on our roadmap and not currently scheduled." Factual, no date. You can say this without approval. The absence of a date is the whole point.
- **Tier 3, answer no plus a dated commitment.** "We expect to complete `<control>` by `<quarter>`." **This requires an explicit yes from whoever owns commitments (usually a founder or the head of sales), and it must be logged.** A date in a questionnaire is frequently attached to the contract by reference, and even when it is not, the customer's security team will diary it and ask again.

When you make any Tier 3 commitment:

1. Write it to `DECISION-LOG.md` with the date, the customer, the exact wording, and who approved it.
2. Write it to the commitments table that CO-3 owns, so it becomes a tracked obligation rather than a forgotten sentence in a spreadsheet.
3. Set the commitment flag on the relevant knowledge base entry so the next person answering the same question sees that a promise exists.

Language that keeps a Tier 3 answer from hardening into a contractual obligation, to be confirmed with counsel if you have one: prefer "we currently expect", "is on our roadmap for", and "subject to change" over "we will", "we commit to", and "we guarantee". State it in the questionnaire body, not in the contract or the security addendum. And never let the commitment appear only in the customer's copy: if you cannot find it in your own log, it will surprise you in twelve months.

## Handling a questionnaire end to end

This is the process the agent follows every time. Do not skip steps 1 and 2, they are where the time savings come from.

1. **Log it.** Add a row to `QUESTIONNAIRE-LOG.md`: customer, date received, due date, format, deal band, who asked.
2. **Try to deflect first.** Reply within one business day: "Before we complete the spreadsheet, would our trust page at `<URL>`, our completed Consensus Assessments Initiative Questionnaire, and our `<SOC 2 / penetration test summary>` under mutual non-disclosure satisfy your review?" Roughly one in four reviewers will accept. That is the cheapest hour you will ever spend. Record the outcome in the log.
3. **Triage the questionnaire.** Read every question and tag each one: `KB-hit` (answer exists), `KB-miss-easy` (you can answer in under ten minutes), `KB-miss-hard` (needs another team), `must-say-no`, `unclear` (ask the customer to clarify rather than guessing).
4. **Fill the KB-hits mechanically.** Paste the canonical or short answer. Check the last-reviewed date; anything over 180 days gets re-verified before it goes out.
5. **Batch the KB-misses by owner.** One message to engineering with all engineering questions, one to people operations, one to finance. Do not ask people one question at a time across three days.
6. **Handle the noes using the three-tier escalation rule** above. Get approval before any dated commitment.
7. **Ask about unclear questions.** "Question 47 asks about `<X>`. Are you asking about `<interpretation A>` or `<interpretation B>`? I want to give you an accurate answer." This makes you look competent, not ignorant. Guessing makes you look like a liar later.
8. **Self-review before sending.** Check three things: does any answer contradict a previous answer to another customer, does any answer overclaim, and does any answer create a commitment that is not logged.
9. **Write everything back to the knowledge base.** Every new question and answer becomes an entry with owner, date, evidence, and confidence. This is the step that everyone skips and it is the only reason the library exists.
10. **Close the log row.** Record hours spent and percentage answered from the library. These two numbers are your metric.
11. **Feed commitments to CO-3** and any newly discovered gaps to `RISK-REGISTER.md`.

## Enterprise readiness features: the answers you cannot write, because the product does not do it yet

Some of the noes you hit are not control gaps at all. They are missing product features. A buyer's security reviewer asks whether their administrators can log in with the company's own identity provider, whether they can see who did what inside your product, and whether they can give a contractor a read-only seat. If the answer is no, no amount of knowledge base craft fixes it, and this is frequently the real reason a deal stalls rather than anything in your 90-day plan.

**Framing first, because getting this wrong costs you the quarter.** These five features live on the product roadmap, owned by a product manager and built by product engineers. You are the requirements author and the internal customer, not the implementer, and they do not belong on the security backlog. A first security hire who takes on shipping customer-facing single sign-on has traded a quarter of program work for one feature that the product team was going to have to own anyway. Say this out loud when the work is offered to you, and say it early, because it is much harder to hand back later.

They are listed in the order enterprise buyers actually demand them.

**1. Customer-facing single sign-on (SSO).** The buyer's administrators sign in to your product through their own identity provider rather than with a password you store. This is the single most requested enterprise feature and the most common hard blocker.
- Good enough at 20 to 100 people: SAML 2.0 (Security Assertion Markup Language) plus OpenID Connect, self-serve configuration per customer organisation, one identity provider connection per customer, tested against at least Okta, Microsoft Entra ID, and Google Workspace. Just-in-time user creation on first login is expected. Enforced-SSO mode, where password login is disabled for that organisation, is what a security-conscious buyer will actually check for.
- Rough engineering cost: one to three engineer-weeks using an identity vendor that provides the enterprise connection layer, four to eight weeks and ongoing maintenance if hand-rolled. Vendor pricing in this category is commonly per enterprise connection per month in the low hundreds of United States dollars, or bundled into a per monthly-active-user price. Get a current quote rather than trusting any number in this file, and note that purchasing needs a budget owner's explicit yes.
- The trap: pricing single sign-on into your most expensive tier. Buyers and security practitioners both read that as charging for safety, it generates public criticism, and it means your smallest enterprise customers stay on shared passwords. If commercial reality forces it into a paid tier, say so plainly in the questionnaire rather than answering "yes".

**2. Role-based access control (RBAC) inside the customer's account.** The buyer can give different people different permissions rather than everyone being an administrator.
- Good enough at 20 to 100 people: three or four fixed roles (owner, administrator, member, read-only or billing), enforced server-side on every endpoint, not just hidden in the interface. Custom roles and per-object permissions are a later problem.
- Rough engineering cost: two to six engineer-weeks, dominated by how entangled the existing permission checks are. If the product currently has one implicit "logged in equals allowed" model, budget the top of that range.

**3. Customer-visible audit logs.** The buyer's administrators can see who did what in their own account.
- Good enough at 20 to 100 people: an append-only record of security-relevant events (login, failed login, permission change, member invited or removed, integration or key created, data exported, settings changed) with actor, action, target, timestamp in Coordinated Universal Time, and source internet protocol address. Ninety days of retention visible in the product, comma-separated-value export, and a documented way for the customer to pull it. A streaming or webhook export is a later ask.
- Rough engineering cost: two to four engineer-weeks for the write path plus a simple viewer and export. The expensive part is instrumenting every code path that mutates state, so the earlier it is done the cheaper it is.
- Bonus that matters to you specifically: the same event stream is a detection source for DR-2 and evidence for an incident under DR-1. It is the one of the five that pays you back directly, and it is the one to push for first if you get to choose.

**4. SCIM provisioning.** SCIM (System for Cross-domain Identity Management) lets the buyer's identity provider create, update, and deactivate users in your product automatically, so a leaver in their directory becomes a deactivated user in your product without anyone remembering.
- Good enough at 20 to 100 people: user create, update, and deactivate, plus group-to-role mapping if roles exist. Deactivate is the part the buyer's security team cares about, because it is their offboarding story.
- Rough engineering cost: two to four engineer-weeks standalone, often days if you already bought the identity vendor that supplies your single sign-on layer. This is why the vendor decision in feature 1 should be made with feature 4 in view.

**5. Internet protocol allowlisting and session controls.** The buyer can restrict access to their account to named network ranges, and set session timeout behaviour.
- Good enough at 20 to 100 people: per-organisation allowlist of Internet Protocol version 4 and version 6 ranges enforced at your edge or in middleware, with a documented recovery path for the customer who locks themselves out. Configurable session lifetime is a cheap addition once you are already in the session code.
- Rough engineering cost: a few days to two weeks. It is the smallest of the five and the least often decisive, so it should not jump the queue on enthusiasm alone.

**How to prioritise these without arguing from anecdote.** Your request log is the evidence. In `QUESTIONNAIRE-LOG.md`, add a column recording which of the five features each questionnaire or security review asked for, and whether the deal stalled on it. After ten questionnaires you can walk into a product review with a counted claim: "seven of our last ten security reviews asked for customer single sign-on, four of those deals are open, and their combined annual contract value is X". That sentence moves a roadmap. "Enterprise customers want single sign-on" does not. Feed the same counts to `05-metrics-and-comms.md` under deals unblocked, because this is where the deal-unblocking metric actually comes from.

Two cautions. Do not commit a delivery date for any of these to a customer: that is a Tier 3 commitment and it belongs to the product owner and the escalation rule above, not to you. And do not build any of them speculatively because a single prospect asked once. Two named deals or a counted pattern in the log, or it waits.

## Decision points

**Do you build the library in markdown, a spreadsheet, or a paid platform?**
**DEFAULT: markdown files in the state directory, plus a mirror in whatever document tool the sales team already lives in.** Markdown is versionable and diffable, which means you can prove when an answer changed. Change this if the sales team will not open a git repository, in which case a shared spreadsheet or a Notion or Confluence database is fine and better than a perfect system nobody reads. Change to a paid platform only when the conditions below are met.

**Do you complete a standard format pre-emptively?**
**DEFAULT: yes, complete the Cloud Security Alliance CAIQ first, because it is free and self-serve.** Change this if your customers are consistently financial services or healthcare, in which case the Shared Assessments SIG Lite is more likely to be accepted, but note the SIG requires a paid Shared Assessments membership to license. If money is zero, CAIQ plus a good trust page covers most of the ground.

**Who answers questionnaires after the library exists?**
**DEFAULT: the sales engineer or account executive drafts, security reviews the exceptions only.** Change this if the deal is above a threshold the company cares about (pick one, for example anything over a quarter of a typical annual contract value) or if the customer is regulated, in which case you draft. The failure mode of the default is a confident sales person answering yes to something that is not true, which the confidence field and the escalation rule are designed to prevent.

**Do you buy a compliance automation platform (Vanta, Drata, Secureframe, Sprinto, Thoropass) for this?**
**DEFAULT: no, not for questionnaires alone.** These tools earn their money on evidence collection for an audit, not on questionnaire answering. Buy one when you have actually committed to SOC 2 or ISO 27001, not before. See CO-4.

**Do you buy a trust portal (SafeBase, Conveyor, Whistic, TrustCloud, or the trust-centre module bundled with a compliance platform)?**
**DEFAULT: no at under 10 questionnaires a quarter, yes at more than that.** The arithmetic: if you receive 10 questionnaires a quarter at 8 hours each, that is 80 hours a quarter. A trust portal that deflects 40 percent and autofills half of the rest saves roughly 40 hours a quarter. At a loaded cost of a security engineer's hour, a portal in the several-thousand-dollars-per-year band pays for itself. Below that volume it is a subscription that makes you feel organised. Free-first alternative: a static trust page on your own website plus a gated document request form, which achieves most of the deflection at zero cost.

**Do you answer a questionnaire for a prospect who is clearly not going to buy?**
**DEFAULT: no, and this is a decision you should push back on out loud.** Ask the account executive for the deal stage and the expected close. If it is early-stage discovery, offer the trust page and the CAIQ and nothing else. Filling a 300-question SIG for a tyre-kicker is the exact trap Evan Johnson warned about.

## Danger zone

These actions need an explicit yes from a named human before you take them. State the stop, name the risk, wait.

- **Sending a completed questionnaire to a customer.** STOP. Once it is sent, it is a written representation attached to a commercial relationship and you cannot retract it cleanly. A founder or the deal owner should see the noes and the commitments before it goes. What breaks if you get it wrong: a misrepresentation claim, a failed re-review at renewal, or an incident where your own questionnaire is the evidence against you.
- **Making a dated commitment ("SOC 2 Type 2 by Q3").** STOP. Requires the person who owns commitments. Evan Johnson's exact warning applies: "Before security folks join a startup it's really common for the business to make commitments to future compliance standards that they might not be ready for." A missed compliance date can trigger contractual remedies or termination rights.
- **Stating a recovery time objective, a recovery point objective, or "restores are tested" to a customer.** STOP unless a timed restore drill recorded per `m-6-backups-and-recovery.md` has produced a number and a date. What breaks if you get it wrong: the claim is tested for the first time during the worst day the company has ever had, in front of the customer you made it to, and the questionnaire is the document they quote back.
- **Sharing a full penetration test report.** STOP. Share the executive summary only. A full report is a map of your unfixed weaknesses, and once distributed you cannot control where it goes. If the customer insists, share under a mutual non-disclosure agreement with a named recipient, and log it in `ACCESS-LOG.md`.
- **Publishing the knowledge base publicly or to an unrestricted internal link.** STOP. The library contains architecture details, control gaps, and `UNKNOWN` markers. Publish the trust page (curated), never the library.
- **Purchasing a platform.** STOP. Anything with a contract and an annual cost requires a budget owner's yes. Present the arithmetic above rather than the vendor's deck.
- **Answering a questionnaire on behalf of a company you have only just joined.** STOP if you have not verified the facts. Inheriting and re-sending a previous person's answers without verification is how startups repeat a lie for three years. Re-verify anything with a last-reviewed date you cannot see.
- **Using an artificial-intelligence autofill tool on a questionnaire.** STOP unless a human reviews every generated answer. These tools are genuinely good at retrieval and genuinely willing to invent a plausible control that does not exist. The output is a legal representation, not a draft blog post.

## Do not do this yet

- **Do not complete a full SIG Core pre-emptively.** It is hundreds of questions, it goes stale, and most customers will never ask for it. Wait until two separate customers ask for the same heavyweight format.
- **Do not build a custom internal questionnaire-answering application.** You will be tempted, it is a fun weekend project, and it will consume a month you do not have. Markdown plus search is enough until well past 100 people.
- **Do not chase a certification because one questionnaire asked for it.** One customer asking for ISO 27001 is a data point, not a mandate. Three customers with signed contracts contingent on it is a mandate. That decision belongs in CO-4.
- **Do not write a formal internal service level agreement for questionnaire turnaround.** You will miss it, and then you have created a second obligation on top of the first.
- **Do not answer questions about controls you have not verified yourself**, even when a colleague sounds confident. "The database is encrypted" is a claim, and the console screenshot is the fact.
- **Do not attempt to standardise the customer's process.** You cannot make a Fortune 500 vendor risk team drop their spreadsheet. Deflect where you can, comply gracefully where you cannot, and spend the saved energy on the library.

## Evidence to capture

- `SECURITY-STATE.md`, row `CO-2`: status (`unknown` / `none` / `partial` / `done`), count of knowledge base entries, count of `UNKNOWN` entries, link to `QUESTIONNAIRE-KB.md`, link to `QUESTIONNAIRE-LOG.md`, date of the last quarterly review, and the current percentage a non-security person can complete unaided.
- `RISK-REGISTER.md`: one entry per contradiction found between past questionnaire answers (severity depends on the subject and how many customers received the wrong answer), and one per control gap discovered while answering. Owner, severity, decision, accepted-by.
- `DECISION-LOG.md`: every Tier 3 dated commitment with customer, exact wording, approver, and date. Also log the decision to buy or not buy a trust portal with the arithmetic behind it, and each quarterly review date.
- `ACCESS-LOG.md`: CRM read access requested, granted or denied, date. Every distribution of a penetration test report or audit report, with recipient and non-disclosure agreement reference.
- `QUESTIONNAIRE-LOG.md`: alongside the per-questionnaire row, the enterprise readiness column recording which of the five customer-facing features each review asked for and whether the deal stalled on it. That column is the evidence behind any roadmap ask you make.
- Any recovery time objective or recovery point objective you state anywhere: the drill date and measured time it came from, recorded per `m-6-backups-and-recovery.md`. An answer citing no drill is not evidence, it is a guess with a number attached.
- **What an auditor or a customer will ask you for later:** the completed questionnaires you sent (they may ask for consistency), the evidence links behind your answers (this is why the evidence field exists), your list of sub-processors, your incident response plan, your access review records, and proof that your public claims match your internal reality. If you populate the evidence field as you go, CO-4 and any future audit get materially cheaper for free.

## Cost and effort

- **Setting up intake plus the request log:** 1 hour, free.
- **Harvesting the existing corpus:** 2 to 4 hours, free.
- **First 100 knowledge base entries:** 1 to 2 days, free.
- **First questionnaire answered end to end:** 4 to 16 hours. Expect the first to be slow.
- **Steady state after the library exists:** 1 to 3 hours per questionnaire, and falling.
- **Pre-filled CAIQ:** 1 to 2 days, free (the Cloud Security Alliance publishes the CAIQ at no cost; listing in the Security, Trust, Assurance and Risk registry is also free at the self-assessment level).
- **SIG or SIG Lite:** licensing requires Shared Assessments membership, typically low thousands of dollars per year. Skip unless your customers demand it.
- **Static trust page:** free, half a day of your time plus a web change.
- **Trust portal (SafeBase, Conveyor, Whistic, TrustCloud):** roughly low-to-mid five figures per year at startup tiers, sometimes bundled cheaply with a compliance platform. Do not buy before the volume arithmetic clears.
- **Compliance automation platform (Vanta, Drata, Secureframe, Sprinto):** roughly ten to thirty thousand dollars per year at startup size, plus a separate audit fee. Justify it under CO-4, not here.
- **Total to reach "definition of done":** 5 to 8 working days of your time spread across the first quarter, at zero external cost.

## 2026 notes

The 2019 cell said "build a knowledge base and make it self-service", and that instruction is still exactly right. Four things changed around it.

- **Volume is up and the questions got harder.** Post-SolarWinds and post-MOVEit, third-party risk teams exist at companies that did not have them in 2019, and they ask about your suppliers, not just about you. Expect questions about your sub-processors' sub-processors, your software bill of materials, and your build pipeline. Cross-reference `07-modern-cells.md`.
- **Artificial intelligence questions are now standard, and they are the top source of accidental lies.** Expect: do you use large language models in the product, is customer data used for training, which model providers, do you have an artificial intelligence usage policy, do you allow employees to paste customer data into consumer chat tools. Answer these only after checking with engineering what is actually wired up, because the answer changes monthly at a startup and nobody tells security.
- **Both sides now use automation.** Vendors autofill with retrieval-augmented generation, and reviewers increasingly use automated analysis to flag inconsistency across your answers and against your public trust page. Inconsistency is now cheap for them to detect, which raises the value of a single canonical source and lowers the value of improvising.
- **The trust page has partly replaced the spreadsheet for smaller deals.** A credible public trust page with a documents-under-non-disclosure request flow now deflects a meaningful share of inbound reviews, which was not true in 2019. Build CO-1 and CO-2 as one project.

## Failure modes

- **You become the questionnaire person.** *Early tell:* you can name the current questionnaire backlog from memory, and your calendar has no blocks for engineering work. *Recovery:* stop answering for two weeks, publish the library, and make the sales engineer draft. Show the percentage-completed-unaided metric to your manager. This is the exact failure Evan Johnson called out and it is the most common one.
- **The library rots and starts lying.** *Early tell:* an answer references a tool or a service the company stopped using. *Recovery:* the quarterly stale-date sweep. If more than a quarter of entries are stale, the owners field was never real, and you need to reassign owners rather than re-verify everything yourself.
- **Two customers received contradictory answers.** *Early tell:* you find it during harvest, or worse, a customer finds it at renewal. *Recovery:* decide the true answer, correct it in the library, and proactively send a correction to the customer who got the wrong one. Proactive correction is uncomfortable and vastly cheaper than being caught. Log it in `DECISION-LOG.md`.
- **A commitment nobody logged comes due.** *Early tell:* a customer emails "you said SOC 2 by Q3, where is it". *Recovery:* immediate honest reset with a new realistic date, escalated to a founder same day. Prevention is the Tier 3 rule and the CO-3 commitments table.
- **Sales answers a questionnaire without you and says yes to something false.** *Early tell:* a questionnaire in the log that you never saw, or a customer referencing a control you know does not exist. *Recovery:* correct in writing to the customer, and tighten the process so any `low` confidence or missing entry hard-stops. Do not respond by taking the work back entirely, that recreates the first failure mode.
- **You deflect too aggressively and a deal stalls.** *Early tell:* the account executive stops routing questionnaires to you and starts answering them alone. *Recovery:* deflection is an offer, not a refusal. Always pair "would this satisfy you" with "and if not, we will complete your spreadsheet by `<date>`."
- **The library is technically excellent and nobody uses it.** *Early tell:* the git history shows only your commits, and the sales team still asks you in direct messages. *Recovery:* meet them where they are. Mirror the library into their tool, and run one live working session where a sales person completes a questionnaire with you watching but not typing.

## Related cells

- [CO-1: Public facing security docs](co-1-public-security-docs.md): the trust page is the deflection asset for this cell and shares a source of truth with the library.
- [CO-3: Understand existing commitments](co-3-existing-commitments.md): every Tier 3 commitment you make here becomes a tracked obligation there.
- [CO-4: Data inventory, privacy commitments, and framework choice](co-4-data-inventory-and-framework.md): the data-handling questions you cannot answer here are the reason the data inventory exists.
- [DR-1: Basic incident response plan](dr-1-incident-response-plan.md): the source of truth for breach notification answers.
- [SE-3: Secrets and keys](se-3-secrets-and-keys.md): where the encryption and key management answers come from.
- [CS-1: Identity and access management](cs-1-identity-and-access.md) and [CS-3: Onboarding and offboarding](cs-3-onboarding-offboarding.md): the source of truth for access, multi-factor authentication, and deprovisioning answers.
- [DR-4: Establish a communication channel with the rest of the company](dr-4-company-comms-channel.md): owns the single security channel and the report alias that questionnaire intake rides on, which is why this cell does not create a channel of its own.
- [M-6: Backups and recovery](m-6-backups-and-recovery.md): the only place a recovery time objective or recovery point objective may come from, and the file that runs the drill your business continuity answer cites.
- [08: When it is not working](08-when-it-is-not-working.md): the refusal procedure for the moment someone senior wants an answer sent that the evidence does not support.
- [07: Modern cells](07-modern-cells.md): supply chain, continuous integration and delivery, cloud posture, software-as-a-service sprawl, and artificial intelligence security, which are now questionnaire subjects.
- [05: Metrics and comms](05-metrics-and-comms.md): hours per questionnaire and percentage completed unaided are two of the few security metrics an executive team genuinely cares about.
