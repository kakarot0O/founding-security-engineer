# Interrupt and context switch protocol

> **Load when:** the human says "hold on", "park this", "urgent", "incident", "switch", "resume", "where were we", "what is parked", or "drop it"; when an interruption of any kind arrives mid-task; when the agent itself discovers something that outranks the work in progress; or at the start of any session where the previous session ended with unfinished work.

## Why this file exists

A first security hire gets interrupted constantly. Sales needs a questionnaire answered before a contract signs. An engineer wants a design reviewed before a release train leaves. Somebody forwards a phishing email. A founder pulls you into a two day fire that has nothing to do with security. Each interruption is individually reasonable. Together they are the single biggest reason a founding security program stalls: work gets started, abandoned at 60 percent, and quietly forgotten, and nobody notices because there is nobody else on the team to notice.

The fix is not discipline. The fix is a written stack. Every time work is interrupted, the exact state of that work gets written to a file before anything else happens. Every time an interruption ends, that file is read back and the work resumes at the precise next action. The agent owns this bookkeeping so the human does not have to hold it in their head.

The rule underneath everything in this file: **nothing is ever dropped silently.** Work can be paused, deprioritised, delegated, or explicitly abandoned with a written reason. It can never just evaporate.

## The Context Stack

The Context Stack is a last in, first out stack of **frames**. A frame is one unit of parked work. It lives at `.security/CONTEXT-STACK.md` inside the state directory. If the working directory is a code repository the state directory is `./.security/`. If there is no repository (the human is working from a laptop home directory, a Downloads folder, an empty directory) the state directory is `~/security-program/<org-slug>/` and the file is `~/security-program/<org-slug>/CONTEXT-STACK.md`. Use whichever the cold start protocol in `references/00-cold-start.md` already established. Do not create a second one.

Rules of the stack:

1. The frame at the top of the `## Active stack` section is the work currently paused most recently. Resume pops from the top unless the human names a different frame identifier.
2. There is exactly one **in flight** item at a time, and it is not in the file. The file holds only paused work. If work is in flight and the session ends, that work gets parked into the file before the session ends.
3. Frame identifiers are monotonic and never reused: `F-1`, `F-2`, `F-3`. If `F-4` is dropped, the next new frame is still `F-5`.
4. Frames move to `## Closed frames` when finished or dropped. They are never deleted.

### Exact file format

Write the file exactly like this. The agent parses its own output on the next session, so the shape must be stable.

```markdown
# Context Stack

State directory: ./.security/
Last updated: 2026-08-25T14:02Z
Frames parked: 2
Next frame id: F-6

## Active stack

### F-5 Finish the AWS IAM user inventory
- Grid cell: CS-1 (Identity and Access Management)
- Class: planned work
- Opened: 2026-08-24
- Parked at: 2026-08-25T13:41Z
- Parked because: F-6 arrived, class 1 live incident (see DECISION-LOG.md 2026-08-25)
- Completed so far:
  - Ran `aws iam list-users --output table` across the two accounts we know about (prod, sandbox)
  - Found 11 IAM users, 7 with active access keys, 4 keys older than 400 days
  - Wrote the raw output to .security/evidence/2026-08-24-iam-users.txt
- Exact next action: Ask Priya (VP Eng) in #eng whether accounts 4455 and 9912 in the
  organisation are still live, using the message drafted in ACCESS-LOG.md under
  "Pending: AWS org account list". Do not disable any key yet.
- Open decisions awaiting a human answer:
  - D1: Do we rotate the 4 stale keys before or after we have SSO working? Recommendation
    is after, so we do not lock out a deploy path we have not mapped yet. No answer yet.
- Files touched:
  - .security/SECURITY-STATE.md (CS-1 set to partial)
  - .security/evidence/2026-08-24-iam-users.txt (new)
  - .security/RISK-REGISTER.md (R-3 added: long lived static cloud keys)
- Blocked on: answer from Priya (asked 2026-08-25, no reply yet)
- Age: 1 day

### F-2 Draft the public security page
- Grid cell: CO-1 (Public facing security docs)
- Class: planned work
- Opened: 2026-08-18
- Parked at: 2026-08-20T16:10Z
- Parked because: human asked to park it and move to identity work first
- Completed so far:
  - Outline agreed, four sections: how we handle data, how we secure it, how to report
    a vulnerability, subprocessor list
  - Security contact inbox does not exist yet, blocking the reporting section
- Exact next action: Ask the human to create security@<company domain> as a group with
  at least two members, then paste the address back so the page can be finished.
- Open decisions awaiting a human answer:
  - D1: Do we publish a subprocessor list now or wait until legal reviews it?
- Files touched:
  - .security/drafts/security-page.md (new, 40 percent complete)
- Blocked on: creation of a security contact address
- Age: 5 days  ← ESCALATE, older than 5 days

## Closed frames

### F-4 Answer the Acme security questionnaire (CLOSED 2026-08-23, completed)
- Grid cell: CO-2 (Knowledge base for questionnaires)
- Outcome: 62 of 71 questions answered from the knowledge base, 9 escalated to eng,
  returned to sales 2026-08-23. Nine new question/answer pairs added to
  QUESTIONNAIRE-KB.md.

### F-3 Evaluate three endpoint agents (CLOSED 2026-08-21, dropped)
- Grid cell: CS-2 (Endpoint security)
- Outcome: DROPPED. Reason: no budget approved this quarter and the built in disk
  encryption and OS firewall settings cover the immediate risk. Recorded as R-7 in
  RISK-REGISTER.md, accepted by the CTO, revisit at 40 employees.
```

Every field is mandatory. If a field is genuinely empty write `none`, never leave it blank. The two fields that matter most are **Exact next action** and **Open decisions awaiting a human answer**, because those are the two things a future session cannot reconstruct from the other state files.

## Trigger phrases and what each one does

The human will not memorise these. Recognise the **intent**, not the exact words. "Hang on a sec", "wait, something came up", "put a pin in that", and "stop, more important thing" all mean park. If the intent is ambiguous, ask one closed question: "Do you want me to park the identity work and pick this up now, or note it and finish the current step first?"

| Phrase family | Intent | Agent does |
|---|---|---|
| "park this", "put a pin in it", "hold that thought" | Pause current work, no new work named yet | Run PARK, then ask what the new work is |
| "hold on", "wait", "stop" | Pause immediately, possibly only for a moment | Stop the current action, do not write files yet, ask if this is a park or a pause |
| "switch", "switch to X", "do X instead" | Pause current work and start named work | Run SWITCH |
| "urgent", "this is on fire", "drop everything" | High priority arrival, class unknown | Run the triage rubric first, out loud, before switching |
| "incident", "we have been breached", "phishing", "someone got in" | Possible live incident | Treat as class 1 until disproven, jump to `references/dr-1-incident-response-plan.md` |
| "resume", "back to it", "carry on" | Return to top frame | Run RESUME on the top frame |
| "resume F-2", "back to the security page" | Return to a named frame | Run RESUME on that frame, leave the others parked |
| "where were we" | Orientation request | Print the top frame's restatement, do not start work |
| "what is parked", "what is open", "show the stack" | Full stack request | Print every active frame as one line each plus age |
| "drop it", "forget that", "not doing that" | Explicit abandonment | Never delete. Move the frame to Closed with `dropped`, require a one line reason, and record the residual risk in `RISK-REGISTER.md` |

The agent must also self trigger. If the human starts talking about something clearly outside the current frame's grid cell for more than one exchange, say so: "We have drifted from CS-1 to CO-2. Do you want me to park the identity work, or is this a quick aside?"

## Interrupt triage rubric

Every interruption gets classified out loud, in one line, before any other action. Say the class, say the reason, say the proposed handling, then wait for a go or no-go unless it is class 1.

### Class 1: live security incident

**Definition:** there is credible reason to believe an attacker has access right now, or data has left, or a system is being actively abused. Signals: reported phishing with a credential entered, an alert from a cloud provider about a leaked key, a customer reporting data they should not see, ransomware, a public repository containing a live secret, an unexpected admin account, a supply chain advisory naming a package the company actually installs.

**Handling:** pre-empts everything. Do not ask permission to switch. Do not finish the current sentence of work.

1. Say: "Treating this as a class 1 live incident. Parking current work now."
2. Run PARK on the in flight work with a two line frame if that is all there is time for.
3. Open `references/dr-1-incident-response-plan.md` and follow it from step 1.
4. Create the incident frame as `F-n` with class `incident` and start the timeline immediately.
5. Do not close the incident frame until containment, eradication, and a written timeline exist.

**Downgrade rule:** if the evidence turns out benign (the phishing link was a marketing email, the alert was a false positive), say so explicitly, close the incident frame with the outcome, and resume. Do not quietly let an incident frame go stale.

### Class 2: revenue blocking

**Definition:** a deal, renewal, or contract is waiting on a security artefact. Security questionnaire, vendor risk assessment, a customer's security team wanting a call, a request for a penetration test report or a compliance report.

**Handling:** time box and schedule. Do not drop everything, and do not refuse. This is the class where a founding security hire loses entire quarters, because questionnaires are infinitely elastic. The talk this program is built on is blunt about it: your highest and best use is not completing questionnaires for sales teams.

1. Ask two closed questions: "What is the actual deadline, the date the deal slips?" and "Is this blocking signature, or is it a nice to have from their security team?"
2. If the deadline is more than three working days out, park nothing. Schedule a fixed block, name the day, and continue current work.
3. If it is genuinely today or tomorrow, SWITCH with a stated time box: "I am giving this 90 minutes, then we go back to F-5 regardless of completion state."
4. Every time this class fires, add one line to the knowledge base at `QUESTIONNAIRE-KB.md` so the next one is cheaper. See `references/co-2-questionnaire-knowledge-base.md`.
5. If this class fires more than twice in two weeks, raise it: the answer is a self service knowledge base or a trust page, not more of your hours.

### Class 3: engineering blocking

**Definition:** an engineer or a team cannot ship until you answer. A design review before a release, a question about whether an approach is acceptable, a dependency they want to add, a permission they want granted.

**Handling:** fast lightweight answer now, proper follow up later. Blocking engineers is how a security function becomes something people route around, and once they route around you it takes a year to get back.

1. Give the answer within the current session if the answer is knowable in under 15 minutes. State confidence: "High confidence yes", or "Provisional yes, with one condition".
2. If the answer is a conditional yes, write the condition down as its own frame so the follow up actually happens.
3. If the answer is genuinely not knowable fast, say so and give a time: "I need two hours on this. Can you ship behind a flag, or is the release train leaving at 5?"
4. Never say no without offering the alternative that gets them shipped.
5. Record the review in `SECURITY-STATE.md` under SE-1 as evidence that an ad hoc design review process exists, because it does now.

### Class 4: new information that changes the plan

**Definition:** a fact arrives that invalidates part of the plan. "We just signed an enterprise customer who needs a compliance report in 90 days." "We are migrating from one cloud to another next month." "The CTO already promised the board we would have single sign on by Q4." "We acquired a company."

**Handling:** record now, re-plan at the next natural boundary. Do not re-plan mid task. Re-planning is expensive and half of these facts change again within a week.

1. Write the fact to `DECISION-LOG.md` under a dated entry, marked `input, not yet actioned`.
2. Say out loud what it probably changes: "This likely moves CO-3 and CO-4 into the first 30 days and pushes SE-4 out entirely."
3. Do not touch `90-DAY-PLAN.md` yet.
4. At the next natural boundary (end of current frame, end of session, start of next session) run the re-plan and rewrite `90-DAY-PLAN.md`, citing the dated `DECISION-LOG.md` entry as the reason.
5. Exception: if the new fact means current work is now pointless (you are hardening a cloud account that is being decommissioned next week), stop immediately, say why, and re-plan on the spot.

### Class 5: distraction

**Definition:** interesting, security adjacent, and not on the plan. A vendor demo request. A conference talk about a threat that does not apply. A tool somebody wants evaluated. A newsletter item. A "we should really look into" from a founder with no deadline and no owner. A shiny new detection idea that would take three weeks to build and would fire twice a year.

**Handling:** name it as a distraction, out loud, with a reason. Record it. Decline to start it.

Use this exact shape:

```
That is a distraction relative to the current plan, and here is why: it addresses
<risk>, which sits below <top risk> in RISK-REGISTER.md, and it would cost roughly
<estimate> against a 90 day plan that currently has <n> days of committed work.

I have added it to RISK-REGISTER.md as <ID> with status `open` and a review date so it is not lost. Recommendation: revisit at
<trigger, for example "after CS-1 is done" or "at 50 employees" or "if it appears in
a customer questionnaire twice">.

Next action stays: <exact next action from the current frame>. Go or no-go?
```

Being wrong here is fine. Being silent is not. If the human overrules and wants it now, that is their call, but the reasoning is on the record and the frame is parked properly.

## The PARK procedure

Run this every time work is set down, without exception, even for a five minute interruption. The cost is thirty seconds. The cost of not doing it is a lost afternoon three weeks later.

1. **Stop cleanly.** Finish the tool call in flight. Do not start a new one. If a mutating command was about to run, do not run it.
2. **Confirm nothing is half applied.** If a change was partially made (a policy edited but not saved, a group created but not populated, a file written but not committed) say so explicitly in the frame under `Completed so far`, with the exact partial state. This is the single most dangerous kind of parked work.
3. **Assign the frame id.** Read `Next frame id` from `CONTEXT-STACK.md`, use it, increment it.
4. **Write the frame** to the top of `## Active stack` using the full format above. Every field filled or set to `none`.
5. **Write the exact next action as an imperative sentence a stranger could execute.** Not "continue the IAM work". Instead: "Run `aws iam list-access-keys --user-name deploy-bot` in the prod account and check the CreateDate on each key."
6. **Move any unanswered question into `Open decisions`.** If the human was asked something and did not answer, it goes here, not into the void.
7. **Sync the other state files.** If the parked work changed a cell's status, update `SECURITY-STATE.md` now, while the evidence is fresh. If it surfaced a risk, add it to `RISK-REGISTER.md` now. Parked work must not be the only place a finding lives.
8. **Confirm to the human in two lines.** "Parked F-5 (CS-1 identity inventory) with the next action recorded. Two frames now parked. What is the new thing?"

## The SWITCH procedure

SWITCH is PARK plus a triage plus a start.

1. Run the triage rubric and say the class out loud. Class 5 stops here, with the decline message.
2. Run PARK on the current work.
3. **Check stack depth.** If parking this frame makes three or more active frames, flag overload before starting anything new (see the anti-loss rules below).
4. **State the new work in one line with its grid cell.** "New work: answering the Acme questionnaire, CO-2, class 2 revenue blocking, time boxed to 90 minutes."
5. **Open the relevant cell playbook.** Do not improvise a cell that already has a reference file.
6. **State the first action and ask for a go.** Even under time pressure. The only exception is class 1.
7. Do not create the new frame in `CONTEXT-STACK.md` yet. Frames are created when work is parked, not when it starts. The in flight work lives in the conversation. The exception is class 1 incidents, which get a frame immediately because the timeline must be written from minute zero.

## The RESUME procedure

The whole point of the stack is that this step is cheap and accurate.

1. **Read `CONTEXT-STACK.md` from disk.** Do not resume from memory of the conversation, even if the conversation is still open. The file is the source of truth and it may have been edited.
2. **Pick the frame.** Top of stack by default. If the human named a frame, use that one and say the others stay parked.
3. **Restate the context in at most five lines.** This is a hard limit. The format:

```
Resuming F-5, cell CS-1, parked 1 day ago.
Done: inventoried 11 IAM users across 2 accounts, 4 keys older than 400 days.
Blocked on: Priya has not confirmed whether accounts 4455 and 9912 are live.
Open decision D1: rotate stale keys before or after SSO. My recommendation is after.
Next action: chase Priya in #eng with the drafted message. Go or no-go?
```

4. **Re-verify anything that could have changed while parked.** If the frame is more than a day old and it involved a system state (a permission, a key, a policy, a member list), re-run the read only discovery command before acting on the old finding. State that you are doing this: "That inventory is 6 days old, re-running the read only list before we act on it."
5. **Do not start work until the human answers the go or no-go.** If they answer the open decision at the same time, record the answer in `DECISION-LOG.md` with the date and who decided.
6. **Remove the frame from `## Active stack`** only when it is finished or dropped, not when it is resumed. If the session ends mid resume, the frame must still be there.

## Agent initiated interrupts

Sometimes the agent is the interruption. While inventorying identity providers it finds a public storage bucket. While reading a build configuration it finds a long lived cloud key. While reviewing a design it notices the same pattern is already deployed in production.

**Hard rule: never silently switch tasks.** Do not start fixing the new thing because it feels more important. Surface it, recommend, and let the human decide. Silently switching is how the human loses trust in the stack, and once they stop trusting it they stop using it.

Use this exact message format:

```
INTERRUPT (agent initiated)

Finding:   <one sentence, plain language, no acronym unexpanded>
Severity:  <critical | high | medium | low> because <one line of reasoning tied to blast radius>
Evidence:  <the exact command output, file path and line, or console screen the human can
            check themselves. Never assert without this.>
Cost of waiting: <what gets worse, and how fast. "Nothing changes if we wait a week" is a
            valid and useful answer.>
Recommendation: <park current work and handle now | finish current step then handle |
            add to RISK-REGISTER.md and schedule | accept and move on> because <reason>
Current frame: <id and exact next action, so it is trivially resumable either way>

Your call. Go or no-go on the recommendation?
```

Severity guidance for a startup with no team, so the word means something consistent:

- **Critical:** an unauthenticated path to customer data, a live credential in a place an outsider can read, or evidence of actual compromise. Recommend parking immediately.
- **High:** a credential or permission with production blast radius that requires an insider or a chained step to abuse. Recommend finishing the current step, then handling.
- **Medium:** a real weakness with a plausible attack path but meaningful preconditions. Recommend registering and scheduling.
- **Low:** hygiene, defence in depth, or a finding that only matters after the company grows. Recommend registering only.

Every agent initiated interrupt, including the ones the human declines, gets a row in `RISK-REGISTER.md` with the severity, the evidence pointer, and the decision. If the human declines a critical or high finding, the register row must name who accepted the risk and the date. That is not bureaucracy, it is the thing that protects the human when it goes wrong later.

## Rules that prevent loss

These are enforced by the agent, not by the human's memory.

1. **Three frame ceiling.** When parking a frame would make three or more active frames, stop and say: "That would be three parked frames. We are accumulating unfinished work faster than we are closing it. Before I park this, pick one: close F-2 today, drop F-2 with a reason, or hand F-2 to someone else. Which?" Do not proceed until answered. Four or more parked frames means the plan is wrong, and `90-DAY-PLAN.md` should be regenerated with less in it.

2. **Print the stack at the end of every session.** Unprompted. One line per active frame: id, title, cell, age, blocked on, next action. Then one line of judgement: which frame is at risk of rotting and what to do about it.

3. **Age escalation.** Any frame older than **five calendar days** gets flagged on every stack print with `← ESCALATE`. On the first print after day five the agent must force a choice and offer exactly three options: resume it now, drop it with a written reason and a risk register entry, or convert it into a scheduled item in `90-DAY-PLAN.md` with a named date. "Leave it parked" is not an option. Any frame older than **fourteen days** is auto proposed for dropping: "F-2 has been parked 14 days. My recommendation is we drop it and record the residual risk. Objection?"

4. **Blocked frames get chased, not just aged.** If a frame's `Blocked on` names a person and the block is older than two working days, the agent drafts the chase message, copy pasteable, and puts it in `ACCESS-LOG.md` under the pending request. Waiting silently on a colleague is the second most common way founding security work dies.

5. **Nothing is dropped silently.** Dropping requires: a written reason, a move to `## Closed frames`, and a row in `RISK-REGISTER.md` if any risk remains unaddressed. If the human says "forget it" without a reason, ask for one sentence. "We decided it is not worth the time right now" is a perfectly good sentence.

6. **Partial mutations are never parked without a note.** If a change was half applied to a live system, the frame's first line under `Completed so far` must say so in capitals: `PARTIAL CHANGE APPLIED: group sec-admins created but empty, no policy attached.` On resume, the first action is always to verify and either complete or revert it.

7. **The stack file is written before the interruption is discussed, not after.** The temptation is to talk about the shiny new thing first and write the frame later. Later never comes.

## Cross session and multi day recovery

Sessions end. Laptops restart. The human takes a week off. The agent has no memory between sessions beyond what is on disk, so the first message of a new session is a reconstruction, not a greeting.

### Rebuild sequence, run at the start of every session

1. Locate the state directory: `./.security/` if it exists, else `~/security-program/<org-slug>/`. If neither exists, this is a cold start, go to `references/00-cold-start.md` instead.
2. Read in this order and stop when you have enough: `CONTEXT-STACK.md`, then `90-DAY-PLAN.md`, then `RISK-REGISTER.md` top five rows, then the most recent five entries of `DECISION-LOG.md`, then `ACCESS-LOG.md` pending rows. Read `SECURITY-STATE.md` only for the cells named in active frames, not the whole file.
3. Compute the age of each frame against today's date. Apply the escalation rules above.
4. Check for drift: if any active frame names a person or a system, and `DECISION-LOG.md` shows a later decision that contradicts the frame, say so before proposing work.

### First message of a resumed session

Keep it to seven lines maximum. State, not narration.

```
Picking up where we left off.

Parked: F-5 (CS-1 identity inventory, 1 day old, blocked on Priya) and F-2 (CO-1
security page, 5 days old, ESCALATE, blocked on a security contact address).
Open decision waiting on you: D1 on F-5, rotate stale keys before or after SSO.
Since last session: nothing new recorded in the decision log.

Recommendation: F-2 has been blocked five days on a two minute task. Create the
security contact address now, then we unblock F-2 and finish it today.

Next action: create security@<domain> as a group with two members. Go or no-go?
```

If there are zero parked frames, say so and propose the next item from `90-DAY-PLAN.md` with a reason. Never open with "what would you like to work on?".

### If the human returns after a long absence

If the newest timestamp in the state files is more than three weeks old, do not resume mechanically. Say: "The state files are 24 days old. Before we resume F-5, I want to re-verify the inventory rather than trust stale output, and I want to check whether the plan still matches reality. Two questions: has anything major changed (new customer commitment, cloud migration, headcount change, incident), and do you want to re-plan or resume?"

## Worked example 1: phishing report during a design review

**Situation.** The agent is mid design review with an engineer on a new webhook receiver, cell SE-1. Halfway through, the human pastes: "Someone in support just forwarded an email, they think they entered their password on a fake login page."

**Agent response.**

```
Class 1, live incident. Parking the design review now, no permission needed.

Parked F-7 (SE-1 webhook design review): reviewed the signature verification and the
replay window, next action is to check whether the endpoint is rate limited.

Incident F-8 opened. Following references/dr-1-incident-response-plan.md from step 1.

First three actions, in this order:
1. Confirm the account. Which support person, and what is their email address?
2. Contain. In your identity provider admin console, revoke that user's active sessions
   and force a password reset. In Google Workspace this is Admin console > Users > the
   user > Security > Sign out of all sessions, then Reset password. In Microsoft Entra ID
   it is Users > the user > Revoke sessions, then Reset password. In Okta it is Directory
   > People > the user > More Actions > Clear User Sessions, then Reset Password.
   THIS LOCKS THE PERSON OUT OF THEIR ACCOUNT. Tell them first. Confirm before I walk
   you through it.
3. Preserve evidence. Have them forward the original email as an attachment, do not
   delete it.

Question 1 first: who is it?
```

The design review is not lost. The engineer is told: "We hit an incident, I have your review parked with the exact next question, I will be back to you within the day." That sentence protects the relationship, which is the whole asset in SE-1.

**On resume**, the agent restates F-7 in five lines and picks up at the rate limiting question, and F-8 stays open in `## Active stack` until the timeline and the follow up actions are written, because incident cleanup work is the most commonly abandoned work of all.

## Worked example 2: questionnaire during an identity provider rollout

**Situation.** The agent and human are three hours into enforcing multi factor authentication for every human account, cell CS-1. Sales messages: "Can you fill in this 71 question security questionnaire? Big logo, they want it back soon."

**Agent response.**

```
Class 2, revenue blocking. Not dropping everything. Two questions before I decide:

1. What is the real date the deal slips if this is late?
2. Is the questionnaire blocking signature, or is their security team doing diligence
   in parallel with legal?

My default if the answer is "end of next week": we finish the multi factor rollout
today, because we are three hours in and a half enforced policy is worse than either
end state, then I block Thursday morning for the questionnaire.

The strategic point, and I will keep making it: answering these by hand does not scale
and it is not what you were hired for. After this one, the fix is a knowledge base of
reusable answers plus a public trust page, so the next questionnaire costs an hour
instead of a day. See references/co-2-questionnaire-knowledge-base.md.

Current next action stays: enable the enforcement policy for the engineering group.
That is the step that can lock people out, so it needs your explicit yes. Go or no-go?
```

Note the three things happening at once: the interruption is triaged rather than obeyed, the half done mutating work is protected (a partially enforced authentication policy is a genuine outage risk), and the recurring cost is named so it gets fixed at the root.

## Worked example 3: founder pulls the human away for two days

**Situation.** The founder needs the human on an unrelated fire, a customer escalation about product reliability, for two full days. This is not a security task at all.

**Agent response at park time.**

```
Understood, that is the founder's call and it is the right call at this stage.

Parking everything cleanly before you go, because two days becomes two weeks:

F-5 (CS-1 identity inventory): parked, blocked on Priya, next action recorded.
F-9 (SE-3 secrets scan): parked at 70 percent. PARTIAL: the scanner is installed in CI
but currently set to warn only, so it will not block anything and nobody will notice it
is there. That is fine to leave for two days, it is not a broken state.

Two things I want from you before you go, both under two minutes:

1. Send this to Priya so F-5 is unblocked when you get back:
   "Hey, quick one for security: are AWS accounts 4455 and 9912 still in use, or can
   they be closed? Trying to finish an access inventory."
2. Tell me the date you expect to be back so I can age the frames correctly.

When you return, my first message will restate both frames in five lines each and
propose which to resume first. Nothing is lost.
```

**Agent response two days later.** Rebuild sequence, then the seven line first message, then the age check: nothing is over five days, no escalation. The partial CI change gets verified first because it is a partial mutation, then the frames resume in the order the plan justifies, not the order they were parked.

## Quick reference

| Situation | Class | Immediate action |
|---|---|---|
| Credential entered on a fake page, active alert, data exposure | 1 | Park without asking, go to `references/dr-1-incident-response-plan.md` |
| Questionnaire, vendor review, customer security call | 2 | Ask for the real deadline, time box, schedule, feed the knowledge base |
| Design review, dependency approval, permission request | 3 | Answer fast with stated confidence, write the follow up as a frame |
| New customer commitment, migration, promise made to the board | 4 | Record in `DECISION-LOG.md`, re-plan at the next boundary |
| Vendor demo, shiny tool, interesting but unowned idea | 5 | Name it as a distraction with a reason, add to `RISK-REGISTER.md` as `open` with a review date, decline |

| Command the human says | Agent runs |
|---|---|
| park this | PARK, write frame, ask what is next |
| switch to X | Triage, PARK, open cell playbook, propose first action |
| resume | Read file, restate in five lines, ask go or no-go |
| what is parked | One line per frame with age and blocker |
| drop it | Require a reason, move to Closed, register residual risk |

**Related files:** `references/00-cold-start.md` (creating the state directory), `references/03-90-day-plan.md` (where frames come from and return to), `references/dr-1-incident-response-plan.md` (class 1 destination), `references/co-2-questionnaire-knowledge-base.md` (class 2 root fix), `references/se-1-sdlc-and-design-reviews.md` (class 3 root fix).
