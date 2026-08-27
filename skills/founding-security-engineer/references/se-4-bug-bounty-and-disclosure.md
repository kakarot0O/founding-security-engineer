# SE-4: Bug bounty (hold off if you can) and vulnerability disclosure

> **Grid coordinate:** SE-4, Security Engineering domain.
> **Original 2019 wording:** "Bug bounty (hold off if you can)". The parenthetical is Evan Johnson's, and it is the most important part of the cell. His speaker notes: "I have not ever had a truly great experience with Bug Bounty."
> **Load when:** the human asks about starting a bug bounty, a founder or sales leader asks why the company does not have one, an unsolicited vulnerability report has already arrived from a stranger, a customer or questionnaire asks whether the company has a vulnerability disclosure policy, or the human is about to sign a contract with a bounty platform.

## Why this cell exists

A bug bounty pays strangers on the internet to find flaws in your product. That sounds like free security work, but it is not free: every report that arrives has to be read, reproduced, judged, routed to an engineer, tracked to a fix, and answered. At a startup with one security person, that person is the entire triage queue, and the queue never closes. What a bounty really does is convert risk you did not know about into a stream of inbound work you may not be able to absorb.

There is a second thing hiding inside this cell, and it is the part you actually need. Independent of any payment, you need a way for a stranger who finds a bug to tell you about it, and a public promise that you will not sue or report them for looking. That is a **vulnerability disclosure policy (VDP)**. A VDP is cheap, it is expected by 2026 enterprise buyers, and it is the correct first step. Bounty (money) is the last step. The staircase is: VDP first, private invite-only program second, public paid bounty last, and most 20 to 100 person startups should stop after step one for a year or more.

So when someone asks "should we start a bug bounty?", the honest partner answer is usually: "no, not yet, and here is the thing we should do instead this week."

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A `security.txt` file is served at `https://<domain>/.well-known/security.txt` and returns HTTP 200 with `Content-Type: text/plain`.
- [ ] A public VDP page exists at `https://<domain>/security/disclosure`, linked from the trust page at `/security` (see `co-1-public-security-docs.md`, which owns the public surface and settles these two URLs), with explicit safe harbor language, a scope list, an out-of-scope list, and a response commitment you can actually meet.
- [ ] A dedicated inbound mailbox (`security@<domain>`) exists, is a group or shared mailbox and not one person's inbox, has at least two members, and delivery has been tested from an external address.
- [ ] A written internal triage runbook: who reads the mailbox, how fast a first human reply goes out, how severity is assigned, and how a confirmed finding becomes a tracked engineering ticket.
- [ ] Internal remediation targets exist and have been agreed with engineering leadership in writing, even if they are generous (for example critical 7 days, high 30 days, medium 90 days).
- [ ] The three reply templates in this file are saved somewhere the human can copy from in under a minute.
- [ ] The VDP and the mailbox are referenced from the public security page (see `co-1-public-security-docs.md`) and from the questionnaire knowledge base (see `co-2-questionnaire-knowledge-base.md`).
- [ ] A record in `SECURITY-STATE.md` under `## SE-4` with status and evidence links.

**Explicitly NOT required at this stage:** a paid bounty program, a bounty platform contract, a published payout table, a public hall of fame, a 24-hour response commitment, a CVE Numbering Authority (an organization authorized to assign CVE identifiers), a formal coordinated disclosure calendar, a researcher non-disclosure agreement (NDA) process, or a triage vendor. Every one of those is a real thing you might do later. None of them makes a startup measurably safer in year one.

## Discovery

The goal here is to find out what already exists, what has already been promised, and whether reports are already arriving and being silently dropped. Everything below is read-only.

**1. Does a security.txt already exist?** This works for any stack.

```bash
DOMAIN=example.com
curl -sSI "https://${DOMAIN}/.well-known/security.txt"
curl -sS  "https://${DOMAIN}/.well-known/security.txt"
curl -sSI "https://${DOMAIN}/security.txt"
```

A 404 on both is the common answer and is fine. A 200 that returns HTML instead of plain text means a catch-all route is swallowing the path, which is worth noting.

**2. Is there a public security or disclosure page?**

```bash
for p in security security/disclosure vulnerability-disclosure responsible-disclosure trust security-policy bug-bounty; do
  printf '%s -> ' "$p"; curl -sS -o /dev/null -w '%{http_code}\n' "https://${DOMAIN}/${p}"
done
```

**3. Does the repository already reference a policy?** If the working directory contains code:

```bash
ls -la SECURITY.md .github/SECURITY.md docs/SECURITY.md 2>/dev/null
grep -rIl --exclude-dir=node_modules --exclude-dir=.git \
  -e 'security@' -e 'responsible disclosure' -e 'vulnerability disclosure' -e 'bug bounty' . | head -40
```

If the code host is GitHub, a `SECURITY.md` in the repo root, `.github/`, or `docs/` renders as a "Report a vulnerability" tab. If the host is GitLab, the equivalent convention is also a `SECURITY.md` in the repo root, surfaced on the project overview. Confirm which host is in use before telling the human what will render where.

**4. Does the inbound mailbox exist and does it actually deliver?** Branch by identity provider:

- **Google Workspace:** Admin console at `admin.google.com` then Directory then Groups. Look for `security@`. Check that "Who can post" allows "Anyone on the web", otherwise external researcher mail bounces. Read-only view only; changing posting permissions is a mutation, see Danger zone.
- **Microsoft 365:** Exchange admin center at `admin.exchange.microsoft.com` then Recipients then Groups (or Shared mailboxes). Confirm the group exists and that "Allow external senders" is on.
- **Neither, or you do not know yet:** ask the human directly (see Ask the human). Do not guess.

The definitive test is external delivery, and it is safe to run. From a personal address outside the company, send a message to `security@<domain>` with subject `disclosure channel test, ignore` and confirm it arrives. Have the human do this, not the agent.

**5. Are reports already arriving?** If the human has mailbox access, search for the words `vulnerability`, `bug bounty`, `disclosure`, `bounty`, `POC` (proof of concept), and `XSS` (cross-site scripting) across `security@`, `support@`, `info@`, and the founders' inboxes over the last 12 months. Unanswered reports sitting in a support queue are extremely common and are the single most likely finding.

**6. Has anyone already promised a bounty publicly?** Check the careers page, sales decks, prior questionnaire answers, and the trust page. Check platform directories by searching the company name on the public program directories of the major platforms (HackerOne, Bugcrowd, Intigriti, YesWeHack). A dormant program someone created two years ago and abandoned is a live liability.

**7. Have the free scanners been run yet?** This is a readiness gate, not a bounty task, but you must know the answer. Confirm from `SECURITY-STATE.md` whether dependency scanning, secret scanning, and a basic external surface scan exist. If they do not, see `se-1-sdlc-and-design-reviews.md` and `se-3-secrets-and-keys.md`. Opening a disclosure channel before running the free tools means paying strangers, in time or money, for findings a free tool would have handed you.

**When the agent has no access at all:** you can still do steps 1, 2, and 6 from the public internet with nothing but `curl` and a browser, because they only touch public surfaces. Do those, write the results into `SECURITY-STATE.md` under `## SE-4`, and then ask the human the closed questions below rather than speculating.

## Ask the human

Ask these one or two at a time, not as a wall. Every one is closed and answerable in a sentence.

1. Has anyone outside the company ever emailed us claiming to have found a security bug? If yes, what happened to that email?
2. Has anyone at the company, in a sales call, a security questionnaire, a contract, or a public page, promised that we have a bug bounty or a disclosure policy? (Cross-check the answer against `co-3-existing-commitments.md`.)
3. Who owns the Domain Name System (DNS) records and the marketing site, and can they publish a static file at a specific path this week?
4. Do we use Google Workspace, Microsoft 365, or something else for email?
5. If an external researcher reports a critical bug in production today, who is the engineer who can ship a fix, and what is the fastest we have ever shipped an emergency fix?
6. Do we have a way to pay an individual outside the company, and does finance require an invoice, a United States tax form (a W-9 for a US person or a W-8BEN for a non-US person), or a purchase order? (This determines whether paying a bounty is even operationally possible.)
7. Is anyone pushing for a bug bounty right now, and what problem do they think it solves?

**Copy-pasteable message to get the mailbox created** (send to whoever runs IT or the workspace):

> Hi, I need a shared mailbox or group at security@ourdomain.com that accepts mail from outside the company. Please add me and one backup person as members. This is the address we will publish for outside researchers to report security bugs, and it needs to accept external senders, which is not the default on most group configurations. It should not forward to a single person's inbox. Once it is created I will send a test message from an external address to confirm delivery. Can you do this this week?

**Copy-pasteable message to get the file published** (send to whoever owns the website):

> Hi, I need one static file served at https://ourdomain.com/.well-known/security.txt, returned as plain text (Content-Type: text/plain), no redirect, no login. It is a short machine-readable file that tells security researchers where to report bugs to us. I will send you the exact contents. It is a standard (Request for Comments 9116, published by the Internet Engineering Task Force) and enterprise customers increasingly check for it during vendor review. I also need a page at https://ourdomain.com/security/disclosure with the policy text, linked from our main security page at https://ourdomain.com/security. What is the process and how long does it take?

**Copy-pasteable message to the founder or sales leader who is asking for a bounty:**

> On the bug bounty question: I want to do the useful half of it now and the expensive half later. This week I will publish a vulnerability disclosure policy and a security.txt so outside researchers have a legitimate way to report bugs to us, with legal safe harbor. That is what customers and questionnaires actually ask about, and it costs us nothing. A paid bounty is a different thing: it creates a continuous inbound queue that I am currently the only person able to triage, and until we can reliably ship a fix for a critical bug in under a week, paying for more findings makes our backlog worse, not our product safer. I would like to revisit paying for findings once we can demonstrate that. Does that work?

## The walk

Baby steps. Do one, verify it, then come back for the next. Step 1 delivers real value on day one.

**Step 1: Find and answer the reports that are already sitting there.**
*Goal:* stop the worst failure mode, which is a real vulnerability report rotting unread in a support queue.
*Do:* search the mailboxes listed in Discovery step 5. For anything real and unanswered, send the "valid report" template below today, even if it is six months late. Late and honest beats silent.
*Verify:* every identified inbound report has a reply timestamp and a row in `RISK-REGISTER.md` if the finding is still open.
*Time:* 1 to 3 hours.
*Who else:* whoever owns `support@` and the founders' inboxes, for read access.

**Step 2: Create the inbound channel.**
*Goal:* one durable address that outsiders can reach and that does not depend on one person being awake.
*Do:* have IT create `security@<domain>` as a group or shared mailbox with at least two members and external senders allowed. Set up a filter or label so it is visibly separate from other mail.
*Verify:* send a test message from a personal external address and confirm it arrives for both members. Screenshot it.
*Time:* 30 minutes of your time, up to a few days of waiting.
*Who else:* IT or the workspace admin.

**Step 3: Run the readiness gate honestly.**
*Goal:* decide, on evidence, whether you are allowed to open a channel at all, and definitely whether you are allowed to pay.
*Do:* answer each gate below with yes or no in `SECURITY-STATE.md`. Do not soften a no.
*Verify:* the gate table is written down with dates and named owners.
*Time:* 1 hour.
*Who else:* engineering leadership, to confirm the fix-speed and ownership answers.

| # | Gate | Needed for a VDP | Needed to pay bounties |
| --- | --- | --- | --- |
| G1 | You can ship an emergency production fix in under 7 days, and have done it at least once | Nice to have | Required |
| G2 | You have an inventory of internet-facing assets: domains, subdomains, apps, application programming interfaces (APIs), mobile apps | Nice to have | Required |
| G3 | You have production logging good enough to tell researcher traffic from attacker traffic (see `dr-3-logging-consumption-model.md`) | Nice to have | Required |
| G4 | Every internet-facing service has a named engineering owner | Nice to have | Required |
| G5 | Free scanners have been run and their obvious findings fixed: dependency scanning, secret scanning, cloud posture baseline, transport layer security (TLS) and header check | Nice to have | Required |
| G6 | You have an incident response plan and a way to declare an incident (see `dr-1-incident-response-plan.md`) | Required | Required |
| G7 | Finance can actually pay an individual, possibly overseas, on short notice | Not applicable | Required |
| G8 | A second person can triage reports when you are on holiday | Nice to have | Required |

Decision rule: any **no** in the "Required to pay" column means no paid bounty. Not "a small one to start". No.

**Step 4: Write and publish the VDP page.**
*Goal:* a public, legally meaningful promise that gives researchers a safe path to you.
*Do:* take the full VDP text below, fill the bracketed fields, get legal or the founder to read the safe harbor paragraph, and publish it.
*Verify:* `curl -sS https://<domain>/security/disclosure | head -40` returns the policy, and the page is linked from the trust page at `/security` and from the site footer.
*Time:* 2 to 4 hours of writing plus review turnaround.
*Who else:* whoever owns the website, and one person with authority to make a legal promise (founder, general counsel, or outside counsel).

**Step 5: Publish security.txt.**
*Goal:* make the policy machine-discoverable, because researchers and automated tools look here first.
*Do:* publish the file below at `/.well-known/security.txt`. Set the `Expires` field no more than a year out and put a calendar reminder to refresh it before then.
*Verify:* `curl -sSI https://<domain>/.well-known/security.txt` returns `200` and a `text/plain` content type. An expired file is worse than no file, because it signals abandonment.
*Time:* 1 hour.
*Who else:* website owner.

**Step 6: Write the internal triage runbook.**
*Goal:* the promise you made publicly is backed by a process, not by your memory.
*Do:* write a one-page runbook: who checks the mailbox and how often, the first-reply target, the severity rubric, where confirmed findings go as tickets, and when a report becomes an incident. Save the three reply templates alongside it.
*Verify:* a colleague who is not you can read it and correctly triage a sample report.
*Time:* 2 hours.
*Who else:* your backup triager.

**Step 7: Add it to the sales and compliance surface.**
*Goal:* get credit for the work, which is how you fund the next thing.
*Do:* add the VDP link and one paragraph to the public security page and to the questionnaire knowledge base, so sales stops asking you the same question.
*Verify:* the answer appears in the knowledge base with the VDP URL.
*Time:* 30 minutes.
*Who else:* sales or whoever fields questionnaires.

**Step 8 (only after two clean quarters, and only if gates pass): a private invite-only program.**
*Goal:* controlled, throttled inbound from a small number of known-good researchers.
*Do:* invite 5 to 15 researchers, scope narrowly to one or two applications, cap monthly spend, and run it for a fixed 90 day trial with a stated stop condition.
*Verify:* at the end of 90 days, compute reports received, valid reports, hours spent triaging, dollars paid, and mean time to fix. Decide continue or stop on those numbers.
*Time:* 1 to 2 days to set up, then a genuine 4 to 8 hours per week ongoing.
*Who else:* finance for the budget, engineering leadership for the fix commitment.

**Step 9 (year two at the earliest): go public.** Only when private-program triage load is comfortably absorbed, valid-report rate is healthy, and you have a second person. Going public multiplies volume by roughly an order of magnitude, and most of the increase is noise.

## Decision points

**Bug bounty now, or not?**
**DEFAULT: not now.** Publish a VDP instead. *Changes if:* you are already receiving a steady stream of unsolicited reports, all gates in the paid column are yes, you have a second triager, and a specific buyer contract requires a bounty in writing.

**VDP now, or wait until we are cleaner?**
**DEFAULT: publish now.** Researchers who find bugs will contact you whether you have a policy or not. Without a policy they contact you on Twitter, or through a founder, or not at all. A VDP does not create reports, it routes them. *Changes if:* you genuinely cannot answer mail within 5 business days, in which case fix that first, it takes a week.

**Self-hosted VDP, or a platform?**
**DEFAULT: self-hosted.** A static page plus `security@` plus a `security.txt` costs zero dollars and handles the report volume a 20 to 100 person startup will actually see, which is usually under 50 reports a year, most of them junk. *Changes if:* volume exceeds roughly 10 real reports a month, or you need the platform's payment rails and tax paperwork handling to pay researchers at all.

**Managed triage, or do it yourself?**
**DEFAULT: do it yourself, at VDP stage.** You learn what your attack surface looks like from reading the reports, and that knowledge is worth more than the hours saved. *Changes if:* you have gone public and are drowning. Managed triage is meaningful money (commonly a five-figure annual add-on) and it does not remove your work, it only filters it.

**Cash payouts or swag and credit?**
**DEFAULT at VDP stage: credit only.** Offer public acknowledgement, and be explicit in the policy that you do not currently pay. Discretionary one-off payments are allowed but should not be advertised, because an advertised payout is a promise. *Changes if:* you enter a private program, at which point publish a band table and honor it.

**Do we promise a response time publicly?**
**DEFAULT: yes, but generous.** "We aim to acknowledge within 5 business days" is a promise you can keep on a bad week. Never publish a number you have not met three times in a row internally. *Changes if:* you have a rota with real coverage, then you can tighten to 2 business days.

**Someone found a bug in a third party's product using our systems, or in a dependency, not in us.**
**DEFAULT: route it to that vendor and tell the reporter you did.** Do not attempt coordinated disclosure on someone else's behalf as a one-person team. Log it in `RISK-REGISTER.md` if it affects you.

## Danger zone

Every item here requires an explicit human yes before you act. State the risk out loud, then stop and wait.

- **STOP: launching any paid program.** Money creates a contractual-feeling obligation and unbounded volume. Requires a named budget owner, a monthly cap, and finance confirming they can pay individuals. Getting this wrong means either an unpayable invoice or a public argument with a researcher, both of which end up on social media.
- **STOP: publishing scope that includes production systems you do not own.** Naming a vendor's domain in scope authorizes strangers to attack a system you have no right to authorize testing against. That can breach your contract with that vendor and can be unlawful for the researcher. Scope only assets you control, and say so.
- **STOP: publishing a response-time commitment.** A public service level agreement (SLA) that you miss is quoted back at you in questionnaires and in public disclosure posts. Test it internally first.
- **STOP: changing mail group permissions to allow external senders.** This is a real configuration change to a production mail system. It can expose an internal-only group to spam or, if the wrong group is selected, leak internal mail routing. Have the workspace admin do it, on a group created for this purpose, not on an existing internal group.
- **STOP: any legal-sounding language.** Safe harbor text is a promise not to sue. Do not publish it without one named human with authority signing off. Conversely, do not send a legal threat to a researcher: threatening a good-faith reporter is the single fastest way to turn a private bug into a public story.
- **STOP: publishing a policy, a safe harbor paragraph, or a response commitment the company does not intend to honor.** This is the specific failure this cell is most likely to produce, because the VDP is cheap to publish and expensive to mean. Watch for these exact signals: a founder or counsel wants the safe harbor paragraph softened to "we reserve all rights" while still calling it safe harbor; someone wants a 24 hour acknowledgement published because a competitor publishes one; sales wants the page live this week and nobody has agreed who reads the mailbox; or a named person tells you privately that they would sue a researcher who found something embarrassing. A safe harbor promise you will not keep is worse than no policy at all: a researcher relies on it, tests in good faith, and is then threatened, and that story travels. A published acknowledgement time you do not meet is quoted back at you in every questionnaire afterwards. If you are being asked to publish language the company does not intend to honor, or to put your name on a claim about response times you cannot evidence, stop and work `08-when-it-is-not-working.md`. It gives you the exact wording to state the disagreement once and factually, an accurate alternative to offer instead (usually a longer acknowledgement window and honest "we do not pay" language, which costs nothing and is true), and the step that makes whoever wants the inaccurate version own it in writing. Publishing is an external action and always needs an explicit human yes; when what is being published is a promise, it needs the yes of a named person with the authority to make that promise, recorded in `DECISION-LOG.md`.
- **STOP: replicating a reported exploit against production.** Reproducing a vulnerability can create real records, send real emails to real customers, delete data, or trigger billing. Reproduce in staging. If only production can reproduce it, get explicit approval, use a test account you own, and write what you did into `DECISION-LOG.md` before you do it.
- **STOP: blocking or rate-limiting the reporter's traffic mid-report.** It looks like retaliation and it destroys the evidence you need.
- **STOP: paying anyone who threatened to publish or sell the finding unless you pay.** That is extortion, not a bounty. Escalate to the founder and to counsel immediately, and treat it as an incident under `dr-1-incident-response-plan.md`.
- **STOP: deleting or quietly closing a report.** Retention matters. If a reported issue later becomes a breach, the fact that a report existed and how it was handled will be examined.

## Do not do this yet

- Do not sign a bounty platform contract in year one. The annual platform fee buys you a queue, not safety.
- Do not publish a payout table before you have a budget line and a finance path to pay an individual.
- Do not build a researcher portal, a submission form, or a triage tool. Email plus your issue tracker is sufficient at this size.
- Do not run a live hacking event, a capture the flag, or a public "hack us" launch campaign.
- Do not pursue CVE Numbering Authority status. You do not need it until you ship software that others self-host.
- Do not offer a bounty as a substitute for a penetration test. Buyers ask for a penetration test report, and a bounty does not produce one. See the "Buying a penetration test" section below for how to purchase one, and `co-1-public-security-docs.md` for how to share the summary.
- Do not write an elaborate severity rubric. Use the Common Vulnerability Scoring System (CVSS) qualitative bands (critical, high, medium, low) plus your own judgement about real-world exploitability, and move on.
- Do not promise coordinated disclosure timelines (for example "we will publish an advisory within 90 days") until you have an advisory process at all.
- Do not spend a week negotiating with a reporter about severity. Pay or credit generously at the margin, and preserve goodwill. Your reputation among researchers is a real asset and it is cheap to buy now.

## Evidence to capture

- `SECURITY-STATE.md`, section `## SE-4`: status (unknown, none, partial, done), the URLs of the published `security.txt` and VDP page, the mailbox address and its member count, the date external delivery was verified, and the completed readiness gate table from Step 3.
- `DECISION-LOG.md`: the dated decision to publish a VDP and to defer a paid bounty, the reasoning, and who approved. Also log any later decision to open a private program, including the spend cap and the stop condition.
- `RISK-REGISTER.md`: one row per confirmed external finding, with severity, owner, agreed fix date, and, if it is accepted rather than fixed, who accepted it by name.
- `ACCESS-LOG.md`: the request for `security@` mailbox access and for website publishing rights, with dates requested and granted.
- `90-DAY-PLAN.md`: SE-4 should appear as "publish VDP and security.txt", not as "launch bug bounty". If a bounty appears in the plan, it belongs in a later quarter with the gates as its precondition.

**What an auditor or enterprise customer will ask for later:** the URL of the published disclosure policy, evidence that the inbound channel is monitored, your defined remediation timelines by severity, and a sample of how a real report was handled end to end. Keep one anonymized worked example: report received, acknowledged, triaged, ticketed, fixed, reporter notified. That single artifact answers a surprising number of questionnaire items.

## Cost and effort

- **VDP plus security.txt plus mailbox:** 1 to 2 days of your time, spread over 1 to 2 weeks of waiting on other people. **Dollar cost: zero.** This is the highest ratio of buyer credibility to effort in the whole Security Engineering domain.
- **Ongoing VDP triage:** roughly 1 to 4 hours per month at 20 to 100 people, dominated by junk. Budget more in the first month after publishing, when automated scanners notice you.
- **Private invite-only program:** 1 to 2 days to set up. Payouts realistically 5,000 to 25,000 US dollars per year at a small scope. Platforms can host a private program, sometimes at low or no platform cost for a VDP-only tier, with paid tiers commonly starting in the low tens of thousands per year; get a current quote rather than trusting a number in a document. **Free alternative first:** run the private program by email with a short list of researchers you already trust, and pay via normal accounts payable.
- **Public paid bounty:** platform fee plus payouts plus triage. Realistically 50,000 US dollars per year and up all-in for a program that is not embarrassing, and at least a meaningful fraction of one full-time person. If you cannot fund both halves, fund neither.
- **Comparison for the same money:** a scoped external penetration test typically runs 10,000 to 40,000 US dollars, produces a dated report your sales team can hand to buyers, and has a fixed, known time cost. For a startup's first year, that is usually the better purchase, and questionnaires ask for it by name. The next section is how to actually buy one.

## Buying a penetration test

This file keeps telling you that a penetration test (an authorized, time-boxed manual security assessment performed by an outside firm, commonly shortened to "pentest") is the better purchase than a bounty. That advice is useless unless you know how to buy one, and nobody teaches a first security hire how to do it. This section does. It is also the artifact that questionnaires, enterprise buyers, and every compliance framework ask for by name, so you will buy one within your first year whether you planned to or not.

**Buying is a spending decision and testing is an authorized attack. Both need an explicit human yes.** You do not sign a statement of work, you do not agree a price, and you do not let anyone start testing without the founder or budget owner approving in writing, and without a signed authorization to test that names the exact assets, the exact window, and the source addresses the testers will use. Record the approval and the authorization in `DECISION-LOG.md` before the first packet is sent. Testing anything you do not fully control, including a vendor's hosted component sitting inside your product, needs that vendor's written permission as well, and most of them will say no.

### Scope by crown jewel, not by hostname

The default vendor question is "how many internet-facing hosts and applications do you have?", because that is how they price. That question produces a thin test spread across everything. Answer a different question first, internally: if an attacker got one thing, what would end the company? That is usually a single application, one multi-tenant data path, the authentication and session flow, or the administrative console. Scope the test to that, in depth, and say explicitly in the statement of work that breadth is not the goal.

Concretely, write scope as: named application, named user roles the testers will be given (including at least two accounts in two different tenants so they can attempt cross-tenant access), named application programming interfaces (APIs), whether the mobile application is included, and whether the cloud configuration review is included or excluded. Cross-tenant data access is the finding that matters most to a business-to-business buyer, and testers cannot find it if you only give them one account.

Explicitly exclude, in writing: denial of service and volumetric testing, social engineering and phishing of staff unless you separately decided you want that, physical intrusion, and anything hosted by a third party. Note whether a web application firewall or bot-protection layer sits in front of the target, and decide with the firm whether to allowlist the testers' source addresses. Testing through a rate limiter wastes days of a fixed-price engagement; testing with the firewall bypassed tells you what the application is really worth. Most first tests should allowlist, and the report should say that it did.

### Choosing a firm

- Ask for two redacted sample reports before you talk about price. This is the single most useful selection signal. A good report names the exact request, the exact impact, and a fix an engineer can act on. A bad report is a rebranded scanner export with severity ratings and no reproduction steps. You can tell them apart in ten minutes even if you have never bought a test.
- Ask who actually performs the test, by name and experience, and whether the work is subcontracted. Ask what proportion of the engagement is manual.
- Ask for a reference from a company your size and stage, not from their largest logo.
- Prefer a firm that has tested your kind of product before: multi-tenant software as a service, mobile, an API-first product, machine learning features. Sector familiarity beats brand.
- Boutique firms of five to twenty testers commonly deliver better technical depth per dollar than large brands at startup scope. Large brands sometimes matter when a specific enterprise buyer recognizes the name, which is a sales reason and not a security reason. Decide which one you are buying and say so out loud.
- Check the engagement contract for the confidentiality terms covering your data, the NDA, data handling and deletion after the engagement, and liability. Have whoever handles contracts read it. You are giving strangers authenticated access to your product.

### Fixed price, time boxed, and what the deliverable must contain

Insist on a fixed price for a stated number of tester-days with a stated start and end date. Open-ended or time-and-materials engagements are how a startup's first test becomes a budget argument. Ten to fifteen tester-days is a realistic first engagement at this size, at roughly 10,000 to 40,000 US dollars all-in in 2026, varying widely by region and firm; get two or three quotes rather than trusting that band.

Write the deliverable requirements into the statement of work before signing, because you cannot negotiate them after the report is written:

1. **An executive summary suitable for distribution to customers.** Two to four pages, no raw findings, no internal hostnames, no exploit detail, no credentials, dated, signed by the firm, stating the scope, the methodology, the dates, and a plain summary of the outcome. This is the artifact your sales team hands to buyers under NDA, and if the firm will not produce it separately you will end up either sending customers the full technical report (which hands a stranger a map of your weaknesses) or sending them nothing.
2. **A separate technical report** with per-finding reproduction steps, evidence, affected endpoints, severity with a stated rating method, and remediation guidance specific enough for an engineer to act on without a follow-up call.
3. **A machine-readable finding list** (comma-separated values or JavaScript Object Notation) so you can import findings into `RISK-REGISTER.md` and your issue tracker without retyping them.
4. **A free retest window.** Thirty to ninety days after delivery, the firm re-tests the findings you fixed and issues a revised report or a retest attestation. Get this in the statement of work, in writing, with the window length named. Without it, you pay again to prove you fixed anything, and your dated report circulates forever showing the original findings.
5. **A named point of contact and a live findings channel during the test**, usually a shared channel, so a critical finding reaches you on the day it is found rather than three weeks later in a document.

### What to give the testers

Give them more than an attacker would have. You are buying depth, not a simulation of a stranger's first week. That means: working credentials for each user role and at least two tenants, a walkthrough call with an engineer at kickoff, the API documentation, a test environment they can hammer without a customer noticing, and an explicit statement of which parts of the product you are most afraid of. Firms consistently report that the highest-value findings come from the engagements where someone told them where the bodies are buried.

**Test against staging, populated with production-like but synthetic data.** Production testing risks real customer records, real emails to real people, real charges, and real deletions, and it needs a separate and much higher approval bar. Staging is only useful if it is genuinely comparable: same code version, same authentication configuration, same tenant isolation model, same infrastructure shape. If staging differs materially from production, say so in the statement of work and note the gap in the report, because a buyer will eventually ask what was actually tested. If a finding can only be validated in production, that is a separate, explicitly approved, narrowly scoped action with a test account you own, written into `DECISION-LOG.md` first.

### Agree the finding-handling process before the report exists

The report is dated the day it is issued, and from that day it circulates to customers, auditors, and your board with whatever it says on it. Decide these things before the engagement starts, not after:

- **Who receives the report**, where it is stored, and who may forward it. Treat the technical report as one of the most sensitive documents in the company. It should not live in a public wiki or a general Slack channel.
- **Critical findings are reported immediately**, mid-engagement, not held for the report. Say so in the statement of work. A live critical finding is an incident trigger: if there is any evidence the issue was already exploited, stop the test workflow and go to `dr-1-incident-response-plan.md` and `dr-0-compromise-assessment.md`.
- **Every finding gets a row in `RISK-REGISTER.md`** with severity, owner, and agreed fix date on the day the report lands. Findings that live only in the report get forgotten.
- **What happens to findings you cannot fix in time.** This is the part everyone gets wrong. You will not fix everything before the report is dated, and that is normal and survivable. What is not survivable is pretending. For each unfixed finding, write down the compensating control, the reason, the named executive accepting the risk, and the target date, and keep that acceptance next to the report. When a buyer asks about a high-severity finding in your report, the correct answer is a specific one: what it was, why it is not exploitable in practice today, what mitigates it now, and when it is fixed. That answer builds more trust than a clean report does. Never edit a firm's report to remove a finding, never ask them to downgrade a severity you disagree with without a technical argument they accept, and never hand a buyer a summary that implies findings were resolved when they were not. That is a misrepresentation you will personally own, and it is exactly the pattern `08-when-it-is-not-working.md` describes.
- **The retest is scheduled at the same time as the test.** Put it in the calendar on day one, or it will not happen.
- **Whether and how you say anything publicly.** A line on the trust page saying that an independent penetration test is performed annually, with the summary available under NDA, is a real sales asset (see `co-1-public-security-docs.md`). Publishing the report itself is not something you do. Any external publication needs an explicit human yes.

**Cadence.** Annually is the normal expectation, and it is what compliance frameworks and buyers assume. Add an extra scoped test when you ship something that materially changes the risk shape: a new multi-tenant data path, a payments flow, a public API, or a machine-learning feature with tool access. Do not buy your first test before the free scanners have been run and their obvious findings fixed (gate G5 above). Paying manual testers day rates to find an unpatched dependency or a missing authorization check that a free tool would have handed you is the most expensive way to learn that lesson.

## 2026 notes

- **The VDP half is now table stakes; the bounty half is not.** In 2019 a VDP was a nice signal. By 2026 enterprise vendor reviews, and public sector procurement in several jurisdictions, routinely check for a published disclosure policy and a reachable `security.txt`. Request for Comments 9116 standardized the file format in 2022, so there is now one correct answer to "where does it go".
- **Automated and AI-assisted report spam is the dominant volume.** Since roughly 2024, maintainers and small programs have been flooded with plausible-looking, entirely fabricated reports generated by language models: convincing prose, invented line numbers, no working proof of concept. The triage cost per junk report went up, because they no longer look like junk at a glance. Your defence is a hard rule: no reproducible steps means no triage. State that requirement in the policy.
- **Beg bounty is worse and better organized.** Mass-emailed "I found a missing security header, please pay me" messages now arrive at almost every domain within days of a `security.txt` going live. Expect it. It is not a reason to skip the file.
- **Scope has to name the modern surfaces explicitly.** In 2019 scope meant the web application. In 2026 you must decide, in writing, whether these are in scope: your public cloud storage buckets, your continuous integration configuration files, your published packages, your model-backed features and prompt injection, and your Model Context Protocol (MCP) servers if you run any. See `07-modern-cells.md`. Silence about a surface is not an answer; researchers will test it and then argue about it.
- **AI features attract a specific report class you must pre-decide on.** "I made your chatbot say something rude" is not a vulnerability. "I made your agent read another tenant's data and send it to my server" is a critical one. Write the distinction into scope before the first report arrives, or you will be arguing about it under time pressure.
- **Safe harbor language matured.** Since 2022 the US Department of Justice has stated it will not charge good-faith security research under the Computer Fraud and Abuse Act, and standard safe harbor wording (the disclose.io style template is the common reference) is now widely reused. You do not need to draft this from scratch, and you should not.

## Failure modes

| Failure | Early tell | Recovery |
| --- | --- | --- |
| Reports arrive faster than you can triage | Unread reports older than a week; you dread opening the mailbox | Publicly pause new submissions with an honest note, clear the backlog, add a second triager before reopening. Do not just go quiet. |
| A real report sat unanswered and the reporter goes public | A social media post or a blog naming your company | Reply immediately and factually, thank them, fix fast, publish a short honest note. Never argue about tone in public. Log it in `DECISION-LOG.md`. |
| Beg bounty volume swamps the mailbox | Ten near-identical header and Sender Policy Framework (SPF) emails in a week | Use the out-of-scope template as a canned reply, add a filter and a label, and add an explicit "we do not pay for missing headers or theoretical findings" line to the policy. Never insult them; it costs nothing to be polite. |
| Scope creep into systems you do not control | A report against a vendor's login page or a payment processor | Reply that it is out of scope, forward it to the vendor's own disclosure channel, tighten your published scope the same day. |
| You promised 24 hours and are answering in 5 days | The first missed acknowledgement | Change the published number to something true, today. Do not quietly keep missing it. |
| Engineering will not fix a valid finding | A confirmed ticket with no owner after two weeks | Move it to `RISK-REGISTER.md` as an accepted risk with a named accepting executive. Named acceptance usually produces a fix within days. |
| A bounty program launches over your objection | A founder announces it on stage or in a deal | Do not fight it in public. Insist on three things: a scope limited to one application, a monthly spend cap, and a named second triager. Log your objection and its date in `DECISION-LOG.md`. |
| The security.txt expires and nobody notices | Automated scanners flag an expired policy file; report volume drops to zero | Set a calendar reminder now for 11 months out and treat the refresh as a 5 minute task. |
| A report is actually an active breach report | The reporter mentions data they already extracted, or names real customer records | Stop triaging. Declare an incident under `dr-1-incident-response-plan.md`. This is no longer a bug report. |

## Copy-paste artifact 1: security.txt

Publish at `https://<domain>/.well-known/security.txt`, served as `text/plain` over HTTPS with no redirect and no authentication. Replace every bracketed value. Keep `Expires` within twelve months and refresh it before it lapses.

If `co-1-public-security-docs.md` has already published a security.txt, edit that file rather than creating a second one. Two files at two paths, or one file published twice with different `Policy:` values, is worse than no file: automated vendor-review tooling reads whichever it finds first, and researchers report to whichever address they see. Publishing is an external action, so it needs an explicit human yes before it happens.

```
# Vulnerability disclosure information for [Company Name]
Contact: mailto:security@[domain]
Contact: https://[domain]/security/disclosure
Expires: [YYYY-MM-DDT00:00:00.000Z, no more than 12 months from today]
Preferred-Languages: en
Canonical: https://[domain]/.well-known/security.txt
Policy: https://[domain]/security/disclosure
Acknowledgments: https://[domain]/security/disclosure#thanks
```

Notes for the agent: `Contact` and `Expires` are the only required fields. Omit `Encryption` unless a Pretty Good Privacy (PGP) key genuinely exists and someone can decrypt mail sent to it; a broken key is worse than none. Omit `Acknowledgments` and `Hiring` until those pages exist, because a link to a 404 undermines the file. Do not include `CSAF` (Common Security Advisory Framework) unless the company publishes machine-readable advisories.

## Copy-paste artifact 2: full vulnerability disclosure policy

Publish at `https://<domain>/security/disclosure`, and link to it from the trust page at `/security`. `co-1-public-security-docs.md` owns the public surface and fixes those two URLs; do not invent a third path. Get the safe harbor paragraph reviewed by someone with authority to make that promise before publishing.

```markdown
# Vulnerability Disclosure Policy

Last updated: [YYYY-MM-DD]

[Company Name] takes the security of our systems seriously, and we value the
security community. We welcome reports of security vulnerabilities in our
products and services from anyone acting in good faith, and this policy
explains how to report one and what you can expect from us.

## How to report

Email security@[domain]. Please include:

- A clear description of the issue and why you believe it is a security problem.
- The exact steps required to reproduce it, including URLs, request details,
  accounts used, and any payload.
- What an attacker could achieve by exploiting it.
- Any supporting material such as screenshots, a short video, or logs.

We cannot triage reports without reproducible steps. Reports consisting only of
automated scanner output, or of a claim without a working proof of concept,
will be closed without detailed review.

Please report in English where possible, and please do not include third party
personal data in your report.

## What you can expect from us

- We will acknowledge your report within 5 business days.
- We will give you an initial assessment, including whether we consider the
  report valid and our severity rating, within 10 business days.
- We will keep you informed of remediation progress at reasonable intervals.
- We will tell you when the issue is resolved.
- With your permission, we will credit you publicly once the issue is fixed.

## What we ask of you

- Give us a reasonable opportunity to fix the issue before you disclose it
  publicly or to any third party. Our default request is 90 days from your
  initial report, and we are happy to discuss a different timeline.
- Do not access, modify, delete, or store data belonging to anyone other than
  yourself. If you inadvertently access other people's data, stop, and tell us
  immediately in your report.
- Do not degrade, disrupt, or damage our services or the experience of our
  users. That includes denial of service testing, automated high-volume
  scanning, and resource exhaustion.
- Do not use social engineering, phishing, or physical intrusion against our
  staff, our users, our offices, or our vendors.
- Use only test accounts you have created yourself. Tell us the account
  identifiers you used so we can distinguish your testing from real attacks.
- Do not demand payment in exchange for withholding disclosure. We do not
  respond to extortion, and we will treat such messages as a security incident.

## Scope

In scope:

- [https://app.[domain] and its API]
- [https://www.[domain]]
- [list any additional domains, mobile applications, or APIs you control]

Out of scope:

- Any system, domain, or service not listed above, including systems operated
  by our vendors and third party providers. We cannot authorize testing of
  systems we do not control.
- Findings that require physical access to a device, or a compromised or
  jailbroken device.
- Social engineering of any kind, including phishing of staff or users.
- Denial of service, volumetric testing, and rate limit exhaustion.
- Reports generated solely by automated tooling with no demonstrated impact.
- Missing security headers, missing cookie flags, weak TLS cipher suites, SPF,
  DomainKeys Identified Mail (DKIM), or Domain-based Message Authentication,
  Reporting and Conformance (DMARC) configuration findings, and similar best practice
  recommendations, unless you can demonstrate a concrete exploit.
- Vulnerabilities affecting users of unsupported or end of life browsers,
  operating systems, or application versions.
- Publicly disclosed vulnerabilities in third party dependencies, unless you
  can demonstrate exploitability against our specific deployment.
- Self exploitation, including issues that require a user to paste code into
  their own browser console or to attack their own account.
- Content, tone, or factual accuracy of output produced by our machine learning
  features. Reports that our assistant can be persuaded to produce
  objectionable text are not security vulnerabilities. Reports that our
  assistant can be induced to access or transmit data belonging to another
  customer, or to take a privileged action on their behalf, are in scope and we
  want to hear about them.

## Rewards

[Choose one and delete the other.]

[Option A, default:] We do not currently operate a paid bug bounty program and
we cannot guarantee any financial reward. We will publicly acknowledge
researchers who report valid issues, with their permission. We may, entirely at
our discretion, offer a reward for a report of exceptional impact.

[Option B, only if you have budget and finance approval:] We pay rewards for
valid, in scope, previously unreported vulnerabilities according to severity.
Current bands are listed at [URL]. Severity is determined by us, taking into
account real world exploitability. We pay the first reporter of an issue;
subsequent reports of the same issue are marked as duplicates.

## Safe harbor

If you make a good faith effort to comply with this policy during your
research, we will consider your research to be authorized. We will not initiate
or support legal action against you for accidental, good faith violations of
this policy, and we will not report you to law enforcement for such activity.
We will take steps to make it known that your actions were authorized under
this policy if legal action is initiated by a third party.

This authorization does not extend to actions that intentionally harm our
users, exfiltrate data beyond what is necessary to demonstrate a
vulnerability, or violate applicable law. You remain responsible for complying
with all laws that apply to you. If you are unsure whether a specific action is
authorized, ask us at security@[domain] before you do it, and we will answer.

## Questions

Email security@[domain]. This policy is versioned; the date at the top reflects
the last substantive change.
```

## Copy-paste artifact 3: three reply templates

Save these where the human can reach them in under a minute. Fill the bracketed fields every time; a template that still contains a bracket is worse than a short original message.

**Template A: valid report, acknowledged.** Send within 5 business days. Never argue severity in the first reply.

```
Subject: Re: [their subject] (tracked as VDR-[NNNN])

Hi [name],

Thank you for reporting this to us, and for the clear reproduction steps. I have
reproduced the issue and confirmed it is valid. We are tracking it internally as
VDR-[NNNN].

Our current assessment is [severity], because [one sentence on real world impact].
Our target is to have a fix deployed by [date]. I will write to you when it is
resolved, and sooner if that timeline changes.

Two requests. First, please hold off on public disclosure until the fix is
deployed, or until [date], whichever comes first. If you need a different
timeline, tell me and we will work it out. Second, if you would like credit on
our acknowledgements page, send me the name and any link you would like used. If
you would prefer to stay anonymous, that is completely fine.

We do not currently run a paid bounty program, so I cannot offer a reward, but I
genuinely appreciate the time you spent on this and the care you took in
reporting it.

[Your name]
Security, [Company]
```

**Template B: out of scope or not a vulnerability.** Be specific about why, and stay warm. This person may find something real next time.

```
Subject: Re: [their subject]

Hi [name],

Thanks for taking the time to write this up. I looked at it, and it falls outside
what we treat as a vulnerability, for this reason: [specific reason, for example
"the affected host is operated by our payment provider and we are not able to
authorize testing against it", or "this requires the victim to paste attacker
supplied code into their own browser console, which we do not consider a
practical attack path"].

Our full scope and exclusions are published here: https://[domain]/security/disclosure

I am not disputing that you found what you described. It just is not something we
will be changing, and I would rather tell you that plainly than leave you waiting.

If you find something with a demonstrable impact on our users or their data,
please do send it, and I will look at it quickly.

[Your name]
Security, [Company]
```

**Template C: beg bounty and low quality automated reports.** One reply, then filter. Do not escalate, do not insult, do not negotiate. If they reply demanding payment, stop responding and keep the thread.

```
Subject: Re: [their subject]

Hi,

Thanks for the note. The item you describe is on our published exclusions list at
https://[domain]/security/disclosure, and we do not treat it as a vulnerability without a
demonstrated exploit.

We do not operate a paid bug bounty program and we do not pay for reports.

If you have a proof of concept showing concrete impact on our users or their data,
send it and I will review it. Otherwise I am going to close this out here.

[Your name]
Security, [Company]
```

Agent rule for Template C: send it exactly once per reporter. If the same person sends five more variations, filter them and stop replying. Do not send a legal threat, do not report them anywhere, and do not mock them publicly. The cost of a filter rule is zero; the cost of a viral screenshot of a rude security team is not.

## Related cells

- [se-1-sdlc-and-design-reviews.md](se-1-sdlc-and-design-reviews.md): findings from outside have to land in the same fix pipeline as findings from inside.
- [se-2-understand-the-tech-stack.md](se-2-understand-the-tech-stack.md): you cannot define scope without an asset inventory.
- [se-3-secrets-and-keys.md](se-3-secrets-and-keys.md): exposed credentials are the most common valid external report; rotation must be ready first.
- [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md): some reports are breach notifications wearing a bug report costume.
- [dr-2-top-security-signals.md](dr-2-top-security-signals.md): you need to tell researcher traffic from attacker traffic.
- [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md): how a report reaches you when it lands in a founder's inbox instead.
- [co-1-public-security-docs.md](co-1-public-security-docs.md): the VDP lives on the public security page and is a sales asset.
- [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md): "do you have a vulnerability disclosure policy?" is a recurring questionnaire item.
- [co-3-existing-commitments.md](co-3-existing-commitments.md): check whether a bounty was already promised in a contract before you decide.
- [07-modern-cells.md](07-modern-cells.md): supply chain, CI/CD, cloud posture, and AI surfaces that scope must now address explicitly.
- [08-when-it-is-not-working.md](08-when-it-is-not-working.md): what to do when the company wants to publish a disclosure policy, a safe harbor promise, or a response time it does not intend to honor, and how to avoid personally owning that claim.
- [dr-0-compromise-assessment.md](dr-0-compromise-assessment.md): when a report describes access someone already had, the question stops being "is this a bug" and becomes "how long have they been in here".
- [06-2019-to-2026-delta.md](06-2019-to-2026-delta.md): why "hold off if you can" aged well while other cells did not.
