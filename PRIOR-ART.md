# Prior art: what already exists

Scanned 2026-08-25. Question asked: does something like this already exist, free or open source, on GitHub or elsewhere?

**Short answer.** Plenty exists in each of the four quadrants below. Nothing found combines them. The pieces this pack is built from are individually well covered, and several of those sources are better than anything we would write from scratch, so the playbooks should link out to them rather than pretend to be the only source.

---

## Quadrant 1: free written guidance, no agent

The content competitors. These are the canon for startup security programs and they are all free.

| Resource | What it is | Overlap with this pack |
|---|---|---|
| [Starting Up Security](https://scrty.io/) (Ryan McGeehan, `@magoo`) | The canonical long-form guide to building a startup security program. Enough material for the first two years. Chapters on risk scenarios, information security policy, why you do not need a CSO. | High on principles and on risk framing. No sequencing walk, no environment discovery, no interactivity. |
| [Startup Security Starter Pack](https://ramimac.me/wiki/startup-security-starter-pack/) (Rami McCarthy) | Curated reading list, organised Start Here / Read More / Reference / Scale. | It is a map to the canon, not a program. Explicitly does not give a prescriptive timeline or sequencing for a new hire. |
| [Latacora blog](https://latacora.github.io/blog/), "The SOC2 Starting Seven" | Prescriptive, opinionated tactical controls to implement early. | Overlaps CO-4 and parts of CS-1 and M-3. Prescriptive in a way most guidance is not, which is a genuine strength. |
| [MVSP](https://mvsp.dev/) Minimum Viable Secure Product | A minimalist control checklist for B2B suppliers. | Overlaps CO-1 and CO-2. Useful to cite when a customer asks what baseline we meet. |
| [Evan Johnson, AppSecCali 2019](https://appseccalifornia2019.sched.com/event/GS4T/startup-security-starting-a-security-program-at-a-startup) | The talk this pack's grid comes from. Confirmed: Senior Security Engineer at Cloudflare, "Startup security: Starting a security program at a startup". | This is the source, not a competitor. |

**Gap they leave:** all static prose. None of them tell you what to do in the next hour, none of them look at your actual environment, and none of them adapt when a contract turns up that reorders the plan.

---

## Quadrant 2: free template packs, no agent

| Resource | What it is | Overlap |
|---|---|---|
| [sectemplates](https://github.com/securitytemplates/sectemplates) (914 stars) | The closest artifact competitor. Six packs: Security Partners, Bug Bounty, External Pentest, Incident Response, Vulnerability Management, Security Exceptions. Preparation checklists, runbooks, metrics, document templates. | Directly overlaps DR-1, SE-4, and parts of SE-1. Genuinely good. **Recommendation: link to it from those playbooks rather than reinventing the artifacts.** Note the license is free for use but restricts derived products sold on. |
| [startup-security-kit](https://github.com/st-hisatoshi-2973/startup-security-kit) | Lightweight ISMS templates, developer security checklists, secure backend patterns. | Overlaps CO-4 and SE-1. Smaller and less battle-tested than sectemplates. |
| [startup-security-with-opensource-tools](https://github.com/Alevsk/startup-security-with-opensource-tools) | Compilation of open source security tooling to deploy at a startup. | Overlaps the tooling recommendations inside several playbooks. Tool list, not a program. |
| [CISO-Dashboard](https://github.com/SiteQ8/CISO-Dashboard) | Open source security KPI dashboard with CIS and NIST CSF 2.0 mappings. | Overlaps `05-metrics-and-comms.md`. A dashboard, not guidance on what to measure and why. |

**Gap they leave:** templates with no sequencing and no judgment about what to do first, or at all, at your size.

---

## Quadrant 3: Claude Code and AI agent security skills

This is the busiest quadrant and the one worth watching. All MIT or similar, all free.

| Resource | Stars | What it is | Overlap |
|---|---|---|---|
| [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills) | 365 | **The closest thing found.** 29 skills for Claude Code, Cursor, Codex. Explicitly targets "founders/operators securing stacks without dedicated CISOs". Includes `iam-audit`, `incident-triage`, `cloud-audit`, `secrets-audit`, `csf-mapping`, `security-comms`, `threat-modeling`, `privacy-engineering`. | Substantial overlap on the audit verbs. **No 90 day plan, no sequencing, no partner persona, no interrupt protocol** (confirmed by reading the repo). It answers "audit this", not "what do I do first, and then what". |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 124 | "Transform Claude Code into your personal security engineer". 50+ skills, heavily offense, DFIR, and reverse engineering. Strong design discipline: explicit scope, hand-off, and "Rationalizations to Reject" sections. | Minimal overlap. Practitioner tradecraft, not program building. Explicitly excludes identity governance, compliance, corporate security, onboarding/offboarding, and 90 day plans. |
| [Security-Phoenix-demo/security-skills-claude-code](https://github.com/Security-Phoenix-demo/security-skills-claude-code) | 66 | AppSec shift-left kit: CTI research, secure PRD generator with STRIDE, OpenGrep/SAST rule generation, pre-merge reviewer, plus session hooks that gate package installs. | Overlaps SE-1 and M-1. The install-gating hook is a good idea worth borrowing. Code-time only. |
| [trailofbits/skills](https://github.com/trailofbits/skills) | - | Security research, vulnerability detection, and audit workflows from a top-tier audit firm. | Deep technical audit. No program layer. |
| [eth0izzle/security-skills](https://github.com/eth0izzle/security-skills) | - | Claude Code skills to help security teams stay secure. | Assumes a security team exists. |
| [UnitOneAI/SecuritySkills](https://github.com/UnitOneAI/SecuritySkills) | - | OWASP/NIST/MITRE/CIS-grounded skills across Claude Code, Gemini CLI, Cursor, Codex, Kiro. | Framework-mapped audits. No sequencing. |
| [BagelHole/DevOps-Security-Agent-Skills](https://github.com/BagelHole/DevOps-Security-Agent-Skills) | - | 80+ skills: Kubernetes, Terraform, cloud, container hardening, SOC 2 / ISO 27001, incident response. | Overlaps M-2, M-3, CO-4. Platform-engineering shaped. |

**Gap they leave, consistently:** every one of these is a **task tool**. You already have to know which audit to run. None of them is a colleague who decides what matters this week, defends the order, and remembers where you were. And every one of them is code-and-cloud weighted: **corporate security is the shared blind spot**. Almost nobody covers joiner/mover/leaver, endpoint fleet, workplace and payment fraud, which is where startups actually get hurt.

---

## Quadrant 4: AI vCISO and GRC platforms

| Resource | What it is | Overlap |
|---|---|---|
| [vciso.com/skills](https://www.vciso.com/skills) | MIT-licensed Claude Code skills from a vCISO firm: SOC 2 Readiness Scorecard (live), SOC 2 Policy Template Kit, Threat-informed Baseline, **Security Questionnaire Responder**, Board Briefing Generator. | Direct overlap with CO-2 and parts of `05-metrics-and-comms.md`. Important caveat found on the page: most are roadmap, not shipped, and the firm states plainly that "the tools amplify the human work; they do not replace the call". Discovery happens on a consultation call, not in the tool. |
| [intuitem/ciso-assistant-community](https://github.com/intuitem/ciso-assistant-community) | Open source GRC platform. 150+ frameworks with automatic control mapping: ISO 27001, NIST CSF, SOC 2, CIS, PCI DSS, NIS2, DORA, GDPR, HIPAA, CMMC. Risk management, AppSec, audit, third party risk, BIA, privacy, reporting. | The heavyweight in this space and genuinely impressive. It is a **web application you operate**, not a partner that walks you. It assumes you already know which framework you want and what your controls are. Good destination for the state files once the program outgrows markdown. |
| [IBM/ITBench-CISO-CAA-Agent](https://github.com/IBM/ITBench-CISO-CAA-Agent) | Research agents (CrewAI, LangGraph) that automate compliance assessment, generate Kyverno/OPA policy from natural language, and collect evidence via GitOps. | Overlaps CO-4 evidence automation. Research-grade, compliance-only, Kubernetes-shaped. |
| [NVISOsecurity/cyber-security-llm-agents](https://github.com/NVISOsecurity/cyber-security-llm-agents) | AutoGen agents for day-to-day cyber security tasks. | Operational tasks, not program building. |
| Vanta, Drata, Secureframe, JupiterOne, Latacora (service) | Commercial. | Out of scope: paid. Worth knowing they exist because they change the CO-4 sequencing argument, which is covered in the 2019 to 2026 delta. |

---

## What is actually unclaimed

Five things, and they are the reason this pack is worth building rather than just bookmarking the list above.

1. **Nothing is organised around Evan Johnson's 4x4 grid.** The talk is well regarded and the grid is a genuinely good spine, but no one has turned it into an executable program.
2. **Nothing is a partner persona with an enforced behavioural contract.** Opinions stated, disagrees out loud, one named next action, go or no-go every turn, never mutates without a yes. Every skill collection found is imperative: you invoke a verb, it does the verb.
3. **No sequenced, gated walk.** Zero of the resources found refuse to dump the plan and instead walk it one step at a time with exit criteria per gate. The 90 day artifacts that do exist are static documents.
4. **No interrupt or context-switch protocol.** This appears to be genuinely novel. Searches for a context stack, park and resume semantics, or interrupt triage in an agent skill returned nothing. Given that constant interruption is the defining feature of the first security hire's week, this is a real gap.
5. **No cold start in an unknown environment.** Nothing found does read-only orientation, tiered discovery by available access, and drafting of the actual access request messages. The commercial products start after you have granted them integrations; the skill collections start after you already know what to audit.

Honourable mention for the sixth: **corporate security coverage**. It is the shared blind spot of the entire AI agent quadrant.

---

## What we should do about it

1. **Link out, do not reinvent.** `dr-1-incident-response-plan.md` and `se-4-bug-bounty-and-disclosure.md` should cite [sectemplates](https://github.com/securitytemplates/sectemplates) directly. `co-4` should cite Latacora's SOC 2 Starting Seven and MVSP. The whole pack should point at [scrty.io](https://scrty.io/) as further reading. Citing better sources makes the pack more credible, not less.
2. **Read `briiirussell/cybersecurity-skills` before finalising.** It is MIT, it is the nearest neighbour, and it is well built. Worth checking whether any of its 29 audit skills should simply be recommended as companions rather than duplicated.
3. **Consider CISO Assistant as the graduation path.** When a program outgrows markdown state files, that is where it should go. Saying so in `05-metrics-and-comms.md` is more honest than pretending markdown scales forever.
4. **Borrow the install-gating hook idea** from the Phoenix Security repo for M-1 supply chain.
5. **Keep the differentiators sharp.** Partner persona, gated walk, interrupt protocol, cold start, and corporate security coverage are the whole moat. Do not let them get diluted into another audit skill collection.

---

## Sources

- [Starting Up Security (scrty.io)](https://scrty.io/) and [Starting Up Security: From Scratch](https://magoo.medium.com/starting-up-security-from-scratch-6f9a41199a65)
- [Startup Security Starter Pack, Rami McCarthy](https://ramimac.me/wiki/startup-security-starter-pack/)
- [sectemplates](https://github.com/securitytemplates/sectemplates)
- [startup-security-kit](https://github.com/st-hisatoshi-2973/startup-security-kit)
- [startup-security-with-opensource-tools](https://github.com/Alevsk/startup-security-with-opensource-tools)
- [briiirussell/cybersecurity-skills](https://github.com/briiirussell/cybersecurity-skills)
- [trilwu/secskills](https://github.com/trilwu/secskills)
- [Security-Phoenix-demo/security-skills-claude-code](https://github.com/Security-Phoenix-demo/security-skills-claude-code)
- [trailofbits/skills](https://github.com/trailofbits/skills)
- [eth0izzle/security-skills](https://github.com/eth0izzle/security-skills)
- [UnitOneAI/SecuritySkills](https://github.com/UnitOneAI/SecuritySkills)
- [BagelHole/DevOps-Security-Agent-Skills](https://github.com/BagelHole/DevOps-Security-Agent-Skills)
- [vciso.com free skills](https://www.vciso.com/skills)
- [intuitem/ciso-assistant-community](https://github.com/intuitem/ciso-assistant-community)
- [IBM/ITBench-CISO-CAA-Agent](https://github.com/IBM/ITBench-CISO-CAA-Agent)
- [NVISOsecurity/cyber-security-llm-agents](https://github.com/NVISOsecurity/cyber-security-llm-agents)
- [SiteQ8/CISO-Dashboard](https://github.com/SiteQ8/CISO-Dashboard)
- [Latacora blog](https://latacora.github.io/blog/)
- [Evan Johnson, AppSec California 2019 session listing](https://appseccalifornia2019.sched.com/event/GS4T/startup-security-starting-a-security-program-at-a-startup)
