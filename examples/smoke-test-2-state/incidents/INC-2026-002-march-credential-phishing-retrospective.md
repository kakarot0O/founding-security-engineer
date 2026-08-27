**Privileged and Confidential: Prepared at the request of Halloran Vance LLP for the purpose of obtaining legal advice**

---

# INC-2026-002: Retrospective review of a reported credential phishing campaign in spring 2026

**This is a retrospective review of an event reported to have occurred before the security owner joined. It is not a live incident. It is opened on 2026-08-25 and dated with today's date, and every entry states clearly what is confirmed and what is not.**

**Relationship to INC-2026-001 is NOT established.** The two are recorded separately and deliberately. Merging them would assert a causal link that has not been evidenced. If the link is later established, that is recorded as a dated finding with its evidence, not assumed here.

- Declared by: Sam Okafor
- Declared at: 2026-08-25 22:10 UTC
- Detected at: not applicable. The event is reported to have occurred in spring 2026. No date has been established.
- Detected by: reported second-hand to Sam Okafor in conversation on approximately 2026-08-22, his second day, by a member of the data team. Not reported through any channel, because no channel exists (R-016).
- Severity: unassigned
- Incident commander: Sam Okafor
- Scribe: Sam Okafor
- Current status: scoping
- Last updated: 2026-08-25 22:10 UTC
- Communication channel: not established. Discussion is off email while INC-2026-001 is open.

## Summary

Sam Okafor was told informally, on approximately 2026-08-22, that at some point in spring 2026 a number of people at Acme received a phishing email leading to a page imitating a Google sign-in screen, and that at least one person entered their credentials on it. The account is second-hand and was given in a social setting rather than as a report. The following are not known: the date, the number of recipients, the identity of anyone who entered credentials, whether anyone reported it at the time, and whether anyone looked into it. No incident was declared at the time and no record of any investigation has been located.

This review was opened on 2026-08-25 because the earliest unauthorised sign-in observed on Maria's account during INC-2026-001 is dated 2026-03-17, and a credential phishing campaign in the same period is a plausible source of a working password. Plausible is the correct word and the only one available. No link has been established and none is asserted here.

The material consequence for INC-2026-001 is that the reported phrasing was "at least one person", which is not the same as "one person". The number of Acme accounts that may hold compromised credentials from that campaign is unknown, so INC-2026-001 cannot be assumed to be limited to a single mailbox.

## Method, and why the order is what it is

Artifacts are reconstructed before any person is interviewed. This ordering is for evidence quality, not politeness. Asking people first causes recollection to become reconstruction, causes separate accounts to converge into one shared story, and gives anyone embarrassed by their part in it an opportunity to tidy up. None of those things happen to a log.

People are approached only after the artifact timeline exists, and then with specific dated questions rather than open ones.

The single exception taken on 2026-08-25 was briefing Priya, before she contacted the company's legal adviser, on the basis that counsel advising without this fact would be advising on incomplete facts. That is a briefing, not an interview.

## Artifact timeline

Nothing is entered here that has not been read from a source. Retention window is recorded before each source is queried, because for an event several months old the log may already have aged past the relevant period, and that is itself a fact worth recording.

| Time (UTC) | Actor | Event or action | Evidence |
| --- | --- | --- | --- |
| approx 2026-08-22 | member of the data team | Told Sam Okafor informally that a phishing email in the spring led to a fake Google sign-in page and that at least one person entered credentials. No date, no names, no numbers given. | verbal, second-hand, unverified |
| 2026-08-25 22:10 | Sam Okafor | Connected the report to the 2026-03-17 date observed in INC-2026-001 and opened this retrospective review. | this file |
| 2026-08-25 22:15 | Sam Okafor | Briefed Priya on the reported campaign before her call with the company's legal adviser, stating explicitly that it is second-hand, undated, unverified and possibly unrelated. | call notes |

## Sources to reconstruct from, in order, none yet queried

| Source | Retention window | Queried? | What it would establish |
| --- | --- | --- | --- |
| Google Workspace login events, all accounts | unknown, to be recorded before querying | no | Sign-ins from unfamiliar addresses across the domain in the March period. The single highest-value query available. |
| Google Workspace login events filtered to the address observed on Maria's account | as above | no | Whether any account other than Maria's was reached by the same party. Queued as the first job of 2026-08-26. |
| Chat history in the main company channels around March | unknown | no | Whether anyone warned colleagues at the time, which would date the campaign. |
| Mailboxes, for the original phishing message | n/a | no | The lure, the fake domain, and the recipient list. |
| Gmail filters and forwarding rules across all mailboxes | n/a | no | Whether the artifact found on Maria's account exists elsewhere. Method not yet chosen. |

## What is confirmed and what is not

**Confirmed:** nothing yet. This file currently contains one second-hand verbal account and one date drawn from a separate incident.

**Not confirmed, and to be treated as open rather than as fact:** that a phishing campaign occurred; its date; how many people received it; that anyone entered credentials; who; whether any account was accessed as a result; and whether any of it relates to INC-2026-001.

## Notification decision

No determination has been made and none is the security owner's to make. Priya was briefed on 2026-08-25 and contacted the company's legal adviser the same evening. Whether this review should be conducted under legal privilege, and how it should be structured and documented, was put to that adviser as an explicit question. The answer, when received, is recorded in `DECISION-LOG.md`.

## Control gaps this has already exposed

These are the durable value of the exercise, they are safe to record, and they are true regardless of what the reconstruction finds.

| # | Gap | Risk register row |
| --- | --- | --- |
| 1 | An event that people talked about openly was never reported, never triaged and never recorded, because there is no reporting channel and no stated rule that raising something is safe. | R-016 |
| 2 | Second-factor authentication is not enforced, so a harvested password is sufficient to sign in. | R-020 |
| 3 | No detection exists for a sign-in from an unfamiliar location, so five months of intermittent access produced no alert. | DR-2, row to be opened |
| 4 | No log retention window is known for any source, so the size of the evidence window for a five-month-old event is itself unknown. | DR-3, DR-0 |

## Closure

- Closed at:
- Closed by:
