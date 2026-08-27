# Metrics, reporting up, and getting resources

> **Load when:** the human needs to report progress to a founder, exec, or board; needs to pick metrics; is preparing a weekly, monthly, quarterly, or board update; is asking for budget, headcount, or a tool purchase; is being asked what the security function looks like in twelve months; is being told no; needs to record a risk acceptance; or is showing signs of a political failure mode (being the department of no, being the single point of failure, absorbing engineering's operational work, or being set up to take blame).
> **Load `references/08-when-it-is-not-working.md` instead** when the problem is not visibility or resourcing but good faith: the mandate looks decorative, access never arrives, or the human is being asked to sign, send, publish, or say a security claim they cannot evidence. This file assumes a company that wants the work done and is merely slow. That one handles the case where it does not.

## Why this file exists

The first security hire is usually fired or burned out for one of two reasons, and neither is a technical failure. Either nobody could tell what they were doing, or everybody could tell and hated it. Measurement and communication are the two controls that prevent both. Treat this file as load-bearing as any technical playbook.

The agent's job in this file is to keep the human employed, funded, and trusted, so that the technical work in the other files has time to compound.

## Behavioural rules for the agent in this file

1. Never produce a metric without also producing the exact command, console path, or export that generates it. An unverifiable metric is a lie waiting to be found.
2. Never let the human report a raw count of findings as a headline number. Push back explicitly and offer the coverage or time-based alternative.
3. Never let a risk be accepted verbally. If the human says "the CTO said it's fine", stop and produce a risk acceptance record for signature. Record it in `RISK-REGISTER.md`.
4. Never write a report that a founder cannot read in ninety seconds.
5. When the human asks "should I ask for budget", answer with a recommendation, not a question. State the number, the risk it removes, and the free alternative you would try first.
6. Every report produced from this file gets written to a file in the state directory and the fact of it gets logged in `DECISION-LOG.md` with the date, so there is a paper trail of what was communicated and when.

## Part 1: Metrics that mean something

### The test for a good metric

Ask three questions. A metric must pass all three.

1. **Does it move when I do good work, and only when I do good work?** Vulnerability counts fail this. Buying a scanner makes the number go up. Ignoring the scanner makes it go up too. The number tracks the tool, not the program.
2. **Would a non-security person understand it without a glossary?** "Percentage of laptops with disk encryption on" passes. "Mean time to detect" fails at seed stage because nobody, including the human, knows the denominator yet.
3. **Can I still produce it in six months without heroics?** If the metric requires an hour of manual spreadsheet work each week, it will be abandoned by week five and its absence will look like the program stalled.

### Vanity metrics, and what to use instead

The agent must actively refuse these and offer the replacement.

| Vanity metric | Why it is bad | Use instead |
|---|---|---|
| Number of vulnerabilities found | Rewards noise. A founder reads a rising number as "we are getting less safe" and a falling number as "you stopped working". | Percentage of critical and high findings remediated inside the target window. |
| Number of alerts fired or handled | Measures your tuning quality, inverted. More alerts is worse, not better. | Percentage of alerts that led to an action, and count of real incidents detected by tooling rather than by a human noticing. |
| Number of training modules completed | Compliance theater. Correlates with nothing. | Phishing simulation click and report rate, or better, percentage of accounts on phishing resistant authentication (which removes the risk instead of measuring it). |
| Security score from a vendor dashboard | Vendor defined, not comparable, and gameable. | The weekly diff of a posture baseline: what changed since last week, not the score. |
| Hours spent on security work | Measures effort, not outcome, and invites the question of whether you are efficient. | Deals unblocked and questionnaire turnaround time. |
| Number of policies written | Documents are not controls. | Percentage of production services with a named owner, evidenced from a real registry. |

### The starter metric set

Eight candidates follow. Pick five to seven of them. Not more. A first security hire reporting fifteen metrics is reporting none.

Choose by what this company actually is, not by trying to cover the grid. The selection rule is the same one that governs the whole playbook: a metric earns its place because a fact about this company points at it. A company with no laptops it owns does not report fleet enrollment, it says so once and moves on. A company whose users are individual people does not report questionnaire turnaround, because it does not receive questionnaires. Read `SECURITY-STATE.md` and the open rows in `RISK-REGISTER.md` first, then pick.

**1. Fleet enrollment percentage (Corporate Security, CS-2).**
What it is: the share of company laptops that are enrolled in whatever device management exists, with disk encryption on and screen lock configured. The plain reason it matters: a stolen or infostealer-infected laptop is the most common way a startup gets breached, and you cannot protect a machine you cannot see.
How to instrument it cheaply: the denominator is the hard part, not the numerator. Get the headcount number from the human resources system or the finance team's payroll export. Get the numerator from the device management console if one exists (Apple Business Manager, Microsoft Intune, Google Endpoint Management, Kandji, Jamf, Fleet, or an open source osquery deployment). If there is no device management at all, the honest number is zero percent and you report it as zero percent. Do not report "unknown" for more than one reporting cycle.
Target to state publicly: 95 percent within one quarter of starting the rollout. The last five percent is contractors and edge cases and always takes longer.

**2. Percentage of accounts on phishing resistant multi factor authentication (CS-1).**
What it is: the share of human accounts in your identity provider using a hardware security key or platform passkey, rather than a code from an app or, worse, a text message. The plain reason it matters: codes from apps and texts can be phished in real time by an attacker relaying them. Hardware keys and passkeys cannot, because they are cryptographically bound to the real site.
How to instrument it cheaply, branching by provider:
- Google Workspace: Admin console, Reporting, then Reports, then User Reports, then Security. The report includes a two step verification enrollment column and a security key column. Export as a spreadsheet.
- Microsoft 365 or Entra ID: Entra admin center, Protection, then Authentication methods, then User registration details. Filter on the methods registered column.
- Okta: Reports, then Multifactor Authentication Enrollment. Or query the users API and inspect enrolled factors.
- Other or unknown: ask the human which identity provider the company uses. If the answer is "we mostly just use Google logins", the identity provider is Google Workspace and you use the first branch.
Report it split by population: all staff, and separately administrators and engineers with production access. The second number matters far more and is usually worse.

**3. Mean and maximum time to revoke access after departure (CS-3).**
What it is: hours between a person's last day and the moment their identity provider account is suspended and their sessions are revoked. The plain reason it matters: a departing person with live access is the single easiest incident to prevent and the single most embarrassing one to explain.
How to instrument it cheaply: you need two timestamps. Last day comes from the human resources system or the people operations lead. Suspension time comes from the identity provider audit log. Google Workspace: Admin console, Reporting, then Audit and investigation, then Admin log events, filtered to the suspend user event. Microsoft 365: Entra audit logs filtered to the disable account or update user events. Okta: System Log filtered to `user.lifecycle.suspend`. Record each departure manually in a small table in the state directory if there are fewer than three per month, which at startup scale there usually are. Report the maximum, not just the mean. One person left live for three weeks is the story, and a mean hides it.
Target to state: same business day, and eventually inside one hour via automated deprovisioning from the human resources system.

**4. Percentage of production services with a named human owner (SE-2 and DR-1).**
What it is: for each deployed service, database, and externally reachable endpoint, is there a specific person (not a team alias, not "platform") who is accountable for it. The plain reason it matters: during an incident, the first ten minutes are spent finding who knows how this thing works. Ownership converts those ten minutes to zero, and it is also the prerequisite for every other control, because unowned things never get patched.
How to instrument it cheaply: build the denominator from your infrastructure. If the company uses Amazon Web Services, list running compute and data resources with the resource groups tagging API. If Google Cloud, use the Cloud Asset Inventory. If Microsoft Azure, use the Resource Graph. If you have no cloud access yet, build the denominator from the code repositories instead: every deployable repository is a service. Then require an owner field, either as a cloud resource tag, a `CODEOWNERS` file, or a `service.yaml` in each repository. Percentage is trivially countable after that.
This metric is quietly the highest leverage one in the list, because chasing it forces every other conversation you need to have.

**5. Time to remediate, bucketed by severity (SE-1, and the modern cells in `references/07-modern-cells.md`).**
What it is: for issues you have raised, how long from raised to fixed, reported as the median and the count still open past the target for each severity. The plain reason it matters: it measures the organisation's ability to respond, which is the thing you are actually building, rather than the number of problems, which you do not control.
How to instrument it cheaply: every finding must become a ticket in whatever issue tracker engineering already uses (Jira, Linear, GitHub Issues, GitLab Issues, Shortcut, Asana). Never track findings in a private spreadsheet. Use a label such as `security` and a severity label. The tracker's own reporting then produces this metric for free, and, more importantly, the finding lives where engineers already look.
Propose these targets and get them agreed in writing before you ever report against them, because an unagreed target makes every red number a debate about the target instead of about the fix: critical in 7 days, high in 30 days, medium in 90 days, low as best effort or explicitly accepted.

**6. Questionnaire turnaround time and deals unblocked (CO-1 and CO-2).**
What it is: business days from a security questionnaire landing on you to it going back, plus a running count of deals where security was on the critical path and is no longer. The plain reason it matters: this is the only metric on the list that a sales leader and a chief executive already care about before you explain it. It converts you from a cost centre to a revenue enabler in one line.
How to instrument it cheaply: ask the sales or revenue leader to add two fields to the deal record in the customer relationship management system (Salesforce, HubSpot, Pipedrive, Attio), one for security review requested date and one for security review cleared date. If they will not, keep a five column table in the state directory yourself. Also record the deal value where you are allowed to know it, because "unblocked 1.4 million dollars of pipeline this quarter" is the sentence that funds your budget request.

**Substitution when the company sells to individual people rather than to companies.** If the customers are consumers, this metric does not exist. Nobody sends a security questionnaire to a consumer product, there is no deal to unblock, and reporting a turnaround time against a queue of zero makes the whole metric set look invented. Do not report it, and say once, in the first monthly review, why it is absent. In its place report two numbers, both of which a founder of a consumer company already cares about:

- **Account takeover rate.** Confirmed unauthorised accesses of end-user accounts per ten thousand active accounts per month, plus the raw count. Use a rate as well as a count so that the number does not automatically rise with growth. Define "confirmed" narrowly and write the definition down, because an unstated definition is the thing that gets argued about later. A workable definition: a login or session that the account owner has told us was not them, or that the company reversed on its own initiative. Source it from the authentication logs and the support ticket queue together, since at consumer scale most of them arrive as tickets first.
- **Support-driven account recovery volume.** Account recoveries handled by a human in customer support per week, and the share of those that bypassed the normal self-service password reset flow. The plain reason it matters: the support recovery path is the route that defeats a strong password, a breached-password check, rate limiting, and multi-factor authentication all at once, and it is the one number that tells you whether attackers have found it. A rising share of bypasses is the earliest warning available, usually earlier than the takeover rate itself. Source it from the support tool's ticket categories (Zendesk, Intercom, Front, Help Scout, or a shared inbox with labels), which means the first instrumentation step is asking the support lead for a category or tag that did not previously exist.

Both numbers, their definitions, the thresholds worth alerting on, and the support procedure behind the second one are covered in `references/se-5-consumer-account-security.md`. Get the definitions from there before you report either number, so that the first value you publish is one you can still reproduce in six months. If the company sells to both companies and consumers, report questionnaire turnaround and the two consumer numbers, and accept that this makes eight, which is the one legitimate reason to exceed seven.

**7. Coverage of the critical control set (whole grid).**
What it is: a single percentage derived from `SECURITY-STATE.md`, counting grid cells at status `done` or `partial` against the total in scope. The plain reason it matters: it gives the founder one number for "how far along is the program", which they will ask for whether or not you offer it. If you do not define it, they will invent a worse one.
How to instrument it cheaply: it is already in `SECURITY-STATE.md`. Count the statuses. Report `done` as one point and `partial` as a half point. Cells closed as `n/a` with a written reason come out of the denominator, not out of the numerator, because a cell that does not apply to this company is not an outstanding task. Say out loud that this is a self assessment, every time, because the moment it looks like an audited number it becomes a liability.
One caution the agent must enforce. This number reports progress, it never sets direction. Do not let a founder, or yourself, look at the remaining cells and conclude that the next piece of work is whichever one is unfinished. What gets worked next is decided by what the environment is actually showing you, and the reasons live in `RISK-REGISTER.md`. A percentage that starts choosing the work turns a quarter into completionism.

**8. Measured time to restore, with the date of the drill that produced it (M-6).**
What it is: the wall clock time from the decision to restore to the moment a query against the restored data returns correct results, taken from the last timed restore drill, and always reported together with the date that drill was run. The plain reason it matters: losing the data kills a company faster than leaking it, and an undated recovery claim is worthless. "We can restore in four hours" with no date behind it is a belief. "Four hours ten minutes, measured on 12 March, by the engineer who owns the database" is a fact, and it is the only version of this number that can safely be repeated to a customer, an insurer, or a board.
How to instrument it cheaply: you do not calculate this metric, you read it off the drill record produced by step 7 of `references/m-6-backups-and-recovery.md`. Report it in the form "N hours, measured YYYY-MM-DD". If no drill has ever been run, the honest value is "never drilled", not an estimate derived from the backup configuration, and reporting it that way once is usually what gets the drill scheduled. If the last drill is more than six months old, report the age alongside the number, because a stale measurement of a system that has since changed shape is a belief again.
Two hard rules attached to this metric. A restore drill mutates whatever environment it touches, so it is scheduled with an explicit yes from the person who owns that datastore, it runs into a scratch environment, and it never restores over live data. And the number that leaves the building, on a public page or in a questionnaire answer, is the drill result rounded generously upward, never the raw best case, per `references/co-1-public-security-docs.md` and `references/co-2-questionnaire-knowledge-base.md`.

### Metrics to add later, not now

Do not start these in the first ninety days. Note them in `90-DAY-PLAN.md` under a later section so the human knows they exist.
Mean time to detect and mean time to respond need enough real incidents to have a meaningful average, and at startup scale you will have too few. Percentage of code covered by security review becomes meaningful only once there is an actual software development lifecycle gate. Vendor risk coverage matters once the vendor count exceeds roughly fifty. Patch latency across the fleet is a good metric but requires the device management rollout to be finished first.

### How to present a bad number without triggering panic or blame

This is a skill, not a formatting trick. The agent must apply this structure whenever a metric is red.

Use four beats, in this order, in one short paragraph:

1. **State the number flatly.** No hedging, no "unfortunately". "Twelve percent of laptops are enrolled in device management."
2. **Immediately give the reason, as a system fact rather than a person's fault.** "We have never had a device management tool, so this is what a starting number looks like, not a regression."
3. **Give the target and the date.** "Target is 95 percent by the end of March."
4. **Name what you need, if anything.** "I need fifteen minutes at the next all hands and the finance team's laptop purchase list."

The two things that trigger panic are an unexplained number and an unbounded one. A red number with a date attached reads as a plan. A red number alone reads as an emergency.

The thing that triggers blame is naming a team before naming a system. Never write "the platform team has not patched". Write "eight services are past the thirty day window; six of them belong to a team that lost two engineers last month, so I am rescoping".

Report a baseline as a baseline. The first time you measure anything, label it explicitly: "first measurement, this is the baseline, not a performance result". This is the single most useful sentence in the first quarter and buys the human enormous room.

## Part 2: Reporting cadence

Three rhythms. Weekly written, monthly reviewed, quarterly or board summarised. Each has a different audience and a different job. The agent should keep all three in the state directory and never invent a fourth.

### The weekly written note

Audience: the human's manager, plus whichever channel from DR-4 the company reads (see `references/dr-4-company-comms-channel.md`).
Job: prove motion, surface blockers early, create a searchable record.
Length: under 200 words. If it needs scrolling, it will not be read.
Timing: same day and same hour every week. Consistency is the entire value. A brilliant note sent erratically communicates less than a mediocre one sent every Friday at 4pm.
It contains: what shipped, what is blocked and by whom, what is next, and one number. Not all metrics, one number, rotated.
It does not contain: findings without context, anything that reads as an accusation, anything confidential about a specific person, or details of a live incident beyond what the incident communications plan allows.

### The monthly review

Audience: the human's manager, and usually one other exec (the chief technology officer or the chief executive at seed stage).
Job: check that priorities are still right, adjust the plan, surface anything that needs a decision, and get risks formally accepted or funded.
Length: one page plus the metric table, and a live conversation of thirty minutes.
It contains: the full metric set with the previous month's values next to them, the top three risks from `RISK-REGISTER.md`, the decisions needed from this person, and any change to the ninety day plan.
It is the correct venue for the budget ask and the risk acceptance signature. Do not raise those in the weekly note and do not surprise anyone with them at board level.

### The quarterly or board summary

Audience: the board, or the full executive team.
Job: give confidence that risk is being managed, and get the two or three things you need that only this audience can grant.
Length: one slide. Two if there was a material incident.
It contains: posture in one sentence, three to five metrics with the direction of travel, the top risks with an owner and a decision, incidents in the quarter with what changed as a result, and the ask.
It does not contain: technical detail, tool names, vulnerability counts, or anything that requires the founder to defend a decision they do not understand.

### Rule: no first-time news at board level

Anything appearing on a board slide must have appeared in a monthly review first. A board member learning something new and bad from a slide is a governance failure that the human will be blamed for regardless of who caused the underlying issue. The agent must check this before producing any board content and refuse to include an item that has not been previously socialised, offering instead to raise it with the manager first.

## Part 3: Speaking each audience's language

Same fact, four translations. The agent must translate before presenting, never after being asked.

**For the chief executive and for sales, speak in revenue and deals.**
They care about closed business, sales cycle length, and enterprise customers not walking away. Translate: "adding single sign on support unblocks the four enterprise deals in the pipeline that require it" rather than "we should implement SAML". Translate: "a public trust page cuts questionnaire volume, which is currently adding nine days to enterprise deals". When you must describe a risk, describe it as an event with a customer consequence: "if this happens, we notify every customer in writing within seventy two hours", not "this is a high severity finding".

**For engineering, speak in velocity and toil.**
They care about not being slowed down and not being paged. Translate: "moving continuous integration to short lived federated credentials means nobody has to rotate keys by hand again and no key can leak in a build log" rather than "static credentials are a risk". Translate: "the paved road template means new services get this for free and you never talk to me about it" rather than "you must follow the standard". The strongest sentence available to a first security hire with engineering is "this removes work from you". Use it whenever it is true and never when it is not, because being caught overselling once costs a year of credibility.

**For finance and operations, speak in cost, vendor risk, and insurance.**
They care about spend, contract obligations, and the cyber insurance renewal questionnaire, which asks directly about multi factor authentication, backups, and endpoint protection. Translate: "the endpoint tool costs six thousand dollars a year and is a named requirement on our insurance renewal, so it partly pays for itself in premium" rather than "we need endpoint detection". Also bring finance the shadow information technology finding from the corporate card statement, because that is their language natively and it makes them an ally.

**For legal and for the data protection lead, speak in obligation and liability.**
They care about what has been promised in contracts, what a regulator would ask, and what the notification clock is. Translate: "our master services agreement with the two largest customers commits us to notifying them of a security incident within twenty four hours, and we currently have no mechanism to detect one within twenty four hours" rather than "our logging is inadequate". Legal is often the first security hire's most useful ally because they already think in terms of documented risk acceptance, which is exactly the mechanism in Part 5.

**When the audience is unknown or mixed**, default to the chief executive translation and add one engineering sentence. Never default to the technical framing.

## Part 4: Budget, and the ask

### Build a first budget from nothing

The human will often be told "there is no security budget". That is usually true and usually irrelevant, because at seed and Series A the correct first budget is small and mostly not new spend.

Build it in this order:

1. **Inventory what is already paid for and unused.** Most companies are already paying for security features they have not turned on: the higher tier of the identity provider, the cloud provider's native security services, the source control platform's advanced security features, the endpoint capabilities built into the operating system. Producing a list of already-funded, switched-off controls is the fastest credibility win available and costs nothing.
2. **Exhaust free and built-in controls.** Enforcing hardware keys, restricting third party application installation, turning on cloud audit logging, running an open source posture scanner, enabling secret scanning where it is free, setting branch protection, and blocking install scripts by default all cost zero dollars and remove more risk than most purchases.
3. **Then buy, in this order of payoff.** Hardware security keys for all staff (roughly 25 to 50 dollars per person, one time, and the single best dollar-for-risk purchase available). A password manager for the whole company (roughly 3 to 8 dollars per user per month). Device management and endpoint protection (roughly 5 to 15 dollars per device per month; the operating system vendors' own management tooling is often free or cheap and is a legitimate first step). Log retention (highly variable; see `references/dr-3-logging-consumption-model.md` because this is the line item most likely to run away from you). Compliance automation, only once a framework is actually committed (roughly 7,000 to 25,000 dollars per year, and never buy it before reading `references/co-3-existing-commitments.md`). Penetration testing, once per year, when a customer contract requires it (roughly 10,000 to 40,000 dollars). Bug bounty last, or never yet, per SE-4.
4. **Add a contingency line for incident response.** A small retainer or simply a named, pre-vetted incident response firm with a signed agreement and no minimum. Negotiating this during an incident costs multiples more and days you do not have.

State prices as bands and always as "roughly", because pricing changes and the human will be quoted something different. Always name the free alternative before the paid one.

### How to price a request against the risk it removes

Use this four line form, and never present a price without all four lines.

1. The risk, described as an event and its consequence in the audience's language.
2. Your current best estimate of likelihood, stated honestly as a judgment, not a fake percentage.
3. The cost of the control, per year, all in, including your time to run it.
4. The cheaper thing you already tried or considered, and why it is insufficient.

The fourth line is the one that gets requests approved. A founder who sees you already tried the free option trusts the paid one.

### Handling a no

A no is data, not a rejection, and there are only four kinds. The agent must diagnose which one it is before responding.

- **"Not now, cash is tight."** Correct response: accept immediately and without friction, then ask for the trigger. "Understood. Can we revisit at the next raise, or if we sign a customer over a certain size?" Record the risk as accepted with an expiry date in `RISK-REGISTER.md`. Do not re-ask before the trigger.
- **"I do not think that risk is real."** Correct response: this is a disagreement about facts, so go get facts. Offer to come back with evidence from the environment, not from an industry report. One real example from the company's own logs beats any statistic.
- **"I do not understand what you are asking for."** Correct response: your framing failed. Rewrite the ask in the audience's language from Part 3, shorter, and re-present. Do not repeat the same words louder.
- **"No, and I do not want to discuss it."** Correct response: this is a risk acceptance, whether or not they used the word. Write the acceptance record, send it for confirmation, and move on. Do not escalate around the person on a first no. Escalate only if the risk is severe and the acceptance has been refused in writing, and even then, escalate by asking the person to bring it to their own boss with you present.

The agent must never let the human sulk, re-litigate weekly, or go around someone silently. All three are career-ending at startup scale and all three are tempting.

### What comes after you: the second hire and the four buying options

Somewhere around the day 90 review, and usually without warning, the human will be asked what the security function looks like in twelve months. The wrong answers are "I need a team" and "I am fine". Both are guesses. The right answer is a set of triggers that are already being measured, plus a stated preference for what gets bought first when a trigger fires.

**Triggers, expressed in the units this program already produces.** None of these is a reason to hire on its own. Two of them firing in the same month is.

| Trigger | The number behind it | Where it comes from |
|---|---|---|
| Joiner, leaver, and role change events exceed roughly four per month, sustained | Lifecycle events per month | `references/cs-3-onboarding-offboarding.md` |
| Alerts needing a human judgment exceed roughly ten per week, sustained | Alert volume and the share that led to an action | `references/dr-2-top-security-signals.md` |
| Security questionnaires exceed roughly ten per quarter | Questionnaire count and turnaround | `references/co-2-questionnaire-knowledge-base.md` |
| An audit has actually been committed to, with a date and a scope | The framework decision and its deadline | `references/co-4-data-inventory-and-framework.md` |
| A second cloud provider, a second product line, or an acquisition arrives | Count of environments in `SECURITY-STATE.md` | `references/01-recon.md` |
| For a consumer company, account takeover volume is now a weekly operational load | Takeover rate and support recovery volume | `references/se-5-consumer-account-security.md` |

Before treating a trigger as a hiring case, apply the failure mode 2 defence below and ask whether the load is mechanisable. A questionnaire count of twelve per quarter is a hiring case only if the knowledge base already exists and sales still cannot self serve. Automating first is both cheaper and a stronger argument when you do eventually ask.

**The four options, and what each one is actually for.** Prices are rough bands in United States dollars and will be different by geography and by year. Always state them as approximate.

- **A second security engineer.** Roughly 150,000 to 250,000 dollars a year fully loaded, depending on market and seniority. Correct when the load is continuous, internal, and requires context that cannot be handed to an outsider: access reviews, design reviews, incident work, engineering relationships. This is the most expensive option and the only one that increases the company's own capability permanently.
- **A fractional chief information security officer (CISO).** Roughly 3,000 to 10,000 dollars a month for a few days of attention. Correct when what is missing is seniority, board air cover, or someone to sit opposite an enterprise customer's security team, and not hands. Wrong when the backlog is operational, because a few days a month cannot do operations. Read the mandate carefully: a fractional CISO who ends up owning nothing is a governance decoration, and if the human is already reporting into a decorative arrangement, that is a `references/08-when-it-is-not-working.md` conversation, not a purchase.
- **A managed security service provider (MSSP), or managed detection and response (MDR).** Roughly 15,000 to 60,000 dollars a year at startup scale. Correct when the trigger is alert volume and the real gap is coverage outside working hours. Only buy this after `references/dr-2-top-security-signals.md` and `references/dr-3-logging-consumption-model.md` are done, because an outside provider pointed at untuned signals returns the same noise with an invoice attached, and because the log volume they will ask you to ship is exactly the line item most likely to run away with the budget. Ask specifically what they will do at three in the morning and what they need from you before they can do it.
- **A compliance contractor or compliance automation platform.** Automation platform roughly 7,000 to 25,000 dollars a year, audit fees roughly 10,000 to 30,000 dollars, a contractor or virtual compliance analyst roughly 800 to 2,000 dollars a day. Correct when the trigger is a committed audit with a date and the work is evidence collection and policy drafting rather than engineering. Do not buy any of it before reading `references/co-3-existing-commitments.md`, because what has already been promised determines the scope and the scope determines the price.

**What to buy first differs by what kind of company this is.** If the pressure is enterprise customers, questionnaires, and an audit deadline, the first addition is almost always compliance capacity rather than a second engineer, because that work is boundable, outsourceable, and directly unblocks revenue. If the pressure is consumer account abuse, the first addition is detection and abuse capability, and it is often not a security hire at all: the right answer is frequently a shared engineer with product or support, per `references/se-5-consumer-account-security.md`, since most abuse signals belong to those functions anyway. Say which case this company is in, out loud, in the answer.

**Approval gate.** Every option in this section is a purchase or a hire and none of it happens without an explicit yes from whoever owns the budget and the headcount. Take the ask through the four line pricing form above, put it in the monthly review rather than the weekly note, and record the decision and its date in `DECISION-LOG.md` whichever way it goes.

### The rule

**No risk is ever silently accepted.** If the human decides not to fix something, or someone else decides for them, it becomes a written record with a named accepter and an expiry date. The agent must enforce this without exception and must interrupt the human to do so.

Trigger phrases that require the agent to stop and produce a record: "we decided not to fix that", "the chief technology officer said it is fine", "we will do it later", "that is not a priority", "the business accepted it", "we are shipping anyway".

### Why this protects both sides

For the company: it converts an invisible unmanaged risk into a tracked one with a review date, which is exactly what an auditor, an insurer, and a due diligence process all want to see. Unwritten decisions get re-made badly and forgotten.

For the human: it is the only defence against being blamed after an incident for something someone else decided. A dated record showing the risk was raised, quantified, and accepted by a named person is complete protection. Without it, the post-incident narrative will be "security missed it", and the human has nothing to point at.

Say this to the human plainly, once, the first time it comes up. Beginners often feel that asking for a signature is aggressive or distrustful. Reframe it: it is not distrust, it is how a decision becomes a decision instead of a shrug.

### Who can accept at what severity

Propose this ladder to the human's manager in the first month and get it agreed. Adjust for company size, but keep the principle that severity determines seniority.

| Severity | Who may accept | Maximum acceptance period |
|---|---|---|
| Low | The service owner or engineering manager | 12 months |
| Medium | The engineering leader or the head of the affected function | 6 months |
| High | The chief technology officer or the equivalent exec | 3 months |
| Critical | The chief executive, and noted at the next board meeting | 30 days |

Two hard rules. The security hire never accepts risk on the business's behalf, because they do not own the business outcome and accepting removes their independence. And nothing is ever accepted permanently: every acceptance expires and returns for a fresh decision.

### The accepted-risk record

Every acceptance is a record in `RISK-REGISTER.md` under the `## Accepted risks` heading, which sits between `## Open risks` and `## Closed risks`. That table has ten columns and they are, in this order: `ID`, `Risk as an event`, `Affected system`, `Severity`, `Compensating control`, `Accepted by`, `Role`, `Accepted on`, `Expires on`, and `Trigger conditions that void this early`. All ten are mandatory and none of them is left blank. The record block in Part 6 of this file carries those ten in the same order, plus four fields that stay in the block rather than becoming columns, and the same ten columns are declared in `templates/README.md`, so the register, the template, and this file agree field for field.

The register's status vocabulary is `open`, `in-progress`, `mitigated`, `accepted`, `dropped`, and `closed`. Accepting a risk is what moves its row under `## Open risks` to `accepted`. `dropped` exists for a row that turns out to be a duplicate or a mistake, and the rule for using it, including that the row is never deleted and its identifier is never reused, is in `templates/README.md`.

Trigger conditions matter and are usually forgotten. Write them explicitly: "this acceptance is void if the affected service begins handling customer payment data, if the company signs a customer requiring SOC 2, or if a public exploit is released". These turn a stale record into something that wakes up on its own.

At each monthly review, list every acceptance expiring in the next thirty days. This is the mechanism that keeps the register alive rather than becoming a graveyard.

## Part 6: Templates

Each template is written to the state directory. Replace bracketed placeholders. Keep the headings exactly, because consistency across weeks is what makes these scannable.

### Weekly note

```markdown
# Security weekly, week ending [YYYY-MM-DD]

**Shipped this week**
- [Thing that is now done, phrased as an outcome, not an activity]
- [Thing that is now done]

**In progress**
- [Thing], expected [date]

**Blocked**
- [Thing], waiting on [person or team] for [specific item]. Asked on [date].

**Number of the week**
[Metric name]: [value] ([previous value], [direction]). [One sentence of context.]

**Next week**
- [The single most important thing]
```

### Monthly review

```markdown
# Security monthly review, [Month YYYY]

## One line summary
[Posture in one sentence a founder can repeat.]

## Metrics
| Metric | This month | Last month | Target | Notes |
|---|---|---|---|---|
| Fleet enrolled in device management | | | 95% | |
| Accounts on phishing resistant MFA (all staff) | | | 100% | |
| Accounts on phishing resistant MFA (admins and prod access) | | | 100% | |
| Max time to revoke access after departure | | | Same day | |
| Production services with a named owner | | | 100% | |
| Critical and high findings open past target | | | 0 | |
| Median questionnaire turnaround (business days) | | | 3 | |
| Deals unblocked this month | | | n/a | |
| Time to restore, from last drill | | | [agreed target] | Drilled [YYYY-MM-DD] |
| Coverage of in-scope controls (self assessed) | | | n/a | |

## Top three risks
1. [Risk as an event and consequence] - owner [name] - status [open / in-progress / mitigated / accepted]
2. ...
3. ...

## Decisions I need from you
1. [Specific decision, with your recommendation stated.]

## Risk acceptances expiring in the next 30 days
- [ID]: [risk], accepted by [name] on [date], expires [date]. Recommendation: [renew / fix / escalate].

## Plan changes
[What moved in 90-DAY-PLAN.md and why.]

## Budget
[Nothing this month, or the specific ask with the four line form.]
```

The status words in the top three risks line are the `RISK-REGISTER.md` status vocabulary from Part 5. Use those words and no others. A top three risk is never `dropped` or `closed`, because a row that was dropped as a duplicate or closed because it was fixed is by definition not one of the top three.

If the company's customers are individual people rather than companies, delete the questionnaire turnaround and deals unblocked rows, which will always be empty, and replace them with these two:

| Metric | This month | Last month | Target | Notes |
|---|---|---|---|---|
| Confirmed account takeovers per 10,000 active accounts | | | [agreed target] | Raw count: |
| Support-handled account recoveries per week | | | n/a | Share bypassing self-service reset: |

### Board slide outline

One slide. Written so the founder can present it without the security hire in the room, which is the real test. Every line must be defensible by someone who is not a security person.

```markdown
# Security, [Quarter YYYY]

**Where we are:** [One sentence. Example: "Corporate identity and endpoint controls are largely
in place; production access controls and logging are the current focus."]

**Progress this quarter** (three bullets maximum, each an outcome)
- [Outcome], e.g. "All staff moved to hardware security keys; phishing via stolen passwords
  is no longer a viable path into company systems."
- [Outcome]
- [Outcome]

**Key measures**
| Measure | Now | Last quarter | Target |
|---|---|---|---|
| [3 to 5 rows, chosen from the starter set, never more than 5] | | | |

**Incidents this quarter:** [Number, severity, customer impact yes or no, and the one thing
that changed as a result. If none, say "none reported" and state how you would know.]

**Top risks and decisions**
| Risk (as an event) | Severity | Owner | Decision needed |
|---|---|---|---|
| | | | |

**Ask:** [One ask. Money, headcount, or a decision. With the number and the date.]
```

Rules for the board slide the agent must enforce: no more than five measures, no tool names, no vulnerability counts, no acronym that has not been expanded, nothing that has not already been through a monthly review, and one ask, not three. If the human wants three asks, make them choose, and put the other two in the appendix that nobody reads but that exists so they were technically disclosed.

### Budget request

```markdown
# Budget request: [Control or tool name]

**The risk**
[One or two sentences describing an event and its consequence, in the language of the person
reading this. Not a technical description.]

**Likelihood, honestly**
[Your judgment, with the basis. Example: "I would expect this within twelve months, based on
seeing three near misses in our own logs this quarter." Never a fabricated percentage.]

**What it costs**
- Licence or subscription: [amount] per [unit] per [period], for [count] units = [annual total]
- One time setup: [amount]
- My time to run it: [hours per month]
- Total first year: [amount]

**What I tried first**
[The free or built-in option, and specifically why it is insufficient. If you have not tried a
free option, stop and go try it before sending this.]

**What we get, measurably**
[Which metric moves, from what to what, by when.]

**If the answer is no**
[The compensating control you will run instead, its limits, and the risk acceptance record
that will be created. Written before the answer, so the no is easy to give.]
```

### Risk acceptance record

```markdown
### [RISK-ID]: [Short title]

- **Risk as an event:** [If X happens, then Y, affecting Z.]
- **Affected system:** [Specific system, and what data it holds.]
- **Severity:** [Critical / High / Medium / Low] - [one line on how you rated it]
- **Recommended fix:** [What should be done, and rough effort.]
- **Why it is not being done now:** [Stated reason, in the accepter's words where possible.]
- **Compensating control:** [What partially reduces this, or "none".]
- **Accepted by:** [Full name]
- **Role:** [Their role, because severity decides who is senior enough to accept]
- **Accepted on:** [YYYY-MM-DD]
- **Expires on:** [YYYY-MM-DD] (max period per the severity ladder)
- **Review owner:** [Who brings this back]
- **Trigger conditions that void this early:** [At least one, written explicitly.]
- **Evidence of acceptance:** [Link to the message, email, or meeting note, or "confirmed in
  writing on [date] in [channel]".]
```

Ten of these fields are also the columns of the `## Accepted risks` table in `RISK-REGISTER.md`, in the same order: the identifier from the heading, then Risk as an event, Affected system, Severity, Compensating control, Accepted by, Role, Accepted on, Expires on, and Trigger conditions that void this early. Recommended fix, Why it is not being done now, Review owner, and Evidence of acceptance live only in this block, which is the form the accepter signs. Fill the block first, then copy the ten across, so the signed record and the register can never disagree.

The agent must obtain the evidence line. A record with no evidence link is not a record. If the accepter will not confirm in writing, that is itself the finding, and the agent should tell the human to escalate one level with the exact words: "I need this in writing not because I distrust you, but because if it goes wrong I need to be able to show the board that we decided this deliberately."

## Part 7: Political failure modes and their defences

Four ways the first security hire loses. Each has a specific, mechanical defence. The agent should watch for the symptom in how the human talks and raise the defence unprompted.

All four assume good faith. They are what goes wrong in a company that genuinely wants the security work done and is merely slow, distracted, under-resourced, or bad at prioritising, which describes the large majority of startups. Two failure modes sit outside that assumption and are deliberately not in this file, because treating them as visibility problems makes them worse. Both live in `references/08-when-it-is-not-working.md`:

- **A mandate that is decorative rather than under-resourced.** The difference matters and a first-time hire usually cannot see it. Under-resourced means the company wants the work and cannot afford it yet, and everything in this file applies. Decorative means the role exists to satisfy an investor, a single customer questionnaire, or a slide, and nothing is intended to change. No amount of better reporting fixes the second one, and that file gives dated, checkable signals for telling them apart at day 30 and day 60 rather than diagnosing from a feeling.
- **The human's own exposure when asked to attest to something false.** `references/co-1-public-security-docs.md` and `references/co-2-questionnaire-knowledge-base.md` correctly treat an inaccurate security claim as a misrepresentation risk to the company. What neither says, and what this file does not say either, is that the person who writes, signs, sends, or says the claim has attached their own name to it, and is the person most likely to be produced later as its author. That file carries the refusal procedure and the wording to use.

Do not route to it during one bad week or after a single refused budget ask. That is what this file is for.

### Failure mode 1: becoming the department of no

**Symptom:** the human is being routed around, hears about launches after they ship, or notices meeting invites drying up.
**Root cause:** saying no without offering a path to yes. People stop asking permission they expect to be denied.
**Defence, concretely:**
- Never answer with a bare no. Answer with "yes, if" and name the condition. "Yes, you can use that service, if customer data does not go into it and we turn on single sign on."
- Keep a standing list of pre-approved paths (an approved way to store secrets, an approved way to get cloud credentials in continuous integration, an approved vendor tier). The paved road is what converts a no into a default.
- Set a response time commitment for security reviews and meet it. Being slow is functionally identical to saying no and is the more common cause of being routed around.
- Track your own yes rate. If more than roughly one in five requests ends in a flat no, the problem is the process, not the requesters.

### Failure mode 2: being the single point of failure

**Symptom:** the human cannot take a week off. Every questionnaire, every access request, every review needs them.
**Root cause:** doing work rather than building mechanisms. It feels productive and it is a trap, because it caps the program at one person's throughput permanently.
**Defence, concretely:**
- Anything done more than three times becomes a document, a template, or an automation, in that order of ambition. Store it where others can find it, not in the state directory.
- Self service is the goal for questionnaires specifically. The knowledge base in CO-2 exists so that sales answers their own questionnaires. This is the speaker's original point from the source talk and it remains the highest leverage compliance move.
- Write the runbooks so someone else can execute them, then have someone else execute one while you watch, once. Untested delegation is not delegation.
- Take the week off deliberately in the first six months, and see what breaks. Whatever breaks is the next mechanism to build.

### Failure mode 3: absorbing operational work that belongs to engineering

**Symptom:** the human is doing dependency upgrades, rotating credentials by hand, chasing individual patches, or triaging scanner output alone.
**Root cause:** it is easier to do it than to get it prioritised, and it earns short term gratitude. It also permanently transfers ownership, and now every future failure is yours.
**Defence, concretely:**
- Separate the two jobs explicitly and out loud: security owns the standard, the tooling, and the visibility. Engineering owns the fix. Say this in the first month, before there is a specific dispute to make it look defensive.
- Then write it down and get it signed, because a boundary that exists only as a remembered conversation gets relitigated at the first real conflict, which is precisely when it is worth the most. Produce a one page security charter during Gate A of `references/03-90-day-plan.md`, agreed by whoever the human reports to, covering: what security decides alone, what security recommends while engineering decides, what needs the chief executive, the standing incident containment pre-authorisation in the exact wording from step 10 of `references/dr-4-company-comms-channel.md` (revoking a named human employee's active sessions and refresh tokens, and revoking a third party application's access grant, during a declared incident, those two and nothing else), the risk acceptance severity ladder from Part 5 above, the response time commitment for security reviews, and a date to review the whole thing. Keep it in the state directory as `SECURITY-CHARTER.md` and record the date it was agreed, and by whom, in `DECISION-LOG.md`. The field list is the `SECURITY-CHARTER.md` template block in `templates/README.md`, and the step that produces it is GA-09 in `references/03-90-day-plan.md`. One page, signed, is worth more than ten pages nobody read.
- Route findings into engineering's own tracker with an owner. Never hold a private queue of things you intend to fix yourself.
- The one legitimate exception: do the first one yourself, end to end, to prove it is possible and to learn the friction. Then hand over the second one with the path you just walked documented. Doing the first is credibility; doing the tenth is capture.
- If engineering genuinely lacks capacity, that is a resourcing conversation for the monthly review, not something to quietly absorb. Absorbing it hides the resourcing problem and guarantees it never gets fixed.

### Failure mode 4: being blamed for an incident you flagged

**Symptom:** none in advance, which is what makes it dangerous. It is entirely prevented or entirely not prevented before the incident happens.
**Root cause:** the raise was verbal, or in a chat message that scrolled away, or in a document nobody acknowledged.
**Defence, concretely:**
- Every raised risk that is not fixed becomes a dated record in `RISK-REGISTER.md`, with a named accepter, per Part 5. This is the whole defence and it is not negotiable.
- The monthly review is the forum, so there is a recurring, timestamped, attended venue where risks were presented. A calendar invite with an agenda is evidence.
- Keep `DECISION-LOG.md` current with what was communicated, to whom, and on what date. It costs a minute per entry and is worth a career.
- After an incident, drive a blameless review that focuses on the system, and specifically do not use it to say "I told you so", even though you did and it is tempting. The register already says it, permanently and without emotion. Let the document be the one that points.
- There is a version of this failure mode that the register alone does not cover: being asked, before or after the incident, to state publicly or to a customer that a control existed when it did not. That is no longer a reporting problem and it carries the human's own exposure rather than only the company's. Stop and go to `references/08-when-it-is-not-working.md`, which has the refusal procedure, the accurate alternative wording to offer instead, and the rule that whoever wants the inaccurate version has to own it by name. Never sign, send, or publish a security claim you cannot evidence, whatever the deal is worth.

## Part 8: What the agent does at the end of any reporting session

1. Write the produced artifact (weekly note, monthly review, board slide, budget request) into the state directory, dated in the filename.
2. Append a line to `DECISION-LOG.md` recording what was communicated, to whom, and on what date.
3. Update the metric values in `SECURITY-STATE.md` so the next report has a previous value to compare against.
4. Move any new risk acceptance into the `## Accepted risks` section of `RISK-REGISTER.md`, as a full ten field record with its expiry date, and set the row's status under `## Open risks` to `accepted`.
5. Name the single next action and ask for a go or no-go. Do not ask what the human would like to do next.
