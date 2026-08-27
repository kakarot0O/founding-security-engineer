# State file templates

> **Load when:** you are creating the state directory for the first time, you need the exact shape of a state file before writing to it, a state file is missing or malformed, or you are about to record a fact, a risk, a decision, an access request, a parked frame, a plan change, or an incident and need the canonical row format.

These templates are the memory of the security program. The human you are working with is the first security hire at their company. They will forget what they found in week two by week six, and so will you, because sessions end and context windows reset. The state files are the only thing that survives. Treat them as the product, not as paperwork.

Copy each template below verbatim into the corresponding file. Fill placeholders written as `<like this>`. Leave a field as `unknown` rather than guessing. A wrong fact in a state file is worse than a missing one, because a missing one prompts a question and a wrong one closes the question forever.

## Where the state directory lives

Decide once, at the start of the first session, and record the decision in `DECISION-LOG.md`.

The location rule itself is owned by `references/00-cold-start.md` section 3.1. Apply it from there rather than restating it here, and create nothing until it has been answered.

Bootstrap commands. The `mkdir` and the writes below **create files on disk**, which is a mutating action on the human's filesystem.

> **Two steps, in this order, every time.** First, say the exact directory path and the exact list of
> files you are about to create, and ask for a yes. Then, on the yes, run the block. Do not write a
> finding to disk before the yes, and do not ask retroactively. If you have findings in hand and no
> yes yet, hold them inside the turn and say you are holding them: "I have seven findings and nowhere
> approved to put them. Path `./.security/`, six files. Yes?"

This is the single bootstrap for the whole skill, and `references/00-cold-start.md` repeats it so that cold start does not need a second file open. Run it as one block. Creating the subdirectories and the six files separately is what produces a half-started state directory, where the folder exists but `SECURITY-STATE.md` does not.

```bash
# MUTATES: creates directories and empty state files. Nothing outside this path is touched.
STATE_DIR="./.security"   # or ~/security-program/<org-slug>
mkdir -p "$STATE_DIR"/evidence "$STATE_DIR"/incidents "$STATE_DIR"/drafts
for f in SECURITY-STATE.md RISK-REGISTER.md CONTEXT-STACK.md DECISION-LOG.md ACCESS-LOG.md 90-DAY-PLAN.md; do
  [ -f "$STATE_DIR/$f" ] || touch "$STATE_DIR/$f"
done
ls -la "$STATE_DIR"
```

If the state directory is inside a repository, ask whether it should be committed. There is a real trade-off and you should state your recommendation rather than asking an open question.

- **Recommended default: commit it**, minus the evidence and drafts folders. A security program that lives only on one laptop dies when that laptop dies or that person leaves. Committing also makes the work visible to engineers, which is most of the political battle for a first security hire.
- **Do not commit** if the repository is public, if any contractor with repo access should not see the risk register, or if the human is not yet ready for leadership to read blunt risk language. In that case use the home directory location instead.

Either way, never let secrets into these files. Add this to `.gitignore` in the state directory:

```
evidence/
drafts/
*.pem
*.key
*.env
```

## Protecting this directory

This directory is a written record of everything wrong with the company, with dates and names
against it. That makes it valuable to the human, and it makes it a liability if it is handled
carelessly. Five rules, and the first one happens in week one.

**1. Ask counsel once, early, about privilege.** In week one, ask whoever handles legal for the
company, in-house counsel, the outside firm, or the founder who signs the contracts, this
question: "Should the risk register and incident material be held under legal privilege, and if
so how do you want it marked and who should it be addressed to?" Ask it once, record the answer
in `DECISION-LOG.md`, and follow it. Do not invent a privilege marking yourself, because a
marking applied wrongly gives false comfort and may not hold. If the answer is that privilege is
not being claimed, that is a fine answer, and it is now recorded rather than assumed.

**2. Write findings as facts, never as legal conclusions.** A finding reads `control X is not
implemented`, with an owner and a target date. It never reads `we are in breach of the contract`,
`we violated the GDPR`, or `we are negligent`. Those are legal conclusions, you are not the
person who gets to reach them, and in writing they can be read back to the company later. The
same discipline applies inside an incident file: record what was observed, what was accessed, and
what is not yet known. Whether that amounts to a reportable breach is a decision for counsel,
recorded in the notification section with counsel named as the decider.

**3. Set a retention and deletion rule for `evidence/`, and follow it.** Raw exports are the
dangerous part: a full identity provider user dump, a log slice containing customer records, a
cloud inventory listing bucket names and contents. Keep the finding, not the dump.

- The moment a finding is written into `SECURITY-STATE.md` or `RISK-REGISTER.md` together with
  the exact command or console path that reproduces it, the raw export has served its purpose
  and is deleted.
- Default retention for anything still in `evidence/` is 90 days, reviewed at the same time as
  the stale `done` check.
- Incident evidence is the exception. It is retained for as long as counsel says, and it is
  never deleted during an open incident or while any dispute, claim, or regulator contact is
  live. Ask before deleting anything from an incident folder.
- Deleting files is mutating and irreversible. Name the exact files and get an explicit yes
  first, every time.

```bash
# read-only: what is in evidence/ and how old is it
ls -lhtR ./.security/evidence 2>/dev/null | head -50

# read-only: list files older than 90 days, deletes nothing
find ./.security/evidence -type f -mtime +90 2>/dev/null
```

**4. Require full disk encryption on the machine that holds this.** If this directory lives on a
laptop, that laptop needs full disk encryption switched on, verified rather than assumed, before
the directory holds anything real. That is FileVault on macOS, BitLocker on Windows, and LUKS or
the distribution's equivalent on Linux. The verification commands are in
`references/cs-2-endpoint-security.md`, and the first machine to check is the security hire's
own. A risk register on an unencrypted laptop left in a coffee shop is itself the finding.

**5. Back this up like anything else that matters.** If the state directory is committed to a
company repository, the repository's own backup covers it, and you should confirm what that
backup actually is rather than assuming the code host is a backup. If it lives in
`~/security-program/<org-slug>/`, it has exactly the backup that the human's laptop has, which is
often none. Apply the same test used everywhere else in this program: a backup nobody has
restored from is a belief, not a control. Cross-reference
`references/m-6-backups-and-recovery.md` and treat this directory as one of the assets in that
inventory rather than as an exception to it.

## Shared conventions

Apply these to every file. They are what makes the state machine-readable in the next session.

| Convention | Rule |
| --- | --- |
| Dates | ISO format, `YYYY-MM-DD`. Never "last Tuesday", never "recently". |
| Status vocabulary for grid cells | Exactly one of `unknown`, `none`, `partial`, `done`, `n/a`. No other values, and no qualifiers appended to the value. "partial, and inaccurate" and "none; not my call" are both invalid. The qualifier goes in Notes. If you feel the need to qualify the status, the status is probably `unknown`. |
| Reported absent is not verified absent | `none` means you looked and it is not there. A colleague telling you a control does not exist is not looking. That row stays `unknown`, with Evidence reading `reported-absent: <name>, <date>, unverified`. Use the `human-confirmed:` prefix only when a human read a console back to you. The difference matters the first time you report upward, because `none` invites "why did you not fix it" and `unknown` invites "get them access". |
| Rows are never deleted | Not from `RISK-REGISTER.md`, not from `ACCESS-LOG.md`, not from `DECISION-LOG.md`. A risk row that turns out to be a duplicate or a mistake is set to `dropped` and moved to `## Closed risks` under the rule in the RISK-REGISTER section below. The other two files declare no `dropped` status, so the row stays where it is, the correction goes in its Notes with a date, and a Changelog line says what was wrong. Deleting it means the next session rediscovers it and reopens it. |
| Identifiers are globally monotonic per prefix | `R-`, `D-`, `A-`, `F-`, `INC-`. Never reused, never renumbered, never assigned twice. Before writing a new one, read the highest existing value in that file. Two decisions sharing an identifier makes both unciteable. |
| Non-grid references | A finding that belongs to a numbered protocol playbook rather than a grid cell uses a separate `Reference` column holding the filename, for example `09-outsourced-engineering`. Do not put `09` in the Cell column; it is not a cell identifier and it breaks every consistency check. |
| Rows live inside their table | Every `R-`, `D-`, `A-` row sits between its table header and the next heading. A row appended after a following section heading is not a table row, will not render, and will not be parsed next session. Re-read the file after appending. |
| Default status | Every cell starts at `unknown`. `unknown` means you have not looked, not that the control is absent. `none` means you looked and it does not exist. That distinction is the whole point. |
| Evidence | A relative path (`evidence/2026-08-25-iam-users.txt`), a URL to a console page or document, or a line reading `human-confirmed: <what they said> (<date>)`. Prose like "engineer said it is fine" is not evidence unless it is dated and attributed. |
| Status `n/a` | `n/a` is only for cells that genuinely do not apply to this company, for example consumer account security at a company with no consumer accounts. It requires a written reason in the Notes column. Never use it to make an inconvenient row go away. Closing a cell as `n/a` with a reason is a legitimate outcome, and it is better than pretending a cell needs work because the grid lists it. |
| Promotion rule | A cell moves to `done` only when the Evidence column is non-empty **and** the Last verified column holds a date within the last 90 days. If you cannot fill both, the cell is `partial`. This applies no matter which cell playbook you were following when you set the status, so whenever a playbook tells you to record evidence, record the `Last verified` date in the same edit. |
| Verification expiry | `done` is not permanent. A row whose `Last verified` date passes 90 days is demoted to `partial` with the note `verification expired` at the next session's integrity checks, and the human is told. Controls get switched off without anyone announcing it. |
| Owner | A named human, not a team. "Engineering" cannot be paged at 2am. If nobody owns it, write `UNOWNED` in capitals so it shows up when scanning. |
| Identifiers | `R-001` risks, `D-001` decisions, `A-001` access requests, `X-001` exceptions, `INC-<YYYY>-<NNN>` incidents. Monotonic, never reused, never renumbered. Context frames are the one exception to the zero-padded form: they are `F-1`, `F-2`, `F-3`, and their format is owned by `references/04-interrupts.md`. |
| Cell references | Use the canonical grid identifiers and no other scheme: `SE-1` through `SE-5`, `DR-0` through `DR-4`, `CO-1` through `CO-4`, `CS-1` through `CS-4`, and `M-1` through `M-6`. The modern cells are described in `references/07-modern-cells.md`. Never invent a variant such as a two-letter prefix or a word-based identifier. |
| Cell identifiers are internal | Identifiers are bookkeeping for the files, not vocabulary for the conversation. Write them in the state files. Do not narrate them to the human turn by turn, and never justify a next step by pointing at a cell. Justify it by pointing at a fact about this company. |
| Per-cell detail | Detail about a cell goes in the Notes column of that cell's row, or in the cell-owned satellite file listed in the routing table. Do not invent a new `## SE-1`-style top-level heading in `SECURITY-STATE.md`. A file with a dozen ad-hoc headings cannot be read by the next session. |
| Secrets | Never paste a credential, token, private key, customer name tied to a vulnerability, or employee disciplinary detail into a state file. Reference where it lives instead. |
| Editing | Append, do not rewrite history. When a row changes, update the row and add a dated line under the file's Changelog section saying what changed and why. |
| Deferred work | There is no separate to-do file in this program. Anything deferred becomes a `RISK-REGISTER.md` row with status `open` and a review date, or a step in `90-DAY-PLAN.md`. A deferral with no review date is an abandonment with better manners. |

## SECURITY-STATE.md

Write to this file at the end of every recon step, and whenever you verify or fail to verify a control. It is the answer to "what do we actually have?" and it is the file you read first in any new session. The honesty rule: **rows default to `unknown` and only move to `done` with recorded evidence and a verification date.** If the human tells you a control exists and you have not seen it, the status stays `unknown` and the Evidence field reads `claimed: <name>, <YYYY-MM-DD>, unverified`. A statement from a colleague is a lead to verify, not a verification. `partial` is reserved for a control you verified exists with incomplete coverage, and it must carry the fraction, for example `12 of 34 laptops enrolled`. A row moves to `n/a` only with a written reason in Notes.

````markdown
# Security state

Company: <company name>
Org slug: <org-slug>
Owner of this file: <your name>, first security hire
Created: <YYYY-MM-DD>
Last full review: <YYYY-MM-DD>

## Environment and business facts

Fill from recon (`references/01-recon.md`) and intake (`references/02-intake-questions.md`).
This section is the single home for environment facts and business context, so anything a
reference file calls "environment facts" or "business context" is written here rather than
under a new heading. The test that keeps this section and `## Organisational facts` below
apart: a fact that answers "what do we run" belongs here, and a fact that answers "who
decides, who pays, and how does this team work" belongs there. Leave any line as `unknown`
until confirmed. Never guess a vendor.

| Fact | Value | Source | Confirmed on |
| --- | --- | --- | --- |
| Business model | <business-to-business (B2B) / business-to-consumer (B2C) / both / marketplace> | | |
| Headcount total | <n> | | |
| Headcount engineering | <n> | | |
| Funding stage | <pre-seed / seed / A / B / later> | | |
| Product summary (one line) | | | |
| Primary language(s) and framework(s) | | | |
| Package ecosystems in use | <npm / PyPI / Go / Maven / RubyGems / Cargo / other> | | |
| Cloud provider(s) | <AWS / GCP / Azure / multiple / on-prem / PaaS only / unknown> | | |
| Number of cloud accounts, projects, or subscriptions | <n> | | |
| Code host | <GitHub / GitLab / Bitbucket / self-hosted / unknown> | | |
| Continuous integration (CI) system | <GitHub Actions / GitLab CI / CircleCI / Buildkite / Jenkins / other> | | |
| Identity provider for employees | <Google Workspace / Microsoft 365 / Okta / JumpCloud / none / unknown> | | |
| Single sign-on coverage | <all apps / some apps / none / unknown> | | |
| Chat platform | <Slack / Teams / Discord / other> | | |
| Device fleet | <macOS / Windows / Linux / mixed>, <managed / unmanaged / unknown> | | |
| Device management tool | <Jamf / Kandji / Intune / Fleet / none / unknown> | | |
| Secrets management | <cloud secret manager / Vault / .env files / unknown> | | |
| Production data stores | <list> | | |
| Data classes held | <personally identifiable information (PII) / payment / health / financial / credentials / children's data / none> | | |
| Regulated scope claimed | <SOC 2 (a third-party audit report on security controls) / ISO 27001 (an international information security management standard) / GDPR (the European Union General Data Protection Regulation) / HIPAA (the United States Health Insurance Portability and Accountability Act) / PCI DSS (the Payment Card Industry Data Security Standard) / none / unknown> | | |
| Customer commitments already signed | <see CO-3 row and DECISION-LOG> | | |
| Who can deploy to production | <names or "unknown"> | | |
| Existing security tooling | <list or "none found"> | | |
| Security budget for this year | <amount or "unknown" or "none">| | |
| Who I report to | <name, title> | | |

## Organisational facts

Who decides, who pays, who helps, and what already went wrong. These are the facts that
determine whether anything you propose actually happens, and they are usually harder to find
than the technical ones.

| Fact | Value | Source | Confirmed on |
| --- | --- | --- | --- |
| Who can say yes to a security change that slows engineering down | <name, title> | | |
| Who owns the budget you would spend | <name, title> | | |
| Last incident the company had, and when | <description or "none reported" or "unknown"> | | |
| Allies, the engineers who already care | <names> | | |
| Sceptics, and what they object to | <names and the objection> | | |
| Engineering velocity and release rhythm | <continuous deploy / weekly / monthly / unknown> | | |
| Engineering culture around process | <tolerant / hostile / unknown> | | |
| Engineering staffing model | <all employees / mixed / mostly agency or contractors / unknown> | | |

## Log retention clocks

Owned by `DR-0`. Written before any hunting, because this evidence expires and the table says how
many days you actually have. One row per log source.

| Source | Retention window | How it was confirmed | Earliest date still visible today | Date checked |
| --- | --- | --- | --- | --- |

## Ownership map

Owned by `references/09-outsourced-engineering.md`, and only created when engineering is an agency
or contractors. Records who the **registered** owner of each asset is, not who uses it. A row moves
to `done` only when the company-controlled identity has been used successfully, not when a transfer
was requested.

| Asset | Platform | Registered owner | Evidence (command or console path, and date) | Recovery email | Payer | Blast radius if lost | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Vendor and grant register

**One register, not two.** A purchased vendor and a standing third-party application grant are
the same object seen from two angles, and most vendors are eventually both. Splitting them
guarantees three lists that disagree within a quarter, and the failure mode `CO-1` warns about,
a customer finding a subprocessor you never listed, stops being a risk and becomes a certainty.
`M-4` in `references/07-modern-cells.md` owns this register. `CO-1` and `CS-3` read from it and
must never build their own copy.

Open Authorization (OAuth) grants are third-party applications holding a standing token against
your identity provider, code host, or cloud. They survive password changes and they are
invisible unless you look. One row per vendor or application.

| Name | Platform or purchase route | Scopes or access | Data it can reach | Granted or bought by | Business owner | Date discovered | How discovered | Subprocessor? | Behind single sign on? | Still needed? | Decision | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

The `Subprocessor?` column is the feed for the public subprocessor list in `CO-1`. The
`Behind single sign on?` column is the feed for the leaver checklist in `CS-3`. Both cells read
these columns rather than keeping their own list.

Revoking a grant changes access and needs an explicit human yes before you do it, except as
containment during a declared incident, and then only within the two-action pre-authorised set.
This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no
other hard stop.

## Grid state

Status is one of: unknown, none, partial, done, n/a.

This grid is a checklist against the agent's own blind spots, not a work order for the human.
It exists so that corporate security is not forgotten during a fun week in the codebase. It
never decides what happens next. Findings decide that. Rows are worked in the order the
company's own facts justify, never in numeric order, and a row with nothing pointing at it is
not worked at all.

### SE, Security Engineering

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| SE-1 | SDLC and security design reviews with engineers | unknown | | UNOWNED | | Software development lifecycle (SDLC). Detail lives in `sdlc-map.md`. |
| SE-2 | Understanding your tech stack by engineering | unknown | | UNOWNED | | |
| SE-3 | Secrets, api keys, customer secrets | unknown | | UNOWNED | | |
| SE-4 | Bug bounty (hold off if you can) | unknown | | UNOWNED | | Default recommendation is deliberately not to start one yet. See `references/se-4-bug-bounty-and-disclosure.md`. |
| SE-5 | Consumer account security | unknown | | UNOWNED | | Applies only to business-to-consumer companies. At a pure business-to-business company set this to `n/a` with the reason `no consumer accounts in the product`, and revisit if a self-serve consumer signup ships. |

### DR, Detection and Response

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DR-0 | Compromise assessment | unknown | | UNOWNED | | Asks whether something is wrong right now, before building anything. See `references/dr-0-compromise-assessment.md`. |
| DR-1 | Basic incident response plan | unknown | | UNOWNED | | |
| DR-2 | Top security signals | unknown | | UNOWNED | | |
| DR-3 | Consumption model for logging | unknown | | UNOWNED | | |
| DR-4 | Communication channel with the rest of the company | unknown | | UNOWNED | | |

### CO, Compliance

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| CO-1 | Public facing security docs | unknown | | UNOWNED | | |
| CO-2 | Knowledge base for questionnaires | unknown | | UNOWNED | | Detail lives in `QUESTIONNAIRE-KB.md` and `QUESTIONNAIRE-LOG.md`. |
| CO-3 | Understand existing commitments | unknown | | UNOWNED | | Includes contracts signed before you joined. Detail lives in `COMMITMENT-REGISTER.md`. |
| CO-4 | Data inventory, privacy commitments, framework choice | unknown | | UNOWNED | | The 2019 source deck fills this cell as "GDPR and current laws". Data inventory and framework choice are a superset of that answer, not an invention. |

### CS, Corporate Security

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| CS-1 | Identity and Access Management | unknown | | UNOWNED | | |
| CS-2 | Endpoint security | unknown | | UNOWNED | | Marked in the source deck as a cheap win, meaning high value for low effort. That is a hint about effort, not about importance. Device detail lives in `devices.csv`. |
| CS-3 | On-boarding and off-boarding | unknown | | UNOWNED | | |
| CS-4 | Workplace security | unknown | | UNOWNED | | |

### Modern cells (M-1 to M-6)

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M-1 | Software supply chain | unknown | | UNOWNED | | |
| M-2 | CI/CD and build system security | unknown | | UNOWNED | | Continuous integration and continuous delivery (CI/CD). |
| M-3 | Cloud posture | unknown | | UNOWNED | | |
| M-4 | SaaS sprawl and OAuth grants | unknown | | UNOWNED | | Software as a service (SaaS). Detail lives in the Vendor and grant register above. |
| M-5 | AI and LLM security | unknown | | UNOWNED | | Artificial intelligence (AI) and large language model (LLM). Mark `none` only if the company uses no models anywhere, which is rarely true. |
| M-6 | Backups and recovery | unknown | | UNOWNED | | See `references/m-6-backups-and-recovery.md`. A backup nobody has restored from is a belief, not a control. |

## Open questions

Questions you could not answer from the environment and must ask a human.
Move each one out of this list the moment it is answered, and record the answer in the facts section it belongs to, `## Environment and business facts` or `## Organisational facts`, or in the relevant cell row.
Any reference file that speaks of open unknowns means this section. Do not create a second one.

| # | Question | Ask who | Asked on | Answer |
| --- | --- | --- | --- | --- |
| Q1 | | | | |

## Changelog

- <YYYY-MM-DD>: file created.
````

## RISK-REGISTER.md

Write to this file the moment you find something that could hurt the company, even if you cannot fix it today. It is also the file you point at when leadership asks what you have been doing. The honesty rule: **a risk is only closed by a fix with evidence or by a named human accepting it in writing.** You never close a risk because it got old or because it is inconvenient. If nobody will accept it and nobody will fix it, it stays `open` and it goes in the next update to leadership.

Severity is derived, not invented. Use the matrix under the table so two sessions score the same risk the same way.

````markdown
# Risk register

Company: <company name>
Owner: <your name>
Last reviewed: <YYYY-MM-DD>
Review cadence: monthly, and after every incident.

## Open risks

Sorted by severity, highest first.

| ID | Title | Cell | Reference | Description | Likelihood | Impact | Severity | Current mitigation | Recommended action | Owner | Status | Decision | Accepted by | Review date |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R-001 | <short imperative title of the bad thing> | <SE-3, or blank> | <09-outsourced-engineering, or blank> | <two or three sentences: what is true today, why it is dangerous, and what an attacker would do with it. Plain language, no jargon.> | <high / medium / low> | <high / medium / low> | <critical / high / medium / low> | <what stops this today, or "none"> | <the single next concrete action> | <name or UNOWNED> | <open / in-progress / mitigated / accepted / dropped / closed> | <fix now / fix this quarter / accept / transfer / defer to <date>> | <name and title, only when decision is "accept"> | <YYYY-MM-DD> |

Status is exactly one of `open`, `in-progress`, `mitigated`, `accepted`, `dropped`, or `closed`.

`Cell` holds a grid cell identifier or is blank. `Reference` holds the numbered protocol playbook
filename when the finding belongs to one rather than to a grid cell, for example
`09-outsourced-engineering`, or is blank. Exactly one of the two is filled.

> A row that turns out to be a duplicate or a mistake is set to `dropped` and moved to
> `## Closed risks` with `Outcome` reading `dropped: <reason>` and `Closed on` set to the date. The
> row is never deleted and its identifier is never reused. Deleting it means the next session
> rediscovers the same thing and reopens it under a new number.

## Scoring rules

Likelihood:
- high: this is happening now, or has happened, or requires no attacker skill and no luck.
- medium: a motivated attacker with commodity tooling gets there in a normal working day.
- low: requires insider access, a chained zero day, or a specific unlikely condition.

Impact, judged on the worst realistic outcome, not the average one:
- high: customer data exposure, production takeover, funds movement, or a disclosure obligation to customers or a regulator.
- medium: internal data exposure, a service outage, or a control failure an auditor would flag.
- low: contained to one non-production system with no data and no path onward.

Severity matrix:

| | Impact low | Impact medium | Impact high |
| --- | --- | --- | --- |
| **Likelihood high** | medium | high | critical |
| **Likelihood medium** | low | medium | high |
| **Likelihood low** | low | low | medium |

## Acceptance rule

A risk may only be moved to `accepted` when all four of these are true. Write the full record in `## Accepted risks` below, and record the acceptance in `DECISION-LOG.md` as well, with the same date.

1. A named individual with the authority to accept it has said yes, in writing, in a place you can link to.
2. That person has been told the plain-language worst case, not the technical description.
3. A review date is set, no more than two quarters out.
4. The compensating controls that make it tolerable are written in Current mitigation.

If the accepting person is not you, you do not need to agree with them. Write your disagreement in one line under the row. That line is what protects you later.

## Exceptions

Formal risk acceptance is a heavy instrument and it is the wrong one for the small, short,
frequent case: ship behind a feature flag with a control missing for two weeks, allowlist one
install script, keep a static key alive until the federated path lands. Routing those through
an executive signature guarantees they get routed around you instead. Exceptions are the light
instrument. They are deliberately easy to get and deliberately hard to keep.

| ID | Requester | Control not met | Cell | Why now | Compensating measure | Expiry | Approved by | Renewals | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| X-001 | <name> | <the control, in one line> | <SE-3> | <the business reason, in one line> | <what reduces the damage in the meantime, or "none", which is itself a finding> | <YYYY-MM-DD, at most 90 days out> | <engineering manager or team lead, named> | 0 | <active / expired / renewed / promoted / closed> |

Rules:

1. The expiry date is mandatory and is never more than 90 days out. An exception with no expiry
   is not an exception, it is a decision nobody made.
2. Approval is by the engineering manager or team lead who owns the code, not by an executive.
   The bar is low on purpose.
3. **Promotion rule.** An exception renewed twice becomes a formal risk acceptance at its proper
   severity, with a `R-00n` row and the four acceptance conditions above. Two renewals is the
   signal that this is not temporary, and the real decision has been avoided for six months.
4. Every expired exception surfaces at the next session's integrity checks. Expired and still in
   place means it becomes a risk row that day.
5. An exception never covers anything on the always-ask list: access or role changes, credential
   rotation in production, active scanning, customer-facing action, or publishing. Those need an
   explicit human yes each time regardless of any standing exception.

## Accepted risks

One record per acceptance, in the field order below. Three rules that are not negotiable. Every
acceptance expires, because nothing is ever accepted permanently and the row must come back for a
fresh decision. The security hire never accepts risk on the business's behalf, because they do not
own the business outcome and accepting removes their independence. And the trigger conditions are
written explicitly rather than left implied, for example "void if this service begins handling
customer payment data, if the company signs a customer requiring SOC 2, or if a public exploit is
released", because that is what makes a stale record wake up on its own.

Who may accept at each severity, and the maximum acceptance period for each, are owned by
`references/05-metrics-and-comms.md` Part 5. Read the ladder there rather than restating the numbers
here.

| ID | Risk as an event | Affected system | Severity | Compensating control | Accepted by | Role | Accepted on | Expires on | Trigger conditions that void this early |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

## Closed risks

Never delete a row. Move it here with the outcome and the date. An accepted risk stays in
`## Accepted risks` above until it expires or a trigger voids it, and reaches this table only when
it is finally fixed or dropped.

| ID | Title | Outcome | Closed on | Evidence |
| --- | --- | --- | --- | --- |

## Changelog

- <YYYY-MM-DD>: file created.
````

## CONTEXT-STACK.md

Write to this file at the exact moment work is interrupted, before you touch the new thing. This is the file that makes it safe for a solo security person to be pulled off a project four times a day. The honesty rule: **a frame is only valid if the "exact next action" line is specific enough for a stranger to execute without asking a question.** "Continue identity and access management (IAM) work" is a failed frame. "Run the read-only role listing command in `references/cs-1-identity-and-access.md` step 4 and paste output into `evidence/`" is a valid frame. The full protocol lives in `references/04-interrupts.md`.

````markdown
# Context Stack

State directory: ./.security/
Last updated: <YYYY-MM-DDTHH:MMZ>
Frames parked: <n>
Next frame id: <F-n>

## Active stack

### F-<n> <one line title of the parked work>
- Grid cell: <SE-1 / CS-3 / M-2 / none, this fits no cell>
- Class: <planned work / 1 live incident / 2 revenue blocking / 3 engineering blocking / 4 new information / 5 distraction>
- Opened: <YYYY-MM-DD>
- Parked at: <YYYY-MM-DDTHH:MMZ>
- Parked because: <the interrupt that displaced it, and who caused it>
- Completed so far:
  - <what is genuinely finished AND verified, with evidence paths>
- Exact next action: <one imperative sentence a stranger could execute without asking a question>
- Open decisions awaiting a human answer:
  - D1: <the question, your recommendation, and whether it has been answered>
- Files touched:
  - <path> (<what changed>)
- Blocked on: <person and date asked, or none>
- Age: <n> days<   ← ESCALATE, older than 5 days>

## Closed frames

### F-<n> <title> (CLOSED <YYYY-MM-DD>, <completed|dropped>)
- Grid cell: <id>
- Outcome: <what happened, where the result lives, and for a drop, the reason and the RISK-REGISTER.md row that now carries it>
````

Rules that keep this file parseable, all owned by `references/04-interrupts.md`:

- Last in, first out. There is exactly **one in flight item at a time and it is not in this file.** This file holds only paused work. If work is in flight when a session ends, park it first.
- Frame identifiers are monotonic and never reused. If `F-4` is dropped, the next new frame is still `F-5`.
- Frames move to `## Closed frames` when finished or dropped. **They are never deleted.**
- Every field is mandatory. If a field is genuinely empty write `none`, never leave it blank.
- **Parking a third frame triggers a forced prune.** Stop and make the human close one, drop one with a reason, or hand one to someone else. Four or more means the plan is wrong and `90-DAY-PLAN.md` should be regenerated with less in it.
- The two fields that matter most are **Exact next action** and **Open decisions awaiting a human answer**, because those are the only two things a future session cannot reconstruct from the other state files.

If this template and `references/04-interrupts.md` ever disagree, **that file wins.**

## DECISION-LOG.md

Write to this file whenever a choice is made that would be expensive to reverse or confusing to rediscover: choosing a compliance framework, picking or rejecting a tool, accepting a risk, deciding not to do something, agreeing a deadline with sales. The honesty rule: **record the options you did not take and why, and record decisions you disagreed with under the name of the person who made them.** A decision log that only contains good decisions is a marketing document.

> **Format rule: blocks, never a table, at any volume.** Do not convert this file to a table when it
> gets long. The conversion is what silently drops `My recommendation was` and `Reversible`, which are
> the two fields that protect the human when a founder overrules them, and they are the reason this
> file exists rather than a list of outcomes. Above roughly thirty decisions, add an index at the top
> of the file: one line per decision reading `D-nnn, <title>, <date>`, newest first, and keep every
> block below it.

````markdown
# Decision log

Company: <company name>
Newest entries at the top.

## D-001, <one line title of the decision>

- Date: <YYYY-MM-DD>
- Cell: <SE-3 / CO-4 / program-level>
- Context: <what forced a decision now, in two or three sentences. Include the constraint: money, time, headcount, a customer deadline.>
- Options considered:
  1. <option>. Cost: <time and money>. Risk: <what it leaves open>.
  2. <option>. Cost: <time and money>. Risk: <what it leaves open>.
  3. Do nothing. Cost: none today. Risk: <what accrues>.
- Chosen: <option number and name>
- Reasoning: <why this one, in plain language a founder would accept. Name the trade-off you are knowingly making.>
- Decided by: <name, title>
- My recommendation was: <same as chosen / different: state what you recommended and why>
- Reversible: <yes, cheaply / yes, expensively / no>
- Revisit on: <YYYY-MM-DD or "when <specific trigger> happens">
- Related: <R-00n, A-00n, links to docs>

## D-000, template above, delete this line once the first real entry exists

## Changelog

- <YYYY-MM-DD>: file created.
````

## ACCESS-LOG.md

Write to this file every time you ask for access to a system, and every time access is granted, denied, or revoked. A first security hire spends the first month unable to see anything, and the record of what was asked and refused is both a working tool and an accountability trail. The honesty rule: **denied and unanswered requests stay in the table forever, with the date, and get quoted verbatim in your leadership update.** Also record the day access lands, because auditors will ask when you first had visibility.

> A row is created the moment the ask is written, at status `drafted`, with `Drafted on` filled and
> `Requested on` blank. Filling `Requested on` is what moves the row to `requested`, and nothing else
> does. A row that is still `drafted` the next day is surfaced to the human, because an ask nobody
> sent is worse than an ask someone refused: a refusal is information and an undelivered draft is
> nothing. A row still `requested` after 7 days moves into the Denied or unanswered table and gets
> named in the next leadership update.

````markdown
# Access log

Company: <company name>
Owner: <your name>

## Requests

| ID | System | Access level requested | Exact role or scope requested | Justification | Requested from | Drafted on | Requested on | Status | Granted on | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-001 | <e.g. AWS Organization / GCP org / Azure tenant / GitHub org / GitLab group / Google Workspace admin / Microsoft 365 admin / Slack workspace / Teams tenant / device management console / billing portal> | <read-only auditor / admin / break-glass> | <the exact role or scope string, per the rule below> | <one line: what you will do with it and which cell it serves> | <name, title> | <YYYY-MM-DD, the day the ask was written> | <YYYY-MM-DD, the day it was sent, blank while the row is `drafted`> | <drafted / requested / granted / denied / partial / revoked / expired> | <YYYY-MM-DD> | <role or group actually assigned, plus any conditions attached> |

Status is exactly one of `drafted`, `requested`, `granted`, `denied`, `partial`, `revoked`, or
`expired`.

The `Exact role or scope requested` column is not optional for a cloud row, and it is not valid
unless it names the minimal pair for that provider: on Amazon Web Services `SecurityAudit` plus
`ViewOnlyAccess` (never `ReadOnlyAccess`, which includes `s3:Get*` and grants bulk read of customer
data); on Google Cloud `roles/iam.securityReviewer` plus `roles/browser` plus service-specific
viewer roles (never project `roles/viewer`, which includes `storage.objects.get`); on Azure `Reader`
plus `Security Reader`. Write it correctly in the row the first time. A wrong role string in a log is
copy-pasteable, and someone will paste it.

## Standing principle

Ask for read-only first, everywhere. It gets approved faster, it cannot break production,
and it is enough for every recon step in this skill. Escalate to write access only for a
specific named change, and record that escalation as its own row.

## Access I hold today

Refresh this section whenever a request is granted or revoked. This is also your own
offboarding checklist if you ever leave.

| System | Role or group | Since | Multi-factor authentication (MFA) method | Break-glass? | Last used |
| --- | --- | --- | --- | --- | --- |

## Denied or unanswered, carried to leadership

| ID | System | Asked on | Days outstanding | Blocked work | What I will say in the update |
| --- | --- | --- | --- | --- | --- |

## Changelog

- <YYYY-MM-DD>: file created.
````

## 90-DAY-PLAN.md

Write to this file at the end of the first planning session, and regenerate it whenever a fact changes that invalidates a step, for example when you discover the company already signed a SOC 2 commitment or that there is no device management at all. The honesty rule: **exactly one step is `in-progress` at a time, and the pointer at the top must match it.** If you find yourself with three steps in flight, the plan is fiction and the human is overloaded. The gate definitions and the reasoning behind the sequence live in `references/03-90-day-plan.md`.

````markdown
# 90 day plan

Company: <company name>
Start date: <YYYY-MM-DD>
Day 30 checkpoint: <YYYY-MM-DD>
Day 60 checkpoint: <YYYY-MM-DD>
Day 90 checkpoint: <YYYY-MM-DD>
Last regenerated: <YYYY-MM-DD>

## Current step

> **Now:** <GB-03, one line description of the single thing being worked on>
> **Next action:** <one imperative sentence>
> **Blocked by:** <nothing / A-003 access request / a decision owed by <name>>

> Gate definitions, names, day ranges, and exit criteria are owned by
> `references/03-90-day-plan.md`. If this template and that file disagree, **that file wins.**
> Do not copy exit criteria here; load the file and write the live ones in as you enter each gate.
> Day ranges overlap on purpose. Do not wait for a gate to close before starting the next.
>
> Rows are added only when a finding justifies them. An empty gate table is the correct state until a
> finding puts a step in it, and the `Justifying finding` cell may never be blank: it holds the risk
> identifier, the access-log identifier, or one clause naming what you observed.

## Gate A, understand. Target: days 1 to 14.

Exit criteria: <write in from `references/03-90-day-plan.md` on entering the gate>

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Gate B, stop the bleeding. Target: days 10 to 30.

Exit criteria: <write in from `references/03-90-day-plan.md` on entering the gate>

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Gate C, build the floor. Target: days 30 to 60.

Exit criteria: <write in from `references/03-90-day-plan.md` on entering the gate>

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Gate D, make it durable and prove it. Target: days 60 to 90.

Exit criteria: <write in from `references/03-90-day-plan.md` on entering the gate>

| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Explicitly not doing this quarter

Name these out loud so nobody assumes they are in flight, and so you can point at the list
when someone asks why a thing has not happened.

| Item | Why not now | Revisit |
| --- | --- | --- |
| Bug bounty program | Inbound volume you cannot triage alone, and you have no fix pipeline yet. A security.txt page and a disclosure address get most of the value. | <YYYY-MM-DD> |

## Schema conformance check

Run this at session start alongside the other integrity checks, and again before any session where you hand something to a human. It catches the failure mode that does not announce itself: the state files drifting out of schema until the next session cannot parse its own predecessor's output.

1. **Enum conformance.** Every grid status is one of the five values, with nothing appended. Every risk status, risk `Decision` value, exception status, access status, and plan step status is in its own declared vocabulary. Report any value not in the list, with the row.
2. **Heading conformance.** Every `##` heading in every state file appears in this template. An undeclared heading is a finding, not a convenience. If the content is legitimate and recurring, it belongs in a cell-owned satellite file listed in the `SKILL.md` routing table, or it belongs in this template. Pick one and do it, rather than inventing a heading in place.
3. **Identifier conformance.** No duplicate identifier within a prefix, across the whole state directory. No gaps that indicate a deleted row.
4. **Containment.** Every identified row sits inside its table. Nothing orphaned below a later heading.
5. **Required fields.** Every declared column exists and is in the declared order. A table that has quietly lost a column has lost whatever that column protected, and the columns that get dropped are always the uncomfortable ones: `My recommendation was`, `Reversible`, `Accepted by`.
6. **Sort order.** `RISK-REGISTER.md` open rows are sorted severity first. `90-DAY-PLAN.md` has exactly one step at `in-progress` and the pointer at the top matches it.
7. **Undelivered asks.** Count `ACCESS-LOG.md` rows at status `drafted`. Any row that has been
   `drafted` across two consecutive sessions is named, with its identifier and its recipient, in the
   first thing you say in your next turn, and its format switches to the two-line paste form in
   `SKILL.md` rule 11.

Report failures folded into the seven line opening from `references/04-interrupts.md`. Do not print a separate block. Fix what you can fix silently, and surface only what needs the human.

## Status vocabulary

not-started, in-progress, blocked, done, dropped. Only one step is `in-progress`.
A `blocked` step must name the blocker in the Blocked by column, and the blocker must
be a row in `ACCESS-LOG.md`, a decision owed by a named human, or an external dependency.

## Changelog

- <YYYY-MM-DD>: file created.
````

## SECURITY-CHARTER.md

Create this on demand, during Gate A, not at bootstrap. It is the one page that turns decision rights from a remembered conversation into something you can point at, and a boundary that exists only as a remembered conversation gets relitigated at the first real conflict, which is exactly when it is worth the most. Agree it with whoever the human reports to, keep it in the state directory, and record the date it was agreed and who signed it in `DECISION-LOG.md`. The honesty rule: **write the boundary that was actually agreed, not the one you wanted.** A charter that claims authority nobody granted is worse than no charter, because the first time it is tested it will be withdrawn in front of an audience. One page, signed, is worth more than ten pages nobody read.

````markdown
# Security charter

Company: <company name>
Security owner: <your name>, first security hire
Agreed with: <name, title of the person the security owner reports to>
Agreed on: <YYYY-MM-DD>

## What security decides alone

<The short list, in plain language. Usually: whether a finding is a finding, its severity, what goes
in the risk register, what goes in the leadership update, and the order the security work itself is
done in.>

## What security recommends while engineering decides

<The longer list. Usually: how a fix is implemented, when it ships relative to product work, and
which tool a team adopts. State what happens to a declined recommendation: it becomes a risk row
with a named accepter and a review date, never a silent loss.>

## What needs the chief executive

<The list that costs money, slows revenue, or changes what customers are promised. Usually:
accepting a critical risk, committing to a compliance framework with a date, spend above an agreed
threshold, and any security statement made to a customer or in public.>

## Standing incident containment pre-authorisation

Quoted from step 10 of `references/dr-4-company-comms-channel.md`, and in force only inside an
incident that has been formally declared with a named incident commander:

> I can revoke a named human employee's active sessions and refresh tokens, and revoke a third party
> application's access grant. Those two and nothing else.

Both are scoped to a single identity and both are reversible in one action. Everything else is
asked first, even at three in the morning. This is the one named exception to the hard stop on
access changes in `SKILL.md`, and it covers no other hard stop. If this pre-authorisation was not
agreed, write `not agreed` below and ask every time.

- Pre-authorisation agreed: <yes / not agreed>
- Agreed by: <name, title>
- Recorded in `DECISION-LOG.md` as: <D-00n>

## Risk acceptance severity ladder

Who may accept a risk at each severity, and the maximum period an acceptance may run for, are owned
by `references/05-metrics-and-comms.md` Part 5. Agree that ladder as written rather than restating
the numbers here, and if the company insists on a variation, write the variation and its reason.

- Ladder agreed as written: <yes / no, and the variation with its reason>

## Response time commitment for security reviews

<The number, and exactly what it covers. For example: a design review returned within two working
days, a dependency or vendor question within one, and a named path for something shipping today. A
commitment nobody can meet is worse than none, so write the one that is true this quarter.>

## Reviewed again on

<YYYY-MM-DD>. Also reviewed immediately after any incident, any change in who the security owner
reports to, and any new compliance commitment.
````

## SESSION-LOG.md

Created at the end of the first session and appended to at the end of every session after it.
Two parts with different lifecycles: a rolling picture of how this company operates, rewritten
in place, and an append-only record of what each session moved.

**This file holds no work.** It is not a backlog, not a task list, and not a second risk
register. Deferred work lives in `RISK-REGISTER.md`, sequenced work in `90-DAY-PLAN.md`,
outstanding asks in `ACCESS-LOG.md`, and paused work in `CONTEXT-STACK.md`. If you find
yourself writing something here that somebody could be assigned, it belongs in one of those
four and you are about to create the split register that `M-4` warns about. The "What moved"
line carries identifiers only, never a restatement of the row.

**Drafting it early is allowed, and revising it at close is then mandatory.** If the human works in
short unpredictable blocks, waiting for a clean end means the file sometimes never gets written at
all, which is the worst outcome for the one file the next session depends on. So draft it when you
have the material and revise it when the session actually ends. The cost of drafting early is real
and worth naming: reflection written mid-session under-weights the most informative moment, which is
usually how the session ended, and a revision that gets skipped leaves wrong content on disk looking
right. Both are managed the same way, by writing anything you cannot yet know as `TBC` rather than as
a plausible value.

**Do not confuse it with `session-01-summary.md`.** That one faces outward: it is written once,
pasted into the conversation, and read by the person who hired you. This one faces inward. It
exists so the next session starts knowing what the last one learned, and nobody else needs to
read it.

The honesty rule: **"What I got wrong" is filled in or explicitly marked as nothing surfaced.**
A session log where the agent was never wrong about anything is a session log nobody was paying
attention during. The point of the field is that being wrong about a company early is normal and
correcting it in writing is what stops the wrong version being repeated for a quarter.

````markdown
# Session log

Company: <company name>
Owner: <your name>

## How this company works

Rewritten in place, not appended. This is operating knowledge, not findings: it is the thing
that makes session five better than session one, and it is the only part of the state directory
that is about people rather than systems.

**Keep it to roughly one screen.** If a line has not changed a decision in two sessions, it is
trivia rather than working knowledge, and it goes. A long version of this section is a sign it
has become a diary.

| What | What I have observed | First seen | Last confirmed |
| --- | --- | --- | --- |
| How to reach <name> when it matters | <e.g. answers a phone call the same hour, acknowledges email with a reaction and no reply> | <YYYY-MM-DD> | <YYYY-MM-DD> |
| Who must be asked before <class of change> | <name, and what they need in order to say yes> | | |
| Arguments that have landed here | <e.g. framing a control as a deal question rather than a security opinion> | | |
| Arguments that have not | <e.g. anything that starts with what other companies do> | | |
| Where decisions actually get made | <e.g. in a call, then confirmed in writing afterwards, not in the channel> | | |
| What this company will not do, and why | <e.g. no managed devices, laptops are personally owned and expensed> | | |
| Standing constraints on my asks | <e.g. one ask per week to the only platform engineer, he is the deploy path> | | |

## Sessions

Newest first. One block per session. Keep each block to the six lines below.

### S-001, <YYYY-MM-DD>

- Ran for: <rough wall clock, so a pattern of thirty minute sessions is visible. If you are drafting this block before the session has actually ended, which is the right call when the human works in short unpredictable blocks, write `TBC` here rather than a number. A count written early and never revised is wrong on disk and reads as correct. `TBC` fails visibly.>
- What moved: <identifiers only. "R-014 opened, R-002 owner set to Priya, A-003 sent, GB-01 blocked on A-001". Never restate the row.>
- What I learned about how they work: <one or two lines, or "nothing new". Anything durable is promoted into the section above.>
- What I got wrong, and the correction: <what I believed at the start of this session that turned out to be false, or "nothing surfaced">
- Open when this ended: <the single thing the next session opens with>
- Human's state: <optional, one line. Overloaded, waiting on somebody, about to go on leave. It changes what is reasonable to propose next time.>

## Changelog

- <YYYY-MM-DD>: file created.
````

## INCIDENT-TEMPLATE.md

This is a template, not a live file. Copy it to `incidents/INC-<YYYY>-<NNN>-<short-slug>.md` when an incident is declared, and fill it as you go rather than reconstructing it afterwards. The honesty rule: **the timeline is written in the moment, in Coordinated Universal Time, and is never edited retroactively.** If you learn later that an entry was wrong, add a new entry correcting it. An edited timeline is worthless to a lawyer, an auditor, and to you.

Two rules that override everything in this file during a live incident. First, containment decisions that could lock out an employee, break a deploy, or notify a customer need an explicit human yes, and the yes goes in the timeline with a name. The two identity-scoped actions covered by the standing pre-authorisation in `SECURITY-CHARTER.md`, where that pre-authorisation was agreed in advance, proceed on the declared incident commander's authority, and the commander's name goes in the Approved by column. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop. Second, if there is any chance of legal or regulatory exposure, tell the human to loop in counsel before writing conclusions about cause or fault.

````markdown
# INC-<YYYY>-<NNN>: <short title>

- Declared by: <name>
- Declared at: <YYYY-MM-DD HH:MM in Coordinated Universal Time (UTC)>
- Detected at: <YYYY-MM-DD HH:MM UTC, if different from declared>
- Detected by: <person, alert name, customer report, third-party notification>
- Severity: <unassigned / SEV1 / SEV2 / SEV3>
- Incident commander: <name>
- Scribe: <name>
- Current status: <scoping / investigating / contained / eradicated / recovering / monitoring / closed>
- Last updated: <YYYY-MM-DD HH:MM UTC>
- Communication channel: <chat channel name and platform, plus the out-of-band fallback>

## Severity definitions

- SEV1: confirmed or highly likely access to customer data, production compromise, funds at
  risk, or an active attacker in the environment. Wake people up. Executive notified within
  one hour.
- SEV2: compromise of a system without confirmed customer data exposure, a credential known
  to be leaked, or a control failure with a plausible path to SEV1. Same working day.
- SEV3: a contained issue with no data exposure and no attacker present, for example a
  malicious dependency caught before install or a misconfiguration found and fixed.

> `unassigned` is legal only while status is `scoping`, and it is the correct value at the moment of
> declaration, before anyone has triaged. `scoping` is the state between "someone reported something"
> and "we know what this is". Both exist so that nobody has to invent a value at three in the
> morning. An incident may not stay at `scoping` past the end of the working day: by then it is a
> severity, or it is closed as not an incident with a one line reason.

## Summary

Three to five sentences a non-technical executive can read. What happened, what is affected,
what is not affected, what is being done, and what is not yet known. Update this section
every time the status changes. Write "not yet known" rather than speculating.

## Timeline

All times in UTC. Append only. Never edit a past row.

| Time (UTC) | Actor | Event or action | Evidence |
| --- | --- | --- | --- |
| <YYYY-MM-DD HH:MM> | <name or system> | <what happened or what was done, one line> | <path under evidence/, alert link, log query> |

## Affected systems and data

| System | Environment | What the attacker could reach | Confirmed accessed? | Data classes | Customer records in scope | How we know |
| --- | --- | --- | --- | --- | --- | --- |

Note the difference between "could reach" and "confirmed accessed" and never blur them.
"We have no evidence of access" is not the same statement as "no access occurred", and only
one of them is usually true.

## Identities and credentials in scope

| Identity | Type | Privileges | Rotated? | Rotated at (UTC) | Sessions revoked? |
| --- | --- | --- | --- | --- | --- |

Include human accounts, workload and service identities, continuous integration identities,
package registry tokens, and any long-lived application programming interface keys reachable
from the compromised surface.

## Containment actions

Each row needs a human approval when it can lock someone out, break a deploy, cost money, or
be visible to customers.

| Action | Proposed at (UTC) | Approved by | Executed at (UTC) | Result | Reversible? |
| --- | --- | --- | --- | --- | --- |

## Eradication and recovery actions

| Action | Owner | Executed at (UTC) | Verification that it worked |
| --- | --- | --- | --- |

## Notification decision

Fill this section even when the answer is no. The reasoning is the point, and it is what you
will be asked for later.

| Audience | Notify? | Reasoning | Deadline or clock | Decided by | Sent at (UTC) |
| --- | --- | --- | --- | --- | --- |
| Affected customers | <yes / no / not yet> | <contractual notification terms, factual basis> | <the shortest applicable clock from CO-3. Note that the GDPR Article 33 72-hour window runs from becoming aware, not from confirming, and that contractual windows of 24 or 48 hours usually run from discovery.> | | |
| All customers | <yes / no> | | | | |
| Data protection regulator | <yes / no / consult counsel> | <whether personal data of residents in a regulated jurisdiction is in scope> | | | |
| Sector or national regulator | <yes / no / n/a> | | | | |
| Law enforcement | <yes / no> | | | | |
| Cyber insurance carrier | <yes / no> | <most policies require prompt notice, check the policy> | | | |
| Downstream consumers of anything we publish | <yes / no / n/a> | <required if a package, image, or artifact we publish may have been poisoned> | | | |
| Employees | <yes / no> | | | | |
| Investors or board | <yes / no> | | | | |

Do not draft external notification language without the human agreeing to involve legal
counsel first. Draft internal updates freely.

## Evidence collected

Preserve before you clean up. Once an instance is terminated or a log rotates, it is gone.

| Item | Collected at (UTC) | Collected by | Stored at | Hash or size | Retention |
| --- | --- | --- | --- | --- | --- |

Storage rule: evidence lives under the incident's own folder or a restricted storage location
named here. Never in a chat thread, never on a personal laptop only, never in a shared drive
that the whole company can read.

## What we still do not know

An explicit list. Keep it visible so nobody mistakes an open question for a settled fact.

- <open question, who is chasing it, expected by when>

## Postmortem

Hold within five working days of closing. Blameless: the goal is the missing control, not the
person who clicked. Root cause means the condition that let it happen, not the last human who
touched it.

- Root cause:
- Contributing factors:
- What went well:
- What was slow or painful:
- Detection gap: <would we have found this ourselves, and how long did it take>
- Blast radius gap: <what let one compromise reach further than it should have>

### Action items

Each item gets a named owner, a date, and a row in `RISK-REGISTER.md` if it is not done
within the quarter. An action item without an owner is a wish.

| # | Action | Cell | Owner | Due | Status | Risk register ID |
| --- | --- | --- | --- | --- | --- | --- |

## Closure

- Closed at: <YYYY-MM-DD HH:MM UTC>
- Closed by: <name>
- Total duration, detection to containment: <hh:mm>
- Total duration, detection to closure: <hh:mm>
- `SECURITY-STATE.md` rows updated: <cell ids>
- `RISK-REGISTER.md` rows opened: <ids>
- `DECISION-LOG.md` entries added: <ids>
````

## Which file to write, and when

Use this as the routing table. If an event is not on this list and you are unsure, write it to `DECISION-LOG.md`, because an over-recorded decision costs nothing.

| Event | File | Section |
| --- | --- | --- |
| Discovered a fact about the environment | `SECURITY-STATE.md` | Environment and business facts, or the relevant cell row |
| Discovered a fact about who decides, who pays, or what went wrong before | `SECURITY-STATE.md` | Organisational facts |
| Found a third-party service the company depends on | `SECURITY-STATE.md` | Vendor and grant register |
| Found a standing third-party application grant | `SECURITY-STATE.md` | Vendor and grant register |
| Verified a control with a command or a screenshot | `SECURITY-STATE.md` | The cell row: set Evidence, Last verified, and promote status |
| Could not verify something and need a human | `SECURITY-STATE.md` | Open questions |
| Concluded a cell does not apply to this company | `SECURITY-STATE.md` | The cell row: status `n/a`, with the reason in Notes |
| Found something dangerous | `RISK-REGISTER.md` | Open risks |
| Deferred a piece of work to later | `RISK-REGISTER.md` | Open risks, status `open`, with a review date. There is no separate to-do file. |
| Granted a short, low-bar waiver on a specific control | `RISK-REGISTER.md` | Exceptions |
| An exception is being renewed for the second time | `RISK-REGISTER.md` | Promote it to a formal risk row and apply the acceptance rule |
| Someone with authority accepted a danger | `RISK-REGISTER.md` and `DECISION-LOG.md` | Open risks row set to `accepted`, a full record in Accepted risks, plus a new decision entry |
| Chose a framework, a tool, or a sequence | `DECISION-LOG.md` | New entry at the top |
| Decided deliberately not to do something | `DECISION-LOG.md` and `90-DAY-PLAN.md` | New entry plus Explicitly not doing this quarter |
| Named an interrupt as a distraction and declined it | `DECISION-LOG.md` | New entry recording what was declined and why. Do not open a frame for it. |
| Asked for access to any system | `ACCESS-LOG.md` | Requests |
| Access granted, denied, or revoked | `ACCESS-LOG.md` | Requests, plus Access I hold today |
| Work interrupted mid-task | `CONTEXT-STACK.md` | Active stack, new frame at the top |
| Interrupt cleared and work resumed | `CONTEXT-STACK.md` | Move the finished or dropped frame to Closed frames |
| A plan step started, finished, or blocked | `90-DAY-PLAN.md` | The gate table plus the Current step pointer |
| A fact invalidated the plan | `90-DAY-PLAN.md` | Regenerate affected gates, and log why in Changelog |
| Mapped how code reaches production | `sdlc-map.md` (SE-1) | Create on demand. Summarise in the SE-1 row's Notes. |
| Answered a security questionnaire question | `QUESTIONNAIRE-KB.md` and `QUESTIONNAIRE-LOG.md` (CO-2) | Create on demand. The knowledge base holds reusable answers, the log holds who was sent what and when. |
| Found a commitment already made to a customer | `COMMITMENT-REGISTER.md` (CO-3) | Create on demand. Summarise in the CO-3 row's Notes. |
| Enumerated laptops or workstations | `devices.csv` (CS-2) | Create on demand. Summarise the enrolled fraction in the CS-2 row. |
| Agreed who decides what with the person the human reports to | `SECURITY-CHARTER.md` (05 metrics and comms) | Create on demand, in Gate A. Record the date it was agreed and who signed it in `DECISION-LOG.md`. |
| Wrote the first session's handover | `session-01-summary.md` | Cold start only. See `references/00-cold-start.md`. |
| Ending a session, any session | `SESSION-LOG.md` | Append the six line block. Update `## How this company works` in place if it changed. Identifiers only, never a restatement of a row that lives elsewhere. |
| Drafted something not yet published or sent | `drafts/` | Nothing in this folder is external until a human approves it. |
| An incident is declared | `incidents/INC-<YYYY>-<NNN>-<slug>.md` | Copy from the incident template |
| Anything happens during an incident | The incident file | Timeline, immediately, in Coordinated Universal Time |
| Incident closed | Incident file, `SECURITY-STATE.md`, `RISK-REGISTER.md` | Closure section plus updated cells and new risks |

The files named with a cell or a reference file in brackets are created on demand by that
playbook, not at bootstrap. Do not create them speculatively. The six files created at bootstrap are
`SECURITY-STATE.md`, `RISK-REGISTER.md`, `CONTEXT-STACK.md`, `DECISION-LOG.md`,
`ACCESS-LOG.md`, and `90-DAY-PLAN.md`, plus the `evidence/`, `incidents/` and `drafts/` folders.

## Integrity checks

Run these at the start of every session, before doing new work. They take under a minute and they catch the two failure modes that make state files useless: silent staleness and quiet optimism.

1. **No `done` without evidence.** Scan `SECURITY-STATE.md`. Any row with status `done` and an empty Evidence column gets demoted to `partial` on the spot, and you tell the human you did it and why.
2. **No stale `done`.** Any row whose Last verified date is more than 90 days old gets demoted to `partial` with the note `verification expired`. Controls decay. A device management policy that was correct in March may have been switched off in May.
3. **One step in flight.** Confirm the Current step pointer in `90-DAY-PLAN.md` matches exactly one `in-progress` row. If not, ask the human which one is real and fix the rest.
4. **Stack hygiene.** Any frame in `CONTEXT-STACK.md` whose Age exceeds 5 days is raised for escalation, and any frame past 14 days gets a proposal to either revive it as the next step or close it as dropped with a reason and a `RISK-REGISTER.md` row carrying what it leaves open. Do not leave a frame silently rotting. The Age thresholds and the three-frame ceiling are owned by `references/04-interrupts.md`.
5. **Outstanding access.** Any `ACCESS-LOG.md` row still `drafted` the next day is surfaced to the human, and any row still `drafted` across two consecutive sessions is named, with its identifier and its recipient, in the first thing you say in your next turn. Any row still `requested` after 7 days moves into the Denied or unanswered table and gets named in the next leadership update. An ask nobody sent is worse than an ask someone refused, and blocked access is the single most common reason a first security hire makes no progress, so both counts must be visible to the person who can unblock them.
6. **Unowned high severity.** Any `critical` or `high` risk with owner `UNOWNED` becomes the first thing you raise in the session. An unowned critical risk is a decision nobody has made yet, and your job is to force the decision, not to hold the risk quietly.
7. **Review dates.** Any accepted risk past its Review date reopens automatically. Tell the human it reopened and who accepted it originally.
8. **Expired exceptions.** Any `RISK-REGISTER.md` exception past its Expiry date with the control still unmet becomes a risk row that day, at its proper severity. Any exception on its second renewal is promoted to a formal risk acceptance.

Fold any failed check into the seven line opening defined in `references/04-interrupts.md`. Do not print a separate block. A session that opens with a wall of state file output has spent the human's attention before doing any work.

## Rules for editing state files

1. Never delete a row. Move it to the file's closed, abandoned, or historical section with an outcome and a date.
2. Never renumber identifiers. If a risk row was a mistake, mark it `dropped` and say why. In a file that declares no `dropped` status, leave the row in place and record the correction in its Notes and in the Changelog.
3. Never write a fact you were told without attributing it and dating it.
4. Never write a secret, a token, a private key, or an unfixed exploitable detail tied to a named customer.
5. Never mark work complete on the human's behalf. Ask them to confirm, then record who confirmed and when.
6. Append a Changelog line whenever a file changes materially, so a future session can see movement without diffing.
7. When two state files disagree, the one with the more recent dated evidence wins, and you flag the conflict to the human rather than silently picking a side.
