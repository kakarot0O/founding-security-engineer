# CS-3: On-boarding and off-boarding

> **Grid coordinate:** CS-3, Corporate Security domain.
> **Original 2019 wording (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019, slide 18):** "On-boarding & Off-boarding". Speaker notes: "It's where so much security is baked in to... tightly coupled with Identity and Access Management."
> **Load when:** the human asks about joiners, movers, leavers, "what happens when someone quits", offboarding checklists, a termination is scheduled, an auditor or customer asked for evidence of access revocation, a contractor engagement is ending, an agency rotates staff on or off the account, an employer of record processes a termination, or a questionnaire asks about the employee lifecycle. Also load this file whenever CS-1 (Identity and Access Management) discovery turns up accounts belonging to people who no longer work at the company.

## Why this cell exists

Every account at your company was created by somebody, for somebody, for a reason. If nobody writes down who gets what and why, access only ever grows: people join and get a copy of somebody else's permissions, people change teams and keep both sets, people leave and nothing gets taken away. Within two years the average employee has access to a dozen systems they have not opened in a year, and at least one former employee still has a live login somewhere.

That matters for two independent reasons. First, real attacks: a laid-off contractor's still-active code host account, or a departed engineer's personal API token that was never revoked, is a cheap way in with no malware and no exploit. Second, real audits: "terminated users are removed within one business day" is a control in every framework, and it is the single most common place a first audit fails, because the auditor asks for the last ten leavers and one of them still shows as active in a screenshot dated after their last day.

The good news is that this is the cheapest cell in the whole grid to make real progress on. It is two checklists, one owner, and a habit. It needs no budget and no engineering time.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A written joiner checklist exists, lives somewhere the whole company can find it, and names an owner for every line.
- [ ] A written leaver checklist exists with a hard ordering and a stated time target (recommended: identity provider account suspended within 1 hour of the last working moment, everything else within 1 business day).
- [ ] A written mover (internal transfer) checklist exists, even if it is five lines. It must include removing the old team's access, not only adding the new team's.
- [ ] Access is granted by role or group, never by cloning a specific person's account.
- [ ] A single, current list of every system a human can log into, with a named owner per system, and a flag for whether it is behind single sign-on.
- [ ] The last ten leavers have been checked by hand and any live access has been revoked.
- [ ] An involuntary termination runbook exists, has been read by the person who will run it (usually the manager plus one of the founders or the head of people), and states who does what in which minute.
- [ ] Contractors and vendors are covered by the same checklists, with an end date recorded at the moment access is granted.
- [ ] Every non-employee with access is sorted into one of the four cases in Contractors, agencies, and employer-of-record populations, and any employer-of-record population has a named notification path and a monthly reconciliation until a contractual notification term exists.
- [ ] Each completed joiner or leaver produces a dated, saved record with a timestamp and who did it.

Explicitly **not** required at this stage:

- Not required: an identity governance and administration (IGA) product such as SailPoint, Saviynt, or Veza. These are six-figure enterprise tools.
- Not required: automated provisioning through SCIM (System for Cross-domain Identity Management) for every application. Two or three critical apps is plenty. The rest can be manual.
- Not required: quarterly formal access reviews with attestation workflows. One annual pass, done by hand in a spreadsheet, satisfies an early SOC 2 and a Series B customer.
- Not required: a human resources information system (HRIS) integration. If your company runs on a spreadsheet plus a payroll tool, the checklists can be triggered by a human.
- Not required: role based access control modelled down to the individual permission. Three to six coarse roles ("engineer", "sales", "support", "finance", "contractor", "admin") is correct at this size.

## Discovery

The goal of discovery here is not to read a policy. It is to reconstruct what actually happened for the last ten joiners and the last ten leavers, then compare that to what people believe happens. The gap between those two is your finding.

**Step zero, no access at all.** If you have no administrative access to anything yet, you can still do most of this cell. Ask for two lists in plain text: everyone who joined in the last twelve months with their start date, and everyone who left in the last twelve months with their last day. People operations or the office manager has both. Then ask for read-only administrator access to the identity provider. Until you get it, work from the human answers and mark every state file entry as `unknown` with the note "reported, not verified".

**Get the leaver and joiner lists.** Source, in order of preference: the payroll or human resources system (Rippling, Gusto, Justworks, BambooHR, Deel, Workday), then the identity provider's suspended users list, then the founders' memory. Write both lists into `SECURITY-STATE.md` under `## CS-3 On-boarding and off-boarding` before you check anything, so you have a denominator.

**Identity provider, branched by vendor. All commands below are read-only.**

If the org uses Google Workspace:
```bash
# Requires the GAM or GAMADV-XTD3 command line tool with admin authorization.
gam print users fields primaryemail,suspended,lastlogintime,creationtime,ou
gam print users query "isSuspended=true" fields primaryemail,suspended
gam print groups members
```
Console path if you have no tooling: admin.google.com, then Directory, then Users. Add the "Last sign in" column via the column picker. Filter by "User status: Suspended". Also check Apps, then Google Workspace, then Gmail, then "User settings" for delegation, and each departed user's Settings for forwarding.

If the org uses Microsoft 365 or Entra ID (formerly Azure Active Directory):
```powershell
# Microsoft Graph PowerShell SDK, read-only scopes.
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All","Directory.Read.All"
Get-MgUser -All -Property DisplayName,UserPrincipalName,AccountEnabled,SignInActivity |
  Select-Object DisplayName,UserPrincipalName,AccountEnabled,@{n='LastSignIn';e={$_.SignInActivity.LastSignInDateTime}}
```
Console path: entra.microsoft.com, then Users, then All users, and add the "Account enabled" column. For mailbox leftovers, use the Exchange admin center, then Recipients, then Mailboxes, then a given mailbox, then Delegation, and Mail flow settings for forwarding.

If the org uses Okta, JumpCloud, OneLogin, or another dedicated identity provider: the admin console has a Reports or People section that exports users with status and last login. In Okta specifically, Reports then "Okta Password Health" and the System Log filtered on `eventType eq "user.lifecycle.deactivate"` gives you deactivation timestamps, which is exactly the audit evidence you will need later.

If the answer is "we do not really have an identity provider, everyone just has a Google login and separate passwords for everything": that is a finding, not a blocker. Record it, and read `cs-1-identity-and-access.md`, because CS-3 cannot be made reliable until there is one directory of record.

**Code host.**

If the org uses GitHub:
```bash
gh api orgs/YOUR_ORG/members --paginate -q '.[].login'
gh api orgs/YOUR_ORG/outside_collaborators --paginate -q '.[].login'
gh api orgs/YOUR_ORG/members --paginate -q '.[].login' | while read -r u; do
  echo "$u $(gh api "orgs/YOUR_ORG/memberships/$u" -q '.role')"
done
```
Console path for the parts the application programming interface will not tell you cleanly: github.com/orgs/YOUR_ORG/people to see who has not enabled two factor authentication, and Settings, then "Personal access tokens" is per-user only, so you cannot enumerate other people's tokens. Deploy keys are visible per repository under Settings, then "Deploy keys". Machine accounts show up as members with human-looking names; flag anything whose email is a shared alias.

If the org uses GitLab:
```bash
glab api "groups/YOUR_GROUP/members/all?per_page=100"
glab api "groups/YOUR_GROUP/billable_members?per_page=100"
```
Console path: your group, then Manage, then Members, and check "Last activity". Also Settings, then Access Tokens at the group and project level.

**Cloud, only to find human accounts that outlive humans.**

AWS:
```bash
aws iam list-users --query 'Users[].{User:UserName,Created:CreateDate,PasswordLastUsed:PasswordLastUsed}' --output table
aws iam generate-credential-report >/dev/null && aws iam get-credential-report --query Content --output text | base64 -d
aws sso-admin list-instances   # if IAM Identity Center is in use
```
The credential report is the single best artifact here: it lists every IAM user, whether they have a password, whether they have access keys, and when each was last used. If any row belongs to a person, that is a CS-3 problem as well as a CS-1 problem.

GCP:
```bash
gcloud projects get-iam-policy YOUR_PROJECT --format=json | \
  python3 -c 'import json,sys; [print(b["role"], m) for b in json.load(sys.stdin)["bindings"] for m in b["members"] if m.startswith("user:")]'
gcloud organizations get-iam-policy YOUR_ORG_ID --format=json
```

Azure:
```bash
az role assignment list --all --query "[?principalType=='User'].{user:principalName,role:roleDefinitionName,scope:scope}" -o table
```

**Everything else.** Read the corporate card or accounts payable export for the last twelve months and list every software as a service vendor. This is the fastest shadow information technology discovery available and it costs nothing. Ask finance for a comma separated export and grep it. Every vendor on that list is a system somebody can log into, and if it is not on your leaver checklist, nobody is removing access from it.

**Reconstruct the truth.** For each of the last ten leavers, check by hand: identity provider status, code host membership, cloud presence, and their presence in the three or four largest software as a service tools. Record per person: last day, date access actually stopped, and gap in days. That table is the finding. Write it into `SECURITY-STATE.md` and any live access into `RISK-REGISTER.md`.

## Ask the human

Ask these as closed questions, one at a time, and record the answers in `SECURITY-STATE.md`:

1. Who owns offboarding today, by name? (If the answer is "it depends" or "whoever notices", that is the finding.)
2. Is there a written checklist anywhere, even a stale one in a document or ticketing template? Yes or no.
3. How many people have left in the last twelve months? Rough number is fine.
4. Has anyone ever been fired or laid off, as opposed to resigning? Yes or no. (This determines whether the involuntary path has ever been exercised.)
5. Do contractors get company identity provider accounts, or do they use their own email addresses? One or the other.
6. Is there a shared password manager with a shared vault, and if so who is the vault administrator?
7. When someone leaves, does their mailbox get deleted, suspended, or transferred to their manager?
8. Does anyone besides you have administrator rights in the identity provider today? Names.

**Copy-pasteable message to people operations or the founder who handles hiring:**

> Hi, I am putting together the joiner and leaver process so we stop leaving accounts active after people go, which is both a real security gap and the thing auditors and enterprise customers check first. Two asks. (1) Could you send me a list of everyone who joined in the last 12 months with their start date, and everyone who left with their last working day? A spreadsheet or a paste is fine. (2) Could you add me to whatever notification exists today when someone resigns or a termination is planned, so I hear about it at the same time you do rather than after? I am not looking to add steps to your process. I want to write down the process that already exists and take the account cleanup off your plate.

**Copy-pasteable message to the person who administers the identity provider:**

> Hi, could I get read-only super admin (or the equivalent auditor role) on our identity provider? I want to reconcile active accounts against our current headcount and find any accounts belonging to people who have left. Read-only is enough for now. I will not change any settings without asking you first, and I will send you the findings before I do anything about them. If read-only is not a role we have, tell me and I will do this over a screen share with you driving instead.

**Copy-pasteable message to a departing employee's manager (send at notice, before the last day):**

> Hi, [Name] is leaving on [date]. Before their last day, could you confirm four things for me? (1) Which shared or team accounts did they hold the password for? (2) Do they own any automated jobs, scripts, integrations, or alerts that run under their personal account and will break when it is disabled? (3) Who should inherit their files and calendar? (4) Do they have any company hardware, keys, or badges that need to come back, and what is the return plan? I will handle the account side. I need these four answers so we do not break something on the way out.

## The walk

**Step 1: Reconstruct the last ten leavers.**
- Goal: produce a real, evidence-backed answer to "does access actually get removed here?" on day one, which is more persuasive than any policy you could write.
- Do: get the leaver list, then for each person check the identity provider, the code host, the cloud, and the top three software as a service tools by hand. Build a table with last day, date access stopped, and gap.
- Verify: the table has ten rows, or as many as the company has had leavers, with a real date or an explicit "still active" in every cell.
- Time: 2 to 4 hours.
- Who else is needed: whoever holds the leaver list, plus read access to the identity provider.

**Step 2: Revoke what you found, with approval.**
- Goal: close the actual open doors before writing any process.
- Do: list every still-live account for a departed person. Take that list to the identity provider owner and the relevant system owner. Get an explicit yes per account, then suspend (do not delete) each one. Suspend preserves data and is reversible; deletion is not.
- Verify: re-run the discovery commands and confirm each account now reads suspended or removed. Screenshot or save the command output.
- Time: 1 to 2 hours after approval.
- Who else is needed: the identity provider administrator, and for any account that might be running an automated job, the engineering owner.
- This step mutates state. See Danger zone.

**Step 3: Write the leaver checklist and get one person to own it.**
- Goal: make the next departure boring.
- Do: use the checklist below, cut anything that does not apply, add anything specific to your stack, and put it where the process already lives (the ticketing tool template, the people operations document, the onboarding wiki). Then get one named human to own running it. Ownership by a role with no name attached means nobody.
- Verify: the owner can find the checklist without your help and says out loud that they will run it next time.
- Time: 2 to 3 hours.
- Who else is needed: people operations or a founder, for the ownership decision.

**Step 4: Write the joiner checklist and switch to role-based grants.**
- Goal: stop privilege creep at the source.
- Do: define three to six roles. For each, list exactly which systems and which access level. Write the joiner checklist against roles, not against people. Ban the phrase "give them the same access as [name]" explicitly in the document and say why.
- Verify: the next new hire is provisioned from the role list and nobody has to ask "what does an engineer get?"
- Time: 3 to 5 hours, mostly spent asking managers what their team actually needs.
- Who else is needed: one manager per function to confirm the role definitions are usable.

**Step 5: Write the mover checklist.**
- Goal: catch the transfer case, which nobody has a process for and which produces the most over-privileged accounts in the company.
- Do: a five-line checklist. Compare old role to new role. Grant the new. Remove the old. Remove group memberships from the old team. Confirm with the old manager that nothing is still owned by this person. Record the date.
- Verify: run it retroactively against everyone who has changed teams in the last year. You will find leftovers. Fix them.
- Time: 1 hour to write, 2 to 3 hours to run retroactively.
- Who else is needed: the old and new managers.

**Step 6: Write the involuntary termination runbook and rehearse it once.**
- Goal: make sure that when the hard day comes, revocation happens during the conversation and not two hours later.
- Do: use the runbook below. Walk through it verbally with the founder or head of people who will be in the room. Agree the exact signal (a message in a private channel, a phone call) that means "start now".
- Verify: the other person can state the signal and their own first action without reading the document.
- Time: 2 hours including the rehearsal conversation.
- Who else is needed: whoever runs terminations, and legal or an employment advisor if one exists.

**Step 7: Add contractors and third parties.**
- Goal: cover the population with the highest turnover and the least process.
- Do: build a list of every non-employee with access. For each, record the sponsoring employee, the engagement end date, and the systems. Put every end date in a shared calendar with a reminder one week before. Then sort the list into the four cases in the Contractors, agencies, and employer-of-record populations section below, because an individual contractor, an agency's rotating staff, an agency that owns your environment, and an employer-of-record worker each fail in a different way and only the first is covered by the standard checklist.
- Verify: every non-employee account maps to a named sponsor, a date, and one of the four cases.
- Time: 2 to 4 hours.
- Who else is needed: whoever signs contractor agreements, plus whoever owns the employer-of-record relationship if one exists.

**Step 8: Start the evidence habit.**
- Goal: make the audit a non-event twelve months from now.
- Do: for every joiner and leaver from today onward, save one dated record: who, what date, which systems, who ran it, and a link or screenshot proving the identity provider account state changed. A folder of dated files, or a closed ticket per person, is sufficient. It does not need to be pretty.
- Verify: pick a person offboarded last month and produce their record in under two minutes.
- Time: 15 minutes per departure, ongoing.
- Who else is needed: nobody, once the owner from step 3 has the habit.

## The joiner (on-boarding) checklist

Copy this into your own documentation and adapt the vendor names. Every line has an owner column for a reason: an unowned line does not happen.

**Before day one**
- [ ] Role assigned from the approved role list, in writing. Owner: hiring manager.
- [ ] Identity provider account created with the role's group memberships. Owner: information technology or security.
- [ ] Multi-factor authentication enforced on the account before first login, with a hardware security key issued if the role is administrative, engineering, finance, or support with customer data access. Owner: information technology or security.
- [ ] Laptop provisioned, disk encryption confirmed on, device enrolled in whatever device management exists. Owner: information technology. See `cs-2-endpoint-security.md`.
- [ ] Password manager seat created and the person is added only to the vaults their role requires. Owner: security.
- [ ] Contractor only: end date recorded, sponsor recorded, calendar reminder set for one week before end date. Owner: sponsor.

**Day one**
- [ ] Person signs in, enrolls their second factor, and confirms it works. Owner: the new hire, verified by information technology.
- [ ] Application access granted by group membership only. No individual grants. No copying another person. Owner: information technology or security.
- [ ] Acceptable use and confidentiality acknowledgement signed and filed. Owner: people operations.
- [ ] Fifteen-minute security onboarding delivered (content below). Owner: security.

**Week one**
- [ ] Production access, if the role requires it, requested and approved separately, not bundled into the day one grant. Owner: engineering manager plus security.
- [ ] Person is in the security announcement channel and knows how to report something. Owner: security. See `dr-4-company-comms-channel.md`.
- [ ] Record filed: name, start date, role, systems granted, who granted them, date. Owner: information technology or security.

### The fifteen-minute security onboarding

Do not deliver a compliance slide deck. You get fifteen minutes and roughly one memorable idea per five minutes. Cover exactly these four things:

1. **How to report something, and the promise that comes with it.** Give the channel or address. Say the sentence "you will never be in trouble for reporting something, including something you did." This is the single highest-value minute of the session because it converts every employee into a sensor.
2. **The two attacks that will actually target them.** Phishing that asks them to approve a login prompt they did not start (tell them: never approve a prompt you did not trigger, report it instead), and an urgent message from a founder or manager asking for gift cards, a wire, a password, or an urgent file. Show a real example if you have one.
3. **Where company data is allowed to live.** Name the approved places. Name the disallowed ones explicitly, including personal cloud drives, personal email, and pasting customer data into consumer artificial intelligence tools that are not on the approved list. See `references/07-modern-cells.md` for the artificial intelligence tool policy.
4. **The password manager, demonstrated live.** Watch them save one credential. Say that no company password should exist outside it, and that nobody from the company will ever ask them for a password or a multi-factor code, ever.

That is it. No cryptography, no threat landscape, no "the average cost of a breach is". Keep it under fifteen minutes and repeat it in written form in the channel.

## The leaver (off-boarding) checklist

Hard ordering matters. Steps 1 and 2 come first because they cut the largest number of doors with one action. Everything after is cleanup.

**Time target: identity provider suspended within 1 hour of the last working moment. Everything else within 1 business day. For involuntary departures, see the runbook below: the target is simultaneous with the conversation.**

**Phase 1, kill the front door (minute 0 to 60)**
- [ ] Suspend the identity provider account. Do not delete it. Deletion loses data, breaks file ownership, and is irreversible on many platforms after a grace period.
- [ ] Revoke all active sessions and refresh tokens per the runbook in `cs-1-identity-and-access.md`. Suspension alone often leaves existing browser sessions alive. **This signs the person out of every device immediately, so for a resignation tell them first**; for an involuntary departure, see the runbook below, where not telling them first is the whole point. This step is skipped constantly and it is the one that actually matters, because a stolen or still-open session survives a disabled password.
- [ ] Reset the password to a random value, so any cached credential in a browser or on a phone stops working.

**Phase 2, the systems outside the identity provider (hour 1 to end of day)**
- [ ] Code host: remove from the organization. GitHub: Settings, then People, then Remove. GitLab: group Members, then Remove. Also check outside collaborators on individual repositories, which do not appear in the org member list.
- [ ] Code host credentials that survive account removal: any deploy keys they created, any personal access tokens used in shared automation, any secure shell keys registered to the account, any signed commit keys. You cannot enumerate another user's personal tokens, so ask the departing person in writing and ask their team what automation might break.
- [ ] Cloud: AWS, remove the IAM user or Identity Center assignment, and deactivate their access keys. GCP, remove `user:` bindings at project and organization level. Azure, remove role assignments. Verify with the credential report or IAM policy dump.
- [ ] Software as a service applications behind single sign-on: usually handled by phase 1, but verify at least the two most sensitive.
- [ ] Software as a service applications **not** behind single sign-on: these are the killers. Work the list you built from the corporate card export. Each one needs a manual removal.
- [ ] Chat: Slack, deactivate the member (Admin, then Manage members). Teams, handled by the Microsoft 365 account block, but check any guest access in external tenants.
- [ ] Password manager: remove the seat, and separately rotate every credential in every shared vault they had access to. Removing the seat does not un-know a password they memorized or exported.
- [ ] Shared and service accounts: rotate every shared password they knew. This is the most commonly skipped item on the entire list and it is the one that a determined former employee actually uses.
- [ ] Customer-facing and support tools: support desk, customer relationship management, billing and payments, analytics. These hold customer data and are frequently outside single sign-on.
- [ ] Production data stores accessed directly: database users, business intelligence and warehouse tools, any personal database credential.
- [ ] Virtual private network, bastion host, or zero trust access tool: remove the certificate or device enrollment, not just the account.

**Phase 3, the things everyone forgets (day 1)**

Two items in this phase, the mail forwarding rule check and the third party application authorization check, are compromise-assessment checks as well as hygiene checks. The first time you sweep them, whether across one leaver or across the whole directory, there is a genuine chance that what you find is not a departing salesperson's convenience rule but an attacker's persistence, because a forwarding rule and an unclaimed OAuth grant are two of the most common footholds that survive a password reset. If you find a forwarding rule to an address nobody recognises, or a grant with mail read or send scopes that nobody will claim, stop working the checklist. Do not delete it, do not revoke it, do not "just tidy it up": that destroys the artifact, resets the timestamps, removes your ability to prove scope, and warns whoever set it up to check their other footholds. Screenshot it, leave it in place, and go to `dr-0-compromise-assessment.md`, which tells you how to establish whether it is live and how to escalate. Containment, when it comes, is an incident decision with a named owner, and evidence preservation runs in parallel with it rather than delaying it.

- [ ] Mail forwarding rules on their mailbox, forwarding company mail to a personal address. Check this explicitly. It is a favourite of departing salespeople and it is a data exfiltration channel that survives account suspension in some configurations.
- [ ] Mailbox delegation and "send as" permissions, in both directions: what they delegated to others, and what others delegated to them.
- [ ] Calendar and file shares: files shared externally by them, files owned by them that the team still needs, calendars shared to personal accounts. Transfer ownership before suspension turns into deletion.
- [ ] Third-party application authorizations (OAuth grants) they approved, including any personal integration connected to company data. Google Workspace: Security, then API controls, then "App access control". Microsoft 365: Entra, then Enterprise applications. See `references/07-modern-cells.md`.
- [ ] Anything they own that pages or alerts: on-call rotation, alert routing, monitoring escalation, status page administrator. Removing them silently breaks the alerting path.
- [ ] Domain registrar, DNS provider, TLS certificate accounts, app store developer accounts, and social media accounts. These are almost always held by one person and never documented.
- [ ] Recovery contacts: any system where their personal email or phone number is the account recovery path.
- [ ] Subscriptions bought on a personal card and expensed. Ask directly: "is there anything you pay for personally and expense?" Then transfer or cancel.
- [ ] Physical: laptop, hardware security keys, phone if company owned, badge, office keys, and anything in a locked drawer.
- [ ] Multi-factor devices: remove enrolled devices from the identity provider so a reactivated account cannot be claimed by an old phone.

**Phase 4, close it out (day 1 to 2)**
- [ ] Re-run the discovery commands for this person across the identity provider, the code host, and the cloud. Confirm zero results.
- [ ] File the record: name, last day, timestamp per phase, who ran it, verification output.
- [ ] Note anything you could not complete and why, in `RISK-REGISTER.md`.

## The involuntary termination runbook

The rule is simple and non-negotiable: **for an involuntary departure, access revocation happens during the conversation, not after it.** The window between "you are being let go" and "your access is gone" is when data walks out the door. It should be zero minutes.

**Before the day**
1. Security is told in advance, under confidentiality, by the founder or head of people. If security is being told after the fact, that is the process problem to fix, and fix it once rather than arguing about it during a termination.
2. Security prepares a per-person revocation list from the leaver checklist, pre-filled with the exact console pages open in tabs. Do not click anything yet.
3. Agree the trigger signal in advance: typically a one-word direct message from the person leading the conversation, sent the moment the conversation begins. Agree who sends it and who receives it.
4. Agree what happens to the mailbox and files: usually suspend and transfer ownership to the manager. Decide this in advance, because after suspension you will be making the decision under time pressure.
5. If the person has production access, an on-call rotation slot, or is the sole owner of any system, arrange the handover in a way that does not tip them off. Usually this means the manager quietly documents the dependency rather than asking the person directly.
6. Involve legal or an employment advisor if one exists, and follow their instruction on evidence preservation. If there is any suspicion of wrongdoing, preserve first: do not delete the mailbox, do not wipe the laptop, do not reset anything you have not been told to reset. Preservation beats cleanup and destroying evidence is worse than the original problem.

**During the conversation (minute 0)**
7. On the trigger signal, suspend the identity provider account and revoke all sessions and refresh tokens per the runbook in `cs-1-identity-and-access.md`. This is one action and it should take under sixty seconds. The lockout warning that runbook carries does not apply here: the person is being told in the room, at the same moment, by the person leading the conversation. That is the reason the trigger signal exists, and it is why this is the one case where you cut sessions without warning the account holder yourself.
8. Remove from the code host organization and deactivate cloud access.
9. Deactivate chat. Do this after the identity provider, not before, because chat is often the person's only way to reach human resources and cutting it first is both cruel and confusing.
10. Do not send any company-wide announcement. That is people operations' call and their timing, not yours.

**Within the hour**
11. Work the full phase 2 and phase 3 leaver checklist.
12. Rotate every shared credential the person had access to. Treat this as mandatory for an involuntary departure even when it is optional for a resignation.
13. If the departure is contentious, review their recent activity: large file downloads or exports, mass sharing to external addresses, repository clones, and unusual data queries. Google Workspace: Admin console, then Reporting, then Audit and investigation, then Drive log events. Microsoft 365: Purview, then Audit. Code host: the organization audit log. Only do this where employment law and your legal advisor permit it, and document that you were asked to.

**Within the day**
14. Arrange hardware return. If the laptop is enrolled in device management and the situation warrants it, discuss a remote lock with the founder before doing it. A remote wipe destroys evidence and is rarely the right first move.
15. File the record, including timestamps, in the evidence location.

**Layoffs of multiple people at once:** the same runbook, but prepare a script or a batched action list per person in advance, and assign one revoker per five to eight departures so nobody is working a queue while sessions stay live. Agree the exact minute of the trigger. Rehearse the sequence the day before with real names redacted.

## Contractors, agencies, and employer-of-record populations

Everything above assumes the company employs the person directly, which means the company knows their start date, knows their last day, and controls the moment access stops. For a meaningful share of the people with access at a startup, none of those three things is true. Sort your non-employee population into these four cases before you write a single checklist line, because they fail differently.

**Case 1: an individual contractor on your systems.** They have an account in your identity provider, they work on your machines or their own, and you have a direct relationship with them. This is the easy case and the standard checklists cover it unchanged. The only additions are the ones already in Step 7: an end date recorded at the moment access is granted, a named sponsoring employee, and a calendar reminder a week before the end date. Default to letting access expire and requiring a positive renewal, rather than defaulting to extension.

**Case 2: an agency or vendor whose staff work on your systems.** Your contract is with the agency, not with the individual, and the agency rotates people on and off without telling you. The failure mode is specific and common: an agency engineer rolls off a project on a Friday, nobody at your company is told, and their account stays live for months. Fix it with a contract term rather than a checklist: require the agency to notify a named person at your company within one business day of any staff change affecting your account, and name your side's recipient. Until that term exists, compensate by reviewing the agency's account list monthly against a roster you ask the agency account manager to confirm in writing, and by setting a short expiry on every agency account so that neglect fails closed rather than open.

**Case 3: the agency owns the environment, not just access to it.** This is a different problem and this file cannot solve it. If the development agency holds the cloud root account, owns the code host organisation, is the registrant on the domain, or is the only party who can deploy, then you are not offboarding a user from your system, you are trying to reclaim a system from its owner. Every control in this cell assumes you can revoke, and you cannot revoke from someone who holds the account. Go to [09-outsourced-engineering.md](09-outsourced-engineering.md), which covers ownership transfer, what to ask for in what order, and how to sequence it without an outage or a contract dispute. Do not attempt an access change against an environment the company does not own without the founder and, where a contract governs it, counsel.

**Case 4: employer of record and professional employer organisation populations.** An employer of record (EOR) is a company that is the legal employer of a person who works day to day for you, typically so you can hire in a country where you have no legal entity. A professional employer organisation (PEO) is the related arrangement where employment is co-shared. Deel, Remote, Velocity Global, Oyster, Papaya, and the employer-of-record products inside Rippling and Justworks are the common ones. The security consequence is that the EOR, not you, controls the employment relationship, and therefore controls the event your whole leaver process is triggered by.

What that means in practice:

- **The EOR is a required notification path for joiners, movers, and leavers, in both directions.** Get yourself or a named person at your company onto whatever notification the EOR platform sends, and separately ask the EOR account manager what their standard notice is for a termination they process. Ask this before you need it. Many of these platforms can fire a webhook or at least send an email that a workflow tool can catch, which makes them a better trigger than a human remembering.
- **A terminated EOR worker is deprovisioned on the EOR's timetable, not yours, unless a contractual notification term exists.** That is the finding, and you should write it as one. Notice periods and termination processes in the EOR's jurisdiction can mean you learn about a departure days after the last working day. Put the gap in `RISK-REGISTER.md` with the name of the person who owns the EOR relationship, usually people operations or a founder, as the owner, and the remediation as "add a same-day notification term at the next contract renewal".
- **Until that term exists, use the compensating control:** a monthly reconciliation between the EOR's active worker list and your identity provider's user list. This takes fifteen minutes, it is the same reconciliation recommended for the automation failure mode below, and it is the only thing standing between you and a leaver you were never told about.
- **The device question is separate and often worse.** Where the EOR supplies the laptop, or the worker uses their own, you may have no ability to enrol, lock, or wipe it, and enrolling it may need consultation you have not run. See Multi-country employment constraints in [cs-2-endpoint-security.md](cs-2-endpoint-security.md). Record the population as `partial` with the reason rather than pretending the fleet is covered.
- **Check what you already pay for.** If the company runs on an EOR platform, the joiner and leaver automation is frequently included in the subscription and switched off. This is the single most common piece of already-paid-for lifecycle automation sitting idle at a startup.

## Decision points

**Suspend or delete the account?**
DEFAULT: suspend, always, and keep it suspended for at least 30 to 90 days. Deletion loses audit history, orphans file ownership, breaks group memberships that other things depend on, and in several platforms frees the email address for reuse, which creates a confusing security problem later. Change this only if you have a per-seat licence cost that genuinely hurts, in which case check whether your vendor offers an archived or inactive tier first.

**Convert the mailbox to a shared mailbox, or forward it to the manager?**
DEFAULT: suspend the account and grant the manager delegated read access for a fixed period (30 days is typical), rather than setting up forwarding. Forwarding drips company mail into an ongoing stream that nobody remembers to turn off. Change this only if a customer-facing address genuinely needs to stay live, in which case convert it to a properly owned shared mailbox or alias.

**Grant access by role or by request?**
DEFAULT: role for the standard set, request plus approval for anything sensitive (production, billing, customer data export, administrator rights in any system). Never by cloning a person. Change this only if a role's population is one person, in which case it is not a role, it is a person, and it should be a request.

**Single sign-on for everything, or only the important things?**
DEFAULT: single sign-on for anything holding customer data, money, or code, plus anything with more than about ten seats. Everything else can be password manager plus manual removal. Chasing full coverage at 40 people is a good way to spend a quarter on nothing. Note that the "SSO tax" is real: some vendors charge multiples for the tier that includes it. When a vendor prices single sign-on out of reach, put the app on the manual leaver checklist and note the risk in `RISK-REGISTER.md` rather than pretending.

**Contractors on company accounts, or their own?**
DEFAULT: company identity provider accounts with a hard end date. It costs a seat and gives you one revocation point, an audit trail, and multi-factor enforcement. Change this only for a contractor who touches nothing sensitive and works entirely through a client's own tooling. This default assumes you control the accounts in the first place; where an agency owns the environment, see case 3 in Contractors, agencies, and employer-of-record populations above and go to [09-outsourced-engineering.md](09-outsourced-engineering.md) before changing anything.

**Automate provisioning now, or stay manual?**
DEFAULT: stay manual until you are consistently doing more than about four joiner-or-leaver events per month, or until the manual process has failed twice. Below that threshold the checklist is faster to build, easier to change, and produces the same audit evidence. See the automation path below.

## Danger zone

Every action here requires an explicit human yes before you run it. State the risk out loud, get the word "yes", and record who said it in `DECISION-LOG.md`.

- **Suspending or deleting any account.** STOP. Risk: you lock out an active employee, or you disable an account that is silently running production automation. Personal accounts running cron jobs, continuous integration credentials, alert routing, and payment webhooks are extremely common at this size. Before suspending anyone, ask their manager "does anything automated run as this person?"
- **Deleting rather than suspending.** STOP. Risk: irreversible loss of mail, files, and audit history, plus orphaned resources in cloud accounts that nobody can then reclaim.
- **Bulk operations across many accounts.** STOP. Risk: a single wrong filter suspends the whole company. Never run a bulk action you have not first run in a dry-run or list-only mode, and never against more than five accounts on the first pass.
- **Remote lock or remote wipe of a laptop.** STOP. Risk: destroys evidence you may legally need, may be unlawful in some jurisdictions if the device is personally owned, and is very hard to undo. Get a founder's explicit yes and, where one exists, legal's.
- **Reviewing a departing person's mail, files, or messages.** STOP. Risk: employment law, works council rules, and privacy law vary sharply by country. In parts of Europe this can be unlawful without a specific basis. Get written authorization from whoever runs people operations before looking.
- **Rotating a shared credential.** STOP. Risk: outage. A shared credential is shared precisely because several things use it, and at least one of those things is undocumented. Announce the rotation window in advance, rotate during business hours, and have the old value recoverable for the first hour.
- **Removing a person from the code host organization when they are the sole owner of a repository or organization.** STOP. Risk: you can orphan a repository or, worse, lock the company out of its own organization. Confirm there are at least two owners before removing anyone with the owner role.
- **Turning off single sign-on or changing an identity provider application assignment "to test something".** STOP. Risk: instant company-wide outage of the affected application.
- **Cancelling a software as a service subscription found on a personal card.** STOP. Risk: it may be load-bearing for a customer-facing feature. Find the owner first.

## Do not do this yet

- **Do not buy an identity governance product.** At 20 to 100 people the checklist plus a spreadsheet is genuinely better: faster to change, easier to explain to an auditor, and free.
- **Do not build a custom offboarding automation script before the manual checklist has run cleanly ten times.** You will automate a process you do not understand and the script will silently stop working the first time a vendor changes an application programming interface. Automate the process you have proven, not the process you imagine.
- **Do not attempt full single sign-on coverage across every application.** Cover the crown jewels, list the rest, move on.
- **Do not run a formal, evidenced quarterly access review yet.** One annual pass done by hand is enough for an early framework. Quarterly reviews at this size consume more time than they surface risk.
- **Do not write a fifteen-page employee lifecycle policy.** Write the two checklists. Policies that nobody executes are worse than no policy, because they create audit findings against yourself.
- **Do not turn the fifteen-minute security onboarding into a mandatory annual training platform purchase.** That comes later and only if a framework or a customer demands it.
- **Do not try to fix the identity provider architecture as part of this cell.** If the directory of record is a mess, that is CS-1 work. Do CS-3 on top of what exists, note the dependency, and come back.

## Evidence to capture

Write into `SECURITY-STATE.md`, section `## CS-3 On-boarding and off-boarding`:
- Status per line item of the definition of done, as `unknown` / `none` / `partial` / `done`, each with its evidence (a command output, a console screenshot, or a named human's confirmation and the date).
- The reconstructed leaver table: person, last day, date access actually stopped, gap in days, systems still live at time of check.
- The system inventory: every system a human can log into, its owner, and whether it is behind single sign-on.
- The named owner of the joiner checklist and the named owner of the leaver checklist.

Write into `RISK-REGISTER.md`:
- One entry per still-active departed account, with severity set by what the account reaches (code host and cloud are high, a marketing tool is low), the owner, and the remediation date.
- One entry for "no offboarding owner" if that is the case, which is usually the highest-severity item in this cell.
- One entry per application holding customer data that cannot be put behind single sign-on, with the accepted-by name.

Write into `DECISION-LOG.md`: the suspend-versus-delete decision, the mailbox handling decision, the single sign-on coverage boundary, and who approved each.

Write into `ACCESS-LOG.md`: your own request for identity provider read access, the date, who granted or denied it, and at what level.

**What an auditor or an enterprise customer will actually ask for**, so collect it as you go:
1. The written onboarding and offboarding procedure, with a date on it.
2. A population list of all terminations in the audit period, from the human resources system, not from you.
3. For a sample of those terminations (typically five to twenty five people), evidence that access was removed, showing a timestamp after the termination date. A screenshot of the identity provider's deactivation event, or a system log export, is the standard artifact.
4. Evidence that onboarding controls ran for a sample of new hires: signed acceptable use acknowledgement, and proof the account was created with the correct role.
5. The current user list per in-scope system, so they can look for names that are not on the current employee roster.
6. Evidence of an access review, at whatever cadence you claimed. Claim annual, not quarterly, unless you are certain you will do quarterly.

The most valuable habit in this entire cell is that item 3 requires a timestamp, and timestamps can only be captured at the time. Retroactive evidence does not exist.

## Cost and effort

- Discovery and the last-ten-leavers reconstruction: 0.5 to 1 day. Free.
- Writing both checklists plus the mover checklist: 1 day. Free.
- Involuntary termination runbook plus rehearsal: 0.5 day. Free.
- Remediating what discovery found: 0.5 to 2 days depending on how many leftovers there are.
- Ongoing: roughly 15 to 30 minutes per joiner, 30 to 60 minutes per leaver, done manually.
- Total to reach the definition of done: 3 to 5 days of work spread over two to three weeks, at zero dollars.

Optional spend, cheapest first:
- Password manager with team vaults and audit logging: roughly 4 to 8 dollars per user per month. Buy this if it does not exist; it is the highest-value purchase in the corporate security domain.
- Hardware security keys for administrative and engineering staff: roughly 25 to 60 dollars per key, two per person. One-time.
- Identity provider with automated provisioning (SCIM): if you already pay for Google Workspace or Microsoft 365, group-based provisioning to a handful of applications is included in the mid tiers. A dedicated identity provider such as Okta or JumpCloud runs roughly 6 to 15 dollars per user per month. Free and cheap alternatives exist: Google Workspace and Entra ID both act as an identity provider for SAML and OpenID Connect applications at no extra cost on plans you likely already have.
- Employer-of-record and human resources platforms that bundle provisioning (Rippling, Deel, and similar): if the company is already paying for one, the lifecycle automation is often included and unused. Check before buying anything new. This is the single most common piece of already-paid-for automation sitting idle at a startup.
- Identity governance products: 30,000 dollars per year and up. Not now.

## The automation path, when volume justifies it

Trigger to automate: more than about four lifecycle events per month, or two manual failures.

1. Make the human resources system the trigger, not a person. When a termination date is entered in payroll, that event starts the process. Most payroll and employer-of-record platforms can fire a webhook or at minimum send an email that a workflow tool can catch.
2. Turn on SCIM provisioning from the identity provider to your top five applications only. Pick them by data sensitivity, not by ease.
3. Move application access to identity provider groups, so adding or removing one group membership does the work.
4. Automate the checklist itself as a generated ticket with one line per item, rather than automating the revocations. A generated checklist with human execution gets you 80 percent of the value at 10 percent of the risk, and it produces audit evidence for free because each item has a completion timestamp and an actor.
5. Only after all of the above, script the long tail with vendor application programming interfaces. Keep every script's revocation actions behind a confirmation prompt.

Do them in that order. Teams that start at step 5 build a fragile script and still have no evidence trail.

## Failure modes

**The process exists but only for people who resign politely.** Early tell: your leaver reconstruction shows clean revocation for four people and nothing for the fifth, who left abruptly. Recovery: the involuntary runbook, plus getting security into the notification path before the conversation happens.

**Offboarding is owned by "whoever notices".** Early tell: when you ask who owns it, you get three different names. Recovery: name one owner in writing, in front of a founder, today. An owned bad checklist beats an unowned good one.

**Everything outside single sign-on rots.** Early tell: a departed person is gone from the identity provider but still active in the support desk or the analytics tool. Recovery: build the system inventory from the corporate card export, and mark each entry as single-sign-on or manual. Manual entries go on the checklist by name.

**Shared credentials are never rotated.** Early tell: nobody can tell you how many people know the shared root password, or the shared vault has a credential last changed two years ago. Recovery: inventory shared accounts, assign each an owner, rotate on every departure, and start migrating each one to a per-person account or a real service account.

**The mover case is invisible.** Early tell: an engineer who moved to sales two years ago still has production database access. Recovery: run the mover checklist retroactively across everyone who changed role, then add the transfer trigger to whatever notification you already receive for joiners and leavers.

**Contractors accumulate.** Early tell: you cannot say how many non-employees have access right now. Recovery: require an end date at grant time, put it in a calendar, and default to denying access renewal rather than defaulting to extending it.

**Automation was built too early and silently broke.** Early tell: a script exists, nobody has read its logs in months, and a departed person is still active. Recovery: turn the automation into a checklist generator with human confirmation, and add a monthly reconciliation between the human resources roster and the identity provider user list.

**Evidence was never captured.** Early tell: an auditor asks for the deactivation timestamp of someone who left eight months ago and you can only say "we definitely did it". Recovery: you cannot recover past evidence, so start today, and be honest in the audit about the start date of the evidence trail. Auditors accept "the control has operated since [date]" far more readily than they accept a reconstruction that does not hold up.

## Related cells

- [CS-1: Identity and Access Management](cs-1-identity-and-access.md), the directory of record this cell depends on entirely.
- [CS-2: Endpoint security](cs-2-endpoint-security.md), for laptop provisioning, device enrollment, and hardware return.
- [CS-4: Workplace security](cs-4-workplace-security.md), for badges, physical keys, and office access on the way out.
- [SE-3: Secrets and keys](se-3-secrets-and-keys.md), for shared credentials, personal access tokens, and cloud key rotation on departure.
- [DR-0: Are we already compromised?](dr-0-compromise-assessment.md), because the phase 3 mail forwarding sweep and the third party grant review are compromise-assessment checks as well as hygiene checks, and the first time you run either you may find something live.
- [DR-1: Incident response plan](dr-1-incident-response-plan.md), for when a departure becomes an incident.
- [When engineering is an agency](09-outsourced-engineering.md), for the case where a contractor or agency owns the cloud account, the code host organisation, or the domain, rather than merely holding access to yours. That is an ownership problem, not an offboarding problem, and this cell cannot solve it.
- [DR-4: Company communications channel](dr-4-company-comms-channel.md), for where the fifteen-minute onboarding points people to report things.
- [CO-3: Existing commitments](co-3-existing-commitments.md) and [CO-4: Data inventory and framework](co-4-data-inventory-and-framework.md), for the framework controls this cell satisfies.
- [Modern cells](../references/07-modern-cells.md), for third-party application authorization (OAuth) grants left behind by departing employees.
- [The 90 day plan](03-90-day-plan.md), where this cell is sequenced.
