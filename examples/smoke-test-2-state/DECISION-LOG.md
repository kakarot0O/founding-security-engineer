# Decision log

Company: Acme Analytics
Newest entries at the top.

## D-007, security records moved to ~/acme-security/security-register, and the privilege label applied

- Date: 2026-08-26
- Cell: program-level
- Context: Acme's legal adviser, Halloran Vance LLP, asked where the security records are held and was firm that they must not be reachable by contractors or by Northwind Digital. The records were in an encrypted folder on Sam Okafor's personally-owned laptop, which satisfied that requirement but left Acme's incident record on hardware the company does not own, with no backup and no history (R-025). Priya created a new GitHub organisation, `acme-security`, containing one private repository, `security-register`, with two members.
- Options considered:
  1. Leave the records on the laptop. Cost: none today. Risk: single copy, no history, on hardware Acme does not own, held by an employee five days into the role.
  2. Move to a repository inside the existing GitHub organisation. Cost: none. Risk: an organisation owner can read every private repository in it, and the owners of the existing organisation are still unknown (A-002). Also contains the contractors Sam could not enumerate (R-011).
  3. Move to Google Drive or another Workspace location. Cost: none. Risk: rejected outright. Northwind Digital hold a Workspace super admin, so this is precisely the location the legal adviser told us to avoid.
  4. Move to a new organisation with no inherited administrators. Cost: ten minutes. Risk: none material.
- Chosen: 4.
- Reasoning: a new organisation sidesteps the unanswered question of who owns the existing one, rather than waiting on it. Two named members, no inherited admins, outside every trust boundary currently in doubt.
- Decided by: Sam Okafor and Priya
- My recommendation was: same as chosen
- Reversible: yes, cheaply
- Revisit on: when A-002 is answered and the ownership of the existing GitHub organisation is known
- Related: R-025, A-002, R-011, INC-2026-001

**Execution record, 2026-08-26.** The files were moved, not copied, because two copies of a risk register is the same defect as none of them being current. Verified afterwards: no state file or subdirectory remains at `~/security-program/acme-analytics`, and all six state files plus `evidence/`, `incidents/` and `drafts/` are present at `~/acme-security/security-register` with byte sizes matching the pre-move inventory. A pointer file was left at the old path so that a future session reading it does not conclude the programme was never started.

**One deviation, stated deliberately.** The standard move procedure refuses when the destination already exists. It existed and held one file, GitHub's placeholder README. Contents were therefore moved into it rather than the directory itself, and the README was left in place.

**This decision is NOT closed, and the reason is on the record rather than assumed.** `~/acme-security/security-register` is not a git repository. There is no `.git` directory anywhere under `~/acme-security`, and `git rev-parse` fails there. It is a plain folder containing GitHub's placeholder README, so the clone either did not complete or landed elsewhere. Consequently the move has changed the path and nothing else: the records still sit on one personally-owned laptop, with no version history and no backup. R-025 stays open and does not close until a push has succeeded and the files have been seen on github.com. Recording this decision as complete before that point is the exact failure the migration procedure exists to prevent.

**Privilege label applied 2026-08-26**, verbatim as supplied by Halloran Vance LLP through Priya, as the first line of both incident files and nowhere else: "Privileged and Confidential: Prepared at the request of Halloran Vance LLP for the purpose of obtaining legal advice". The wording was not paraphrased, extended, or applied to any other document. The adviser was explicit that `RISK-REGISTER.md` and `90-DAY-PLAN.md` stay outside scope, and they are unlabelled.

## D-006, decline Google Workspace super admin during the incident, request scoped access in daylight

- Date: 2026-08-25
- Cell: CS-1
- Context: At roughly 21:00 during INC-2026-001, Priya discovered she holds an unused Google Workspace super admin account and offered to grant Sam super admin so he could contain Maria's account himself. Containment needed to happen that night. Neither Priya nor Sam had ever opened the admin console. Sam is five days into the role and is the person investigating the incident.
- Options considered:
  1. Accept super admin and perform containment personally. Cost: none in time. Risk: unscoped domain-wide rights granted verbally at night with no record of what was agreed, held by the investigator, whose first ever actions in that console are taken under pressure on a live incident. Any subsequent dispute about what was changed or deleted lands on the newest employee. Creating a privileged account also generates an admin audit event while the attacker's scope is still unknown.
  2. Decline for tonight, Priya drives the console while Sam reads the steps, request scoped access in writing the following day. Cost: marginally slower, and it requires an executive to sit through a console walkthrough late in the evening. Risk: minimal. The bottleneck is the reading, not the clicking.
  3. Defer all containment to the morning. Cost: an intruder retains mailbox access overnight. Risk: unacceptable while a finance mailbox is involved.
- Chosen: 2.
- Reasoning: the actions taken during an incident should be attributable to the company's own authorised administrator, with the security owner advising, and that record is worth more than the convenience. The asymmetry is the argument: an error by the account owner is an awkward evening, the same error by a five-day employee holding rights nobody wrote down is career-defining. A secondary benefit is that the person who holds domain-wide rights over the company learns what they do, which she needed regardless. Access will be requested properly the next day, scoped to the role, in writing.
- Decided by: Sam Okafor
- My recommendation was: same as chosen. I recommended declining and gave the three reasons in the message Sam sent.
- Reversible: yes, cheaply. The grant can be made at any time.
- Revisit on: 2026-08-26, when the scoped access request is written
- Related: INC-2026-001, A-005, R-018, CS-1

## D-005, no further requests to Dev Patel this week

- Date: 2026-08-26
- Cell: program-level
- Context: Two security requests went to Dev Patel on the same day, his last week before holiday. The second was necessary: his answer to the first changed the assessment. Sam judged that a third would damage a working relationship he needs for the next year, and he is the person who has to hold that relationship.
- Options considered:
  1. Keep sending as findings arrive. Cost: none today. Risk: the only engineer who deploys learns that security means an unbounded queue of interruptions, arriving fastest when he is least able to act. That reputation is expensive and slow to undo.
  2. Stop after the second, hold everything else until his return. Cost: the tenant-scoping fix in R-003 may wait weeks unless it rides along with the message already sent. Risk: a critical stays open longer.
  3. Escalate the remainder to Priya so it does not touch Dev. Cost: makes an engineering matter an executive one. Risk: reads as going over his head on day five.
- Chosen: 2.
- Reasoning: the sequencing cost was real and it was the security partner's, not Sam's. Two asks in one day happened because the first answer changed the picture, which is the right reason, but it still spent Sam's capital twice. The remaining items are not on Dev's clock in the way the impersonation question is. One carve-out applies and is not a new ask: if Dev answers that the endpoint is reachable, that the deployed code matches, and that he cannot close it before he leaves, that is the completion of the request already sent, and it goes to Priya the same hour rather than back to Dev.
- Decided by: Sam Okafor
- My recommendation was: same as chosen, with the carve-out above stated explicitly so it is not mistaken for a third ask
- Reversible: yes, cheaply
- Revisit on: Dev Patel's first working day back
- Related: R-001, R-003, R-009, X-001

## D-004, do not test the impersonation endpoint against production

- Date: 2026-08-26
- Cell: program-level
- Context: R-001 describes an endpoint in production that appears to issue a session token for any user with no authentication. The fastest way to know whether it is reachable is to send it a request. Nobody at Acme has given written authorisation for any test against a production system, and the endpoint mints credentials rather than merely returning data.
- Options considered:
  1. Send one request to the endpoint to confirm reachability. Cost: two minutes. Risk: it is an unauthorised active test of production, it may create a real usable session token for a real customer's user, it appears in logs as the new security hire doing exactly what an attacker would do, and it is the single most common way a first security hire ends a career early.
  2. Ask Dev Patel, who can answer from knowledge in one line. Cost: one message, hours of latency. Risk: he is on holiday from next week, so the window is short.
  3. Do nothing and wait for AWS and infrastructure access. Cost: days or weeks. Risk: unacceptable for a critical.
- Chosen: 2, ask Dev Patel.
- Reasoning: the answer is obtainable from a human who already knows it, at zero risk. Testing production without written authorisation is on the always-ask list and would not become acceptable just because the finding is serious. If Dev cannot answer and authorisation is later given in writing by someone with the authority to give it, this decision is revisited.
- Decided by: Sam Okafor, on the security partner's recommendation
- My recommendation was: same as chosen
- Reversible: yes, cheaply
- Revisit on: when written authorisation for active testing exists, or when Q2 is answered
- Related: R-001, Q2

## D-003, Dev Patel retains `permissions: write-all` on the CI workflow until his return

- Date: 2026-08-26
- Cell: M-2
- Context: Sam asked Dev Patel for three changes to `.github/workflows/ci.yml` before Dev's holiday. Dev made two and declined the third, stating that something in the release job needs write access and that he would not risk breaking a deploy the day before going away.
- Options considered:
  1. Press for all three today. Cost: political capital with the only person who deploys, on his last working day. Risk: a broken deploy with nobody available to fix it, and a colleague who learns that security requests are not negotiable.
  2. Accept two of three, record the third as a time-limited exception with an owner and an expiry. Cost: the CI token keeps write scope for a few weeks. Risk: low now that the job no longer runs untrusted pull request code.
  3. Escalate to Priya. Cost: high, and disproportionate. Risk: turns a reasonable engineering judgement into a conflict.
- Chosen: 2, exception X-001.
- Reasoning: after the two changes that were made, the job no longer runs code from an untrusted pull request and no longer carries production credentials. The write-scoped token is now only reachable by people who already have write access to the repository. Dev's reasoning was sound and refusing to change deploy permissions before an absence is correct judgement. Recording it as a dated exception rather than a conversation is what makes it come back in a few weeks instead of never.
- Decided by: Dev Patel, platform engineer
- My recommendation was: same as chosen
- Reversible: yes, cheaply
- Revisit on: 2026-09-30, or on Dev's first working day back if earlier
- Related: X-001, M-2

## D-002, do not commit the state directory, and keep it out of the company repository

- Date: 2026-08-26
- Cell: program-level
- Context: The state directory holds a ranked, dated list of Acme's exploitable weaknesses with named owners. A location had to be chosen before any finding could be written down. The working directory is the product repository, which Sam is only a normal member of, and which apparent non-staff accounts can read (R-011).
- Options considered:
  1. `./.security/` inside the product repository, gitignored. Cost: none. Risk: one `git add -f` or one tooling accident away from publishing the register to everyone with repository access, including the accounts in R-011.
  2. `~/security-program/acme-analytics/` on Sam's laptop. Cost: no version history, and exactly the backup that the laptop has, which may be none. Risk: total loss if the laptop dies.
  3. A separate private repository readable only by Sam and Priya. Cost: needs a repository created, which needs GitHub organisation rights Sam does not have. Risk: none material.
- Chosen: 2 now, moving to 3 once Sam has organisation access.
- Reasoning: option 1 is ruled out by R-011. Option 3 is the right destination but is blocked on access Sam does not yet hold. Option 2 is the recoverable direction: a folder on a laptop can be moved into a repository later, whereas a risk register accidentally readable by contractors cannot be un-read.
- Decided by: Sam Okafor
- My recommendation was: same as chosen
- Reversible: yes, cheaply. Migration procedure is section 3.4 of the cold start protocol, and it does not close until the files are verified at the new path.
- Revisit on: when A-002 is granted
- Related: A-002, R-011

## D-001, work the Meridian Health deal as the organising frame for the first two weeks

- Date: 2026-08-26
- Cell: program-level
- Context: Sam was hired without a specific brief. Discovery established the actual trigger: a security addendum arrived in the draft Meridian Health master services agreement, a deal reported as weeks from closing, and the hire followed shortly after. Meanwhile the read-only survey produced four critical findings.
- Options considered:
  1. Work the findings in severity order and treat the deal as a separate stream. Cost: none directly. Risk: the security programme and the thing the company actually cares about run on separate tracks, and the security owner spends political capital twice.
  2. Use the deal as the frame and let it justify the access and the fixes. Cost: some findings get framed commercially rather than on their own merits. Risk: if the deal dies, the frame dies with it.
  3. Lead with the findings alone. Cost: reads as the new hire cataloguing everyone's mistakes in week one. Risk: high, and it is the standard way a first security hire loses the room.
- Chosen: 2.
- Reasoning: every access request and every fix is easier to grant when it is attached to revenue that a named executive is already thinking about. The findings do not become less real for being framed this way, and they are all recorded here at their own severity regardless. If the deal dies, the register still stands on its own.
- Decided by: Sam Okafor
- My recommendation was: same as chosen
- Reversible: yes, cheaply
- Revisit on: when the Meridian Health addendum has been read, or if the deal is lost
- Related: A-003, R-007, CO-3

## Changelog

- 2026-08-26: D-007 added. Records moved and privilege label applied. Repository step outstanding.
- 2026-08-26: file created with five entries.
- 2026-08-25: D-006 added during INC-2026-001.
