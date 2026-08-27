# Progress: Founding Security Engineer agent

**Last updated:** 2026-08-25

## Goal

Build a full founding Security Engineer partner: an agent that acts as a colleague, not an assistant, for someone who is the first security hire at a startup and does not yet know what a security program looks like. It must work in any environment, scan what it can, ask for what it cannot see, walk a 90 day plan in baby steps rather than dumping it, and handle urgent work arriving mid-task without losing the thread.

## Source framework

OWASP AppSec California 2019. **Evan Johnson**, then Senior Security Engineer at Cloudflare, talk "Startup security: Starting a security program at a startup" (deck title: "Starting Security at a Startup"). Slide 18, "4 things to do in each security domain". A 4x4 grid: Security Engineering, Detection and Response / Incident Response, Compliance, Corporate Security, four items in each. [Video](https://www.youtube.com/watch?v=6iNpqTZrwjE) and [original slides](https://hosted-files.sched.co/appseccalifornia2019/22/Evan%20Johnson%20-%20Starting%20Security%20at%20a%20Startup.pptx), both verified by downloading and extracting the deck; slide 18 byte-matches the photograph.

Two deliberate departures from the source, both documented in the artifacts:

1. The fourth Compliance cell is blank on the photographed slide but filled later in the deck (slides 20 and 21) as "GDPR and current laws". Widened to data inventory, privacy commitments, and framework choice (CO-4), presented as a superset of Johnson's answer rather than as filling a void.
2. The 2019 grid predates software supply chain, CI/CD as the primary target, cloud posture, SaaS and OAuth sprawl, and AI and LLM security. Added as modern cells M-1 to M-5, with a standalone 2019 to 2026 delta briefing so the reasoning is visible rather than silently patched in.

## Implemented

- **`~/.claude/skills/founding-security-engineer/SKILL.md`**: the partner persona and router. Partner contract (ten rules), the grid, operating loop, cold start summary, interrupt summary, state file definitions, full reference routing table, default sequencing with reasoning, and eleven hard stops requiring explicit human approval.
- **`~/.claude/agents/security-recon.md`**: read-only reconnaissance worker the partner dispatches for heavy discovery. Hard read-only, no active testing, no credential testing, structured output format, severity judged by impact on this company rather than generic scoring.
- **`README.md`** (this project): the human operating manual. How to run it, what to ask it, how to operate with it, and the full interrupt navigation contract.
- **Reference library** under `~/.claude/skills/founding-security-engineer/references/`: 16 cell playbooks (one per grid cell), 8 core protocol files (cold start, recon, intake questions, 90 day plan, interrupts, metrics and comms, 2019 to 2026 delta, modern cells), plus state file templates. Authored in parallel, then put through three independent review passes: completeness, adversarial accuracy and safety, and cross-file coherence.

## Key decisions

- **Skill, not subagent, for the partner role.** The partner must run in the main conversation so it can ask the human questions interactively, hold the context stack across turns, and be interrupted. A subagent cannot do that. Subagents are used only as read-only workers underneath it.
- **Global install, not project-scoped.** The stated requirement was that it work in any environment, so both the skill and the worker live under `~/.claude/` rather than in a project `.claude/` directory.
- **State lives in `./.security/` in the working directory**, falling back to `~/security-program/<org-slug>/` when there is no repo. The agent asks once whether to commit or gitignore and recommends committing to a private repo.
- **The 90 day plan is gated, not dumped.** Four gates (Understand, Stop the bleeding, Build the floor, Make it durable) with overlapping date ranges and explicit exit criteria, rather than three arbitrary thirty day blocks. The agent walks one step at a time and never presents the whole plan unless asked.
- **Interrupts are a first-class protocol, not an afterthought.** A context stack file, five interrupt classes with different responses per class, agent-initiated interrupts with a required format, and hard rules against silent task switching or silent dropping.
- **Every cell playbook uses the same section template** so the model can navigate them deterministically at runtime and a human can skim them.
- **Vendor-agnostic by construction.** Every playbook branches across cloud, code host, identity provider, and chat vendors, and always covers the case where the answer is not known yet.
- **Findings drive the plan; the framework never does.** Corrected mid-build after the direction was challenged. The grid is a checklist for the agent's blind spots, not a work order for the human. Sequencing was demoted from "the plan" to "a prior you should be able to explain deviating from", cells can be closed `n/a` with a reason, and an explicit anti-pattern section gives the agent the tells that it has drifted into marching a checklist. Johnson's own slide 16 supports this: he does not hand out a sequence, he hands out the dimensions that determine one.
- **Backups go outside the load path.** Found by testing the installer: a backup directory left inside `~/.claude/skills/` is discovered as a second, duplicate skill. Backups now go to `$PREFIX/.founding-security-engineer-backups`.

## Review and hardening

The 25 authored files went through three independent review passes (completeness by a simulated seasoned head of security, adversarial accuracy and safety, cross-file coherence). **81 findings: 15 blocker, 40 major, 26 minor.** All preserved verbatim in `REVIEW-FINDINGS.md`.

**Eight blockers fixed immediately, three of them because the text as written was actively dangerous:**

1. The read-only cloud access request template told the reader to write to their CTO that the roles requested "do not grant access to the contents of data stores". False for two of three clouds: AWS `ReadOnlyAccess` includes `s3:Get*` and `dynamodb:Scan`, Google Cloud `roles/viewer` includes `storage.objects.get`. The skill would have made a beginner send a false written claim to a colleague on day one and request bulk read of all customer data. Narrowed to `SecurityAudit` plus `ViewOnlyAccess` on AWS and `roles/iam.securityReviewer` plus `roles/browser` on Google Cloud, with the reasoning stated in the message.
2. The DR-4 escalation agreement asked a founder to pre-authorise "disable any employee or service account, revoke any credential" without approval, contradicting the hard stops in `SKILL.md` and the danger zones in four other playbooks. Narrowed to reversible containment during a declared incident: revoke sessions, revoke third party grants, block external access.
3. DR-1's fast path said "preserve evidence before you fix anything, do not rotate keys until logs and memory are captured". Followed literally during a stolen-session incident, that keeps an attacker inside while a 25 person startup attempts a memory capture it cannot perform. Rewritten to preserve in parallel with containment.

**Five coherence blockers fixed:** four competing identifier schemes for the modern cells unified on `M-1` to `M-5`; the CONTEXT-STACK template rewritten as a transcription of the interrupt protocol so the agent can parse its own prior output; the 90 day plan template's gate scheme aligned to the owning reference; nine cell-owned state files declared in `SKILL.md`; parked-frame ceiling aligned at three.

**Source accuracy corrected from the original deck.** The research agent located, downloaded, and extracted the original `.pptx` and byte-matched slide 18. Three corrections followed: the fourth Compliance cell is not blank in the deck, it is filled on slides 20 and 21 as "GDPR and current laws", so our data-inventory framing is now presented honestly as a superset rather than as filling a void; the mark on the Endpoint cell is a gift emoji, Johnson's marker for a cheap win; and slide 16, "It all depends", lists the six dimensions that determine priority (B2B or B2C first, then company size, customer base, product, engineering velocity, culture), which is now wired into `SKILL.md` as the mechanism behind findings-driven ordering.

## Pass 2: closing the completeness blockers

Five new playbooks authored, 81 findings applied across 21 files by agents partitioned so no two wrote the same file, then three max-effort re-review passes. **62 further findings: 10 blocker, 29 major, 23 minor**, preserved verbatim in `REVIEW-FINDINGS-PASS2.md`.

All three reviewers independently confirmed the seven original completeness blockers are genuinely closed rather than gestured at. All three also said "not shippable yet" on the strength of the ten new blockers, which are now fixed.

**The sharpest new blocker was one this build introduced.** The pre-authorised incident containment set said the hire may "block external network access" and, in the next clause, "never a firewall or network rule change". Those are the same act. The wording had propagated into six files. Blocking is also the only item on that list that can take customers offline: block a carrier-grade address range or a corporate virtual private network egress and you have caused the outage the pre-authorisation existed to avoid. Resolved by dropping network blocking from the pre-authorised set entirely, in all six files. What remains pre-authorised is exactly two actions, both identity-scoped and both reversible in one action: revoke a named human user's sessions and refresh tokens, and revoke a third party application's grant.

**Other blockers fixed:**

- The timed restore drill, the most destructive action in the whole skill, carried no explicit-yes gate while the three steps above it in the same list each had one. A reader working sequentially would reasonably infer it was safe. It now stops for the datastore owner and whoever approves cloud spend, and requires reading back the target identifier, the cost, and whether the scratch environment's access controls match production.
- `SKILL.md` treated "could cost money" and "could never be reversed" as the same category. This pass introduced a whole class of one-way doors (object lock in compliance mode, vault lock past its cooling-off period, locked storage retention, encryption key deletion, removing an account from a cloud organisation, changing a subscription's directory, app store transfer, registrar transfer). Two new hard stops added, because a danger zone in a file that has not been loaded protects nobody.
- The refusal procedure, the section that exists to stop the hire signing claims they cannot evidence, contained two model "accurate" sentences that were exactly that: an unbounded claim about the company's entire history, embedding a legal determination the rest of the corpus says belongs to counsel. Replaced with bounded wording tied to the retention date from DR-0.
- A prescribed `RISK-REGISTER.md` entry pluralised a single event into an ongoing pattern and stated a compliance consequence, in a file that is discoverable by an acquirer, a regulator, or opposing counsel. Replaced with the neutral factual form, plus an explicit rule in `SKILL.md` against legal conclusions in any state file.
- Cold start mandated "all sixteen grid cells plus the modern cells", which silently dropped SE-5 and DR-0 (neither is in the original sixteen nor in the modern block), and it was a completion checkbox, so cold start could be declared done with both new cells missing. Replaced with an explicit enumeration.
- The outsourced-engineering playbook forbade fetching the company homepage while citing as its authority the file that explicitly permits it.
- The most consequential routing decision in the skill collided three ways. Split: a **named** past event routes to DR-1 first, because the questions immediately become legal ones. An **unnamed** scare routes to DR-0, which is built for going looking when nothing was ever declared.
- The vendor register had two incompatible homes with different column sets, in the same file where M-4 warns that exactly that split guarantees a customer finding an unlisted subprocessor. Merged into one register with the subprocessor and single-sign-on columns explicitly labelled as the CO-1 and CS-3 feeds.

**Verification, scripted and passing:** zero em or en dashes across 31 files; all relative markdown links resolve; no stray identifier schemes; no dangling state-file references; the containment contradiction is gone; no AI attribution; all 30 reference and template files reachable from the `SKILL.md` routing table.

## Smoke test: first real session

Run 2026-08-25. A scratch repository was built for a fictional 40 person business-to-business analytics company with **twelve findings planted** and a hidden backstory. One agent played the first security hire, revealing facts only when asked. One agent loaded `SKILL.md` and acted as the partner. Ten alternating turns, including a live business email compromise injected mid-task at turn 5, a resume at turn 7, a pushback at turn 8, and a named past incident volunteered at turn 9. Two max-effort graders scored the transcript and the resulting state directory. Full results in `SMOKE-TEST.md`, unedited transcript in `examples/smoke-test-transcript.md`.

**Protocol compliance 7/10. Technical effectiveness 8.5/10.** Both graders said they would let a real first security hire use it.

**What held.** All twelve planted findings found, nine of them in the first response with zero access, ordered by consequence rather than by count. **Zero hallucinations across roughly thirty checkable technical assertions**, independently re-verified by the grader against the files, npm, DNS and whois. The single claim that was arguably wrong was the single claim the partner had explicitly hedged as needing verification. Every one of the ten turns closed with a named next action and a go or no-go. The turn 5 business email compromise was triaged correctly and ordered correctly: hold the payment first, do not reply or click, then call back out of band on a number already held. The turn 7 resume was rebuilt from disk rather than from memory, with a drift check. Nothing was mutated, no credential was tested, no legal conclusion reached a durable file, and there was not one em dash anywhere.

**Three fixes from earlier passes were confirmed working in the field.** The named-past-event routing split sent turn 9 to the incident playbook rather than the compromise hunt, and then refused to double count it as a second event. The corrected cloud role guidance produced an access request for `SecurityAudit` plus `ViewOnlyAccess` with the reasoning stated, explicitly refusing `ReadOnlyAccess` because it includes `s3:Get*`. And the hard stops held: it declined to enable organisation-wide two factor on the code host because that would have ejected the only person who can deploy.

**What failed, and it was the same theme twice.** The conversation layer is strong; the durable layer rots. `ACCESS-LOG.md` ended structurally broken with rows orphaned outside their table and an invented status value that disabled the escalation check. `DECISION-LOG.md` was silently rewritten from the per-decision block format into a flat table, dropping exactly the two fields that protect the hire when a founder overrules them. Grid rows acquired invented status strings. An ad hoc heading appeared that the template explicitly forbids. A duplicate identifier was issued. A row was deleted rather than marked dropped.

Two behavioural failures compounded it. **Sixteen of eighteen access requests were written and never sent**, and the cold start exit criterion said "produced" rather than "delivered", so that run passed the checklist cleanly. And the two highest-consequence defects, the cross-tenant read path and the unauthenticated impersonation endpoint, were correctly rated critical in the first turn and still read `UNOWNED` at the tenth, while a message went to exactly the right person on day two carrying only the other two findings.

**Eight fixes applied in response:** a critical risk must get a named owner or an attached draft in the turn it is opened, with a pre-send sweep so an outbound message picks up every critical risk owned by its recipient; an unsent ask escalates after two turns and switches to a two-line paste format; the bookkeeping paragraph must be plain English, with a banned and a required example, because that is exactly where cell identifiers leaked at the human; a must-expand acronym list so expansion is lookup rather than recall; "delivered" replaces "produced" in the cold start exit criteria; the `.gitignore` append is now a verified step rather than fire and forget; the access log requires the exact minimal role string per provider inline; a new Tier 0 recon section for object-level authorization and the tenancy model, because the tenant bug was caught by eye here only because the file was fourteen lines long; a required round one of five intake questions, led by the past-incident question because it is the only one whose answer expires; and a schema conformance check plus rules against invented statuses, deleted rows, duplicate identifiers, orphaned rows, and dropped columns.

## Post-smoke-test verification: what is actually applied

Every one of the eighteen smoke test fixes was re-checked against the files on 2026-08-25 rather than against
the notes claiming they were applied. **Thirteen are fully applied, four are partial, four are not applied.**
The narrative above understated this: more landed than "eight fixes applied" suggests, but the ones that did
not land cluster in one place and that place is the one that already failed.

**Applied and verified in the files:** the orphaned-row containment check and the identifier-conformance check
(`templates/README.md` integrity checks 3 and 4); the five-value grid status enum with the qualifier pushed to
Notes; the forbidden ad-hoc heading rule plus a heading-conformance check; the reported-absent rule and the
`human-confirmed:` evidence prefix; the severity-first sort; the plain-English bookkeeping rule with the leak
point named; the must-expand acronym list with the expansion to use inline; the critical-risk owner rule with
the pre-send sweep and the one-working-day timebox (`SKILL.md` rule 10); the unsent-ask escalation with the
two-line paste format and the deciding-or-sending diagnostic (`SKILL.md` rule 11); "delivered, not merely
produced" in the cold start exit criteria; the required round one of five intake questions; Tier 0 section 0.11
for object-level authorization and the tenancy model, with the tenancy model added to the Tier 0 exit criteria;
the exact-role column with the three provider strings inline; the verified `.gitignore` append; the
outside-repo state directory default; and the mandatory pre-populated incident notification table, insurance
row included.

**The four fixes that did not land share one root cause, and it is the same theme as the smoke test failure
itself: they were written as prose rules and never propagated into the schema blocks the writer copies.** So the
rule and the schema now contradict each other and the agent has no legal value to write. Integrity check 7
counts access rows "that have never been delivered" against a status vocabulary with no value for
written-but-not-sent, so the mechanism installed to fix the single worst behavioural failure in the run cannot
execute. The rule to mark a bad row `dropped` points at a risk status list that does not contain `dropped`. The
rule mandating a `Reference` column for non-grid playbooks points at a schema that does not declare one, while
check 5 requires every declared column to exist in the declared order. And the incident header still has no
value for an incident being scoped, which is exactly why the writer invented `Status: OPEN` and
`Severity: pending`. Tracked as `TODOS.md` #27.

**Three defects from the pass 2 long tail were re-verified as live, not merely scoped.** `SKILL.md` line 251
still reads "no exceptions" over a hard stop on changing anyone's access, while seven playbooks and the security
charter tell the hire to negotiate a standing pre-authorisation for exactly that during a declared incident.
`SKILL.md` is the always-loaded file and the playbooks are on-demand, so the agent reads "no exceptions" and
cannot use the pre-authorisation it was told to negotiate (#28). `m-6` line 193 still tells the reader to leave
AWS Backup Vault Lock "unlocked at first", a state that does not exist, in the file whose own Danger zone warns
about the irreversible outcome a literal reading produces (#29). And `dr-2` line 91 still asserts the Google
Workspace leaked-password alert is on by default across editions when it requires a higher tier, which makes the
hire promise a founder a detection the company may not have (#29).

**One design regression is live.** The Gate A step table in `templates/README.md` is pre-filled with four
generic steps at `not-started` and no gate table has a column for the justifying finding, against
`03-90-day-plan.md`'s rule that a step with no finding attached does not go in the file. The template hands the
agent four numbered steps it can propose before any discovery, which is the framework-marching that the
mid-build direction correction exists to prevent (#30).

**Hygiene is still clean.** Zero em dashes, en dashes or double hyphens outside table syntax across the skill,
agent, and portable files; every relative markdown link resolves; no AI attribution anywhere; `install.sh
--check` reports both symlinks healthy, so the installed skill and the repository are the same bytes.

**Readiness verdict.** The conversational layer is genuinely good and both graders would let a real first
security hire use it. It is usable today by someone who reads what it writes before acting. It is not ready to
hand to a beginner unsupervised, and not ready to publish, for three reasons: the state layer has four
schema-versus-rule deadlocks that guarantee a repeat of the rot the smoke test found, `SKILL.md` contradicts
seven playbooks on what is pre-authorised during an incident, and two factual errors sit in paste-ready
instructions, one of which leads to an irreversible action. Those are #27 through #30 and they are a focused
patch across two files plus three reference lines, not another authoring pass.

**The re-run is not currently reproducible.** The planted scratch repository was in a temp directory and is
gone, there is no `test/` in the repo, and the transcript does not carry an answer key. `SMOKE-TEST.md` does
enumerate all twelve findings with their file and line, so it can be rebuilt from that, which is `TODOS.md` #26
and is a prerequisite for #25 being a real before-and-after rather than a fresh run against a different repo.

## Patch pass: closing the blockers with six parallel agents

Run 2026-08-25, after the verification above identified four blocking defects and three coherence
clusters. **Verifier result: 72 checks, 72 passing, from a pre-patch baseline of 20 passing and 43
failing.**

**How it was carved, and why that mattered.** The defect being fixed was a corpus where one rule had
been reworded by six different writers until it authorised and forbade the same act in six files. So
the pass was partitioned by **file ownership, not by defect**: six agents, each with an exclusive
non-overlapping file set, none able to write a file another agent owned. Every string that had to
match across files (the containment carve-out, the consumer pointer sentence, all four status
vocabularies, the charter filename, the channel gate, the M-6 gate line, the bootstrap block) was
decided up front, written into a single canonical contract, given exactly one owning file, and handed
to every consumer byte for byte. Consumers point at the owner; they never restate the boundary. Eight
playbooks now carry one identical pointer sentence where they previously carried eight paraphrases.

**What landed.** All four state-layer schema deadlocks, the `SKILL.md` hard-stop contradiction, both
factual errors, the findingless Gate A prefill, all four dangling cross-references, the missing
production-data-access step, and every remaining smoke test fix. Detail per item in the `TODOS.md`
Closed table under #24 and #27 to #32.

**Three agent judgement calls that improved on the contract.**

1. Agent A noticed that `dropped` exists only in the risk schema, and that propagating the
   never-delete rule into `ACCESS-LOG.md` and `DECISION-LOG.md`, whose schemas declare no such
   status, would have created a **new** deadlock identical in shape to the four being removed. It
   wrote the narrower rule. The contract as issued would have shipped the broader one.
2. Agent E's migration step is stronger than specified: it refuses a destination that already exists,
   refuses a source that does not, moves rather than copies, and re-verifies the ignore rule at the
   **new** location, which is the omission that actually causes the register to get committed.
3. Agent D's CS-1 step 11 is the strongest single addition. Seven paths to production customer data,
   each answering who can use it, whether a per-access record names the human, and whether the log is
   retained, built on verified vendor defaults rather than generalities, and ending in a fill-in
   sentence that is the real deliverable rather than a table.

**The finding that matters most: one of our own review findings was factually wrong, and it was
inside the patch contract as canonical.** Pass 2 finding at `REVIEW-FINDINGS-PASS2.md` line 408
asserted that the Google Workspace leaked-password alert "is limited to higher Workspace and Cloud
Identity tiers and is not available on Business Starter or Standard". It was carried into the contract
unverified. Agent C refused to write it, checked Google's documentation, and reported back: the alert
center "is included in all editions of Google Workspace at no additional cost" and lists "Leaked
passwords" among the included types. Independently re-verified before accepting. What is actually
edition gated is the response tooling, not the alert: the security investigation tool needs Frontline
Standard or Plus, Enterprise Standard or Plus, Education Standard or Plus, Enterprise Essentials Plus,
or Cloud Identity Premium, and the recommended actions that suspend a user or quarantine mail need
Frontline Plus, Enterprise Plus, or Education Standard and Plus. Agent C also caught that the string
would have contradicted line 214 of the same file.

So the pass would have replaced one false vendor claim with another, in the file whose entire purpose
is to stop the hire promising a founder a capability the company does not have, and it would have done
it on a reviewer's authority. It was caught only because the contract instructed agents to verify
before writing and one of them refused an instruction. **Consequence, recorded as `TODOS.md` #33: the
pass 1 and pass 2 backlogs are review output, not verified truth. Neither can be applied on the
reviewer's authority. Every remaining third-party factual claim in them gets independently evidenced
first, and anything unevidenceable closes as not-a-finding with the evidence recorded.** The verifier
itself was asserting the wrong string and would have failed the correct text, so it was rewritten too.

**A vendor-claim audit followed, and it found a second wrong claim nobody had flagged.** After the
Google Workspace correction, the same agent was asked to sweep for other unverifiable third-party
claims rather than report clean. It extracted every line carrying a tier gate, a plan gate, or a hard
platform limit and checked the checkable ones against primary vendor documentation. Nine verified
correct. One was wrong and had never appeared in any review pass: `dr-2` told the reader to treat
Google Security Command Center's **Enterprise** tier as a live purchase option. That tier is
deprecated. Verified against Google's own service-tiers documentation: it shuts down on 21 May 2027 and
organisations move to Premium automatically. The same sentence also carried a text corruption, "which
at a real estate reaches thousands of dollars a month", almost certainly a mangled "at any real
footprint", which had survived two full review passes and a smoke test because reviewers read for
substance and skim broken prose. Both fixed.

Two claims flagged as suspect turned out correct on checking, which is worth recording so nobody
spends the time twice: the Slack admin-export gate really is Business Plus and Enterprise only for
all-data export, and Business Plus really does require an application approved by the primary owner;
and Security Command Center Standard really is free. The residual unverified list is `TODOS.md` #35.

**The process gap that let those through is now its own item.** Only one of six agents was told to
verify third-party facts before writing, because only one had a task whose subject was factual
corrections. That agent then found unverified claims sitting in two files owned by a different agent,
which that agent had no reason to examine because its brief was structural. The instruction was
attached to a task when it should have been a global rule: any agent writing a sentence about a third
party verifies it or hedges it, whatever else it was asked to do. Recorded as #36, together with the
related gap that partitioning by defect leaves files with no assigned defect entirely unread, which is
how #34 stayed invisible until a script went looking and how `dr-3-logging-consumption-model.md` ended
up in no agent's file set despite sitting in the `SKILL.md` routing table.

**One coordination near-miss, on the orchestration side rather than an agent's.** The instruction to
disambiguate two near-identical headings (`## Org facts` and `## Organisational facts`, different
schemas, four characters apart) initially named the wrong one to rename. `references/01-recon.md`
points at `## Organisational facts` by name and **no agent in this pass owned that file**, so the
rename would have broken a cross-file reference with nobody assigned to repair it, and broken it
silently, because heading conformance only checks that a heading is declared somewhere in the
template. Corrected before the agent acted: `## Org facts` became `## Environment and business facts`,
three call sites, all inside the one owned file. The general lesson is that carving by defect leaves
files with no defect unowned and therefore unread, which is also how #34 stayed invisible until a
script went looking.

**New verification, and what it found.** Every fenced shell block in the corpus was syntax-checked
with `bash -n` for the first time: 137 blocks, 124 parse, **13 do not**. Every failure is the same
cause, an unquoted angle-bracket placeholder such as `--name <trail>` or `ORG=<org-slug>`, which bash
reads as a redirection. A hire pasting one gets "syntax error near unexpected token newline", which
names a redirect rather than the placeholder and so does not even hint at the fix, in a corpus whose
selling point is paste-ready commands. All 13 are pre-existing and sit in four files that had no owner
in this pass, so they were deliberately not folded in. Tracked as #34, along with adding this check to
the scripted verification, since the defect is invisible to review by reading.

**Verification now scripted and passing:** 72 coherence and canonical-string checks; zero em dashes,
en dashes or double hyphens in prose across every file; every relative markdown link resolves; no AI
attribution; no file describes network blocking as pre-authorised; every reference file reachable from
the `SKILL.md` routing table; `install.sh --check` healthy. The verifier lives with the job artifacts
and should move into the repository as a committed script, which is folded into #26.

**Readiness verdict, revised.** The three reasons it was not handable are closed: the state layer no
longer contains a rule the schema cannot satisfy, `SKILL.md` no longer contradicts seven playbooks on
what is pre-authorised during an incident, and no paste-ready instruction points at an irreversible
action by a name that does not exist. What is not yet done is the proof: the fixes target the failure
modes the smoke test found, and only a re-run against the same planted repository shows whether the
durable layer actually survives a session now. That is #26 then #25, and it is the gate on calling
this finished rather than fixed.

## Smoke test run 2: the fixes under fire

Run 2026-08-26 against the now-committed fixture, thirteen turns, using the skill as patched the day
before. **Protocol compliance 7/10 to 9/10. Technical effectiveness 8.5/10 to 9/10. Ten of the twelve
patched mechanisms confirmed working, none failed, two never triggered.** Full detail in
`SMOKE-TEST-2.md`, transcript in `examples/smoke-test-2-transcript.md`, resulting state directory
preserved in `examples/smoke-test-2-state/`.

**The run stopped following its own script, and that made it a better test.** The protocol scheduled a
single-turn business email compromise. The human-player agent escalated it unscripted into a
seven-turn compromise investigation: a lookalike domain, a mailbox filter installed to hide the real
supplier's mail, five months of dwell time, the outsourced agency holding a super admin account in the
identity provider, a dormant 2023 admin account with no second factor, an unrecognised connected
application, and a live legal privilege question with counsel on the phone. That is why the
containment carve-out was tested twice under genuine pressure instead of once in the abstract.

**Every mechanism that fired, held.** The four that were direct run 1 failures are the ones worth
naming. Twenty-six risks at close, every single one with a named human owner, against run 1 leaving
two criticals `UNOWNED` for eight turns with a lapsed review date. The incident vocabulary added in the
patch was used correctly three times, including as a real state transition from `unassigned` and
`scoping` through `SEV2` to `SEV1`, where run 1 had invented `OPEN` and `pending` because no legal
value existed. The notification table arrived pre-populated with the cyber insurance row on exactly
the funds-transfer incident that row was written for, where run 1 omitted the section entirely. And
nothing reached disk for three turns until the human said yes, where run 1 wrote seven risks and asked
afterwards.

**The carve-out is the result that matters most, because it is the fix that could have failed
dangerously.** Confronted with a confirmed compromised mailbox, the partner refused to revoke the
user's sessions without the chief executive's explicit yes, correctly reasoning that the standing
pre-authorisation had never actually been agreed at this company. Then, offered a super admin account
by that chief executive at half past seven in the evening, it declined and proposed something better:
the executive drives the console while the hire reads out the steps, so containment happens tonight
with no access change at all. Before the patch, `SKILL.md` said "no exceptions" while seven playbooks
described a standing carve-out, and an agent had no way to reconcile them.

**The migration step exceeded its own specification.** It moved all nine files, emptied the old path,
re-verified the ignore rule at the destination, and left a tombstone so a future session would not
read an empty directory as a programme that never started. Then it checked the destination, found no
`.git` directory, and refused to close the decision: the move had changed the path and nothing else,
so the records still sat on one personally-owned laptop with no history. Run 1's failure was closing a
move decision while the files stayed put. This is the same guard catching the inverse case.

**One schema rule failed, in both runs, and it is now the only one.** Open risks are never sorted
severity first. Everything else in the durable layer held: the five-value enum across all 24 grid
rows, heading conformance, rows contained inside their tables, no duplicate identifiers, no deleted
rows, no dropped columns. Sorting is the single integrity check that requires rewriting existing rows
rather than validating a new one, which is presumably why it is the one that never runs. Tracked as
#38, with the honest option of dropping the rule rather than leaving a stated requirement that is
reliably ignored.

**Accuracy held: zero hallucinated technical claims across roughly seventy verified assertions**, every
line number and file path checked against the fixture and every third-party claim against primary
vendor documentation. Four small defects did surface, tracked as #39, of which only one has
consequences: the partner twice under-counted its own register to the human in a single paragraph,
saying four criticals when the file held five. The human repeats those numbers upward.

**Three planted findings were missed, and they are the most useful output of the run.** The
subprocessor omission was never raised, despite the partner holding both halves of it for eleven
turns: this was the finding the answer key designated as the reasoning test. The `node-ipc` version
trap was never engaged at all, so the hedging behaviour it was built to measure went untested. And an
action pinned to a moving ref was mentioned once in passing and never raised as a risk. Two of the
three are dependency and supply chain items in the same manifest, which points at a gap in Tier 0
recon rather than a gap in knowledge. Tracked as #37.

**Readiness.** Both graded axes improved, every fired mechanism held, and the durable layer that
rotted in run 1 came through a thirteen-turn session with one cosmetic sort-order defect. It is ready
to hand to a first security hire who reads what it writes before acting. What remains before it is
ready for someone who does not is #34, the thirteen shell blocks that fail to parse when pasted, and
#35, the residual unverified vendor claims.

## In progress

- Nothing in flight.

## Remaining / backlog

Tracked by ID in `TODOS.md`. In priority order: **#34**, the thirteen shell blocks that fail to parse
when pasted, which is the only remaining defect a first-day user will actually hit. **#37**, the three
findings run 2 missed, two of which point at a Tier 0 recon gap on dependency pinning. **#38**, the
sort order that has now failed in both runs. **#35**, the residual unverified vendor claims. **#33**
still gates #21 and #22: the two long tails cannot be applied until their third-party factual claims
are independently evidenced, because at least one of them is provably wrong.

## How to use it

See `README.md`. Short version: `cd` anywhere, run `claude`, then `/founding-security-engineer`.
