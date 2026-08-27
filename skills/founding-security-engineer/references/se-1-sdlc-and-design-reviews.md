# SE-1: SDLC and security design reviews with engineers

> **Grid coordinate:** SE-1, Security Engineering domain, cell 1.
> **Original 2019 wording:** "SDLC & security design reviews with engineers".
> **Speaker context (Evan Johnson, OWASP AppSec California 2019):** "SDLC and engaging with engineers to do security reviews. This is really big and really important. Starting to work with folks and embedding yourself in how engineers work pays major dividends later. If there isn't a structure for an SDLC, you can also do it by inbound."
> **Load when:** the human asks how to get involved in engineering work, asks about design reviews or threat modelling, is asked to review a feature or an architecture, is told "we ship on Fridays and nobody looks at security", says a big feature is about to launch, the product is multi-tenant and nobody can say what stops one customer reading another's data, or the 90 day plan reaches the SE-1 gate. Also load when the human is new and needs a first-week win with the engineering team.

## Why this cell exists

Software development lifecycle (SDLC) means the path a change takes from someone writing a ticket to that change running in front of customers. Every serious security problem a startup ships was designed at some point by a person who did not know it was dangerous, and it went through that path without anyone asking a question. This cell is about putting one lightweight question-asking moment into that path, early enough that the answer is a design change rather than a rewrite.

The reason this cell is listed first in the 2019 grid is political, not technical. If engineers see you as the person who helps them make good decisions, every other cell becomes possible. If they see you as the person who blocks their ship date with a spreadsheet, you will spend your entire tenure being routed around. You are trying to earn a standing invitation, not to install a gate.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] You can draw the current path from ticket to production on one page, including who approves what and where the automated checks run.
- [ ] There is a written, one page security design review template that lives where engineers already work (the wiki, the docs repo, the issue tracker), not in your personal notes.
- [ ] There is a written trigger list saying which changes need a review, and engineers have seen it at least twice (in a team meeting and in a written channel).
- [ ] At least three real reviews have happened, and the artifacts are findable by someone who was not in the room.
- [ ] Sensitive code paths (authentication, authorization, payments, secrets handling, infrastructure as code, continuous integration workflow files) have a named reviewer requirement configured in the code host.
- [ ] The team's definition of done or pull request template contains at least one security line that an engineer can answer honestly in under a minute.
- [ ] If the product is multi-tenant: the standing tenant-scope question is in the review template, and the authorized cross-tenant access test below has been run once on staging with the authorisation recorded in `DECISION-LOG.md`, or there is a written reason it cannot be run yet.
- [ ] You have personally fixed or unblocked at least one thing for the engineering team that had nothing to do with policy.

Explicitly NOT required at this stage:

- A security review board, a committee, or a standing meeting with an agenda.
- A formal threat model document per service, with data flow diagrams and trust boundary annotations.
- A maturity model score (Building Security In Maturity Model, Open Software Assurance Maturity Model). Nobody will read it and it will not change a single design.
- A blocking gate in continuous integration that fails builds on security findings. You have not earned that yet and the false positive rate will destroy your credibility in a week.
- Full coverage. Evan Johnson's own framing was that an ad-hoc process without full coverage is a legitimate start.
- A secure coding standard document longer than one page.

## Discovery

Goal: understand the real path a change takes, not the path the wiki claims. Everything below is read-only.

**If there is a code repository in the working directory:**

```bash
# What kind of project, what language, what package manager
ls -la
cat README.md 2>/dev/null | head -60
ls .github/ .gitlab-ci.yml .circleci/ Jenkinsfile azure-pipelines.yml 2>/dev/null

# Contribution and review rules already in place
cat CONTRIBUTING.md 2>/dev/null
cat CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS 2>/dev/null
ls .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md .gitlab/merge_request_templates/ 2>/dev/null

# Automated checks that already run on every change
ls .github/workflows/ 2>/dev/null && cat .github/workflows/*.yml 2>/dev/null | head -120
cat .pre-commit-config.yaml 2>/dev/null

# How fast do they actually ship, and who ships
git log --since="90 days ago" --pretty=format:'%an' | sort | uniq -c | sort -rn | head -20
git log --since="30 days ago" --oneline | wc -l

# Where the sensitive code lives (adjust patterns to the stack)
grep -ril --include='*.*' -e 'authenticate' -e 'authorize' -e 'permission' -e 'jwt' -e 'session' . 2>/dev/null | grep -v node_modules | head -40
```

**If the code host is GitHub and the human has the `gh` command line tool authenticated:**

```bash
gh auth status
gh repo list "<org>" --limit 100
gh api "repos/<org>/<repo>/branches/main/protection"            # read-only, needs admin scope
gh pr list --state merged --limit 30 --json number,title,reviews,mergedAt
```

If `gh api ... /protection` returns a 404 or a permissions error, do not guess. Record it as unknown and ask for read access. The console path is Repository, Settings, Branches, Branch protection rules (or Rulesets on newer accounts).

**If the code host is GitLab and `glab` is installed:** `glab auth status`, `glab repo list`, `glab mr list --merged`. Otherwise the console path is Project, Settings, Repository, Protected branches, and Settings, Merge requests, for approval rules.

**If the code host is Bitbucket, Azure DevOps, or self-hosted:** ask for read access and use the console. Do not invent command line flags.

**Where the tickets live:** look for a link in the README, in recent commit messages (`git log --oneline -50 | grep -oE '[A-Z]+-[0-9]+' | sort -u`), or in the pull request template. Common answers are Jira, Linear, Shortcut, GitHub Issues, Notion, or a Slack channel that pretends to be a backlog.

**If there is no code in the working directory at all:** this is normal for a first session. Do not fabricate. Record every SE-1 line in `SECURITY-STATE.md` as `unknown`, and switch entirely to the "Ask the human" section below. The whole discovery for SE-1 can be done in a 30 minute conversation with one senior engineer if you have no access yet.

## Ask the human

Ask these one at a time, not as a wall. Each is closed enough to get a real answer.

1. Where do changes start? A ticket in a tracker, a Slack message, or someone just opening a pull request?
2. Does every change require a review from another human before it merges, or can someone merge their own work?
3. How does code get to production: an automatic deploy on merge, a manual button, or a scheduled release?
4. In the last three months, what was the biggest new thing you shipped? (This tells you what a "big feature" looks like here, and it gives you a candidate for the first review.)
5. Is there anything in flight right now that touches customer data, login, payments, or a new third party service?
6. Who is the one engineer everybody asks when they are unsure about a design? (This is the person whose endorsement makes SE-1 work. Get to them early.)
7. Has anyone ever asked engineering for a security review before, and how did that go?

Copy-pasteable message the human can send to an engineering leader:

> Hi, I am spending my first couple of weeks understanding how we build and ship, before I suggest changing anything. Could I get 30 minutes with you or whoever knows the deploy path best, to walk from "ticket created" to "running in production"? I also want read access to the code host (repository read plus the ability to view branch protection settings) and read access to the ticket tracker, so I can answer my own questions instead of interrupting people. No changes from me without talking to you first.

Copy-pasteable message to post in the engineering channel once the template exists:

> I have put up a one page security design review here: <link>. It is not a gate and it does not need approval from me to ship. If you are building something that touches login, permissions, payments, file uploads, customer data leaving our systems, a new third party service, or anything reachable from the public internet, ping me and we will fill it in together in about 30 minutes. If I am wrong about the risk, we will write that down and move on. I would rather see 10 things early than one thing after launch.

If access is denied or delayed, record it in `ACCESS-LOG.md` with the date, who denied it, and the stated reason, then proceed with interview-only discovery. Do not stall.

## The walk

Steps 3, 5, and 6 assume the engineers work for this company: a wiki you can add a page to, a repository template you can edit, a code host organisation the company administers. If the product is built by an agency or by contractors, stop and read `09-outsourced-engineering.md` first, then run the contractual variant described in the Decision points below. Do not create channels, pages, or merge rules inside a vendor's systems.

### Step 1: Fix one thing for the engineering team

- **Goal:** buy the right to ask questions. Evan Johnson's advice is that value shown to developers spreads by word of mouth, and that is how an ad-hoc process gets traction.
- **Do:** find one small, real annoyance you can fix in a day: a flaky dependency install, a broken lint rule, a confusing error, a missing README step, a slow test. Fix it and open the change yourself. If you cannot code in this stack, do a non-code favour: write the runbook nobody wrote, or take a compliance questionnaire off an engineer's plate.
- **Verify:** the change is merged, or the engineer says thank you in a channel other people can see.
- **Time:** half a day to one day.
- **Who else is needed:** one engineer to review your change.

### Step 2: Map the SDLC end to end on one page

- **Goal:** you cannot insert yourself into a process you cannot describe.
- **Do:** run the Discovery commands, then interview one engineer for 30 minutes. Write a single page with these stages in order: idea, ticket, design (if any), branch, pull request, review, automated checks, merge, build, deploy, verify, rollback. For each stage record: who does it, what is automatic, what is optional, and where a security question could be asked without adding delay. Save it to the state directory as `sdlc-map.md` and summarise the key facts in `SECURITY-STATE.md` under SE-1.
- **Verify:** send the page to the engineer you interviewed and ask "what did I get wrong?". You need one correction back. If they say "looks right" without reading it, ask which stage is most likely to be skipped under pressure.
- **Time:** one day.
- **Who else is needed:** one engineer, ideally the one everyone asks.

### Step 3: Publish the trigger list

- **Goal:** engineers self-select into review, so you do not have to police anything.
- **Do:** publish the trigger list from the Decision points section below, in the same place the team keeps its engineering docs. Keep it to one screen. State plainly that it is not a gate.
- **Verify:** the page exists at a URL you can paste, and one engineer who was not involved can find it by searching the wiki for "security review".
- **Time:** two hours.
- **Who else is needed:** whoever owns the engineering wiki, for permission to add a page.

### Step 4: Run the first review as a pairing session

- **Goal:** the first review sets the emotional tone for every future one. It must feel like help.
- **Do:** pick a feature already in flight that hits a trigger, ideally one where the engineer is already slightly nervous. Book 45 minutes. Share your screen and fill in the template together, live, while they talk. You type. Ask the four questions (below). Do not send them homework. End the session by writing the findings yourself, with severity and a proposed owner, and by naming which findings you think can be safely deferred. Volunteering to defer something is what proves you are not a gate.
- **Verify:** the completed document exists in the shared location, linked from the ticket or pull request, and the engineer agreed with the summary in writing (a thumbs up in the channel counts as evidence, screenshot it).
- **Time:** 45 minutes for the session, one hour to write up.
- **Who else is needed:** the feature owner, and their manager notified so the time is legitimate.

### Step 5: Convert the template into the default

- **Goal:** stop being the bottleneck for starting a review.
- **Do:** add a checkbox line to the pull request template or the definition of done that asks whether any trigger applies. Add a link to the review template. Keep the wording answerable in under a minute.
- **Verify:** open a throwaway pull request (a whitespace or documentation change) and confirm the template renders with your line in it. Close the pull request.
- **Time:** one hour.
- **Who else is needed:** someone with write access to the repository template, and a heads up to the team so it does not look like a surprise.

### Step 6: Name reviewers for sensitive paths

- **Goal:** make sure the small set of files where mistakes are catastrophic always gets a second pair of eyes.
- **Do:** propose a `CODEOWNERS` file (GitHub, GitLab) or reviewer rules (Bitbucket, Azure DevOps) covering: authentication and session code, authorization and permission checks, payment and billing code, secrets and configuration loading, infrastructure as code directories, and continuous integration workflow files. Assign a senior engineer as the owner, and yourself as a second reviewer only where you can actually add value. Start with three or four path patterns, not thirty.
- **Verify:** open a test pull request touching one covered path and confirm the required reviewer is automatically requested. In GitHub, `gh pr view <n> --json reviewRequests`. Screenshot it.
- **Time:** half a day including negotiation.
- **Who else is needed:** engineering leadership approval, because this changes merge behaviour for everyone. This is a Danger zone item, see below.

### Step 7: Set a review rhythm and review your own coverage

- **Goal:** know whether the process is real or theatre.
- **Do:** once a month, list the changes that hit a trigger and check how many got a review. Write the coverage number into `SECURITY-STATE.md` under SE-1. If coverage is below half, the problem is almost always that the trigger list is too broad or the review takes too long, not that engineers are careless. Shorten it.
- **Verify:** you can state a number and name the two features you missed.
- **Time:** two hours per month.
- **Who else is needed:** nobody.

## The one page security design review template

Copy this whole block into the team wiki or docs repository. It should stay one page.

```markdown
# Security design review: <feature name>

Date:
Feature owner (engineer):
Reviewer (security):
Ticket / pull request link:
Review depth (Light / Standard / Deep, see rubric):
Status: Draft | Reviewed | Findings accepted | Closed

## 1. What are we building?
Two or three sentences in plain language. What does the user do, and what does the
system do in response? Link the design doc if one exists.

## 2. What data is involved?
- Data classes touched (for example: email addresses, names, payment data, health
  data, government identifiers, credentials, customer-uploaded files, internal-only data):
- Is any of this a data class we have not handled before? (yes / no)
- Where is it stored, and for how long:
- Who can read it in production (humans, services, third parties):

## 3. Who talks to it?
- Reachable from the public internet? (yes / no / behind login)
- New external service, vendor, or application programming interface (API) involved?
  Name it:
- New inbound integration (webhooks, callbacks, uploads)?
- Does any part accept content the user controls and then send it somewhere else?

## 4. Identity and permissions
- How does the system know who the caller is (authentication)?
- How does it decide what the caller may do (authorization), and where in the code
  is that check?
- Is there any path that skips the check (internal service call, admin tool,
  background job, migration script, bulk export, search, file download, cache)?
- STANDING QUESTION, ask this every review, no exceptions: show me a query in this
  change that fetches a record by an identifier the caller supplied. Where does the
  tenant or owner scope come from, a central mechanism or this line of code? If it is
  this line of code, what stops the next person forgetting it? (See SE-2 for what
  "central" means in this stack, and the authorized cross-tenant access test for how
  the answer gets proved rather than asserted.)
- Any new credential, token, or key created for this? Where does it live?
  (Cross-reference SE-3.)

## 5. What can go wrong?
Fill in only the rows that apply. One line each is enough.
| Concern | Applies? | What happens if it goes wrong | What we are doing about it |
|---|---|---|---|
| Someone pretends to be another user or service | | | |
| Data is changed when it should not be | | | |
| An action cannot be traced back to who did it | | | |
| Data leaks to someone who should not see it | | | |
| The feature can be used to overload or take down the system | | | |
| A normal user gains admin or cross-tenant access | | | |

## 6. If a model is in the loop
Skip if there is no large language model (LLM) or agent involved.
- Does the model see private or customer data? (yes / no)
- Does the model read content from an untrusted source (user input, web pages,
  email, tickets, documents)? (yes / no)
- Can the model cause an outbound action (send a request, write a file, call a
  tool, post a message, render a link)? (yes / no)
- If all three are yes, this needs a Deep review before launch. Say so here.
- What can the model's tools do at worst, assuming the model is fully attacker
  controlled?

## 7. How would we know if it were abused?
- What log line proves this feature was used, and where does it land?
- What would an attack look like in that log?
- Is there an alert, or are we accepting that we would find out later?
  (Cross-reference DR-2 and DR-3.)

## 8. Findings
| # | Finding | Severity (High/Med/Low) | Fix before launch? | Owner | Ticket |
|---|---|---|---|---|---|

## 9. Decision
Recommended: ship / ship with the above fixes / do not ship yet.
Accepted by (name and role):
Date:
Anything accepted as a known risk is copied into RISK-REGISTER.md with an owner
and an accepted-by name.
```

## The four questions (threat modelling in 30 minutes)

Use these when a full template feels heavy or the engineer is short on time. They are Adam Shostack's four question frame and they fit in a hallway conversation:

1. What are we building? (Make them draw it, even badly, even on a whiteboard photo.)
2. What can go wrong? (Prompt with the six rows from section 5, which are STRIDE reworded in plain language: spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege.)
3. What are we going to do about it? (One line per item. Doing nothing is an allowed answer if it is written down.)
4. Did we do a good job? (Ask at the end: what did we not talk about that worries you? The answer to this is frequently the actual finding.)

Record the answers in the template. A 30 minute conversation captured in a findable document beats a 3 hour workshop that lives in someone's memory.

## The authorized cross-tenant access test

`se-2-understand-the-tech-stack.md` documents how tenant isolation is supposed to work: where the tenant identifier comes from, whether the data layer scopes by it centrally or per query, and which paths bypass that. Documentation records intent. This procedure is how you find out whether the intent holds. For a multi-tenant business-to-business product it is the highest-value test you will run all quarter, because a missing object-level authorization check is the likeliest single route to a customer data breach, and it is the question every enterprise buyer asks first.

Run it once the tenant model is written down, and re-run the affected rows whenever a Deep review touches the isolation boundary. If the product is single-tenant, or one deployment per customer, skip this and record the reason in `SECURITY-STATE.md`.

### Hard stops, read these before anything else

If any one of these cannot be satisfied, do not start.

- **Never against production.** Not once, not carefully, not read-only. A cross-tenant read on production is an access attempt against real customer data. It is indistinguishable from an attack in your own logs, it may be a reportable event under your customer contracts and under privacy law, and if it succeeds you have personally copied a customer's records onto your laptop. Staging or a dedicated test environment only.
- **Never against a real customer's tenant**, in any environment, including a customer tenant that was copied into staging. Both tenants in this test are ones you created for this test, holding data you invented.
- **Never in an environment that contains production data.** If staging is a restore of the production database, this test cannot be run there. Say so and stop, and ask for a seeded environment. That request is itself a good SE-1 outcome and engineering usually wants it too.
- **Written authorisation before the first request**, from a named person with the authority to give it. Not a verbal yes in a corridor. The format is below.
- **Stop on the first success.** The moment one object type returns another tenant's record, you have the finding. Do not continue to see how far it goes, do not enumerate, do not pull volume. Capture one proof and stop. Continuing turns a test into the thing you were testing for.
- **Manual only.** No scanner, no fuzzer, no automated crawler, no load. Those are separate activities with their own authorisation requirement, see the Danger zone.
- This is not a penetration test and it does not replace one. It is one narrow question, asked deliberately, with a record.

### Recording the authorisation

Before the first request, write this into `DECISION-LOG.md` and get the named approver to confirm it in writing, in a message you keep. The approver is the engineering owner or the chief technology officer, whoever owns the environment.

```markdown
### <date> Authorised cross-tenant access test
Approved by: <name, role>. Evidence: <link to the message, ticket, or email>.
Scope: <staging hostname(s)> only. Production is explicitly out of scope and will not be touched.
Tenants: <tenant A> and <tenant B>, both created by me on <date> for this test, containing
  synthetic data only. No customer tenant is in scope.
Accounts: <user A> in tenant A, <user B> in tenant B, both created by me.
Window: <start> to <end>, <timezone>.
Method: authenticated requests with substituted identifiers, issued by hand, one at a time.
  No scanning, no fuzzing, no brute force, no load, no attempt against any other tenant.
Notified in advance: <on-call engineer>, <whoever watches the alerting>, so this is not
  mistaken for an incident.
Stop conditions: first successful cross-tenant read; any error visible to another user of the
  environment; any request I did not intend to send; the approver says stop.
Cleanup: test tenants and accounts deleted on <date>, or retained by agreement for re-testing.
```

Telling whoever watches the alerting is not optional politeness. A first security hire who sets off the detection they asked for, on the day they asked for it, without warning anyone, spends credibility for nothing. See `dr-4-company-comms-channel.md`.

### Setup

1. Create tenant A and tenant B on staging through the normal signup or provisioning flow, exactly as a customer would. Do not create them by inserting rows directly, because that skips whatever the real flow configures and you would be testing a shape that does not exist in production.
2. Create at least one user in each, both holding the lowest privilege role the product offers. Optionally add an admin in each, because the interesting question is often whether a tenant admin can reach across.
3. Fill tenant B with recognisable synthetic data. Use a canary string, for example an invoice titled `CANARY-B-0001` and a contact named `CANARY-B-CONTACT`. If a string of that shape ever appears in a response to a tenant A session, the finding is unambiguous and needs no interpretation by anyone.
4. Hold the two sessions in two separate browser profiles, or two separate stored token files. Never in the same session store or the same cookie jar. A leaked cookie between the two is the most common way this test produces a result that is wrong in either direction.

### The matrix

Two axes. Object types down the side, taken from the data store map in SE-2. Endpoints across the top, taken from the route list. Do not chase completeness, which is a penetration test. Take every object type that holds customer data, and for each one, the routes that read it.

For each cell: as user A, holding a valid tenant A session, issue the request that would normally fetch a tenant A object, and substitute a tenant B identifier. Vary how the identifier reaches the server, because the check very often exists on one route and not on another:

- The identifier in the path, for example `GET /api/invoices/<tenant B identifier>`.
- The identifier in a query parameter or a body field.
- The identifier in a nested route, for example `GET /api/orgs/<tenant A>/invoices/<tenant B invoice>`. This is where the parent is checked and the child is not, and it is a frequent finding.
- The tenant identifier itself substituted while keeping the tenant A session: the header, the path segment, or the subdomain. This tests question 1 in `se-2-understand-the-tech-stack.md`, whether a client-supplied tenant identifier is trusted as an identity.
- The same object through a different verb: read, update, delete, and any bulk, import, or export route.
- The same object through search rather than direct fetch.
- The same object through a file download, an attachment route, or a pre-signed link.
- The same request with no session at all, which occasionally succeeds and is a different and worse finding.

The expected result on every attempt is 404 Not Found, or 403 Forbidden, with no tenant B data anywhere in the response, including inside error messages, validation text, and stack traces. Record the actual result, not the expected one.

Three outcomes and what each means:

- **404, no tenant B content in the body.** Correct. The row was never visible to this session.
- **403.** The object was loaded and then a check rejected it. Not a finding on its own, and worth a note, because it tells you the check happens after the load, so any code path that loads without checking will leak. Read the body and any error identifier carefully for tenant B content.
- **200 with tenant B data, or any status carrying the canary string.** Finding. Stop the matrix and go to the writeup.

### Evidence to capture

For each attempt: date and time with timezone, environment hostname, acting user and tenant, the request line and the substituted identifier, the response status code, and whether the canary string appeared. A table inside the design review document is enough.

For a success, capture the minimum that proves it: the request, the status code, and one canary field. Redact the rest. Do not save a full response body containing another tenant's records into your notes even when the data is synthetic, because the habit is what carries over to the day it is not. Store evidence under `evidence/` in the state directory and link it from the review document.

Write into `SECURITY-STATE.md` under SE-1 a dated line: matrix run on `<date>`, N object types by M route shapes, K findings, evidence at `<path>`. That line plus the `DECISION-LOG.md` authorisation entry is exactly what an enterprise customer or an auditor wants when they ask whether you test tenant isolation, and it is far more convincing than a policy sentence. It is also reusable in `co-2-questionnaire-knowledge-base.md`.

### If you find one

A cross-tenant access finding is incident-adjacent, not automatically an incident. What decides is whether anyone has already used it, and the only place that answer lives is the logs.

- Tell the engineering owner privately and immediately. Not the company channel. See the Danger zone.
- Ask, using `dr-2-top-security-signals.md` and `dr-3-logging-consumption-model.md`, whether the logs would show the same request shape coming from a real user, then go and look. If they show it happened, this is an incident and it moves to `dr-1-incident-response-plan.md`, and to `co-3-existing-commitments.md` for any contractual breach notification clock.
- If you cannot tell from the logs whether it was ever used, say exactly that, in those words, to the engineering owner and to the executive. The inability to answer is itself a finding and it belongs to DR-3.
- The fix is a Deep review item. When it lands, re-run the row of the matrix that failed and the whole column it sat in, because a missing check is rarely alone.
- The finding, the owner, the fix, and the re-test date go into `RISK-REGISTER.md` until closed.
- Delete the test tenants when the test is done, or keep them by written agreement as a regression fixture, which is the better outcome.

## Triage rubric: how deep should this review be?

Apply in order. First match wins.

| Depth | Trigger | Time budget | Output |
|---|---|---|---|
| **Deep** | New data class the company has never held; payment or money movement; a change to how authentication works; multi-tenant isolation boundary; a new subprocessor that will hold customer data; an LLM or agent with private data access plus untrusted input plus an outbound channel; anything that will appear in a customer contract or security questionnaire | 2 to 4 hours across two sessions, plus a written follow up | Full template, findings tracked as tickets, explicit named sign-off |
| **Standard** | New internet-facing endpoint or service; any new route or background job that fetches a record by an identifier the caller supplies; authorization or permission model change; file upload or file processing; a new third party integration that receives data; new background job with production database write access; changes to continuous integration workflow files or deploy permissions | 30 to 45 minutes, one session | Full template, findings in the pull request |
| **Light** | Existing pattern reused in a new place; new field on an existing model with no new data class; internal-only tool with existing authentication; copy or user interface changes on an existing flow | 10 minutes, asynchronous in the pull request thread | Three sentences in the pull request, no separate document |
| **None** | Refactor with no behaviour change; dependency version bump inside an existing major version; documentation; tests | 0 | Nothing |

Trigger list to publish verbatim to engineers: a new class of customer data, a new external integration or vendor, any change to login or permissions, any new endpoint that fetches a record by an identifier the caller supplies, a new subprocessor, anything involving payments, anything that accepts file uploads, anything reachable from the public internet, and anything with an AI model in the loop.

## Decision points

**Gate versus advisory.** DEFAULT: advisory for the first two quarters. You have no political capital and a blocked release will be remembered for years. Change to a soft gate (review required, but any engineering manager can override in writing) only after you have run at least ten reviews and the team asks for them unprompted, or when a contract or framework commitment requires it (see CO-3).

**Who runs the review.** DEFAULT: you run all of them at first, because the quality bar and the tone are being set. Change once you hit roughly one review per week: train two or three senior engineers as security champions, let them run Light and Standard reviews, and keep Deep for yourself.

**Where the artifact lives.** DEFAULT: in the same system engineers already use for design documents (the wiki page, the docs repository, the ticket). Never in a security-only folder that requires a special request to read. If the answer is "we do not have a place", put it in the code repository under `docs/security-reviews/` so it is versioned and searchable. Change only if legal counsel asks for privileged handling of a specific review, which does happen with pre-acquisition or post-incident work.

**Synchronous pairing versus asynchronous form.** DEFAULT: synchronous for the first ten reviews. A form emailed to an engineer gets answered defensively and shallowly. Switch to asynchronous only for the Light tier, or once the template is well understood and you are the bottleneck.

**There is no SDLC at all.** This is common at under 30 people. DEFAULT: do not try to create one. Creating a software development lifecycle is not a security hire's job and attempting it will make you the process police in month one. Instead do inbound: publish the trigger list, be visibly useful, ask to be added to the engineering channel, and read every merged pull request title once a day for 15 minutes so you catch triggers yourself. Then propose exactly two lightweight additions that engineering would want anyway: a pull request template and a required second reviewer. Both improve engineering quality, so they are easy to say yes to. Change this only if engineering leadership explicitly asks you to design the process, in which case get that request in writing and record it in `DECISION-LOG.md`.

**Engineering is an agency or contractors, not employees.** Steps 3 through 6 of the walk assume an internal team with a shared wiki, a pull request template you can change, and an engineering channel you can post in. If the product is built by an agency, none of those are yours, and posting a trigger list into a vendor's Slack workspace achieves nothing. DEFAULT in that case: do not create channels, templates, or `CODEOWNERS` rules you cannot maintain. Make the review a contractual checkpoint instead, and read `09-outsourced-engineering.md` before doing anything else, because the prior question is whether the company even owns the repository, the cloud account, and the deploy path. The template in this file still works unchanged as the artifact for the checkpoint. Change this if some engineering is internal and some is outsourced, which is the common middle case, in which case run this cell normally for the internal team and contractually for the agency, and keep one review template for both so the two halves are comparable.

**Coverage versus depth.** DEFAULT: depth on the few things that matter, and accept that you will miss things. Evan Johnson's own framing was that ad-hoc and partial is still a start. Chasing full coverage in quarter one produces a shallow checkbox process nobody respects.

## Danger zone

Every item here requires an explicit yes from a named human before you do it. State the risk out loud, in these words, and wait.

- **Turning on required reviewers or CODEOWNERS enforcement.** If the named owner is on holiday or leaves the company, merges stop for everyone touching those paths. Get engineering leadership approval, name a backup owner, and confirm the team knows how to request an override. STOP and get a yes.
- **Making any check blocking in continuous integration.** A blocking check with a false positive rate stops all deploys, including the hotfix for an incident. Run new checks in warn-only mode for at least two weeks and show the actual finding counts before proposing blocking. STOP and get a yes.
- **Changing branch protection or repository rulesets.** This can lock the whole team out of merging, or silently weaken protection if you get a setting backwards. Read the current settings, screenshot them, propose the change in writing, and let someone with ownership apply it. STOP and get a yes.
- **Commenting a finding publicly on an open source repository or a public pull request.** You may be disclosing a live vulnerability to the internet. Move it to a private channel first. STOP.
- **Declaring a feature "not shippable" in a public channel.** You do not have that authority in month one, and using it early will get it taken away. Escalate privately to the engineering owner, then to their manager, and record the disagreement in `DECISION-LOG.md`.
- **Attempting a cross-tenant request outside the authorized test procedure above.** Substituting one identifier is still an access attempt. Against production it is an access attempt on real customer data, made by an account with your name on it, and if it succeeds you have exfiltrated a customer's records. Against a customer's tenant in any environment it is unauthorised access to their data regardless of who owns the server. The only sanctioned form is two tenants you created, on staging, with the authorisation written into `DECISION-LOG.md` first. STOP and get a yes.
- **Running any scanner against a production environment**, including a web scanner or a fuzzer pointed at a live endpoint. It can cause an outage, generate customer-visible errors, page an on-call engineer, or run up cloud bills. STOP and get a yes with a named window.
- **Adding yourself as a required reviewer on high-traffic paths.** You will become the bottleneck within a week and the team will start batching or routing around you. This is a self-inflicted wound rather than an outage, but it kills the programme just as effectively.

## Do not do this yet

- Do not buy or roll out a static analysis or application security testing platform in your first quarter. The findings backlog will be in the thousands and nobody, including you, will triage it. SE-2 and the modern supply chain cell give you better returns first.
- Do not write a secure coding standard longer than one page. Nobody reads it and it ages badly.
- Do not build a formal threat model per service. Four questions per feature is the right resolution for a startup.
- Do not attempt to mandate design documents where the culture does not already write them. You will be blamed for slowing engineering down and the security content will be padding.
- Do not run a security training programme yet. Training with no working relationship is resented. Do reviews first, then training grows naturally out of the questions engineers keep asking.
- Do not build a review tracking dashboard before you have run ten reviews. You will be measuring nothing.
- Do not gate on a maturity model or import an enterprise SDLC framework wholesale. It is theatre at this size.

## Evidence to capture

- `SECURITY-STATE.md`, section SE-1: status (unknown / none / partial / done), the link to the SDLC map, the link to the review template, the trigger list link, the count of reviews run in the last 90 days, the estimated coverage percentage, and the CODEOWNERS status. Include the evidence for each claim (a link, a screenshot filename, or a command output), never a bare assertion.
- `DECISION-LOG.md`: the date and reasoning for advisory-versus-gate, who approved CODEOWNERS enforcement, and any case where you recommended not shipping and were overruled, including who overruled you.
- `RISK-REGISTER.md`: every finding accepted without a fix, with severity, the owner, the accepted-by name, and a review date. This is the single most valuable artifact SE-1 produces, because it converts "security said it was fine" into a dated record of who decided what.
- `SECURITY-STATE.md`, SE-1, if the product is multi-tenant: the dated result line from the authorized cross-tenant access test (object types by route shapes, findings count, evidence path), or the written reason it has not been run.
- `ACCESS-LOG.md`: the date you requested code host read access, ticket tracker access, and wiki write access, and when each was granted or denied.
- Artifacts a future auditor or enterprise customer will ask for: a written secure development policy (one page is acceptable), evidence that code changes get peer review before merge (a sample of merged pull requests showing an approving reviewer), evidence that security-relevant changes get additional review (the review documents themselves), and a description of how security requirements enter the backlog. Every one of these falls out of this cell naturally if you keep the artifacts findable. Do not create them separately for the audit.

## Cost and effort

- Steps 1 through 5: roughly 4 to 6 working days spread over three to four weeks, because most of it is waiting on other people's calendars.
- Ongoing: 2 to 5 hours per week at 20 to 100 people, mostly reviews.
- Dollar cost: zero. Everything in this cell uses tools the company already pays for (the code host, the wiki, the ticket tracker).
- Free options that add real value here: the code host's built-in secret scanning and dependency alerting (available at no cost on public repositories and on most paid organisation plans you already have), `pre-commit` for local hooks, `semgrep` open source rules run in warn-only mode, `gitleaks` for secret detection. Turn on what is already included before evaluating anything new.
- If you eventually need a paid application security testing tool, expect roughly 10,000 to 40,000 US dollars a year at startup scale for a mid-market static analysis product, and more for the platform vendors. Do not spend it in your first two quarters. If someone insists, ask them to name the finding they expect it to catch that a human reviewer would miss, and record the answer in `DECISION-LOG.md`.

## 2026 notes

Four things changed since the 2019 slide, and they change how this cell should be run.

1. **Human review is no longer the rate limiter.** AI-assisted development has raised the volume of code per engineer sharply. Standing at the pull request and reading everything does not scale and never will again. Your leverage moved to the paved road: the repository template, the shared library, the infrastructure module, the reusable pipeline job. A design review that ends in "we added a safe helper to the shared library" is worth ten that end in "the engineer promised to be careful".
2. **The review triggers now include the build pipeline.** In 2019 nobody thought of a workflow file as production infrastructure. In 2026 a change to a continuous integration configuration file is a change to the most privileged identity in the company, and it should trigger a Standard review the same way an authentication change does. See `07-modern-cells.md`.
3. **A model in the loop is a first class trigger.** Section 6 of the template exists because of the lethal trifecta test: private data access, exposure to untrusted content, and an outbound channel. Any two of the three is usually manageable. All three means anyone who can put text where your system reads it can make it act. Prompt injection is not a bug you patch, it is an input trust problem you design around, so it has to be caught at design time, which is exactly what this cell is for.
4. **Dependency additions deserve a question at review time.** In 2019 "we added a library" was not a security event. In 2026 the install step itself is the compromise point. When a review reveals a new dependency, note it and route it to the supply chain cell rather than treating it as free.

## Failure modes

- **You become the bottleneck.** Early tell: engineers start batching requests, or you hear "we did not want to bother you". Recovery: cut the trigger list, push Light reviews to asynchronous comments, train two champions, and publicly state a turnaround commitment you can actually meet (for example, first response within one business day).
- **The review becomes a checkbox.** Early tell: templates come back with every row marked not applicable, filled in five minutes before the meeting. Recovery: stop accepting written submissions and go back to synchronous pairing for a month. Ask question four ("what did we not talk about that worries you?") first instead of last.
- **You get invited too late, after the code is written.** Early tell: every review produces findings that would require a rewrite, so none of them get fixed. Recovery: move upstream to whatever artifact exists before code (the ticket, the design document, the sprint planning meeting) and ask to be a silent observer there. Also fix the trigger wording, which usually says "before launch" when it should say "before you start building".
- **You are routed around entirely.** Early tell: you learn about a launch from a customer-facing announcement. Recovery: this is a relationship problem, not a process problem. Go back to step 1 and fix something for the team. Then ask the engineering leader directly whether the reviews are seen as useful, and be genuinely willing to hear no.
- **Findings pile up with no owner.** Early tell: your findings table has more rows than the ticket tracker. Recovery: every finding either gets a ticket with an owner within 48 hours, or gets moved to `RISK-REGISTER.md` as accepted with a named accepter. There is no third state. A finding with no owner is not a finding, it is a note to yourself.
- **You block something and are overruled.** Early tell: it already happened. Recovery: do not fight it. Write the risk in `RISK-REGISTER.md`, get the name of the person who accepted it, confirm that in writing, and move on. Being the person who documents decisions calmly is far more durable than being the person who was technically right.

## Related cells

- [SE-2: Understand the tech stack](se-2-understand-the-tech-stack.md), because you cannot review a design in a stack you do not understand, and because the tenant isolation discovery there is the input to the authorized test here.
- [SE-3: Secrets and keys](se-3-secrets-and-keys.md), for every review where the answer to "any new credential?" is yes.
- [SE-4: Bug bounty and disclosure](se-4-bug-bounty-and-disclosure.md), for what to do with findings that arrive from outside this process.
- [DR-2: Top security signals](dr-2-top-security-signals.md) and [DR-3: Logging consumption model](dr-3-logging-consumption-model.md), for section 7 of the template.
- [CO-3: Existing commitments](co-3-existing-commitments.md), which tells you whether a contract already requires a formal secure development process.
- [CO-4: Data inventory and framework](co-4-data-inventory-and-framework.md), which is where a "new data class" answer must be recorded.
- [07: Modern cells](07-modern-cells.md), for supply chain, continuous integration and delivery, cloud posture, and AI review triggers.
- [06: 2019 to 2026 delta](06-2019-to-2026-delta.md), for why the paved road beats the review queue.
- [02: Intake questions](02-intake-questions.md), for the full question bank and more access request templates.
- [09: Outsourced engineering](09-outsourced-engineering.md), for the branch where the engineers are an agency and design review becomes a contract term rather than a habit.
- [03: 90 day plan](03-90-day-plan.md), for where SE-1 sits in the sequence.
