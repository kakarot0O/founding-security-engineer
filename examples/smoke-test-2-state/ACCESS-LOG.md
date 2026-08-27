# Access log

Company: Acme Analytics
Owner: Sam Okafor

## Requests

| ID | System | Access level requested | Exact role or scope requested | Justification | Requested from | Drafted on | Requested on | Status | Granted on | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-001 | AWS account | read-only auditor | `SecurityAudit` plus `ViewOnlyAccess`. Not `ReadOnlyAccess`, which includes `s3:Get*` and would grant bulk read of customer data. | Establish who can reach production data, verify whether the customer exports bucket is public, scope the application IAM policy, and read the audit log to answer whether anything has already happened. Serves DR-0, M-3, CS-1. | originally unknown recipient; re-asked of Priya | Sam's first day, exact date to confirm | Sam's first day, exact date to confirm; re-sent 2026-08-26 | requested | | No reply to the original day-one request as of 2026-08-26. Re-asked inside the message to Priya on 2026-08-26 with the exact role pair named. This request blocks R-004, R-005 and R-012 entirely. |
| A-002 | GitHub organisation | read-only, including organisation settings and membership | organisation member list, repository access lists, and audit log read | Establish who holds access to the repository that contains production credentials in its history, and which of those accounts are not staff. Serves CS-1, SE-1, DR-0. | Priya | 2026-08-26 | 2026-08-26 | requested | | Prompted by Sam's own observation on the repository settings page that more accounts hold access than expected. Blocks R-011. |
| A-003 | Contracts, specifically the Meridian Health MSA security addendum | read | the draft addendum document | Check line by line that every security commitment in it can be evidenced, before it is signed. Serves CO-3. | Priya, or Tom in sales | 2026-08-26 | 2026-08-26 | requested | | The deal is reported as weeks from closing. This is the document that most changes the shape of the programme. |
| A-004 | SOC 2 report | read | a copy of the report referenced by the public /security page | Required for the Meridian Health security review, and it establishes whether a published commitment can be evidenced. Serves CO-1, CO-3. | Priya | 2026-08-26 | 2026-08-26 | requested | | Framed as a request for the artifact rather than a challenge to the claim. Blocks R-007. |
| A-005 | Google Workspace admin console | scoped admin, not super admin | To be specified in daylight. Expected minimum: user management on non-admin accounts (password reset, sign-in cookie reset, two-step verification status), plus Reports privileges for the login and admin audit logs. Super admin only if a specific task requires it and only as a separate account from the daily one. | Investigate INC-2026-001, run the compromise assessment across mailboxes, and hold the identity work. Serves CS-1, DR-0, CS-3. | Priya | 2026-08-26 | 2026-08-26 | requested | | Priya offered unscoped super admin at approximately 21:00 on 2026-08-25, during the incident. Declined that night on the security owner's recommendation, see D-006. This row is the deliberate replacement: scoped, in writing, decided rather than granted in a panic. Blocker while `drafted` was deciding the scope, not sending. Scope decided and sent 2026-08-26, folded into the same message as the answer to the legal adviser's question about where records are held. Super admin acceptable as a fallback only on a separate admin account, with two-step, and with the purpose recorded. Priya agreed on 2026-08-26 and said she would set it up after standup. Row stays at `requested` until the access has been used successfully: an agreement is not a grant, and `granted` requires the date it actually worked. |

Status is exactly one of `drafted`, `requested`, `granted`, `denied`, `partial`, `revoked`, or `expired`.

As of 2026-08-26 the only response to A-002, A-003 and A-004 is a thumbs-up reaction in Slack on the message that carried all four. That is an acknowledgement, not a grant and not a refusal. All four rows stay at `requested`.

## Standing principle

Ask for read-only first, everywhere. It gets approved faster, it cannot break production, and it is enough for every recon step in this programme. Escalate to write access only for a specific named change, and record that escalation as its own row.

## Access I hold today

| System | Role or group | Since | Multi-factor authentication (MFA) method | Break-glass? | Last used |
| --- | --- | --- | --- | --- | --- |
| GitHub organisation | normal member | unknown | unknown | no | 2026-08-26 |
| Local clone of the `acme-analytics` repository | read | unknown | n/a | no | 2026-08-26 |

## Denied or unanswered, carried to leadership

| ID | System | Asked on | Days outstanding | Blocked work | What I will say in the update |
| --- | --- | --- | --- | --- | --- |
| A-001 | AWS account | Sam's first day, exact date to confirm | 5 or more | Cannot verify whether the customer exports bucket is public, cannot scope the application's unrestricted IAM policy, and cannot look at the audit log to answer whether anything has already happened. Three risk register rows are entirely blocked on it. | Read-only AWS access was requested on day one and has not arrived. Until it does, the answer to "has anything already happened here" is unknown rather than no, and that gap is a decision someone else is making by not answering. |

## Changelog

- 2026-08-26: file created. Four requests recorded, all at status `requested`. Nothing is sitting at `drafted`.
- 2026-08-26: A-005 sent and agreed verbally by Priya. Held at `requested` rather than `granted` until it has been used. Nothing sits at `drafted`.
- 2026-08-25: A-005 added at `drafted`. It is deliberately undelivered until 2026-08-26: an offer of unscoped super admin was declined during the incident and is being replaced by a scoped written request. Blocker is deciding the scope, not sending.
