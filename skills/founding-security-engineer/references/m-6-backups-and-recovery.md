# M-6: Backups and recovery

> **Grid coordinate:** M-6, modern cells, the sixth addition to Evan Johnson's 2019 grid. It has no 2019 ancestor cell, in the same way M-3 (cloud posture) has none.
> **Load when:** anything in this company points at losing data rather than leaking it. Concretely: someone asks about backups, restores, disaster recovery, business continuity, recovery time objective, recovery point objective, ransomware, or immutability; a questionnaire or contract asks you to state a recovery time; you are about to publish an availability or resilience claim on a public page; a destructive event has happened or is happening (deleted database, emptied bucket, wiped drive, extortion note); or a finding elsewhere shows that the identity which runs production also holds deletion rights over the backups. Do not load this file for confidentiality-only questions, which belong to CS-1, SE-3, or M-3.

## Why this cell exists

Almost every other cell in this playbook is about someone reading data they should not read. This one is about the data not being there any more. That failure kills companies faster, because a startup that leaks a customer list has a bad quarter and a startup that loses its production database has no product. Two other files in this skill already assume you have done this work: `co-1-public-security-docs.md` tells you to publish backup frequency and whether restores are tested, and `co-2-questionnaire-knowledge-base.md` gives you a questionnaire answer with a recovery time objective and a recovery point objective in it. Nothing else teaches you how to obtain those numbers honestly. This file closes that gap.

There are exactly three questions you must be able to answer, and you should be able to answer all three by the end of your second week.

1. **What would we lose?** If the primary datastore vanished right now, which data comes back, from when, and which data never comes back at all.
2. **How long would it take to get it back?** Not the vendor's marketing number. A number you measured with a stopwatch.
3. **Can the identity that runs production also delete the backups?** This is the question nobody asks and it is the one that matters. The threat model this skill teaches everywhere else (a stolen browser session, then the software as a service tools, then the cloud account) ends with an attacker holding the same rights your deploy pipeline holds. If those rights include deleting snapshots, your backup strategy is a copy of the problem rather than a solution to it.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A written list in `SECURITY-STATE.md` of every datastore and content store that matters, each with an owner, whether it is backed up, by what mechanism, and the retention in days.
- [ ] The primary production datastore has automated backups on, with point in time recovery enabled if the platform supports it, and a retention window of at least 30 days.
- [ ] At least one copy of the primary datastore lives outside the blast radius of the production account, project, or subscription, reachable with a credential that production does not hold.
- [ ] That copy is immutable, or the credential that can delete it is held by a different human than the one who runs deploys, and either way the arrangement is written down and someone else has read it.
- [ ] You know who holds the encryption key for every backup copy, and you have confirmed that losing the production account does not lose the key.
- [ ] A timed restore drill has been run at least once, into a scratch environment, and the measured wall clock time is recorded with a date and the name of who ran it.
- [ ] The recovery time objective and recovery point objective published anywhere externally match the drill result, rounded conservatively in the pessimistic direction.
- [ ] The software as a service systems that would hurt to lose (code host, identity directory, customer relationship management system, document platform, ticketing, password manager) each have either a native export on a schedule, or a written and accepted decision that you rely on the vendor.
- [ ] A destructive event runbook exists, is one page, is linked from the incident plan in `dr-1-incident-response-plan.md`, and exists in a form readable when the cloud account is unavailable.
- [ ] The security program state directory itself is backed up somewhere the company can reach without you.

Explicitly **not** required at this size: a warm standby region, a formally certified business continuity management system, a disaster recovery site, quarterly full-company failover exercises, a backup appliance, a dedicated backup vendor contract, a documented crisis management committee, or an availability commitment in a service level agreement. If a vendor tells you a first security hire needs any of those, they are selling to a company that is not yours.

## Discovery

Everything below is read only. Nothing here changes a configuration. If a command fails because you lack permission, that failure is itself a finding: record it in `ACCESS-LOG.md` and ask for the specific role named in `m-3` guidance inside `references/07-modern-cells.md`.

**Step zero, no cloud access at all.** You can get most of the picture by interview and by reading the infrastructure code. Search the repository for backup configuration in whatever infrastructure as code tool is present:

```
grep -rn -i "backup_retention\|point_in_time\|pitr\|versioning\|deletion_protection\|prevent_destroy\|object_lock\|retention_polic" --include=*.tf --include=*.tf.json --include=*.yaml --include=*.yml --include=*.json .
```

Absence of matches is not evidence that backups are off. It is evidence that backups are not managed as code, which means someone clicked them on in a console and nobody can tell you when.

**Amazon Web Services.** Managed relational databases first, because that is where the company lives.

```
aws rds describe-db-instances --query 'DBInstances[].{id:DBInstanceIdentifier,retentionDays:BackupRetentionPeriod,window:PreferredBackupWindow,multiAZ:MultiAZ,deleteProtect:DeletionProtection,latestRestorable:LatestRestorableTime}' --output table
aws rds describe-db-clusters --query 'DBClusters[].{id:DBClusterIdentifier,retentionDays:BackupRetentionPeriod,deleteProtect:DeletionProtection,earliest:EarliestRestorableTime,latest:LatestRestorableTime}' --output table
aws rds describe-db-snapshots --snapshot-type manual --query 'DBSnapshots[].{id:DBSnapshotIdentifier,created:SnapshotCreateTime,encrypted:Encrypted}' --output table
```

A `retentionDays` of `0` means automated backups are **off** and point in time recovery does not exist for that instance. On Aurora clusters, the gap between `EarliestRestorableTime` and `LatestRestorableTime` is your actual recoverable window, and it is the only number worth quoting. Note the platform ceiling: automated backup retention on Amazon Relational Database Service tops out at 35 days, so anything longer needs manual snapshots or AWS Backup.

Object storage and key value stores:

```
aws s3api list-buckets --query 'Buckets[].Name' --output text
aws s3api get-bucket-versioning --bucket BUCKET
aws s3api get-object-lock-configuration --bucket BUCKET
aws s3api get-bucket-lifecycle-configuration --bucket BUCKET
aws s3api get-bucket-replication --bucket BUCKET
aws dynamodb list-tables --output text
aws dynamodb describe-continuous-backups --table-name TABLE
```

`get-object-lock-configuration` returning an error of `ObjectLockConfigurationNotFoundError` means Object Lock is not enabled, which is the normal answer and not yet a problem. Versioning returning empty output means versioning has never been enabled, which is a problem for any bucket holding customer content, because a single overwrite is then permanent.

Backup service and vault policy, which is where the third question gets answered:

```
aws backup list-backup-vaults --output table
aws backup describe-backup-vault --backup-vault-name VAULT --query '{locked:Locked,lockDate:LockDate,minRetention:MinRetentionDays,maxRetention:MaxRetentionDays,numRecoveryPoints:NumberOfRecoveryPoints}'
aws backup get-backup-vault-access-policy --backup-vault-name VAULT
aws backup list-backup-plans --output table
aws backup list-protected-resources --output table
```

Reading that output: `Locked` true only tells you a vault lock exists, not which mode it is in. A `LockDate` is the end of the compliance mode cooling off period, so a lock that reports one is a compliance mode lock and becomes permanent on that date. A governance mode lock reports `Locked` true with no cooling off period and can be removed by a principal holding `backup:DeleteBackupVaultLockConfiguration`.

Then answer the deletion question directly. Take the role your deploy pipeline assumes (you found it in M-2 work) and simulate the destructive calls rather than making them:

```
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::ACCOUNT:role/DEPLOY_ROLE --action-names rds:DeleteDBSnapshot rds:DeleteDBInstance backup:DeleteRecoveryPoint backup:DeleteBackupVault s3:DeleteObjectVersion s3:PutBucketVersioning kms:ScheduleKeyDeletion --output table
```

`allowed` on any of those, from an identity that a stolen session can reach, is a finding worth writing into `RISK-REGISTER.md` today.

**Google Cloud.**

```
gcloud sql instances list --format="table(name,databaseVersion,settings.backupConfiguration.enabled,settings.backupConfiguration.pointInTimeRecoveryEnabled,settings.backupConfiguration.transactionLogRetentionDays,settings.backupConfiguration.backupRetentionSettings.retainedBackups)"
gcloud sql backups list --instance INSTANCE
gcloud storage buckets list --format="value(name)"
gcloud storage buckets describe gs://BUCKET --format="json(versioning,retentionPolicy,lifecycle,softDeletePolicy,defaultKmsKeyName)"
gcloud firestore databases describe --database='(default)' --format="json(pointInTimeRecoveryEnablement,deleteProtectionState)"
```

On Cloud SQL, `pointInTimeRecoveryEnabled` false means your recovery point objective is the gap between scheduled backups, typically 24 hours, no matter what anyone tells sales. On Cloud Storage, `retentionPolicy.isLocked` true means the retention policy is permanent and can only be lengthened, never shortened or removed. Read that field before you touch anything. If `softDeletePolicy` is present, note its duration: it is a short automatic safety net for deletions, not a backup.

To answer the deletion question on Google Cloud, look at who holds `storage.admin`, `cloudsql.admin`, `cloudsql.editor`, and any custom role containing `storage.objects.delete` or `cloudsql.backupRuns.delete`:

```
gcloud projects get-iam-policy PROJECT_ID --format=json
gcloud iam service-accounts list --project PROJECT_ID
```

**Microsoft Azure.**

```
az sql db list --resource-group RG --server SERVER --query '[].{name:name,earliestRestore:earliestRestoreDate}' -o table
az sql db str-policy show --resource-group RG --server SERVER --name DB
az sql db ltr-policy show --resource-group RG --server SERVER --name DB
az storage account blob-service-properties show --account-name ACCOUNT --resource-group RG
az storage container immutability-policy show --account-name ACCOUNT --container-name CONTAINER --resource-group RG
az backup vault list -o table
az backup vault backup-properties show --name VAULT --resource-group RG
az backup item list --vault-name VAULT --resource-group RG -o table
```

`az sql db str-policy show` returns the short term retention in days, which is your point in time recovery window for Azure SQL Database and ranges from 1 to 35 days. `blob-service-properties` tells you `isVersioningEnabled`, the blob and container soft delete retention, and whether point in time restore is configured. For immutable vault settings, use the portal path Recovery Services vault, then Properties, then Immutable vault, rather than guessing at a command line flag.

**The ones people forget.** Every one of these has an export path that does not require buying anything. Ask for each: what would we lose, and how would we get it back.

| System | What you lose | Native export path |
| --- | --- | --- |
| Code host (GitHub) | Issues, pull request discussion, Actions configuration, org settings. Git history itself is on every laptop. | `gh repo list ORG --limit 1000 --json sshUrl -q '.[].sshUrl'` piped into `git clone --mirror` for code. For the metadata a mirror clone does not carry, use the organization migration application programming interface under `/orgs/ORG/migrations`, or the Settings, then Migrations export in the web console. |
| Code host (GitLab) | Same, plus continuous integration variables. | Group export and project export via the representational state transfer application programming interface at `POST /groups/:id/export` and `POST /projects/:id/export`, then download the archive. Console path: Settings, then General, then Advanced, then Export. |
| Identity directory (Google Workspace) | User records, groups, mail, drive content. | Admin console, then Data, then Data Export, for a full workspace export. Google Vault for retention and targeted export. |
| Identity directory (Microsoft 365) | Mail, SharePoint and OneDrive content, Teams messages. | Purview retention policies plus eDiscovery export. Note that recycle bins and retention policies are not backups: they expire. |
| Identity directory (Okta or JumpCloud) | The directory configuration itself, which is hard to rebuild from memory. | Scripted read only application programming interface dump of users, groups, applications, and policies to JavaScript Object Notation, stored with the other backups. There is no vendor restore button for a deleted org. |
| Customer relationship management | Pipeline, contacts, the sales history the company runs on. | Salesforce: Setup, then Data Export, scheduled weekly or monthly. HubSpot: Settings, then Account Defaults, then Export all data. |
| Document platform | The actual institutional memory of the company. | Notion: Settings, then Workspace, then Export all workspace content. Confluence: space export, or the backup manager for a full site archive. |
| Ticketing | Roadmap and customer issue history. | Jira: Settings, then System, then Backup manager. Linear: Settings, then Workspace, then Export. |
| Password manager | Everything, if it is the only copy of a break glass credential. | Do not schedule plaintext exports. Instead confirm every vault has at least two administrators, that recovery is possible without any single person, and that break glass material also exists offline as described in `cs-1-identity-and-access.md`. |
| A laptop | Whatever the one copy was. | Ask directly. The answer "it is on my machine" appears at least once in every company. |

**The single copy question.** Ask in the company channel from `dr-4-company-comms-channel.md`: is there anything important that exists in exactly one place. You will get answers that no scan produces. Write each into `SECURITY-STATE.md`.

## Ask the human

Ask these one at a time, as closed questions, and write the answers into `SECURITY-STATE.md` under an M-6 heading.

1. If the production database disappeared right now, who is the person who would fix it, and are they on call today?
2. Has anyone in the company ever restored that database from a backup? Yes or no. If yes, when, and did they time it?
3. Is there any copy of production data in a different cloud account, project, or subscription from production? Yes, no, or unknown.
4. Does the credential our deploy pipeline uses have permission to delete backups or snapshots? Yes, no, or unknown.
5. Have we told any customer, in a contract, an order form, a security page, or a questionnaire, how quickly we can recover? Yes or no. If yes, what number did we give and who gave it?
6. Is there a business we could not run without, whose data lives only in a software as a service tool we do not export?
7. What is the largest amount of data loss the chief executive would accept in a disaster: an hour, a day, a week?

Question 7 is the recovery point objective, in the only language a founder actually thinks in. Do not ask for a recovery point objective by name.

**Message to send an engineer.** Copy and paste this, adjusting the vendor names:

> Quick one and there is no wrong answer, I am building the picture rather than auditing anyone. Three things about our data: (1) is the production database on automated backups, and if so how many days back can we go, (2) is there any copy of it that lives outside our main cloud account, and (3) has anyone ever actually restored it, as opposed to trusting that we could. If the answer to any of them is "I think so", that is a completely fine answer and I will go and check.

**Message to send the person who owns finance or operations.** Use this when you are chasing the software as a service side:

> I am putting together a short list of systems where losing the data would genuinely hurt us, so we can make sure each one has an export or a decision that we are fine relying on the vendor. Could you send me the list of software subscriptions we pay for? I do not need amounts, just names. I will do the rest.

## The walk

Each step below stands alone and leaves the company better off than it found it. Do not start at step 6.

**Step 1: Name the crown jewel datastore and read its backup configuration.**
Goal: replace a vague worry with one specific fact.
Do: run the provider commands above against the single datastore that holds customer data. If there are several, pick the one whose loss would end the company.
Verify: you can state, out loud, "we can restore to any point in the last N days, and the last successful backup completed at TIME".
Time: 30 to 60 minutes.
Who else: an engineer with cloud read access if you do not have your own yet.

**Step 2: Turn the answer into a written recovery point objective, unpublished.**
Goal: a number that is honest because it is derived from configuration rather than hope.
Do: write in `SECURITY-STATE.md` the recovery point objective implied by the configuration. Point in time recovery enabled gives you minutes. Daily snapshots only give you up to 24 hours. Mark it `derived from configuration, not yet drill tested`.
Verify: the entry has that exact caveat on it.
Time: 15 minutes.

**Step 3: Find out whether the production identity can delete the backups.**
Goal: answer question three of the three.
Do: run the policy simulation or the identity and access management policy read from Discovery, for the deploy role, the continuous integration role, and any human with administrator rights.
Verify: you have a yes or no per identity, with the command output saved into `evidence/`.
Time: 45 minutes.
Who else: nobody, this is read only.

**Step 4: Get one copy out of the blast radius.**
Goal: a copy that survives the compromise or the deletion of the production account.
Do: this is a mutating change and needs an explicit human yes plus an engineer to make it. The cheap patterns, in order of preference: an AWS Backup copy action into a vault in a separate account with a vault access policy that denies deletion to everyone except a named break glass role; a Cloud SQL export to a Cloud Storage bucket in a separate Google Cloud project with a retention policy; an Azure Backup copy into a Recovery Services vault in a separate subscription. If your company has none of that, a scheduled dump written to storage in a second account is still a real improvement and takes an afternoon.
Verify: from production credentials, attempt a read of the destination and confirm it fails or is read only. Then from the break glass credential confirm the object exists and its size is plausible.
Time: half a day to two days depending on how the pipeline is built.
Who else: the engineer who owns infrastructure, and whoever approves cloud spend.

**Step 5: Make the copy hard to delete.**
Goal: immutability, so that a compromised production identity cannot destroy the only thing that saves you.
Do: on AWS, Object Lock in **governance** mode on the destination bucket, and AWS Backup Vault Lock in **governance** mode on the destination vault. Vault Lock has exactly two modes and there is no unlocked state. Applying it without the `ChangeableForDays` parameter creates a governance mode lock: `Locked` reads true, and a principal holding `backup:DeleteBackupVaultLockConfiguration` can still remove it. Applying it with `ChangeableForDays`, whose minimum is 3 days, creates a compliance mode lock, which becomes immutable once that grace period elapses and cannot then be changed or deleted by any user or by AWS. On Google Cloud, a retention policy on the destination bucket, left **unlocked**, which can still be increased, decreased, or removed. On Azure, a time based immutability policy left **unlocked**, which can still be shortened, lengthened, or deleted. Compliance mode and locked retention policies are the irreversible one way doors covered by the hard stop in `SKILL.md`. They are not applied until the retention behaviour has been observed on the governance mode or unlocked version and that hard stop has been cleared with a written yes. Read the Danger zone section before you consider locking any of them.
Verify: attempt to delete a test object with the production identity and confirm the denial.
Time: two hours.
Who else: the infrastructure owner. This is a mutating change and needs an explicit human yes.

**Step 6: Confirm who holds the key.**
Goal: make sure the backup is not encrypted with a key that dies with the account it is protecting against.
Do: identify the key protecting each backup copy. On AWS, cross account snapshot copies require a customer managed key in the key management service, and an AWS managed key cannot be shared across accounts, so a snapshot encrypted with `aws/rds` cannot be copied to another account at all. On Google Cloud, check `defaultKmsKeyName` on the destination bucket. On Azure, check whether the storage account uses a customer managed key and where that key vault lives.
Verify: write into `SECURITY-STATE.md` the key identifier, the account or project that holds it, and who can schedule its deletion.
Time: one to two hours.

**Step 7: Run the timed restore drill.**
Goal: the number. This step is the whole cell.

> **STOP.** This is the most dangerous action in this file and it needs a gate the three steps above it also have. A restore creates infrastructure, costs real money, can page on-call, can place real customer data into an environment with weaker controls than production, and destroys live data if the target identifier is wrong. Get an explicit human yes from the engineer who owns the datastore **and** from whoever approves cloud spend. Before starting, write down and read back three things: the exact target identifier, which must not already exist; the estimated cost for the day; and whether the scratch environment's access controls match production. If they do not match, the drill runs on masked or synthetic data, not on a real backup.

Do: pick a scratch environment that is not production and cannot reach production. Start a stopwatch at the moment you decide to restore. Restore the most recent backup into the scratch environment. Stop the watch when a query against the restored data returns correct results. Record, separately: time to initiate, time until the platform reported the restore complete, time until the data was actually usable, who was needed, what credential was missing, and what step nobody had written down.
Verify: an entry in `SECURITY-STATE.md` with a date, a duration, and a named person, plus the raw notes in `evidence/`.
Time: half a day, most of which is waiting.
Who else: the engineer who owns the datastore, plus whoever approves cloud spend. Tell them in advance and treat it as a joint exercise rather than a test of them.

**Step 8: Publish nothing until step 7 has produced a number.**
Goal: keep the company out of a contractual problem.
Do: set this as a rule and write it into `DECISION-LOG.md`. No public availability claim in `co-1-public-security-docs.md`, and no recovery time objective or recovery point objective in `co-2-questionnaire-knowledge-base.md`, is written before a drill has produced a measured time. Round the drill result upward, generously, before it leaves the building. If a drill took four hours on a good day with the right person available, the external number is not four hours.
Verify: the questionnaire knowledge base entry cites the drill date.
Time: 15 minutes.

**Step 9: Extend the same thinking to the two or three software as a service systems that matter.**
Goal: stop the export gap being invisible.
Do: use the table in Discovery. For each system, either schedule the native export to a storage location you control, or write an explicit accepted decision in `RISK-REGISTER.md` that the company relies on the vendor, with a review date.
Verify: each system in the list has either an export path or a dated accepted risk. There is no third state.
Time: a day, spread across a week of chasing people.

**Step 10: Write the destructive event runbook and back up the program itself.**
Goal: be able to act when the systems holding your notes are the systems that are gone.
Do: write the one page runbook from the section below, link it from the incident plan, and make sure a copy exists outside the affected systems. Back up `.security/` itself: a private repository with restricted access is usually the right answer, since the directory contains findings, access notes, and risk detail that should not be broadly readable. Print the incident plan and this runbook on paper, or store them in a personal password manager entry. During a real destructive event the document platform may be exactly what is unavailable.
Verify: a second person can find and open the runbook without you.
Time: two hours.

## Decision points

**Cloud native backup service, or scripted dumps?**
Default: the cloud native service (AWS Backup, Cloud SQL scheduled backups plus exports, Azure Backup). It is auditable, has retention policy support, and does not depend on a script somebody wrote in 2023. Change it when your datastore is self managed on virtual machines, or when you need a logical export in a portable format for a migration or a legal hold, in which case run both.

**Governance mode or compliance mode for object immutability?**
Default: governance mode, always, at this company size. It stops a compromised production identity and an accidental script, which is the entire threat you are defending against, while leaving a named break glass identity able to correct a mistake. The same two modes exist on AWS Backup Vault Lock, where governance mode is the reversible one and compliance mode is the permanent one, and the same default applies. Change it only when a specific written regulatory obligation or a signed contract names write once read many storage, and only after counsel has read the retention period you intend to set.

**Retention length?**
Default: 30 to 35 days for the primary datastore, which is the platform maximum on several services anyway, plus one monthly copy retained for 12 months if and only if a contract or a legal obligation requires it. Set retention by the time it takes to notice a compromise, not by superstition or by a round number that looks reassuring. Published incident research consistently puts the time between initial intrusion and detection in the range of a week to a month or more for many intrusions, so a seven day window means that in a plausible number of cases the last clean copy has already aged out by the time you know you need it. Change it upward if you have measurable detection gaps, or downward only if storage cost is genuinely material and you have written that trade off down.

**Same region or different region for the second copy?**
Default: different account or project, same region. Account separation defeats the credential compromise threat, which is the one you actually face. Regional separation defeats a regional outage, which is rarer and more expensive to defend against. Change it when a customer contract or a data residency commitment recorded in `co-3-existing-commitments.md` requires it, or when a single region outage would itself be an existential event for the product.

**Who runs the restore drill?**
Default: the engineer who owns the datastore runs it, and you observe and time it. That builds the muscle in the right place and avoids the drill becoming a security theatre exercise. Change it when the owner is the single point of failure you are trying to test, in which case have someone else run it and let the owner watch in silence.

**Do you back up software as a service systems, or accept the vendor's protection?**
Default: accept the vendor's protection for most systems, and export the two or three whose loss would stop the business. Wholesale software as a service backup products exist and start around 3 to 8 dollars per user per month, which is real money at 80 people for a risk that mostly manifests as an accidental deletion the vendor's own recycle bin already covers. Change it when a system holds the only copy of revenue critical data, or when a contract obliges you to be able to produce records independently of the vendor.

## Danger zone

Every action in this list requires an explicit human yes before you take it. State the risk in plain words, get the word yes, and record it in `DECISION-LOG.md`.

- **Restoring over live data.** This is the single most common way a backup project causes the outage it was meant to prevent. Restoring in place typically replaces the current data with the older copy, and everything written since the backup is gone permanently. Always restore to a new instance, a new bucket prefix, or a new database name, and cut over deliberately afterwards. Never point a restore at the running production identifier.
- **Testing a restore into production.** A drill that touches production is not a drill, it is an incident with a schedule. Use a scratch environment. If no scratch environment exists, creating one is the prerequisite step, not an optional extra.
- **Enabling Object Lock in compliance mode.** Read this twice. In compliance mode, no identity can shorten or remove the retention period, including the account root user and including the person who set it, until the retention expires. If you apply a default retention of several years to a bucket that receives large volumes, you have committed the company to paying for that storage for those years with no way out, and you have made it impossible to honour a customer deletion request for objects in that bucket for the whole period. The same permanence applies to a locked Google Cloud Storage bucket retention policy (it can only be lengthened, never shortened or removed) and to a locked Azure immutability policy, and to AWS Backup Vault Lock once its grace period has elapsed. The default answer at a startup is governance mode on S3 Object Lock and on AWS Backup Vault Lock, and an unlocked retention or immutability policy on Google Cloud and Azure. Vault Lock has no unlocked state, so governance mode is the reversible starting point and it is what step 5 of the walk tells you to apply. If someone insists on compliance mode, the questions to ask before anyone clicks are: exactly which contract or regulation requires it, what retention period does that text specify, what is the projected volume over that period at current pricing, and has counsel confirmed it does not conflict with a deletion obligation.
- **Snapshot and cross region copy costs that surprise finance.** Backup storage, cross account copies, and cross region replication all bill. As rough orders of magnitude, general purpose object storage sits near two cents per gigabyte per month and archive tiers near a tenth of a cent, and cross region transfer is charged per gigabyte moved. A terabyte scale dataset copied nightly with 35 day retention is not a rounding error. Model the monthly cost before enabling anything, tell whoever owns the budget the number, and get a yes. Confirm current prices against the provider's calculator rather than trusting these figures.
- **Enabling a new backup schedule on a busy production database** during business hours, which can affect performance. Schedule it with the owner.
- **Rotating or deleting an encryption key** that a backup depends on. Scheduling a key management service key for deletion silently destroys the ability to read every backup encrypted with it. This is irreversible after the waiting period ends.
- **Deleting old snapshots to save money.** Never as a cleanup task. Only with the owner's explicit yes, after confirming no retention obligation applies, and never during an open incident.
- **Turning on multi factor authentication delete for object storage,** which on AWS requires the account root user and long lived root credentials. Usually the wrong trade at this size. Discuss before doing.
- **Any restore, export, or drill involving real customer data** placed into an environment with weaker access controls than production. That is a confidentiality incident wearing a recovery costume. If the scratch environment is less protected, the drill uses masked or synthetic data, or the scratch environment gets production grade controls first.

## Do not do this yet

- Do not design a multi region active failover architecture. That is an availability engineering project with a headcount attached, and it is not what a first security hire is for.
- Do not buy a backup product before you have measured a restore. The measurement usually shows that the built in tools were adequate and the gap was that nobody had turned one setting on.
- Do not write a 40 page business continuity plan. Write the one page destructive event runbook and prove it works. The long document is a compliance artifact for later, and `co-4-data-inventory-and-framework.md` will tell you when a framework actually requires one.
- Do not attempt to back up every software as a service tool. Pick the two or three that would stop the business.
- Do not lock any immutability policy, or apply a vault lock in compliance mode, in your first quarter. Governance mode and unlocked policies deliver almost all of the protection with none of the permanence.
- Do not turn a restore drill into a graded test of an engineer. You need them to volunteer the ugly details, and they will not do that if the drill has a score attached.
- Do not promise a recovery time objective to a customer to close a deal before a drill exists. Sales will ask. The answer is a date by which you will have a measured number, not a number invented today.

## Evidence to capture

Into `SECURITY-STATE.md`, under an M-6 section, using the standard status vocabulary of `unknown`, `none`, `partial`, `done`, or `n/a`:

- The datastore inventory table: system, owner, backup mechanism, retention in days, point in time recovery yes or no, second copy location, immutability state, key holder.
- The derived recovery point objective and the drill measured recovery time objective, each with its date and its source.
- The answer to whether production identities can delete backups, per identity, with the command output filed in `evidence/`.

Into `RISK-REGISTER.md`: every gap you found and did not close, with an owner and a review date. The common entries are "single copy in production account", "never restore tested", "software as a service system X has no export", and "deploy role can delete snapshots".

Into `DECISION-LOG.md`: the retention choice and its reasoning, the governance versus compliance mode choice, the decision to rely on a vendor for any given system, and the rule that no external recovery claim precedes a drill.

Into `evidence/`: raw command output, the drill timing notes, and a screenshot or console export showing the backup configuration on the date you checked it.

What a future auditor or enterprise customer will ask for: proof that backups are configured, proof that they are encrypted, proof that restoration has been tested within the last 12 months with a date and a result, and the documented recovery time objective and recovery point objective. The drill notes are the artifact that satisfies three of those four. Feed the resulting sentence directly into the business continuity question in `co-2-questionnaire-knowledge-base.md`.

## Cost and effort

- Discovery and the three questions: half a day to one day of your time, free.
- Turning on automated backups and point in time recovery where they are off: an hour of an engineer's time. Cost is the backup storage, which on managed relational databases is often free up to the size of the provisioned storage and billed per gigabyte per month beyond that.
- A second copy in a separate account or project: half a day to two days of engineering. Cost is storage plus cross account or cross region transfer, typically tens of dollars per month at startup data volumes and hundreds at terabyte scale.
- Immutability configuration: two hours, no additional licence cost on any of the three major clouds.
- The first timed restore drill: half a day of two people, plus whatever the scratch environment costs for a day.
- Software as a service exports: mostly free using native export features, a day of chasing. Dedicated software as a service backup products run roughly 3 to 8 dollars per user per month, which is the price band to quote if someone asks, and is rarely the right first purchase.
- Total to reach the definition of done: three to five working days spread over three to four weeks, and typically under 200 dollars per month of new spend at this company size.

## Failure modes

**Backups are on and have never completed successfully.** Early tell: the most recent successful backup timestamp is older than the schedule interval, or the backup job list is empty despite a configured plan. Recovery: read the job history rather than the configuration, fix the cause (usually a permission or a storage quota), and add the "last successful backup age" signal to the small set of things you watch in `dr-2-top-security-signals.md`.

**The drill succeeds and nobody records the time.** Early tell: someone says "yeah we restored it once, it was fine". Recovery: run it again with a stopwatch. An unmeasured drill produces no evidence and cannot support any external claim.

**The restore works but the application does not.** Early tell: the drill restores the database and stops there. Recovery: extend the drill definition to include an application connecting successfully to the restored copy. Data without the schema migrations, the secrets, the configuration, and the object storage that goes with it is not a recovered service.

**The backup contains the compromise.** Early tell: a restore from before the intrusion is not available because retention is shorter than the dwell time. Recovery: lengthen retention, and add a rule to the incident plan that when an intrusion is suspected you immediately preserve a copy of the oldest available backup before it ages out.

**Immutability is switched on for the wrong bucket.** Early tell: a normal application workflow that overwrites objects starts failing, or the storage bill climbs steadily with no matching product growth. Recovery: if the policy is unlocked, or the vault lock is in governance mode, remove it and reapply to the correct target. If it is locked in compliance mode, it cannot be removed, and the recovery is a cost conversation with finance and a lifecycle plan for when the retention expires. This is why the default is governance mode or an unlocked policy.

**The person who knows how to restore leaves.** Early tell: every discovery answer routes to one name. Recovery: have someone else run the next drill from the written runbook while that person stays silent, and fix every gap the silence exposes.

**Backups exist but the encryption key is in the account that was compromised.** Early tell: nobody can answer step 6. Recovery: re-encrypt the destination copies under a key held in the destination account or project, and record the key holder.

## Destructive event runbook

This plugs into the incident plan in `dr-1-incident-response-plan.md` and does not replace it. Declare the incident there, use the severity table there, and use this page for the ordering that is specific to destruction.

**How this differs from every other incident.** In a confidentiality incident, you contain the identity first, because every minute of access is more data taken. In a destruction incident, containing the identity first can trigger the destruction. An attacker who notices they have been locked out may destroy on the way out, and some do exactly that. So the ordering question is: **can this identity delete our recovery path, and can we break that path before we break their access?**

1. **Declare, and say the word destruction out loud.** Use the declaration mechanism in `dr-1-incident-response-plan.md`. Name a single decision maker in the first five minutes.
2. **Establish which case you are in.** Accidental (a migration, a script, a `terraform destroy` in the wrong workspace, someone emptying a shared drive) or malicious. The accidental case is far more common and the ordering below simplifies enormously: skip to step 6. Do not assume malice because the damage is large.
3. **Stop further writes and deletions if you can do so without alerting the actor.** Note carefully: nothing here is pre-authorised. Breaking a deletion path means changing permissions or applying a legal hold, which is a mutating change to production access, and it needs an explicit human yes from the incident decision maker every time. Where a standing pre-authorisation has been agreed, it reaches two actions only: revoking a named human employee's active sessions and refresh tokens, and revoking a third party application's access grant. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.
4. **Break the deletion path before the access path, when the attacker holds deletion rights.** The concrete options, each requiring that explicit yes: apply an object storage legal hold or switch the destination to an immutable state; attach an explicit deny for delete actions to the compromised principal; on AWS attach a service control policy at the organisational unit denying `rds:DeleteDBSnapshot`, `backup:DeleteRecoveryPoint`, `s3:DeleteObjectVersion`, and `kms:ScheduleKeyDeletion`; on Google Cloud remove the delete bearing roles at the project level; on Azure apply a delete lock to the relevant resource group. Then, and only then, kill the session.
5. **Immediately take an out of band copy of whatever still exists.** A snapshot copied into an account the attacker does not control is worth more than any forensic nicety. Evidence preservation never blocks containment: do both in parallel and let containment win if you must choose. Do not reboot or terminate hosts, do not delete the malicious artifact, and do not close the account under investigation.
6. **For the accidental case, freeze and inventory before restoring.** Stop the job or the person who is still deleting. Establish precisely what is gone and the exact timestamp of the last good state. Check the free safety nets first, because they often make a full restore unnecessary: object version history, object storage soft delete, the platform recycle bin, database point in time recovery, and the document platform's trash and version history, all of which have their own expiry clocks that are now running.
7. **Restore to a new target, never over the live one.** New instance identifier, new bucket prefix, new database name. Validate the restored data before any cutover. Compare row counts or object counts against whatever last known good figure you have.
8. **Ransomware and extortion at startup scale.** Classic file server encryption is not the usual shape here. The usual shape is data stolen from cloud storage followed by an extortion demand, or destruction of cloud resources by someone holding console access. Two consequences. First, the recovery question and the disclosure question are separate: restoring the data does not remove a notification obligation for the data that was copied, and that decision belongs in the notification tree in `dr-1-incident-response-plan.md` with counsel. Second, whether to pay is an executive and legal decision, never a technical one, and it carries sanctions exposure in several jurisdictions. Your job is to present the recovery options and the measured restore time, not to have an opinion on payment.
9. **Communicate on a channel the attacker is not in.** If the compromised identity reaches the company chat, move to the out of band channel named in `dr-4-company-comms-channel.md`.
10. **Write it up within 48 hours** using the blameless format in `dr-1-incident-response-plan.md`. The specific thing to capture here is the delta between the drill time and the real time, because that delta is the most valuable number this cell will ever produce.

## What 3-2-1 means when you are entirely in one cloud

The traditional rule says three copies of the data, on two different types of media, with one copy offsite. It was written for tape and for buildings. Restated for a startup that has no buildings and no tape, and where the realistic threat is a stolen credential rather than a flood:

- **Three copies:** the live data, the platform's own automated backup, and one copy you created deliberately.
- **Two failure domains:** the copy you created lives in a different account, project, or subscription, so that a compromise or a billing failure or a mistaken deletion in production cannot reach it. A different region on top of that is a bonus rather than the point.
- **One copy the production identity cannot delete:** this is the modern replacement for "offsite". Offsite used to mean physically out of reach. It now means administratively out of reach, which is immutability, a separate credential root, or both.

Some versions add "one immutable copy and zero errors on restore verification". The zero is the part that matters and it is the part everyone skips. A copy that has never been read back is a hypothesis.

## Related cells

- [DR-1: Incident response plan](dr-1-incident-response-plan.md): the destructive event runbook above is a specialisation of that plan and inherits its declaration, severity, evidence, and notification machinery.
- [DR-2: Top security signals](dr-2-top-security-signals.md): where the "last successful backup is stale" and "mass deletion detected" signals belong.
- [CO-1: Public facing security docs](co-1-public-security-docs.md): the availability and resilience section of the trust page must not make a claim that a drill has not backed.
- [CO-2: Questionnaire knowledge base](co-2-questionnaire-knowledge-base.md): the business continuity answer, including the recovery time objective and recovery point objective, is written from the drill result recorded here.
- [CO-3: Understand existing commitments](co-3-existing-commitments.md): check whether any signed contract already promises a recovery time or a data residency constraint that shapes where the second copy is allowed to live.
- [CO-4: Data inventory, privacy commitments, framework choice](co-4-data-inventory-and-framework.md): the data inventory tells you which datastores are worth protecting, and the deletion commitments there constrain how long backups may be retained.
- [CS-1: Identity and access management](cs-1-identity-and-access.md): the third question of this cell is an identity question, and the separate credential that protects the backup copy is administered there.
- [SE-3: Secrets, api keys, customer secrets](se-3-secrets-and-keys.md): a restore that cannot find its secrets is not a restore, and the break glass credential for the backup account is stored under that cell's rules.
- [references/07-modern-cells.md](07-modern-cells.md): M-2 for the pipeline identity whose deletion rights you simulated, M-3 for the cloud posture context and the correct read only role requests, and M-4 for the software as a service inventory that feeds the export table.
- [references/03-90-day-plan.md](03-90-day-plan.md): owns gate assignment for this cell. The three steps are GC-07 backup inventory, GC-08 one real restore test, and GC-09 backup blast radius, all in Gate C. The one documented jump: GC-09 moves to Gate B when the answer to "can the identity that runs production also delete the backups" is yes.
