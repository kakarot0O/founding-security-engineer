# DR-4: Establish a communication channel with the rest of the company

> **Grid coordinate:** DR-4, Domain DR (Detection and Response / Incident Response).
> **Original 2019 wording:** "Establish a communication channel with the rest of the company."
> **Load when:** the human is in their first 30 days, or nobody in the company knows how to reach security, or a colleague just reported something by direct message to the human personally, or an incident happened and internal staff found out from a customer, or the human says nobody tells them anything.

## Why this cell exists

Security at a startup does not find most of its problems with tools. It finds them because a support agent forwards a weird email, an engineer says "wait, is this bucket supposed to be public?", or a salesperson mentions a customer asked for a penetration test report. Every one of those is a free detection, and every one of them is lost if there is no obvious, low friction, unpunished way to tell you.

This is also the cell that decides whether the rest of the company treats security as a partner or as a compliance tax. The first security hire arrives with no authority and no track record. Communication is how you build both. It is the highest leverage soft skill work available in the first 90 days, and unlike detection engineering it pays off in week one rather than quarter three.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] There is exactly one obvious front door to reach security, and a new hire can find it without asking anyone.
- [ ] The "ask a question" path and the "report a problem" path are separate and both are documented in the same place.
- [ ] Reporting a suspected phishing email takes under 15 seconds and does not require the reporter to be sure.
- [ ] A written, founder co-signed statement exists saying that reporting a mistake will never be punished, and at least one real reporter has been publicly thanked.
- [ ] A recurring security office hours slot exists on the calendar, even if attendance is sometimes zero.
- [ ] A recurring security update note goes out on a fixed cadence (weekly or biweekly) and is under one screen long.
- [ ] Security has a 10 to 15 minute slot in new hire onboarding, with a fixed script.
- [ ] There is a written internal incident communication template and a named person who approves sending it.
- [ ] There is an agreed escalation path to reach a founder or the CTO within 30 minutes, tested once while nothing is on fire.
- [ ] The human has had a real one to one conversation with the four key relationship holders (listed in step 11).

Explicitly **not** required at this stage: a ticketing system with service level agreements, a security awareness training platform, a phishing simulation program, an anonymous whistleblower hotline vendor, an internal security portal or wiki hierarchy, a security newsletter with branding, a formal on-call rotation, or a policy acknowledgement campaign.

## Discovery

Everything here is read only. The goal is to learn what communication surfaces already exist before creating another one. Adding a channel to a company that already has six unused ones is a negative action.

**Step 0, no access at all.** If the agent has no admin access and no chat export, do not guess. Ask the human to answer the closed questions below from what they can see in their own client, and record the answer in `SECURITY-STATE.md` under DR-4 with status `unknown` until confirmed.

**Chat platform, Slack.** Console path: Slack admin at `https://<workspace>.slack.com/admin` for the member list, and the channel browser (search for `security`, `incident`, `it-help`, `phishing`, `oncall`) which any member can use without admin rights. With a user or bot token that has `channels:read`, this is read only:

```bash
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "https://slack.com/api/conversations.list?types=public_channel&limit=1000" \
  | jq -r '.channels[] | [.name, .num_members, (.purpose.value // "")] | @tsv'
```

Also check whether Slack Connect (external shared channels and external direct messages) is enabled, because that is now an inbound social engineering path. Console: Settings and administration, then Workspace settings, then Permissions, then Slack Connect.

**Chat platform, Microsoft Teams.** Console path: Teams admin center at `https://admin.teams.microsoft.com`, then Teams, then Manage teams. Check External access and Guest access under Users. With Microsoft Graph and a read scope, this is read only:

```bash
curl -s -H "Authorization: Bearer $GRAPH_TOKEN" \
  "https://graph.microsoft.com/v1.0/groups?\$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&\$select=displayName,mail" \
  | jq -r '.value[] | [.displayName, .mail] | @tsv'
```

**Chat platform, Discord or Google Chat or nothing.** If the company runs on Discord, look at the server channel list and role list in the client. If on Google Chat, look at Spaces. If there is no chat platform at all, the front door is an email alias plus a form, and that is a perfectly acceptable answer for a 20 person company.

**Email aliases and groups, Google Workspace.** Console path: `admin.google.com`, then Directory, then Groups. Search for `security`, `abuse`, `privacy`, `it`, `help`. If the `gam` command line tool is already installed and configured, this is read only:

```bash
gam print groups name email description | head -50
```

Do not install `gam` just for this. The console listing is faster and requires no new credentials.

**Email aliases and groups, Microsoft 365.** Console path: `admin.microsoft.com`, then Teams and groups, then Active teams and groups. Also check Exchange admin center at `admin.exchange.microsoft.com` for distribution lists and shared mailboxes.

**Existing phishing report path.** In Google Workspace, Gmail has a built in "Report phishing" item in the message overflow menu for every user with no admin configuration required. In Microsoft 365, check whether the Report Message or Report Phishing add-in is deployed, and check the user reported settings: Microsoft Defender portal at `security.microsoft.com`, then Settings, then Email and collaboration, then User reported settings. Note the mailbox that reports currently route to. Very often it routes nowhere useful.

**Onboarding surface.** Ask where the new hire checklist lives. Common answers: a Notion page, a Confluence space, a BambooHR or Rippling or Gusto onboarding workflow, or a single Google Doc that one person maintains. Find it, do not recreate it.

**Existing documentation home.** Whatever the company already uses (Notion, Confluence, Google Docs, a `docs/` folder in the main repository, Slab, Coda) is where security documentation goes. Creating a new tool for security docs is a classic first hire mistake.

## Ask the human

Ask these as closed questions, one at a time, and record answers in `SECURITY-STATE.md` under DR-4:

1. What is the primary chat tool, Slack, Teams, Discord, Google Chat, or none?
2. Is there already a channel or alias people use for information technology help or laptop problems? What is it called and who answers it?
3. If an employee got a suspicious email right now, what would they do? Do not guess, ask two colleagues.
4. Has anyone been reprimanded, publicly criticised, or made to feel stupid for a security mistake in the last year that you know of? (This determines whether the blameless rule needs a founder to say it or whether you can.)
5. Who runs new hire onboarding, and how long is the current agenda?
6. Which founder or executive is the fastest to respond, and on what medium do they actually reply, chat, text message, or phone call?
7. Is there an existing all hands, engineering weekly, or company newsletter I could get five minutes or five lines in, instead of creating something new?
8. Are there external people in the chat workspace (contractors, customers in shared channels, guest accounts)?

**Copy-pasteable message to the chat workspace owner to get the access needed:**

> Hi, I am setting up the way the rest of the company reports security issues to me. To do that without creating a mess I need two things: (1) read access to the workspace admin so I can see what channels and groups already exist before I add another one, and (2) the ability to create one public channel and one private channel. I am not asking to change any workspace wide settings, and I will not change anyone's permissions. If it is easier, you can just send me a screenshot of the channel list and create the two channels yourself. Which do you prefer?

**Copy-pasteable message to whoever owns onboarding:**

> Hi, I would like 10 to 15 minutes in new hire onboarding for a security section. It is not a training course and there is no quiz. It covers three things: how to report something suspicious, why nobody gets in trouble for reporting, and the two or three rules that actually matter here. I will write the script and run it myself, or record it if you prefer async. Can you tell me where the current onboarding agenda lives and who I need to ask to add a slot?

## The walk

Do these in order. Do not run ahead. After each step, report what happened and ask for a go or no-go on the next one.

### Channels: the complete list, the size baseline, and the trigger for each split

This cell owns internal communication, which means it owns how many security channels the company has. No other cell may create one. Several other cells will suggest a channel of their own, and the answer to each of them is the baseline and the split triggers below, not a new channel. An empty security channel is not neutral, it is visible evidence that security here is process rather than help, and it is exactly the theater this whole skill exists to avoid.

**Under 50 people: one channel, `#security-help`, plus direct message for reports.** That is the whole channel set. Questions, answers, announcements, and alert follow-up all live there. Reports arrive by direct message or the native phishing report button, not in a channel. Company size decides this baseline and nothing beyond it.

Each possible split has its own named trigger, and two of the three are not size triggers at all. Growing past 50 people does not by itself unlock anything below. Split only when the named trigger has actually fired:

- **Trigger, alert volume: split out `#security-alerts` only when DR-2 is producing more than about five alerts a week.** Below that threshold, alerts go to the single front door or to an email alias the human reads daily. See [dr-2-top-security-signals.md](dr-2-top-security-signals.md), which defers to this trigger rather than creating a channel on its own. When you do split it, make the channel private, because alert bodies routinely contain employee email addresses, internet protocol addresses, and sometimes customer identifiers.
- **Trigger, plan publication: split out `#security-incidents` only when the incident response plan is published.** A channel for a process that does not exist yet is a channel that will be empty on the day you need it, and worse, people will have muted it. Headcount never unlocks this one: a 200 person company with no published plan still declares in the single front door. See [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md). Make it private and invite-on-declaration.
- **Trigger, none at any size: never create `#security-questionnaires`.** Customer security questionnaires arrive by email and are answered by email. Route them to the trust address in the table below and run the working conversation in a thread in `#security-help`, where the answers stay visible to the people who will be asked the same question next month. See [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md).

Two operating rules go with the set. First, every split is reversible: if a channel goes two weeks with no human posting in it, archive it and fold the traffic back into `#security-help`. Archiving is preferable to deleting, because it preserves history. Second, creating or archiving a channel is a change other people see, so agree it with the chat workspace owner first rather than announcing it afterwards.

If the company uses Microsoft Teams rather than Slack, read "channel" as a channel inside an existing company-wide team, and do not create a new team. If the company uses Discord or Google Chat, read it as a server channel or a Space. If the company has no chat platform at all, the entire set collapses to one email alias, and that is a correct answer rather than a deficiency.

### Step 1: Pick the front door and claim it

- **Goal:** by the end of day one, there is one name that answers "how do I reach security here".
- **Do:** choose one primary front door based on the chat platform. Slack: a public channel named `#security-help`. Teams: a channel named `Security Help` in an existing company wide team, or a new team only if no suitable one exists. No chat platform: an email alias `security-help@<domain>` that forwards to the human. Create it and write a one line purpose or description on it: "Ask security anything. No question is too small. For urgent or sensitive reports see the pinned message." Pin a message with the report path (step 3) and the office hours time (step 6), even if those are still placeholders.
- **Verify:** open the channel or send an email to the alias from a personal account and confirm it arrives. Paste the exact channel name and link into `SECURITY-STATE.md` under DR-4 as evidence.
- **Time:** 30 minutes.
- **Who else is needed:** whoever can create a channel or a group, usually the workspace owner or an information technology admin.

### Step 2: Get a founder to co-sign the announcement

- **Goal:** the announcement carries borrowed authority, because you have none yet.
- **Do:** send the founder or the CTO a draft and ask them to post it, or to reply "+1" in the thread within an hour of you posting it. Do not send an all-company announcement that a founder has not seen first.
- **Verify:** you have their written yes before anything goes out.
- **Time:** 15 minutes plus their response time.
- **Who else is needed:** a founder, the CTO, or the head of engineering.

**Copy-pasteable announcement, general purpose (adapt channel names to the platform):**

> Hi everyone. I am <name> and I look after security here. Two things you need from me today.
>
> **If you have a question**, ask in #security-help. Anything counts: "is this vendor okay to use", "can I put this file in Drive", "is this link safe", "I need to give a contractor access to X". There are no stupid questions and I would much rather answer 50 easy ones than miss one hard one.
>
> **If you think something is wrong**, tell me straight away: direct message me, use the Report phishing button in your mail client, or email security-help@<domain>. You do not need to be sure. "This felt weird" is exactly the right amount of certainty to report at. A screenshot of a chat message counts just as much as a forwarded email.
>
> One promise: **you will never get in trouble for reporting something, including something you did yourself.** If you clicked a link, entered a password, sent money, or shared a file you should not have, tell me immediately and I will help you fix it. The only thing that makes a mistake worse is finding out about it a week later from someone outside the company.
>
> I will also be running open office hours every <day> at <time>. Drop in with anything.

### Step 3: Split the report path from the ask path

- **Goal:** questions and reports do not compete for the same attention, reports never land in a public place, and no single mailbox is asked to be both the place employees confess mistakes and the place anonymous strangers on the internet can write to.
- **Do:** questions go to the public channel from step 1. Reports go to a private path: a direct message to the human, plus the native phishing report button, plus an internal-only alias `security-help@<domain>` for people who prefer email. Google Workspace: the built in Gmail "Report phishing" already works with no admin configuration. Microsoft 365: deploy the Report Phishing add-in and set the user reported mailbox in Microsoft Defender at Settings, then Email and collaboration, then User reported settings. **Deploying the add-in and repointing the user reported mailbox are mutating changes**, so the mail administrator makes them or approves them explicitly before anything is clicked. Document the difference in the pinned message: "Question, use the channel. Something is wrong, direct message me or use the button."
- **Do not use one alias for everything.** Assign one job per address using the table below, and create only the ones you actually need today.

**The four addresses, one job each.** This table is the authoritative assignment for the whole skill. Other cells reference it rather than inventing their own.

| Address | Audience | What it is for | Accepts anonymous external mail? | Owning cell |
| --- | --- | --- | --- | --- |
| `security@<domain>` | External, published | Vulnerability reports from security researchers and the disclosure contact printed in public documentation | Yes, deliberately, and it must never be restricted to internal senders | SE-4, published by CO-1. See [se-4-bug-bounty-and-disclosure.md](se-4-bug-bounty-and-disclosure.md) and [co-1-public-security-docs.md](co-1-public-security-docs.md) |
| `security-help@<domain>`, or the `#security-help` channel | Internal only | Employee questions, and email-preferring employees reporting something | No, restrict delivery to authenticated internal senders | DR-4, this cell |
| Direct message plus the native phishing report button | Internal only | The primary internal report path, including reporting your own mistake | Not applicable, it is inside the identity boundary | DR-4, this cell |
| `trust@<domain>` | External, from customers and prospects | Security questionnaires, due diligence requests, and customer security questions | Yes, from customers | CO-2. See [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md) |

Why this matters and is not a naming preference: a mailbox that must accept unauthenticated mail from anyone on the internet is a mailbox that receives phishing, extortion, and low quality automated scanner output every week. That is fine and expected for `security@`. It is actively harmful for the address where an employee sends "I think I just entered my password on a fake login page", because the human reading it is now triaging a stranger's spam in the same thread as a colleague's confession, and because inbound external mail to that alias can be used to social engineer the security hire directly. Keep the internal report path inside the identity boundary.

At a 20 person company you may genuinely only need two of these on day one: the internal path, and, if any public security documentation exists, `security@`. Create `trust@` when the first questionnaire arrives, not before.

- **Verify:** send a harmless test message to each alias you created, from an address of the correct audience type, and confirm delivery and that the internal alias correctly rejects or quarantines external mail. For the phishing button, ask one friendly colleague to report a real newsletter and confirm you receive it. Note the timestamps in `SECURITY-STATE.md`.
- **Time:** 1 to 2 hours.
- **Who else is needed:** the email or identity administrator. Creating an alias, changing who may deliver to it, and repointing a reported-message mailbox are all mutating changes and need their explicit yes.

### Step 4: Make reporting take 15 seconds

- **Goal:** friction is the enemy. Every extra field is a report you never receive.
- **Do:** accept reports in any form: a forwarded email, a screenshot pasted into chat, a one line direct message, a voice note. Publish that explicitly. Do not require a template, a severity rating, or a form at this stage. If the company already has a form culture (for example everything goes through a Notion or Jira intake), add a form as an *additional* option, never as the only one.
- **Verify:** ask a non technical colleague to describe, in their own words, what they would do if they got a suspicious email. If they cannot answer in one sentence, the path is too complicated.
- **Time:** 30 minutes.
- **Who else is needed:** one friendly non technical colleague, ideally in support or sales.

### Step 5: Make the no punishment rule credible

- **Goal:** a written promise is worth nothing until someone tests it and survives. Prove it in month one.
- **Do:** the first time anyone reports a mistake they made, thank them publicly in the channel (with their permission), name what they did right, and never mention what they did wrong. Then privately fix the underlying control so the next person cannot make the same mistake. If the company has a values or kudos channel, post it there too. If a manager reacts badly to a report, escalate that to the founder as a security risk, because it is one.
- **Verify:** record the date and the (anonymised if needed) instance in `DECISION-LOG.md` under "Blameless reporting norm established". If four weeks pass with zero self reports, the norm is not credible yet and you should ask a friendly colleague to seed one honestly.
- **Time:** ongoing, minutes per instance.
- **Who else is needed:** the reporter's consent, and a founder if a manager pushes back.

### Step 6: Start security office hours

- **Goal:** a standing, low stakes place for people to bring things they would not file a report about, which is where most useful information lives.
- **Do:** put a recurring 30 minute open slot on the calendar, same day and time each week. Invite the whole company but make attendance obviously optional. Sit in the meeting even when nobody comes and use the time for your own work. For remote or async companies, additionally offer a "leave a question in the thread and I will answer by end of day" option.
- **Verify:** the calendar invite exists and is visible to everyone. Link it in `SECURITY-STATE.md`.
- **Time:** 15 minutes to set up, 30 minutes per week to run.
- **Who else is needed:** nobody.

**Copy-pasteable office hours invite:**

> **Security office hours (optional, drop in any time)**
>
> Bring anything: a tool you want to use, an access request you are unsure about, an architecture you want a second pair of eyes on, a customer security question you got stuck on, or something that has been quietly bothering you. No agenda, no preparation, no minutes taken.
>
> If this time never works for you, message me in #security-help and we will find another one.
>
> Zoom/Meet/Teams link: <link>

### Step 7: Start the recurring security note

- **Goal:** people should learn what security is doing without having to ask, and you should build a written record of progress that you can reuse in board updates and questionnaires.
- **Do:** post a short note on a fixed cadence, biweekly for a company under 50 people and weekly above that. Post it where people already read things (the existing engineering or all-company channel) rather than in your own channel where only the converted will see it. Keep it under one screen. Always include one thing a reader can do in under a minute.
- **Verify:** post it and watch for replies or reactions. Zero engagement three times in a row means the content is wrong, not that people are wrong.
- **Time:** 30 minutes per issue.
- **Who else is needed:** nobody, though a founder reaction on the first one helps a lot.

**Copy-pasteable weekly or biweekly security note template:**

> **Security note, <date>**
>
> **Shipped**
> - <one line, in plain language, with the benefit not the mechanism. Example: "Contractor accounts now switch off automatically on their last day, so nobody has to remember.">
>
> **What I am working on next**
> - <one or two lines, so people can tell you it is a bad idea before you finish it>
>
> **Something that happened out there**
> - <one short, non alarmist item from the wider world, only if it is genuinely relevant to how this company works. Skip this section rather than pad it.>
>
> **One thing you can do in 60 seconds**
> - <a single concrete action, for example: "Check that your work laptop asks for a password when the lid is closed. If it does not, ping me.">
>
> **Thanks to**
> - <name someone who reported something or helped. Every issue. This is the most important line in the note.>
>
> Questions, corrections, or "that sounds wrong" go in #security-help.

### Step 8: Get 15 minutes in new hire onboarding

- **Goal:** every future employee arrives already knowing the front door and the blameless rule, so the previous seven steps do not decay.
- **Do:** write a fixed script covering exactly three things: (1) how to report something and where the front door is, (2) the no punishment promise, said out loud by a human, (3) the two or three rules that genuinely matter at this company (usually: use the password manager, use the approved single sign on rather than making new accounts, and ask before putting customer data somewhere new). Do not cover the entire security policy. Offer to record it if onboarding is async.
- **Verify:** attend or record one session, then ask one new hire a week later what they would do with a suspicious email. Their answer is the verification.
- **Time:** 2 hours to write, 15 minutes per cohort.
- **Who else is needed:** whoever owns onboarding, usually the head of people or an office manager or a founder.

### Step 9: Write the internal incident communication template

- **Goal:** during an incident, staff who are not in the response still need to know what to do and what not to say, and you will not have the mental capacity to write that from scratch.
- **Do:** write two short templates and store them next to the incident response plan (see [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md)). Template A is the internal holding message. Template B is the "please do this" message when staff action is required (for example, everyone re-authenticate, or stop using a particular tool). Agree in advance who approves sending them: normally the incident lead plus one founder, and legal counsel if there is any chance of customer notification.
- **Verify:** both templates exist in the documented location and a founder has read them once, before any incident.
- **Time:** 1 hour.
- **Who else is needed:** a founder, and legal counsel if the company has one on retainer.

**Copy-pasteable internal holding message (template A):**

> **Security update, <date> <time and timezone>**
>
> We are investigating <plain, non speculative description, for example "unusual activity on one of our internal accounts">. A small group is working on it now.
>
> **What we know:** <only confirmed facts. If you know almost nothing, say so.>
> **What we do not know yet:** <be explicit, this prevents rumour>
> **What you need to do:** <either "nothing right now" or one clear action>
> **What you should not do:** please do not discuss this outside the company, including with customers, on social media, or in external shared channels. If a customer or anyone outside asks you about it, send them to <named person> and do not answer yourself.
>
> Next update by <specific time, and then actually send it even if there is no news>.
>
> Questions go to <channel or person>, not to the responders, who are busy.

### Step 10: Agree and test the founder escalation path

- **Goal:** when you need a decision in 20 minutes (shut off a production integration, lock an employee account, pay or not pay), you must know exactly how to reach a decision maker and they must have agreed in advance to be reachable.
- **Do:** agree with the founder or CTO on a named primary and a named backup, the medium that actually reaches them out of hours (usually a phone call or text message, not chat), and what you are pre-authorised to do without asking. Write the pre-authorisation down: it is the single most valuable sentence you will get in your first 90 days. Then test it once, on a normal weekday, with a message that says it is a test.
- **Verify:** the test message was answered, and the response time is recorded in `DECISION-LOG.md` along with the agreed pre-authorisation.
- **Time:** 30 minutes plus the test.
- **Who else is needed:** a founder or the CTO, plus a named backup.

**Copy-pasteable escalation agreement request:**

> There will be a moment where I need a yes or no from you in under 30 minutes: disable an account, pull an integration, take a service offline, or contact a customer. I do not want to be discovering how to reach you at that moment. Three questions: (1) if I need you at 11pm on a Saturday, do I call, text, or something else? (2) who is the backup if you do not answer in 15 minutes? (3) what am I allowed to do without asking you first? My suggestion for (3) is a deliberately short list, and only during an incident I have declared: I can revoke a named human employee's active sessions and refresh tokens, and revoke a third party application's access grant. Those two and nothing else. Both are reversible in one action, both are scoped to one identity, and neither can take a customer offline. I will tell you within the hour. Everything else I ask first, even at 3am. Specifically I will always ask before touching a service account, rotating any credential that production uses, changing anything on the deploy path, changing any firewall or network rule including blocking an address range, disabling or deleting an account, or doing anything a customer would notice, because those are the actions that cause outages rather than prevent them. Does that work for you?

Read that list literally. Pre-authorisation covers only containment actions that are reversible in minutes, only during an incident that has been formally declared, and it is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop, all of which require an explicit human yes every time. It never extends to a service account, a production credential, a deploy path, a network rule, or anything customer-facing, and it never authorises an active scan or test against any system. If you find yourself wanting broader standing authority, the answer is a faster path to a human, not a wider grant to yourself. See [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md) for what "declared" means and who declares it.

### Step 11: Deliberately build the four relationships

- **Goal:** four specific people can each hand you an entire domain of visibility that would otherwise take you a quarter to reconstruct. Meet all four in your first three weeks.
- **Do:** book a 30 minute one to one with each. Ask about their problems, not yours. Offer to take something off their plate.
  1. **The person who runs information technology or the laptop fleet.** Often an office manager, a technical operations person, or an engineer who inherited it. They know every device, every account, every "we never got around to it". They are usually overworked and thrilled that someone cares. Ask: what keeps breaking, and what have you been asking for that nobody approved? Relevant to [cs-1-identity-and-access.md](cs-1-identity-and-access.md) and [cs-2-endpoint-security.md](cs-2-endpoint-security.md).
  2. **The platform, infrastructure, or developer experience lead.** They own the paved road, the deploy pipeline, and the cloud accounts. Nothing you want in Security Engineering happens without them. Ask: if you had one engineer for two weeks, what would you fix? Relevant to [se-2-understand-the-tech-stack.md](se-2-understand-the-tech-stack.md).
  3. **The head of customer success, support, or solutions engineering.** They receive the security questionnaires, the customer complaints, and the "a user says their account was accessed" reports. They are your best detection source and your loudest ally once you make questionnaires easier. Ask: how many security questionnaires are you sitting on right now, and how long does each one take? Relevant to [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md).
  4. **The finance or operations person who owns software spend.** The corporate card statement is the most accurate list of vendors in the company, more accurate than anything the engineering team will tell you. Ask: can I see the recurring software charges, and can you tell me before a new tool gets bought? Relevant to [07-modern-cells.md](07-modern-cells.md).
- **Verify:** four names, four dates, and one concrete thing each of them wants, written into `SECURITY-STATE.md` under DR-4.
- **Time:** 30 minutes each, plus follow up.
- **Who else is needed:** the four of them.

## Decision points

**Public channel or private path as the primary front door?**
DEFAULT: both, split by purpose. Public channel for questions (so answers are reusable and the company sees security being helpful), private path for reports (so nobody has to be embarrassed in public). The private path is a direct message plus the native phishing report button plus the internal-only `security-help@` alias, never the externally published `security@` address. Change if: the company culture is heavily direct message based and public channels are dead, in which case lead with the direct message and revisit at 50 people.

**How many security channels should exist?**
DEFAULT: exactly one under 50 people. The full set and the triggers that unlock each additional one are in the Channels subsection above, which is the authoritative list for the whole skill. Change if: the named trigger for a specific channel in that subsection has actually fired, observed rather than anticipated.

**Should reporting be fully anonymous?**
DEFAULT: no at under 100 people. Full anonymity is hard to deliver honestly in a small company (people are identifiable from context), and the tooling costs money. Offer low friction pseudonymity instead: a form that does not require a login, and a stated promise that you will not reveal who reported unless legally required. Change if: the company has had a retaliation incident, is in a regulated sector with whistleblower obligations, is unionised, or is above roughly 150 people. At that point buy a real hotline and route it through legal or people operations, not through you.

**Own the front door yourself or route through the existing information technology help channel?**
DEFAULT: separate channel for security, because merging into an overloaded help desk buries security reports under password resets. Change if: the information technology channel is well run, low volume, and staffed by someone who will tag you reliably. Then co-own it and save yourself a channel.

**Weekly or biweekly security note?**
DEFAULT: biweekly under 50 people, weekly above. Change if: you cannot fill it with real shipped work, in which case go monthly rather than padding it. An honest monthly note beats a padded weekly one.

**Broadcast an incident to the whole company or keep it need to know?**
DEFAULT: tell staff early with a plain holding message. Rumour and silence are worse than a boring update, and staff who do not know what happened will improvise answers to customers. Change if: the incident involves a suspected insider, or counsel has invoked legal privilege, or the information itself is the sensitive material (for example a compromise of executive communications). Then restrict, and say publicly that a small group is handling something and updates will follow.

**Do you own the phishing report button or does information technology?**
DEFAULT: you own triage, they own the mail platform configuration. Do not take over mail administration in your first quarter.

## Danger zone

Each of these needs an explicit human yes before you act. State the risk, then stop and wait.

- **Sending an all-company announcement without a founder having read it.** Risk: you spend political capital you do not have, and a founder finds out about your role from a channel post. Not technical, but the most common way a first security hire starts badly.
- **Changing workspace wide chat settings** (who can post in a channel, who can create channels, external access, guest permissions, retention). Risk: you can silently break workflows for the whole company, and changing message retention can destroy evidence you will later need. Get the workspace owner to make the change while you watch.
- **Renaming, deleting, or repointing an existing email alias or distribution list.** Risk: inbound mail (including from customers and security researchers) silently disappears with no bounce. Always create new, forward old, and only retire an alias after 30 days of observed zero traffic.
- **Deploying or reconfiguring the Report Phishing add-in and the user reported mailbox in Microsoft 365.** Risk: misrouting means reports land nowhere and users conclude reporting does not work. Test with a real report before announcing it.
- **Any external communication about an incident**, including customer emails, status page posts, social media, or telling a single customer informally. Risk: regulatory notification clocks, contractual notification terms, and legal exposure. This is a founder plus legal decision, never yours alone. See [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md).
- **Naming an individual in incident communications.** Risk: you destroy the blameless norm permanently in one message, and you may create an employment law problem. Describe what happened, never who.
- **Running a simulated phishing campaign in your first quarter.** Risk: you trick your colleagues before they trust you, and the relationship never recovers. Also, in many jurisdictions a poorly designed simulation (fake bonus emails, fake layoff notices) has caused real disputes.
- **Signing up for a tool that stores employee reports outside your control** (an anonymous reporting software as a service, a form product) without a privacy review. Risk: you have just created a new data processing activity and possibly a new vendor obligation. See [co-4-data-inventory-and-framework.md](co-4-data-inventory-and-framework.md).
- **Paging everyone with an all-channel notification for anything less than a real incident.** Risk: you burn the one alerting mechanism you have. Use it once wrongly and it is discounted forever.

## Do not do this yet

- Do not buy a security awareness training platform. Not in the first 90 days. The 15 minute onboarding slot and the recurring note do 80 percent of the work for zero dollars, and a training platform without a comms channel is pure theater.
- Do not build a formal ticket queue with service level agreements. You are one person. A channel and an inbox are correct until you are receiving more than roughly ten inbound items a week.
- Do not create a second, third, or fourth security channel because a cell suggested one. Under 50 people the answer is one channel. The Channels subsection above lists every channel that is ever allowed to exist and the named trigger that unlocks each one. A channel with no traffic teaches the company that security is paperwork.
- Do not build a security wiki hierarchy. One page, in the tool the company already uses, linked from the channel description. Expand only when a page gets too long to read.
- Do not create a security policy acknowledgement campaign. Nobody reads them, and doing it before you have credibility makes you the paperwork person forever. That work belongs later, tied to a real framework decision.
- Do not start a bug bounty style internal reward scheme with points and leaderboards. A public thank you and an occasional gift card outperform gamification at this size.
- Do not set up an on-call rotation of one person. Instead, agree the escalation path in step 10 and be honest about your response hours.
- Do not attempt to insert security approval into every purchase and every design decision at once. You will become a bottleneck, people will route around you, and you will lose the visibility this whole cell exists to create.
- Do not report metrics on channel volume to the board yet. See [05-metrics-and-comms.md](05-metrics-and-comms.md) for what is actually worth reporting.

## Evidence to capture

Write these to state files as you go:

- `SECURITY-STATE.md`, section DR-4: the front door name and link, the channel list with the trigger that justified each one beyond the first, the four addresses from the step 3 table with which ones exist today and which are deliberately not created yet, the phishing button status per platform, the office hours calendar link, the note cadence and where it is posted, the onboarding slot status, and the four relationship names with dates. Set the status to `partial` until steps 1 through 8 are all done, then `done`.
- `DECISION-LOG.md`: the date the blameless reporting norm was published and who co-signed it, the escalation path agreement including the pre-authorised actions and the founder who approved them, and the decision on anonymous reporting with its reasoning.
- `ACCESS-LOG.md`: every admin access requested for chat, email, and forms, what was granted, what was refused, and the date. Refusals matter as much as grants, because they become risk register entries.
- `RISK-REGISTER.md`: if there is no reporting path yet, log it as a risk with the owner and severity, and close it with a reference to the announcement message when step 2 lands. If the escalation path is refused or untested, log that too.
- `90-DAY-PLAN.md`: mark DR-4 steps against weeks. Steps 1 to 3 belong in week one.

Artifacts a future auditor or enterprise customer will ask for, so save them where you can find them again: the announcement message with its date, the onboarding security agenda or recording, three or four consecutive security notes (these are excellent evidence of ongoing internal security communication), the internal incident communication template, and the escalation contact list. These commonly map to control expectations around internal communication of security responsibilities and a documented mechanism for reporting security concerns, which appear in SOC 2 (System and Organization Controls 2) common criteria and in ISO/IEC 27001 Annex A awareness and reporting controls.

## Cost and effort

- **Total effort:** roughly 3 to 5 days of work spread across the first 90 days, plus 30 to 60 minutes per week ongoing for office hours and the note.
- **Direct cost: zero.** Every control in this cell uses something the company already pays for. Channels, aliases, calendar invites, and the native phishing report buttons in both Google Workspace and Microsoft 365 are included in existing licences.
- **Optional cheap spend that is actually worth it:** a few hundred dollars a year for gift cards or lunches to thank people who report things. This is the highest return per dollar in the entire security budget at this stage, and you can usually get it approved as a team expense without a formal budget request.
- **Paid options to defer:** security awareness and phishing simulation platforms run roughly 10 to 30 dollars per user per year (vendors in this band include KnowBe4, Hoxhunt, and Huntress). Anonymous ethics and whistleblower hotline platforms run roughly 3,000 to 15,000 dollars per year. Both are correct purchases eventually and wrong purchases in your first quarter. Free alternatives first: the onboarding slot, the recurring note, and a no-login form in whatever tool you already have (Google Forms, Microsoft Forms, Notion, Typeform free tier).

## 2026 notes

The 2019 slide framed this cell as "so people can find you". Four things changed since then, and all of them make this cell more important rather than less.

1. **Chat is now the attack surface, not just the reporting surface.** Slack Connect external direct messages and Microsoft Teams external federation mean an attacker can message your employees inside the tool they trust most, impersonating a vendor, a candidate, or a colleague. The reporting path must therefore accept a screenshot of a chat message as easily as a forwarded email, and your announcement should explicitly say that suspicious chat messages count.
2. **Help desk social engineering became the dominant intrusion technique for the exact company profile this skill targets.** Attackers call or message support and information technology staff pretending to be an employee locked out of their account, and ask for a password or multi factor reset. That means your comms channel work must include a verification norm: an agreed way for staff to prove identity for any credential or device reset, and an agreed way for staff to verify that a request from a "founder" is real. Publish that norm in the same announcement. See [cs-1-identity-and-access.md](cs-1-identity-and-access.md) and [cs-3-onboarding-offboarding.md](cs-3-onboarding-offboarding.md).
3. **Voice and video are no longer proof of identity.** Synthetic audio and video of executives approving urgent payments or access changes is a real, documented fraud pattern. The cheap countermeasure is cultural and belongs in this cell: an out of band verification rule for any urgent request involving money, credentials, or access, stated plainly in onboarding and in the announcement. "If someone who sounds like a founder asks you to do something urgent and unusual, you are expected to hang up and confirm in chat. Nobody will be annoyed with you for this."
4. **Engineers now need a fast answer to a new class of question**: can I paste this into an AI assistant, can I connect this Model Context Protocol server, can I authorise this integration to read our shared drive. These questions arrive daily and they arrive informally. If there is no obvious front door, engineers will simply decide for themselves, and the answer will usually be yes. The front door is the cheapest control you have over this. See [07-modern-cells.md](07-modern-cells.md).

Also worth noting: remote and asynchronous first companies are now the norm rather than the exception, so office hours must have an async equivalent, and the recurring note carries more weight than it did in 2019 because there is no hallway to have the conversation in.

## Failure modes

**Nobody uses the channel.**
Early tell: fewer than two inbound messages in the first two weeks. Recovery: the problem is almost never the channel, it is that you have not visibly helped anyone yet. Go find three people, solve a small annoying problem for each of them, and answer it in the channel so others see it. Also check that you actually announced it with a founder co-sign, and consider whether you picked a channel nobody is in.

**The channel becomes a dumping ground for information technology requests.**
Early tell: password resets and printer problems. Recovery: do not scold. Answer or redirect politely every time, and add one line to the channel description pointing to the information technology channel. Redirecting kindly builds more goodwill than a correctly scoped channel.

**Security becomes the "no" channel.**
Early tell: people preface questions with "sorry to bother you" or stop asking before doing things. Recovery: change the default answer to "yes, and here is the safe way". Track how many requests you approved versus blocked and share the ratio in the note. If you blocked more than roughly one in five, you are calibrated wrong for a startup.

**Someone reports a mistake and gets punished anyway.**
Early tell: a manager says something dismissive in a thread, or the reporter goes quiet. Recovery: this is a five alarm event for this cell. Talk to the manager privately first, then escalate to a founder if it is not immediately fixed, and frame it as a detection capability being destroyed rather than as an interpersonal complaint. Log it in `RISK-REGISTER.md`. If it is not corrected, reporting stops company wide within weeks and you will not know it has happened.

**The recurring note becomes theater.**
Early tell: no replies, no reactions, and you are padding it with industry news. Recovery: cut the cadence in half, cut the length in half, and make sure every issue names a real person who helped. If you have nothing shipped to report, that is a signal about your work, not about the note.

**Internal incident communication leaks externally.**
Early tell: a customer or a journalist references internal wording. Recovery: expect this and write for it. Assume every internal incident message will be screenshotted, so never write anything internally that you would not be willing to see quoted. Keep speculation, blame, and unconfirmed numbers out of internal messages entirely.

**The escalation path fails on first real use.**
Early tell: you never tested it. Recovery: test it now, on a quiet weekday, and then again after any founder changes phone or role. An untested escalation path is not a control, it is a hope.

**You become the bottleneck for every decision in the company.**
Early tell: your channel has a backlog and you are working evenings on questions rather than on controls. Recovery: convert the top five repeated questions into a written default answer, publish it, and point at it. See [04-interrupts.md](04-interrupts.md) for how to park and resume work when the channel keeps interrupting deep work.

## Related cells

- [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md), where the internal communication templates plug into the response process.
- [dr-2-top-security-signals.md](dr-2-top-security-signals.md), because human reports are one of your highest quality detection signals at this size.
- [cs-3-onboarding-offboarding.md](cs-3-onboarding-offboarding.md), which owns the new hire process this cell asks for 15 minutes inside.
- [cs-1-identity-and-access.md](cs-1-identity-and-access.md), for the identity verification norm referenced in the 2026 notes.
- [cs-4-workplace-security.md](cs-4-workplace-security.md), for physical and office communication norms.
- [se-1-sdlc-and-design-reviews.md](se-1-sdlc-and-design-reviews.md), which depends entirely on engineers being willing to come to you.
- [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md), the fastest way to make the customer success relationship pay off.
- [02-intake-questions.md](02-intake-questions.md), for the wider question bank and access request templates.
- [05-metrics-and-comms.md](05-metrics-and-comms.md), for reporting upward to founders and the board.
- [04-interrupts.md](04-interrupts.md), for handling the interruptions this cell deliberately creates.
