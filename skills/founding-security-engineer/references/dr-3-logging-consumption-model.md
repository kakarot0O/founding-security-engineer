# DR-3: Consumption model for logging

> **Grid coordinate:** DR-3, Detection and Response.
> **Original 2019 wording (Evan Johnson, OWASP AppSec California 2019):** "Consumption model for logging".
> **Load when:** the human asks about logging, log retention, SIEM selection, log costs, "where do our logs go", audit trails for an auditor, or is about to enable a firehose of telemetry. Also load this before DR-2 detections are built, because a detection with no reliable log behind it is theatre.

## Why this cell exists

Every company already produces logs. Almost no early company has decided, on purpose, which of those logs matter, where they land, how long they survive, who is allowed to read them, and what that costs per month. "Consumption model" means exactly that set of decisions, made before you turn anything on, not after the bill arrives.

This cell is misunderstood constantly. People read "logging" and start shipping every byte they can find into one place, then either blow the budget or quietly turn the pipeline off six weeks later. The failure that actually hurts is different and quieter: an incident happens, you go to look, and the record you need either was never collected, was deleted after seven days, was writable by the same identity the attacker stole, or is sitting in a bucket nobody can query.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A written log source inventory exists, one row per source, with owner, destination, retention, and rough monthly cost. It lives in the state directory and is referenced from `SECURITY-STATE.md`.
- [ ] Every **control plane** audit log is on and flowing: cloud provider (all accounts, projects, or subscriptions), identity provider, code host, chat, and the top three SaaS tools holding customer data.
- [ ] Control plane and identity logs are retained at least **12 months**, with at least **90 days** immediately searchable.
- [ ] The long term archive lives in a **separate account, project, or subscription** from production, and production credentials cannot delete it.
- [ ] There is one documented way to search logs during an incident, and a human has actually run a query against 60+ day old data and got an answer in under 30 minutes.
- [ ] Read access to logs is an explicit, named list, not "everyone with production access".
- [ ] A known-bad string test has been run to confirm that secrets and obvious personal data are not landing in logs verbatim.
- [ ] All hosts and services emit timestamps in UTC in a consistent format, and clock sync is on.
- [ ] A monthly cost figure exists and a budget alarm fires before it doubles.

**Explicitly NOT required at this stage:** a SIEM product, a detection engineering backlog, full packet capture, network flow logs on every subnet, endpoint telemetry retention, log-based user behaviour analytics, a data lake, a "single pane of glass", or anything with the word "correlation engine" in the marketing copy. None of that helps if the control plane logs are missing.

## Discovery

Everything below is read-only. Run what you have access to, and record "unknown" for the rest rather than guessing.

### Control plane versus data plane, and why it matters

**Control plane** logs record *administrative* actions: a role was created, a user logged in, an OAuth app was authorised, a bucket policy changed, a repository became public, a secret was read. **Data plane** logs record *usage*: an object was downloaded, an API request was served, a row was queried, a page was viewed.

Control plane wins for a first security hire. It is low volume (usually megabytes to a few gigabytes per month), it is cheap or free, it is where every real intrusion leaves a trace, and it is what an auditor and a customer will ask for. Data plane logs are high volume, expensive, and only occasionally decisive. Turn on 100 percent of the control plane before you turn on 1 percent of the data plane.

### Cloud provider

**Amazon Web Services (AWS):**
```bash
aws cloudtrail list-trails
aws cloudtrail get-trail-status --name "<trail-name-or-arn>"
aws cloudtrail get-event-selectors --trail-name "<trail-name-or-arn>"   # shows if data events are on
aws logs describe-log-groups \
  --query 'logGroups[*].[logGroupName,retentionInDays,storedBytes]' --output table
aws s3api get-bucket-versioning --bucket "<log-archive-bucket>"
aws s3api get-object-lock-configuration --bucket "<log-archive-bucket>"
aws organizations describe-organization                              # is there an org trail?
```
Console path if the command line is not available: CloudTrail > Trails, then CloudWatch > Log groups (the retention column is the one that matters).

**Google Cloud Platform (GCP):**
```bash
gcloud logging sinks list --project="<project>"
gcloud logging buckets list --location=global --project="<project>"
gcloud logging buckets describe _Default --location=global --project="<project>"
gcloud logging read 'protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"' \
  --limit=5 --project="<project>" --freshness=1d
```
Note the split: the `_Required` bucket holds Admin Activity audit logs, is free, and is fixed at 400 days. `_Default` holds everything else and defaults to 30 days. Data Access audit logs are **off by default** for most services and are configured under IAM and Admin > Audit Logs.

**Microsoft Azure:**
```bash
az monitor log-analytics workspace list -o table
az monitor activity-log list --offset 1h --max-events 5
az monitor diagnostic-settings list --resource "<resource-id>"
```
Console path: Azure Monitor > Activity log (retained 90 days for free, longer only if you export it), and Microsoft Entra ID > Monitoring > Audit logs and Sign-in logs. Entra free tier keeps sign-in logs 7 days, P1 and P2 keep 30. Anything longer needs a diagnostic setting exporting to a Log Analytics workspace or storage account.

**No cloud access yet:** ask for read-only access. See the message template below. Do not wait; the rest of the inventory is still useful.

### Identity provider

- **Google Workspace:** Admin console > Reporting > Audit and investigation. Login, Admin, Drive, and OAuth Token audit logs are separate views. Default retention varies by log type (commonly 6 months for Login, 6 months for Admin); confirm rather than assume, and export to a warehouse if you need longer.
- **Microsoft 365 and Entra ID:** Microsoft Purview portal > Audit > search, or PowerShell with the Exchange Online Management module: `Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -ResultSize 10`. Retention depends on licence tier.
- **Okta:** Admin > Reports > System Log, or the System Log API. Retention is typically 90 days on standard plans.
- **Anything else (JumpCloud, OneLogin, Auth0, Duo):** find the equivalent "system log" or "audit events" view and record its retention.

### Code host and continuous integration

- **GitHub:** organisation audit log is at Settings > Audit log for the org. The API (`gh api /orgs/<org>/audit-log --paginate`) is available on GitHub Enterprise Cloud only; on lower tiers use the web view and export. Retention on the audit log is limited (commonly around 90 to 180 days depending on plan), so **export it** if you want a year.
- **GitLab:** Admin area > Monitoring > Audit events on self-managed, or group audit events on Premium and Ultimate. `glab api /audit_events` works where the tier permits.
- **CI runner logs:** these are crown jewel logs and are usually forgotten. In GitHub Actions, workflow run logs default to 90 days and are deletable by anyone with repo write. In GitLab CI, job artifacts and traces expire per project settings.

### Chat, endpoint, application, database, edge, email

- **Slack:** the Audit Logs API is Enterprise Grid only. On Pro and Business+, the closest equivalent is the access logs view in the admin console. Record the truth, do not pretend you have what you do not.
- **Microsoft Teams:** covered by the M365 unified audit log above.
- **Endpoint:** whatever mobile device management or endpoint detection tool exists has its own console. See [cs-2-endpoint-security.md](cs-2-endpoint-security.md).
- **Application:** find where the app writes logs. `grep -rn "logger\|winston\|pino\|logrus\|structlog\|slf4j" --include='*.json' --include='*.yaml' -l .` in the repo root is a fast start, plus reading the deployment manifests for `LOG_LEVEL`.
- **Database:** managed databases have audit logging that is usually off. AWS RDS: `aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,EnabledCloudwatchLogsExports]'`. Cloud SQL and Azure SQL have equivalent console toggles.
- **Content delivery network and web application firewall:** Cloudflare, Fastly, CloudFront, Azure Front Door. Cloudflare Logpush requires an Enterprise plan; the free tier gives you sampled analytics only.
- **Email gateway:** Google Workspace or Exchange Online message trace and the anti-phishing verdict logs.

### When the agent has no access at all

Do the inventory as an interview instead of a scan. The inventory itself is the deliverable, and it is genuinely useful on day one even with every "destination" column filled in as `unknown`. Write it into the state directory with a status of `unknown` per row, then work the access requests one at a time.

## Ask the human

Closed questions, one at a time, with a recommended answer attached:

1. "Do we have a single cloud account or an organisation with multiple accounts, projects, or subscriptions? How many?"
2. "Is there a logging or observability tool we already pay for? Datadog, Splunk, Sumo Logic, New Relic, Better Stack, Grafana Cloud, Elastic, something else?"
3. "What is our current monthly spend on that tool, to the nearest hundred dollars?"
4. "Has anyone ever had to go looking through logs for something more than 30 days old? What happened?"
5. "Have we told any customer, in a contract or a security questionnaire, how long we retain logs? If yes, what number did we say?" (This one is load bearing. See [co-3-existing-commitments.md](co-3-existing-commitments.md).)
6. "Who, by name, can currently read production logs?"
7. "Is there a regulated data type in play: cardholder data, protected health information, or financial records?"

Copy-pasteable message for the human to send to whoever owns infrastructure:

> Hi, I am putting together an inventory of where our logs go so we can answer customer security questions and actually investigate things when they break. Three asks, all read-only:
>
> 1. Read-only access to the cloud console and audit logs (AWS: `SecurityAudit` and `ViewOnlyAccess`; GCP: `roles/viewer` plus `roles/logging.viewer`; Azure: `Reader` plus `Log Analytics Reader`). Scoped to every account, project, or subscription we own, not just production.
> 2. A viewer seat on whatever logging or monitoring tool we pay for.
> 3. Fifteen minutes of your time to walk me through what happens to a log line from the moment the app writes it. I am not going to change anything without asking you first.
>
> If some of this needs a ticket or an approval, tell me who to ask and I will do the paperwork.

Copy-pasteable message for finance or whoever owns the vendor spend:

> Hi, can you send me the last three monthly invoices for our logging and monitoring vendors, plus the cloud bill broken down by service? I am trying to work out what we currently spend on log ingestion and storage before I recommend any changes. I would rather find out now than discover it after I turn something on.

## The walk

Baby steps. Do one, verify it, then ask for a go or no-go on the next.

**Step 1: Build the inventory.**
- *Goal:* one table that says what logs exist, where they land, how long they survive, and who owns them. This is the deliverable of the whole cell and it is achievable on day one, even blind.
- *Do:* create the log source inventory table (template in the section below) with one row per source from the Discovery list. Fill what you know, mark the rest `unknown`.
- *Verify:* the human reads it and can point at at least two rows and say "that is wrong, actually it is X". That is success; the table is now doing its job.
- *Time:* 2 to 4 hours.
- *Who else:* nobody required. Better with 15 minutes from an infrastructure engineer.

**Step 2: Prove the cloud control plane audit log is on, everywhere.**
- *Goal:* if an attacker touches your cloud, there is a record, in every account and region, not just the main one.
- *Do:* run the Discovery commands per account. The common gap is a trail configured in one account but not organisation-wide, or a GCP project created last month with no sink.
- *Verify:* take an action you know is benign and recent (create and delete a tag on a resource you own) and find it in the log. If you cannot find your own action, the log is not usable.
- *Time:* half a day.
- *Who else:* the cloud account owner, for read access.

**Step 3: Set retention deliberately, per class, and write down why.**
- *Goal:* stop the default from making the decision for you. Defaults are usually "never expire" (expensive) or "7 days" (useless).
- *Do:* apply the retention rules from Decision points below. Changing retention **upward** is safe. Changing it downward is destructive and belongs in the Danger zone.
- *Verify:* re-run the retention listing commands and confirm every log group, bucket, or workspace shows a deliberate number, not a blank.
- *Time:* half a day.
- *Who else:* infrastructure owner must approve the change.

**Step 4: Get the archive out of blast radius.**
- *Goal:* whoever compromises production must not be able to erase the record of it. This is the single highest value structural control in this cell.
- *Do:* create or identify a dedicated log archive account (AWS), project (GCP), or subscription (Azure). Production identities get write access only, no delete. Enable versioning and object immutability on the archive bucket.
- *Verify:* assume a production role and attempt to delete an object in the archive. It must fail. Record the exact error message as evidence.
- *Time:* 1 to 2 days.
- *Who else:* whoever can create accounts in the cloud organisation. This usually needs a founder or the head of engineering.

**Step 5: Decide who can read logs, and write it down.**
- *Goal:* logs contain access tokens, session identifiers, customer email addresses, and support ticket contents. Read access to logs is close to read access to production data.
- *Do:* enumerate current readers. Split into "needs it for on-call debugging" (application logs, yes) and "needs it for investigation" (audit and identity logs, a much shorter list). Remove the rest.
- *Verify:* list the identity and access policies granting log read, and confirm the names match the written list.
- *Time:* half a day.
- *Who else:* engineering lead, because you will be taking something away from somebody.

**Step 6: Run the secret and personal data leak test.**
- *Goal:* find out whether you are storing credentials in a system with wide read access and long retention.
- *Do:* search recent logs for high signal patterns: `Authorization`, `Bearer `, `password`, `api_key`, `set-cookie`, `eyJ` (the start of a base64 encoded JSON Web Token header), and the format of your own API keys. Search 24 hours only; that is enough to prove the point.
- *Verify:* zero hits, or a written ticket per hit with an owner. Any credential found in logs must be treated as compromised and rotated. See [se-3-secrets-and-keys.md](se-3-secrets-and-keys.md).
- *Time:* 2 hours.
- *Who else:* an application engineer, to fix the emitter.

**Step 7: Fix time.**
- *Goal:* if two systems disagree about what time it is, your incident timeline is fiction.
- *Do:* confirm network time sync is enabled on every host (`timedatectl status` on modern Linux; cloud instances should point at the provider time service, `169.254.169.123` on AWS, `metadata.google.internal` on GCP, and the host integration service on Azure). Confirm every application emits timestamps in UTC in RFC 3339 format.
- *Verify:* pick one event visible in two systems and confirm the timestamps agree within a few seconds.
- *Time:* 2 hours, plus whatever engineering work the UTC change needs.
- *Who else:* application engineer if any service is logging local time.

**Step 8: Put a number and an alarm on the bill.**
- *Goal:* nobody ever turns off a log source because of security. They turn it off because of cost. Get ahead of that.
- *Do:* pull the last three months of logging spend. Set a budget alert at 1.3x the current monthly figure, routed to you and to whoever owns the bill.
- *Verify:* confirm the alert exists and the notification address is correct. Send a test if the platform supports it.
- *Time:* 1 hour.
- *Who else:* whoever owns the cloud bill.

**Step 9: Write the one page consumption model.**
- *Goal:* a document you can hand to an auditor, a customer, or the next hire, and that stops this whole conversation being relitigated every quarter.
- *Do:* one page. Sources, destinations, retention per class, who can read, what it costs, and how to search during an incident.
- *Verify:* an engineer who was not in the room reads it and can answer "where would I look for a failed login three months ago".
- *Time:* 2 hours.
- *Who else:* nobody.

**Step 10: Run a 30 minute retrieval drill.**
- *Goal:* prove the pipeline works end to end before an incident proves it does not.
- *Do:* pick a question ("which identities assumed the deploy role between 60 and 90 days ago") and answer it against archived data, timed.
- *Verify:* answer produced in under 30 minutes, with the exact query recorded in the runbook.
- *Time:* half a day.
- *Who else:* nobody, but do it with a witness so the result is credible.

## Log source inventory table

Copy this into the state directory and fill it in. The four right hand columns are the whole point.

| Source | Class | Why you need it | Do this first | Rough cost |
|---|---|---|---|---|
| Cloud provider audit log (CloudTrail, GCP Admin Activity, Azure Activity Log) | Control plane | Every privilege change, role assumption, and resource modification. The single most important log you have. | Turn it on organisation-wide, all regions, delivering to a separate archive account. | Free to low. AWS: first copy of management events free per trail, storage in object storage is cents per gigabyte per month. GCP Admin Activity is free. |
| Identity provider (Google Workspace, Entra ID, Okta, JumpCloud) | Control plane | Logins, multi-factor prompts, admin role grants, impossible travel. The place an account takeover shows up first. | Confirm retention. Export beyond the vendor default if it is under 12 months. | Free at the vendor default. Export cost is negligible. |
| OAuth grant and third-party app authorisations | Control plane | An employee authorising a malicious integration is a leading breach path and is invisible to endpoint tools. | Turn on the specific audit log for token grants and review monthly. | Free. |
| Code host audit log (GitHub, GitLab) | Control plane | Repository visibility changes, branch protection edits, personal access token creation, member additions. | Export to the archive; vendor retention is short. | Free to low. |
| Continuous integration runner and workflow logs | Control plane and data plane | The pipeline holds every secret and deploys to production. Also: build logs sometimes contain leaked secrets in plaintext. | Extend retention past the 90 day default and restrict who can read them. | Low. |
| Chat platform audit log (Slack, Teams) | Control plane | Channel visibility changes, external shared channels, app installs, file exfiltration. | Check whether your plan tier even exposes it. Record the answer honestly. | Free if your tier includes it, otherwise an enterprise plan upgrade. |
| Endpoint (mobile device management, endpoint detection) | Control plane and data plane | Malware, unmanaged devices, disk encryption status. | Confirm the console retains alerts for 12 months. | Bundled with the endpoint tool. |
| Application logs | Data plane | Debugging, abuse patterns, and the only place your own business logic is visible. | Set a level (info, not debug, in production) and a 30 day retention. This is the source that blows the budget. | High and volume driven. Model it before enabling. |
| Database audit logs | Data plane | Bulk reads of customer data. Needed for any real "was data exfiltrated" question. | Enable connection and administrative logging first. Full statement logging only if a framework requires it. | Medium to high. Statement logging on a busy database can double the database cost. |
| Content delivery network and web application firewall | Data plane | Attack traffic, credential stuffing, scraping. | Use the vendor dashboard first. Only push raw logs when you have a specific question. | Often an enterprise plan gate. Raw log push is frequently the most expensive line item. |
| Email gateway | Data plane | Phishing is still the most common intrusion route. | Confirm you can search 90 days of message trace. | Bundled. |
| Network flow logs (VPC flow, NSG flow) | Data plane | Rarely decisive at startup scale. Occasionally the only proof of exfiltration volume. | Leave off, or enable on one sensitive subnet with sampling. | Very high. This is a classic bill-doubler. |

## Cost model, back of the envelope

Do this arithmetic **before** enabling anything, out loud, in front of the human.

```
daily_gb   = events_per_second * bytes_per_event * 86400 / 1e9
monthly_gb = daily_gb * 30
monthly_$  = monthly_gb * ingest_price_per_gb  +  retained_gb * storage_price_per_gb_month
```

Worked example. One chatty web service, 2,000 requests per second, one 1 kilobyte structured log line per request:

- 2,000 x 1,024 bytes = ~2 megabytes per second = ~172 gigabytes per day = **~5.2 terabytes per month**.
- At roughly $0.50 per gigabyte ingested (the common cloud-native log ingestion price band), that is **about $2,600 per month** for one service.
- At the higher per-gigabyte rates typical of Azure Log Analytics analytics-tier ingestion, or of a commercial observability vendor with per-event indexing on top, the same volume lands in the **$5,000 to $12,000 per month** range.
- The same data written as compressed Parquet or gzip into object storage costs roughly **$25 to $60 per month** to store, and a few dollars per query to scan.

Treat all of those prices as approximations to re-check on the vendor pricing page in the current region before you quote them to anyone. The ratio is the point: indexed hot logging is one to two orders of magnitude more expensive per gigabyte than object storage. That ratio is the entire justification for tiering.

**The classic bill detonations, in rough order of how often they happen:**
1. Debug level logging left on in production after an incident.
2. Network flow logs enabled organisation-wide.
3. Object storage data events enabled on every bucket including the log archive bucket, which then logs its own writes, recursively.
4. A verbose third-party library dumping full HTTP request and response bodies.
5. Kubernetes cluster-wide audit logging at `RequestResponse` level.
6. Log lines that embed a full stack trace at info level on a hot path.

## Tiering: hot, warm, cold

- **Hot (searchable in seconds, expensive):** last 30 days of application logs, last 90 days of control plane and identity logs. This is what you actually query.
- **Warm (searchable in minutes, cheap):** 90 days to 12 months, in object storage in a columnar format, queryable by a serverless query engine (Athena, BigQuery external tables, Azure Data Explorer, or DuckDB against object storage).
- **Cold (retrievable in hours, nearly free):** 12 months and beyond, in archival object storage tiers, kept only because a contract or a regulation says so.

The mistake is treating this as three products. It is one pipeline with a lifecycle policy. Configure the lifecycle rule at the same time you create the bucket, never later.

## Retention: how to pick the number

Two forces set retention, and you take the larger of them.

**Force one, dwell time.** Attackers sit in environments for a while before anyone notices. Industry medians in recent years land in the range of one to three weeks globally, but that median is dragged down by ransomware, which announces itself. The intrusions that matter to a software company, quiet credential theft and data access, are routinely discovered months later and usually by an outside party: a customer, a researcher, a law enforcement notification, or a vendor telling you their product was compromised. If you retain 30 days, a notification that arrives on day 45 leaves you with nothing to say. **90 days hot is the floor. 12 months total is the target.**

**Force two, commitments.** Check these in order, and record findings in `SECURITY-STATE.md` under DR-3 with a cross reference to CO-3:
- Customer contracts and security questionnaires you have already answered. If a sales engineer wrote "we retain audit logs for one year" on a questionnaire last quarter, that is now a commitment.
- SOC 2 does not mandate a specific retention period, but the audit period is typically 3 to 12 months and the auditor will sample evidence across it. In practice you need 12 months.
- PCI DSS requires 12 months of audit log history with the most recent 3 months immediately available for analysis.
- HIPAA requires documentation retention of 6 years, which is often misread as a 6 year log requirement. Read the actual requirement before committing.
- GDPR does not set a retention period, and pushes the other way: logs containing personal data are personal data, need a lawful basis and a documented retention period, and cannot be kept indefinitely "just in case".

Resolve the tension by class: audit and control plane logs (low personal data content, high investigative value) get long retention. Application and request logs (high personal data content, lower investigative value) get short retention plus scrubbing.

## Integrity and tamper resistance

An attacker with production credentials will try to delete the evidence. Three controls, in order of value:

1. **Separate the archive.** Different cloud account, project, or subscription, different administrative owner. Production writes, it does not delete. This alone defeats most log destruction.
2. **Immutable storage.** AWS S3 Object Lock in governance or compliance mode. GCP bucket retention policies (and `gcloud storage buckets update --lock-retention-period` to make the policy itself permanent). Azure immutable blob storage with a time-based retention policy. Turn on versioning first in every case.
3. **Alert on the logging configuration changing.** "CloudTrail trail stopped", "log sink deleted", "diagnostic setting removed", "retention reduced". These are high signal, near zero noise detections and belong in [dr-2-top-security-signals.md](dr-2-top-security-signals.md).

Note the asymmetry that makes this cheap: control plane logs are small. Storing 12 months of them immutably costs single digit dollars per month for most startups.

## Personal data and secrets in logs

Logs leak in four predictable ways: full HTTP headers including `Authorization` and `Cookie`, full request bodies on signup and login endpoints, database query logs containing literal parameter values, and error stack traces that stringify a whole configuration object including credentials.

Scrub at the emitter, not at the destination. A redaction rule in the logging pipeline is a mitigation; a logger configured never to serialise a denylisted field is a fix. Most structured logging libraries support a redaction path list. Set the denylist to at least: `password`, `passwd`, `secret`, `token`, `authorization`, `cookie`, `set-cookie`, `api_key`, `apikey`, `access_key`, `refresh_token`, `client_secret`, `ssn`, `card`, `cvv`.

Then verify with a canary: send a request containing a unique nonsense string in a header and in a body field, wait for the pipeline, and search for it. If the string appears, the scrubbing does not work. Re-run this canary after any logging library upgrade.

## Decision points

**Buy a SIEM now, or not?**
DEFAULT: **not yet.** Under roughly 50 employees, with no dedicated detection engineer, a security information and event management product is a subscription to a backlog of alerts nobody triages. Use cloud-native logging plus object storage plus a query engine. Change this decision when any of these become true: you have a person whose job is detection, a compliance framework explicitly requires centralised log review, or you have more than three clouds and identity providers to correlate across.

**Centralise everything into one system, or route by class?**
DEFAULT: **route by class.** Security and audit logs go to the archive and to whatever you query during incidents. Application and performance logs stay in the engineering observability tool. Forcing them together is how startups end up paying observability prices for security retention. Change this if the volumes are small enough that one system is genuinely cheaper, which is rare above a few hundred gigabytes per month.

**Retention: 30 days, 90 days, or 12 months?**
DEFAULT: **90 days hot and 12 months cold for control plane, identity, and code host; 30 days for application and request logs.** Change to 12 months hot only if a contract requires it, and change application logs upward only after modelling the cost.

**Sampling?**
DEFAULT: **never sample audit or control plane logs. Sample application request logs freely.** A sampled audit log is not an audit log; the one event you need is the one that was dropped. A sampled request log is still perfectly good for volumetric analysis.

**Build the pipeline yourself, or use the managed path?**
DEFAULT: **managed cloud-native for the first year.** A self-hosted OpenSearch cluster is a full-time job you do not have. Vector or Fluent Bit as a lightweight router into object storage is acceptable and cheap; a self-run search cluster is not.

**Separate log archive account: worth the overhead?**
DEFAULT: **yes, always.** It is a day of work, costs nothing extra, and is the difference between having evidence and not having it. This is the one place to spend political capital in this cell.

## Danger zone

Every item here requires an explicit human yes before you run it. State the risk out loud first.

- **STOP: reducing a retention setting.** Lowering retention on a log group, bucket, or workspace can delete existing data immediately and irreversibly. Never lower retention without a written decision in `DECISION-LOG.md` and a check against contractual commitments.
- **STOP: deleting a log group, bucket, sink, or diagnostic setting.** Even an obviously useless one. Rename or stop feeding it instead. What looks like an orphan is frequently the destination for something you have not discovered yet.
- **STOP: enabling object storage data events, network flow logs, or full database statement logging.** These are the three reliable four-figure-per-month surprises. Model the cost first, enable on one resource, measure for 48 hours, then extrapolate before going wide.
- **STOP: turning on immutable storage in compliance mode.** Compliance mode means the objects cannot be deleted by anyone including the account root, for the entire retention period, and you cannot delete the bucket until the last object expires. Set a short retention period first and test it. A one year compliance lock on a mis-sized bucket is a bill you cannot cancel.
- **STOP: applying an organisation-wide policy that denies logging configuration changes.** Correct control, real lockout risk. It can block the platform team from legitimate work at the worst moment. Ship it with a documented break-glass exception and tell the platform team before it lands, not after.
- **STOP: sending logs containing customer personal data to a third-party vendor, or to a different geographic region.** This can create a data transfer obligation, breach a data processing agreement, or violate a commitment already made to a customer. Check [co-4-data-inventory-and-framework.md](co-4-data-inventory-and-framework.md) and get a written yes from whoever owns customer contracts.
- **STOP: removing engineers' log access.** If application logs are how on-call debugs at 3am, removing access is an availability risk, not a security win. Split audit logs from application logs first, then restrict only the audit side.

## Do not do this yet

- Do not buy a logging or SIEM product in your first month. You do not yet know your volumes, and every vendor quote you get before you know them will be wrong.
- Do not write detection rules before ingestion is stable. A detection on a flaky pipeline trains people to ignore alerts, which is worse than no detection.
- Do not chase the "single pane of glass". It is a sales concept. Two panes that both work beat one pane that is always half broken.
- Do not build a custom log pipeline. Every hour you spend on log shipping infrastructure is an hour not spent on identity, which is where the actual breaches are.
- Do not enable endpoint telemetry retention or full packet capture. Wrong decade, wrong company size.
- Do not try to get 100 percent coverage. Johnson's own note on this domain applies directly: you are not going to have full coverage of detection and response, and the traction feels slow until suddenly it is good.
- Do not normalise everything into a common schema up front. Store raw, normalise at query time. Schema work done before you know the questions is thrown away.

## Evidence to capture

Write into the state directory:

- **`SECURITY-STATE.md`**, section "Detection and Response > DR-3 Consumption model for logging": the full log source inventory table, per-source status of `unknown` / `none` / `partial` / `done`, the retention decision per class, the monthly cost figure with its date, and the location and account of the archive. Link the verification output that proved the control plane log is flowing.
- **`RISK-REGISTER.md`**: one row per known gap. Typical rows are "no audit log retention beyond 30 days", "log archive is deletable by production credentials", "secrets observed in application logs", "no audit log available on our chat plan tier". Each with severity, owner, and either a fix date or an explicit acceptance and who accepted it.
- **`DECISION-LOG.md`**: the retention numbers and the reasoning, the SIEM buy or defer decision, and any decision to accept a gap for cost reasons. Date each and name who approved.
- **`ACCESS-LOG.md`**: every log-read access request made, granted, or denied, with dates. This doubles as evidence of least privilege when an auditor asks.
- **`90-DAY-PLAN.md`**: DR-3 usually lands as two chunks, "control plane logging on and archived" in the first month and "retention, access, and cost model" in the second.

**What a future auditor or enterprise customer will actually ask for:** a written log retention policy with a stated period; evidence that audit logging is enabled across all production systems; evidence that logs are protected from unauthorised modification or deletion; the list of people with log access; and evidence that logs are reviewed, which at your size means the alert routing from DR-2 plus a dated record of the reviews. The one page from Step 9 answers four of those five.

## Cost and effort

- **Near zero, $0 to $100 per month.** Cloud-native control plane audit logs (management events, admin activity, activity log) delivered to object storage in a separate account, with lifecycle rules. Identity provider logs at the vendor default. Query with the provider's serverless query engine, paying per query. Effort: 3 to 5 days total. This covers the majority of the investigative value and is where every startup should start.
- **Low, $100 to $1,000 per month.** Add a managed log router or a hosted log platform on the cheaper end of the market for hot search, keep the object storage archive for cold. Add database and code host log export. Effort: 1 to 2 weeks. Open source path at this tier: Vector or Fluent Bit as the router, Grafana Loki or Quickwit for hot search, object storage for cold, Sigma rules for portable detections, Wazuh if you want host agents.
- **Funded, $1,000 to $10,000 per month.** A commercial detection platform. Do this when you have a person to run it. Get a volume-based quote using your measured gigabytes per month, not the vendor's assumption, and negotiate an overage cap. Ask specifically what happens if volume doubles, because it will.

A useful sanity check for the human: if logging costs more than 3 to 5 percent of the total cloud bill and you are not a data company, something verbose is on that should not be.

## 2026 notes

The 2019 slide put logging in a domain that assumed the interesting events happened on servers you operated. Four things changed.

1. **The important logs moved into other people's products.** Your crown jewel data is in the identity provider, the code host, the customer relationship system, the data warehouse, and a dozen other software-as-a-service tools. Those audit logs are the ones that matter now, and many vendors put them behind an enterprise tier. Budget for the audit log upgrade on the two or three tools holding customer data, and treat "does this vendor expose an audit log at our tier" as a purchasing criterion. See [07-modern-cells.md](07-modern-cells.md).
2. **Build pipeline logs became crown jewel logs, and also a leak channel.** The tj-actions incident in 2025 worked by dumping continuous integration runner memory into build logs that were publicly readable. So workflow logs are simultaneously something you must retain and something you must restrict. Public repository build logs should be treated as a publication surface.
3. **Volume went up because code volume went up.** Assistant-written code ships more services, more endpoints, and more log statements per engineer than 2019 assumed. A cost model built on 2019 per-engineer output will be wrong by a multiple.
4. **A new source class exists: agent and model action logs.** If anything in the company runs an autonomous agent with tool access, the record of which tool it called with which arguments is a security log, and almost nobody is retaining it. Add a row for it in the inventory even if the answer today is `none`.

The one structural thing that got better: cheap object storage plus columnar formats plus serverless query engines mean the 2019 assumption that real logging requires buying a search product is simply no longer true. A founding security hire in 2026 can have twelve months of tamper resistant audit history for the price of a couple of lunches.

## Failure modes

- **Bill shock, then a rollback.** A source gets enabled, the bill triples, and finance demands it all be turned off, including the cheap useful parts. *Early tell:* nobody did the arithmetic before enabling. *Recovery:* separate the cheap control plane logs from the expensive data plane logs in the conversation, keep the former, and re-enable the latter behind a measured model.
- **Silent pipeline death.** A sink is deleted, a token expires, a disk fills, and logging stops. Nobody notices for months, because the absence of logs looks exactly like the absence of problems. *Early tell:* you cannot find your own test event. *Recovery:* add a heartbeat check that alerts when a source produces zero events in an hour, and treat that as a real alert.
- **Logs exist, nobody can query them.** Everything is dutifully archived and completely unusable under time pressure. *Early tell:* the retrieval drill in Step 10 has never been run. *Recovery:* run it, write down the exact query, and put it in the incident runbook from [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md).
- **The archive was in the compromised account.** *Early tell:* the archive bucket and production share an account. *Recovery:* Step 4. Do it before you need it, because after you need it you cannot.
- **Logs became a second copy of the database.** Full request bodies at info level means customer personal data, in a system with wide read access and no deletion workflow, which then breaks your own privacy commitments. *Early tell:* the canary test in Step 6 finds the string. *Recovery:* fix the emitter, then purge the affected retention window, then check whether the exposure is reportable.
- **Clock skew makes the timeline unusable.** Two systems, two timezones, one incident, and an hour spent arguing about ordering. *Early tell:* any log in local time. *Recovery:* Step 7, and normalise historical data at query time.
- **New service, no logging.** Six months in, a service shipped last quarter has no log destination configured. *Early tell:* the inventory has not been updated since it was created. *Recovery:* make log destination part of the service template and the design review checklist in [se-1-sdlc-and-design-reviews.md](se-1-sdlc-and-design-reviews.md), so it is a default rather than a task.

## Related cells

- [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md), the plan that consumes these logs.
- [dr-2-top-security-signals.md](dr-2-top-security-signals.md), what to alert on once the pipeline is trustworthy.
- [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md), where log-derived alerts land and who reads them.
- [se-3-secrets-and-keys.md](se-3-secrets-and-keys.md), for credentials discovered in logs.
- [cs-1-identity-and-access.md](cs-1-identity-and-access.md), the source of the highest value control plane log you have.
- [co-3-existing-commitments.md](co-3-existing-commitments.md), retention promises already made to customers.
- [co-4-data-inventory-and-framework.md](co-4-data-inventory-and-framework.md), personal data in logs and the framework that sets your retention floor.
- [07-modern-cells.md](07-modern-cells.md), continuous integration, cloud posture, and software-as-a-service audit logging as first class sources.
- [06-2019-to-2026-delta.md](06-2019-to-2026-delta.md), why the domain boundaries around this cell moved.
