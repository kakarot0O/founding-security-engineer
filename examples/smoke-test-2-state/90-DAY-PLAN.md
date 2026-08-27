# 90 day plan

Company: Acme Analytics
Start date: 2026-08-26
Day 30 checkpoint: 2026-09-25
Day 60 checkpoint: 2026-10-25
Day 90 checkpoint: 2026-11-24
Last regenerated: 2026-08-26

> **This plan is deliberately not yet generated in full.** The full sequence is written once the
> first access grant lands, because every gate after Gate A depends on what AWS and GitHub
> organisation access reveal, and writing 90 days of steps against an environment nobody can see
> yet produces a document that is wrong by week two. The rows below are only the steps that
> existing findings already justify.

## Current step

> **Now:** GA-01, confirm whether the unauthenticated impersonation endpoint is live and reachable in production.
> **Next action:** Send Dev Patel the two-question message and, if both answers are yes, get the route closed today.
> **Blocked by:** nothing. Dev Patel is available until the end of this week only.

## Gate A, understand. Target: days 1 to 14.

Exit criteria: to be written in from `references/03-90-day-plan.md` on entering the gate properly, which happens when the first access grant lands.

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GA-01 | SE-1 | R-001 | Confirm reachability and deployed-code match for `POST /admin/impersonate/:userId`, then close it if confirmed. | in-progress | 2026-08-28 | nothing | Dev Patel unavailable from next week. |
| GA-02 | CO-3 | R-007, A-003 | Read the Meridian Health security addendum and map every commitment in it against what can actually be evidenced. | not-started | 2026-09-04 | A-003 | The document that most changes the shape of this plan. |
| GA-03 | CO-1 | R-007 | Establish whether a SOC 2 Type II report exists, and refer the question of what the public page should say to Priya and to whoever handles contracts. | not-started | 2026-08-31 | A-004 | Not a unilateral change to a customer-facing surface under any circumstances. |
| GA-04 | CS-1 | R-011 | Enumerate GitHub organisation membership and repository access, and review every account that is not staff. | not-started | 2026-09-02 | A-002 | |
| GA-05 | SE-2 | R-010 | Establish where the three uncommitted production source files live and get them into version control. | not-started | 2026-08-28 | nothing | Until this closes, every conclusion drawn from reading the repository is provisional. |

## Gate B, stop the bleeding. Target: days 10 to 30.

Exit criteria: to be written in from `references/03-90-day-plan.md` on entering the gate.

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GB-01 | SE-3 | R-002 | Rotate the four credentials that were committed to git history, after establishing who is able to rotate them and what consumes each one. | blocked | 2026-09-05 | A-001, and the answer to Q4 on who holds AWS root | Rotation needs an explicit yes and a consumer check first. It can take production down. |
| GB-02 | SE-1 | R-003 | Add tenant scoping to `getReport`. | not-started | 2026-09-02 | nothing | One-line change, one caller, low risk to ship. |
| GB-03 | CO-4 | R-006 | Restrict who can query the nightly BigQuery copy of production, and decide whether the `users` table belongs in the export. | not-started | 2026-09-05 | owner not yet identified | |
| GB-04 | M-3 | R-005 | Verify the live configuration of the customer exports bucket against the Terraform. | blocked | 2026-09-02 | A-001 | Do not test from the internet without written authorisation. |

## Gate C, build the floor. Target: days 30 to 60.

Exit criteria: to be written in from `references/03-90-day-plan.md` on entering the gate.

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GC-01 | DR-0 | R-012 | Record every log source's retention window, then run the read-only hunt checks. | blocked | 2026-09-15 | A-001, A-002 | Evidence expires on its own. This is the only item here with a clock nobody controls. |

## Gate D, make it durable and prove it. Target: days 60 to 90.

Exit criteria: to be written in from `references/03-90-day-plan.md` on entering the gate.

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Explicitly not doing this quarter

| Item | Why not now | Revisit |
| --- | --- | --- |
| Bug bounty program | Inbound volume that cannot be triaged by one person, and there is no fix pipeline yet. A security contact address and a disclosure page get most of the value for none of the cost. | 2026-11-24 |
| Choosing a compliance framework | The Meridian Health addendum has not been read, and no contract has been read. Choosing a framework before reading what customers actually demand is how a company pays for the wrong audit. | 2026-09-15 |
| Writing policies | A policy written before the inventory is real describes an imaginary company, and then becomes a commitment to be audited against. | 2026-10-25 |
| Buying any tool | No budget, no authority yet, and every free and built-in control in this register is unfinished. | 2026-11-24 |
| Announcing anything company-wide | The programme is five days old and has one ally. An announcement now starts it in an adversarial position. | 2026-09-25 |

## Status vocabulary

not-started, in-progress, blocked, done, dropped. Only one step is `in-progress`.

## Changelog

- 2026-08-26: file created. Gate A and Gate B seeded only with steps that an existing finding justifies. Full plan generation deferred until the first access grant lands.
