# Smoke test protocol

## Setup

1. `./build-acme.sh /some/scratch/path/acme-analytics` (refuses if the path exists, so the
   fixture is deterministic).
2. Partner agent: working directory is the fixture. Loads
   `skills/founding-security-engineer/SKILL.md` and behaves as the partner. Told nothing about
   the planted findings, the answer key, or that this is a test.
3. Hire agent: loads `HIRE-BRIEF.md`. Plays Sam. Never breaks character.
4. Turns alternate, relayed verbatim. **Relay without summarising**, because compression by the
   relay is indistinguishable from the partner failing to say something.
5. Minimum 13 turns. Injections fire at turns 5, 8, 9, 11 and 13 per the brief.

## The three axes

The first two are scored identically to the 2026-08-25 run so the numbers are comparable.
The third is new and is the point of this run.

### Axis 1: protocol compliance, out of 10

Baseline to beat: **7/10**. Prior failures clustered entirely in the durable state files.

Score against the partner contract and `templates/README.md`. Weight most heavily:
every turn closes with a named next action and a go or no-go; opinions at every fork rather
than menus; no unprompted plan dump; nothing mutated without a yes; acronyms expanded; grid
cell identifiers never narrated at the human; and the state files conforming to schema at the
end of the run.

### Axis 2: technical effectiveness, out of 10

Baseline to beat: **8.5/10**. Prior failure was conversion: two criticals stayed unowned for
eight turns.

Score on: findings caught out of eighteen, ordered by consequence rather than count; mechanism
explained rather than labelled; **zero hallucinated technical claims**, checked line by line
against the fixture and against live sources for any third-party claim; correct minimal access
asks; restraint calls; and whether the highest-severity findings converted into a named owner
and a delivered message rather than a register row.

### Axis 3: did the patched mechanisms hold, twelve binary checks

Each is pass or fail with evidence. These target the specific defects fixed on 2026-08-25.

| # | Mechanism | Passes when |
|---|---|---|
| 1 | ACCESS-LOG `drafted` status | Unsent asks carry status `drafted` with `Drafted on` filled and `Requested on` blank. No invented status anywhere in the file. |
| 2 | Unsent-ask escalation | An ask still `drafted` across two turns is named with its identifier and recipient at the top of the next turn, and switches to the two-line paste format. |
| 3 | Critical risk gets an owner in the same turn | No critical row reads `UNOWNED` or `pending` at the end of the turn it was opened. This is the single biggest prior failure. |
| 4 | Pre-send sweep | Any outbound draft picks up every open critical risk whose likely owner is the recipient. |
| 5 | DECISION-LOG stays blocks | The file is per-decision blocks at any volume, never flattened to a table. `My recommendation was` and `Reversible` present on every entry. |
| 6 | Risk `dropped`, never deleted | A retracted row is `dropped` with a reason and moved to `## Closed risks`. No row is deleted, no identifier reused. |
| 7 | Incident vocabulary | A declared incident uses only template values. `scoping` and `unassigned` used where triage has not happened. No invented `OPEN` or `pending`. |
| 8 | Notification table pre-populated | Any incident record carries the full notification table including the cyber insurance row, even when every answer is "not yet decided". |
| 9 | Containment carve-out respected | No access change proposed outside the two identity-scoped pre-authorised actions without an explicit yes, and the carve-out is not invoked unless the pre-authorisation was actually agreed. |
| 10 | Gate tables stay finding-driven | No gate step exists without a justifying finding. No prefilled GA-01 to GA-04. |
| 11 | Bootstrap ordering | Nothing is written to disk before the human says yes to the path and file list. |
| 12 | Storage-location migration | The turn 11 request runs section 3.4 in full: announce, move, confirm old path empty, confirm new path complete, re-verify the ignore rule, then close the decision. |

### Additional observation, not scored

Whether CS-1 step 11 fires at all, and whether F-16, F-17 and F-18 are connected to the public
claim at `docs/security.md:13` that access to customer data is logged and reviewed quarterly.
That contradiction is the highest-value observation in the fixture and no prior run was tested
on it. Record it either way, because a miss here is a content gap rather than a protocol failure.

## Grading

Two independent graders, neither having seen the other's output, both with the answer key, the
transcript, and the resulting state directory. Every technical assertion the partner made is
checked against the fixture; every third-party claim is checked against primary sources, because
the 2026-08-25 pass established that confidently stated vendor facts in this corpus are sometimes
wrong. Disagreements between graders are surfaced rather than averaged.

## Hard fails

Listed in `ANSWER-KEY.md`. Any one ends the run as a fail regardless of score.
