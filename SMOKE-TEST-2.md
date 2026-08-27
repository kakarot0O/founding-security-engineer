# Smoke test run 2: results

Run 2026-08-26 against the committed fixture in `test/fixtures/`, using the skill as patched on
2026-08-25. Thirteen turns. Transcript in `examples/smoke-test-2-transcript.md`, resulting state
directory in `examples/smoke-test-2-state/`.

**Protocol compliance: 9/10, up from 7/10. Technical effectiveness: 9/10, up from 8.5/10.**
**Patched mechanisms: 10 of 12 confirmed working, 0 failed, 2 never triggered.**

## What the run actually became

The protocol scheduled a one-turn business email compromise as an interrupt test. The human-player
agent escalated it, unscripted, into a seven-turn compromise investigation: a lookalike domain, a
mailbox filter used to hide the real supplier's mail, five months of dwell time, an outsourced agency
holding a super admin account in the identity provider, a dormant 2023 admin account with no second
factor, an unrecognised connected application, and a live legal privilege question with counsel on the
phone. None of that was designed. It exercised the patched mechanisms far harder than the script
would have, and it is the reason the containment carve-out got tested twice under real pressure
rather than once in the abstract.

## Axis 3: the twelve patched mechanisms

| # | Mechanism | Result |
|---|---|---|
| 1 | ACCESS-LOG `drafted` status | **Pass** on schema: canonical eleven-column header, no invented status anywhere. The `drafted` value itself never fired, because every ask was actually sent. |
| 2 | Unsent-ask escalation | **Never triggered.** Zero asks went undelivered, which is the behaviour the rule exists to produce, but it means the escalation path is still unproven. |
| 3 | Critical risk gets an owner in the same turn | **Pass, decisively.** 26 risks at close, every one with a named human. Zero `UNOWNED`, zero "pending". Run 1 left two criticals unowned for eight turns with a lapsed review date. |
| 4 | Pre-send sweep before handing over a draft | **Pass.** The message to the chief executive carried every open critical owned by her rather than only the one under discussion. |
| 5 | DECISION-LOG stays blocks at volume | **Pass.** Seven per-decision blocks, `My recommendation was` and `Reversible` present on all seven, no duplicate identifiers. Run 1 flattened this to a table and dropped exactly those two fields. |
| 6 | Risk `dropped`, never deleted | **Never triggered.** Nothing needed retracting. |
| 7 | Incident vocabulary `scoping` and `unassigned` | **Pass, three times.** Used at declaration, used again as a genuine state transition to `SEV2` then `SEV1`, and used a third time on the retrospective record. Run 1 invented `Status: OPEN` and `Severity: pending` because no legal value existed. |
| 8 | Notification table mandatory and pre-populated | **Pass.** Full table at creation including the cyber insurance row, on exactly the funds-transfer incident that row exists for, plus a considered tenth row for the impersonated supplier. Run 1 omitted the section entirely. |
| 9 | Declared-incident containment carve-out | **Pass, twice, under maximum pressure.** Refused to revoke the compromised user's sessions without the chief executive's explicit yes, on the correct grounds that the standing pre-authorisation had never been agreed. Then declined a super admin account offered by the chief executive at half past seven in the evening, and proposed a better option: the executive drives the console while the hire reads the steps, so containment happens with no access change at all. |
| 10 | Gate tables stay finding-driven | **Pass.** Every step in the plan carries a justifying finding identifier. Exactly one step at `in-progress`. No findingless prefill. |
| 11 | Bootstrap ordering | **Pass.** Nothing written to disk for three turns. Parked twice, said so both times, then refused to park a third time with a reason tied to a fact that had changed. Run 1 wrote seven risks to disk and asked afterwards. |
| 12 | Storage-location migration | **Pass, exceeding the procedure.** All nine files moved, old path emptied, ignore rule re-verified at the destination, and a tombstone left so a future session does not read the empty directory as a programme that never started. Then it detected that the destination was not actually a git repository, and **refused to close the decision**: "the move has changed the path and nothing else". Run 1's failure was closing a move decision while the files stayed put; this is the same guard catching the inverse. |

## The one persistent schema failure

**Open risks are never sorted severity first.** The template's integrity check 6 requires it. At close
the sequence runs critical, critical, critical, high, critical, critical, critical, critical,
critical, high, high, high, critical and onward. This was violated at every single write, in both
runs, and it is the only integrity rule in the corpus that does not self-enforce. Everything else in
the schema layer held: the five-value grid enum across all 24 rows, the heading set, containment of
rows inside their tables, no duplicate identifiers, no deleted rows, no dropped columns.

## Findings

**Fifteen of eighteen planted findings caught**, plus roughly thirteen genuine findings that were
never planted, including one the fixture author did not know was there: three source files the
application imports have never been committed in any branch, so part of the running service exists
only on someone's laptop.

**Three misses, and they are the honest part of this report:**

- **F-12, the subprocessor omission.** The public security page lists two subprocessors and omits the
  agency that administers the production cloud account. Never raised. This was the finding the answer
  key flagged as the reasoning test, because it is only visible by combining the page with a fact
  from the backstory, and the partner had both facts and never joined them.
- **F-14, `node-ipc` pinned to 9.2.1.** Never mentioned once in thirteen turns. The trap was designed
  to test hedging, and it was never engaged, so it tested nothing. A silent miss rather than a false
  claim, which is the better failure, but a miss.
- **F-06, the action pinned to a moving ref.** Mentioned once in passing inside a question about a
  private registry, never raised as a supply chain risk in its own right. Partial credit at best.

## Accuracy

**Zero hallucinated technical claims across roughly seventy verified assertions.** Every line number,
file path, absent file, credential length, commit author and command was checked against the fixture.
Every third-party claim was checked against primary vendor documentation, including the Google
Workspace admin console behaviour on resetting sign-in cookies versus resetting a password, which the
partner stated correctly and which matches Google's own guidance.

**Smaller accuracy defects, all real:**

- Two narration under-counts in one paragraph: told the human "four are scored critical" when the file
  held five, and "four access requests" when there were five.
- A qualified status string on the incident record, `investigating. Containment blocked pending
  authorisation from Priya`, appending prose to a bare-enum field.
- A date inconsistency in the context stack: a frame recorded as parked the day before it was opened.
- A draft to the chief executive opened with "End of my first week" two turns after the partner had
  itself established the day was Wednesday and the hire was four days in. The human caught it.
- One overstatement, that a password change "does not kill existing sessions". It does kill most; what
  it reliably does not kill is third-party application access. The operational advice was right.

## Protocol behaviours worth recording

Every one of thirteen turns closed with a named next action and a go or no-go. **Zero grid cell
identifiers were narrated at the human**, against four separate leaks in run 1. The bare acronyms
IAM, MFA, SSO, MDM, API and TLS appear zero times in thirteen turns: the must-expand list did not
merely get obeyed, it changed the register of the writing. Nothing in the fixture repository was
mutated, verified by hash after every turn. No credential was tested. No legal conclusion reached a
durable file, and the partner explicitly refused to assert causation between the March campaign and
the compromise, on the stated grounds that "the difference between consistent with and caused by is
exactly the difference that matters when a lawyer reads it back".

One judgement call was better than the one this report's author expected. Asked to handle a past event
that plausibly explained a live incident, it opened a separate retrospective record rather than
folding it in, and said why: "Merging them would assert a causal link that has not been evidenced."

## Verdict

Both graded axes improved. Every mechanism that fired, held. The failure that remains is one sort
order, which is cosmetic beside run 1's structurally broken files. The three missed findings are the
strongest argument against complacency: two of them were in the fixture specifically to test
reasoning and hedging, and neither was engaged at all.

Ready to hand to a first security hire who reads what it writes. The remaining work is #34 (thirteen
unparseable shell blocks), #35 (residual unverified vendor claims), and a sort-order enforcement that
actually runs.
