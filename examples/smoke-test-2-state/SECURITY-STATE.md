# Security state

Company: Acme Analytics
Org slug: acme-analytics
Owner of this file: Sam Okafor, first security hire
Location: ~/acme-security/security-register, moved there 2026-08-26, see D-007. Not yet a git repository.
Created: 2026-08-26
Last full review: 2026-08-26

## Environment and business facts

| Fact | Value | Source | Confirmed on |
| --- | --- | --- | --- |
| Business model | business-to-business (B2B) | README.md, plus Sam confirmed | 2026-08-26 |
| Headcount total | unknown | | |
| Headcount engineering | unknown; one platform engineer named (Dev Patel) | Sam | 2026-08-26 |
| Funding stage | unknown | | |
| Product summary (one line) | Customer-facing analytics for B2B SaaS teams; approximately 200 customer companies | README.md, Sam | 2026-08-26 |
| Primary language(s) and framework(s) | Node.js, Express | package.json, src/ | 2026-08-26 |
| Package ecosystems in use | npm | package.json | 2026-08-26 |
| Cloud provider(s) | AWS, plus Google Cloud (BigQuery) used by the nightly analytics export | infra/main.tf, scripts/export-analytics.sh | 2026-08-26 |
| Number of cloud accounts, projects, or subscriptions | unknown; at least one AWS account and one GCP project (`acme-analytics-prod`) | scripts/export-analytics.sh | 2026-08-26 |
| Code host | GitHub, private repository | .github/, Sam checked the settings page | 2026-08-26 |
| Continuous integration (CI) system | GitHub Actions | .github/workflows/ci.yml | 2026-08-26 |
| Identity provider for employees | unknown; a Google Workspace domain is implied by "anyone with a Google account on our domain" | docs/runbook.md | 2026-08-26 |
| Single sign-on coverage | unknown | | |
| Chat platform | unknown | | |
| Device fleet | employee-owned personal machines, bought and expensed by the individual. No company-owned hardware. Mixed operating systems, unmanaged. | human-confirmed: Sam Okafor, from his own onboarding | 2026-08-26 |
| Device management tool | none | human-confirmed: Sam Okafor reports no enrolment during onboarding and no tool known to exist | 2026-08-26 |
| Secrets management | 1Password team vault holds a shared bastion key; application secrets live in individual engineers' local `.env` files; no secret manager referenced in the repository | docs/runbook.md, repo grep | 2026-08-26 |
| Production data stores | PostgreSQL (production cluster, reached via a bastion); S3 bucket `acme-customer-exports-prod`; Google BigQuery dataset `analytics.nightly` | infra/main.tf, docs/runbook.md, scripts/export-analytics.sh | 2026-08-26 |
| Data classes held | personally identifiable information (PII) implied: a `users` table is exported nightly. Payment data handling unknown; a Stripe secret key exists in `.env.example`. Health data unknown; a healthcare prospect (Meridian Health) is in a late-stage deal. | .env.example, scripts/export-analytics.sh, Sam | 2026-08-26 |
| Regulated scope claimed | SOC 2 Type II is claimed on the public security page. No report located. See R-007. | docs/security.md | 2026-08-26 |
| Customer commitments already signed | unknown. A security addendum is present in the draft Meridian Health master services agreement (MSA), not yet read. See CO-3. | Sam | 2026-08-26 |
| Who can deploy to production | Dev Patel, reported as the only person who deploys | Sam | 2026-08-26 |
| Existing security tooling | none found | repo survey | 2026-08-26 |
| Security budget for this year | unknown | | |
| Who I report to | Priya (surname unknown), the person who hired Sam | Sam | 2026-08-26 |

## Organisational facts

| Fact | Value | Source | Confirmed on |
| --- | --- | --- | --- |
| Who can say yes to a security change that slows engineering down | unknown; Priya is the likely answer | Sam | 2026-08-26 |
| Who owns the budget you would spend | unknown | | |
| Last incident the company had, and when | INC-2026-001, declared 2026-08-25, SEV1, investigating. Approximately five months of unauthorised access to the finance operator's mailbox, earliest observed sign-in 2026-03-17, still active 2026-08-25 06:12. Payment fraud attempt delivered as a reply inside a genuine supplier email thread, which establishes that a third party has read that conversation. No payment made. Before that, none reported. The hiring trigger was a security addendum in the Meridian Health MSA draft, not an incident. | Sam | 2026-08-26 |
| Allies, the engineers who already care | Dev Patel acted on a security request within a day of being asked, and pushed back on one item with a stated reason and a date rather than ignoring it. Treat as an ally. | Sam | 2026-08-26 |
| Sceptics, and what they object to | unknown | | |
| Engineering velocity and release rhythm | unknown. Repository history shows 7 commits, all by one author. | git log | 2026-08-26 |
| Engineering culture around process | unknown | | |
| Engineering staffing model | mixed. One internal platform engineer. An agency, Northwind Digital, set up the AWS account before there were engineers and is reported to still hold root. Apparent non-staff accounts hold GitHub repository access. | Sam | 2026-08-26 |

## Log retention clocks

Owned by DR-0. Written before any hunting, because this evidence expires.

| Source | Retention window | How it was confirmed | Earliest date still visible today | Date checked |
| --- | --- | --- | --- | --- |
| AWS CloudTrail | unknown | not yet accessible, blocked on A-001 | unknown | 2026-08-26 |
| GitHub organisation audit log | unknown | not yet accessible, blocked on A-002 | unknown | 2026-08-26 |
| Application access logs (Express service) | unknown | no logging configuration found in `src/` | unknown | 2026-08-26 |
| Retool support tool | reported as none, free tier | reported-absent: docs/runbook.md, 2026-08-26, unverified | n/a | 2026-08-26 |
| Bastion host SSH sessions | reported as not recorded | reported-absent: docs/runbook.md, 2026-08-26, unverified | n/a | 2026-08-26 |

## Ownership map

Created because an agency set up and may still control core infrastructure.

| Asset | Platform | Registered owner | Evidence (command or console path, and date) | Recovery email | Payer | Blast radius if lost | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AWS account root | AWS | reported: Northwind Digital | reported: Sam relaying Dev Patel, 2026-08-26, unverified | unknown | unknown | Total. All production data and infrastructure. | unknown |
| GCP project `acme-analytics-prod` | Google Cloud | unknown | scripts/export-analytics.sh, 2026-08-26 | unknown | unknown | Full nightly copy of production users, reports and events. | unknown |
| GitHub organisation | GitHub | unknown | Sam is a normal member and cannot see organisation owners, 2026-08-26 | unknown | unknown | All source code, plus production credentials in history. | unknown |
| Domain `acmeanalytics.example` | unknown registrar | unknown | README.md, docs/runbook.md | unknown | unknown | Email, TLS, every customer-facing surface. | unknown |
| Marketing site hosting /security | unknown | unknown | human-confirmed: Sam, page is live and linked in the footer, 2026-08-26 | unknown | unknown | Public security claims. | unknown |

## Vendor and grant register

| Name | Platform or purchase route | Scopes or access | Data it can reach | Granted or bought by | Business owner | Date discovered | How discovered | Subprocessor? | Behind single sign on? | Still needed? | Decision | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Amazon Web Services | direct | production hosting | all customer data | unknown, likely Northwind Digital | unknown | 2026-08-26 | infra/main.tf | yes, listed on /security | unknown | yes | none | open |
| Stripe | direct | payments | payment data | unknown | unknown | 2026-08-26 | .env.example | yes, listed on /security | unknown | unknown | none | open |
| Google Cloud BigQuery | direct | nightly full copy of users, reports, events | all customer data | unknown | unknown | 2026-08-26 | scripts/export-analytics.sh | not listed on /security, open question | unknown | unknown | none | open |
| Retool | free tier | support tooling including an impersonate action | all customer data | unknown | unknown | 2026-08-26 | docs/runbook.md | not listed on /security, open question | unknown | unknown | none | open |
| 1Password | unknown | team vault holding a shared production bastion key | production database via the bastion | unknown | unknown | 2026-08-26 | docs/runbook.md | no, internal tool | unknown | yes | none | open |
| Northwind Digital | services contract | reported to hold AWS root | all customer data and infrastructure | pre-dates current engineering | unknown | 2026-08-26 | Sam relaying Dev Patel | likely, contract not read | n/a | unknown | none | open |
| GitHub | direct | source code, CI, production secret storage | source, CI secrets | unknown | unknown | 2026-08-26 | repo | unknown | unknown | yes | none | open |

## Grid state

Status is one of: unknown, none, partial, done, n/a.

### SE, Security Engineering

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| SE-1 | SDLC and security design reviews with engineers | unknown | no CODEOWNERS and no SECURITY.md in repo (`git ls-files`, 2026-08-26) | UNOWNED | 2026-08-26 | Software development lifecycle (SDLC). Branch protection and review requirements are not visible without GitHub organisation access (A-002). |
| SE-2 | Understanding your tech stack by engineering | partial | full read of the single service repository, 2026-08-26 | Sam Okafor | 2026-08-26 | One Express service mapped. Two material gaps: the ingress and network path in front of the app is described nowhere in code, and three source files the app imports have never been committed. See R-010. |
| SE-3 | Secrets, api keys, customer secrets | partial | `.env` present in commit 7a91e88 and deleted in 8d45d3a; docs/runbook.md | UNOWNED | 2026-08-26 | Coverage: a 1Password team vault is used for the shared bastion key only. Application secrets sit in individual local `.env` files and were committed to git history. No secret manager referenced anywhere in the repository. See R-002. |
| SE-4 | Bug bounty (hold off if you can) | unknown | no SECURITY.md in repo (`git ls-files`, 2026-08-26) | UNOWNED | 2026-08-26 | No external check for `/.well-known/security.txt` has been performed. Default recommendation remains not to start a bounty. |
| SE-5 | Consumer account security | n/a | README.md plus Sam confirmed B2B, 2026-08-26 | n/a | 2026-08-26 | Reason: no consumer accounts in the product. Revisit if a self-serve consumer signup ships. |

### DR, Detection and Response

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DR-0 | Compromise assessment | unknown | | Sam Okafor | 2026-08-26 | Blocked on A-001 and A-002. Every retention window in the clocks table above is unknown, so the size of the evidence window is itself unknown. This is the item with the hardest deadline in the programme. |
| DR-1 | Basic incident response plan | unknown | claimed: docs/security.md states a formal incident response plan exists and customers are notified within 24 hours, 2026-08-26, unverified | UNOWNED | 2026-08-26 | The 24 hour figure is a published commitment. See R-007. |
| DR-2 | Top security signals | none | Google Workspace, 2026-08-25: intermittent sign-ins from an unfamiliar country over approximately five months generated no alert to any human. | Sam Okafor | 2026-08-25 | The control that detected this was a person in finance being uneasy about an invoice. Workspace generates the relevant signal natively and nobody receives it. See R-022. |
| DR-3 | Consumption model for logging | unknown | reported-absent: docs/runbook.md states the support tool has no audit logs and bastion sessions are not recorded, 2026-08-26, unverified | UNOWNED | 2026-08-26 | See R-013. |
| DR-4 | Communication channel with the rest of the company | none | human-confirmed: on 2026-08-25 Maria in finance sat on a suspicion for most of an afternoon because there was no channel to raise it in and no stated rule that raising it was safe | Sam Okafor | 2026-08-25 | She reached the right outcome by choosing to ask the new hire personally. That is a person, not a control. See R-016. |

### CO, Compliance

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| CO-1 | Public facing security docs | partial | human-confirmed: Sam confirmed /security is live on the marketing site and linked in the footer (2026-08-26); docs/security.md | UNOWNED | 2026-08-26 | The page exists and makes six commitments. None are verified. The subprocessor list names AWS and Stripe only, while Google Cloud and Retool both appear to reach customer data. See R-007. |
| CO-2 | Knowledge base for questionnaires | unknown | | UNOWNED | 2026-08-26 | No questionnaire received yet. A security addendum is expected through the Meridian Health deal. |
| CO-3 | Understand existing commitments | partial | Sam, 2026-08-26 | Sam Okafor | 2026-08-26 | Known: six public commitments on /security, and a security addendum in the Meridian Health MSA draft. The addendum is requested (A-003) and not yet read. `COMMITMENT-REGISTER.md` to be created when it arrives. |
| CO-4 | Data inventory, privacy commitments, framework choice | unknown | | UNOWNED | 2026-08-26 | A production copy including a `users` table lands in BigQuery nightly. Data classes not yet established. No framework decision until the addendum is read. |

### CS, Corporate Security

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| CS-1 | Identity and Access Management | none | Google Workspace console, 2026-08-25: four super admin accounts, two unattributable to a named current person, one belonging to the agency. The finance operator's account had no second authentication factor and was accessed by an unauthorised party for approximately five months. | Sam Okafor | 2026-08-25 | Known so far: Dev Patel holds a normal AWS IAM user and has never rotated a key; account-level control is reported to sit with Northwind Digital; GitHub repository access includes accounts Sam does not recognise as staff and cannot enumerate. See R-011. |
| CS-2 | Endpoint security | none | human-confirmed: Sam Okafor received no company device and no enrolment at onboarding, reports no device management tool and no device inventory (2026-08-26). FileVault confirmed on his own machine only. | Sam Okafor | 2026-08-26 | Fleet-wide coverage is unverified because no list exists. Production database credentials are reported to sit in local `.env` files on machines the company does not own. See R-008 and R-014. |
| CS-3 | On-boarding and off-boarding | unknown | | UNOWNED | 2026-08-26 | |
| CS-4 | Workplace security | none | human-confirmed: on 2026-08-25 Maria in finance had to ask the security owner by hand whether a vendor bank-detail change was legitimate, which establishes that no written verification rule exists to follow | Sam Okafor | 2026-08-25 | Payment verification is the only sub-area with any evidence and it is absent. Physical office, guest wifi, network gear, shipping, disposal, travel and insider posture are all still unexamined. Fully remote with no office is likely, which would make most of the physical sub-areas `n/a`, but that is not yet confirmed. See R-015 and INC-2026-001. |

### Modern cells (M-1 to M-6)

| Cell | Title | Status | Evidence | Owner | Last verified | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M-1 | Software supply chain | none | no lockfile present and no `.npmrc` or registry configuration anywhere in the repo (`find` and `git grep`, 2026-08-26) | UNOWNED | 2026-08-26 | See R-009. |
| M-2 | CI/CD and build system security | partial | .github/workflows/ci.yml, before and after Dev Patel's change on 2026-08-26 | Dev Patel | 2026-08-26 | Continuous integration and continuous delivery (CI/CD). Two of three hardening changes are made. The third is under exception X-001. |
| M-3 | Cloud posture | unknown | infra/main.tf read, 2026-08-26 | UNOWNED | 2026-08-26 | Terraform describes only an S3 bucket and one IAM policy. It does not describe compute, network, ingress, or the database, so it is not a complete picture of the account. Blocked on A-001. See R-004 and R-005. |
| M-4 | SaaS sprawl and OAuth grants | unknown | | UNOWNED | 2026-08-26 | Software as a service (SaaS). Detail lives in the Vendor and grant register above. |
| M-5 | AI and LLM security | unknown | no model or AI dependency found in package.json or `src/`, 2026-08-26 | UNOWNED | 2026-08-26 | Artificial intelligence (AI) and large language model (LLM). Only the one service has been surveyed. |
| M-6 | Backups and recovery | unknown | | UNOWNED | 2026-08-26 | Three source files the production app imports have never been committed to version control, so at least part of the running service exists in only one place. See R-010. |

## Open questions

| # | Question | Ask who | Asked on | Answer |
| --- | --- | --- | --- | --- |
| Q1 | Does the code deployed in production match `src/routes/admin.js` on master, specifically the impersonate route having no authentication middleware? | Dev Patel | 2026-08-26 | pending |
| Q2 | Is `POST /admin/impersonate/:userId` reachable from the public internet, or is there a proxy, gateway or path allowlist in front of the service? | Dev Patel | 2026-08-26 | pending |
| Q3 | Where does the `analytics-helper-utils` dependency resolve from? | Dev Patel | 2026-08-26 | deferred by Dev to his return from holiday |
| Q4 | Who holds AWS root, and what is the contractual arrangement with Northwind Digital? | Priya | 2026-08-26 | pending |
| Q5 | Does a SOC 2 Type II report exist, and who holds a copy? | Priya | 2026-08-26 | pending |
| Q6 | What does the Meridian Health security addendum commit Acme to? | Priya, or Tom in sales | 2026-08-26 | pending |
| Q7 | Who are the non-staff accounts with GitHub repository access, and who granted them? | Priya | 2026-08-26 | pending |
| Q8 | Should the risk register and incident material be held under legal privilege, and if so how marked and addressed to whom? | whoever handles legal for Acme | 2026-08-25 | asked the same evening via Priya during INC-2026-001. Tracked as Q26. |
| Q9 | What is the total headcount, and how many are engineers? | Sam | not yet asked | pending |
| Q10 | What is the employee identity provider, and is single sign on in use? | Sam or Priya | not yet asked | pending |
| Q11 | Is full disk encryption enabled on the laptop holding this state directory? | Sam | 2026-08-26 | yes, FileVault confirmed on by Sam, 2026-08-26 |
| Q12 | What is the real default branch on GitHub? The CI workflow targets `main` and the only branch in the local clone is `master`, so the workflow may never have fired. | Dev Patel | not yet asked | pending |
| Q16 | Is the Northwind Digital message a new email, or a reply inside a genuine existing thread, and does its invoice number or amount match a real outstanding invoice? | Maria, finance | 2026-08-25 | ANSWERED 2026-08-25: it is a reply inside a genuine thread with prior messages quoted, and the invoice number follows on from the last one paid. A third party has read the real conversation. |
| Q19 | Which company's mailbox was read, Acme's or Northwind Digital's? | Maria's own mailbox settings, plus the preserved message headers | 2026-08-25 | ANSWERED 2026-08-25: Acme's. A filter the account holder did not create, plus login records from a foreign address dating to at least 2026-03-17. The sending domain was a hyphenated lookalike, so Northwind's own mail was not needed. |
| Q21 | Who is `admin@acmeanalytics.com`, what uses it, and when did it last sign in? | Priya, plus the Workspace login log | 2026-08-25 | PARTLY ANSWERED 2026-08-25: no login events, last sign-in recorded 2023, no second factor. Dormant. Still unknown what it is attached to, which is why it must not be deleted yet. See R-023. |
| Q22 | When did the `@northwinddigital.com` super admin account last sign in, and what is it for contractually? | Priya, plus the Workspace login log and the Northwind contract | 2026-08-25 | PARTLY ANSWERED 2026-08-25: sporadic use, most recent three weeks prior, from a connection consistent with normal UK business use, different address to the intruder. Assessed as legitimate agency use, not the intrusion. Contractual basis still unknown. See R-024. |
| Q23 | Does the intruder's IP address appear in the login events of any other Acme account? | Workspace login events log, one filter change | not yet run | pending, first thing 2026-08-26. This is the test for whether Maria is the only affected account. |
| Q24 | What was present in Maria's mailbox between 2026-03-17 and 2026-08-25? | scoping exercise, method to be written | 2026-08-25 | pending, deliberately not answered at night. See R-021. |
| Q25 | Did a credential phishing campaign occur at Acme in spring 2026, on what date, how many people received it, and how many entered credentials? | artifacts first, people second. See INC-2026-002 for the method and the source order. | 2026-08-25 | pending. Reported second-hand, unverified. Relationship to INC-2026-001 not established. |
| Q26 | Should this review be conducted under legal privilege, and if so how structured, who directs it, who receives findings, and how are documents labelled? | Acme's legal adviser, via Priya | 2026-08-25, asked the same evening | PARTLY ANSWERED 2026-08-26: the adviser wants to direct the work, wants documents labelled, and was firm that records must not be reachable by contractors or Northwind. Exact label wording, and which documents it applies to, still to be supplied. Do not invent a marking. |
| Q27 | What are the two connected applications removed from Maria's account on 2026-08-25, what scopes did they hold, and when were they granted? | Sam's notes, then the Workspace admin console | 2026-08-26 | PARTLY ANSWERED 2026-08-26: `Expensify`, recognised and expected, and `MailSync Pro`, never heard of by the account holder. Scopes and grant date still unknown, and they are the part that matters. See R-026. |
| Q29 | When was `MailSync Pro` authorised on Maria's account, by what route, and with what scopes? | Google Workspace OAuth token audit log, a different log from the sign-in log | 2026-08-26 | pending. If it predates 2026-03-17 the access window is wider than the sign-in log shows. |
| Q30 | Does `MailSync Pro`, or any comparable unrecognised application, hold a grant on any other account in the domain? | Google Workspace, third-party application access controls | 2026-08-26 | pending. Alongside the intruder IP search, one of the two fastest tests for whether Maria was the only one. |
| Q28 | Which of the security records should sit inside the legal adviser's scope, and which stay as ordinary operational records? | Acme's legal adviser, via Priya | 2026-08-26 | ANSWERED 2026-08-26 by Halloran Vance LLP: the two incident files in scope and labelled with their exact supplied wording; the risk register and the plan outside scope and unlabelled. Applied the same day. Original note retained: Security owner's view, offered as a question rather than a position: the two incident files inside, the risk register and plan outside, because they are used daily with engineers and over-broad scoping weakens the claim where it matters. |
| Q20 | Were the new bank details saved onto Northwind's vendor record in the accounting system or the banking portal, rather than only typed into one payment? | Maria, finance | 2026-08-25 | pending, urgent. If yes, every future payment to Northwind is affected, not only the one that was stopped. |
| Q17 | Does Acme hold cyber insurance, and what notice does the policy require after an attempted fraud? | Priya | not yet asked | pending |
| Q18 | Has any vendor bank detail ever been changed before without a callback? | Maria, finance | not yet asked | pending |
| Q14 | How many laptops exist, who holds them, and does any list exist anywhere, for example in the expense or corporate card records? | Priya, or whoever owns finance | not yet asked | pending |
| Q15 | What happens to a leaver's personal laptop and the production credentials on it? | Priya | not yet asked | pending |
| Q13 | Do the `PROD_*` secrets still exist in the repository's GitHub Actions secret store now that the workflow no longer references them? | Dev Patel | not yet asked | pending |

## Changelog

- 2026-08-25: INC-2026-002 opened as a retrospective review of a reported spring phishing campaign. Relationship to INC-2026-001 explicitly not established. DR-2 moved from unknown to none.
- 2026-08-25: INC-2026-001 scoped to approximately five months. CS-1 moved from unknown to none on enumerated evidence.
- 2026-08-25: INC-2026-001 raised to SEV2. DR-4 moved from unknown to none.
- 2026-08-25: INC-2026-001 declared. CS-4 moved from unknown to none on the payment verification sub-area.
- 2026-08-26: records moved to ~/acme-security/security-register. Privilege label applied to both incident files, verbatim as supplied. Q28 answered.
- 2026-08-26: mailbox containment completed overnight. Two unrecognised application grants removed, not yet identified, so containment is recorded as provisional.
- 2026-08-26: endpoint picture established. All machines are employee-owned and unmanaged, with no inventory. CS-2 moved from unknown to none. Q11 answered.
- 2026-08-26: file created. Populated from a read-only survey of the `acme-analytics` repository, one public npm registry lookup, and four conversations with Sam Okafor. No company system was accessed and nothing in the company repository was modified.
