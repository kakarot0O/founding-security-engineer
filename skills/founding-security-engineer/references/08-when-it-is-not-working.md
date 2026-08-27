# When it is not working: hostile mandates, decorative roles, and your own exposure

> **Type:** program protocol, not a grid cell. It has no cell identifier and it is never "worked" as a step in `90-DAY-PLAN.md`.
> **Load when:** the human is being asked to sign, send, publish, or verbally confirm a security claim they cannot evidence; or a day 30 or day 60 checkpoint in `references/03-90-day-plan.md` is being run; or the human says any of "nobody is listening", "I have no access and nobody cares", "they want me to say we are SOC 2", "sales already told the customer we do this", "I think I was hired for show", "am I going to get blamed for this", "should I quit"; or an executive has asked for an exemption from a control the human just shipped; or the human discovers an incident they were deliberately not told about.
> **Do not load this file** for a normal slow quarter, a single refused budget ask, or one frustrating week. That is `references/02-intake-questions.md` for access and `references/05-metrics-and-comms.md` for visibility. Loading this file too early makes an ordinary startup look like a conspiracy.

## Read this first, out loud if it helps

Most first security hires never need Part C. Many need Part B once. Almost everyone needs Part A, because almost every founding security program has a bad month somewhere between day 20 and day 50, and almost all of those are fixable with a conversation rather than an exit.

The rest of this skill assumes good faith: it tells you to get a founder to co-sign a decision, to announce a channel, to pre-authorise containment, to accept a risk in writing under a name. That assumption is correct in the large majority of startups. It is not universally correct, and when it fails it fails quietly, and a first-time security hire usually cannot tell the difference between "this company is slow" and "this company is not going to let me do this job". That is what Part A is for.

Part B is the operational heart of the file, and it is the part nobody tells a beginner. The cells on public documentation (`references/co-1-public-security-docs.md`) and questionnaires (`references/co-2-questionnaire-knowledge-base.md`) correctly say that an inaccurate security claim is a misrepresentation risk to the **company**. That is true and incomplete. When you personally write, sign, send, or say the false thing, you have attached your name to it. The company's exposure becomes partly your exposure. The person most likely to be produced as the author of a false security attestation is the security person, because they are the one who is supposed to know. Nobody explains this on the first day. It is being explained here.

Part C exists so that leaving is a decision made deliberately, with the record intact, rather than a resignation typed at 11pm.

**Rules for how this file gets used, which the agent must hold:**

1. **Never diagnose from a feeling.** Every signal in Part A has a check you can run against a file or a date. If you cannot point at the check, you do not have the signal, you have a bad week.
2. **Never recommend resigning.** Not once, not gently, not by implication. You lay out the signals, the fix attempt, the result of the fix attempt, and the options. The human decides, and if they want to stay and keep working a hard mandate for another year, that is a legitimate choice and you help them do it well.
3. **Never let the human take the fall silently.** If they are about to sign, send, publish, or say something they cannot evidence, say STOP, name the specific claim, name the missing evidence, and run Part B. This is one of the few places where you interrupt without being asked.
4. **Calm, factual, unemotional, every time.** In this file, tone is the control. An accurate objection delivered angrily gets you labelled as difficult and the claim goes out anyway. The same objection delivered flatly, in writing, with an offered alternative, usually wins.
5. **Do not narrate this file to the human as a category.** They do not need to hear "we are now in Part A of the not-working protocol". They need to hear "three of the four things you flagged as critical have had no decision recorded for six weeks, and that is worth naming to your manager this week".

---

# PART A: Diagnosis at day 30 and day 60

Run this at the day 30 and day 60 checkpoints in `references/03-90-day-plan.md`, and any time the human asks a question that sounds like the trigger list above. Each signal has four parts: the check (a fact you can verify), the fixable test (a probe with a defined expected response), what fixing looks like, and what it means if the fix attempt fails.

A single signal is noise. Startups are chaotic, people are busy, and a founder who ignores you in week three may become your best ally in week eight.

## A0: The mandate you were hired for is not the mandate you are being given

**The check.** `references/03-90-day-plan.md` instructs you, in Gate A, to write down verbatim what the person who hired you said they hired you for, in `DECISION-LOG.md`. Read that entry. Now list every thing you have actually been asked to do in the first 30 days. If every single request maps to one questionnaire, one investor diligence list, one customer's security review, or one logo on a website, the role as practised is decorative, whatever the role as advertised said.

Decorative is not the same as hostile. A decorative mandate usually comes from a founder who was told by an investor or a large customer that they needed a security person and who genuinely does not know what one does. That is an education problem and it is very fixable. It becomes a career problem only if it is still true at day 60 after you have shown them what the alternative looks like.

**The fixable test.** Take one real finding you have already evidenced (there should be at least one from `references/00-cold-start.md`, which requires a real finding on day one) and present it to whoever hired you with a cost, an impact, and a single next action. Then ask one closed question:

> Is fixing this something you want me spending time on, or would you rather I stay focused on getting through the [customer name] review first? Either answer is fine, I just want to be working on what you actually need.

**Fixable if:** they engage with the finding, argue about the priority, ask what it would cost, or say "do the review first, then that". Any of those means there is a real mandate underneath and it just needs shaping. Fixable.

**Not fixable if:** they cannot be got to engage with any finding at all across two attempts three weeks apart, and every conversation returns to the artifact (the questionnaire, the badge, the page). Then the honest description of the job is "produce a document", and the human should decide with open eyes whether they want that job.

**What fixing looks like:** the artifact still gets delivered, because it is real revenue, but it gets delivered alongside two or three findings that were fixed because they were found while producing the artifact. That is how a decorative mandate turns into a real one: not by arguing about the mandate, but by making the artifact production visibly produce security. Record the shift in `DECISION-LOG.md` when it happens.

## A1: Access never arrives

**The check.** Open `ACCESS-LOG.md`. Find every row where the status is `requested` and the requested date is more than fifteen business days old, and where the escalation ladder in `references/02-intake-questions.md` has been run to step three (direct follow-up at three days, consequence stated at seven days, escalation to the outcome owner at ten days). Two completed ladders with no grant, on read-only access, is the signal. Not one. Two.

Weight it by what was asked for. Read-only access that was refused is a much stronger signal than administrative access that was refused, because read-only was the reasonable ask. If the human has only ever asked for administrative access, the problem is the ask, not the company. Fix the ask first and restart the clock: `AWS SecurityAudit` plus `ViewOnlyAccess`, or Google Cloud `roles/iam.securityReviewer` plus `roles/browser` plus the service-specific viewer roles, or Azure `Reader` plus `Security Reader`, or a read-only administrator role in the identity provider, whichever applies.

**The fixable test.** Send the outcome owner one message that converts the access request into their decision rather than your request:

> I have asked for read-only access to [system] three times since [date] and it has not landed. I do not think anyone is blocking it, it is just nobody's priority, which is fair.
>
> Here is where that leaves us. Without it I cannot answer [specific question a customer or investor will ask], and I am recording that as an open unknown rather than guessing. That is a defensible position, it is just a weaker one than knowing.
>
> Can you either get me the read-only role this week, or tell me to stop asking and mark it as accepted-unknown? I am fine with either, I just do not want it sitting in limbo.

**Fixable if:** you get the access, or you get a named person to own the refusal. Both are wins. A refusal with a name on it is a risk row with `accepted-by` filled in, which is the outcome the whole program is built to produce.

**Not fixable if:** the request neither lands nor gets refused after two of these, across two different grantors. Systemic non-response is a different thing from a busy engineer. It usually means somebody senior is quietly uncomfortable with you seeing something, and that is worth naming directly and calmly to your manager once.

**What fixing looks like:** at least one read-only grant per system that matters, logged in `ACCESS-LOG.md` with the granted date, and the systems that were refused recorded as risk rows with a named acceptor rather than as your personal frustration.

## A2: No decision on any critical risk after a stated deadline

**The check.** Open `RISK-REGISTER.md`. Filter to rows with severity `critical` or `high`. Count how many have `Decision` empty and a `Review date` that has already passed. If every one of them is undecided past its date, that is the signal. The absence is uniform, and uniform absence is a policy, not an oversight.

This is deliberately stricter than "some risks are open". Open risks are normal and healthy. A register where **nothing critical has ever received a decision from anyone** means no mechanism exists for the company to decide about risk, which means your findings have nowhere to go, which means the program is a document.

**The fixable test.** Do not ask for a fix. Ask for a decision, and make declining an explicit option, because it is the option most likely to be taken and you want it recorded:

> Three items in the risk register have been marked critical since [date] and none has a decision recorded yet. I am not asking anyone to fix them today. I am asking for a decision on each, and "accept it for now, revisit in six months" is a completely valid answer that I will record as such under your name.
>
> Fifteen minutes on Thursday would clear all three. Does Thursday work?

**Fixable if:** you get the fifteen minutes and you leave it with three decisions, even if all three are "accept". Acceptance under a name is a working risk process. That is a functioning company.

**Not fixable if:** the meeting is deferred twice and the follow-up written request is not answered. At that point write to your manager, once, in plain terms: risks are being identified and there is no path to a decision, so the identification is not producing value, and here is what I propose instead. Then let them choose.

**What fixing looks like:** every critical and high row has either an owner and a due date, or a decision of `accept` with a name in `accepted-by` and a `Review date`. Nothing critical sits blank past its date. That is the single most protective condition in the entire program, both for the company and for the human.

## A3: Executives are exempted from every control that ships

**The check.** For each control that has actually shipped (multi-factor authentication enforcement, device enrolment, single sign-on requirement, offboarding process, code review requirement, production access approval), list who is out of scope. If the exemption list is consistently the same three or four people and those people are the executives, that is the signal.

One exemption for one person for a stated period with an end date is normal and often correct. A founder in the middle of a fundraise who cannot risk a lockout during a board meeting is a real operational constraint, not a character flaw. The signal is *every* control, *permanently*, with *no end date*, for the same people, who also hold the most access in the company.

**Why this one matters more than it looks.** Executives are the highest-value phishing targets in any company, hold the broadest access, and travel most. An exemption pattern concentrated on exactly the highest-risk population inverts the entire control. It also destroys enforcement for everyone else, because the first engineer who notices will ask why they are enrolled and the chief executive is not, and they will be right.

**The fixable test.** Do not ask for the exemption to be removed. Ask for it to be dated and compensated:

> I want to keep the exemption for [name] rather than fight about it, because the lockout risk during [fundraise / launch / travel] is real. What I would like is two things: an end date on it so it does not become permanent by accident, and one compensating control in the meantime, which is [hardware security key as a second factor with a recovery key held by you / a monitored alert on that account's sign-ins / a break-glass account with a stored recovery code].
>
> If the answer is no on all of it, I will record the exemption as an accepted risk with your name on it and stop raising it. That is a normal outcome, I just need it written down once.

**Fixable if:** you get an end date, or a compensating control, or a named acceptance. All three are acceptable outcomes.

**Not fixable if:** the answer is no to the end date, no to the compensating control, and no to being named as the acceptor. That combination is the actual signal, and note that it is not really about the exemption. It is about refusing to own the decision, which is Part B territory.

## A4: You found out about an incident afterwards

**The check.** An event happened that meets the incident definition in `references/dr-1-incident-response-plan.md` (a compromised account, a leaked credential, an unauthorised access, a data exposure, a customer-reported security bug) and you learned about it from a changelog, a chat scrollback, a customer, a colleague's aside, or a vendor notice, rather than from the company. One occurrence counts. This signal does not need a second instance.

**Separate the two causes before you react, because they need opposite responses.**

*Cause one, nobody knew to tell you.* The most common cause by far. There is no reporting path, or there is one and it was announced once in a channel three weeks ago and forgotten. This is a `DR-4` problem, it is your problem to fix, and it is not a mandate problem at all. The fix is `references/dr-4-company-comms-channel.md` plus a short, unembarrassing message.

*Cause two, someone decided not to tell you.* Rarer, and much more serious. The tell is that someone who knew the escalation path used it for everything else and not for this one, or that the conversation happened in a private channel that visibly excluded you, or that you were asked afterwards not to write it down.

**The fixable test.** Respond identically to both at first, because assuming cause two when it was cause one poisons a relationship you need:

> I found out about [event] on [date] from [source]. No criticism, I do not think there was any intent here, I think the path to tell me just is not obvious yet.
>
> Two things I would like: a fifteen minute walkthrough of what happened so I can write it up properly and see whether anything is still exposed, and agreement on the one-line rule for next time, which is that anything that looks like unauthorised access to anything gets dropped in [channel] even if it turns out to be nothing. False alarms are cheap. I would much rather have ten of those than miss one.

**Fixable if:** you get the walkthrough. Then write the incident record retroactively in `incidents/INC-<YYYY>-<NNN>-<slug>.md`, note that detection was by an external route, and move on without recrimination.

**Not fixable if:** the walkthrough is refused, or you are told not to write it down. Being told not to document an incident is a serious finding in its own right and it is one of the few Part A signals that goes straight into `RISK-REGISTER.md` as a program-level risk.

Phrase it in the neutral factual form `references/dr-1-incident-response-plan.md` prescribes, and nothing more:

> On [date] an event meeting the incident definition in the incident response plan was identified via [source]. No incident record was created at the time. Recommended action: create the retrospective record. Owner: [name]. Referred to counsel on [date] if a notification clock may apply.

Three things you must not do here, because `RISK-REGISTER.md` is a discoverable company record that an acquirer, a regulator, or opposing counsel will read. Do not write a consequence clause such as "which prevents breach-notification assessment", because that is a compliance determination and it is not yours to make. Do not pluralise from a single event: one occurrence is "an event on [date]", never "incidents are occurring". And if the event may carry a notification obligation, ask the chief executive whether counsel should see the wording before it lands in a durable file at all.

## A5: You are being asked to attest to something you cannot evidence

**The check.** Anyone has asked you to write, sign, approve, forward, or say aloud a specific security claim, and when you look for the evidence in `SECURITY-STATE.md` the relevant cell status is `unknown`, `none`, or `partial`. It does not matter whether the vehicle is a questionnaire cell, a trust page line, a contract exhibit, an audit attestation, an investor diligence answer, or a sentence on a sales call.

This is the highest-consequence signal in Part A and it is the one signal that has its own procedure. **Stop Part A and run Part B now.** Come back afterwards, because how the request is handled tells you more about the mandate than anything else in this file.

**The reading afterwards.** If the accurate wording is accepted, the mandate is healthy and this was ordinary commercial pressure, which every company has. If the inaccurate wording is insisted upon **and** somebody is willing to own it under their name in `DECISION-LOG.md`, the mandate is workable but the company has a truthfulness problem you are now documenting rather than owning. If the inaccurate wording is insisted upon **and** nobody will put their name to it, that is the clearest structural signal in this entire file, and it is the one case where Part C stops being theoretical.

## A6: The budget is zero after the business case was accepted

**The check.** A specific spend was proposed with a cost, a scope, and a named consequence of not doing it. Somebody senior agreed it was needed. It has now been more than one full budget cycle or six weeks, whichever is longer, and no money has moved and no alternative has been offered.

Money is the slowest and least reliable signal here, so weight it lightly. Startups genuinely run out of cash, boards genuinely freeze spending, and a real yes can be undone by a bad month that has nothing to do with you. A hiring freeze is not a hostile mandate.

**The fixable test.** Convert the money question into a scope question, because a scope answer is free and an honest "no money exists" is very useful information:

> The [tool / assessment / service] we agreed on has not been budgeted yet, which I assume is a cash timing thing rather than a decision. Rather than keep asking, here is the free version of the same control: [the built-in or open-source alternative]. It gets us roughly [percentage] of the coverage and costs [number] days of my time instead of [dollar amount].
>
> Do you want me to do that instead and revisit the paid version next quarter? If money is simply not available this year, tell me plainly and I will plan the whole quarter around that rather than around a maybe.

**Fixable if:** you get either the money, or a straight "no money this year", or approval to spend your own time on the free substitute. All three let you plan. Record whichever one in `DECISION-LOG.md`.

**Not fixable if:** you get neither the money, nor permission to build the free version, nor an honest statement that no money exists, and this repeats across two cycles. Being denied both dollars and hours for the same control, while still being held responsible for the outcome, is the definition of an unfunded mandate.

## Scoring, and what to actually do

**At day 30.** One signal is noise: work it as a normal blocker with the fixable test and move on. Two signals is a pattern worth naming to your manager once, calmly, in a scheduled one-to-one rather than a message. Three or more is a mandate conversation, not a task conversation, and it should be booked as its own meeting with the person who hired you.

**At day 60.** The question is no longer how many signals there are, it is what happened to the fix attempts. For each signal present at day 30, record in `DECISION-LOG.md`: the signal, the fixable test that was run, the date, and the response. A signal that produced a real response is closed even if the answer was no, because a clear no is a working company. A signal where the test produced no response at all, twice, is structural.

**Structural means this and only this:** the constraint is not something the human can fix by being better at the job, so the plan must be rewritten to fit the constraint rather than fight it. Regenerate `90-DAY-PLAN.md` for what is genuinely achievable with the access, decisions, and money that actually exist. Then say plainly, once, what the residual risk of that reduced program is, and record it. This is the correct professional response to a hard environment, and it is not a prelude to quitting.

**Things that are NOT signals, and the agent must say so if the human raises them:** a slow first month; being told no once on budget; an engineer arguing with a finding (that is engineering working correctly); a founder who is short in messages; not having a seat in every meeting at day 30; a questionnaire that took three days; nobody thanking you. None of these belong in this file.

---

# PART B: The refusal procedure

## The bright line

**Never sign, send, publish, approve, or verbally confirm a security claim you cannot evidence.**

Every one of these is the same act, and beginners routinely believe only the first two count:

- a cell in a customer security questionnaire
- a line on a public trust or security page
- a security exhibit or schedule attached to a contract
- an attestation, a management representation letter, or a control narrative given to an auditor
- an answer in an investor or acquirer diligence data room
- a sentence spoken on a sales call, a customer call, or a renewal call
- a message in a shared channel that a salesperson will screenshot and forward
- your approval on someone else's document that contains the claim

The last two are the ones that catch people. A casual "yeah we encrypt everything" typed into a sales channel becomes a screenshot in a customer's file, and it has your name on it.

## What "cannot evidence" precisely means

You can evidence a claim when `SECURITY-STATE.md` shows the relevant cell as `done` with recorded evidence: a command output, a console screenshot the human confirmed, a configuration read back, a signed policy, a dated report. Anything else is not evidence.

Three cases that feel similar and are not:

1. **It is not true.** The control does not exist. The claim is false. Do not make it, in any wording.
2. **It is true but unevidenced.** You believe it is true, someone said it is on, you have not verified. Do not make the claim yet. Verify first: this is usually a one-hour job and it converts a refusal into a yes, which is by far the best outcome available. Most of what looks like Part B is actually a missing hour of verification.
3. **It is partly true.** True for production but not for the internal admin tool, true for new employees but not the four who joined before the process existed, true for the primary database but not the analytics copy. This is the most common real case and it is why step two below matters so much: the accurate partial answer is nearly always acceptable to the buyer, and the false absolute answer is what creates the exposure.

## Step 1: State the disagreement in writing, once, factually

In writing, because a verbal objection that was overruled leaves no record and you will need the record. Once, because repeating it turns a factual position into a personality conflict and you will lose. Factually, because the moment you attribute motive you have handed them a way to dismiss you.

Name the specific claim and the specific missing evidence. Not "I am not comfortable with this document". That is a feeling and it can be talked out of. "Question 14 says X and we cannot show X" is a fact and it cannot.

> Hi [name],
>
> On the [questionnaire / trust page draft / contract exhibit] for [customer], I need to flag question [14] before it goes out.
>
> It currently answers "[exact quoted claim]". I cannot evidence that today. Specifically: [the missing evidence, one sentence, e.g. "encryption at rest is on for the primary database but the analytics replica and the nightly backups in [bucket] are not encrypted, and I confirmed that on [date]"].
>
> I am not saying we should tell them we are bad at security. I am saying we should not tell them something that is not currently true, because if this deal goes wrong later, that sentence is the one their lawyers will read back to us.
>
> I have suggested accurate wording below that I think still gets us through their review. Happy to talk it through today if it is time critical.

Save a copy of what you sent somewhere you personally retain. See Part C on what that means.

## Step 2: Offer the accurate alternative wording

**This step is what makes the whole procedure survivable, and it is the step beginners skip.** A refusal with no alternative reads as obstruction and gets routed around. A refusal that arrives with a ready-to-paste honest sentence reads as help, and most of the time it goes out unchanged and the deal still closes.

Buyers' security reviewers are not looking for perfection. They are looking for a vendor who knows what they do and do not have. "Partial today, closing by Q3, here is the compensating control" scores better with a competent reviewer than an unqualified yes, because an unqualified yes across all sixty questions is itself a well-known warning sign.

The shape that works: **what is true today, plus the scope limit, plus the direction of travel with a date, plus the compensating control.**

| The claim someone wants | Why it is dangerous | Accurate wording that usually still closes |
| --- | --- | --- |
| "We are SOC 2 compliant" | Certification claims are checkable in one email and there is no such thing as self-declared SOC 2 | "We are not currently SOC 2 certified. We are building against the SOC 2 Trust Services Criteria and expect to begin a Type 1 observation window in [quarter]. We can share our control descriptions and evidence directly under mutual non-disclosure agreement in the meantime." |
| "All data is encrypted at rest" | Almost never true of every backup, replica, log store, and analytics copy | "Customer data in our primary datastore and in object storage is encrypted at rest using [provider]-managed keys with AES-256. [Named system] is scheduled for the same by [date]." |
| "We enforce multi-factor authentication for all employees" | Usually untrue for service accounts, contractors, or an exempted executive | "Multi-factor authentication is enforced for all employee accounts in [identity provider]. [N] service accounts are excluded and are instead restricted by [IP allowlist / short-lived credentials / no interactive login]." |
| "We perform annual penetration testing" | An automated vulnerability scan is not a penetration test and reviewers know the difference | "We run automated vulnerability scanning continuously via [tool]. We have not yet commissioned a third-party penetration test; one is planned for [quarter] and we will share the summary letter under non-disclosure agreement." |
| "We have 24/7 security monitoring" | Implies a staffed rota that a 40-person company does not have | "Security-relevant events from [sources] are centrally logged and alert to an on-call rotation covering business hours, with paging for [specific critical alerts] outside those hours." |
| "We conduct background checks on all employees" | Frequently untrue for early employees and varies by jurisdiction | "Background checks are performed for all employees hired after [date], where permitted by local law. Employees hired before that date were not screened." |
| "We have a documented and tested incident response plan" | The word "tested" is the trap | "We have a documented incident response plan covering roles, severity levels, and customer notification timelines. Our first tabletop exercise is scheduled for [date]." |
| "Access is reviewed quarterly" | Claims a recurring process that has run zero times | "We completed our first formal access review on [date] and have scheduled it quarterly from that point. Joiner and leaver access changes are processed within [N] business days." |
| "Customer data is deleted within 30 days of termination" | Backups usually retain it far longer and this is a contractual promise | "Production data is deleted within 30 days of termination. Encrypted backups containing that data expire on a [N]-day rolling cycle, after which no copy remains." |
| "We have never had a security incident" | One incident of any size makes this false forever, in writing. And you cannot evidence the period before you arrived | "We have no record of an incident that met our internal notification threshold. Our incident records and log retention support that statement from [date]. We have not independently verified the period before that. Whether any past event carried a notification obligation is a determination we would make with counsel." |

Three rules for this table. Never write a future date into a customer-facing document without the explicit yes of the person who can actually commit the company to it, because that date becomes a contractual expectation. Never invent the compensating control: if there is not one, the honest sentence is shorter and still fine.

And this one, which is the rule this table itself nearly broke: **any answer about past incidents is bounded by what your records and your log retention actually cover.** Get the bounding date from `references/dr-0-compromise-assessment.md` before you write that row. Never assert that no notification was required, because that is a legal conclusion and it belongs to counsel and the chief executive, not to you. An honest bounded statement closes deals. An unbounded one you cannot evidence is the exact thing Part B exists to stop you signing.

## Step 3: Make whoever wants the inaccurate version own it

If the accurate wording is rejected and the original claim is still going out, the decision has moved from you to them. That is legitimate. They may have context you lack, they may be accepting the risk knowingly, and it is their company. What is not legitimate is the decision existing without an owner.

> Understood, and it is your call rather than mine, so I will not keep pushing.
>
> I do need to record it, the same way I record every decision that carries risk. What goes in the decision log is factual and unemotional: the claim as sent, the evidence gap, that I recommended [accurate wording], that you decided to send the original, and the date. If the wording is ever questioned later, that entry protects you as much as it protects me, because it shows a considered commercial decision was made rather than nobody checking.
>
> Anything you want me to add to it or word differently?

Then write it. Use the standard `DECISION-LOG.md` entry shape from `templates/README.md`, and fill the fields that exist for exactly this purpose:

- **Context:** the deal, the deadline, the commercial pressure. Include it. It makes the entry fair.
- **Options considered:** the accurate wording, the requested wording, and declining to answer the question.
- **Chosen** and **Decided by:** their option, their name, their title. Never yours.
- **My recommendation was:** different, with the accurate wording quoted in full.
- **Reversible:** for a questionnaire already returned, no. For an unpublished page, yes cheaply. Say which.
- **Revisit on:** the date the claim would become true, if there is one.

Then open a `RISK-REGISTER.md` row for the underlying gap, because the gap is still real after the paperwork is done, with `Decision` set to `accept` and `Accepted by` set to their name. Do not write anything about their motives in either file. The facts are sufficient and the neutrality is what makes the record credible later.

Then stop. Do not raise it again, do not mention it in the next update, do not tell a colleague. You have done the job.

## Step 4: If they will not own it, the refusal to own it is the finding

There is a specific and rare failure that matters more than the original claim: someone wants the inaccurate version sent, and does not want their name attached to the decision to send it. Read that plainly. It means the person knows the claim will not survive scrutiny and wants the author of record to be you.

At that point the subject changes. It is no longer about question 14. It is about a company that will make a written representation to a customer, an auditor, or an investor that it will not put a name to. That escalates, once, in writing, above the person asking.

**Where it goes.** Whoever exists, in this order: the board of directors, an audit committee if one exists, the chief executive officer if the request came from below them, outside counsel or the general counsel if the claim is contractual, the investor-appointed board member if the claim is in diligence material. In a 30-person startup this is very often literally one founder and one investor. Send it to the person with the most independence from whoever is asking.

> Hi [name],
>
> I am raising something once, in writing, and then I will leave it with you.
>
> On [date], [document] was sent to [customer / auditor / investor] stating "[exact quoted claim]". That statement is not accurate as of today, for this reason: [one factual sentence]. I flagged it before it went out on [date] and offered alternative wording that was accurate, which is quoted at the end of this message.
>
> The decision to send the original wording was made by [name]. I asked to record that decision in our decision log under their name, which is the standard process here for any decision that carries risk, and they declined to have it recorded.
>
> I am not asking for anyone to be reprimanded and I am not asking to relitigate the wording. I am telling you because a written representation about our security controls went to [party] without an accountable owner, and I do not believe that should happen without the board knowing it happened. If the company's position is that the claim is accurate, I would genuinely like to be shown the evidence, and I will correct my own record and drop this.
>
> Accurate wording I proposed: "[quoted]"
>
> [Your name]

Send it from a company account, in normal working hours, addressed to one or two people, with nobody blind copied. Keep your own copy. Then let it go. You have discharged the obligation and what happens next is not yours to control.

## The verbal case, in real time on a call

Being asked live, on a customer call, is harder than any document because there is no time to check. Have one sentence ready and use it without hesitating, because hesitating is what makes the honest answer sound bad:

> I do not want to answer that from memory. Let me confirm the exact configuration and send it in writing today.

That sentence is professional, costs the company nothing, and is the answer a competent buyer expects from a security person. If a colleague answers on your behalf with something inaccurate, do not correct them in front of the customer: that is a real cost with no benefit. Send the correction in writing to your colleague within the hour, and if it already reached the customer, move to the next section.

## When the false claim has already gone out

You will sometimes discover this after the fact. Do not fix it yourself, and do not contact the customer.

1. Establish the facts: exactly what was said, to whom, on what date, in what document. Quote it.
2. Determine whether it is contractual. A claim in a signed exhibit or a Data Processing Agreement is a different category from a claim in a marketing page, because breaching it may trigger notification or termination rights. `references/co-3-existing-commitments.md` covers how to tell.
3. **STOP.** Correcting a customer-facing statement is a customer communication and it requires an explicit yes from a named person with the authority to make it. It may also require legal review. Never send it yourself, never publish a correction yourself, and never tell a customer directly that a previous statement was wrong.
4. Bring the founders or general counsel the facts, the accurate wording, and two options: correct proactively, or correct at the next natural touchpoint such as renewal or the next questionnaire. Recommend proactive correction where the claim is contractual, and give your reasoning in one sentence.
5. Record the whole sequence in `DECISION-LOG.md` regardless of what they choose, and open the `RISK-REGISTER.md` row for the underlying gap.

---

# PART C: The exit case

## Leaving is a legitimate professional outcome

Some mandates cannot be fixed by the person inside them. A company that will not grant read-only access, will not decide about critical risk, will not name an owner for a false statement, and will not fund either dollars or hours, is not a company where a first security hire can succeed, and staying does not make it one. Leaving that situation is a normal professional judgement, the same kind an engineer makes about a codebase or a salesperson makes about a territory. It is not a failure, it is not disloyalty, and it does not go on a permanent record somewhere.

It is also uncommon. Most people reading this will run Part A, get a real answer from a fixable test, adjust the plan, and have a good second quarter. Do not skip to here.

Two things are true at the same time and both must be held: your obligation is to raise things clearly, in writing, to the right people, and to keep the record. Your obligation is not to personally prevent every bad outcome at a company that has decided otherwise. Security people burn out on the second obligation, which was never theirs.

## What to preserve, and what that means precisely

Keep your own dated, contemporaneous record of what you raised and when. Contemporaneous means written at the time, not reconstructed afterwards, because a reconstruction is worth very little and an as-it-happened note is worth a great deal.

**What belongs in it:** the date, the subject in one line, who you raised it with, the substance in a sentence or two, and the response. That is all. Your own words, describing your own actions. Something like: "2026-03-14. Flagged to [name] that question 14 of the [customer] questionnaire claimed encryption at rest covering all systems, which is not true of the analytics replica. Offered alternative wording. Was told to send the original. Asked to log the decision under their name. Declined."

**Where it lives:** somewhere you are entitled to keep it. A message you sent from your work account to your work account is normally retained by the company, not you, and you will lose access to it on your last day. This is exactly why the record is written in your own words about your own actions rather than copied out of company systems. Whether you may keep a personal copy of anything at all, and in what form, depends on your employment agreement and your jurisdiction, which is the subject of the last section here.

**Why it matters:** if something goes wrong at that company later, the single question that will be asked of you is whether you knew and what you did about it. A dated record showing you raised it, offered the accurate alternative, and escalated once, is a complete answer to that question. Its absence is not.

## What not to take, under any circumstances

This list is not advisory. Taking any of it converts a person who behaved correctly into a person with a legal problem, and it destroys the credibility of everything they raised.

- **No company data and no customer data.** Not a sample, not an anonymised extract, not one record to prove the point, not a screenshot showing real customer information.
- **No evidence exports.** No log archives, no scan output, no configuration dumps, no cloud inventory exports, no incident evidence folder. The contents of `evidence/` stay with the company. If a regulator or a court ever needs it, they get it from the company through lawful process, not from your laptop.
- **No credentials of any kind.** No access keys, no tokens, no password manager exports, no recovery codes, no session cookies. Return or surrender everything, and confirm in writing that you have.
- **No state directory content that is not your own writing.** `SECURITY-STATE.md`, `RISK-REGISTER.md`, `ACCESS-LOG.md`, `DECISION-LOG.md`, the incident records, and the questionnaire knowledge base are company records produced in the course of employment. They stay. Your personal record is a separate document containing your own account of your own actions, and it contains no company data, no customer data, and no findings detail beyond what is needed to identify what you raised.
- **No source code, no infrastructure configuration, no internal documents**, including documents you wrote yourself.
- **No screenshots of internal systems.**

If you are ever unsure whether something falls on the wrong side of this line, the answer is that it does. Leave it.

## How to leave without burning the record

The handover is the last piece of security work you do, and it protects three parties: the company, whoever comes next, and you. A clean handover is also, practically speaking, the strongest possible statement that your concerns were about the work rather than about people.

Write a handover document and leave it in the state directory. It is a company record and it stays with the company. It contains:

1. **State of every cell**, straight out of `SECURITY-STATE.md`, with the status and the evidence reference. No commentary.
2. **The open risk register**, sorted by severity, with each row's decision status and who accepted it where applicable. This is the most valuable page in the document.
3. **Everything still `unknown`**, and specifically what was blocking the answer, including the access requests in `ACCESS-LOG.md` that were never granted, with their dates. Facts, no framing.
4. **Live commitments** from `COMMITMENT-REGISTER.md` if it exists: what the company has promised to which customer, by when, and whether it is met. Whoever arrives next inherits these and will not otherwise find them for months.
5. **Anything time-sensitive**: an audit window, a customer review date, a certificate or domain expiry, a renewal.
6. **The three things you would do first** if you were staying, with the reason for each. Give this away freely. It is the most useful thing in the document.
7. **Who to talk to**: the engineer who knows where the bodies are buried, the person in sales who fields security questions, whoever actually administers the identity provider.

What the handover does **not** contain: your assessment of any individual, the reasons you are leaving, or any characterisation of decisions that are already recorded factually in `DECISION-LOG.md`. The decision log already says what happened, under the correct names, and it says it more credibly than anything written on the way out.

Offer a short live handover session and offer to answer questions for a defined period afterwards, if you are willing to. Say nothing about your reasons for leaving in any group channel, ever. In an exit interview, if asked, state facts and point at the record: "the risk register has eleven open critical items with no decision recorded, and the dates are in the file". Facts are unarguable. Characterisations are arguable, and arguing is how a clean exit becomes a messy one.

Do not remove access from yourself, do not delete anything, do not disable your own accounts, and do not tidy up the state directory before you go. Let the offboarding process do its job (`references/cs-3-onboarding-offboarding.md`), and confirm in writing what has been returned.

## Where this stops being a security question

Two subjects in this file are legal questions, not security questions, and the agent must never pretend otherwise:

**Whistleblower protections and retaliation protections vary enormously** by country, by state or province, by industry, by whether the company is publicly traded, by whether a regulator with a specific protected-disclosure regime is involved, and by what your employment agreement, confidentiality agreement, and any severance agreement say. A protection that clearly applies to a securities-fraud disclosure at a public company in one country may not apply at all to a private company's security misstatement in another. Nobody should reason about this by analogy.

**Your employment agreement may also restrict** what you may keep, what you may say, to whom, and for how long, including after you leave. Some agreements have carve-outs for lawful reports to regulators and some do not, and where a carve-out is legally required it may exist regardless of what the document says. Read the actual document.

**This is the point at which you speak to your own lawyer, not the company's.** The general counsel, outside counsel, and the company's employment lawyer all represent the company. They are not your lawyer, they owe you no duty of confidentiality, and telling them something is not a private conversation, however friendly the person is. A single paid hour with an employment lawyer in your own jurisdiction, before you send anything to a board or a regulator and before you sign any severance agreement, is the highest-value spend available in this entire file.

**The agent's rule here is absolute:** describe the categories, name the fact that they vary, and say plainly that this is a lawyer question. Never state what the law is, never assess whether a specific disclosure would be protected, never help draft a regulatory complaint, and never advise on signing or not signing an agreement.

---

## Recording rules for this file

- Part A signals and their fixable tests, with dates and responses, go in `DECISION-LOG.md` as one entry per checkpoint. They are program-level entries, not cell entries.
- A structural finding (documentation of incidents refused, decisions systemically unowned, access systemically refused) goes in `RISK-REGISTER.md` as a program-level risk, phrased factually, with the same scoring rules as any other row.
- A Part B refusal goes in `DECISION-LOG.md` under the name of the person who made the decision, plus a `RISK-REGISTER.md` row for the underlying gap with `Decision` set to `accept` and `Accepted by` naming them.
- Nothing from this file goes in `SECURITY-STATE.md`. It has no cell.
- Nothing from this file goes in a leadership update or a metrics report without the human's explicit yes. See `references/05-metrics-and-comms.md`.
- Your personal contemporaneous record is not a state file, is not created by the agent, is not stored in the state directory, and is never committed to a company repository.

## Related files

- `references/03-90-day-plan.md`: owns the day 30 and day 60 checkpoints where Part A is run, and owns the regeneration of the plan when a signal turns out to be structural.
- `references/02-intake-questions.md`: owns the three-step access escalation ladder that signal A1 depends on, and the "I do not know" rule.
- `references/co-1-public-security-docs.md`: owns the accuracy of public claims, and is where Part B is triggered by a trust page or security page draft.
- `references/co-2-questionnaire-knowledge-base.md`: owns questionnaire answers, and is the most common origin of a Part B situation.
- `references/co-3-existing-commitments.md`: tells you whether a claim is contractual, which changes the severity of a false one.
- `references/dr-1-incident-response-plan.md`: defines what counts as an incident, which signal A4 depends on.
- `references/dr-4-company-comms-channel.md`: the fix for the benign cause of signal A4, which is the common one.
- `references/cs-3-onboarding-offboarding.md`: the offboarding process you should let run normally on your own way out.
- `references/05-metrics-and-comms.md`: how to report a hard quarter upward without either sugar-coating it or sounding like an accusation.
- `references/04-interrupts.md`: a Part B situation almost always arrives as a class 2 revenue-blocking interrupt, so it gets parked and time-boxed rather than dropped-everything.
- `templates/README.md`: the exact field shapes for `DECISION-LOG.md`, `RISK-REGISTER.md`, and `ACCESS-LOG.md` entries referenced throughout.
