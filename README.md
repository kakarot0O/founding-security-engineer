# Founding Security Engineer: operating manual

You are the first security hire. This is the manual for the partner that walks it with you.

**This is a portable pack, not a machine-local setup.** It is a plain directory of markdown plus one shell script. Clone it onto any machine, run the installer, and you have the same partner. Take it to whatever company you land at next. Nothing in it is tied to a laptop, a company, a cloud, or a stack.

| Piece | What it is |
|---|---|
| `skills/founding-security-engineer/` | The partner. Runs in your main conversation. Asks you questions, scans the environment, walks the plan. Ships with 24 playbooks. |
| `agents/security-recon.md` | A read-only worker the partner dispatches for heavy discovery so your conversation stays readable. |
| `portable/SYSTEM-PROMPT.md` | A single self-contained block for machines or companies where you cannot install anything. Paste it into any assistant, or read it as a plain runbook. |
| `install.sh` | One command install, update, check, and uninstall. macOS, Linux, WSL. |
| `.claude-plugin/` | Plugin and marketplace manifests, if you would rather distribute it to a team than to a laptop. |

---

## 1. How to run it

**Install once per machine** (see `INSTALL.md` for the other three ways):

```bash
git clone <your-repo-url> founding-security-engineer
cd founding-security-engineer
./install.sh
```

It symlinks into `~/.claude`, so `git pull` updates it with no reinstall. `./install.sh --copy` if the repo will not stay put. `./install.sh --uninstall` to remove it.

**Then, anywhere on that machine:**

```bash
cd /path/to/whatever/you/are/securing     # a repo, an infra repo, or an empty folder
claude
```

Then:

```
/founding-security-engineer
```

That is it. It works the same in a monorepo, in a Terraform repo, in a docs folder, or in an empty directory with nothing but your laptop. If there is no code, it says so and switches to the interview and access-request path instead of the code path.

**First run in a new company.** Just say what you know:

```
/founding-security-engineer

I started Monday as the first security hire. Series A, 40 people, mostly remote.
I have a laptop and a Google account. That is all I have so far.
```

It will orient, introduce itself, ask **one** question, and start.

**Resuming, days or weeks later.** Same command. It reads `.security/` and opens with where you are, what is parked, and what is next. You do not have to re-explain anything.

**Optional: pin it to a company.** State files default to `./.security/` in whatever directory you launched from. If you have no repo, it will offer `~/security-program/<company>/`. Either way it asks once whether that directory should be committed to version control or gitignored. Recommendation it will give you: commit it, to a **private** repo. A lost security program is worse than a slightly sensitive one, and you will want the history.

**More than one company.** The install is global; the program state is not. One install, as many independent programs as you have clients or employers, each with its own `.security/` directory. Nothing bleeds between them. When it is ambiguous which one you mean, it asks.

**A machine where you cannot install anything.** Use `portable/SYSTEM-PROMPT.md`. Paste it into whatever assistant you are allowed to use, or read it as a runbook with no model at all. You lose the 24 detailed playbooks and keep the spine: behaviour, framework, sequencing, cold start, interrupts, and stop conditions.

---

## 2. Should you ask it questions?

Yes, but that is not the main mode. **It asks you.** It is designed to interrogate the environment first and interrogate you second, only for what it cannot discover.

Things worth asking it directly, in roughly this order:

**Day one**
- "What should I do first, and what should I explicitly not do?"
- "What can you already tell about this environment without any access?"
- "What access should I ask for, from whom, and in what order?"
- "Draft the message I send to the CTO asking for it."

**Week one**
- "Walk me through understanding our tech stack. I do not know what to ask engineers."
- "What has this company already promised customers that I do not know about?"
- "Show me the current state. What is unknown versus what is actually fine?"

**Ongoing**
- "What is the next step?" (the default question; it should already be telling you)
- "Why this before that?" (it must defend sequencing; make it)
- "Is this good enough for a company our size, or am I gold-plating?"
- "What is the cheapest version of this that still counts?"
- "What would you push back on if you were me?"
- "A customer sent a security questionnaire. Take it."
- "Give me the day 30 review I present to the founders."

**When you are unsure whether something is a big deal**
- "Here is what I found. How bad is this really, and what do I do in the next hour?"

Questions that will get you a straight refusal and a redirect: anything asking it to change access, enforce MFA, rotate a live credential, scan something, or publish something without your explicit approval. It stops and asks. That is deliberate. (Section 6 has the full list, and the one narrow exception to it.)

---

## 3. How to operate with it

> Read `examples/first-week-transcript.md` once before your first session. It is a short worked transcript of a real-shaped first week: cold start, an agent-initiated interrupt, a live incident landing mid-task, a resume, and the Friday founder update. You will learn the rhythm faster from that than from this section.

**It is a partner, not a tool.** Expect it to have opinions and to disagree with you. If it never pushes back, something is wrong with the setup.

**The rhythm.** Every turn ends with one named next action and a go or no-go. Your job is mostly to say go, no, or "not that, this instead". You are the one with context about the people and the politics; it is the one with context about the security.

**Baby steps are the point.** It will not dump a 90 day plan on you. If you want the whole map, ask for it explicitly:
```
Show me the full 90 day plan, then go back to walking it step by step.
```

**Overrule it freely.** When you do, it logs the decision and the reasoning in `.security/DECISION-LOG.md` and helps you execute your call. That log is not bureaucracy; it is the thing that protects you in nine months when someone asks why.

**Make it prove things.** It is instructed never to mark something done without evidence. If it says a control is in place, ask "show me". Anything unverified stays `unknown` in `.security/SECURITY-STATE.md`, and `unknown` is a perfectly respectable state to be in during month one.

**Feed it reality.** Tell it when a founder is hostile to process, when engineering is drowning, when a deal is blocked, when you have no budget. It reorders the plan around constraints. Withholding the politics makes its advice worse.

**Use the worker for heavy lifting.** When a scan would produce a wall of output, ask:
```
Dispatch security-recon to survey the cloud account and just give me the findings.
```

**What it writes down**, in `.security/`:

| File | Read it when |
|---|---|
| `SECURITY-STATE.md` | You want the honest current picture, one row per grid cell |
| `RISK-REGISTER.md` | You need to show someone what the risks are and who accepted what |
| `90-DAY-PLAN.md` | You want to see the map and where you are on it |
| `CONTEXT-STACK.md` | You want to know what is parked |
| `DECISION-LOG.md` | Someone asks why you did or did not do something |
| `ACCESS-LOG.md` | You need to chase access that was promised and never granted, or an ask you drafted and never sent |
| `SECURITY-CHARTER.md` | Someone asks what you are allowed to decide on your own and what needs a founder |

---

## 4. When something urgent lands in the middle of something else

This is the normal state of a first security hire's week, so it is a first-class feature rather than an afterthought.

**Say any of these and it handles the switch:**

| You say | It does |
|---|---|
| `park this` / `hold on` | Writes a full frame to the context stack: what was done, the exact next action, open decisions, files touched. Then asks what came up. |
| `urgent` / `incident` | Parks automatically and jumps straight to incident response. No ceremony. |
| `switch to X` | Parks, then triages X before starting it. |
| `resume` / `where were we` | Pops the stack, restates the parked context in at most five lines, names the exact next action, continues. |
| `what is parked` | Prints the stack. |
| `drop it` | Removes a frame, but only after stating what is being given up. Nothing is dropped silently. |

**It triages the interruption rather than just obeying it.** Five classes, five different responses:

1. **Live incident.** Pre-empts everything. Everything else parks.
2. **Revenue blocking** (customer questionnaire, deal-blocking security review). Time-boxed and scheduled, not dropped-everything. It will tell you how long it should take and when to do it.
3. **Engineering blocking** (a design review needed before a release ships). Fast lightweight answer now, proper follow-up parked.
4. **New information that changes the plan.** Recorded, and it triggers a re-plan at the next natural boundary rather than derailing the current step.
5. **A distraction.** It will say so, out loud, with a reason, put it in the backlog, and not start it. You can override. It will still say it.

**It can interrupt you too.** If it finds something mid-task that outranks what you are doing, it stops and says: the finding, the severity, the evidence, what it costs to wait, and its recommendation. Then you decide. It is not allowed to silently switch tasks on you.

**Guardrails against losing the thread.** More than three parked frames and it flags overload and makes you prune. It prints the stack at the end of any session with parked work. Old frames get escalated or explicitly killed with a reason, never left to rot.

---

## 5. The framework it runs on

AppSec California 2019 (OWASP AppSecCali), **Evan Johnson**, then Senior Security Engineer at Cloudflare, talk titled *"Startup security: Starting a security program at a startup"*, slide **"4 things to do in each security domain"**. Four domains, four things each, sixteen cells. [Session listing](https://appseccalifornia2019.sched.com/event/GS4T/startup-security-starting-a-security-program-at-a-startup)

| | Security Engineering | Detection & Response | Compliance | Corporate Security |
|---|---|---|---|---|
| 1 | SDLC and security design reviews | Basic incident response plan | Public facing security docs | Identity and Access Management |
| 2 | Understanding your tech stack | Top security signals for your org | Knowledge base for questionnaires | Endpoint security |
| 3 | Secrets, API keys, customer secrets | Consumption model for logging | Understand existing commitments | On-boarding and off-boarding |
| 4 | Bug bounty (hold off if you can) | Comms channel with the company | *(blank on slide 18)* | Workplace security 🎁 |

The original `.pptx` was located and extracted, and slide 18 byte-matches the photo. Three things that verification changed:

- **The fourth Compliance cell is not actually blank.** Slide 18 is frame two of a five-slide progressive build; by slides 20 and 21 Johnson fills it as **"GDPR and current laws"**. Our CO-4 widens that to data inventory, privacy commitments, and framework choice, and is presented as a superset of his answer rather than as filling a void.
- **That mark on Endpoint is a gift emoji.** It is Johnson's marker for a cheap win: high value, low effort. A hint about effort, not importance.
- **Slide 16 is the one that matters most**, titled *"It all depends"*. It lists what determines priority: business-to-business or business-to-consumer (his notes: *"this is, in my opinion, the biggest thing"*), company size, customer base, product, engineering velocity, culture. He does not hand out a sequence. He hands out the dimensions that produce one, which is exactly why this agent derives order from findings rather than reciting a list.

His framing of the whole playbook: *"The common denominator of all of these is that they're short in scope. You can get 95% of the way to at least initially addressing all of these in a quarter."* That is the bar.

Sources: [video](https://www.youtube.com/watch?v=6iNpqTZrwjE) · [original slides](https://hosted-files.sched.co/appseccalifornia2019/22/Evan%20Johnson%20-%20Starting%20Security%20at%20a%20Startup.pptx)

### What was added on top

Independent review found real gaps in the 2019 grid, so eight more cells and two situational playbooks were added:

| Added | Why |
|---|---|
| **DR-0** Are we already compromised? | Runs **first**. It is the only item on a clock: log retention is often 7 to 90 days, so the evidence expires while you draw architecture diagrams. |
| **SE-5** Consumer account security | B2C is named the most important branching question and then nothing serviced it. A consumer company would have spent 90 days on corporate identity and questionnaires that never arrive. |
| **M-1** to **M-5** | Supply chain, CI/CD as the crown jewel, cloud posture, SaaS and OAuth sprawl, AI and LLM security. None existed as first-class concerns in 2019. |
| **M-6** Backups and recovery | Absent from the 2019 slide too. The pack was telling you to publish recovery-time claims it never taught you how to obtain. |
| **When it is not working** | A decorative mandate, access that never arrives, and what to do when you are asked to sign or publish something you cannot evidence. Nobody tells a first hire this. |
| **Outsourced engineering** | Very common at seed stage: an agency owns the cloud root account, the repos, and the app store listing. Every other control sits on assets you may not own. |

Everything is referred to by cell identifier (SE-2, CS-1, M-6). Each has a playbook: why it exists, what done looks like at startup scale, how to discover the current state, what to ask a human when you cannot discover it, the numbered walk, the decision forks with a recommended default, the danger zone, what not to do yet, and the failure modes.

**Important:** the grid is a checklist for the *agent's* blind spots, not a work order for you. It never decides what happens next; findings do. A cell can be closed `n/a` with a written reason, and a finding that fits no cell is still worked. If the agent ever proposes a step by citing a cell identifier instead of a fact about your company, it has drifted, and there is an anti-pattern section that tells it so.

**Default order it will argue for:** understand the stack and fix identity first, find the promises the company already made, then secrets and the comms channel, then joiner/leaver and laptops, then incident response and logging and detections, then the compliance artifacts, then design reviews once you have credibility, and bug bounty deferred past day 90 in almost every case.

---

## 6. Things it will refuse to do without an explicit yes

Every one of these stops and asks first, every time:

- Changing anyone's access, roles, or authentication requirements
- Enforcing MFA, conditional access, or device compliance on a population
- Enrolling or wiping a device
- Rotating a credential something in production uses
- Any active scan or test against any system, including your own, without written authorisation
- Anything touching a customer or customer data
- Publishing anything externally, including a trust page or a security.txt
- Committing to a customer that a control exists or will exist by a date
- Turning on a log source that could materially increase a bill
- Deleting, force-pushing, or rewriting repository history
- Buying anything, or telling someone else to buy anything
- Anything that cannot be reversed at all. Its own category, and not the same thing as expensive: an object storage immutability or retention lock in compliance mode, locking a backup vault past its cooling-off period, scheduling an encryption key for deletion (which silently destroys every backup encrypted with it), removing an account from a cloud organisation, moving a subscription to another tenant, transferring an app store listing, a registrar transfer. For these it wants the yes in writing rather than in conversation, and it will tell you what living with the decision costs for its full duration
- Any restore, failover, or recovery drill. It names the exact target and confirms the target does not already exist first, because a drill pointed at a live identifier destroys live data

If you say yes, it records the approval with your name and the date. That record is for your protection.

**There is exactly one named exception, and only if you set it up in advance.** Inside a formally declared incident with a named incident commander, two identity-scoped containment actions can proceed on the commander's authority: revoking a named employee's active sessions and refresh tokens, and revoking a third party application's access grant. That only holds if the pre-authorisation was agreed beforehand and recorded in `DECISION-LOG.md`. Nothing else is covered by it, and no other hard stop has an exception. The exact boundary is in the hard stops section of [`skills/founding-security-engineer/SKILL.md`](skills/founding-security-engineer/SKILL.md).
