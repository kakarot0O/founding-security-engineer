**Privileged and Confidential: Prepared at the request of Halloran Vance LLP for the purpose of obtaining legal advice**

---

# INC-2026-001: Email claiming to be from Northwind Digital requesting payment to changed bank details

- Declared by: Sam Okafor
- Declared at: 2026-08-25 19:09 UTC
- Detected at: 2026-08-25 19:05 UTC (approximate, time Maria forwarded it to Sam; confirm exact time from the mail headers)
- Detected by: Maria (finance), who forwarded it to Sam and asked whether it was legitimate before paying
- Severity: SEV1
- Incident commander: Sam Okafor
- Scribe: Sam Okafor
- Current status: contained, investigating scope.
- Last updated: 2026-08-26 08:30 UTC
- Communication channel: to be moved off email immediately. Email is not a safe channel while a mailbox on either side may be read by a third party. Slack or phone.

## Summary

Updated 2026-08-25 21:30 UTC. Scope established and it is substantially larger than the invoice. Google Workspace login records show sign-ins to Maria's account from an address in a country where Acme has no personnel, the earliest visible on 2026-03-17, recurring every few days, most recently 2026-08-25 at 06:12, which is the same day the fraudulent invoice was sent and the same day this incident was declared. Maria's account has no second authentication factor; it is protected by a password alone. Nine genuine Northwind messages sit in her trash, the earliest dated 2026-03-24, consistent with the filter having been in place since around that date. That is approximately five months of unauthorised access to the mailbox of the person who operates Acme's finance systems.

Separately, and on current evidence a different problem rather than the same one, the Workspace holds four super admin accounts: Priya, Dev Patel, an unattributed `admin@acmeanalytics.com` believed to date from the original setup, and an `@northwinddigital.com` address belonging to the agency. Priya's has a second factor. The other three are unverified. Assessment, recorded as inference and not as fact: an actor holding domain-wide rights would have no reason to sign in as a single user from a foreign address every few days, nor to monetise that access with a 14,000 invoice, so the mailbox intrusion is most likely a commodity credential compromise rather than an admin compromise. The login history of the two unattributed admin accounts is the test of that assessment and is being pulled.

An open question has been raised by Priya as to whether customer personal data was present in the affected mailbox. That question is not answered, is not being answered tonight, and is being referred with the notification-clock question to whoever provides Acme's legal advice. No determination has been made by the security owner and none is the security owner's to make.

Previous update, 2026-08-25 20:35 UTC. Severity raised to SEV1. Unauthorised access to an Acme mailbox is confirmed, not inferred. Maria located a mail filter in her own Gmail account that she did not create: it matches on Northwind and the word invoice, skips the inbox, marks as read, and sends to trash. Only someone with access to that account can create a rule in it, and the rule's only function is to prevent the genuine supplier emails reaching her so that the attacker's version of the thread is the only one she sees. Separately, the sending address is `northwind-digital.com` while every message in the genuine thread history is `northwinddigital.com`. The message therefore did not originate from Northwind Digital's mail system; it came from an attacker-registered lookalike domain, and the thread content was obtained by reading Maria's mailbox rather than Northwind's. Northwind is not cleared but is no longer the likely point of compromise.

Maria saved the fraudulent bank details onto Northwind's contact record in Xero before deciding not to pay. No payment has been made to those details, but until the record is reverted any person in the company paying Northwind would pay the attacker.

The invoice was the attempt that was caught. The mailbox access is the actual incident and remains open. The material risk is that an Acme mailbox is a password reset channel for every system that emails its owner, and the owner in this case is the person who operates the finance systems.

Previous update, 2026-08-25 19:40 UTC. The message is a reply inside a genuine existing email thread between Maria and Northwind Digital, with older messages quoted underneath including one Maria sent herself last month. The invoice number follows on from the last invoice Acme paid, and the amount is within Northwind's normal billing range. That combination establishes that a third party has read the real conversation. The read occurred either in a mailbox at Northwind Digital or in a mailbox at Acme, and which of the two is the open question that everything else depends on. No payment has been made. Severity raised from unassigned to SEV2. It becomes SEV1 if the account being read is confirmed to be an Acme account, or if anything beyond this thread is found to have been reached.

Original description, retained: An email presenting as Northwind Digital states that the supplier's bank details have changed and requests payment of an invoice for 14,000 due today. Maria in finance forwarded it to Sam and asked whether it was legitimate before paying. Sam observed that the reply-to address looked inconsistent. No payment has been made. No customer data is involved and there is no evidence at this time of any access to Acme systems. What is not yet known: whether the message is fraudulent, whether it sits inside a genuine existing email thread, whether any mailbox at Acme or at Northwind Digital has been accessed by a third party, and whether anyone else at Acme received the same message.

Northwind Digital is the agency reported to hold root on Acme's AWS account, which raises the consequence if that supplier's mail is found to have been accessed by a third party. That is an open question, not a finding.

## Timeline

All times in UTC. Append only. Never edit a past row.

| Time (UTC) | Actor | Event or action | Evidence |
| --- | --- | --- | --- |
| 2026-08-25 19:05 | Maria, finance | Forwarded an email presenting as Northwind Digital, stating changed bank details and an invoice for 14,000 due today, and asked Sam whether it was legitimate before paying. Payment screen reported open. | to be captured: original message with full headers |
| 2026-08-25 19:07 | Sam Okafor | Observed that the reply-to address looked inconsistent with the sender. Raised with the security partner rather than answering directly. | Sam's own report |
| 2026-08-25 19:09 | Sam Okafor | Incident declared at status scoping, severity unassigned. | this file |
| 2026-08-25 19:20 | Sam Okafor | Sent Maria a hold instruction. Payment stopped before it was made. Maria reported she had been uneasy about the invoice for most of the afternoon and had not wanted to be the person who refused it. | Sam's report |
| 2026-08-25 19:25 | Maria, finance | Forwarded the original message to Sam as an attachment, preserving headers. Nobody has replied to the message and nobody has deleted anything. | original message with headers, held by Sam, to be stored in `evidence/` |
| 2026-08-25 19:35 | Maria, finance | Confirmed the message is a reply inside an existing thread with Northwind Digital, with prior messages quoted including one Maria sent last month. Confirmed the invoice number follows on from the last invoice paid and the amount is in Northwind's usual range. | Maria, relayed by Sam |
| 2026-08-25 19:38 | Sam Okafor | Established that Acme holds no phone number for any named individual at Northwind Digital. All contact runs through a shared support mailbox answered by a different person each time. Old invoices carry an email address and a postal address only. | Sam and Maria |
| 2026-08-25 19:40 | Sam Okafor | Severity raised to SEV2, status moved to investigating. Instruction issued to move all discussion of this incident off email. | this file |
| 2026-08-25 20:05 | Maria, finance | Inspected her own Gmail settings. Found a filter she states she did not create, matching Northwind and the word invoice, set to skip the inbox, mark as read and send to trash. Screenshotted. No forwarding address and no delegated access visible to either Maria or Sam. Nothing deleted, nothing modified. | screenshot held by Maria, to be stored in `evidence/` |
| 2026-08-25 20:10 | Sam Okafor | Confirmed no action has been taken against Maria's account by anyone, and instructed that none be taken. | Sam's report |
| 2026-08-25 20:15 | Maria, finance | Confirmed she saved the new bank details onto Northwind's contact record in Xero before deciding not to pay. No payment made to those details. States no other supplier's details have changed and no payments went out that she did not initiate, but wants to review the ledger properly before confirming. | Maria, relayed by Sam |
| 2026-08-25 20:20 | Sam Okafor and Maria | Moved all discussion of the incident off email onto Slack. | Sam's report |
| 2026-08-25 20:25 | Sam Okafor | Identified that the sending domain is `northwind-digital.com`, hyphenated, while every message in the genuine thread history uses `northwinddigital.com`. Establishes an attacker-registered lookalike domain rather than a compromised Northwind mailbox. | original message, preserved as an attachment, held by Sam |
| 2026-08-25 20:35 | Sam Okafor | Severity raised to SEV1 on confirmed unauthorised access to an Acme mailbox. | this file |
| 2026-08-25 21:05 | Priya | Enumerated super admin assignments in the Google Workspace console. Four: Priya, Dev Patel, `admin@acmeanalytics.com` (unattributed, believed to date from the original setup), and an `@northwinddigital.com` address. Priya's own account has two-step verification enabled. The other three are unverified. | Google Workspace admin console, Account, Admin roles, Super Admin |
| 2026-08-25 21:10 | Priya | Confirmed Maria's account has no second authentication factor. Password only. | Google Workspace admin console, Directory, Users |
| 2026-08-25 21:20 | Priya and Sam Okafor | Reviewed the login events log for Maria's account. Sign-ins present from an address in a country where Acme has no personnel. Earliest visible 2026-03-17. Recurring every few days. Most recent 2026-08-25 06:12. | Google Workspace login events log. IP addresses and dates to be captured to `evidence/` before the session ends. |
| 2026-08-25 21:25 | Sam Okafor and Maria | Counted nine genuine Northwind messages in Maria's trash without opening any. Earliest dated 2026-03-24. | Gmail trash, message list only, nothing opened |
| 2026-08-25 21:28 | Priya | Asked whether customer data was present in the affected mailbox. Sam answered that he would have to look. No determination made. | call notes |
| 2026-08-25 21:30 | Sam Okafor | Scope recorded as approximately five months of unauthorised mailbox access. Containment confirmed to proceed tonight, gated on first pulling the login history of the two unattributed super admin accounts. | this file |
| 2026-08-25 21:45 | Priya | Pulled login history for the two unattributed super admin accounts. `admin@acmeanalytics.com`: no login events, last recorded sign-in 2023, no second factor. `@northwinddigital.com`: sporadic use, most recent approximately three weeks prior, from a connection consistent with normal UK business use, different address to the intruder. Assessed as legitimate agency use. Containment cleared to proceed. | Google Workspace login events log |
| 2026-08-25 22:15 | Sam Okafor | Briefed Priya on the reported spring phishing campaign before her call with the company's legal adviser. See INC-2026-002. | call notes |
| 2026-08-25 22:30 | Priya | Reset Maria's sign-in cookies, terminating all active sessions. | Google Workspace admin console |
| 2026-08-25 22:35 | Priya | Reset Maria's password and conveyed it to her by phone. Not by email. | call notes |
| 2026-08-25 22:55 | Maria, finance | Enrolled in two-step verification on her own account. Took approximately 20 minutes: no authenticator application installed and the phone was mislaid. Recorded because it is the realistic per-person cost of any wider rollout. | Google Workspace admin console |
| 2026-08-25 23:05 | Priya and Sam Okafor | Reviewed connected applications on Maria's account. Three present. One identified as Xero. Two unrecognised by Maria. Names recorded by Sam. Both unrecognised grants removed by Priya. | Google Workspace admin console. Application names to be captured to `evidence/`. |
| 2026-08-25 23:20 | Priya | Contacted the company's legal adviser. Call ran long. The privilege question was put as an explicit question. | Priya, relayed 2026-08-26 |
| 2026-08-26 08:15 | Priya, relaying the legal adviser | Adviser asked where the security records are held and was firm that they must not be reachable by contractors or by Northwind Digital. Adviser also raised document labelling and directing the work. | Priya, relayed by Sam |
## Affected systems and data

| System | Environment | What the attacker could reach | Confirmed accessed? | Data classes | Customer records in scope | How we know |
| --- | --- | --- | --- | --- | --- | --- |
| Acme bank account, outbound payment | production | 14,000 in a single payment, and any subsequent payments to the same stored vendor record | no, no payment made | none | none | Maria has not paid; payment held pending verification |
| Acme email (Maria's mailbox) | production | the full contents of her mailbox, plus every account that can be password-reset by email to that address, which for this person includes Xero, the banking portal and any payroll system | YES. A filter created by a third party was found in the account on 2026-08-25. The extent of what was read is not yet known. | supplier and internal correspondence, potentially far more | unknown | a mail filter exists in the account that Maria states she did not create |
| Xero, Northwind Digital contact record | production | all future payments to Northwind, not only the one that was stopped | changed, by Maria, acting on the fraudulent instruction. Whether any other party has accessed Xero is unverified. | payment instructions | none | Maria confirmed she saved the new details before deciding not to pay |
| Northwind Digital email | third party | not applicable on current evidence | no evidence of compromise. The lookalike sending domain indicates the attacker did not need access to Northwind's mail. | n/a | n/a | sending domain is a hyphenated lookalike, not Northwind's real domain |
| Acme vendor record for Northwind, in the accounting system and the banking portal | production | all future payments to Northwind, not only this one | not yet known, being checked | payment instructions | none | Maria had a payment screen open; whether the new details were saved to the vendor record is unconfirmed |

Note the difference between "could reach" and "confirmed accessed" and never blur them.

## Identities and credentials in scope

| Identity | Type | Privileges | Rotated? | Rotated at (UTC) | Sessions revoked? |
| --- | --- | --- | --- | --- | --- |
| none identified yet | | | | | |

## Containment actions

| Action | Proposed at (UTC) | Approved by | Executed at (UTC) | Result | Reversible? |
| --- | --- | --- | --- | --- | --- |
| Hold the payment pending an out-of-band callback | 2026-08-25 19:09 | Sam Okafor | 2026-08-25 19:20 | Payment stopped before it was made. | yes, fully |
| Do not reply to the message and do not use any contact detail contained in it | 2026-08-25 19:09 | Sam Okafor | 2026-08-25 19:20 | Complied with. Nothing replied to, nothing deleted. | n/a |
| Preserve the original message with full headers before anyone deletes it | 2026-08-25 19:09 | Sam Okafor | 2026-08-25 19:25 | Original forwarded as an attachment, headers intact. | n/a |
| Move all discussion of the incident off email onto Slack or phone | 2026-08-25 19:40 | Sam Okafor | | | yes, fully |
| Maria to inspect her own mailbox filters, forwarding rules, delegated access and recent sign-in activity | 2026-08-25 19:40 | Sam Okafor | 2026-08-25 20:05 | Malicious filter found and screenshotted. No forwarding, no delegate visible. Nothing deleted. | n/a, read-only |
| Screenshot the Xero vendor record as it stands, revert to the previous bank details, and review the contact's History and Notes | 2026-08-25 20:35 | Sam Okafor | | | yes, fully |
| Maria to action no payment, no bank detail change and no password reset overnight, regardless of apparent sender | 2026-08-25 20:35 | Sam Okafor | | | yes, fully |
| Preserve trash. The filter routes matching mail to trash, so genuine Northwind correspondence may be recoverable there and would establish how long the filter has been active. Gmail purges trash after 30 days, so this evidence has a 30 day clock. | 2026-08-25 20:35 | Sam Okafor | | | n/a, preservation |
| Pull the login history for `admin@acmeanalytics.com` and the `@northwinddigital.com` super admin account. Read-only. Gates the containment below: if either shows a recent sign-in, containment stops and is re-planned, because evicting one intruder while two unattributed admin doors stand open spends the element of surprise for nothing. | 2026-08-25 21:30 | Priya | | | n/a, read-only |
| Reset Maria's sign-in cookies, then reset her password, then have Maria enrol two-step verification herself on the call, then review Connected applications and Application-specific passwords. In that order. | 2026-08-25 20:35 | Priya, authorised on the call of 2026-08-25 | 2026-08-25 22:30 to 23:05 | Completed in order. Two unrecognised connected applications found and removed. Names recorded, not yet assessed. | yes |
| Do NOT change the password alone. On Google a password change does not by itself terminate existing sessions or revoke connected application tokens. Rejected as a partial action. | 2026-08-25 20:35 | rejected by Sam Okafor on the security partner's recommendation | n/a | not done, deliberately | n/a |
| Do NOT enforce two-step verification organisation-wide tonight. Enforcing on a population without warning locks people out of their accounts. Deferred to a staged, announced change. | 2026-08-25 21:30 | deferred by Sam Okafor. This is on the always-ask list and needs its own explicit yes when it is scheduled. | n/a | deferred | n/a |
| Do NOT suspend the unattributed admin accounts or remove the Northwind super admin role tonight. Northwind is reported to hold AWS root and Acme currently has no independent access to that account. Removing an agency's access at night, without a conversation, risks a far larger problem than the one being contained. This is a business decision belonging to Priya, to be taken in daylight. | 2026-08-25 21:30 | deferred by Sam Okafor on the security partner's recommendation | n/a | deferred to 2026-08-26 | n/a |
| Delete nothing. Filter, trash, and the nine Northwind messages are preserved. Preservation now also bears on an open question about customer data. | 2026-08-25 21:30 | Sam Okafor | ongoing | | n/a |

## Eradication and recovery actions

| Action | Owner | Executed at (UTC) | Verification that it worked |
| --- | --- | --- | --- |

## Notification decision

| Audience | Notify? | Reasoning | Deadline or clock | Decided by | Sent at (UTC) |
| --- | --- | --- | --- | --- | --- |
| Affected customers | not yet determined | Unauthorised access to a mailbox is confirmed. Whether personal data of any customer was present in that mailbox is an open question and is being scoped. Whether any notification obligation follows is a determination for counsel, not for the security owner. Note for counsel: Acme's public security page states that affected customers are notified within 24 hours, which may be shorter than any statutory period. | referred to counsel 2026-08-26 | pending counsel | |
| All customers | not yet determined | As above. | referred to counsel 2026-08-26 | pending counsel | |
| Data protection regulator | consult counsel | Unauthorised third-party access to a mailbox belonging to a member of staff is confirmed, over approximately five months. Whether personal data was in scope is not yet established. Notification clocks in this area commonly run from the point of becoming aware rather than the point of confirmation, and Acme became aware on 2026-08-25. The determination belongs to counsel. | referred 2026-08-26, first thing | pending counsel | |
| Sector or national regulator | n/a | | | | |
| Law enforcement | for Priya to decide | Attempted payment fraud with confirmed unauthorised access to a company account. Reporting is normally to the national fraud reporting body. This decision belongs to Priya, with counsel if she wants it, and not to the security owner. | 2026-08-26 | pending Priya | |
| Cyber insurance carrier | yes if a policy exists | Whether Acme holds a policy is unknown (Q17). Most policies require prompt notice, and notice periods commonly run from awareness. | 2026-08-26 | pending Priya | |
| Downstream consumers of anything we publish | n/a | | | | |
| Employees | not yet | If confirmed fraudulent, a short factual note to everyone who can move money is proportionate. Not a company-wide alarm. | after verification | pending Priya | |
| Investors or board | no | | | | |
| Northwind Digital | yes, urgent | A lookalike of their domain has been registered and is being used against their customers. On current evidence their own mail is not compromised, so the value of telling them is that their other customers are very likely being invoiced the same way this week. Contact only via a number or address already on file, never one from the message. Decision on who makes the call belongs to Priya. | first thing 2026-08-26 | pending Priya | |

Do not draft external notification language without agreeing to involve legal counsel first.

## Evidence collected

| Item | Collected at (UTC) | Collected by | Stored at | Hash or size | Retention |
| --- | --- | --- | --- | --- | --- |
| Original message with full internet headers | pending | Maria, via Sam | to be stored in `evidence/` | | retained until the incident is closed and counsel agrees otherwise |

Preserve before you clean up. Nobody deletes the message.

## What we still do not know

- **How the account was accessed, and when it started.** Stolen password, a session token, an application password, or a third-party application grant are all still open. This determines whether a password reset is sufficient. Needs Google Workspace admin sign-in logs, which nobody at Acme currently has available to the security owner.
- **How long the filter has been in place, and what it has been hiding.** The oldest genuine Northwind message sitting in trash gives a lower bound. 30 day clock.
- **Whether any other mailbox at Acme carries a similar rule.** Needs Workspace admin.
- **What else was reachable by password reset from that mailbox.** Xero, the banking portal and any payroll system are the ones that matter, because the account belongs to the person who runs finance.
- Whether the intruder read anything beyond the Northwind thread.
- **What the two removed connected applications were.** Names recorded on 2026-08-25 and not yet assessed. An unrecognised standing application grant on a mailbox is one of the standard ways access survives a password reset. If either held mail scopes it may be the foothold rather than a leftover, and if so containment is not yet complete.
- Whether unrecognised application grants exist on any other account.
- **Whether any account other than Maria's was reached.** A credential phishing campaign is reported to have occurred at Acme in spring 2026 in which "at least one person" entered credentials on a page imitating a Google sign-in screen. That report is second-hand and unverified, and it is being reconstructed separately as INC-2026-002. No relationship between the two has been established and none is asserted. Its material consequence here is that this incident cannot be assumed to be limited to one mailbox. The first job of 2026-08-26 is to search every account's login events for the address observed on Maria's account.
- When `northwind-digital.com` was registered. A recent registration indicates an opportunistic attacker; an older one indicates a patient, targeted campaign and probably other victims.
- Whether any other supplier's bank details have been changed recently.
- Whether Northwind Digital's other customers are being invoiced the same way right now.
- Whether anything beyond this email thread has been reached, in either company.
- Whether anyone else at Acme received the same or a similar message.
- Whether Acme has a written payment verification policy at all, and whether any change of vendor bank details has been made previously without a callback.
- Whether Acme holds cyber insurance.
- Whether Acme has any phone contact for a named individual at Northwind Digital. As of 2026-08-25 the answer appears to be no: all contact runs through a shared support mailbox answered by a different person each time. For a supplier reported to hold root on the AWS account, that is a finding in itself and it is recorded as R-017.

## Postmortem

To be held within five working days of closing. Blameless. Maria did the correct thing by asking before paying, and that should be said explicitly and publicly whatever the outcome.

- Root cause:
- Contributing factors:
- What went well:
- What was slow or painful:
- Detection gap:
- Blast radius gap:

### Action items

| # | Action | Cell | Owner | Due | Status | Risk register ID |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Write the one-page payment verification policy with a mandatory out-of-band callback on any new or changed vendor bank details, and get it signed off. | CS-4 | Sam Okafor | 2026-09-04 | not-started | R-015 |

## Closure

- Closed at:
- Closed by:
