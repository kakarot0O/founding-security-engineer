# CS-4: Workplace security

> **Grid coordinate:** CS-4, Corporate Security, cell 4.
> **Original 2019 wording:** "Workplace security" (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019, slide 18).
> **Load when:** the human asks about the office, badges, visitors, wifi, laptop shipping, hardware disposal, travel, remote work security, phishing simulations, wire fraud, business email compromise, deepfake or voice-cloned finance requests, USB drops, tailgating, or insider risk. Also load when CS-3 (onboarding and offboarding) surfaces a physical or payment step that needs an owner, and when the finance or people team asks "is this request real?"

## Why this cell exists

Every other cell in this grid assumes the attacker comes through a network. This cell covers the attacker who walks through a door, mails a package, or simply sends your finance lead a convincing email. For a startup between twenty and one hundred people, the single most financially damaging attack is not a breach of your product. It is someone tricking a human into wiring money to the wrong bank account, and that attack has nothing to do with your code.

The 2019 version of this cell meant a physical office: badges, a visitor log, and a server closet. In 2026 most startups are hybrid or fully distributed, so "the workplace" is a coworking desk, a kitchen table, an airport lounge, and a Slack or Teams channel. Both realities are real and both need a plan, so this file covers physical, distributed, and people risk separately. Treat all three as the same domain because they share one root cause: a person, in a physical or social context, making a trust decision without a rule to lean on.

## Definition of done

Good enough for a twenty to one hundred person startup:

- [ ] **A written payment verification policy** exists, is signed off by the CEO or CFO, and every person who can initiate or approve a payment has read it. It includes an out-of-band callback rule for any new or changed bank details, with no exceptions for urgency or seniority.
- [ ] **Bank detail changes require a callback to a phone number already on file**, never a number supplied in the request itself, and the callback is logged.
- [ ] **Office physical access (if an office exists) is tied to offboarding.** Badge or door code revocation is a line item in the offboarding checklist in CS-3, with a named owner and a same-day deadline.
- [ ] **Guest wifi is a separate network from anything corporate**, with a rotating or captive-portal password, and no route to any internal system.
- [ ] **Network gear and any physical infrastructure has default credentials changed**, with the new credentials in the company password manager, not on a sticky note.
- [ ] **A hardware inventory exists**: every company-owned laptop, phone, and external drive has an owner, a serial number, and a state (issued, in transit, returned, wiped, disposed). A spreadsheet is acceptable.
- [ ] **Laptops shipped to remote hires arrive enrolled in device management** and require the new hire to authenticate through the identity provider before use, so an intercepted package is a paperweight rather than an access grant.
- [ ] **Devices leaving the company are wiped with a verified method** and the wipe is recorded with a date and an operator name.
- [ ] **A short travel guidance page exists** covering laptop custody, public wifi, and what to do if a device is taken from you at a border or lost.
- [ ] **A "how to report something weird" path exists** and every employee knows it, tied to the DR-4 company communication channel.

Explicitly **not required** at this size: a badge system with anti-passback and photo credentials, a security guard, mantraps or turnstiles, a formal clean desk audit programme, an insider threat monitoring platform, user behaviour analytics, a mandatory monthly phishing simulation, a data loss prevention deployment, or ISO 27001 Annex A physical control evidence unless a customer contract already demands it (check CO-3 for existing commitments before assuming it does).

## Discovery

Most of this cell is not discoverable from a terminal. It lives in people's heads, in a facilities email thread, and in the finance team's habits. Start with the few things you can query, then move to interviews.

**Do you even have an office?** Check the company handbook, the website careers page, and the expense system for a rent or coworking line item. If the answer is "we have a WeWork membership and three people use it", the physical section shrinks to badge revocation and clean desk, and you should spend your time on the people and distributed sections instead.

**Device inventory, branched by mobile device management (MDM) platform.** MDM is the software that lets you configure, lock, and wipe company laptops centrally. See `cs-2-endpoint-security.md` for the full treatment. For workplace purposes you only need the roster:

- Apple-first shops using Jamf, Kandji, Mosyle, or Apple Business Manager: read the device list in the admin console. Apple Business Manager at `business.apple.com` shows every device assigned to your organisation with serial numbers, which is the authoritative shipping and disposal record.
- Cross-platform using Microsoft Intune: Microsoft Intune admin center, Devices, All devices. Export to CSV for the inventory.
- Google Workspace with ChromeOS or Google endpoint management: Google Admin console, Devices, Chrome devices or Mobile devices. Export the list.
- Fleet, Rippling, JumpCloud, Hexnode, or similar: same idea, export the device list from the admin console.
- No MDM at all: this is common and it is the finding. Record it in `SECURITY-STATE.md` under CS-2 as well as CS-4, and build the inventory from the purchasing records instead. Ask finance for every laptop purchase in the last three years.

**Physical access system.** Ask, do not guess. Common answers: a smart lock app (Brivo, Kisi, Openpath, Latch, SALTO), a building landlord's badge system that you do not control, a keypad with one shared code, or physical keys. Each has a different revocation story and the shared-code case is the one that quietly fails at offboarding.

**Network gear.** If there is an office network you control, find out who owns it. Do not probe it and do not probe the office public address. There is no read-only command you can run from your own laptop that tells you anything true about someone else's router, and any command that would is an active scan, which requires written authorisation from the network owner (see Danger zone).

Instead, ask whoever administers the office router to read back three things from the admin console while you watch, over a screen share or standing next to them:

1. Whether the default administrator password was changed, and where the current one is stored. The correct answer is the company password manager.
2. Whether remote administration from the wide area network (WAN) side, meaning the internet-facing side of the router, is disabled.
3. The current firmware version, and whether automatic firmware updates are on.

Write the three answers and the date into `SECURITY-STATE.md`. If the administrator cannot answer one of them, record that item as `unknown` rather than guessing, and put "office router configuration unverified" in `RISK-REGISTER.md` with the administrator as the owner.

If the office is a coworking space, you do not control the network at all, and that is the important finding: treat the office wifi as hostile public wifi and make sure every laptop is fine with that.

**Finance process.** This is the highest value discovery in the whole cell. Ask the finance lead to walk you through, out loud, exactly what happens when a vendor emails to say their bank details changed. Do not ask "do you have a verification process". Ask them to narrate the last time it happened. The gap between the policy and the narration is your risk.

**Phishing and reporting history.** Search the chat platform for prior reports. In Slack, use the search bar for `phishing`, `is this real`, `suspicious email`. In Microsoft Teams, use the search bar for the same terms. Read the threads. They tell you what your people already fall for and whether reporting is socially safe.

**When you have no access at all.** This is the normal starting state for a first security hire in week one. Do not stall. Every item in this cell can be started from a conversation. Write the payment verification policy draft, the travel checklist, and the office offboarding checklist from this file with sensible defaults, then use them as the artifact you bring to the finance and people leads to get corrected. A draft someone can red-pen gets you further in one meeting than three weeks of access requests.

## Ask the human

Closed questions, in priority order. Ask two or three at a time, not all at once.

1. Is there a physical office, a coworking membership, or neither?
2. If there is an office, who controls door access, and can you name the system?
3. When someone leaves, who removes their door access, and has that ever been missed?
4. Is the guest wifi a separate network from the one staff use, yes or no, and do you know the password?
5. Is there a room with servers, network gear, or spare laptops, and is it locked?
6. Who at this company can move money, and how many people must approve a payment above a threshold?
7. Has anyone here ever received a fake invoice, a fake bank detail change, or a fake CEO request for a wire or gift cards?
8. When a new remote hire is onboarded, who ships the laptop, and does it arrive already enrolled in device management?
9. What happens to a laptop when someone leaves: does it come back, and who wipes it?
10. Has the company ever run a phishing simulation, and if so, how did people react?
11. Does anyone travel to a country where the company or the customers would consider device seizure a real risk?

Copy-pasteable message to the finance or operations lead:

```
Hi, I am working through our security basics and finance process is one of
the highest-value places to start. The most common attack on companies our
size is not a hack, it is someone impersonating a vendor or an executive to
redirect a payment. I would like 25 minutes to do two things:

1. Have you walk me through what actually happens today when a vendor emails
   to say their bank details changed, and what happens when a payment request
   comes in marked urgent from someone senior.
2. Agree a one-page verification rule we both sign off on, so you have
   something to point at when a request feels off and you do not have to make
   the judgement call alone.

I am not auditing you. The goal is that you get a rule to lean on instead of
having to guess. When works this week?
```

Copy-pasteable message to whoever owns the office or facilities:

```
Hi, I am putting together our physical and workplace security baseline. Can
you help me with four short answers?

1. What system controls the office doors, and who has admin access to it?
2. When someone leaves the company, who removes their door access and how
   quickly does that normally happen?
3. Is our guest wifi on a separate network from the one employees use?
4. Is there a locked room or cabinet with network gear, servers, or spare
   laptops, and who has the key?

If the answer to any of these is "I am not sure", that is genuinely fine and
useful to know. I would rather have an accurate picture than a tidy one.
```

## The walk

Ordered so that step 1 delivers value on day one, before you have any access to anything.

**Step 1: Write the payment verification policy.**
- **Goal:** Remove the judgement call from the single most financially damaging attack on companies your size. Business email compromise is the attack where someone impersonates a vendor, an executive, or a payroll provider to redirect money, and it costs small companies more than any technical breach.
- **Do:** Draft a one-page policy using the template in the Decision points section below. Take it to the finance lead and the CEO for edits. Get it signed off in writing (a Slack or Teams message from the CEO saying "approved" is sufficient evidence at this stage).
- **Verify:** The policy exists in the company wiki or shared drive, the finance lead can restate the callback rule in their own words without reading it, and the CEO has said in writing that they will never be exempt from it.
- **Time:** Half a day to draft, one meeting to agree, one week of chasing for sign-off.
- **Who else is needed:** Finance lead or the person who pays invoices, plus the CEO or CFO for authority.

**Step 2: Get the CEO to pre-commit publicly.**
- **Goal:** Kill the "the CEO said it was urgent so I skipped the check" failure mode before it happens. This control costs nothing and prevents the most common variant of the attack.
- **Do:** Ask the CEO to post a short message in the main company channel saying, in their own words, that they will never ask anyone to move money, buy gift cards, or change bank details over chat or email without a verification call, and that anyone who slows down such a request has their full backing.
- **Verify:** The message is posted, pinned, and linked from the payment policy.
- **Time:** Fifteen minutes of your time, one message from the CEO.
- **Who else is needed:** The CEO personally. It does not work if you post it on their behalf.

**Step 3: Add the callback verification rule for voice and video.**
- **Goal:** Cover the 2026 version of the attack where the "CEO" is a cloned voice on a call or a synthetic face on a video meeting. Voice and video are no longer proof of identity, and your finance team needs to be told that explicitly.
- **Do:** Add to the payment policy: any request to move money, change bank details, or share credentials that arrives by voice call or video call is verified by hanging up and calling back on the number already stored in the company directory or the human resources system, or by messaging the person in the internal chat platform and waiting for a reply. Never verify using contact details supplied in the request. Add one agreed challenge question or shared phrase for the small group who can move money, kept out of email.
- **Verify:** Ask the finance lead the scenario question out loud: "The CEO video calls you, looks right, sounds right, and asks you to push a payment today because a deal is closing. What do you do?" The correct answer names the callback. If they hesitate, the rule is not internalised yet.
- **Time:** One hour to write, one team meeting to walk through.
- **Who else is needed:** Everyone who can initiate or approve a payment, including executive assistants.

**Step 4: Build the hardware inventory.**
- **Goal:** You cannot revoke, wipe, or ship what you cannot list. This is also the artifact every future auditor and enterprise customer asks for.
- **Do:** Create a single sheet with columns: serial number, device type, assigned person, issue date, MDM enrolled (yes or no), state (issued, in transit, returned, wiped, disposed), and disposal date. Populate it from the MDM export if one exists, and from the purchasing records and a company-wide "reply with the serial number of every company device you hold" message if not. On macOS, a person can find their serial with the Apple menu, About This Mac. On Windows, run `Get-CimInstance -ClassName Win32_BIOS | Select-Object SerialNumber` in PowerShell. This is read-only. Do not use the older `wmic` command: Windows Management Instrumentation Command-line (WMIC) is deprecated and is not installed by default on recent Windows 11 builds, so the instruction fails for exactly the newest machines you most want in the inventory.
- **Verify:** The count of devices in the sheet matches the count of devices in the MDM console, or the difference is explained line by line. Unexplained gaps are the finding.
- **Time:** One to three days depending on company size and record quality.
- **Who else is needed:** IT or operations, finance for purchase records, and every employee for one reply.

**Step 5: Close the office offboarding gap.**
- **Goal:** Physical access outliving employment is one of the most common and most embarrassing audit findings, and it is cheap to fix.
- **Do:** Add a physical block to the offboarding checklist owned by CS-3: revoke badge or door code, collect keys, collect the laptop and any external drives, collect any hardware security key that belongs to the company, remove the person from the visitor and delivery notification list, remove them from the office door system's admin group if they had one, and update the hardware inventory state. Assign each line a named owner and a same-day deadline. Link the checklist from `cs-3-onboarding-offboarding.md` so there is one canonical list, not two competing ones.
- **Verify:** Pick the two most recent leavers. Confirm in the door system that their access is actually removed, not just marked removed in a spreadsheet. Screenshot the door system showing the revocation and attach it as evidence.
- **Time:** Half a day to write, one hour to verify against past leavers.
- **Who else is needed:** People operations or whoever runs offboarding, plus office manager for the physical collection.

**Step 6: Split guest wifi from corporate wifi (office only).**
- **Goal:** A visitor, a contractor, or a compromised phone on the guest network should not be able to reach anything the company owns. This is a twenty minute change with a large blast-radius reduction.
- **Do:** In the router or access point admin interface, confirm there is a separate guest network with client isolation enabled and no route to internal ranges. If the office network is run by the building or a coworking provider, you cannot change it, so instead confirm that no company system is reachable only via the office network, and that every laptop assumes the local network is hostile.
- **Verify:** From a device on the guest network, attempt to reach an internal address the human names. Failure to connect is the pass condition. Ask the human to run the test and confirm the result. Do not scan the network without written authorisation.
- **Time:** Half a day including scheduling.
- **Who else is needed:** Whoever administers the office network, or the coworking provider's support contact.

**Step 7: Write the travel and public wifi guidance.**
- **Goal:** Give travelling employees a short, realistic set of rules they will actually follow, instead of a policy that assumes a corporate virtual private network and a security team on call.
- **Do:** Write a single page using the travel checklist in Decision points below. Keep it under one screen. Publish it where people will find it, which is usually the same place as the expense policy.
- **Verify:** Ask one person who travels regularly to read it and tell you which line they would ignore. Rewrite that line.
- **Time:** Half a day.
- **Who else is needed:** One frequent traveller for a reality check, people operations to publish it.

**Step 8: Fix laptop shipping to remote hires.**
- **Goal:** A laptop in a courier's hands is out of your control for several days. It should arrive useless to anyone except the intended person.
- **Do:** Ensure that every shipped laptop is enrolled in the device management platform before it leaves, that disk encryption is enforced by policy rather than left to the user (FileVault on macOS, BitLocker on Windows, both are free and built in), and that the first login requires authenticating to the identity provider. Never ship credentials, a temporary password, or a hardware security key in the same package as the laptop. Send the enrolment or activation details through a separate channel to the person's personal contact detail on file, and require them to confirm receipt by a method other than the one you sent it on.
- **Verify:** Do one test shipment or, cheaper, factory reset a spare machine and walk through the first-boot flow yourself. Confirm you cannot get to a desktop without an identity provider login.
- **Time:** One to two days, mostly waiting on the device management side.
- **Who else is needed:** IT or operations, and whoever handles new hire logistics.

**Step 9: Write the disposal and wipe procedure.**
- **Goal:** Old laptops and drives leave the building with customer data on them more often than anyone expects, usually through a well-meaning donation or an employee buyback.
- **Do:** Rule: no device leaves company ownership until it has been wiped and the wipe recorded. On modern Apple silicon and T2 Macs, "Erase All Content and Settings" in System Settings is cryptographically sound because the storage is always encrypted and the key is destroyed. On Windows with BitLocker enabled, a reset with the "remove files and clean the drive" option is acceptable. On Linux, destroy the LUKS header and reinstall, or physically destroy the drive. If a device cannot be verified as wiped, physically destroy the drive or pay a certified disposal vendor and keep the certificate. Record the wipe date, operator, and method in the hardware inventory.
- **Verify:** Boot the wiped device. It should come up at the out-of-box setup screen with no company data and, if device management enrolment is enforced, it should still be locked to the organisation. Screenshot it.
- **Time:** Half a day to write, twenty minutes per device thereafter.
- **Who else is needed:** IT or operations.

**Step 10: Decide on phishing simulation, and if yes, run it the non-destructive way.**
- **Goal:** Measure and improve real reporting behaviour without teaching your colleagues that the security person sets traps for them. At under one hundred people, trust is your only real asset and it is easy to spend it here.
- **Do:** See the decision rule below. If you run one, announce beforehand that simulations will happen at some point during the quarter, never name or shame individuals, never use a lure that touches compensation, bonuses, layoffs, immigration status, or bereavement, measure the report rate rather than the click rate, and thank every reporter publicly and every clicker privately with a single non-judgemental sentence.
- **Verify:** Report rate is your primary number. A rising report rate is success. A falling click rate with a flat report rate means people are ignoring email, not reporting it, which is a worse outcome.
- **Time:** One day to configure, one week to run, half a day to write up.
- **Who else is needed:** The CEO or people lead must approve the lure text in advance. This is not optional.

## Decision points

**Should you run phishing simulations at all at this size?**
DEFAULT: no, not in your first ninety days. Below roughly fifty people, spend that effort on the payment verification policy and a working reporting channel instead. The measured benefit of simulation is small compared to the political cost for a new security hire with no relationship capital. What changes this: a customer contract or an insurance policy explicitly requires simulated phishing, a real phishing incident has already occurred, or you have crossed roughly one hundred people and inbound social engineering is regular. When you do start, use what you already own: Microsoft Defender for Office 365 Attack Simulation Training is included with Microsoft 365 E5 or the equivalent add-on, Google Workspace has no native equivalent so you would need a third-party tool. Paid tools sit in the range of roughly three to seven dollars per user per year at startup scale for the cheaper vendors, and up to twenty-five to forty dollars per user per year for the well-known platforms. Try the built-in option first.

**The payment verification policy, recommended default text.**
Adapt the thresholds to the company's actual payment sizes, but keep the structure:

1. Any new vendor bank account, or any change to an existing vendor's bank account, requires a callback to a phone number already stored in the vendor record before payment. Never a number from the request. The callback is logged with date, number called, and person spoken to.
2. Any payment above an agreed threshold requires two people: one initiator and one approver, who must be different humans. Set the threshold low enough that it catches real risk and high enough that it does not block a coffee order.
3. Any request marked urgent, confidential, or "do not tell anyone yet" is treated as suspicious by default, regardless of who appears to have sent it.
4. Requests arriving by voice call or video call are verified by callback or by internal chat message to the person's known account. Voice and appearance are not proof of identity.
5. Nobody, including the CEO and the founders, is exempt. Slowing a payment down to verify it is never punished.
6. Gift card purchases requested over chat or email are always fraud. There is no legitimate version of this request.

**Do you need an office network you control?**
DEFAULT: no. For a startup under one hundred people, an office network you have to secure is a liability with no upside. Prefer coworking or landlord-provided internet, treat it as hostile, and push all the security onto the endpoint and the identity layer where it belongs. What changes this: you have physical hardware that must live on premises (a lab, test devices, hardware you build), or a customer contract requires network segregation. If you do run one, change the default credentials, put guest on a separate network with client isolation, disable remote administration from the internet, and keep the firmware current.

**Should employees be told what to do about their home networks?**
DEFAULT: give two lines of guidance, not a policy. "Change your router's default admin password, and keep its automatic updates on." Anything more is unenforceable and will be ignored, which trains people that your guidance is optional. The security model for remote work must not depend on the home network being trustworthy. If your architecture requires a trusted home network, that is an architecture finding, not a home network finding, and it belongs in the risk register.

**Standard travel versus high-risk travel.**
DEFAULT for standard travel: normal laptop, full disk encryption on, device management enrolled, screen lock at one minute, laptop never checked into hold luggage, never left in a hotel room unattended if it contains customer data, and a privacy screen filter for anyone who works on planes (they cost roughly twenty to sixty dollars and are the cheapest control in this entire file). Use the phone's mobile hotspot rather than airport or hotel wifi where practical. A virtual private network is optional at this stage: nearly all traffic is already encrypted in transit, so a consumer virtual private network mostly shifts who can see your metadata rather than eliminating the risk.
DEFAULT for high-risk travel (destinations where device seizure or compulsory inspection is a realistic concern, or where the company or its customers are of specific interest): issue a clean loaner laptop and a clean phone with no historical data, no stored credentials, and no persistent sessions. Re-issue credentials on return and wipe the loaner. Decide the destination list with the CEO and legal counsel, not unilaterally, because it has employment and diplomatic implications. Record the decision and the list in `DECISION-LOG.md`.

**Insider risk at a size where everyone knows everyone.**
DEFAULT: no monitoring tooling, no user behaviour analytics, no keystroke logging. At under one hundred people, surveillance destroys more value than it protects. What you do instead is structural: least privilege in the identity provider (see `cs-1-identity-and-access.md`), same-day offboarding (see `cs-3-onboarding-offboarding.md`), audit logging that exists and is queryable (see `dr-3-logging-consumption-model.md`), and a two-person rule on the highest-consequence actions such as moving money and deleting production data. The honest framing for leadership is that you are protecting people from being wrongly suspected as much as you are detecting wrongdoing, because a clean audit trail exonerates far more often than it accuses. What changes this: a specific credible concern about a specific person, which is a legal and human resources matter first, and you should not act alone.

## Danger zone

Every item here requires an explicit human yes before you act. State the risk out loud and wait.

- **Revoking physical access.** STOP. Getting this wrong locks a current employee out of the building, potentially at night or alone. Confirm the person's employment status with people operations in writing before revoking, and confirm the door system does not fail closed on the whole office when you edit a group.
- **Changing office network configuration or rebooting network gear.** STOP. This takes the entire office offline, including anyone on a customer call. Only during an agreed window, only with the person who administers it present, and only with a rollback plan and physical access to the device.
- **Scanning or probing an office network.** STOP. If the office is a coworking space or landlord-provided, scanning is very likely a violation of their acceptable use policy and can get the company evicted from the network or the space. Get written authorisation from whoever owns the network. Never scan a network you do not own.
- **Running a phishing simulation without executive approval of the lure text.** STOP. A lure referencing bonuses, layoffs, equity, visas, or a family emergency will cause real distress and can become a human resources or legal matter. It has ended security hires' credibility permanently. Get the exact text approved in writing.
- **Wiping a device.** STOP. Verify the device is not currently in use and that the owner has nothing unbacked-up on it. A remote wipe on the wrong serial number destroys someone's work and your relationship with them in one click. Read the serial number back to the human and get a yes.
- **Blocking or restricting personal device access to company chat or email.** STOP. This can cut people off from work mid-day, including on-call engineers. Announce, stage it, and give an exception path.
- **Confiscating or imaging an employee's device during a suspected insider incident.** STOP. This has employment law implications that vary by country and can invalidate the evidence if done wrong. Legal counsel and people operations lead, not you.
- **Publishing an office address, floor plan, or delivery process externally.** STOP. Check with the people team, particularly if anyone at the company has a personal safety concern.

## Do not do this yet

- **A formal physical security standard mapped to a framework.** Nobody is asking. When they do, it will be one line in a questionnaire and CO-2 has the answer.
- **Badge systems with photo credentials, anti-passback, or visitor kiosks.** Thousands of dollars to solve a problem you can solve with a door code you actually rotate and a person at the front who knows everyone's face.
- **A data loss prevention deployment.** Extremely high false positive rate, extremely high configuration cost, and it will make you the person who blocks people from doing their jobs in your first quarter.
- **Employee monitoring or productivity tooling.** It will be read as surveillance, it will leak into the recruiting reputation, and it does not detect the attacks in this file.
- **A camera system, unless you have physical inventory worth stealing.** It generates footage retention and privacy obligations you then have to manage.
- **Company-wide mandatory security awareness training in month one.** Nobody remembers it and it burns your only shot at people paying attention. Spend that attention budget on the payment verification rule, which is the one lesson that pays for itself.
- **A clean desk audit programme.** In a distributed company it is close to meaningless. One line of guidance about screen privacy in coworking spaces is proportionate.

## Evidence to capture

Write these into the state files as you go. Use the exact locations named.

- `SECURITY-STATE.md`, section **CS-4 Workplace security**: one row per sub-area (physical access, guest wifi, network gear, hardware inventory, shipping, disposal, travel guidance, payment verification, phishing simulation, insider risk posture), each with a status of unknown, none, partial, or done, plus the evidence link or screenshot filename and the date checked.
- `RISK-REGISTER.md`: one entry per open gap. The three most likely to appear are "no out-of-band verification on vendor bank detail changes", "former employees may retain physical access", and "no verified wipe before device disposal". Each entry needs an owner (usually finance, operations, or people, not you), a severity, a decision, and an accepted-by name if leadership chooses to accept the risk.
- `DECISION-LOG.md`: the dated decision on whether to run phishing simulations and why, the high-risk travel destination list and who approved it, the payment approval threshold and who set it, and the decision not to deploy monitoring tooling with the reasoning.
- `ACCESS-LOG.md`: your requests for the device management console, the door access system, the office network administration, and the finance system, with dates requested, granted, or denied.
- `90-DAY-PLAN.md`: the CS-4 line items you have scheduled, and explicitly the ones you have deferred past day ninety so that nobody thinks you forgot them.

Artifacts a future auditor or enterprise customer will ask for by name: the asset or hardware inventory, the media disposal and sanitisation procedure with wipe records, the physical access revocation evidence for recent leavers, the visitor handling process if an office exists, the acceptable use and travel guidance, and the payment authorisation policy. Write each once, keep it current, and reuse it in the CO-2 questionnaire knowledge base rather than answering from scratch every time.

## Cost and effort

- Payment verification policy and CEO pre-commitment: half a day of writing, one meeting. Zero dollars. Highest return per hour in this entire file.
- Hardware inventory from scratch: one to three days. Zero dollars using a spreadsheet.
- Office offboarding checklist and verification against past leavers: one day. Zero dollars.
- Guest wifi separation: half a day if you control the network, zero if you do not. Zero dollars on existing hardware, roughly one hundred and fifty to four hundred dollars if the office needs a decent access point.
- Travel and remote guidance page: half a day. Zero dollars, plus roughly twenty to sixty dollars per privacy screen filter for frequent travellers.
- Shipping and enrolment fix: one to two days of your time, dependent on device management being in place (costed in CS-2, typically three to eight dollars per device per month).
- Disposal procedure: half a day to write. Certified disposal vendors typically charge in the tens of dollars per device, and free options exist if you can verify the wipe yourself.
- Loaner devices for high-risk travel: only buy when the destination list justifies it. One refurbished laptop and one cheap phone, roughly five hundred to nine hundred dollars total, shared across the company.
- Phishing simulation: zero if you use a Microsoft 365 licence you already pay for, otherwise roughly three to forty dollars per user per year. Defer.

Total realistic effort for a defensible CS-4 baseline: five to eight working days spread across a quarter, with almost all of the dollar cost optional.

## 2026 notes

Four things changed since the 2019 slide.

**The workplace stopped being a place.** In 2019 this cell was a facilities conversation. In 2026 most of the risk has moved onto the laptop, the identity provider, and the person's judgement, which means CS-4 now overlaps heavily with CS-1 and CS-2. Treat the physical office as a nice-to-have hardening layer and put your effort into the controls that work whether the person is in an office, a cafe, or an airport.

**Synthetic voice and video broke a verification method people relied on for decades.** A short sample of a public voice is enough to produce a convincing clone, and live video impersonation on calls has moved from research demonstration to documented fraud, including multi-participant fake meetings used to authorise large transfers. The practical consequence is narrow and important: recognising a face or a voice on a call is no longer evidence of identity for any request involving money, credentials, or access. The callback rule is not paranoia, it is the replacement for a check that used to work.

**Vendor and invoice fraud scaled up with generative text.** The old tells (bad grammar, odd formatting, generic greeting) are gone. Assume every phishing and invoice fraud attempt your team sees is fluent, correctly branded, contextually aware of your actual vendors, and often threaded into a real email conversation after a supplier's mailbox was compromised. This is why process controls beat detection controls here: you cannot train people to spot a message that is indistinguishable from a real one, but you can give them a rule that does not depend on spotting it.

**The USB drop is mostly dead, and the shipped-device and QR code attacks replaced it.** Modern operating systems and device management make a dropped USB drive a poor delivery mechanism, and it does not work at all against a distributed workforce. The equivalents that do work are malicious QR codes replacing legitimate ones in offices and on printed material, unsolicited hardware sent to employees as a gift or a conference prize, and the interception of legitimately shipped equipment. Guidance is simple and cheap: never plug in hardware the company did not send you, and treat a QR code the same way you treat a link in an email.

## Failure modes

**The policy exists but nobody uses it under pressure.**
Early tell: the finance lead can find the policy but cannot restate the callback rule from memory, or they say "well, in that case I would probably just check with the CEO". Recovery: run the scenario out loud in a meeting rather than sending the document again. Repetition of a spoken scenario beats another wiki page. Add the rule as a pinned message in the finance channel.

**The CEO exempts themselves.**
Early tell: someone says "that rule is for everyone except obviously the founders". Recovery: this is a partner-mode moment and you should disagree out loud. Explain that the CEO exemption is the exact attack, since the attacker will always impersonate the person nobody dares to slow down. Ask the CEO to state the rule applies to them, in the company channel, in their own words. If they refuse, log it in `RISK-REGISTER.md` with their name in the accepted-by field and move on. Do not fight it twice.

**Badge or door code revocation silently fails.**
Early tell: offboarding is marked complete in the tracker but nobody has an access system screenshot. Or worse, the office uses one shared door code that has never been rotated, so "revoking" access is meaningless. Recovery: verify against the door system for the last two leavers, not the tracker. If it is a shared code, rotate it now and set a rotation on every departure, and put replacing it with per-person access in the backlog.

**The hardware inventory goes stale within a quarter.**
Early tell: a new hire started three weeks ago and their laptop is not in the sheet. Recovery: the inventory must be updated by the same process that issues and collects devices, not by a periodic audit. Make the sheet update a line item in the onboarding and offboarding checklists in CS-3 with a named owner. If you are updating it yourself, it will rot.

**Phishing simulation destroys trust.**
Early tell: someone posts publicly that the exercise felt like a trap, or reporting volume drops after the exercise rather than rising. Recovery: apologise directly and specifically, name what was wrong with the lure, stop the programme, and rebuild by making reporting rewarding for a full quarter before trying again. Never defend the exercise on the grounds that real attackers would do worse. It is true and it does not help.

**Nobody reports anything, and you read that as safety.**
Early tell: zero suspicious message reports in three months at a company of sixty people. That is not a clean environment, that is a broken reporting path. Recovery: check the DR-4 channel actually exists, is discoverable, and is monitored. Seed it yourself by forwarding one real suspicious message and thanking the next person who does. Reporting volume is a health metric, so track it in `05-metrics-and-comms.md` and expect it to go up, not down.

**Wiped devices were not actually wiped.**
Early tell: a returned laptop still shows the previous user's account at the login screen, or a disposal batch has no dated wipe records. Recovery: recall what you can, verify each device by booting it, and record the ones you cannot account for as an open risk with a data exposure assessment. If a device with customer data left unwiped, that is potentially a notifiable event, so read `co-4-data-inventory-and-framework.md` and involve legal counsel before deciding it is not.

## Related cells

- [CS-1: Identity and access management](cs-1-identity-and-access.md), because door access, device enrolment, and payment approval all resolve back to who a person is.
- [CS-2: Endpoint security](cs-2-endpoint-security.md), for device management, disk encryption, and the controls that make a shipped or stolen laptop safe.
- [CS-3: Onboarding and offboarding](cs-3-onboarding-offboarding.md), which owns the canonical checklist that the office and hardware steps in this file plug into.
- [DR-1: Basic incident response plan](dr-1-incident-response-plan.md), for what happens after a payment goes out the door or a device goes missing.
- [DR-4: Establish a communication channel with the rest of the company](dr-4-company-comms-channel.md), which is where suspicious message reports land.
- [CO-3: Understand existing commitments](co-3-existing-commitments.md), to check whether a customer contract already obliges you to a physical security control before you decide to skip one.
- [CO-4: Data inventory, privacy commitments, and framework choice](co-4-data-inventory-and-framework.md), for whether a lost or unwiped device triggers a notification obligation.
- [05: Metrics and communications](05-metrics-and-comms.md), for how to report reporting rate and payment fraud attempts to leadership without sounding alarmist.
- [07: Modern cells](07-modern-cells.md), for the SaaS and OAuth sprawl surface that has absorbed much of what "workplace" used to mean.
