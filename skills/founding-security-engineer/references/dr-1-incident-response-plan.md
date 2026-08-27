# DR-1: Basic incident response plan

> **Grid coordinate:** DR-1, Domain DR (Detection and Response / Incident Response).
> **Original 2019 wording:** "Basic incident response plan."
> **Load when:** the human asks how to handle an incident, says the company has no incident response plan, is in the middle of an incident right now, has just been asked by a customer or auditor for an IR plan, or the 90 day plan reaches the DR-1 gate, or a hunt query in [DR-0 compromise assessment](dr-0-compromise-assessment.md) returned a hit, or somebody mentions an incident that happened before the human joined. If an incident is live right now, skip to "In-incident fast path" below before reading anything else. If the event is months old rather than live, read "An incident that happened before you arrived" before asking anyone a single question.

## In-incident fast path

If something is burning right now, do these five things in order and read the rest later.

1. Open one dedicated channel or call and put every responder in it. Name one person the incident commander (IC) out loud.
2. Start a timestamped timeline document. Every fact gets a UTC timestamp and a source.
3. Preserve evidence **in parallel with** containment, never instead of it. If pulling the credential's usage log or the sign-in log takes under five minutes, pull it, then contain. Do not delay containment of an active compromise for a memory capture you have no capability to perform. What you must not do while containing: do not reboot or terminate a host, do not delete the malicious file, email, or package, and do not close the account you are investigating. See step 6 of The walk for the full list and the correct rotation ordering.
4. Contain (stop the bleeding) before you eradicate (remove the cause). Containment is reversible, eradication destroys evidence. Almost every containment action still needs an explicit yes from a named human first, and the "Danger zone" section below says which ones and from whom. The narrow exception, only during an incident that has actually been declared and only if the standing pre-authorisation in step 10 of [DR-4 company comms channel](dr-4-company-comms-channel.md) was agreed in advance and recorded in `DECISION-LOG.md`, is a set of exactly two actions: revoking a named human user's active sessions and refresh tokens, and revoking a third party application's access grant. Those two and nothing else. If that pre-authorisation was never agreed, there is no exception and you ask. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.
5. Check the notification clocks in [CO-3 existing commitments](co-3-existing-commitments.md) within the first two hours, not the last. Contractual windows are often shorter than the law.

**Two situations where the ordering above changes, so check them before you act.** If the attacker holds deletion rights over your data or your backups (an extortion note, a wiped database, an emptied bucket, a compromised principal that can delete snapshots), the destructive event runbook in [M-6 backups and recovery](m-6-backups-and-recovery.md) applies and its containment ordering is different: you break the deletion path before you cut the access path, because cutting access first is what triggers the destruction. If instead you are here because a hunt query in [DR-0 compromise assessment](dr-0-compromise-assessment.md) returned a hit, that hit opens an incident here, right now, using this fast path, and the hunt stops until the incident is scoped.

Everything below builds the plan so that the next incident is boring.

## Why this cell exists

Something bad will happen, and the difference between a bad afternoon and a company-ending event is almost entirely about whether people knew what to do in the first thirty minutes. An incident response plan is not a binder. It is a one page answer to four questions: who decides this is an incident, who is in charge, where do we talk, and who do we have to tell and by when. Startups routinely lose more value to a chaotic response than to the original technical problem, because nobody preserved evidence, nobody kept a timeline, and the customer heard about it from a journalist instead of from you. Evan Johnson's framing holds here: detection and response is the hardest domain to get traction in, but the plan itself is the cheapest possible piece of it and it can be done in one afternoon.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A one page IR plan exists in a place every employee can find without asking (company wiki, not a private folder, not only in the security repo).
- [ ] Severity levels are defined with at least two concrete company-specific examples per level.
- [ ] "Anyone can declare an incident" is written down explicitly, with the exact mechanism (a channel, a phone number, a form) and an explicit no-blame promise.
- [ ] There is a named incident commander rotation of at least two people, and a documented way to reach them out of hours.
- [ ] A dedicated chat channel or a documented process for spinning one up exists, plus a bridge or video link.
- [ ] A timeline template exists and the scribe role is named.
- [ ] Evidence preservation rules are written as a short do-not list, in the plan, sitting alongside the containment steps and explicitly stated as constraints on how you contain rather than as a gate you must clear before containing.
- [ ] The plan links to the destructive event runbook in [M-6 backups and recovery](m-6-backups-and-recovery.md) with one line saying when that branch applies.
- [ ] The customer notification decision tree exists and references the actual contractual windows from signed customer contracts.
- [ ] Outside counsel and a forensics firm are identified by name with a phone number, even if there is no retainer.
- [ ] A blameless postmortem template exists and one tabletop exercise has been run and its output logged.

Explicitly NOT required at this stage: a 24/7 on-call rotation for security, a paid incident response retainer, a dedicated war room tool (PagerDuty, incident.io, FireHydrant, Rootly), a formal crisis communications firm, a legal hold system, a forensics lab, tabletop exercises more than once or twice a year, or separate playbooks for every attack type. One plan and two or three playbooks is the correct amount of paper at this size.

## Discovery

Read-only. Find out what already exists before writing anything new. Half of this plan usually exists in fragments.

**Look for existing plans and adjacent process.**

```bash
# From the working directory, look for anything IR-shaped already in the repo.
grep -ril -E "incident response|runbook|postmortem|post-mortem|on-?call|sev1|severity" . \
  --include="*.md" --include="*.mdx" --include="*.txt" 2>/dev/null | head -50

# Engineering already has an outage process most of the time. Find it.
ls -la docs/ .github/ 2>/dev/null
```

If the wiki is Notion, Confluence, Google Drive, or similar, the agent almost certainly cannot read it. Ask the human to search it for the terms above and paste back what exists.

**Look for the alerting and paging path that already works.** Security incidents should ride the same rails as outages, because those rails are already tested.

- If the org uses PagerDuty, Opsgenie, or Grafana OnCall, ask for read access and check whether a security service or escalation policy exists.
- If the org pages through Slack or Microsoft Teams only, find the channel names and who is actually watching them at 2am. Usually nobody is, and that is a finding.

**Look for contractual notification clocks.** These are the hard deadlines and they beat every internal preference.

- Ask for the signed customer contracts, master service agreements (MSAs), or data processing agreements (DPAs) with the largest customers. Search for "notif", "breach", "security incident", "without undue delay", and "hours".
- If there is a contract repository (a Google Drive folder, Ironclad, PandaDoc, DocuSign, a sales shared drive), ask for read access to the executed folder only.
- Record findings in [CO-3 existing commitments](co-3-existing-commitments.md), not here, but consume them here.

**Look for what would even tell you an incident happened.** The plan is worthless if nothing triggers it. Cross reference [DR-2 top security signals](dr-2-top-security-signals.md).

- Cloud: if AWS, check whether CloudTrail is on in all regions and where it lands. If Google Cloud, check Cloud Audit Logs and their sink. If Azure, check the Activity Log and any diagnostic settings. Read-only console paths are fine here; do not create trails yet.
- Identity: if Google Workspace, the Admin console has Reporting then Audit and investigation. If Microsoft 365 or Entra ID, the audit log is in the Microsoft Purview or Entra admin center. If Okta or JumpCloud, check the System Log.
- Code: GitHub org audit log lives under Organization settings then Logs then Audit log (requires owner). GitLab has Admin then Audit events on self-managed, or group audit events on GitLab.com Premium and above.

**If the agent has no access at all.** This is the common case on day one and it is not a blocker. Writing the plan requires zero system access. Write the plan from interviews, mark every unknown as `UNKNOWN` in the document itself rather than guessing, and record each blocked item in `ACCESS-LOG.md` under "Requested". A plan with five honest UNKNOWNs beats a plan with five invented facts, because the UNKNOWNs get fixed and the inventions get believed.

## Ask the human

Ask these as closed questions. Do not ask "what should the plan look like."

1. Has this company had a security incident before? What happened, and who ran it? (If the answer is yes, or is a vague yes, do not keep pulling on it in that conversation. Stop, and follow "An incident that happened before you arrived" below, which starts with artifacts and not with people.)
2. Who has the authority to take production down or take a customer-visible action without asking anyone? Name the humans.
3. Who is the most senior person who must be woken up at 3am for a confirmed customer data exposure? One name.
4. Do we have a lawyer? Is it in-house counsel, an outside firm, or nobody yet?
5. Do we have cyber insurance? If yes, does the policy require using their panel firm for forensics? (This changes who you are allowed to call.)
6. What is the largest customer contract, and does it contain a security incident notification window? How many hours?
7. Are we subject to the EU General Data Protection Regulation (GDPR), meaning do we process personal data of people in the EU or UK? Do we have customers in California, Texas, or other US states with breach notification statutes?
8. Where does engineering handle outages today, and does that process have a severity scale I can reuse instead of inventing a second one?
9. Who is allowed to talk to press or post publicly? Is there a marketing or communications lead?
10. If our chat tool were the thing compromised, what is our backup way to talk to each other?

**Copy-pasteable message to engineering leadership:**

> Hey, I am writing our first incident response plan and I want to reuse what already works rather than invent a parallel process. Three things I need from you: (1) a link to the current outage or on-call process and its severity definitions, (2) confirmation of who has the authority to take prod down or roll back without approval, and (3) whether I can add a security escalation to the existing paging setup. Target is one page that everyone can read in five minutes, and I want your name on the review before it goes out.

**Copy-pasteable message to whoever owns contracts (usually the founder, head of sales, or finance):**

> I need read access to our executed customer contracts, MSAs, and DPAs, largest ten customers is enough to start. I am checking one specific thing: whether we have promised any customer that we will notify them within a fixed number of hours after a security incident. If we have signed a 24 hour or 48 hour window and we do not know about it, that is the single most expensive thing that can go wrong during an incident. Read-only access to the signed-contracts folder is all I need.

**Copy-pasteable message to the CEO or founder, for the legal and insurance question:**

> Two quick yes or no questions for the incident response plan. (1) Do we have cyber insurance, and if so can you send me the policy? Some policies require using their approved forensics firm, which changes who I am allowed to call during an incident. (2) Who is our lawyer for a data incident? If the answer is "we do not have one", that is fine, I will identify two firms and get quotes, but I need to know now rather than at 2am.

## The walk

Numbered baby steps. Do one, verify it, then propose the next. Step 1 alone is worth shipping on day one.

### Step 1: Write the one page plan, unfinished

- **Goal:** a findable document that answers who declares, who leads, where we talk, and who we tell. Even at 60% accuracy this is a large improvement over nothing.
- **Do:** copy the "One page IR plan template" below into the company wiki. Fill in every name you know. Mark everything else `UNKNOWN (owner: <name>, due: <date>)`. Do not wait for completeness.
- **Verify:** send the link to one engineer who was not involved and ask them "if you found a leaked API key in a public repo right now, what would you do?" If they can answer from the page in under 60 seconds, it works.
- **Time:** 2 to 3 hours.
- **Who else is needed:** nobody for the draft. One engineer for the read test.

### Step 2: Define severity with real examples

- **Goal:** so that "is this a Sev1?" is answered in ten seconds instead of debated for thirty minutes.
- **Do:** use the severity table below. Replace the generic examples with two company-specific examples per level, using real system names. If engineering already has Sev1 to Sev4 for outages, reuse their numbers exactly and add security examples to each level. Never create a second competing scale.
- **Verify:** take the last three real incidents or near misses and classify them. If two people classify the same past event differently, the definitions are still too vague.
- **Time:** 1 hour.
- **Who else is needed:** the engineering on-call lead, 20 minutes.

### Step 3: Make declaration free and blameless

- **Goal:** the person who notices is almost never the security team. If reporting feels risky, you find out from the customer instead.
- **Do:** write one sentence in the plan: "Anyone at this company can declare a security incident. You will never be in trouble for declaring one that turns out to be nothing. Over-declaring is the desired behavior." Then name the exact mechanism, and name only one. **Channel gate, owned by DR-4:** declarations go in the single security front door (normally `#security-help` on Slack, or a `Security Help` channel on Microsoft Teams) until the split condition in [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md) fires, which is when this plan is published. The per-incident channel is spun up at declaration time either way. Write that exact channel name into the plan and use the same name everywhere, because a plan that points at a channel which does not exist is worse than no plan. Add a fallback in the same sentence: message a named person directly, or call a specific phone number if there is no reply in ten minutes.
- **Verify:** announce it in the all-hands channel and ask one non-engineer to repeat back where they would report a suspicious email. See [DR-4 company comms channel](dr-4-company-comms-channel.md) for how to make that channel exist and be watched.
- **Time:** 30 minutes plus one announcement.
- **Who else is needed:** whoever owns internal comms, to approve the all-hands post.

### Step 4: Assign roles and admit that one person covers several

- **Goal:** clear ownership during the event, without pretending you have a staffed team.
- **Do:** define four roles in the plan. **Incident commander (IC)** decides, does not type. **Scribe** keeps the timeline, does nothing else. **Communications lead** handles internal updates and any customer or exec messaging. **Subject matter expert (SME)** is whoever actually knows the system. At startup scale, the realistic collapse is: IC plus comms is one person, scribe is a second person, SME is one to three engineers pulled in as needed. The two rules that must not be broken are (a) the IC does not also debug, because a person with their head in a terminal cannot see the whole incident, and (b) the scribe is never also the SME. If exactly two people are available, one is IC plus scribe and the other is SME, and you accept a worse timeline.
- **Verify:** name at least two people who can be IC, and confirm both have agreed in writing (a message in the channel is enough). Record in `DECISION-LOG.md`.
- **Time:** 1 hour including the conversations.
- **Who else is needed:** the two IC candidates, and their manager to bless the time commitment.

### Step 5: Set up war room mechanics before you need them

- **Goal:** no time is lost figuring out where to gather.
- **Do:** decide the declaration channel using the channel gate in step 3, which defers to DR-4 and keeps declarations in the single security front door until DR-4's split condition fires, and document that each incident gets its own channel or thread named `inc-YYYY-MM-DD-<short-name>`. If the org uses Slack, a public channel is better than a private one for anything not involving personnel or legal sensitivity, because it prevents duplicate investigations. If the org uses Microsoft Teams, create a dedicated team or a channel per incident with a linked meeting. Always pair the channel with a standing video bridge link (Zoom, Meet, or Teams) pasted in the channel topic. **Out-of-band backup:** write down a fallback that does not depend on the corporate identity provider or chat tool, because if the chat tool or the identity provider is the compromised thing, you cannot coordinate inside it. A shared Signal group with the core responders, plus everyone's personal phone numbers in a printed or offline document, is the standard cheap answer.
- **Verify:** post a test message in the channel and confirm the on-call person's phone actually buzzes. Untested notification settings are the most common silent failure here.
- **Time:** 45 minutes.
- **Who else is needed:** a workspace admin if channel creation is restricted.

### Step 6: Write the evidence preservation rules as a list of things that must not happen while you contain

- **Goal:** you cannot answer "what did they take" after you have destroyed the only record. Every notification decision, every legal position, and every customer conversation depends on evidence you had exactly one chance to capture.
- **The ordering rule that this whole step hangs on:** evidence preservation runs **in parallel with** containment, never instead of it and never before it. Containment actions that are themselves reversible and non-destructive (revoking a session or a refresh token, revoking a third-party application grant, blocking an address, isolating a host from the network without powering it off, taking a service off the internet) destroy no evidence and are never delayed for a capture. Not being delayed for a capture is a different question from not needing a yes: these actions still carry the approvals set out in the fast path above and in the Danger zone below. The list below is not a queue you work through before you are allowed to act. It is a list of specific destructive actions that people reach for under pressure, each of which throws away the record permanently. If a capture takes under five minutes, do it and then contain. If it does not, or if the company has no capability to perform it, contain now and write the gap into the timeline honestly.
- **Do:** put this do-not list in the plan, in bold, next to the containment instructions rather than in front of them, so that a reader in hour one takes it as a set of constraints on how they contain and not as a reason to wait.

  **While you contain, do not:**
  - **Reboot or shut down a compromised host.** Memory contains the running malware, the decrypted secrets, and the network connections. A reboot destroys all of it permanently.
  - **Delete or restart the affected container or pod.** Kubernetes will happily replace it and the evidence is gone in seconds. Cordon the node or scale the deployment while keeping the original object, or capture logs and a filesystem snapshot first.
  - **Rotate the credential before you have pulled its usage log, when pulling that log is quick.** Once rotated, you still have the log, but people forget and the attacker's actions blur with the rotation noise. Capture the "where has this key been used, from what addresses, in what time range" query output first, then rotate. Rotation itself is usually right, it is the ordering that people get wrong. The exception, and it overrides this bullet: a credential that is confirmed live and confirmed publicly exposed gets disabled immediately, and the usage log is pulled after. See [SE-3 secrets and keys](se-3-secrets-and-keys.md), which states this the same way. Rotating a credential production depends on always needs an explicit human yes and an engineer with deploy access on the call.
  - **Terminate the instance or delete the storage bucket.** Take a snapshot first. In AWS create an EBS snapshot and preserve the instance in a stopped-but-not-terminated state only if you have already captured memory. In Google Cloud create a persistent disk snapshot. In Azure create a managed disk snapshot.
  - **Let logs age out.** Note the retention window of every relevant log source in the first hour and export anything with a short window. Many default retentions are 7, 30, or 90 days, and investigations routinely need older data. See [DR-3 logging consumption model](dr-3-logging-consumption-model.md).
  - **Talk to the attacker, or change passwords one at a time in a way that tips them off**, before you understand the scope. Partial eviction turns a contained intruder into a destructive one.
  - **Delete the malicious file, email, or package.** Copy it to a preservation location first. It is the sample the forensics firm will ask for.

- **Verify:** ask an engineer to walk through the do-not list and tell you which one they would have violated in the first five minutes. Whatever they name goes at the top.
- **Time:** 1 hour.
- **Who else is needed:** one infrastructure engineer, to confirm the snapshot mechanics for your actual platform.

### Step 7: Write the containment then eradication ordering

- **Goal:** stop the bleeding fast, remove the cause carefully, and do not confuse the two.
- **Do:** define the three phases in the plan. **Containment** limits further damage and is intentionally blunt and reversible: disable the account, revoke the session, block the IP address, take the service off the internet, suspend the token, isolate the host from the network without powering it off. **Eradication** removes the attacker's access and the root cause: rotate every reachable credential, rebuild the host from a known good image, remove the backdoor, patch the vulnerability, close the misconfiguration. **Recovery** restores service and adds monitoring for return. The rule: contain within minutes, eradicate only after you understand scope, and never partially eradicate. If the attacker has five footholds and you remove three, you have taught them you are watching and kept them inside. Prefer one coordinated eviction event where every credential and session is invalidated together. **The one documented exception to "contain first" is a destructive event.** If the compromised identity holds deletion rights over production data or over the backups, cutting its access first is exactly what provokes the deletion, so the ordering inverts: you break the deletion path first (an object storage legal hold or immutability switch, an explicit deny on delete actions attached to the compromised principal, a delete lock on the resource group) and only then kill the session. That runbook, including the platform-specific actions and the fact that every one of them needs an explicit human yes, lives in [M-6 backups and recovery](m-6-backups-and-recovery.md). Write one line in your plan that points at it, so that the person reading at 2am knows this branch exists.
- **Verify:** for your top two most likely incidents (usually leaked cloud credential and compromised employee account), write the specific containment action next to the specific console path. That is your first playbook.
- **Time:** 2 hours.
- **Who else is needed:** an engineer with production access, to confirm the containment action is actually possible and who can do it.

### Step 8: Build the customer notification decision tree

- **Goal:** notification is a legal and contractual decision, not a mood. Make it mechanical.
- **Do:** put this decision tree in the plan and walk it in every Sev1 and Sev2.

  1. **Was personal data or customer data accessed, exfiltrated, or plausibly accessible to an unauthorized party?** If no with evidence, log the reasoning and stop. If unknown, treat as yes for clock purposes and keep investigating. "We could not rule it out" is a yes for the clock, not a no.
  2. **Start the clocks immediately, in parallel with the investigation.** Under GDPR Article 33, a controller must notify the relevant supervisory authority without undue delay and where feasible within **72 hours** of becoming aware of a personal data breach, and under Article 34 must notify affected individuals without undue delay when the risk to their rights and freedoms is high. If your company is a processor acting for business customers rather than a controller, Article 33(2) requires you to notify your customer (the controller) without undue delay, and your DPA has almost certainly converted that into a specific number of hours.
  3. **Check the contractual window.** US state breach notification laws exist in all fifty states with varying triggers and deadlines, and several specify a fixed outer limit, but in practice the tightest deadline you face is contractual. A signed MSA or DPA promising notification within 24 or 48 hours of discovery beats every statutory deadline. Pull the exact numbers from [CO-3 existing commitments](co-3-existing-commitments.md). Note that sector rules can bite too: if you handle protected health information under HIPAA as a business associate, or payment card data under PCI DSS, or you are a US public company subject to SEC cybersecurity disclosure rules, those add their own timelines and the answer is to involve counsel early rather than to memorize them.
  4. **Decide who notifies.** Notification to a business customer normally goes from an executive or the account owner, never from an engineer in a support ticket. Notification to consumers normally goes with legal review of the wording.
  5. **Write it down.** Whatever you decide, including a decision not to notify, gets recorded in `DECISION-LOG.md` with the date, the reasoning, the facts known at the time, and who approved it. A documented and reasoned decision not to notify is defensible. An undocumented one is not.

- **Verify:** the plan contains an actual number of hours for your largest customers, not the phrase "per contract".
- **Time:** 2 hours, plus waiting on contract access.
- **Who else is needed:** whoever owns contracts, and a lawyer if one exists.

### Step 9: Identify outside counsel and forensics before you need them

- **Goal:** you do not want to be searching for a breach lawyer at midnight, and privilege matters.
- **Do:** identify by name and phone number (a) a law firm with a data breach or privacy practice, and (b) a digital forensics and incident response (DFIR) firm. Call outside counsel when: customer data may have been exposed, a regulator may need to be notified, the incident involves an employee, there is any chance of litigation, or a ransom demand is involved. Engaging the forensics firm through counsel rather than directly is the standard practice for attorney-client privilege over the investigation report. Do not assert to the human that privilege is guaranteed, it is fact-specific and contested in some jurisdictions, but engaging through counsel is the accepted default and costs nothing extra to arrange. **Check the cyber insurance policy first**, because many policies require using a firm from their approved panel and will deny costs otherwise. A retainer is not required at seed or Series A. Two names, two phone numbers, and one intro call is enough, and it costs nothing.
- **Verify:** the names and numbers are in the plan and in a place reachable without corporate single sign-on.
- **Time:** 2 to 3 hours of calls.
- **Who else is needed:** the CEO or CFO to approve any spend and to make the intro.

### Step 10: Adopt the blameless postmortem format

- **Goal:** learning without punishment, because punishment produces hiding, and hiding produces the next breach.
- **Do:** commit to a postmortem for every Sev1 and Sev2, due within five business days. Blameless means describing what a person did and why it made sense to them at the time, using roles rather than names in the narrative where possible, and prohibiting the words "should have" and "careless". The output is action items with a single named owner and a due date, and those action items go into `RISK-REGISTER.md`. Actions that nobody owns do not exist. Use the postmortem template stub in "Evidence to capture".
- **Verify:** the first postmortem produces at least one action item that was actually completed.
- **Time:** 1 hour to write the template, 90 minutes per postmortem.
- **Who else is needed:** everyone who was in the incident, for one meeting.

### Step 11: Run the first tabletop

- **Goal:** find the broken parts of the plan on a Tuesday afternoon instead of during a real breach.
- **Do:** run the 45 minute tabletop script below with four to eight people including at least one executive, one engineer, and one non-technical person. Do not use a nation-state scenario. Use a leaked cloud key or a compromised laptop, because those are what actually happen.
- **Verify:** the exercise produces at least three concrete gaps, and each becomes a row in `RISK-REGISTER.md`.
- **Time:** 45 minutes plus 45 minutes of prep and writeup.
- **Who else is needed:** four to eight people for one 45 minute block. Getting that block on calendars is the hard part, not the exercise.

## An incident that happened before you arrived

At some point in the first month somebody will tell you about something that already happened. A laptop that went missing last year. A repository that was public for a while. An engineer who mentions, in a hallway tone, that "we had a thing with a storage bucket before you started". Or a hunt query from [DR-0 compromise assessment](dr-0-compromise-assessment.md) returns a hit whose timestamps are all months old. This is not the same job as a live incident and running it like one causes real harm, because the questions are now legal questions and the answer may be that a notification obligation was missed. Follow this procedure in order.

**1. Reconstruct the timeline from artifacts before you ask any human a single question.** This ordering is not politeness, it is evidence quality. The moment you ask "do you remember what happened with that bucket", three things change at once: the person begins reconstructing rather than recalling, they compare notes with colleagues and the accounts converge on a shared story that nobody can now un-hear, and somebody quietly tidies up something they are embarrassed about. Artifacts do not do any of that. So first pull what still exists: repository history and the dates of any visibility change, the cloud audit log for the window if it reaches back that far, identity provider sign-in and admin logs, chat history in the engineering channels around the date, ticket systems, and any email thread. Note the retention window of each source before you query it, because for an event that is months old you are often reading the last few weeks of a log that has already aged past the interesting part, and that itself is a fact worth recording. Only when you have the artifact timeline do you go to people, and then you go with specific dated questions ("on 4 March this key was disabled, who did that and why") rather than open ones.

**2. Do not write a conclusion into any durable file.** This is the rule people get wrong, and it is the one that costs the most. You may write dates, actions, log sources, quotes, and what you could and could not confirm. You must not write, in `SECURITY-STATE.md`, `RISK-REGISTER.md`, `DECISION-LOG.md`, an incident file, a Slack message, or a document anyone can export, a sentence of the form "we had a breach", "customer data was exposed", "we were required to notify and did not", or "this was a reportable incident". Those are legal conclusions. You are not qualified to reach them, the company will be bound by them, and they are discoverable. Write the neutral factual version instead, exactly as [CO-3 existing commitments](co-3-existing-commitments.md) has you write a gap in the commitment register: state the observed fact and the open question, not the verdict. "Bucket `X` had public read enabled between the dates `A` and `B` per the configuration history. Access logging was not enabled for that period, so downloads cannot be confirmed or ruled out from available evidence. Referred to counsel on date `C`." That sentence is true, useful, and survives being read out in a deposition. "We leaked customer data in March" is a sentence you wrote about a fact you did not establish.

**3. Route it to counsel before you route it anywhere else, and ask the privilege question explicitly.** The first substantive conversation is with the company's lawyer, in-house or outside, and the chief executive. Not the engineering channel, not the wider team, not a customer, not the board. In that conversation ask one specific question, once, early, the same way CO-3 has you ask it about the commitment register: should this review be conducted under attorney-client privilege, and if so, how do you want me to structure it (who directs the work, who receives the findings, how documents should be labelled, whether a forensics firm should be engaged through the firm rather than directly). Do not assert to anyone that privilege is guaranteed, because it is fact-specific and it is contested in some jurisdictions. Ask the question and follow the answer. If the company has no lawyer at all, that is the finding, and step 9 of the walk above becomes urgent rather than a nice-to-have.

**4. The decision to notify late is not yours.** If it turns out that a notification window was missed, the choices are to notify now, to notify with a stated explanation of the delay, or not to notify, and every one of those is a decision for the chief executive with counsel's advice. Never the security hire, never alone, never "I just sent a quick note to the customer to be transparent". Your job is to put the facts, the applicable clocks from CO-3, and the options in front of the people who own the decision, clearly and in writing, and then to record whatever they decide in `DECISION-LOG.md` with the date, the facts known at the time, the reasoning, and the name of the person who decided. A documented and reasoned decision, including a decision not to notify, is defensible. An undocumented one is not, and an engineer improvising one in a support ticket is the worst of all available outcomes.

**5. If the company declines to act on advice you gave in writing, that is a risk acceptance with a name on it.** This is the part that protects you, so do it deliberately rather than resentfully. Write the recommendation once, plainly, without threat or drama, and send it to the person with the authority to act. If they decline, or if they simply do not respond, open a row in `RISK-REGISTER.md` recording the recommendation, the date it was made, who it was made to, the decision or the non-response, and the name of the accepting person. Set a review date. Then keep working. You are not building a case, you are keeping a record, and the difference matters both ethically and in how the register reads later. A register full of accepted risks with executive names on them is a normal artifact at a startup. A register full of accusations is not.

**6. If you are asked to state something false about it, stop and use the refusal procedure.** "Tell the customer nothing happened", "put in the questionnaire that we have had no security incidents", "say the review found no evidence of access" when it found no evidence either way: these are requests to attach your name to a claim you cannot evidence, and the consequence lands on you personally as well as on the company. Do not improvise a response and do not simply comply while feeling bad about it. Load [08 when it is not working](08-when-it-is-not-working.md) and follow the refusal procedure there, which gives you the wording, the escalation path, and the record to keep.

**What to actually create.** One incident file, `incidents/INC-<YYYY>-<NNN>-<slug>.md`, dated with today's date and clearly marked as a retrospective review of an event that occurred earlier, containing the artifact timeline and the confirmed and unconfirmed columns. One `DECISION-LOG.md` entry for the privilege question and its answer. One `ACCESS-LOG.md` entry for any log access you had to request. Rows in `RISK-REGISTER.md` for the control gaps the reconstruction exposed, which are usually the durable value of the whole exercise: the logging that was not enabled, the alert that did not exist, the offboarding that did not happen. Those gaps are yours to fix and they are safe to write down.

## Decision points

**Do we reuse engineering's severity scale or create a security-specific one?**
DEFAULT: reuse engineering's scale exactly and add security examples to each level. Two scales guarantee that a Sev1 means different things to different people during the worst hour of the year. Change this only if engineering's scale is purely about customer-facing uptime and cannot express "no outage, but an attacker is in our database", in which case add a parallel security dimension inside the same numbering rather than inventing new numbers.

**Public incident channel or private?**
DEFAULT: public within the company for technical incidents, so people stop duplicating work and so the timeline is captured naturally. Switch to a private channel with an explicit named membership list when the incident involves a specific employee (insider risk, HR matters), legal exposure, or unreleased material information. Announce that a private channel exists so people do not think the incident vanished.

**Who is the incident commander?**
DEFAULT: the founding security engineer is IC for security incidents at first, because you know the plan. Change this as soon as you have two trained alternates, because you cannot be IC and the primary SME at the same time on a security-specific incident, and you will eventually be on a plane.

**Do we buy an incident management tool?**
DEFAULT: no, not at this stage. A chat channel, a document, and a calendar invite are sufficient below roughly 100 people. Buy PagerDuty, incident.io, FireHydrant, or Rootly (roughly 20 to 60 US dollars per user per month depending on tier) when you have more than about five incidents a quarter or when the existing paging tool is already in the org and adding a security service is free.

**Do we pay for an incident response retainer?**
DEFAULT: no at seed and Series A, yes once you hold significant customer data or an enterprise customer demands it. Retainers commonly run from roughly 10,000 to 50,000 US dollars per year and often convert to hours. A free substitute: an intro call with two DFIR firms so they have your company in their system and you have a number. Check the cyber insurance panel requirement before spending anything.

**Do we notify when it is ambiguous whether data was accessed?**
DEFAULT: assume access and start the clock, while continuing to investigate. Almost every regret in this space is a delayed notification, not an early one. Change this only on written advice of counsel. Record either way in `DECISION-LOG.md`.

**Do we contain immediately or watch the attacker to learn more?**
DEFAULT: contain immediately. Watching an intruder to gather intelligence is a mature-team activity with a legal risk profile and a real chance of the attacker destroying data when they notice. A first security hire at a startup contains fast. Deviate only with counsel involved and an explicit executive decision logged.

## Danger zone

Every action below requires an explicit human yes, spoken or written, before the agent runs or recommends running it. State the risk out loud first.

- **Disabling or suspending a user account.** Can lock out a founder or the only person with a critical credential. If the account is also the recovery contact for the identity provider or the cloud root account, you can lock the entire company out permanently. STOP: confirm break-glass access exists and is tested before suspending any admin.
- **Rotating or deleting production credentials.** Rotating a database password, a cloud access key, or a signing key will break every service that uses it, potentially instantly and silently. Requires an engineer with deploy access on the call, and a rollback plan. Also see [SE-3 secrets and keys](se-3-secrets-and-keys.md).
- **Revoking all sessions or forcing a global password reset.** Locks out every employee at once, including the people who need to run the incident. Do it only after the responders have out-of-band contact set up.
- **Terminating, rebooting, or deleting a compromised host, pod, or bucket.** Irreversible destruction of evidence, and possibly of customer data. Snapshot first, always.
- **Taking a production service offline for containment.** Customer-visible outage, revenue impact, possible service level agreement (SLA) credits. Requires the person who owns the availability decision, usually the CTO or VP Engineering, not the security hire acting alone.
- **Any external communication.** A customer email, a status page update, a tweet, a press response, or a regulator filing is not reversible. All external comms go through one named person with executive and, where relevant, legal sign-off. An engineer explaining the incident helpfully in a support ticket has created a legal document.
- **Paying or negotiating a ransom.** Legal exposure including sanctions risk. Executive and counsel decision only, never a security engineer decision.
- **Restoring from backup over live data.** Can destroy the current state and any remaining forensic artifacts, and can restore the attacker's foothold along with the data.
- **Engaging a forensics firm.** Real money, often 25,000 US dollars and up, and possibly a policy violation if the insurer requires a panel firm. CEO or CFO approval, and check insurance first.

## Do not do this yet

- Do not write a separate playbook for every threat type. Two playbooks (leaked credential, compromised employee account or laptop) cover the large majority of real startup incidents. Add a third for a malicious dependency once you have read [07 modern cells](07-modern-cells.md).
- Do not build a 24/7 security on-call rotation with one person. You will burn out and the coverage will be fictional. Ride the existing engineering on-call and add a security escalation path.
- Do not buy a security information and event management (SIEM) platform in order to have an IR plan. The plan is prose, not tooling. Logging comes later and deliberately, see [DR-3](dr-3-logging-consumption-model.md).
- Do not write a 40 page plan modeled on NIST SP 800-61 or an enterprise template. It will not be read, and an auditor asking for an IR plan is checking that it exists, is approved, and was tested, not that it is long.
- Do not run a red team or hire a penetration tester before the IR plan exists. If they find something real you will have no process to respond with.
- Do not promise a recovery time objective (RTO) or a specific notification time in a public document until you have checked what you can actually do. See [CO-1 public security docs](co-1-public-security-docs.md).
- Do not conflate an outage with a security incident in the plan text. Some incidents are both, but treating every outage as a security incident makes people ignore the security process.

## Evidence to capture

**Into `SECURITY-STATE.md`, under the DR section, cell DR-1:** the status (`unknown`, `none`, `partial`, `done`), the URL of the plan, the date it was last reviewed, the names of the incident commanders, the date of the last tabletop, and any `UNKNOWN` fields still outstanding. Evidence means a link, not an assertion.

**Into `DECISION-LOG.md`:** the severity scale choice and whether it was reused from engineering; the IC roster and who agreed; the public-versus-private channel policy; the notification posture; the choice to buy or not buy a retainer; and every notification decision made during a real incident.

**Into `RISK-REGISTER.md`:** every gap the tabletop exposed, and every postmortem action item, each with an owner, a severity, and a due date. If an executive decides to accept a gap (for example, "no out-of-hours coverage until we hire"), record it as accepted with the accepting person's name.

**Into `ACCESS-LOG.md`:** the contract repository access request, the audit log access requests, and the paging tool access request, with dates requested and granted.

**Into `90-DAY-PLAN.md`:** mark DR-1 complete only when the tabletop has been run, not when the document is written.

**What an auditor or an enterprise customer will ask for later:** a copy of the incident response plan, evidence of management approval (a dated signature or an approval message), evidence that it is reviewed at least annually, evidence that it was tested at least annually (the tabletop notes and attendee list are the artifact), the defined roles, and for SOC 2 specifically, evidence that identified incidents were tracked to resolution. Save the tabletop invite, the attendee list, the notes, and the resulting action items. That bundle answers the request in full.

## Cost and effort

- **Writing the plan, severity table, and decision tree:** 1 focused day, or 2 to 3 half-days spread across a week while waiting on answers. Zero dollars.
- **Getting names, approvals, and contract facts:** 3 to 5 elapsed days of waiting, roughly 3 hours of your time.
- **First tabletop:** 90 minutes of your time plus 45 minutes each from four to eight people. Zero dollars.
- **Free tooling that is genuinely enough:** the existing chat tool, a shared document for the timeline, a calendar invite, and a Signal group as the out-of-band fallback.
- **Cheap upgrades if the money exists:** adding a security service to an existing PagerDuty or Opsgenie account is often no additional cost. A dedicated incident tool (incident.io, FireHydrant, Rootly) runs roughly 20 to 60 US dollars per user per month and is not needed yet.
- **Real money, later:** a DFIR retainer at roughly 10,000 to 50,000 US dollars per year, outside counsel at roughly 400 to 900 US dollars per hour for breach work, and emergency forensics engagements that commonly start around 25,000 US dollars. Cyber insurance frequently covers most of this, which is why finding the policy is step 9 and not step 30.

## 2026 notes

The 2019 slide said "basic incident response plan" and meant a document. Four things have changed materially.

1. **The most likely incident is no longer a server exploit.** It is a stolen browser session or an infostealer on a laptop leading to software-as-a-service (SaaS) access, or a malicious package executing on a developer laptop or a continuous integration (CI) runner. Both of these mean your first containment action is in an identity provider or a package registry, not on a server. Your two starter playbooks should reflect that, and neither of them involves logging into a box.
2. **You may be the upstream.** If a developer's package publishing token or CI credential is stolen and used to publish a poisoned version of something you maintain, you are now the source of a supply chain incident and you owe outbound disclosure to your own users on top of everything else. The plan needs a line for that scenario. See [07 modern cells](07-modern-cells.md).
3. **Third-party application (OAuth) incidents are now a routine category.** An integration you authorized years ago being compromised means an attacker reads your data through a legitimate, fully authorized token, with no login event, no multi-factor authentication (MFA) prompt, and nothing for endpoint tooling to see. Containment is revocation, and the plan should link to the exact revoke path per platform because nobody finds it under pressure.
4. **Regulatory clocks tightened and multiplied.** GDPR's 72 hour authority notification is the well known one, but contractual windows in enterprise agreements are now routinely 24 or 48 hours, and sector rules add more. The practical consequence is that the notification analysis has to start in hour one and run in parallel with the investigation, rather than being the last step. Build the plan so that the comms lead is working the clock while the SME is still working the box.

One thing did not change: Evan Johnson's point that detection and response feels like no progress until suddenly it is good. The plan is the one part of this domain that is finished in an afternoon and immediately worth something, which is exactly why it goes first.

## Failure modes

| What goes wrong | The early tell | Recovery |
| --- | --- | --- |
| The plan exists but nobody can find it | Ask a random employee where to report a phishing email and they guess | Move it to the wiki homepage, pin it in the main chat channel, and mention it in onboarding ([CS-3](cs-3-onboarding-offboarding.md)) |
| Nobody ever declares an incident | Zero declarations in three months at a company where things clearly happen | The bar is too high or people fear blame. Lower the bar explicitly, publicly thank the first person who over-declares |
| The IC also debugs | The timeline goes quiet for 40 minutes while the "leader" is in a terminal | Hand the shell to the SME. If only two people are present, the IC keeps the timeline and asks questions, and never types |
| No scribe, so no timeline | After the incident nobody can say when access was cut off | Reconstruct from chat logs immediately while memory is fresh, then make scribe a named role in the plan and assign it in the first two minutes of every incident |
| Evidence destroyed in the first ten minutes | Someone says "I already restarted it" or "I rotated the key already" | Preserve what remains, note the gap honestly in the timeline, and move the do-not list so it sits directly beside the containment steps where the reader will hit it at the moment they act |
| Notification clock discovered late | Someone reads the MSA on day three and finds a 24 hour window | Notify immediately with what you know, tell counsel, and finish [CO-3](co-3-existing-commitments.md) this week so it never repeats |
| Everyone talks to the customer | A customer quotes three different explanations back at you | One comms lead, immediately. Send an internal note saying all customer questions route to that person |
| The postmortem becomes a blame session | People stop volunteering information mid-meeting | Stop the meeting, restate the blameless rule, rewrite the document using roles instead of names |
| The plan is written and never tested | It is eighteen months old and half the named people have left | Run the 45 minute tabletop this quarter. Add a recurring calendar reminder to review names every six months |
| Chat tool is the compromised thing | You are coordinating an identity provider breach inside the tool that uses that identity provider | Switch to the out-of-band group. If you never set one up, this is the moment you wish you had, so set it up in step 5 |

## Templates

### One page IR plan template

```markdown
# Incident Response Plan
Owner: <name>  |  Last reviewed: <YYYY-MM-DD>  |  Approved by: <exec name, date>

## 1. Declare an incident
ANYONE at <company> can declare a security incident. You will never be in trouble
for declaring something that turns out to be nothing. Over-reporting is what we want.

How: post in <declaration channel> with the words "I am declaring an incident",
or message <name> directly, or call <phone number> if you get no reply in 10 minutes.
(Declaration channel is the single front door until DR-4's split gate fires. Write the
real name here and use it everywhere.)

## 2. What counts
Anything that looks like: unauthorized access, leaked credentials or keys, a lost or
stolen laptop or phone, a suspicious email someone clicked, customer data in the wrong
place, malware, a suspicious charge, an extortion message, or a stranger asking
employees for access. If unsure, declare it.

## 3. Severity
See the severity table. If you cannot decide between two levels, pick the higher one.

## 4. Roles (assigned out loud in the first 5 minutes)
- Incident commander (IC): decides and coordinates. Does NOT debug.
- Scribe: keeps the timeline. Does nothing else.
- Comms: internal updates, exec updates, any customer or public message.
- Subject matter expert (SME): the person who knows the affected system.
Current IC roster: <name 1>, <name 2>. Out of hours: <how to reach them>.

## 5. Where we work
Declarations: <declaration channel, same name as section 1>
This incident: <#inc-YYYY-MM-DD-name>  |  Bridge: <standing video link>
If chat or single sign-on is compromised, fall back to: <Signal group / phone tree>

## 6. CONTAIN NOW. WHILE YOU CONTAIN, NEVER DO THESE THINGS
Containment is never delayed to preserve evidence. Preserve in parallel. If a capture
takes under 5 minutes, take it and then contain. If it does not, contain and write the
gap into the timeline. But while containing:
Do NOT reboot, shut down, or terminate the affected machine. Isolate it from the
  network instead and leave it running.
Do NOT delete the pod, container, instance, or bucket. Snapshot first.
Do NOT delete the malicious file or email. Copy it somewhere safe first.
Do NOT close or delete the account under investigation. Suspend or revoke instead.
Do NOT rotate the credential until its usage log has been captured, UNLESS the
  credential is confirmed live and publicly exposed, in which case disable it now.
Note the retention window of every relevant log NOW and export anything short-lived.

## 7. Contain, then eradicate, then recover
Contain (minutes, reversible): disable the account, revoke sessions and tokens,
block the address, isolate the host without powering it off, take the service off
the internet.
Eradicate (only after scope is understood, all at once): rotate every reachable
credential, rebuild from known-good, patch the cause.
Recover: restore service, add monitoring for the attacker's return.

## 8. Who we may have to tell, and by when
Run the notification decision tree. Known clocks:
- <Customer A>: <N> hours per MSA section <x>
- <Customer B>: <N> hours per DPA section <x>
- GDPR (if applicable): supervisory authority within 72 hours of awareness
- Other statutory or sector obligations: <fill in with counsel>
Nobody communicates externally except <comms lead name>, with <exec> sign-off.

## 9. Outside help
Counsel: <firm, name, phone>   DFIR: <firm, name, phone>
Cyber insurance: <carrier, policy number, claims phone, panel requirement yes/no>
Call counsel when: customer data may be exposed, a regulator may be involved, an
employee is involved, litigation is plausible, or there is a ransom demand.

## 10. After
Blameless postmortem within 5 business days for Sev1 and Sev2. Action items get one
named owner and a due date, and are tracked in the risk register.
```

### Severity table

Adjust the examples to real system names before publishing. If engineering already uses different numbers, match theirs.

**This table is the single source of truth for severity in this skill.** Four levels, spelled `Sev1` through `Sev4`. Nothing else, including any incident file template, should restate these definitions, because two copies drift and the drift is discovered during the incident. An incident record should carry the level and a link back here, not a second copy of the meanings. Sev4 matters more than it looks: it is the landing place for the near miss and the reported-and-blocked phishing email, and if there is nowhere to record a Sev4 then the "over-declaring is the desired behavior" promise in step 3 is not true, because half of what people bring you would have no file to go in.

**One value sits outside the four, and it is not a fifth level.** An incident that has been declared but not yet triaged carries the severity `unassigned`, which is the correct value at the moment of declaration and is legal only while the incident's status is `scoping`. It exists so that nobody has to invent a value at three in the morning, and it does not survive the end of the working day: by then the incident carries one of the four levels, or it is closed as not an incident with a one line reason. An incident record uses these values and links back to this table rather than restating the meanings.

| Level | Meaning | Examples | Response | Who is woken |
| --- | --- | --- | --- | --- |
| **Sev1** | Confirmed or highly likely unauthorized access to customer data, production systems, or the ability to affect customers | Attacker has valid production database credentials; customer data found in a public bucket; ransomware on a production host; an active intruder in the cloud account; our published package was poisoned | Immediate, all hands, 24/7, updates every 30 minutes | CEO, CTO, security lead, counsel |
| **Sev2** | Credible compromise with no confirmed customer data impact yet, or a serious control failure | Employee laptop with an infostealer; an administrator account phished with MFA bypassed; a long-lived cloud key found in a public repository; a third-party integration provider reports a breach affecting our tenant | Same business day, out of hours if evidence suggests active use, updates every 2 hours | CTO, security lead |
| **Sev3** | Contained or low-impact issue that still needs investigation and a fix | A single non-privileged account phished with no successful login; a vulnerable dependency actively exploitable but not exploited; a lost phone with full disk encryption and remote wipe available | Next business day, updates daily | Security lead |
| **Sev4** | Hygiene issue or a near miss worth recording | A phishing email reported and blocked; an expired certificate; a misconfiguration found and fixed by the owner | Normal work queue, no incident channel needed | Nobody |

Tie-break rule: if you cannot choose between two levels, choose the higher one and downgrade later. Downgrading is easy and free. Upgrading three hours late is neither.

### Customer holding statement template

Use this when you must say something before you know everything. Approved by comms lead and, where relevant, counsel, before it is sent. Never speculate about cause, never name a suspected attacker, never promise a number you have not verified.

```
Subject: Security notice regarding <product>

Hello <name>,

We are writing to let you know about a security matter affecting <product/service>.

What we know: On <date, time, timezone> we identified <plain factual description of
what happened, no speculation about cause>. We began investigating immediately.

What we have done: <containment actions taken, stated plainly>. <Service status.>

What we do not yet know: We are still determining <specific open questions, for
example whether any of your data was accessed>. We will not speculate ahead of the
evidence.

What you should do right now: <specific action, or "no action is required from you
at this time">.

Next update: We will send you another update by <specific date and time>, even if
the only news is that the investigation is ongoing.

Questions: <single named contact and address>.

<Name, title>
```

The commitment to a next update time is the most important line. It converts an anxious customer repeatedly emailing your CEO into a customer waiting until Thursday at 5pm.

### 45 minute tabletop script

Four to eight people. One facilitator (you). No laptops except the scribe. Say up front: "This is a test of the plan, not of the people. Nothing said here goes in anyone's performance review." Have someone take notes on gaps.

**Scenario (read aloud):** It is 4:40pm on a Thursday. A support engineer forwards you an email from an outside researcher. It contains a screenshot of a file listing from one of our cloud storage buckets, and it includes filenames that look like customer exports. The email says "you may want to look at this" and gives no other detail. Nobody on the team recognizes the bucket name.

**Minutes 0 to 5, declaration.** Who declares this an incident? What exactly do they type and where? What severity, and why? Gap to watch for: people debating whether it is "really" an incident, or not knowing the channel.

**Minutes 5 to 12, roles and war room.** Assign IC, scribe, comms, SME out loud. Where does everyone gather? Who is missing and how do we reach them at 4:40pm on a Thursday? Gap: no scribe named, or IC immediately starts debugging.

**Minutes 12 to 20, first technical moves.** What is the very first thing you check, and do you have access to it right now? Inject: **the bucket is confirmed public, and the access logs for it are not enabled.** Now what? Gap: nobody knows whether logging exists, nobody can tell what was downloaded, and someone wants to immediately make the bucket private, which is correct containment but must be paired with capturing what evidence exists first.

**Minutes 20 to 28, scope and evidence.** How do we determine what was in the bucket and for how long it was exposed? Who has the ability to snapshot or copy the contents before anything changes? Inject: **one file is named `customers_export_2026_q1.csv` and an engineer says "I think I can just delete it".** Stop and discuss why that is the wrong move.

**Minutes 28 to 36, notification.** Do we have to tell anyone? Which contracts apply? Who reads the MSA and how long does that take? Does GDPR apply to this data? Who calls counsel and do we have the number? Inject: **the researcher emails again saying they will publish a blog post in 48 hours.** Who responds to the researcher, and what do they say? Gap: nobody knows the contractual window, nobody has counsel's number, everyone wants to reply to the researcher personally.

**Minutes 36 to 42, comms.** Who tells the CEO, and when? Who writes the customer message? What goes on the status page, if anything? Who is allowed to answer if a customer asks in a shared Slack channel? Gap: three people assume they are the one who tells the CEO.

**Minutes 42 to 45, close.** Go around the room. Each person names one thing that was unclear or missing. Write every one down.

**Afterwards, 30 minutes.** Turn each gap into a row in `RISK-REGISTER.md` with an owner and a date. Save the invite, the attendee list, and the notes as the audit artifact. Log the exercise date in `SECURITY-STATE.md` under DR-1.

## Related cells

- [DR-0: Are we already compromised?](dr-0-compromise-assessment.md) - the historical hunt. Any hit there opens an incident here, and if the hit is months old, read "An incident that happened before you arrived" above before you talk to anyone.
- [DR-2: What are the top security signals for your org?](dr-2-top-security-signals.md) - the plan is only triggered if something detects. Do this next.
- [DR-3: Consumption model for logging](dr-3-logging-consumption-model.md) - retention windows decide what you can investigate.
- [DR-4: Establish a communication channel with the rest of the company](dr-4-company-comms-channel.md) - the reporting path that makes "anyone can declare" real.
- [CO-3: Understand existing commitments](co-3-existing-commitments.md) - the contractual notification clocks that override everything.
- [CO-1: Public facing security docs](co-1-public-security-docs.md) - where a vulnerability disclosure address lives.
- [SE-3: How you manage secrets, api keys, customer secrets](se-3-secrets-and-keys.md) - credential rotation mechanics for containment.
- [SE-4: Bug bounty and disclosure](se-4-bug-bounty-and-disclosure.md) - the inbound researcher path that starts many incidents.
- [CS-1: Identity and Access Management](cs-1-identity-and-access.md) - session revocation and break-glass access.
- [CS-2: Endpoint security](cs-2-endpoint-security.md) - laptop isolation and remote wipe as containment actions.
- [M-6: Backups and recovery](m-6-backups-and-recovery.md) - the destructive event runbook. Read it before containing anything if the attacker holds deletion rights, because the containment ordering inverts there.
- [07: Modern cells](07-modern-cells.md) - supply chain, CI/CD, and OAuth incident types the 2019 plan did not anticipate.
- [08: When it is not working](08-when-it-is-not-working.md) - the refusal procedure, for when you are asked to state something about an incident that you cannot evidence.
- [04: Interrupts](04-interrupts.md) - how to park current work when an incident interrupts it.
