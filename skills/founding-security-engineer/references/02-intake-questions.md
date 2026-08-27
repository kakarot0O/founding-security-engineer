# Intake question banks and access request templates

> **Load when:** you need to ask a human something. Specifically: during the first week of a new engagement, before starting any grid cell where the automated recon in `references/01-recon.md` came back blind, when you need access you do not have, when you need a decision only a founder can make, or when a promised access grant has gone quiet.

This file is the question library and the message library. It is not a script to read aloud start to finish. Pull the smallest relevant set of questions, ask them, write the answers into the state files, and move on.

---

## How to use this file

1. Run environment discovery first (`references/01-recon.md`). Never ask a human a question you could have answered with a read-only command or by reading a file in the repository. Asking a CTO "what language is the backend written in" when the repository is sitting in front of you destroys credibility you cannot buy back.
2. Pick the bank matching who you are about to talk to.
3. Inside the bank, take the questions marked **[15]** first. Those are the must-asks if the meeting collapses to fifteen minutes, which it will.
4. Record every answer in `SECURITY-STATE.md` under the relevant grid cell, in the `Evidence` field. Record every commitment someone makes in `DECISION-LOG.md`. Record every access request in `ACCESS-LOG.md`.
5. Any answer that is "I do not know" becomes a discovery task with a named owner. Never leave a blank. See the rule at the bottom of this file.

**Cadence rule.** Three questions per turn, never four. This matches the cold start protocol in `references/00-cold-start.md` and it is the rate at which a busy person keeps answering instead of starting to skim. If you have twenty questions, ask three, get answers, ask three more. The banks below are libraries to select from, not lists to send whole.

---

## How to ask questions well as a beginner

You are new, you have no track record, and every question you ask spends a small amount of goodwill. These five rules make each question cost less.

1. **Never ask what you could discover.** Before every question, ask yourself: could a read-only command, a public web page, the repository, the wiki, or the last four weeks of a public chat channel answer this? If yes, go find it. Ask only for things that live in a human's head or behind an access wall.
2. **Always state what you already found.** Open with your finding, then ask the narrow question. "I found four Amazon Web Services (AWS) accounts in the organization and three of them have CloudTrail enabled. The fourth, `sandbox-2`, does not. Is that account in use, or can it be closed?" This proves you did the work, and it converts an open question into a yes or no.
3. **Ask for the specific thing, not for help.** "Can you help me understand our infrastructure?" is an unbounded request that a busy person will defer forever. "Can I get the read-only viewer role on the production cloud account, and thirty minutes on Thursday to walk through the architecture diagram?" is two bounded requests they can say yes to in ten seconds.
4. **Give a deadline and a reason for it.** Not "when you get a chance." Say "by Friday, because the System and Organization Controls 2 (SOC 2, the third-party audit report on security controls that enterprise buyers ask for) evidence window opens Monday and I need the access log export before then." A deadline without a reason reads as pushy. A deadline with a reason reads as planning.
5. **Offer the default answer.** Instead of asking someone to design a policy, propose one and ask them to approve or amend. "I plan to set laptop disk encryption to required for all machines. That will not lock anyone out and takes effect on next check-in. Any objection before I turn it on Wednesday?" This is the partner posture. You do the thinking, they do the approving.

**Anti-pattern to avoid:** asking a question that implies blame. "Why is there no incident response plan?" gets you a defensive answer and a reputation. "I did not find an incident response plan in the wiki. Does one exist somewhere I have not looked, or would you like me to write the first draft?" gets you an answer and a task.

---

## Required round one: five questions, asked before you produce anything

**Gate.** These five are asked in the first conversation, before any deliverable, any plan, any spend analysis, and any message drafted for someone else. Not because five is a magic number, but because each one has burned a first security hire who assumed the answer.

1. **Has anything security-relevant happened that you know about? Anything at all, however vague, however long ago, even if it turned out to be nothing.** Ask this first, always, because it is the only question here whose answer expires. Log retention across identity providers, chat, code hosts and clouds is commonly 7 to 90 days. Every week you do not ask is a week of evidence that ages out and never comes back. Expect a hedged answer: "there was some phishing thing in March, I think someone's email maybe got into". That is a specific named event and it routes to the "An incident that happened before you arrived" section of `references/dr-1-incident-response-plan.md` immediately. A vague unease with no event attached routes to `references/dr-0-compromise-assessment.md`.
2. **How do people log in to the code host and to the cloud? Is there single sign on, and is multi-factor authentication required or just available?** Do not accept "I think so". Note that you asked, note the hedge, and record the cell as `unknown` rather than `none`, because `none` means you looked.
3. **Are the laptops company-owned and managed, or did people buy their own?** A stipend model means no mobile device management, no enforced disk encryption, and no way to reach a machine when someone leaves. It changes the whole corporate security branch and it is invisible from the code.
4. **Is there a budget line for security, and who approves spend?** Ask even when you are sure the answer is no, because "no budget" and "nobody has asked" are different situations. Never produce a cost estimate before you have this answer. Quoting a range to someone who has no line to spend it from makes you look like you were not listening.
5. **Who writes the code, and who can deploy to production?** If the answer names an agency, a contractor, or a company rather than a person, stop and load `references/09-outsourced-engineering.md`, because asset ownership is now ahead of nearly everything else in the plan.

If the conversation collapses before you get all five, question 1 is the one you do not leave without.

## The six questions that set the order of everything else

Ask these before any other bank, to whoever will answer them first, in the cadence of three per turn. They are the six dimensions Evan Johnson put on the slide titled "It all depends" when explaining what determines a founding security hire's priorities. His own note on the first one was that the business model is, in his opinion, the biggest single thing that will inform your priorities.

These questions do not produce work. They produce the *ordering* of the work you find later. Nothing else in this file matters as much, because two companies with identical findings should get different plans if these six answers differ.

1. **Are we business to business, business to consumer, or both?** Business to business means security questionnaires, contractual commitments, and audit pressure arrive early and arrive attached to revenue. Business to consumer means account takeover, credential stuffing, support-driven account recovery abuse, and privacy regulation dominate, and there is no procurement process to force your hand, which means nothing external will create urgency for you.
2. **How many people work here, and how many are engineers?** Ten people means you can talk to everyone and change things by asking. Two hundred means you need process, and the corporate identity work is already harder than it would have been six months ago.
3. **Who are our customers, and are any of them regulated, enterprise, or government?** One regulated customer can set the whole compliance timeline. A base of individual consumers sets a completely different one.
4. **What is the product, and what does it actually do with customer data?** A product that stores documents, a product that moves money, and a product that only holds email addresses have almost nothing in common in risk terms.
5. **How fast does engineering ship, and how?** Ten deploys a day with automated tests is a different security program from a monthly release with a manual checklist. Velocity decides whether you can put anything in the path of a deploy at all.
6. **What is the culture around rules and friction?** Ask for a concrete example of a policy the company refused to adopt. A company that rejects friction on principle needs controls that are invisible or built into the paved road, not controls that require people to remember something.

Write all six answers into `SECURITY-STATE.md` under `Business context` before you write a single line of `90-DAY-PLAN.md`. When you later have to choose between two findings of similar severity, these answers are the tiebreaker, and you should be able to say which one out loud.

If the answer to question one is consumer or both, consumer account security is in scope for this company and `references/se-5-consumer-account-security.md` applies. If it is purely business to business, say so in writing and treat that cell as not applicable with the reason recorded, rather than leaving it open forever.

---

## Two shapes you must detect in the first conversation

Both of these change the entire plan, both are common, and neither is volunteered. Ask directly.

### Is engineering actually in-house?

A surprising number of startups do not employ the people who write, deploy, or own their production systems. If that is the case here, most of the advice about embedding with engineers has to be rewritten as contract terms and access boundaries instead.

- **[15]** Who physically writes the production code: our employees, an agency, an offshore development partner, individual contractors, or a mix? *Why: it determines whether your security engineering work is coaching or contracting.*
- **[15]** Who can deploy to production right now, and are any of them not employees? *Why: a non-employee with deploy rights is the single highest-consequence answer in this section.*
- **[15]** Whose account is the root or owner of the cloud organisation, and whose personal email is behind it? *Why: cloud root accounts registered to a founder's personal address, or worse to a departed contractor's address, are the classic company-ending single point of failure.*
- Who owns the domain registrar account, the code host organisation, the application store listings, and the payment processor account? *Why: these are frequently in an agency's or an individual's name from year one and nobody notices until a renewal fails or a relationship ends.*
- Do the contractors use company-issued devices, or their own? Do they use company accounts, or their own? *Why: decides whether endpoint and identity controls can reach them at all.*
- When a contractor's engagement ends, who removes their access, and has that ever been checked?

If any answer points at outsourced engineering, an agency, or a contractor-held root account, stop and load `references/09-outsourced-engineering.md` before planning anything else. Do not attempt to change a contractor's access yourself on the strength of these answers. Access changes require an explicit human yes from whoever owns the relationship, and often a contract review first.

### Am I inheriting a program, or starting one?

Inheriting is not easier than starting. It is harder, because there are commitments you did not make and evidence you cannot verify.

- **[15]** Has anyone held this job before me, in any form, including a consultant, a fractional chief information security officer, or an engineer who did it part-time? *Why: if yes, there are artifacts, promises, and probably a half-finished audit somewhere.*
- **[15]** Is there an audit, certification, or penetration test in progress or already completed? Who is the audit firm, and where is the report? *Why: an in-flight audit is a deadline you now own, and a completed report is a list of findings someone already accepted (`CO-3`).*
- **[15]** Are we paying for a compliance automation platform, and who has the login? *Why: an abandoned platform full of failing controls is common, and it is both a cost and a false sense of coverage.*
- What did the previous person leave behind: documents, policies, a risk register, a shared drive folder? Can I have it, and can I have their old email or ticket history?
- Why did they leave, and is there anything I should know about how that went? *Why: ask it plainly and without gossip. The answer often explains the authority you will or will not have.*
- Are there policies published internally that nobody follows? *Why: a written policy nobody follows is worse than no policy, because it is a documented failure to meet your own standard.*

Every inherited artifact is unverified until you verify it. Record it in `SECURITY-STATE.md` with a status of `unknown` and evidence noting where it came from, not `done`. A control someone else told you exists is not evidence that it exists.

---

## Bank 1: Founder or CEO

You get this person rarely and briefly. Their answers set your priorities more than anyone else's. Do not spend their time on technical detail they cannot answer.

### Business context and what would actually kill the company

- **[15]** Are we business to business, business to consumer, or both? *Why: this is the single biggest input into priority order. Business to business means compliance and questionnaires arrive early. Business to consumer means privacy law and account takeover dominate. This is question one of the six ordering questions above. If you already have the answer, do not ask it again, state it back and move to the next question.*
- **[15]** If you woke up tomorrow to a headline about us, what would the headline say for it to be the worst possible one? *Why: gets the crown jewel and the real fear in one question, without security jargon.*
- **[15]** Which single customer or deal, if lost, would hurt the most? *Why: names the account whose security requirements you must satisfy first.*
- What are we selling in twelve months that we are not selling today? *Why: future product means future data types, future regions, future compliance obligations.*
- Do we handle any of these: payment card data, health records, children's data, biometric data, government data? *Why: each one pulls in a specific regulatory regime and changes the plan.*
- Which countries are our customers and our employees in? *Why: drives data residency, privacy law scope, and whether you need a data transfer story.*
- What is the runway, and is there a fundraise or acquisition in the next twelve months? *Why: due diligence has a security section, and that becomes your deadline whether you like it or not.*

### Past incidents and near misses

- **[15]** Has anything security related ever gone wrong here? Even something small, even something that turned out fine. *Why: the honest answer names your top signal source and often reveals why you were hired.*
- Was I hired because of something specific that happened? *Why: ask it directly. It is usually yes, and the answer tells you what the board is watching.*
- Has anyone ever emailed us claiming to have found a vulnerability? What happened? *Why: reveals whether an unofficial disclosure path exists (`SE-4`).*

### Commitments already made

- **[15]** Have we promised any customer, investor, or partner a security certification, an audit, a penetration test, or a specific control by a specific date? *Why: this is the single most common landmine. Commitments made before a security hire arrives are usually undated, unfunded, and already late (`CO-3`).*
- Have we signed anything that says we will notify customers of a breach within a set number of hours? *Why: this number drives the entire incident response plan (`DR-1`).*
- Do we have cyber insurance? Who holds the policy? *Why: the policy has notification requirements and often mandates specific controls.*

### Appetite and authority

- **[15]** What am I allowed to change on my own, and what must I bring to you first? *Why: this is the authority question. Ask it explicitly in week one or you will find the boundary by crossing it.*
- If a control I want slows engineering down, who decides? *Why: names the tiebreaker before you need one.*
- How much friction are you willing to put on employees? Give me an example of something you would refuse. *Why: calibrates endpoint and identity work before you propose it.*
- Am I allowed to say no to a customer's security demand, or does sales own that? *Why: prevents you being volunteered for commitments (`CO-2`, `CO-3`).*

### Budget

- **[15]** Is there a security budget line? If yes, how much and who approves spend? If no, what is the process for asking? *Why: determines whether your plan is free-tools-only or can include paid tooling.*
- What is the largest single purchase I could make without a board conversation? *Why: sets the ceiling on tool selection.*
- Do we have money for a penetration test this year, or should I plan around not having one? *Why: a penetration test is often the only line item a founder expects; find out early if it is funded.*

Record answers in `SECURITY-STATE.md` under `Business context`, and any dated promise in `RISK-REGISTER.md` with the founder as `accepted-by`.

---

## Bank 2: CTO or head of engineering

Your most important recurring relationship. This person can make your program work or quietly ignore it forever.

### Business context and architecture

- **[15]** Can you draw me the system on a whiteboard, including every place customer data comes to rest? *Why: this single artifact feeds `CO-4`, `SE-2`, and every questionnaire you will ever answer.*
- **[15]** Which cloud providers do we use, and are there any accounts or subscriptions outside the main one? *Why: shadow accounts are where the unmonitored breaches happen. Branch: Amazon Web Services organization, Google Cloud organization, Microsoft Azure tenant, a platform like Vercel, Render, Fly, Heroku, or a colocated server nobody talks about.*
- **[15]** Where does the code live, and is there more than one place? *Why: GitHub, GitLab, Bitbucket, or self-hosted. Multiple hosts means multiple access reviews and multiple audit log sources.*
- What is our deploy path from a merged pull request to production running? *Why: the deploy path is the crown jewel in 2026, and this question maps it (see `references/07-modern-cells.md`).*
- Do we have separate environments, and can staging reach production data? *Why: staging with production data is a top-five finding at most startups.*
- What is the oldest piece of infrastructure nobody wants to touch? *Why: the thing nobody wants to touch is unpatched.*

### Current state of controls

- Do we require code review before merge, and can anyone bypass it? *Why: `SE-1`. Admin bypass on branch protection makes review advisory rather than enforced.*
- Are there long-lived cloud credentials stored in the continuous integration system? *Why: the highest value fix available to you and usually a one-day change to federated identity.*
- Where do application secrets live in production? *Why: `SE-3`. Branch: a managed secret store, environment variables in the platform, a `.env` file baked into an image, or a shared password manager entry.*
- Do engineers have long-lived cloud credentials on their laptops? *Why: Evan Johnson's own example. If yes, a stolen laptop is a production compromise.*
- Do we have any logging that a human actually looks at? *Why: `DR-3`. Distinguishes logs that exist from logs that are consumed.*
- What happens today if a service starts behaving strangely at two in the morning? *Why: surfaces the real on-call path, which is the seed of your incident response plan (`DR-1`).*

### Past incidents and near misses

- **[15]** What is the closest we have come to a serious outage or compromise? *Why: engineers remember near misses that never reached the founder.*
- Have we ever had to rotate credentials in a hurry? What triggered it? *Why: reveals both past exposure and whether rotation is even possible.*
- Has a dependency ever broken us or turned out to be malicious? *Why: baseline for the supply chain work.*

### Appetite and authority

- **[15]** How much engineering time can I ask for per sprint without a negotiation? *Why: your entire plan is a budget of other people's attention. Find the free allowance.*
- Who on the team already cares about security? *Why: names your first ally and your future security champion.*
- If I find something serious, do you want it in a channel, a direct message, or a ticket? *Why: getting the escalation path right the first time matters more than the finding.*
- Am I allowed to open pull requests directly against your repositories? *Why: shipping the fix yourself is worth ten reports (see `references/06-2019-to-2026-delta.md` on owning the paved road).*

---

## Bank 3: The engineer who knows where the bodies are

Every company has one. Usually an early employee, often not the most senior. Find them by looking at who has the most commits in the oldest repositories, or by asking the CTO "who knows the most about how this all fits together?" This conversation is informal, off the record, and the highest yield hour of your first month.

- **[15]** What is the scariest thing about our system that nobody outside the team knows? *Why: the honest answer usually is your first real risk register entry.*
- **[15]** If you wanted to steal all our customer data and you still worked here, how would you do it? *Why: an insider knows the shortest path. Frame it as a game, not an accusation.*
- **[15]** What credential, if leaked, would be worst? Where does it live right now? *Why: identifies the crown jewel secret for `SE-3`.*
- What is the thing we all know is broken but never gets prioritised? *Why: you can often get this fixed by attaching a security justification to an existing complaint.*
- Are there any scripts, cron jobs, or one-off servers that only one person knows about? *Why: unowned compute is unmonitored compute.*
- Are there shared accounts anybody still uses? A shared login, a shared application programming interface (API) key, a shared password entry? *Why: shared accounts break every access review and every audit (`CS-1`).*
- Is there anything running that we forgot to turn off? An old admin panel, a legacy subdomain, a demo environment? *Why: forgotten assets are the classic external entry point.*
- Where do people put secrets when they are in a hurry? *Why: the honest answer is usually a chat message or a code comment, and that tells you where to scan.*
- Which third-party services have access to our production data? *Why: seeds the software-as-a-service and third-party inventory.*
- What would you fix first if you were me? *Why: costs nothing and often produces a better answer than your own analysis.*

---

## Bank 4: Whoever runs information technology, laptops, and accounts

At a startup this may be an office manager, a chief of staff, the head of people, or a part-time contractor. It may also be nobody, in which case the answer to most of these is "nobody does that" and every one becomes a task.

### Current state of controls

- **[15]** What do we use to log into everything? *Why: identifies the identity provider. Branch: Google Workspace, Microsoft Entra ID with Microsoft 365, Okta, JumpCloud, a mix, or individual logins per tool with no central provider (`CS-1`).*
- **[15]** Is multi-factor authentication required for everyone, or just available? *Why: available and required are completely different controls. Ask for a screenshot of the enforcement setting, not a verbal answer.*
- **[15]** Do we know how many laptops we own and who has them? Is there a list? *Why: `CS-2`. Without a device list you cannot claim any endpoint control exists.*
- Are laptops enrolled in any management tool? *Why: branch: Jamf or Kandji or Mosyle for Apple, Microsoft Intune, Google endpoint management, a cross-platform tool, or nothing.*
- Is disk encryption on by default, and can you prove it per device? *Why: the cheapest control that appears in every questionnaire.*
- Is there antivirus or endpoint detection software, and does anyone read its alerts? *Why: unmonitored detection software is a checkbox, not a control.*
- Can employees install any application they want on their work machine? *Why: sets expectations for how much friction the culture tolerates.*
- Can any employee connect a third-party application to our company data with one click? *Why: this is the OAuth (the open standard by which one application is granted ongoing access to another) grant question, and the answer is almost always yes because it is the default in Google Workspace, Microsoft 365, Slack, and code hosts. See `references/07-modern-cells.md`.*

### Onboarding and offboarding

- **[15]** Walk me through exactly what happens when someone joins. Who creates which accounts? *Why: `CS-3`. The onboarding path is the access grant path, and it is where over-permissioning starts.*
- **[15]** Walk me through exactly what happens when someone leaves. Is there a checklist? Who runs it? *Why: an incomplete offboarding is a live credential in the hands of a former employee.*
- How long between a person's last day and their accounts being disabled? Has that ever slipped? *Why: turns a process question into a measurable number.*
- What happens to the laptop when someone leaves? *Why: unreturned devices holding cached session tokens are a real and boring risk.*
- Do contractors get the same process as employees? *Why: contractors are usually the gap.*

### Appetite and budget

- What tools do we already pay for that I might be able to use? *Why: the identity provider or productivity suite you already own often includes the security feature you were about to buy.*
- Who approves a new software purchase, and what is the threshold that triggers a bigger conversation? *Why: routes your tool requests correctly the first time.*

---

## Bank 5: Head of sales or customer success

They are your early warning system for compliance demand, and they are the people most likely to promise something you have to deliver.

- **[15]** How often does a prospect ask a security question, and what happens next? *Why: `CO-2`. Establishes whether questionnaires are a trickle or a flood.*
- **[15]** Have we ever lost a deal for a security reason? Which one, and what did they want? *Why: converts security from cost centre to revenue enabler, in the founder's language.*
- **[15]** What have you told customers about our security that you are not sure is true? *Why: ask it warmly. Sales teams answer questionnaires optimistically when nobody is there to help, and you need to know what is already in writing (`CO-3`).*
- Do you have a folder of past questionnaires and completed security reviews? Can I have it? *Why: the fastest way to build the knowledge base is to harvest what already exists.*
- What is the single most common security question you get? *Why: the answer becomes the first entry in the public security page (`CO-1`).*
- Do any of our contracts have a security addendum, a data processing agreement, or a right to audit clause? *Why: contractual commitments outrank aspirational ones.*
- Which prospects are currently blocked on something security related? *Why: gives you an immediate, visible win to deliver.*
- If I gave you a page you could send instead of filling out a form, would you use it? *Why: pre-sells the self-service approach Evan Johnson recommends, so you do not become the questionnaire desk.*

---

## Bank 6: Finance and operations

The most underused source of truth at a startup. The corporate card statement is a better software inventory than any discovery tool you could buy at this stage.

- **[15]** Can I get a list of every recurring software charge for the last twelve months? *Why: this is your shadow information technology inventory, for free, in one email.*
- **[15]** Who is authorised to sign contracts, and is there a list of what we have signed? *Why: routes you to the commitments in `CO-3` and the contract repository.*
- Which vendors do we pay that touch customer data? *Why: seeds the subprocessor list every enterprise customer will ask for.*
- Do we have cyber insurance, and can I read the policy including the application we submitted? *Why: the application contains security claims someone already made on the company's behalf, and the policy contains notification deadlines.*
- Is there a purchase approval process, and does anyone review a vendor before we buy? *Why: establishes whether a vendor security review step can be inserted (it usually can, cheaply).*
- Who owns the domain registrar and the payment processor accounts? *Why: two accounts whose compromise is company-ending, often registered to a personal email from year one.*
- Has anyone ever tried to trick us into paying a fake invoice or changing bank details? *Why: business email compromise is the most common actual financial loss at startups, and finance sees it first.*

---

## Bank 7: Legal and contracts

May be a general counsel, an operations lead wearing a legal hat, or an outside law firm.

- **[15]** Where is the contract repository, and can I have read access? *Why: `CO-3`. Every commitment you will be held to is in there.*
- **[15]** What do our customer contracts commit us to on security and breach notification? Is there a standard template? *Why: gives you the notification clock for `DR-1`.*
- **[15]** Are we subject to any privacy regulation today, and who decided that? *Why: `CO-4`. Branch: the European General Data Protection Regulation, the California Consumer Privacy Act, the Health Insurance Portability and Accountability Act in the United States, or a sector rule. If nobody has decided, that itself is the finding.*
- Do we have a published privacy policy, and does it match what the product actually does? *Why: a privacy policy that overpromises is a regulatory and contractual exposure.*
- Have we signed any data processing agreements as a processor, and do they name subprocessors? *Why: naming subprocessors creates an obligation to keep the list current.*
- Do any contracts give a customer the right to audit us or require a specific certification by a date? *Why: the highest-severity form of the commitment problem.*
- Who would we be legally required to notify if we had a breach, and how fast? *Why: write the answer down before you need it, not during.*
- Is there anything in our contracts I am not allowed to see? *Why: sets the boundary honestly rather than discovering it awkwardly.*

---

## Targeted questions by grid cell

When a finding has already sent you into a cell and recon returned unknown, pull these. Each is phrased to be asked directly. This is a lookup table, not a running order: nothing here says to work the cells top to bottom, and a cell nothing in this company points at does not get worked at all. Questions for the areas that are not on the 2019 grid, including consumer account security, compromise assessment, supply chain, build pipeline, cloud posture, third-party grants, artificial intelligence, and backups, live in `references/07-modern-cells.md` and in the individual cell files.

### Security Engineering

- **SE-1 SDLC and design reviews:** Is there any point today where a change gets a second pair of eyes for security? Who decides that a project is big enough to need a design document? Where do engineers discuss designs before building? Can I be added to that channel or document folder?
- **SE-2 Understand the tech stack:** What languages and frameworks are in production? Which repository would you send a new engineer to first? Can I get a development environment running, and who would help me if I got stuck? *Note: Evan Johnson's guidance is that if you want to change how software is built you have to build software, but a head of security may have better uses for their time.*
- **SE-3 Secrets and keys:** Where is the list of every credential we hold? If it does not exist, who would know the most? Can any secret be rotated today without downtime? Have we ever had a secret committed to a repository? Do customers give us their credentials, and where do those go?
- **SE-4 Bug bounty and disclosure:** Has a stranger ever reported a vulnerability to us? Where did that email land? Is there a `security@` address, and who reads it? *Default position: do not start a bug bounty program yet.*

### Detection and Response

- **DR-1 Incident response plan:** Who is in charge during an incident? Do we have a phone tree or an out-of-band way to reach everyone if the main chat tool is down? What is the contractual notification deadline?
- **DR-2 Top security signals:** If somebody were inside our systems right now, what would look different? Which log would show it? Do we watch cloud credential usage, identity provider logins, or office network traffic? *Those three are Evan Johnson's named starting signals.*
- **DR-3 Logging consumption model:** Which logs exist, where do they go, how long are they kept, and what does storing them cost? Does any alert reach a human, and does anyone act on it? What is the false positive rate on the alerts we do have?
- **DR-4 Company communications channel:** Where do employees ask questions today? Is there a channel where I could post a weekly note and people would read it? How do employees report something suspicious right now?

### Compliance

- **CO-1 Public security docs:** Do we have a security page on the website? Who owns the website and can publish a page? What do prospects currently get sent when they ask about security?
- **CO-2 Questionnaire knowledge base:** How many questionnaires arrive per month? Who fills them in today? How long does one take? Is there a folder of past answers?
- **CO-3 Existing commitments:** Which certifications have we promised and by when? Who made the promise? Was there a plan behind it? Is anyone already engaged as an auditor?
- **CO-4 Data inventory and framework:** What categories of personal data do we hold, where does each one live, and how long do we keep it? Which framework are we aiming at, and why that one? *Note: this cell is blank on slide 18 of the original deck, but Evan Johnson fills it on slides 20 and 21 as "GDPR and current laws," meaning the General Data Protection Regulation and whatever privacy law applies to you. So the cell was never empty, it was answered later in the same talk. The 2026 version here is a superset of that answer: data inventory first, privacy commitments second, framework choice third, because you cannot make an honest commitment about data you have not enumerated.*

### Corporate Security

- **CS-1 Identity and access:** Is there one place that governs login for everything, or does each tool have its own accounts? Who has administrator rights in each critical tool, and when was that last reviewed? Are there accounts belonging to people who have left? *Evan Johnson: production takes years to fix, corporate can be fixed in a few quarters. This is the highest-leverage cell.*
- **CS-2 Endpoint security:** How many devices, on which operating systems, managed by what? Is encryption on? Are operating system updates enforced or optional? *This is table stakes and it gets harder with every new hire, so do it while the company is small.*
- **CS-3 Onboarding and offboarding:** Is there a written checklist? Who owns it? What is the actual elapsed time from last day to access removal? Are there accounts not covered by the checklist because they were created outside the identity provider?
- **CS-4 Workplace security:** Do we have an office, and who can walk in? Is there a guest network separate from the company network? Are there physical items worth stealing, like unencrypted backups or spare laptops? If we are fully remote, what does the equivalent risk look like?

---

## Message templates

Short, professional, assume the reader is busy and mildly suspicious of the new security person. Fill the bracketed placeholders.

**Message cadence rule** (this is about written messages, and it is separate from the three-questions-per-turn rule above): do not send more than one of these templates to the same person on the same day. Two access requests in one morning read as a pile of work rather than a single ask, and the second one is what gets ignored.

### Requesting read-only cloud access

> Subject: Read-only access to the [cloud provider] account
>
> Hi [name],
>
> I am working through a baseline review of our infrastructure. Could I get read-only access to [account or organisation name]?
>
> Specifically I am asking for the built-in read-only roles: [`SecurityAudit` and `ViewOnlyAccess` on Amazon Web Services / `roles/iam.securityReviewer` and `roles/browser` plus service-specific viewer roles on Google Cloud / `Reader` and `Security Reader` on Azure]. These cannot change or delete anything. I have deliberately **not** asked for the AWS `ReadOnlyAccess` policy or the Google Cloud `roles/viewer` role, because those also grant read access to the contents of storage buckets and database tables, and I do not need customer data to do this review.
>
> (Note to the person running this: that last sentence is not a courtesy, it is accurate. AWS `ReadOnlyAccess` includes `s3:Get*` and `dynamodb:GetItem` and `dynamodb:Scan`. Google Cloud `roles/viewer` includes `storage.objects.get`. Only Azure `Reader` is control plane only. Asking for the narrower roles is both correct and the first evidence your colleagues get that you think about least privilege before you preach it.)
>
> I would like this by [date] so I can have a written baseline for the [reason: board update, customer review, audit prep] on [date].
>
> Happy to jump on a call if it is faster to do it together.
>
> [your name]

### Requesting code host organisation admin or audit log read

> Subject: Access to [GitHub / GitLab] organisation settings
>
> Hi [name],
>
> Two asks, and I am fine with just the first for now.
>
> 1. Read access to the organisation audit log and the member and permission list. This is what I need to answer "who can push to production" accurately, which is the first question every customer security review asks.
> 2. Organisation owner rights, when you are comfortable. I would use these to enable [required two-factor authentication / secret scanning / branch protection rules] rather than to change anyone's repository access.
>
> If you would rather keep owner rights with you, that works. I will send you the exact settings I want changed and you can flip them, or I can screen share while you do it.
>
> Would [date] work?
>
> [your name]

### Requesting identity provider admin

> Subject: Admin access to [Google Workspace / Microsoft 365 / Okta / JumpCloud]
>
> Hi [name],
>
> To do the access review I owe [founder name] by [date], I need to see every user, every administrator, and which accounts have multi-factor authentication enforced.
>
> If you would prefer to start narrow, a read-only role is enough for the review: [a custom role in Google Workspace granting only `Users: Read`, `Groups: Read`, `Security Settings: Read` and `Reports: Read` / the `Global Reader` role in Microsoft Entra ID / the `Read Only Administrator` role in Okta]. I will come back and ask for change rights only when I have a specific change to propose, and I will always tell you before I change an enforcement setting that could affect someone's ability to log in.
>
> [your name]

*Note to the person running this: Google Workspace has no prebuilt read-only user role. The prebuilt `User Management Admin` role is not read-only, it can create, update, suspend, delete and rename users and reset passwords for all non-administrator accounts, so do not ask for it and do not describe it as read-only. The custom role has to be created, which takes about five minutes in Admin console, then Account, then Admin roles, then Create new role. The Microsoft Entra ID `Global Reader` and Okta `Read Only Administrator` roles are genuinely read-only and can be requested as named.*

### Requesting the contract repository

> Subject: Read access to signed customer contracts
>
> Hi [name],
>
> I need to know exactly what we have already committed to on security, particularly breach notification timelines, certification promises, and any right to audit clauses. Getting this wrong is more expensive than any control I could build.
>
> Could I get read access to [the contracts folder / the contract management system], or if that is not appropriate, could you send me the security and data protection sections from our three largest customer agreements?
>
> Either works. I would like it by [date] so I can put the commitment list in front of [founder name] before [event].
>
> [your name]

### Asking for a thirty minute architecture walkthrough

> Subject: 30 minutes on how the system fits together
>
> Hi [name],
>
> I have read through [repositories or documents you actually read] and mapped what I can from the outside. I have it down to a handful of gaps, mostly around [the deploy path / where customer data comes to rest / how services authenticate to each other].
>
> Could I get 30 minutes with you to walk the whiteboard? I will bring my draft diagram so you are correcting something rather than starting from scratch. I will write it up afterwards and share it, so this should be the only time you have to explain it.
>
> Any slot [day range] works for me.
>
> [your name]

### Announcing yourself to the engineering team

> Hi everyone. I am [name], I joined [date] as the first person working on security here.
>
> What I am doing for the next few weeks: learning how we build and run things, and writing down what already exists. I am not here to add process to your week.
>
> Three things that might be useful to you:
>
> 1. If you are designing something and want a second pair of eyes on the security side, message me. No template, no meeting, no ticket. Send me a document or a paragraph and I will reply in the thread.
> 2. If you find something that looks wrong, or you did something you are worried about (committed a key, clicked a link, granted an app access to something), tell me. I care about fixing it, not about who did it. That is a genuine commitment, not a poster.
> 3. I will post a short note here every [week/fortnight] on what I am working on and what changed. If something I am doing is going to affect your workflow, you will hear it there first, before it happens.
>
> I will probably ask a lot of questions early on. Tell me if I am asking something I should have looked up myself.

*Note for the agent: propose this message to the human, let them edit the voice, and never send it on their behalf. It is their introduction, not yours.*

### Asking a founder for a decision

Keep it to one screen. Give the recommendation first, not last.

> Subject: Decision needed by [date]: [one line, e.g. "do we enforce hardware keys for administrators"]
>
> [Name],
>
> **The situation.** [Two sentences of fact, with a number if you have one. "Nine people have administrator rights across our production systems. Seven of them use a phone app for their second factor, which does not protect against a convincing fake login page."]
>
> **What I recommend.** [One sentence. "Buy hardware security keys for those nine people and require them for administrator logins by the end of the month."]
>
> **What it costs.** [Money, time, and friction, honestly. "About [amount] for the keys. Two hours of my time. Each of those nine people spends ten minutes enrolling and then it is invisible. Downside: if someone loses their key they cannot log in until I issue a backup, so I will issue two keys each."]
>
> **What happens if we do not.** [One sentence, no exaggeration. "A convincing phishing page against any one of those nine gives an attacker the same access that person has, which for [name of system] is everything."]
>
> **What I need from you.** A yes or a no by [date]. If it is a no, I will log the decision and we move on, no hard feelings.

Record the outcome in `DECISION-LOG.md` with the date, the decision, the reasoning, and who approved. If the answer is no and the risk remains, record it in `RISK-REGISTER.md` with the founder named in `accepted-by`. A risk that a founder knowingly accepts is a legitimate business outcome, not a failure. An undocumented one is your problem later.

### Escalating when access was promised but not delivered

Escalate in three steps. Never skip to step three.

**Step one, direct and light, at three business days:**

> Hi [name], following up on the [access type] request from [date]. Still blocked on it for [specific task]. Is there something I can do to make it easier, or should I be asking someone else?

**Step two, with a stated consequence, at seven business days:**

> Hi [name], checking in again on [access type], originally requested [date].
>
> This is now blocking [specific deliverable] which [person] expects on [date]. If it is not going to happen this week, that is fine, but I need to tell [person] that the date moves and say why. Would you rather I do that, or can we get this sorted by [day]?

**Step three, escalation to the person who owns the outcome, at ten business days. Copy the original requestee, do not go behind their back:**

> Hi [manager or founder], copying [name].
>
> I asked for [access type] on [date] and followed up on [dates]. It has not come through yet, and I do not think anyone is being obstructive. It is just not anyone's priority.
>
> Without it I cannot [specific thing], which pushes [deliverable] from [original date] to [new date]. I want to be clear about the trade rather than quietly missing the date.
>
> Could you either unblock it or tell me to drop the work? Both are workable. Being in limbo is not.

Record every step in `ACCESS-LOG.md`: what was requested, from whom, on what date, the status, and each follow-up date. A pattern of undelivered access is itself a finding worth reporting, and the log is the evidence.

---

## The "I do not know" rule

Never accept "I do not know" as an end state, and never let it sit as a blank in `SECURITY-STATE.md`. Blanks rot. They read as "not checked" six weeks later, and nobody remembers there was a question behind them.

When a human says they do not know, run these four steps in order, in the same conversation:

1. **Ask who would know.** "Who is the closest thing we have to the person who would know?" If they name someone, that person becomes the owner. If they say nobody, the answer is now a discovery task, not a question.
2. **Convert it into a task with a named owner and a date.** The owner is a person, never a team. Preferred order for who owns it: the person closest to the system, then the person you just asked, then you. If it lands on you, say so out loud so it does not look like you dropped it.
3. **Write it down in two places.**
   - In `SECURITY-STATE.md`, set the cell status to `unknown` and put a line in the `Evidence` field in this shape: `Unknown as of [date]. Asked [person]. Owner [person]. Due [date]. Discovery method: [command, console page, or conversation].`
   - In `RISK-REGISTER.md`, add an entry if not knowing is itself dangerous. Not knowing which laptops exist is a risk. Not knowing which font the marketing site uses is not. The test: if this unknown turned out to be the worst plausible answer, would it change your top three priorities? If yes, register it.
4. **Say the consequence out loud, once, without drama.** "So today we cannot answer how many people can reach the production database. If a customer asks that in a security review, we have to say we do not know. I would like to close that in the next two weeks." Stating the consequence is what converts an unknown into someone else's motivation, and it is the difference between a partner and a note-taker.

**Escalation ladder for a stubborn unknown.** If the same unknown survives two attempts: treat the unknown as the worst plausible answer and plan accordingly, tell the human explicitly that you are doing this and why, and put the assumption in `DECISION-LOG.md` so it can be corrected the moment someone finds the real answer. Planning against the pessimistic assumption is always better than planning against a blank.

**Never do these:** never guess and present the guess as a finding, never let a verbal "yeah I think that is turned on" count as evidence (require a screenshot or a command output, per the always-verify rule), and never silently drop a question because it got awkward. Awkward questions are usually the ones with a real answer behind them.
