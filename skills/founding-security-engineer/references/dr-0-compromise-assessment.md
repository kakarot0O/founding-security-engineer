# DR-0: Are we already compromised?

> Grid coordinate: Detection and Response, cell zero. This cell sits before DR-1 and DR-2 because it answers a question about the past, not the future.
>
> Load when: you are in the first two weeks at a company and have not yet checked whether an intruder is already inside or was inside recently, or when an intake answer, a rumour, an investor question, or a customer question suggests something already happened. Load this instead of continuing recon if any of those signals appear. If an incident is already declared and active, do not load this file, load [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md). **If a person has named a specific past event**, that is the "An incident that happened before you arrived" section of [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md), and it runs first, because the moment an event has a name the questions become legal ones and what you write down starts to matter. Come back here afterwards for the different and unnamed question of whether anything else is inside. If you are designing ongoing alerting for future events, that is [dr-2-top-security-signals.md](dr-2-top-security-signals.md), not this file.

## Step zero, before anything else: write down which clocks are running out

Do this before you run a single hunt query. Not after. Not "once I understand the environment".

Every hunt below reads a log. Every log has a retention window, and once a window closes the evidence is gone permanently, including the evidence that would have told you the company was breached last quarter. As [dr-3-logging-consumption-model.md](dr-3-logging-consumption-model.md) explains, default retention is commonly 7 to 90 days. If you spend your first three weeks drawing architecture diagrams, you may draw them over the top of the only fortnight in which the answer was still recoverable.

So the first artifact of this cell is a small table. Create `.security/RISK-REGISTER.md` entries later, but write the table now, in `SECURITY-STATE.md` under a heading `## Log retention clocks`, with these columns: source, retention window, how it was confirmed, earliest date still visible today, date checked.

Confirm retention per platform like this. Do not guess, and do not trust a colleague's memory, because the number is usually a licence tier question and the tier often changed at some point.

| Platform | Where the retention answer actually lives |
| --- | --- |
| Google Workspace | Admin console > Reporting > Audit and investigation, then open each log (Admin, Login, OAuth Token, Drive, Gmail). Google publishes a retention and lag table in its Workspace admin help; several logs are around six months while Gmail log events are much shorter. Confirm the current published numbers for your edition rather than assuming. If Google Vault is licensed, check Vault > Retention separately, because Vault retention and audit log retention are different systems. |
| Microsoft 365 | Microsoft Purview portal > Audit. Audit (Standard) and Audit (Premium) have different retention (Standard is commonly 180 days, Premium commonly one year, with a paid long-term add-on). Confirm which you hold in the Microsoft 365 admin centre licence list. Mailbox audit logging is on by default but the set of audited actions differs per licence. |
| Microsoft Entra ID (formerly Azure Active Directory) | Sign-in and audit logs are commonly 7 days on the free tier and 30 days with Entra ID P1 or P2. Check entra.microsoft.com > Identity > Monitoring and health > Diagnostic settings to see whether logs are also being exported anywhere with longer retention. |
| Okta | Reports > System Log. Okta documents System Log retention (commonly 90 days). Check whether a log streaming integration exists under Reports > Log Streaming, because that copy may go back further. |
| GitHub | Organization settings > Archives > Logs > Audit log. GitHub documents a retention period for organization audit log events (commonly around 180 days) and a shorter one for Git events. Confirm in the current GitHub documentation for your plan. |
| GitLab | Group or Admin Area > Audit events. On GitLab.com, availability and depth depend on tier. On self-managed, retention is effectively however long the database rows survive, so ask whether anything prunes them. |
| AWS | CloudTrail Event history in the console holds 90 days and cannot be extended. A configured trail delivering to Amazon Simple Storage Service (S3) holds whatever the bucket lifecycle policy allows. Run `aws cloudtrail describe-trails` and then check the destination bucket's lifecycle rules. CloudTrail Lake has its own configured retention. |
| Google Cloud | Admin Activity audit logs are retained for a long fixed period in the `_Required` log bucket and cannot be shortened. Data Access audit logs land in `_Default` with a much shorter default and, critically, **are off by default for most services**. Run `gcloud logging buckets list --location=global` for retention, and check IAM and Admin > Audit Logs for which Data Access logs are enabled. |
| Azure | The platform Activity log is retained 90 days and cannot be extended in place. Anything longer requires a diagnostic setting exporting to a Log Analytics workspace or storage account. Check `az monitor diagnostic-settings subscription list`. |
| Anything self-hosted | Ask the engineer who owns it, then verify by querying for the oldest record you can find. |

When the table is done, look at the shortest window in it. That number, in days, is the deadline for the rest of this file. Say the number out loud to the human: "we have N days of evidence in the thinnest source, so this hunt happens this week, not next month."

If any window is shorter than 30 days, that is a finding on its own. Record it in `RISK-REGISTER.md` with status open. Do not fix it now; extending retention costs money and belongs to [dr-3-logging-consumption-model.md](dr-3-logging-consumption-model.md).

## The hard rule: a hit stops everything

**If any hunt below produces a real hit, stop. Do not run the next hunt. Open [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md) and declare an incident.**

Four things people do instead, all of which make the outcome worse:

1. **They keep hunting.** It feels efficient to finish the checklist first. It is not. Every hour between "I found a forwarding rule" and "we declared" is an hour the attacker keeps their access, and the rest of the hunt is now an incident investigation task that should be run with an incident commander, a timeline, and someone else preserving evidence in parallel.
2. **They tell the whole company.** A general announcement reaches the attacker, who is very often reading the company chat or the compromised mailbox in real time. It also reaches people who will forward it outside, which can turn an internal matter into a disclosure event before anyone knows the facts. Comms in an incident go through one named person, see the customer notification and comms sections of [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md).
3. **They tip off the account under investigation.** Messaging the employee ("hey, weird question, did you set up email forwarding?") is the single most common self-inflicted wound. If the account is attacker-controlled, you have just told the attacker they are burned, and burned attackers destroy things or dig in deeper. If the account is not attacker-controlled, the message is still an HR and employment-law event you are not authorised to start.
4. **They clean it up.** Deleting the forwarding rule, revoking the token, or removing the rogue collaborator feels like the responsible act. It destroys the artifact, resets timestamps, removes your ability to prove scope, and often removes only one of several footholds while alerting the attacker to look for the others. Preservation runs in parallel with containment, never instead of it, and containment is an incident decision with a named owner, not a solo decision by the person who happened to find it.

The correct sequence after a hit: screenshot or export the finding exactly as it appears, note the timestamp and the timezone, tell exactly one person (usually the CTO or CEO), and open DR-1. Nothing else.

One exception, and only one: **evidence preservation never delays containment.** If what you found is clearly live and clearly ongoing (an attacker is actively sending mail, exfiltrating a repository, or spinning up cloud resources right now), containment happens immediately and preservation happens alongside it. Do not wait to build a forensic capture the company cannot actually perform. The reversible containment actions available during a declared incident are listed in the Danger zone below.

## Why this cell exists

Everything else in the first month assumes the building is empty and you are installing locks. That assumption is unearned. A meaningful share of first security hires are hired *because* something already happened, and a further share arrive at companies where something happened and nobody noticed. The recon in [01-recon.md](01-recon.md) builds an inventory of what exists, and DR-2 builds alerting for what happens next, but neither one asks whether someone is in the building right now.

The check is cheap. It is a day of read-only queries against systems you can already reach, it needs no tooling purchase, and it produces one of two genuinely valuable outcomes: either you find something, in which case nothing else you could have done in week one comes close in value, or you find nothing, in which case you can say with a date attached how far back the company can prove it was clean. Both outcomes are worth more than another diagram.

## Definition of done

Good enough for a 20 to 100 person startup:

- The log retention table exists in `SECURITY-STATE.md` and every row has a confirmed window, not an assumed one.
- Every hunt in the Discovery section below has been run, or has been explicitly marked not applicable with a written reason (for example, "no Microsoft 365 tenant, company is Google Workspace only").
- Each hunt has a recorded result: clean, hit, or blocked (no access, name the person who has it).
- If clean, a dated statement exists saying what was checked, how far back, and by whom.
- If any hit, an incident file exists at `.security/incidents/INC-<YYYY>-<NNN>-<slug>.md` and this file's job is finished.
- The admin access you used, and whether it was permanent or temporary, is recorded in `ACCESS-LOG.md`.

Explicitly **not** required at this size: a forensics vendor, disk imaging, memory capture, endpoint detection and response telemetry, a threat intelligence feed, indicator-of-compromise matching against a commercial list, a written hunt methodology document, or a repeatable automated hunt. Those come later, or never. This is one person, read-only, in a day or two.

## Discovery

Every command in this section is read-only. Where a command mutates anything, it is labelled. Run nothing that touches a customer, and run no active scan of any kind against any system, including the company's own, without written authorisation. Reading logs and configuration is not scanning; a port scan, a credential test, or a web vulnerability scan is.

**If you have no admin access yet.** Do not wait weeks for it. Send the message in "Ask the human" below, and ask the current administrator to run the query with you on a screen share and export the result. Screen-share output is real evidence if you note who ran it and when. Ask for temporary read-only administrator access with a stated end date rather than permanent access, and log the grant in `ACCESS-LOG.md`. For cloud, ask for the minimal correct roles, and be precise, because the obvious answers are wrong:

- **AWS:** ask for `SecurityAudit` plus `ViewOnlyAccess`. Do **not** ask for `ReadOnlyAccess`; it includes `s3:Get*` and `dynamodb:Scan`, so it grants bulk read of customer data and will fail any reasonable least-privilege conversation.
- **Google Cloud:** ask for `roles/iam.securityReviewer` plus `roles/browser` plus any service-specific viewer role you actually need. Do **not** ask for `roles/viewer`; it includes `storage.objects.get`, so it reads customer data out of buckets.
- **Azure:** ask for `Reader` plus `Security Reader`. Azure's `Reader` is genuinely control plane only and does not read blob or database contents, which makes Azure the one place where the plain reader role is an honest answer.

### H-1. Tenant-wide mail forwarding and inbox rules

The highest-yield check in this entire file, and the one that is almost never run. Business email compromise is the dominant threat chain against a company of this size, and the attacker's first persistent action after taking a mailbox is nearly always a rule that forwards, redirects, or auto-deletes mail. The rule survives a password reset. It survives adding multi-factor authentication (MFA). It sits there quietly for months.

*Google Workspace.* Admin console > Apps > Google Workspace > Gmail > End User Access, and check whether "Automatic forwarding" is allowed at all. Then Admin console > Reporting > Audit and investigation > Gmail log events (edition dependent) and User log events, and look for forwarding and filter changes. If the free, community-maintained GAM command line tool is already installed and authorised in the tenant, `gam all users print forwardingaddresses` and `gam all users print filters` produce the whole-domain answer in one pass. If GAM is not already set up, use the console path rather than installing new tooling mid-hunt.

*Microsoft 365.* Connect with `Connect-ExchangeOnline` from the ExchangeOnlineManagement PowerShell module, then run these read-only cmdlets:

```powershell
# Mailbox-level forwarding, whole tenant
Get-Mailbox -ResultSize Unlimited |
  Where-Object { $_.ForwardingSmtpAddress -ne $null -or $_.ForwardingAddress -ne $null } |
  Select-Object DisplayName, PrimarySmtpAddress, ForwardingSmtpAddress, ForwardingAddress, DeliverToMailboxAndForward

# Inbox rules, whole tenant. Slow on large tenants; let it run.
Get-Mailbox -ResultSize Unlimited | ForEach-Object {
  Get-InboxRule -Mailbox $_.PrimarySmtpAddress -ErrorAction SilentlyContinue |
    Select-Object MailboxOwnerId, Name, Enabled, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage, MoveToFolder, From, SubjectContainsWords
}
```

Also check Exchange admin center > Mail flow > Rules for tenant-wide transport rules, which are rarer but far worse when present, and Mail flow > Remote domains for a permissive forwarding setting. In Microsoft Purview > Audit, search operations `New-InboxRule`, `Set-InboxRule`, `UpdateInboxRules`, `Set-Mailbox`, and `Set-TransportRule`.

*What a hit means.* A rule that forwards to an external address, or that moves messages matching words like invoice, payment, wire, bank, password, reset, or the name of your payment processor into Archive, RSS Feeds, or Deleted Items, is close to conclusive. Attackers hide replies from the victim so the victim does not see the fraud conversation.

*False positive rate.* Moderate for forwarding, low for the hiding rules. Genuine benign causes: a person forwarding to their own personal address (still a policy problem, still worth a conversation, but not an intrusion), a ticketing or customer relationship management integration, a shared mailbox forwarding to a distribution list, and executives forwarding to an assistant. The rules that delete or bury mail matching financial keywords have essentially no benign explanation.

*Action.* Any external forward you cannot immediately attribute to a known integration, or any hiding rule at all, is a hit. Stop and open DR-1.

### H-2. Changes to audit logging configuration

An attacker turning logging off is the loudest possible signal available, and nobody looks. Run this second, because if logging was disabled at some point you need to know before you interpret the silence in every other hunt as innocence.

*AWS.* `aws cloudtrail describe-trails` then `aws cloudtrail get-trail-status --name <trail>` and read `IsLogging`. Then search history:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=StopLogging \
  --start-time 2026-05-01 --max-results 50
```

Repeat for `DeleteTrail`, `UpdateTrail`, `PutEventSelectors`, and `DeleteFlowLogs`. Note that CloudTrail Event history only covers 90 days, so anything older needs the S3 trail data.

*Google Cloud.* `gcloud logging read 'protoPayload.methodName:"google.logging.v2.ConfigServiceV2"' --freshness=90d --limit=50` catches sink and bucket changes, and `gcloud logging sinks list` shows current export. Also check IAM and Admin > Audit Logs for Data Access logging being turned off.

*Azure.* Portal > Monitor > Diagnostic settings, and `az monitor diagnostic-settings subscription list` to see whether an export existed and was removed. Deletions appear in the Activity log itself.

*Google Workspace and Microsoft 365.* In Microsoft Purview > Audit, search for `Set-AdminAuditLogConfig` and `Set-MailboxAuditBypassAssociation`; a mailbox audit bypass is a strong signal. Google Workspace does not let an administrator disable core audit logs, so the equivalent check is whether an administrator account with the power to change alert rules was itself compromised.

*What a hit means.* Logging disabled, a trail deleted, a sink removed, or a mailbox exempted from auditing, by an account other than a known infrastructure automation, is treated as compromise until proven otherwise.

*False positive rate.* Low, but not zero. Real benign causes: a cost-cutting exercise nobody documented, a Terraform refactor that recreated a trail, and a contractor tidying up. Ask "who did this and can they explain it" before escalating, but ask it of the person, not of the account under suspicion.

### H-3. Third party OAuth application grants in the last 12 months

Open Authorization (OAuth) grants are how an attacker keeps mailbox or repository access after every password in the company has been changed. Look specifically for grants carrying mail, drive, or repository scopes.

*Google Workspace.* Admin console > Security > Access and data control > API controls > Manage Third-Party App Access, and review the app list with its scopes and the count of users who granted it. Then Reporting > Audit and investigation > OAuth log events, filtered on authorisation events, sorted by date, for the last 12 months or the retention limit, whichever is shorter.

*Microsoft 365 and Entra ID.* entra.microsoft.com > Identity > Applications > Enterprise applications, add the "Created on" column, sort descending. Check Permissions on anything unfamiliar, looking for `Mail.Read`, `Mail.ReadWrite`, `Mail.Send`, `Files.Read.All`, `offline_access`, and any application-level (not delegated) permission. In Purview > Audit, search operations `Consent to application`, `Add service principal.`, `Add OAuth2PermissionGrant.`, `Add app role assignment grant to user.`, and `Add delegated permission grant.`.

*Okta.* Applications > Applications for the inventory, and in Reports > System Log query for API token creation with `eventType eq "system.api_token.create"`. An API token created by an admin account you do not recognise is equivalent to a persistent grant.

*What a hit means.* An unfamiliar application with broad mail or file scopes, especially one consented to by a single user rather than admin-consented tenant-wide, is a classic consent-phishing outcome.

*False positive rate.* High. Startups accumulate genuine integrations constantly: meeting recorders, sales tools, calendar schedulers, note-takers, AI assistants. Expect a long list. Triage by scope breadth first and by consent date second, and ask the apparent owner in a neutral way ("I am doing an inventory of connected apps, do you use X?") only for apps you have already decided are probably benign. For anything you suspect, do not ask; escalate.

*Action.* Anything you cannot attribute after checking with the person who granted it goes on the list for [m-4 SaaS sprawl and OAuth grants](07-modern-cells.md). Anything with mail read or send scopes that nobody claims is a hit.

### H-4. MFA methods registered, reset, or removed

*Microsoft Entra ID.* entra.microsoft.com > Identity > Monitoring and health > Audit logs, filter Category to authentication-method and user-management activity, and look for "User registered security info", "User deleted security info", "Admin registered security info", and password reset activity. Also Identity > Users > per user > Authentication methods for the current state.

*Okta.* Reports > System Log, query `eventType eq "user.mfa.factor.reset_all"`, then `eventType eq "user.mfa.factor.deactivate"`, then `eventType eq "user.mfa.factor.activate"`. A reset followed within minutes by an activation from a different internet protocol (IP) address is the pattern.

*Google Workspace.* Admin console > Reporting > Audit and investigation > Admin log events, filter on two-step verification events, and User log events for the user-initiated equivalents. Admin console > Directory > Users lets you add a "2-Step Verification enrollment" column for current state.

*What a hit means.* A factor removed and a new one added from an unfamiliar device or location, especially on an administrator account, is account takeover with persistence.

*False positive rate.* High in raw volume, low once correlated. People genuinely lose and replace phones constantly. The discriminator is always the pairing: reset plus new factor plus new location plus new device, within a short window.

### H-5. Admin and privileged role grants

*Google Workspace.* Admin console > Account > Admin roles, review every role and its members, then Reporting > Audit and investigation > Admin log events filtered on role assignment.

*Microsoft Entra ID.* Identity > Roles and administrators, check Global Administrator, Privileged Role Administrator, Exchange Administrator, and Application Administrator membership. If Privileged Identity Management is licensed, check both eligible and active assignments.

*Okta.* Security > Administrators for the current state, and System Log `eventType eq "user.account.privilege.grant"` for the history.

*AWS.* `aws iam list-users`, `aws iam list-attached-user-policies --user-name <user>`, and search CloudTrail for `AttachUserPolicy`, `AttachRolePolicy`, `PutUserPolicy`, `CreateLoginProfile`, and `UpdateAssumeRolePolicy`.

*Google Cloud.* `gcloud projects get-iam-policy <project> --format=json` and `gcloud logging read 'protoPayload.methodName="SetIamPolicy"' --freshness=90d --limit=100`.

*Azure.* `az role assignment list --all --include-inherited -o table`, and search the Activity log for role assignment writes.

*False positive rate.* Moderate. Startups over-grant admin as a matter of routine, so a long list is normal and is a CS-1 problem, not necessarily a compromise. The hit is a *recent* grant to an account that should not have it, or a grant made by an account that itself should not have been able to make it.

### H-6. New cloud identity users and access key creation

*AWS.* Search CloudTrail for `CreateUser`, `CreateAccessKey`, `CreateLoginProfile`, `CreateSAMLProvider`, and `DeactivateMFADevice`:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey \
  --start-time 2026-05-01 --max-results 50 --output json
```

For current state, `aws iam generate-credential-report` (this writes a report object, so it is technically a mutating call, but it changes no access and is included in `SecurityAudit`) followed by `aws iam get-credential-report --query Content --output text | base64 --decode > evidence/aws-credential-report.csv`. Read the key age and last-used columns.

*Google Cloud.* `gcloud logging read 'protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"' --freshness=90d --limit=100` and `gcloud iam service-accounts list`. User-managed service account keys are the GCP equivalent of a long-lived password.

*Azure.* Check the Activity log for service principal and credential writes, and Entra ID > App registrations > (app) > Certificates and secrets for secrets with recent start dates.

*What a hit means.* A long-lived access key created for an existing user, especially one that already uses federated or role-based access and had no keys before, is a textbook persistence move.

*False positive rate.* Moderate. Engineers create keys for legitimate reasons and forget to tell anyone. Correlate against the human, not the intent.

### H-7. SSH keys, deploy keys, personal access tokens, and self-hosted runners on the code host

*GitHub.* Organization settings > Archives > Logs > Audit log, and filter by action. Useful searches include `action:repo.create_deploy_key`, `action:org.register_self_hosted_runner`, `action:repo.register_self_hosted_runner`, `action:personal_access_token.access_granted`, and `action:oauth_application.create`. If a typed query returns nothing, do not assume the event does not exist; use the Action dropdown in the audit log user interface and browse the available event names, because GitHub renames events over time. Programmatically, with GitHub Enterprise Cloud:

```bash
gh api "/orgs/ORG/audit-log?phrase=action:repo.create_deploy_key&per_page=100" --paginate
gh api /orgs/ORG/actions/runners
gh api /repos/OWNER/REPO/keys
gh api /orgs/ORG/members --paginate -q '.[].login'
```

*GitLab.* Group > Secure > Audit events, or Admin Area > Monitoring > Audit Events on self-managed. Via the application programming interface (API), with a read-scoped token:

```bash
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/groups/<group-id>/audit_events?created_after=2026-01-01T00:00:00Z&per_page=100"
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/runners/all?scope=active"
```

*What a hit means.* A self-hosted runner registered against a public or widely-forked repository is an immediate hit, because pull request workflows can execute attacker code on it. A deploy key with write access on a repository that already uses an app-based integration is a hit. A personal access token with broad scope and no expiry, created recently, is a hit.

*False positive rate.* Moderate for deploy keys and tokens, low for unexpected runners. Ask the platform or infrastructure engineer to identify each runner by name before escalating; they usually can, instantly.

### H-8. New external collaborators on private repositories

*GitHub.* `gh api /orgs/ORG/outside_collaborators --paginate -q '.[].login'`, then per repository `gh api /repos/OWNER/REPO/collaborators --paginate -q '.[] | {login, role_name}'`. In the audit log, look for `action:repo.add_member` and `action:org.add_outside_collaborator`. Also check organization settings for whether members can create public repositories and whether repository visibility changes are restricted, and search the audit log for `action:repo.access` which records visibility changes.

*GitLab.* `curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.example.com/api/v4/projects/<id>/members/all"` and compare against the directory of employees.

*What a hit means.* An account with repository access that maps to no current employee and no known contractor. Also treat a private repository that recently became public as a hit even if it looks accidental, because the exposure window is real regardless of intent.

*False positive rate.* High. Contractors, agencies, design partners, and open source maintainers are all legitimate and often undocumented. See [09-outsourced-engineering.md](09-outsourced-engineering.md) if the company uses an outsourced engineering firm, because the account naming there is frequently opaque by default. The hit is an account nobody can name.

### H-9. Administrator sign-ins from unexpected geographies or networks

Compare against where your people actually are. A fully remote company spread over eight countries has no useful geography baseline, and pretending otherwise wastes a day. In that case, pivot to autonomous system number (ASN, the identifier of the network operator an IP address belongs to): sign-ins from a hosting provider or commercial virtual private network ASN are interesting even when the country is expected, because employees usually connect from residential or mobile carrier networks.

*Microsoft Entra ID.* Identity > Monitoring and health > Sign-in logs, filter to your administrator accounts, add the Location and IP address columns, and check the Conditional Access and Authentication requirement columns while you are there.
*Okta.* Reports > System Log, `eventType eq "user.session.start"`, and use the geolocation fields in the event detail.
*Google Workspace.* Reporting > Audit and investigation > Login log events, filter by user and review the IP addresses. Also check the Alert Center for existing suspicious login alerts that were never actioned; unread alerts sitting in the Alert Center are extremely common and occasionally contain the whole answer.
*AWS.* Search CloudTrail for `ConsoleLogin` and read the `sourceIPAddress` and the `additionalEventData.MFAUsed` field. Console logins without MFA are a separate finding for [cs-1-identity-and-access.md](cs-1-identity-and-access.md).

*False positive rate.* High. Travel, VPNs, mobile carrier IP geolocation being wrong by a thousand kilometres, and cloud-hosted browsers all produce noise. Never escalate on geography alone. Escalate on geography plus a second signal: an MFA change, a new OAuth grant, a forwarding rule, or an impossible travel pair.

### H-10. Inbox delegates and mailbox permissions

*Microsoft 365.*

```powershell
Get-Mailbox -ResultSize Unlimited | ForEach-Object {
  Get-MailboxPermission -Identity $_.PrimarySmtpAddress |
    Where-Object { $_.User -notlike "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false } |
    Select-Object Identity, User, AccessRights
}
Get-RecipientPermission -ResultSize Unlimited |
  Where-Object { $_.Trustee -notlike "NT AUTHORITY\SELF" } |
  Select-Object Identity, Trustee, AccessRights
```

In Purview > Audit, search `Add-MailboxPermission`, `Add-RecipientPermission`, and `Add-MailboxFolderPermission`.

*Google Workspace.* Admin console > Apps > Google Workspace > Gmail > User settings, check whether mail delegation is enabled domain-wide, then review delegation per user (or with GAM, `gam all users show delegates` if GAM is already available). Also check Drive sharing settings for whether external sharing and link sharing are unrestricted.

*What a hit means.* Full-access or send-as permission granted to an account that is not an assistant, a shared-mailbox operator, or a documented service. Delegation is quieter than forwarding and lasts longer.

*False positive rate.* Moderate. Executive assistants, shared support mailboxes, and migration tooling all create legitimate delegations.

### H-11. Password resets clustered in time

A burst of resets in a short window is either a help desk being social engineered or an attacker moving laterally. Look at the shape, not the individual events.

*Okta.* System Log, `eventType eq "user.account.reset_password"`, then group by hour.
*Microsoft Entra ID.* Audit logs, activity "Reset user password" and "Change user password", grouped by initiating actor. Also search Purview Audit for `Update StsRefreshTokenValidFrom Timestamp`, which is what a forced sign-out looks like.
*Google Workspace.* Admin log events, filter on password change events, and note the acting administrator.

*What a hit means.* Several resets initiated by the same administrator account in a short window, particularly outside working hours, or resets on accounts that have nothing to do with each other. Also look for a reset performed on an account and then a successful sign-in to that account from a new location shortly afterwards.

*False positive rate.* Moderate. Onboarding a cohort, a policy migration, or an identity provider cutover produce identical shapes. Check the calendar for what the company was doing that week before escalating.

## Ask the human

Closed questions, asked of the CEO or CTO, in private, early:

1. Has this company ever had a security incident, a suspected incident, a near miss, or an event that someone described as "probably nothing"?
2. Has any customer, investor, or partner ever asked whether they were affected by anything?
3. Has anyone here ever received an invoice or wire request that turned out to be fraudulent, or nearly did?
4. Has anyone lost a laptop or phone, or had an account taken over, including a personal account they also used for work?
5. Has any former employee left in circumstances where you were worried about what they still had access to?
6. Was there ever a period where email, cloud, or code host logging was turned off or misconfigured?
7. Do you object to me reading configuration and log metadata across email, identity, cloud, and the code host this week? I am not reading anybody's mail content.

Question 7 matters. Get a yes in writing and put it in `DECISION-LOG.md`.

Copy-pasteable message to the person who currently administers the identity or email system:

> Hi [name], I am doing a one-time baseline check in my first week: I want to confirm nothing unexpected is configured in email and identity, mostly forwarding rules, connected apps, and admin roles. It is all read-only configuration and log metadata, no mail content. Two asks. (1) Can you give me read-only admin access, or if you would rather not, can we spend 45 minutes on a call where you drive and I tell you what to look at? (2) Do you know off the top of your head what our audit log retention is for [Google Workspace / Microsoft 365 / Okta]? That number decides how far back I can look, so it is the one thing I need first. Happy either way, and I will write down whatever we find so you never have to answer this from memory again.

## The walk

**Step 1: Build the retention table.** Goal: know your deadline. Do: the platform-by-platform check at the top of this file. Verify: every row has a source for its number, and you have identified the shortest window. Time: 60 to 90 minutes. Who else: whoever holds admin, for the licence tier answers.

**Step 2: Get read access, or get a driver.** Goal: be able to run the hunts this week. Do: send the message above, and if access is refused or slow, book the screen share instead of waiting. Verify: you can open one audit log yourself, or you have a calendar invite. Time: 30 minutes plus waiting. Who else: the identity or email administrator.

**Step 3: Run H-1, forwarding and inbox rules.** Goal: the single highest-yield check, done on day one. Do: the queries above for your mail platform. Verify: you have a list of every external forward and every hiding rule in the tenant, or an explicit note that the platform prevents the check. Time: 60 minutes, longer if the tenant is large and the inbox rule enumeration is slow. Who else: nobody, if you have access.

**Step 4: Run H-2, audit logging configuration.** Goal: confirm the absence of evidence is not evidence of tampering. Do: the CloudTrail, Cloud Logging, Azure Monitor, and Purview checks. Verify: you can state for each platform whether logging has been continuously on for the retention window. Time: 45 minutes.

**Step 5: Run H-3 through H-6, the identity and cloud persistence hunts.** Goal: find footholds that survive a password change. Do: OAuth grants, MFA changes, privileged role grants, cloud identity and key creation. Verify: every unexplained item has a name attached or is escalated. Time: half a day.

**Step 6: Run H-7 and H-8, the code host hunts.** Goal: find access to source that nobody granted deliberately. Do: keys, tokens, runners, collaborators, visibility changes. Verify: every collaborator maps to a person you can name. Time: two hours. Who else: the engineer who administers the code host, to identify runners.

**Step 7: Run H-9 through H-11, the correlation hunts.** Goal: catch what the state-based hunts missed. Do: sign-in geography and ASN, delegates and mailbox permissions, password reset clustering. Verify: no unexplained pairing of two independent signals on one account. Time: two to three hours.

**Step 8: Write the verdict.** Goal: a durable, dated answer. Do: the Evidence to capture section below. Verify: someone joining in a year could read it and know exactly what was checked and how far back. Time: 45 minutes.

## Decision points

**Run the hunt at all, or get to know people first?**
DEFAULT: run it in week one, unconditionally, in parallel with the intake conversations in [02-intake-questions.md](02-intake-questions.md). The evidence is expiring and the relationships are not. Change this only if you have been explicitly told an active investigation is already running, in which case you join that investigation rather than starting a parallel one.

**Run it quietly, or announce it?**
DEFAULT: tell the CEO or CTO and the system administrator, and nobody else, until you have a result. This is not secrecy for its own sake; it is that a company-wide "I am checking whether we have been hacked" message produces a week of anxious speculation and, if there is an intruder, warns them. Change this if the company culture is aggressively transparent and the executives prefer to announce it as routine hygiene, which is a legitimate choice, but make it their choice and log it in `DECISION-LOG.md`.

**Escalate on a single ambiguous signal, or wait for a second?**
DEFAULT: for H-1 and H-2, escalate on one signal, because the false positive profile is low and the cost of being late is high. For H-9 (geography), never escalate on one signal. For everything else, escalate when you cannot attribute the item to a named human after one careful check that does not involve contacting the account under suspicion.

**Bring in outside help?**
DEFAULT: no, not for the hunt itself. This is a day of read-only queries and you can do it. Bring in outside digital forensics and incident response only after DR-1 is open and only with the approvals described there. If the company has cyber insurance, check the panel requirement before calling anyone, because using a non-panel firm can void coverage.

**Extend retention now, because it is short?**
DEFAULT: no, not mid-hunt. Note it in `RISK-REGISTER.md` and handle it deliberately in DR-3. The exception is when you have an active hit, in which case exporting the short-window source right now is part of preservation, and the export is a containment-adjacent action that needs the same explicit yes as anything else that costs money.

## Danger zone

Each of these requires an explicit human yes, spoken or written, before you do it. The only exception is the single named one at the end of this section, and the yes must come from a person, not from another agent and not from an earlier instruction in this file.

- **Any active scan or test of any system, including the company's own.** Port scanning, credential testing, web vulnerability scanning, phishing simulation, or "just seeing if this login works" without written authorisation. Nothing in this file requires it. Breaks: potentially the law, certainly a cloud provider's acceptable use policy, and possibly production.
- **Disabling, suspending, or resetting any account.** Breaks: the person's ability to work, and if the account is the recovery contact for the identity provider or the cloud root account, potentially the entire company's ability to recover. Confirm break-glass access exists and is tested first.
- **Revoking an OAuth grant, a token, a deploy key, or a session.** Breaks: whatever integration depended on it, silently and often in a way nobody notices for a day. Also tips off an attacker.
- **Rotating any credential production uses.** Breaks: production. See [se-3-secrets-and-keys.md](se-3-secrets-and-keys.md).
- **Changing anyone's access, roles, or authentication requirements, including enforcing MFA, conditional access, or device compliance on a population.** Breaks: sign-in for anyone whose device or method does not meet the new rule, all at once, usually including you.
- **Enrolling or wiping a device.** Breaks: the device, and possibly personal data on it, with employment-law consequences.
- **Reading the content of anyone's mailbox, files, or messages.** Metadata and rule configuration is administration. Content is an investigation with employment-law, works-council, and privacy implications that vary by country. Requires the CEO's yes, and often counsel's.
- **Enabling a new log source, such as Google Cloud Data Access audit logs or verbose cloud audit logging.** Breaks: the bill. Data Access logging on a busy project can be a very large monthly increase.
- **Exporting logs or mailbox data to your own laptop or to any third party tool.** Creates a new copy of sensitive data outside the company's controls. Keep exports inside `.security/evidence/` on a company-managed device, or better, inside a company storage location the CEO has approved.
- **Telling anyone outside the CEO, CTO, and the system administrator what you are doing or what you found.** Includes the whole-company channel, the affected employee, a customer, and an investor. Publishing anything externally, or telling a customer that a control exists or that they were or were not affected, is a decision for the incident process in DR-1 with executive and legal sign-off.
- **Buying anything.** No tools are required for this cell.

Narrow pre-authorisation, and only this: during a **declared** incident (DR-1 open, incident commander named), and only where the standing pre-authorisation in step 10 of [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md) was agreed in advance and recorded in `DECISION-LOG.md`, two containment actions may proceed on the incident commander's authority. They are revoking a named human user's active sessions and refresh tokens, and revoking a third party application's access grant. Those two and nothing else, and if that pre-authorisation was never agreed there is no exception and you ask. Separately, and regardless of who gave the yes, during containment do not reboot or terminate a host, do not delete the malicious file, email, or package, and do not close the account under investigation, because those destroy the record rather than limit the access. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.

## Do not do this yet

- Do not build a repeatable, scheduled, automated hunt. This is a one-time baseline. Ongoing detection is [dr-2-top-security-signals.md](dr-2-top-security-signals.md) and it is a different design problem.
- Do not buy a security information and event management platform to run these queries. Every query above runs in a native console or a free command line tool.
- Do not attempt disk imaging, memory capture, or malware reverse engineering. If you need those, you need DR-1 and probably an outside firm.
- Do not compare anything against a commercial threat intelligence feed. At this stage the signal you need is "nobody can explain this", not "this IP appeared on a list".
- Do not expand the hunt into a full access review of every system. Identity hygiene is [cs-1-identity-and-access.md](cs-1-identity-and-access.md) and it is a bigger, slower, more political piece of work.
- Do not audit the personal accounts of employees. Out of scope, and in most jurisdictions out of bounds.
- Do not turn a clean result into a claim you cannot support, such as telling a customer the company has never been breached. You checked what the logs retain. Say exactly that.

## Evidence to capture

**When the hunt is clean.** This is the deliverable, and it is worth more than it looks. Write, in `SECURITY-STATE.md` under the DR-0 row, a statement in this shape, then set the DR-0 status to `done`:

> Compromise assessment completed [date]. Checked: mail forwarding and inbox rules, mailbox delegates and permissions, third party OAuth grants, MFA method changes, privileged role grants, cloud identity and access key creation, code host keys, tokens, runners and collaborators, admin sign-in locations, audit logging configuration changes, and password reset clustering. Platforms: [list]. No unexplained findings. Evidence depth: this result covers back to [date], limited by the shortest retention window ([source], [N] days). Anything before that date is unknown and unknowable from current logs. Run by [name], access used: [role], recorded in ACCESS-LOG.md.

The "evidence depth" sentence is the important one. It converts "we think we are fine" into "we can prove nothing bad is visible since 12 March, and we cannot see further back". A future customer questionnaire, a future auditor, and your own successor will all want that sentence, and only you can write it, because after retention rolls over nobody can reconstruct it.

Also record: the retention table (`SECURITY-STATE.md`), any short-retention source as an open item with a review date (`RISK-REGISTER.md`), the authorisation to run the hunt and any scope decisions (`DECISION-LOG.md`), and the admin access granted, by whom, when, and whether it was removed afterwards (`ACCESS-LOG.md`). Keep raw exports in `.security/evidence/` with the query and the timestamp in the filename.

**When you find a hit.** The incident file at `.security/incidents/INC-<YYYY>-<NNN>-<slug>.md` becomes the record and DR-1 governs it. Capture, before anything changes: a screenshot or export of the finding exactly as displayed, the full timestamp with timezone, the query or console path that produced it, and who else was in the room. Then stop.

**When you find evidence of a past compromise nobody disclosed.** This happens, and it is the most delicate situation in this file. Route to [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md) and treat it as an incident that predates you, because the response process is the same even though the urgency differs. Three specific cautions:

- **Be careful what you write down, and where.** You may be creating a document that is later read by a regulator, a plaintiff, an acquirer's diligence team, or opposing counsel. Write facts and timestamps. Do not write legal conclusions ("we were breached and failed to notify"), do not write speculation about intent, and do not write characterisations of colleagues. Ask the CEO early whether they want counsel involved, because in some jurisdictions bringing counsel in early changes the privilege status of what you produce afterwards. That is a lawyer's call, not yours, and asking the question is the whole of your responsibility.
- **Distinguish "not disclosed" from "not detected".** Most of the time nobody covered anything up; nobody knew. Assume that until facts say otherwise, and say it out loud when you brief, because the first thing a founder hears in "I found evidence of a past compromise" is an accusation.
- **There may still be a live notification obligation.** Some breach notification duties run from discovery, not from occurrence, and some customer contracts contain notification clauses with their own clocks. Check [co-3-existing-commitments.md](co-3-existing-commitments.md) for what the company has already promised, and get counsel's answer before anyone decides that an old event is a closed matter. That decision is not yours and it is not the CTO's.

## Cost and effort

One to two days of your time, in week one. Zero dollars: every query above uses a native admin console, a vendor command line tool you already have, or a free community tool that is already installed or can be skipped.

The costs that can appear: enabling Google Cloud Data Access audit logs or a similar verbose source (potentially hundreds to thousands of US dollars per month, needs a yes, and belongs to DR-3 rather than here), a licence uplift to see the logs at all (Microsoft Entra ID P1 to get 30 days of sign-in logs instead of 7, commonly a few US dollars per user per month; Microsoft Purview Audit Premium for longer retention), and, only if you find something real, digital forensics and incident response engagement (commonly 25,000 US dollars and up, an executive decision, and check the cyber insurance panel first).

## Failure modes

- **The hunt never happens because access never arrives.** Early tell: three days in and you are still waiting on an admin invite. Recovery: stop waiting and book the screen share. A driven session with the current administrator produces the same evidence and builds the relationship. Record it in `ACCESS-LOG.md` as blocked, with the name.
- **You find something and immediately fix it.** Early tell: you catch yourself reaching for the delete button on a forwarding rule. Recovery: hands off, screenshot, escalate. If you already deleted it, say so immediately and in writing; a known gap in the evidence is recoverable, a silent one is not.
- **You escalate on noise and lose credibility.** Early tell: your first escalation is a geography anomaly on a salesperson who is at a conference. Recovery: apply the correlation rule (never escalate on H-9 alone), and when you do escalate, lead with what you checked and ruled out, not with the alarm.
- **The hunt turns into a three-week project.** Early tell: you are building a dashboard, writing a script framework, or normalising log formats. Recovery: this is a two-day, read-only, manual pass. The tooling instinct is right in general and wrong here, because the retention clock is the constraint, not query ergonomics.
- **You mistake "logging was off" for "nothing happened".** Early tell: a platform with no findings and no logs. Recovery: mark that platform's result as unknown, not clean, in `SECURITY-STATE.md`, and say so in the verdict statement. An unknown honestly recorded is worth more than a clean result you invented.
- **A hit arrives while you are mid-hunt on something else and you finish the hunt first.** Early tell: the thought "let me just finish this query". Recovery: none needed if you catch it. Stop, and open DR-1.
- **Somebody asks you to confirm the company has never been breached.** Early tell: a sales colleague forwarding you a customer email. Recovery: answer only with the evidence-depth statement, and route the request through [co-2-questionnaire-knowledge-base.md](co-2-questionnaire-knowledge-base.md) so the answer is consistent and recorded.

## Related cells

- [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md): where every hit in this file goes, immediately, including a compromise that predates you.
- [dr-2-top-security-signals.md](dr-2-top-security-signals.md): the same signal families turned into ongoing detection instead of a one-time look backwards.
- [dr-3-logging-consumption-model.md](dr-3-logging-consumption-model.md): why the retention windows are what they are, and what it costs to widen them.
- [00-cold-start.md](00-cold-start.md): the first session flow that loads this file.
- [01-recon.md](01-recon.md): the inventory work this hunt runs alongside, and which stops the moment a hit is confirmed.
- [02-intake-questions.md](02-intake-questions.md): the intake answer about why they are hiring now, which is the trigger that makes this cell urgent rather than routine.
- [cs-1-identity-and-access.md](cs-1-identity-and-access.md): where over-granted admin, missing MFA, and stale accounts get fixed properly rather than noted in passing.
- [cs-3-onboarding-offboarding.md](cs-3-onboarding-offboarding.md): the leaver checklist that should catch forwarding rules on an ongoing basis so this hunt never needs repeating in full.
- [se-3-secrets-and-keys.md](se-3-secrets-and-keys.md): what to do about the long-lived keys and tokens this hunt surfaces.
- [co-3-existing-commitments.md](co-3-existing-commitments.md): the notification clauses that decide whether an old, undisclosed event still carries an obligation.
- [09-outsourced-engineering.md](09-outsourced-engineering.md): why an outsourced engineering firm makes the external collaborator hunt noisier, and how to read it.
