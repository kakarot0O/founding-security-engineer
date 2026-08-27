# CS-1: Identity and Access Management

> **Grid coordinate:** CS-1, Corporate Security, cell 1.
> **Original 2019 wording:** "Identity and Access Management." Evan Johnson's note on this cell: "on the corp side it's a top top priority. Production takes years to fix and corp is something you can do in a few quarters."
> **Load when:** the human asks about single sign on, multi factor authentication, passkeys, "who has access to what", admin accounts, service accounts, access reviews, break glass accounts, session revocation, or a questionnaire asks about access control. Also load when an incident involves a stolen session, a phished employee, or an unexpected login.
>
> **Boundary against M-4.** This file owns the login side: the identity provider, how a human proves who they are, which humans hold administrator power, and how you cut a human's access. The third party application layer is split. The control that stops an employee granting an outside application access to company data is Step 5 below, because it is an identity provider setting. The register of which grants exist, what scopes they hold, who owns each one, and the runbook for revoking one is M-4 (software as a service sprawl and OAuth grants) in [07-modern-cells.md](./07-modern-cells.md). If the question is "should users be able to authorise applications at all", stay here. If the question is "what is currently authorised and which of it should go", go there.

## Why this cell exists

Every company account your colleagues log into is a door. If you cannot list the doors, you cannot lock them, and you cannot tell whether someone walked through one. Attackers in 2026 almost never break cryptography or exploit a zero day at a startup: they log in as a real person using a stolen password, a stolen session cookie, or a token an employee approved once and forgot about. Fixing identity is the single highest ratio of risk reduced per hour of work available to a first security hire, because the controls are configuration changes in systems you already pay for, not engineering projects that need another team's roadmap.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A written inventory of every system a human can log into, with the login method for each, stored in `SECURITY-STATE.md`.
- [ ] The company-ending accounts table from Step 1b is complete: registrar, domain name system provider, certificate authority, app store developer accounts, package registry namespace, payment processor, payroll, banking, and primary advertising and social accounts, each with a named owner of record, a known recovery path, and a phishing-resistant factor with a registered backup factor.
- [ ] One identity provider (Google Workspace, Microsoft Entra ID, Okta, or JumpCloud) is the single source of truth for employee identity. New accounts are created there and nowhere else.
- [ ] The top 10 highest risk applications authenticate through that identity provider using single sign on, not their own username and password.
- [ ] Phishing resistant multi factor authentication (passkeys or hardware security keys) is enforced for every administrator, and for all employees where the plan supports it.
- [ ] Zero shared accounts with a password in a spreadsheet or a chat message. Shared logins that genuinely cannot be avoided live in a password manager with a named owner.
- [ ] Administrator privileges are separated from daily accounts, or are granted through a time limited elevation, and admins are counted and named in `SECURITY-STATE.md`.
- [ ] Two break glass accounts exist, are excluded from single sign on and conditional access, use hardware keys, are stored offline, and their use raises an alert.
- [ ] Access is granted through groups tied to job function, not one at a time per person.
- [ ] Third party application access to the workspace and the code host requires administrator approval, and existing grants have been reviewed once.
- [ ] You can answer, in under 30 minutes and with evidence: who can read the customer database, and who can deploy to production. Step 11 of the walk produces this, as a path table plus a dated sentence in `SECURITY-STATE.md`.
- [ ] A quarterly access review runs and produces a dated artifact.

Explicitly **not** required at this size: an identity governance platform, automated certification campaigns, role based access control with dozens of custom roles, privileged access management with session recording, a zero trust network overlay, an identity threat detection product, or a separate administrative forest. If a vendor proposes any of those in your first quarter, say no.

## Discovery

The goal of discovery is a list, not a fix. Do not change anything in this phase. Every command below is read only unless marked.

**Step zero, no access at all.** If you have no administrator access anywhere yet, you can still produce most of the inventory:

1. Ask finance or the operations lead for the company card statements and the accounts payable list for the last 12 months. Every software as a service subscription is an identity boundary. This finds more shadow systems than any tool.
2. Ask for the list of applications shown on the employee launcher page (Google Workspace app grid, Microsoft 365 My Apps, Okta dashboard, JumpCloud user portal).
3. Read the onboarding checklist and the offboarding checklist if they exist. They are usually in Notion, Confluence, or a Google Doc, and they name the systems.
4. Search the company chat for the words "invite", "access", "can someone add me", "admin", and "password". Ask a colleague to run the search if you cannot.

**Identity provider, branched by vendor.**

*Google Workspace.* Console paths at admin.google.com: Directory > Users (count users, spot suspended and never signed in), Account > Admin roles (who is a Super Admin), Security > Authentication > 2 Step Verification (is it enforced, which methods are allowed), Security > Authentication > Password management, Security > Access and data control > API controls > Manage Third-Party App Access (OAuth application grants), Apps > Web and mobile apps (which applications use Google as their single sign on provider), Reporting > Audit and investigation > OAuth log events and Login log events. If the command line tool GAM is already installed and configured, `gam print users fields primaryemail,suspended,isadmin,lastlogintime` and `gam print admins` produce the same data faster. Do not install GAM just for discovery in week one.

*Microsoft Entra ID (formerly Azure Active Directory).* Portal paths at entra.microsoft.com: Identity > Users > All users, Identity > Roles and admins (look at Global Administrator first), Protection > Conditional Access > Policies, Protection > Authentication methods > Policies, Identity > Applications > Enterprise applications and then Consent and permissions, Identity > Applications > App registrations (look for credentials and secrets). Command line, read only: `az login` then `az ad user list --query "[].{u:userPrincipalName,e:accountEnabled}" -o table` and `az ad sp list --all --query "[].{n:displayName,a:appId}" -o table`. With Microsoft Graph PowerShell: `Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All"` then `Get-MgUser -All`, `Get-MgDirectoryRole -All`, `Get-MgIdentityConditionalAccessPolicy`.

*Okta.* Admin console: Directory > People, Directory > Groups, Applications > Applications, Security > Authenticators, Security > Authentication policies, Security > Administrators, Reports > System Log. Read only application programming interface calls with a read scoped token in the environment variable `OKTA_TOKEN`:
```
curl -s -H "Authorization: SSWS $OKTA_TOKEN" "https://<your-org>.okta.com/api/v1/users?limit=200"
curl -s -H "Authorization: SSWS $OKTA_TOKEN" "https://<your-org>.okta.com/api/v1/apps?limit=200"
curl -s -H "Authorization: SSWS $OKTA_TOKEN" "https://<your-org>.okta.com/api/v1/authenticators"
```

*JumpCloud.* Admin console: User Management > Users, User Groups, SSO Applications, Directory Integrations, Security Management > MFA settings, and Insights > Directory Insights for events. Read only application programming interface calls with the key in `JC_API_KEY`:
```
curl -s -H "x-api-key: $JC_API_KEY" "https://console.jumpcloud.com/api/systemusers?limit=100"
curl -s -H "x-api-key: $JC_API_KEY" "https://console.jumpcloud.com/api/v2/usergroups"
```

*No identity provider at all.* Some startups run on Google Workspace or Microsoft 365 purely as email, with every other tool using its own password. That is a normal finding. Record it as `none` for this cell and treat consolidation as the first project rather than a failure.

**Cloud accounts, branched by vendor.** These are where a compromised identity turns into a breach.

*Amazon Web Services.* `aws sts get-caller-identity`, `aws organizations list-accounts` from the management account, `aws iam list-users`, and for each user `aws iam list-access-keys --user-name NAME`. `aws iam get-account-authorization-details` dumps every user, group, role, and attached policy in one call, which is the fastest complete picture. `aws iam generate-credential-report` followed by `aws iam get-credential-report` gives password age, key age, and multi factor status per user. Any identity of the form `AKIA...` belonging to a human is an open finding.

*Google Cloud.* `gcloud organizations list`, `gcloud projects list`, `gcloud projects get-iam-policy PROJECT_ID --format=json`, `gcloud iam service-accounts list --project PROJECT_ID`, and `gcloud iam service-accounts keys list --iam-account SA_EMAIL` to find long lived downloaded keys.

*Microsoft Azure.* `az account list -o table`, `az role assignment list --all --include-inherited -o table`, and check Subscriptions > Access control in the portal for Owner assignments.

**Code host.** *GitHub:* `gh api /orgs/ORG` and read the `two_factor_requirement_enabled` field, `gh api "/orgs/ORG/members?role=admin"` for owners, `gh api /orgs/ORG/installations` for installed applications, and Settings > Third-party Access and Settings > Personal access tokens in the organization settings for grants and token policy. *GitLab:* `curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/GROUP_ID/members/all"` and read `require_two_factor_authentication` from `curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/GROUP_ID"`.

**Chat.** *Slack:* the workspace admin page at `https://<workspace>.slack.com/admin/settings` shows whether single sign on is required, and `https://<workspace>.slack.com/apps/manage` lists installed applications and whether members can install without approval. *Microsoft Teams:* app permission policies live in the Teams admin center under Teams apps > Permission policies, and the underlying identity controls are in Entra.

## Ask the human

Ask these as closed questions, one at a time, and record the answers in `SECURITY-STATE.md` under the CS-1 section:

1. Which system creates a new employee account on day one: Google Workspace, Microsoft 365, Okta, JumpCloud, or something else?
2. Do you have Super Admin, Global Administrator, or equivalent in that system today? Yes or no.
3. How many people are employees, and how many are contractors or agency staff with company logins?
4. Is multi factor authentication currently required for everyone, required for admins only, or optional?
5. Name the three systems where a leaked login would hurt most. My guess is the cloud provider, the code host, and the customer database. Correct me.
6. Has anyone ever been locked out of the workspace, and who fixed it?
7. Is there a shared login anyone still uses, for example a support inbox, a social media account, or a legacy database console?
8. Who is the person who will be angry if I change a login setting without telling them? I want to talk to them before I touch anything.

**Copy-pasteable access request the human can send.** Adjust the vendor name:

> Hi, I am setting up our security program and I need read only visibility into our identity systems this week. Can you grant me the following, and tell me if any of it needs someone else's approval?
>
> 1. A read only or auditor administrator role in our identity provider so I can see users, groups, admin roles, and login logs. I do not need the ability to change settings yet.
> 2. Read only access to the organization settings of our code host so I can see members, admins, and installed applications.
> 3. Read only or security auditor access to our cloud accounts.
> 4. Access to the last 12 months of software subscriptions from finance so I can build a complete list of systems people log into.
>
> I am not going to change any setting without telling you first and getting a yes. The goal this week is a written inventory so we can agree on what to fix.

**Copy-pasteable heads up before the first enforcement change:**

> On <date> at <time>, I am turning on <control> for <group>. Here is what you will see: <exact user experience>. It takes about <n> minutes per person. If you get stuck, contact me on <channel> and I can reverse it immediately. Two of us hold emergency accounts that are not affected, so nobody can be permanently locked out.

## The walk

Do these in order. Do not skip ahead, and stop at the end of each step for a go or no-go.

**Step 1: Build the door list.**
Goal: one table of every system a human can log into. Do: run the discovery commands and console paths above, plus the finance subscription list. Record each row as system, who owns it, login method (single sign on, own password, social login, shared), number of users, and whether it touches customer data. Verify: read the list back to one engineer and one operations person and ask what is missing. They will name two systems you missed, every time. Time: half a day to a day. Who else is needed: finance for the card statement, one engineer, one operations or people lead.

**Step 1b: Fill in the company-ending accounts table.**
This is a separate, fixed-row table that sits alongside the door list, and it is the part of Step 1 you must not skip. The general door list is built by asking what people log into, and that question systematically misses a specific class of account: the ones nobody logs into month to month, that were created once by a founder, and whose loss ends the company rather than merely embarrassing it. Losing the domain registrar account means losing the domain, which means losing email, which means losing the recovery path for every other account you own. Losing the package registry namespace means an attacker can publish a malicious version of your own package to your own customers. None of these show up in a crown jewels exercise framed around what engineers use, so ask for them by name.

Use exactly these rows, and write `unknown` rather than leaving a cell blank:

| Account | Owner of record | Recovery email or phone | Phishing-resistant factor enrolled, with a registered second factor |
| --- | --- | --- | --- |
| Domain registrar | | | |
| Domain name system (DNS) provider, if separate from the registrar | | | |
| Certificate authority or transport layer security (TLS) certificate account | | | |
| Apple App Store and Google Play developer accounts | | | |
| Package registry namespace (npm, PyPI, RubyGems, Maven, crates.io, Docker Hub) | | | |
| Payment processor (Stripe, Adyen, PayPal, or equivalent) | | | |
| Payroll and employer-of-record platform | | | |
| Business banking portal | | | |
| Primary advertising and social media accounts | | | |

Three data columns, three questions, and the answers are usually uncomfortable. "Owner of record" means the human whose name is on the account, not the team that uses it. "Recovery email or phone" is the single most important cell in the table, because it is frequently a founder's personal address, sometimes a former employee's address, and occasionally an address at a domain the company no longer controls. The third column asks two things at once: is a passkey or hardware security key enrolled, and is there a second one registered, because a single hardware key with no backup is a lockout waiting to happen.

Do: send one message to the founders and the finance lead asking who holds each of these, then log into the ones you are given access to and read the recovery settings yourself. Do not change any of them yet; several of these accounts have brittle recovery flows and changing a recovery address without the owner present can lock the company out of its own domain. Verify: every row has a named human and a recovery path, or an explicit `unknown` with the name of the person you are waiting on. Time: about an hour once the replies come back. Who else is needed: whoever signed up for each service, which at a startup under 100 people is usually one or two founders.

This table is an output of Gate A in [03-90-day-plan.md](./03-90-day-plan.md), meaning it is part of understanding the company rather than part of fixing it. In practice it produces the first genuinely critical finding more often than any other hour of work in this cell. Every row where the owner has left, the recovery address is outside company control, or no phishing-resistant factor is enrolled goes into `RISK-REGISTER.md` immediately with a severity that reflects what losing that account would actually do.

**Step 2: Count and name the administrators.**
Goal: know exactly who holds god access in the identity provider, the cloud accounts, and the code host. Do: pull the admin lists from each. Write the names down. Time: one hour. Verify: every name on the list is a current employee who needs it. Any leaver, contractor, or former vendor is an immediate entry in `RISK-REGISTER.md` at high severity. Who else is needed: nobody. This step usually finds the first real problem and it earns you credibility on day one.

**Step 3: Create break glass accounts before you enforce anything.**
Goal: make it impossible to lock the company out of its own identity system. Do: create two accounts in the identity provider that are not tied to a person, give them the highest administrator role, set a long random password from a password manager, enrol two hardware security keys per account, and exclude them from every conditional access policy and single sign on requirement you are about to create. Print the password and recovery codes, seal them in two envelopes, and store them in two different physical locations, for example a safe at the office and a safe at the chief executive's home.

*If there is no office,* which is the normal case for a hybrid or fully distributed company, the two locations are two different households belonging to two named executives, or one household plus a bank safe deposit box. Two envelopes in the same building is not two locations, and two envelopes in the same household is not two locations either. Record both custodians by name in `DECISION-LOG.md`, and re-seal with fresh credentials on any executive departure, because a sealed envelope in the home of someone who no longer works here is worse than no envelope at all: it looks like a control and is not one.

Verify: log into one of them once, in front of a witness, and confirm it works. Then set up an alert for any use of these accounts. Time: two hours. Who else is needed: one founder or executive to hold the second envelope and witness the test.
This step is mandatory and comes before Step 4. Skipping it is the most common way a first security hire ends their tenure early.

**Step 4: Turn on phishing resistant multi factor authentication for administrators only.**
Goal: protect the accounts that can undo everything else. Do: order hardware security keys for every administrator plus two spares, or use platform passkeys if every admin has a modern laptop and phone. Enrol admins in a scheduled session, not by email request. Then enforce.
*Google Workspace:* Security > Authentication > 2-Step Verification, apply to an organizational unit or a group containing admins, set the method to "Only security key" and set a short enrolment period. **This mutates state.**
*Microsoft Entra ID:* Protection > Authentication methods > Policies, enable FIDO2 security key and Passkey, then create a Conditional Access policy targeting the administrator role group requiring authentication strength "Phishing-resistant MFA". Create it in report only mode first and read the results for 48 hours. **Switching it to On mutates state.**
*Okta:* Security > Authenticators, add FIDO2 (WebAuthn), then Security > Authentication policies, create a rule for the admin group requiring a possession factor that is phishing resistant. Preview against the System Log first. **This mutates state.**
*JumpCloud:* Security Management > Conditional Policies and MFA, enrol WebAuthn factors and target the admin user group. **This mutates state.**
Verify: sign in as one admin from a clean browser session and confirm the key is demanded. Confirm the break glass account still works. Time: one day plus one to two weeks of shipping lead time for keys. Who else is needed: every administrator, for 15 minutes each.

**Step 5: Shut the third party application door.**
Goal: stop any employee from silently granting an outside application permanent read access to company data. This is the cheapest large win in the entire cell. Do:
*Google Workspace:* Security > Access and data control > API controls, set "Trust internal, domain-owned apps" appropriately and set unconfigured third party applications to Blocked, then allowlist the ones the business actually uses.
*Microsoft 365 and Entra:* Identity > Applications > Enterprise applications > Consent and permissions, set user consent to "Do not allow user consent" and turn on the admin consent request workflow so people can still ask.
*GitHub:* organization Settings > Third-party Access, enable OAuth application access restrictions, and set the fine grained personal access token policy to require approval.
*GitLab:* group Settings > Applications and the group level token settings.
*Slack:* Settings and permissions > Apps, require admin approval for app installation.
**All of these mutate state and can break a working integration, so each one needs an explicit yes from a named human before you flip it.** Before flipping each one, export the current grant list and post it in the company channel with a deadline: "these are the applications currently connected; tell me which ones you use by Friday or they get reviewed." Verify: attempt to install a test application as a normal user and confirm it now requires approval. Time: half a day. Who else is needed: a heads up in the company channel, plus whoever owns the sales and marketing tools.

**Read the exported grant list as a compromise check, not only as a hygiene list.** The first time anyone looks at this list, there is a real chance one of the entries is not a forgotten sales tool but an application an attacker authorised, typically with mail read or send scopes, sometimes years ago. If you find a grant that nobody will claim and that reads mail, files, or code, stop treating this as a configuration task and switch to [dr-0-compromise-assessment.md](./dr-0-compromise-assessment.md), which tells you how to establish whether it is live before you touch it. Do not revoke it as your first move: a silent revocation destroys your ability to prove scope and tells the attacker to go looking for their other footholds. Preserve in parallel, escalate, and let containment be an incident decision with a named owner.

**Step 6: Roll single sign on to the top applications, highest risk first.**
Goal: one account to disable when someone leaves, and one place where MFA is enforced. Do: rank the application list by blast radius, not by ease. The usual order is cloud provider console, code host, secrets manager, customer database or data warehouse admin, production observability, then chat, then everything else. Connect each to the identity provider, test with your own account, then a pilot group of three, then the whole company. Keep local password login enabled until the last application user has migrated, then disable it. Verify: for each application, disable your own local password and confirm you can still log in through the identity provider, then confirm a deprovisioned test account cannot. Time: half a day to two days per application depending on the vendor. Who else is needed: the owner of each application.

**Step 7: Replace individual grants with groups.**
Goal: make access a property of a job, not a favour. Do: create groups that map to real functions, for example `eng-all`, `eng-oncall`, `data-analysts`, `finance`, `support-tier1`. Assign applications and cloud roles to groups. Migrate existing per person grants into the matching group and remove the direct grant. Verify: pick one person, remove them from a group, and confirm their access to the associated application disappears. Time: two to three days. Who else is needed: engineering leadership to confirm the group definitions match reality.

**Step 8: Extend phishing resistant multi factor authentication to everyone.**
Goal: remove the ways an attacker relays a login. Do: repeat Step 4 targeting all users. Run an enrolment day: a two hour window with coffee where people register a passkey or a key while you watch. Announce it a week ahead. Allow a documented exception list with an expiry date recorded in `RISK-REGISTER.md`. Verify: pull the enrolment report from the identity provider and confirm the number of enrolled users equals the number of active users minus the documented exceptions. Time: one day plus two weeks of calendar. Who else is needed: an executive to send the announcement so it is not perceived as a security person's hobby.

**Step 9: Separate admin from daily, or add just in time elevation.**
Goal: an attacker who compromises a normal work session does not get administrative power. Do: either give administrators a second account used only for administration (simple, works everywhere, mildly annoying), or use built in time limited elevation where the platform supports it. Microsoft Entra ID has Privileged Identity Management on the P2 licence, which lets an eligible user activate a role for a few hours with a justification. Okta and JumpCloud have their own privileged and delegated administration features that vary by tier. Google Workspace does not have native just in time elevation, so use separate admin accounts there. Verify: confirm that the daily account of one administrator can no longer perform a specific administrative action. Time: one day. Who else is needed: the administrators.

**Step 10: Run the first access review, and make it small enough to repeat.**
Goal: an artifact you can hand to an auditor or a customer, produced by one person in half a day. Do: export the membership of the administrator groups, the production cloud roles, and the groups that can read customer data. Send each group's list to the single owning manager with one question: "reply with any name that should be removed by Friday." Remove them. Save the export, the request, the replies, and the removals as a dated folder. Verify: the folder exists and contains before and after evidence. Time: half a day per quarter. Who else is needed: one manager per group. Do not review every application. Reviewing three high value groups quarterly and actually finishing beats reviewing 40 applications annually and abandoning it.

**Step 11: Enumerate the paths to production customer data, and write the sentence you will be asked for.**
Goal: a defensible written answer to "who can read the customer database, and who can deploy to production", built from the paths people actually use rather than from a role list, because the role list is not where the access is. This is the definition of done item most often unmet at thirty people, and it is one of the first three things an enterprise buyer asks. **Everything in this step is read only.** Do not close a tunnel, revoke a grant, or remove a path while you are counting. The count is the deliverable, and changing the estate halfway through destroys it. Fixes come afterwards, as their own steps, with their own yes.

Do: work the seven paths below and fill in one row each. For every path answer exactly three questions, writing `unknown` rather than leaving a cell blank: **who can use it**, as a named list rather than "engineering"; **is the use logged**, meaning a record exists that names the human and the time, not merely that a connection happened; and **is the log retained**, for how many days, read out of the console rather than assumed. A path where the second answer is no is a finding on its own, because the buyer's next question is "how would you know", and the honest answer is that you would not.

| Path | Who can use it | Per-access record naming the human | Retention | Evidence |
| --- | --- | --- | --- | --- |
| Bastion, jump box, or tunnel | | | | |
| Database console or desktop client | | | | |
| Connection string held locally | | | | |
| Internal admin tool | | | | |
| Support impersonation | | | | |
| Warehouse or analytics copy | | | | |
| Restored backup or production data in a lower environment | | | | |

*Bastion, jump box, or tunnel.* The modern forms are AWS Systems Manager Session Manager, Google Cloud Identity-Aware Proxy port forwarding, Azure Bastion, and an overlay network such as Tailscale, Teleport, or a WireGuard or OpenVPN gateway. The older form is a long lived jump host with port 22 open to an office address that no longer exists. Read only: `aws ssm describe-sessions --state History` lists who connected and when, and the account's Session Manager preferences say whether those sessions were also written to CloudWatch Logs or S3, which is off unless somebody turned it on. On Google Cloud the role that grants the tunnel is `roles/iap.tunnelResourceAccessor`, so `gcloud projects get-iam-policy PROJECT_ID --format=json` gives you the list and the connections appear in Cloud Audit Logs. On Azure, Bastion emits diagnostic logs only once you have pointed them at a Log Analytics workspace. For a self-managed jump host the only record is `/var/log/auth.log` or `/var/log/secure` on the box itself, which sits inside the blast radius and rotates in a week or two by default.

*Database console or desktop client.* Two very different things wearing one name. The hosted consoles (the RDS query editor, Cloud SQL Studio, the Azure SQL query editor, the MongoDB Atlas data explorer, the Supabase, Neon, and PlanetScale editors) run in the vendor's control plane, so the vendor's own audit log usually knows who opened them. The desktop clients (TablePlus, DBeaver, DataGrip, pgAdmin, MySQL Workbench, Postico) run on an engineer's laptop against a saved connection and leave no company-side record at all beyond whatever the database itself writes. That is the part people get wrong: PostgreSQL's `log_statement` defaults to `none`, MySQL's general query log is off by default, and neither records a read until somebody enables statement auditing, which on managed PostgreSQL means the `pgaudit` extension. So the usual true answer for this path is that reads are not recorded anywhere. Count saved connections, not consoles: ask each engineer to open their client and read out how many production connections are in it.

*A connection string held locally.* A production connection string in a `.env` file, a shell profile, a note, or a shared password manager item is a standing credential that survives offboarding, survives single sign on, and appears in no access review. Read only: search the code host for the production hostname (`gh api -X GET search/code -f q='<db-host> org:<org>'` with a token that carries the code search scope, or the equivalent search in the GitLab interface), read the sharing list on the relevant password manager items, and pull the item usage report if the plan has one, which 1Password Business and Bitwarden Teams and above both provide. Then ask the question directly in the engineering channel, because the honest answer arrives faster than the search: "who has a production database connection string saved locally right now?" The number you get back is the real answer to the buyer's question, and it is normally larger than the identity provider's group membership.

*Internal admin tool.* Whether it is Django admin, a Rails console page, Retool, Forest Admin, or a page somebody built in an afternoon, ask four things: is it behind the identity provider rather than its own password, does it enforce the same groups as everything else, does it write a per-action record naming the acting human, and is that record somewhere the same people cannot edit. Django's admin writes a log entry for additions, changes, and deletions and writes nothing at all for reads, which means the tool that shows a support agent a customer's full record leaves no trace that anyone looked. Retool has audit logs on its paid tiers. A hand-built tool usually has none. Also check whether the tool can run arbitrary structured query language, because a page with a query box is a database console with a friendlier name and a wider audience.

*Support impersonation.* The "view as customer" or "log in as this user" feature. Ask who can trigger it, whether a reason is required, whether the customer is told, whether a record is written naming both the staff member and the customer, and how long that record is kept. The common defect is that the impersonated session is written to the ordinary session log as the customer, so every read the staff member performs is attributed to the customer and the audit trail actively misleads you. If that is what you find, write it down in exactly those words. An enterprise buyer understands it immediately, and it is the finding that appears in the news story when it goes wrong.

*Warehouse or analytics copy.* The copy is the path people forget, and it usually holds the same personal data behind a looser access list because it was built for a growth team in a hurry. Cover both the store (Snowflake, BigQuery, Redshift, Databricks) and the tool sitting on it (Looker, Metabase, Mode, Superset, Tableau), because the tool frequently connects with one shared service account, which makes the tool's user list the real access list rather than the warehouse's. Read only: in Snowflake, `SHOW GRANTS ON DATABASE <db>` plus the `SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS` view, and `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`, which retains a year. On BigQuery, dataset access lists come from `bq show --format=prettyjson <project>:<dataset>`, and data access audit logging is on by default for BigQuery, which makes it the one path on this list where the log usually already exists. Redshift audit logging to S3 is off unless somebody enabled it, and the system query tables hold only a few days.

*A restored backup, or production data in a lower environment.* Somebody restored production into staging to reproduce a bug, or dumped a table to a laptop, and it is still there. That data inherits the lower environment's access list, which is everyone, and its logging, which is nothing. Read only: ask the question in the engineering channel, compare row counts between production and staging for one identifying table, and search the shared drive and the code host for `.sql`, `.dump`, and `.bak` artifacts. The backup inventory itself belongs to [m-6-backups-and-recovery.md](./m-6-backups-and-recovery.md); what belongs here is only the copies a human can reach.

**The other half of the sentence: who can deploy to production.** Same three questions, four paths. Who can merge to the branch that deploys, who can run the deploy workflow by hand, who holds a cloud role that can change the running service directly, and who can bypass the pipeline entirely through the console, `kubectl`, or a shell on the host. Read only: branch protection and required reviewers from `gh api /repos/ORG/REPO/branches/main/protection`, the environment approvers on the deploy workflow, and the cloud role list you already pulled in Step 2. The fourth path is the one that matters, because it is the one nobody counts.

**Then write the sentence, because the table is not the deliverable.** Put this in `SECURITY-STATE.md`, dated:

> As of <date>, <N> named people can read production customer data, by <M> distinct paths: <path, count; path, count>. <K> of those paths write a per-access record naming the human, retained <n> days. The remaining paths do not, and are `RISK-REGISTER.md` rows <IDs>. Separately, <P> people can cause a change to reach production, of whom <p> can do it without a review.

That sentence is what the definition of done asks for and what questionnaire answer 8 in [co-2-questionnaire-knowledge-base.md](./co-2-questionnaire-knowledge-base.md) is built on. It is also the thing that turns "every engineer has the production URL" into something you can defend, and the turn is worth spelling out because the instinct is to hide the number. The URL is not the access; the credential is. If fourteen engineers hold a working production connection string and nothing records their reads, the defensible version is "fourteen of our engineers can query production directly, individual reads are not logged today, and statement auditing is scheduled for <date>". A buyer accepts a named gap with a date far more readily than a claim their next question disproves. What loses the deal is "access is granted on a least privilege basis", followed by a request for the evidence.

Verify: two proofs, both cheap. First, pick one path, have somebody with access use it while you watch, and then find that use in the log within ten minutes. If you cannot find it, the path is unlogged whatever the vendor documentation says. Second, pick one person who left in the last six months and establish whether any path above would still work for them, because a saved connection string appears on no offboarding checklist. That is why this check sits here rather than in [cs-3-onboarding-offboarding.md](./cs-3-onboarding-offboarding.md). Time: one day, two if there is a warehouse and a support tool. Who else is needed: one backend engineer for an hour, whoever owns the data warehouse, one support lead for the impersonation feature, and nobody's approval, because nothing here changes anything.

## Session revocation runbook

This cell owns this runbook. Four other files need the action and all of them should point here rather than repeating the console paths, because a path copied into five files drifts in five directions and only one copy ends up carrying the warning that matters.

**The warning, first, because it is the part people forget.** Revoking sessions signs the person out of everything, everywhere, immediately: laptop, phone, tablet, and every browser tab they had open. **This locks the person out until they sign in again, so tell them first** unless you are deliberately cutting off an account you believe an attacker controls. For a lost laptop, a suspected phish, or a leaver, say the sentence out loud to whoever is affected before you click: "you are about to be signed out of everything and you will need to sign back in." Ninety seconds of warning is the difference between a control that works and a control that people learn to route around.

**When you may run it.** Outside a declared incident, this is an access change and needs an explicit yes from a named human, normally the identity provider administrator plus the affected person's manager. Inside a **declared** incident, with an incident commander named under [dr-1-incident-response-plan.md](./dr-1-incident-response-plan.md), and only where the standing pre-authorisation in step 10 of [dr-4-company-comms-channel.md](./dr-4-company-comms-channel.md) was actually agreed in advance and recorded in `DECISION-LOG.md`, two actions may proceed on the commander's authority: revoking a named human user's active sessions and refresh tokens, and revoking a third party application's access grant. Both are reversible within minutes, because the person simply signs in again. If that pre-authorisation was never agreed, there is no exception and you ask. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.

**Per vendor.** Find yours today and write the exact path into `SECURITY-STATE.md`, so you are not learning a console at three in the morning.

| Platform | Path | Notes |
| --- | --- | --- |
| Google Workspace | Admin console, Directory, Users, select the user, Security, then "Sign out user from all web and device sessions". Also reset the sign-in cookies from the same panel. | Does not revoke third party OAuth grants. Revoke those separately. |
| Microsoft Entra ID | Entra admin center, Identity, Users, select the user, then "Revoke sessions". | Revocation invalidates refresh tokens. Existing access tokens can remain valid until they expire, typically up to an hour, unless continuous access evaluation is in effect for that application. Do not tell anyone the cut is instant. |
| Okta | Admin console, Directory, People, select the user, then "Clear user sessions" under More Actions. | Clearing sessions does not deactivate the account. If the account itself must be stopped, deactivate as well. |
| JumpCloud | Admin console, User Management, Users, select the user, then the option to force a logout or reset the user state. | Console wording varies by tenant version, so confirm the current label before you rely on it in an incident. |
| GitHub | The organization cannot revoke a member's personal sessions. Remove them from the organization, and separately revoke organization-owned tokens and any single sign on session under organization Settings, Authentication security. | This is a real gap. Removing from the organization is the effective control. |
| GitLab | Group Members to remove access. A self-managed administrator can also see and remove active sessions from the admin area user page. | On GitLab.com you cannot end another user's sessions; removal from the group is the control. |
| Slack | Admin, Manage members, select the member, then deactivate, or use the workspace-wide session settings to force reauthentication. | If Slack is behind single sign on, the identity provider revocation is the real control and Slack follows on next token refresh. |

**After revoking, do these two things or the revocation is cosmetic.** First, reset the account password to a random value, because a cached credential in a browser or on a phone will otherwise sign straight back in. Second, review third party OAuth grants on the account, because an application token issued to an outside application is a separate credential that survives both a password reset and a session revocation. The grant register and the revocation runbook for those live in M-4 in [07-modern-cells.md](./07-modern-cells.md).

**Test it once, on yourself, before you ever need it.** Revoke your own sessions, time how long it takes for your phone to notice, and write the observed number down. That number is what you will be asked for during an incident.

## Decision points

**Which identity provider.** DEFAULT: use what you already pay for. If the company runs Google Workspace, use Google Workspace as the identity provider. If it runs Microsoft 365, use Entra ID. Adding a separate identity vendor in the first quarter costs money and weeks and rarely changes the outcome. What changes this: you need automated provisioning and deprovisioning into 20 or more applications, you have a mixed Google and Microsoft estate, you have a hard customer or auditor requirement the built in tool cannot meet, or you need fine grained authentication policies per application. Then buy Okta or JumpCloud. JumpCloud tends to fit better when you also want device management bundled; Okta tends to fit better when the application catalogue and lifecycle management are the driver.

**Hardware security keys or platform passkeys.** DEFAULT: hardware keys for administrators and anyone with production access, platform passkeys (the fingerprint or face unlock built into laptops and phones) for everyone else. Hardware keys survive a lost or compromised laptop and work across devices; passkeys cost nothing and enrol in 30 seconds. What changes this: a fully remote team with shipping problems pushes you toward passkeys everywhere; a regulated customer requirement or a company that shares devices pushes you toward hardware keys everywhere.

**Enforce for admins first, or everyone at once.** DEFAULT: admins first, then everyone within four weeks. Admins are a small group you can support personally, and the failure mode is contained. What changes this: an active incident, in which case enforce for everyone immediately and accept the support load.

**Separate admin accounts or just in time elevation.** DEFAULT: separate admin accounts under 50 people, because they cost nothing and work in every platform. Move to just in time elevation when you already hold the licence tier that includes it, or when the number of administrators exceeds roughly 10 and the second account has become a tolerated annoyance people work around.

**How much least privilege to chase.** DEFAULT: cut the number of administrators and remove standing access to production and customer data. Do not attempt per resource fine grained permissions in your first quarter. The moment you become the bottleneck for routine access requests, engineers route around you and your credibility is gone. What changes this: a compliance framework with an explicit least privilege control that an auditor will test, and even then, scope it to the systems in the audit boundary.

**Contractors and agencies.** DEFAULT: they get accounts in your identity provider, in their own group, with an expiry date set at creation. Do not let a contractor use a personal account, and do not create a shared contractor login.

## Danger zone

Every action here requires you to stop, state the risk in plain language, and get an explicit yes from a named human. Announce a maintenance window and be online while it runs.

- **Enforcing multi factor authentication or a conditional access policy without break glass accounts excluded.** Failure mode: total company lockout with no recovery path except a vendor support ticket that can take days. Complete Step 3 first, without exception. Test the break glass account before you enforce, not after.
- **Enforcing single sign on on the identity provider itself, or on the code host, before every user has enrolled.** Failure mode: engineers cannot push code, deploys stop, and the security program is blamed for an outage on day four.
- **Deleting or suspending an account that turns out to own automation.** Founders and early engineers routinely own the cron job, the payment integration, the domain registrar, and the application store listing under a personal or personal-ish account. Before removing any account, search the codebase and the scheduler for its address. Suspend rather than delete, wait 30 days, then delete.
- **Revoking third party application grants in bulk.** Failure mode: the sales team's calendar tool, the customer support integration, or the deploy bot stops working and nobody connects it to your change. Export first, announce with a deadline, revoke in batches, watch the channel.
- **Rotating or disabling cloud access keys.** Failure mode: production outage. Keys are frequently embedded in running services. See [se-3-secrets-and-keys.md](./se-3-secrets-and-keys.md) for the deactivate, observe, then delete sequence. Never delete a key as the first action.
- **Changing password or session lifetime policies.** Failure mode: everyone is signed out at once, help requests flood in, and mobile applications reauthenticate in a way that looks like an outage.
- **Buying an identity platform in month one.** Failure mode: a multi year contract of tens of thousands of dollars signed before you know the requirements, and a migration you have to run while you are still learning the company.

**The exact order of operations that avoids locking out the founders:**

1. Create and test two break glass accounts with hardware keys, stored offline in two places.
2. Explicitly exclude those accounts from the policy you are about to create.
3. Build the policy in report only or preview mode. Let it run 48 hours. Read the results and find the people it would have blocked.
4. Enrol the affected users and confirm enrolment in the vendor report before enforcing.
5. Enforce for a pilot group of three volunteers, including yourself.
6. Enforce for administrators.
7. Enforce for everyone, with an announcement, during business hours, on a Tuesday or Wednesday. Never Friday.
8. Keep a documented, time limited exception group and empty it within two weeks.
9. Record the whole sequence and the approving human in `DECISION-LOG.md`.

## Do not do this yet

- Do not deploy an identity governance or access certification platform. A spreadsheet and a quarterly email do the same job at this size.
- Do not build custom role based access control for internal tools before the identity provider consolidation is finished.
- Do not attempt to remove all standing production access in month one. Get the inventory and the multi factor authentication first; standing access is a month four project that needs engineering buy in.
- Do not write an access control policy document before the controls exist. Writing the policy first creates a document that describes a fiction, which is worse than having no document when an auditor arrives.
- Do not chase every dormant account in every minor tool. Fix the systems that touch customer data, money, code, and infrastructure.
- Do not buy an identity threat detection or software as a service security posture product. The workspace audit log and the corporate card statement cover the realistic threats at this stage.
- Do not become the approval queue for routine access requests. Push approval to the manager who owns the group.

## Evidence to capture

Write into `SECURITY-STATE.md`, under a heading `## CS-1 Identity and Access Management`:
- The door list from Step 1, as a table.
- The company-ending accounts table from Step 1b, with every cell filled or explicitly marked `unknown` and the name of the person you are waiting on.
- The identity provider name and whether it is the authoritative source.
- The session revocation console path for your identity provider, and the observed time it took when you tested it on yourself.
- The production data access path table from Step 11, and the dated sentence underneath it naming how many people can read production customer data, by how many paths, how many of those paths are logged, and how many people can deploy.
- Administrator counts per system, with names.
- Multi factor authentication state per population: enforced, method, percentage enrolled, exception count.
- Single sign on coverage as a fraction, for example "9 of 34 applications, including all 5 crown jewel systems."
- A cell status of `unknown`, `none`, `partial`, or `done`, with the date and the verification command or screenshot that proves it.

Write into `RISK-REGISTER.md`: every administrator who should not be one, every shared account, every long lived cloud access key belonging to a human, every third party grant nobody claims, and every multi factor exception with an expiry date. Each row needs an owner, a severity, a decision, and the name of the person who accepted the risk if it is accepted.

Write into `DECISION-LOG.md`: the identity provider choice and why, the authentication method choice and why, the enforcement dates, and who approved each enforcement.

Write into `ACCESS-LOG.md`: every administrative or read only access grant you requested, who granted or denied it, and the date. This doubles as evidence that you did not silently take privileges.

Write into `90-DAY-PLAN.md`: the steps from this cell that you have actually scheduled, each as a step with an owner and a date. This file does not assign day ranges. [03-90-day-plan.md](./03-90-day-plan.md) owns the gates and the calendar, and it is the only place that decides when something happens. Schedule a step there because a fact about this company demands it, for example because the administrator count you found in Step 2 includes two leavers, not because it is the next step in this file's numbering.

Artifacts a future auditor or enterprise customer will ask for, so save them as dated files: the user list export, the administrator list export, the multi factor enrolment report, the access review request and responses, the offboarding evidence for one named leaver, and a screenshot of the enforced authentication policy.

## Cost and effort

- Discovery and the door list: 1 to 2 days. Free.
- Break glass setup: 2 hours plus roughly 100 to 120 dollars for four hardware keys.
- Hardware security keys: budget two per person who needs them. Entry level models are roughly 25 to 35 dollars each; the fuller featured models are roughly 50 to 75 dollars. For 40 admins and engineers with two keys each, expect 2,000 to 4,000 dollars one time. Passkeys are free.
- Third party application restrictions: half a day. Free, already included in every plan.
- Single sign on rollout: 0.5 to 2 days per application. Free if the identity provider is already Google Workspace or Microsoft 365 at a plan that supports it. Some software as a service vendors charge extra for single sign on; that surcharge is often the largest hidden cost in this cell, so price it before you promise a date.
- Upgrading the existing suite is usually the cheapest path to better controls. Google Workspace tiers run roughly from the mid teens to the mid twenties of dollars per user per month; Microsoft Entra ID P1 is roughly 6 dollars per user per month and P2 roughly 9, which is what unlocks conditional access and just in time role elevation. Confirm current list prices before quoting them to a founder.
- A dedicated identity platform: Okta and JumpCloud land roughly in the 3 to 15 dollars per user per month range depending on the modules. For 60 people that is 2,000 to 11,000 dollars a year. Get a quote, do not guess.
- Total realistic first quarter identity spend at a 50 person startup: 0 to 5,000 dollars if you use what you already own, plus keys.

## 2026 notes

The 2019 slide put Corporate Security fourth and treated identity as back office hygiene. That ordering is now wrong. The dominant breach path against a startup is: information stealing malware or a phishing page on an employee laptop, then a stolen session cookie or password, then software as a service access, then cloud. Identity is the perimeter, and this cell belongs in the first 30 days rather than the last quarter.

Three specific things changed since the slide:

1. **Text message codes and push approvals are no longer sufficient.** Adversary in the middle phishing kits proxy the real login page in real time, so the victim enters a valid code into the attacker's page and the attacker captures the resulting session cookie. Push fatigue attacks simply spam approval prompts until someone taps yes. Both defeat the multi factor that was considered adequate in 2019. Only phishing resistant factors bound to the site origin, which means passkeys and FIDO2 or WebAuthn hardware keys, actually stop this. Number matching on push notifications is a meaningful improvement and a reasonable interim step, but it is not the destination.
2. **Session and token theft is the follow on problem.** A stolen refresh token or session cookie survives a password reset and often survives a multi factor reset. Your response plan therefore needs an explicit session revocation step per platform, tested once so you are not learning the console path during an incident. The per-vendor paths, the lockout warning, and the test are in the Session revocation runbook section above, which is the single copy the rest of this skill points at.
3. **Third party application grants became a mass breach vector, not a hygiene item.** In August 2025, attackers used stolen OAuth refresh tokens belonging to a single widely installed third party integration to query data across more than 700 organizations, then searched the extracted records for cloud and data warehouse credentials. None of those companies were hacked in the traditional sense. Their only decision was that someone, sometimes years earlier, clicked Authorize. That is why Step 5 is placed before the single sign on rollout in this walk, despite being smaller work. See [07-modern-cells.md](./07-modern-cells.md) for the wider software as a service and OAuth sprawl treatment.

Also new since 2019: continuous access evaluation and device trust signals are now available in the mainstream suites, machine identity has multiplied because continuous integration systems and agents now authenticate constantly, and artificial intelligence assistants installed by employees are a fresh category of grant that reads mail, files, and code with the employee's own permissions. Treat an artificial intelligence assistant's OAuth grant with exactly the same seriousness as a human account, because functionally it is one.

## Failure modes

| What goes wrong | Early tell | Recovery |
| --- | --- | --- |
| You lock out the company | Support requests spike within minutes of enforcement | Use a break glass account, disable the policy, communicate immediately, then redo it in report only mode. If you have no break glass account, this becomes a vendor support ticket and a very bad day. |
| Enforcement announced by you, not by leadership | People argue about the change rather than doing it | Get an executive to resend the announcement in their own words. Never re-announce it yourself. |
| Users pile up in the exception group | The exception group grows and no entry has an expiry | Put every exception in `RISK-REGISTER.md` with a named accepter and a hard date. Report the count in your monthly update so it becomes visible. |
| Single sign on rolled to easy applications first | Three months in, the code host and cloud console still use local passwords | Reorder by blast radius. Report coverage as "crown jewel systems covered", not "applications covered", so easy wins stop looking like progress. |
| You become the access ticket queue | Your calendar fills with access requests and no project moves | Move approval to group owners, document the request path, and stop being in the loop for routine grants. |
| Offboarding still misses systems | A leaver's account is found active weeks later | This is a CS-3 problem, not a CS-1 problem. Fix it in [cs-3-onboarding-offboarding.md](./cs-3-onboarding-offboarding.md) by driving deprovisioning from the identity provider. |
| Break glass credentials are lost or stale | Nobody has tested them in a year, or the person holding the envelope left | Test annually, and re-seal on any executive departure. Put the test date in `DECISION-LOG.md`. |
| A shared account survives because "it is only for X" | Someone posts the password in chat again | Move it into the password manager with a named owner and an expiry, and open a `RISK-REGISTER.md` row for replacing it with a proper account. |

## Related cells

- [cs-3-onboarding-offboarding.md](./cs-3-onboarding-offboarding.md) is the operational half of this cell. Identity without a joiner and leaver process decays within a quarter.
- [cs-2-endpoint-security.md](./cs-2-endpoint-security.md) covers the laptop, which is where session cookies and passkeys actually live.
- [cs-4-workplace-security.md](./cs-4-workplace-security.md) covers physical and office access, including the identity provider's role in it.
- [se-3-secrets-and-keys.md](./se-3-secrets-and-keys.md) covers machine credentials, cloud access keys, and continuous integration identity.
- [dr-2-top-security-signals.md](./dr-2-top-security-signals.md) tells you which identity events to alert on, including impossible travel, new device enrolment, admin role grants, and break glass account use.
- [dr-1-incident-response-plan.md](./dr-1-incident-response-plan.md) needs the session revocation runbook this cell owns, and is where a finding here becomes a declared incident.
- [dr-0-compromise-assessment.md](./dr-0-compromise-assessment.md) is where you go the moment a grant, an administrator account, or a multi factor change in this cell's discovery looks like someone else's work rather than your colleagues' untidiness. The first pass over third party grants and administrator lists is a compromise check as much as a hygiene check.
- [co-4-data-inventory-and-framework.md](./co-4-data-inventory-and-framework.md) tells you which systems hold customer data, which is what makes an access review meaningful rather than performative.
- [07-modern-cells.md](./07-modern-cells.md) covers software as a service sprawl, OAuth grant risk, and cloud posture in depth.
- [06-2019-to-2026-delta.md](./06-2019-to-2026-delta.md) explains why this cell moved from fourth priority to first.
- [03-90-day-plan.md](./03-90-day-plan.md) places these steps on the calendar.
- [02-intake-questions.md](./02-intake-questions.md) has the broader question bank and more access request templates.
