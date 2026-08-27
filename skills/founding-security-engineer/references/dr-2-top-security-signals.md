# DR-2: What are the top security signals for your org?

> **Grid coordinate:** DR-2, Detection and Response domain.
> **Original 2019 wording (Evan Johnson, "Starting Security at a Startup", OWASP AppSec California 2019):** "What are the top security signals for your org?"
> **Load when:** the human asks what to monitor or alert on, is evaluating a detection vendor, has just been asked by a customer or auditor what monitoring exists, is writing the detection half of an incident response plan, or has finished DR-1 and needs something that will actually fire.
>
> **Do not load this first when the human says "we need a SIEM" (Security Information and Event Management platform).** That sentence is about where logs live, what they cost, and how long they are kept, which is [dr-3-logging-consumption-model.md](dr-3-logging-consumption-model.md). Consumption comes before detection: a detection built on a log that is retained for seven days, or that the company cannot afford to keep ingesting, is theatre. Load dr-3, settle retention and cost, then come back here. The same ordering is stated in dr-3's own load-when line, and the two files must never disagree about it.

## Why this cell exists

Detection means noticing that something bad is happening while you can still do something about it. Most startups skip straight to buying a log platform, pointing everything at it, and then never looking at it again, which produces a large invoice and zero detections. The useful version is the opposite: pick a small number of things that would genuinely indicate a break-in at *this* company, wire each one to a place a human will see it, and write down what to do when it fires.

Evan Johnson's own warning in the talk still holds: "Detection and Response is honestly one of the hardest areas to get traction. It's something that really can feel like you aren't making much headway until it's really good." His concrete advice was to start with a handful of signals (cloud key usage, identity provider access, corporate DNS) rather than aiming for coverage. He also said plainly: "You are not going to have 100% coverage over D&R." Accept that on day one.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] A written list of the top ten to fifteen signals for this company, each traced back to a crown jewel or a known attack path, stored in `SECURITY-STATE.md` under `## DR-2 Top security signals`.
- [ ] At least eight of those signals are actually firing to a real destination (a dedicated chat channel, an on-call rotation, or an email alias that a human reads daily).
- [ ] Every live alert has a one-paragraph documented response linked from the alert text itself. No exceptions.
- [ ] Alert volume is under roughly ten alerts per week in total across all rules. If it is higher, the rules are wrong, not the humans.
- [ ] Audit logging is confirmed enabled and retained for at least 90 days on: the cloud provider, the identity provider, the code host, and the chat platform.
- [ ] A named human (usually the security hire) checks the alert channel every working day, and there is a written statement of what happens outside working hours.
- [ ] One tabletop or one live test per quarter proves at least one alert path end to end (fire a benign trigger, confirm a human saw it).

Explicitly **not** required at this stage:

- A SIEM (Security Information and Event Management platform, a central searchable log store with correlation rules). You do not need one to have detections.
- Centralised logging of everything. Detection and log centralisation are different projects with different budgets. See `dr-3-logging-consumption-model.md`.
- Twenty four by seven human coverage, a follow-the-sun rota, or a paid managed detection service.
- Threat intelligence feeds, a detection engineering framework, ATT&CK coverage matrices, or purple teaming.
- Network intrusion detection sensors, full packet capture, or a honeypot.
- Detection content for exotic attacks. Your attacker is a stolen session cookie and a phished password, not a nation state implant.

## Discovery

The goal of discovery is to answer one question per candidate signal: *does the log that would produce this signal already exist, and can I read it?* Prefer read-only commands. Nothing below mutates state.

### Step zero: what are the crown jewels

Before touching a console, write down in `SECURITY-STATE.md` the three to five things whose compromise would be a company-ending event. For most startups that is: the production customer database, the cloud provider root or organisation owner account, the identity provider admin, the code host organisation, and the deployment pipeline credentials. Every signal you pick must trace to one of these. If a proposed alert does not trace to one, delete it.

### Cloud provider

**Amazon Web Services (AWS).** Confirm CloudTrail (the AWS audit log service) exists and is multi-region:

```bash
aws cloudtrail describe-trails --query 'trailList[].{Name:Name,MultiRegion:IsMultiRegionTrail,Bucket:S3BucketName,Logging:HomeRegion}'
aws cloudtrail get-trail-status --name "<trail-name>"
```

Sample a real security event to prove the log has data:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey \
  --max-results 10
```

Check whether Amazon GuardDuty (the built-in threat detection service) is on, since it is the cheapest real detection you can buy:

```bash
aws guardduty list-detectors
aws guardduty get-findings-statistics --detector-id "<id>" --finding-statistic-types COUNT_BY_SEVERITY
```

**Google Cloud Platform (GCP).** Admin Activity audit logs are on by default and free. Confirm you can read them and check where they are routed:

```bash
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity"' --limit=5 --freshness=7d
gcloud logging sinks list
gcloud logging read 'protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"' --limit=20 --freshness=30d
```

For Security Command Center findings, use the console at Security > Security Command Center > Findings, since the command line surface varies by tier.

**Microsoft Azure.** Activity Log is on by default with 90 day retention:

```bash
az monitor activity-log list --offset 30d --max-events 50 -o table
az monitor log-analytics workspace list -o table
```

Microsoft Defender for Cloud findings live at Microsoft Defender for Cloud > Security alerts in the portal.

**If you do not know which cloud is in use:** run `env | grep -iE 'aws|gcp|google|azure'`, look for `~/.aws/config`, `~/.config/gcloud/`, or `~/.azure/`, grep the repository for `terraform` provider blocks, and check the corporate card statement. If all of that fails, ask (see "Ask the human").

### Identity provider

**Google Workspace.** Admin console > Reporting > Audit and investigation. The two logs that matter most are "Login audit log" and "OAuth log events". Alerting lives at Admin console > Security > Alert center, which Google includes in every Workspace edition at no extra cost, and the suspicious login, leaked password, and government backed attack alerts all land there. What is gated by edition is not the alert but what you can do next. The security investigation tool, which is how you search across logs and act in bulk, needs Frontline Standard or Plus, Enterprise Standard or Plus, Education Standard or Plus, Enterprise Essentials Plus, or Cloud Identity Premium. The recommended actions that let you suspend a user or quarantine mail straight from an alert need Frontline Plus, Enterprise Plus, or Education Standard or Plus. Check the edition at Admin console > Billing > Subscriptions before you promise a founder anything beyond the alert itself. Then confirm the alerts reach a human: recipients are set per rule at Admin console > Rules, on the rule's Actions panel under Send email notifications.

**Microsoft 365 and Entra ID.** Sign-in logs at Entra ID > Monitoring > Sign-in logs. Audit logs at Entra ID > Monitoring > Audit logs. Risk based detections such as atypical travel live under Entra ID > Protection > Risk detections and require a premium licence tier, so check the licence before promising it. The unified audit log lives in the Microsoft Purview compliance portal and may need to be turned on.

**Okta, JumpCloud, OneLogin, or similar.** All of these have a System Log with a searchable event type field. Use the log search interface first and confirm the exact event type strings in your own tenant before writing a query, because event names differ between versions. In Okta the starting points are the session start, multi-factor authentication factor change, and administrator privilege grant event families.

**If there is no identity provider and everyone logs into each tool separately:** that is a finding, not a detection gap. Record it in `RISK-REGISTER.md` and read `cs-1-identity-and-access.md`. Detection on top of no identity provider is building a roof with no walls.

### Code host

**GitHub.** Organisation owners can read the audit log at Organisation > Settings > Logs > Audit log. The audit log REST API and log streaming require GitHub Enterprise Cloud, so check the plan before writing automation:

```bash
gh api "/orgs/<ORG>/audit-log" -f phrase='action:org.add_member' --paginate 2>/dev/null | head -c 2000
gh api "/orgs/<ORG>/members" --paginate -q '.[].login' | wc -l
gh api "/repos/<ORG>/<REPO>/branches/main/protection" 2>/dev/null
```

Force pushes are not reliably present as a distinct audit log action. The reliable detection is the organisation `push` webhook payload, which contains a `forced` boolean field. That is your force push alarm.

**GitLab.** Audit events live at Group > Secure > Audit events (SaaS Premium and above) or Admin Area > Monitoring > Audit Events (self managed). Push rules and protected branch changes are recorded there.

**If you have no admin access to the code host yet:** stop and request it. Detection without read access to the audit log is not possible, and a read-only audit log grant is the least controversial access request a security hire can make.

### When you have access to nothing at all

Do not stall. Three things are still possible on day one:

1. Write the signal list from the crown jewels and the threat model. That is thinking work and needs no access.
2. Write the response paragraph for each signal. Also thinking work.
3. Send the access request messages below, and log each one in `ACCESS-LOG.md` with the date, the person asked, and the scope requested.

## Ask the human

Ask these as closed questions, one at a time, and record the answers in `SECURITY-STATE.md`:

1. If you had to name the one system whose compromise ends the company, is it the production database, the cloud account, or the code host?
2. Do we have a single identity provider that everyone logs in through, yes or no? If yes, which one?
3. Which cloud provider holds production: AWS, GCP, Azure, more than one, or none because we are on a platform as a service?
4. Is there an existing log platform in use today (Datadog, Splunk, Sumo Logic, Elastic, Grafana, cloud native only, or nothing)?
5. Is there an on-call rotation for engineering today, yes or no? If yes, what paging tool?
6. Who is allowed to wake someone up at 3am for a security event, and has anyone ever done it?
7. Are we contractually committed to any monitoring or alerting language in a customer contract? (Cross reference `co-3-existing-commitments.md`.)
8. What is the monthly budget I can spend without a further approval, in dollars?

### Copy-pasteable: request read access to the audit logs

> Hi <name>. I am setting up basic security monitoring and I need read-only access to the audit logs for four systems: our identity provider, our cloud provider, our code host, and our chat platform. To be specific, I am asking for the audit log viewer role only, not administrative rights, and not access to customer data. Concretely that would be: the audit log reader role in <identity provider>, a read-only role in <cloud provider> scoped to CloudTrail or the equivalent audit log, organisation owner or audit log read in <code host>, and workspace admin read in <chat platform>. The goal is to be able to answer "did someone break in" without having to ask an engineer to run queries for me during an incident. Happy to do this over a call if that is easier. Can you grant these this week, or tell me who owns each one?

### Copy-pasteable: ask engineering what already alerts

> Quick question for the team. Do we have any alerts today that would fire if someone logged into the AWS or GCP root account, created a new access key, or turned off audit logging? I am not proposing to build anything yet, I am trying to find out what already exists so I do not duplicate it. If the answer is "we have Datadog monitors" or "we have nothing", both are useful answers. Where do those alerts go today, and who actually reads that channel?

## The signal catalogue (reference)

Each entry gives: what it detects, where the log comes from, the rough query or built-in alert, the expected false positive volume, and the response action. Verify exact event names in your own console before writing a rule. Vendors rename fields.

### 1. Cloud root or break-glass account use

- **Detects:** the single highest privilege identity in your cloud being used at all. In a healthy org this fires roughly never, which is what makes it perfect.
- **Log source:** AWS CloudTrail (`userIdentity.type = "Root"`, event `ConsoleLogin`), GCP Cloud Audit Logs for the organisation administrator principal, Azure Activity Log plus Entra ID sign-in logs for the Global Administrator break-glass account.
- **Rule:** AWS, a CloudWatch Logs metric filter on the CloudTrail log group, or an EventBridge rule. Logs Insights version for hunting: `fields @timestamp, sourceIPAddress, eventName | filter userIdentity.type = "Root" | sort @timestamp desc | limit 50`. GCP, a log based alerting policy on the audit log filtered by the break-glass principal email. Azure, an Activity Log alert plus a sign-in log alert on the break-glass user object id.
- **False positives:** near zero. Expect fewer than one per quarter, usually a planned billing change.
- **Response:** confirm with the named owner within fifteen minutes. If unconfirmed, treat as a confirmed incident, open the `dr-1-incident-response-plan.md` flow, and rotate the root credential.

### 2. New or changed third-party OAuth application grant

- **Detects:** an employee, or an attacker using an employee's session, authorising an external application to read your mail, files, code, or customer records. This is the Salesloft Drift pattern from 2025, where stolen refresh tokens for one widely installed integration were used to query data across more than seven hundred organisations without touching a single endpoint.
- **Log source:** Google Workspace OAuth log events; Microsoft 365 Entra ID audit log, "Consent to application" and "Add service principal" operations; Slack app install events (audit log API requires Enterprise Grid, otherwise rely on the admin approval queue); GitHub organisation audit log OAuth and GitHub App events.
- **Rule:** prefer the built-in approval workflow over an alert. Turn on admin approval for third-party app installation in each platform, which converts the detection into a prevention plus a queue you review. Where an alert is still wanted, alert on grants that include broad scopes (anything containing `mail`, `drive`, `repo`, `admin`, or `offline_access`).
- **False positives:** high if you alert on every grant, roughly five to twenty per week at fifty people. Near zero if you scope to high privilege grants only.
- **Response:** identify the business owner, confirm the app is intentional, record it in the OAuth grant register, revoke if unclaimed. Keep a per-platform revocation runbook with the exact admin URL, and test it once before you need it.

### 3. Multi-factor authentication method changed, removed, or reset

- **Detects:** account takeover in progress. Attackers who have a password almost always need to add their own second factor, and helpdesk-driven factor resets are a standard social engineering path.
- **Log source:** identity provider audit log. Google Workspace login audit log (two step verification events), Entra ID audit log (authentication method registered or deleted), Okta System Log (factor deactivate, reset, enrol).
- **Rule:** alert on factor deactivation and factor reset for any account. Alert on factor enrolment only for accounts holding administrative roles, otherwise onboarding will drown you.
- **False positives:** low. Roughly one to three per month at fifty people, mostly genuine lost phones.
- **Response:** contact the user out of band, on a channel that is not the account in question, and confirm they made the change. If they did not, disable the session and treat as an incident.

### 4. New administrator or privilege escalation, anywhere

- **Detects:** an attacker granting themselves persistence, or a well meaning employee handing out owner rights.
- **Log source:** identity provider admin role grants, cloud IAM policy attachments (AWS `AttachUserPolicy`, `AttachRolePolicy`, `PutUserPolicy`, `CreateUser`; GCP `SetIamPolicy`; Azure role assignment write), code host organisation role change (GitHub `org.update_member`, `org.add_member`), and SaaS admin grants in the tools holding customer data.
- **Rule:** one alert per platform. AWS Logs Insights hunting version: `fields @timestamp, userIdentity.arn, eventName, requestParameters.policyArn | filter eventName in ["AttachUserPolicy","AttachRolePolicy","PutUserPolicy","CreateUser"] | sort @timestamp desc`.
- **False positives:** moderate during hiring or a reorganisation, roughly two to five per month. Reduce by excluding changes made by your infrastructure-as-code deploy identity, and separately alert if that identity's own permissions change.
- **Response:** match the change to a ticket or an approved request. If there is no ticket, ask the actor directly. Record accepted exceptions in `DECISION-LOG.md`.

### 5. New long-lived cloud credential created

- **Detects:** the creation of a static key that can be copied, committed, or stolen. Evan Johnson's 2019 framing still lands: "If you run on AWS, do you have engineers with AWS API Keys running on their laptops? Holy cow."
- **Log source:** AWS CloudTrail `CreateAccessKey`; GCP `google.iam.admin.v1.CreateServiceAccountKey`; Azure Activity Log for service principal credential addition, visible in Entra ID audit logs as "Add service principal credentials".
- **Rule:** alert on every occurrence. In a modern setup using single sign on for humans, roles for workloads, and OpenID Connect federation for continuous integration, this should be zero.
- **False positives:** low once federation is in place, roughly zero to two per month. High before that, which is itself the finding.
- **Response:** ask why a static key was needed, offer the federated alternative, and set a deletion date. Log the key in `SECURITY-STATE.md` under secrets, and cross reference `se-3-secrets-and-keys.md`.

### 6. Audit logging disabled, deleted, or diverted

- **Detects:** an attacker covering tracks, and also a genuine misconfiguration that would silently blind every other detection on this list.
- **Log source:** AWS CloudTrail `StopLogging`, `DeleteTrail`, `UpdateTrail`, `PutEventSelectors`, `DeleteFlowLogs`; GCP audit log sink deletion or an audit config update on the organisation; Azure diagnostic setting delete.
- **Rule:** alert on every occurrence, and route it higher than the rest. This is the one alert that should page even when others only notify.
- **False positives:** near zero, expect fewer than one per quarter.
- **Response:** treat as an incident until proven otherwise. Confirm the trail is restored, then confirm what happened during the gap by using a second log source.

### 7. Continuous integration workflow change or self-hosted runner registration

- **Detects:** an attacker turning the build system into a deployment mechanism for their own code. The pipeline holds every secret, runs untrusted third-party code by design, and has no human watching the screen. The March 2025 `tj-actions/changed-files` compromise, where a mutable tag used by tens of thousands of repositories was repointed at a credential-dumping payload, is the canonical case.
- **Log source:** code host push webhook or pull request events filtered to workflow definition paths, plus the audit log entries for runner registration.
- **Rule:** the cheapest version needs no log platform at all. Add a code owners rule requiring security review on `.github/workflows/**` (or `.gitlab-ci.yml` and any included templates) with a required review, then alert on any change to the branch protection ruleset itself. To hunt historically: `git log --since="30 days ago" --name-only --pretty=format:'%h %an %ad %s' -- .github/workflows/`. For runners, search the organisation audit log for `self_hosted_runner`.
- **False positives:** moderate. Legitimate workflow edits happen weekly at an active startup, so treat this as a review queue rather than a page.
- **Response:** read the diff. Look specifically for new third-party actions, unpinned tags in place of commit hashes, added secret references, and new outbound network calls. See `07-modern-cells.md`.

### 8. Branch protection bypassed, changed, or a force push to the default branch

- **Detects:** code reaching production without review, which is the mechanism by which most malicious insider and stolen-token scenarios actually ship.
- **Log source:** GitHub audit log entries in the `protected_branch` family (policy override, destroy, ruleset update), or the `push` webhook with `forced: true`. GitLab audit events for protected branch and push rule changes.
- **False positives:** low, roughly one to two per month, usually a genuine emergency deploy.
- **Response:** require a written reason in the alert thread within one working day. Accumulate these and use the count as a metric when you argue for a proper break-glass process. See `05-metrics-and-comms.md`.

### 9. Impossible travel or first login from a new country

- **Detects:** a stolen session or password being used from somewhere the human is not.
- **Log source:** identity provider sign-in logs. Google Workspace surfaces this as a "suspicious login" alert in the Alert center on all editions. Entra ID surfaces "atypical travel" under risk detections, which requires a premium licence tier. Okta has behaviour detection rules in sign-on policy.
- **Rule:** use the built-in first. Building your own geolocation velocity rule is a classic first-security-hire time sink with a terrible ratio of effort to value.
- **False positives:** high for a remote or travelling workforce, roughly three to ten per week at fifty people if applied to everyone. Scope it to accounts with administrative roles or access to customer data and it drops to under one per week.
- **Response:** contact the user out of band. If unconfirmed, revoke sessions and force reauthentication. Note that revoking sessions is a mutating action, see the danger zone.

### 10. Public exposure of a storage bucket or data store

- **Detects:** the single most common cause of a startup data breach, which is a configuration mistake rather than an exploit.
- **Log source:** AWS CloudTrail `PutBucketPolicy`, `PutBucketAcl`, `DeletePublicAccessBlock`; GCP `storage.setIamPermissions` granting `allUsers` or `allAuthenticatedUsers`; Azure Activity Log for blob container public access changes.
- **Rule:** prefer prevention. AWS S3 Block Public Access at the account level, GCP organisation policy constraining domain restricted sharing and public access prevention, Azure storage account setting to disallow blob public access. Then alert on any attempt to change those settings. Also re-run a posture scanner weekly (Prowler and ScoutSuite are free) and alert on the diff, not on the score.
- **False positives:** near zero once prevention is in place.
- **Response:** revert immediately if the change is unexplained, then determine whether the data was accessed while public by checking access logs. Public exposure of customer data is a notification-triggering event, so involve legal early. See `co-4-data-inventory-and-framework.md`.

### 11. Production database access outside the normal path

- **Detects:** a human querying customer data directly, which is both an insider risk and the last step of most external compromises.
- **Log source:** this one is harder because cloud audit logs usually cover the control plane, not the data plane. Practical sources are the bastion or session broker (AWS Systems Manager Session Manager `StartSession` events in CloudTrail, Teleport audit log, Tailscale SSH session logs), the database's own audit extension (pgaudit for PostgreSQL, the general log or audit plugin for MySQL, database auditing in the managed service), and the internal admin tool's log if one exists.
- **Rule:** start with the access path, not the query. Alert on any interactive production database session at all, and count on there being few.
- **False positives:** depends entirely on engineering culture. If it fires twenty times a week, the finding is that engineers routinely query production by hand, and that belongs in `RISK-REGISTER.md` rather than in a tuning exercise.
- **Response:** confirm the session had a ticket or a customer support reason. Over time, push the work into an audited internal tool.

### 12. Mass data export or bulk download

- **Detects:** exfiltration, and departing employee data theft, which is far more common than either.
- **Log source:** Google Workspace Drive audit log download and copy events plus the Data export tool; Microsoft Purview audit log for bulk downloads and eDiscovery exports; the customer relationship management platform's data export log; the data warehouse query log for unusually large result sets; the code host's repository archive and clone events where available.
- **Rule:** threshold based, for example more than one hundred files downloaded by one user in one hour. Set the threshold by measuring a normal week first, never by guessing.
- **False positives:** moderate until tuned, and heavily dependent on whether your team syncs whole drives locally.
- **Response:** correlate with the human resources offboarding list before contacting anyone. Most hits are a departing employee, and that conversation belongs to the people team, not to you. See `cs-3-onboarding-offboarding.md`.

### 13. Endpoint detection alerts

- **Detects:** malware, infostealers, and unsigned tools running on employee laptops. Infostealer to session cookie to software as a service to cloud is now the dominant breach chain for small companies.
- **Log source:** whichever endpoint detection and response product is deployed, or the built-in tooling if none is (macOS with a mobile device management platform reporting XProtect and Gatekeeper state, Windows with Microsoft Defender reporting into the security portal).
- **Rule:** route critical and high severity only. Route medium and low to a weekly review, never to the alert channel.
- **False positives:** vendor dependent, typically one to five per week at fifty seats before tuning, most of them developer tooling.
- **Response:** isolate the device, which is a mutating action, then rotate every credential that laptop could reach in the last thirty days. See `cs-2-endpoint-security.md`.

### 14. Repeated authentication failure and multi-factor fatigue patterns

- **Detects:** password spraying, credential stuffing, and push bombing where an attacker repeatedly triggers approval prompts until the user taps accept.
- **Log source:** identity provider sign-in logs, filtering on failure outcomes and on repeated push challenges to the same user in a short window.
- **Rule:** alert on more than five denied push challenges to one user within ten minutes, and on any successful login that follows a burst of failures. Do not alert on raw failed login counts; internet background noise makes that useless.
- **False positives:** low once you filter on the burst-then-success pattern, roughly one to two per month.
- **Response:** contact the user, confirm they did not approve anything, then move the account to phishing resistant authentication. Number matching and passkeys eliminate this class of attack, so this signal should shrink as `cs-1-identity-and-access.md` progresses.

### 15. Corporate domain name resolution anomalies

- **Detects:** malware calling home and employees reaching known-bad infrastructure. This was one of Evan Johnson's four named starting signals in 2019.
- **Log source:** the resolver. In 2019 that meant office network equipment. In 2026, with a remote workforce, it means a managed resolver deployed by the mobile device management platform, or the endpoint agent's network telemetry.
- **Rule:** use the resolver's own blocklists and alerting rather than building your own. Free and low cost managed resolvers exist and take under an hour to deploy through device management.
- **False positives:** low with a reputable feed.
- **Response:** identify the device and the process, then treat it as an endpoint compromise until disproved.

## Where the sixteenth signal comes from: the compromise assessment hunt list

The catalogue above is a starting set, not the finished set. The best source of signals that are actually specific to this company is the compromise assessment in [dr-0-compromise-assessment.md](dr-0-compromise-assessment.md), which is the retrospective sweep for "are we already compromised" that normally runs in the first two weeks.

**The hunt list and the alert list are two different artifacts and must not be merged.** A hunt query is retrospective and manual: a human runs it once, by hand, over a window of history that is about to expire, reads the whole result set with judgement, and accepts that it is slow and noisy because it only runs once. An alert rule is prospective and automated: it runs forever without a human, fires on a single event, must be quiet enough that a person still reads the hundredth one, and needs a written response paragraph before it is switched on. Copying a hunt query straight into an alert rule is one of the most reliable ways to produce the alert-fatigue failure described below, because a query tuned for "show me everything so I can eyeball it" becomes a firehose when it runs continuously.

Use the hunt to generate candidates, then convert deliberately:

1. **Take the hunt output, not the hunt query.** For every finding, near miss, or "I could not answer that question" from DR-0, write down the *event* that would have made it visible sooner. That event is the candidate signal.
2. **Apply the crown jewel test from walk step 1.** If the candidate does not trace to a crown jewel, it goes in `RISK-REGISTER.md` as a visibility gap rather than becoming a rule.
3. **Estimate volume before writing the rule.** Run the candidate as a one-off query over the last thirty days and count the hits. More than about four hits a week and it is a review queue, not an alert. This is read-only and costs nothing but query time.
4. **Write the response paragraph first,** exactly as in walk step 4. No response, no rule, no exception.
5. **Record the origin.** In the `SECURITY-STATE.md` signal table, note that the row came from the compromise assessment. Six months later somebody will ask why the rule exists, and "because the hunt in week two found the log was empty" is the answer that keeps it alive.

Three categories reliably fall out of a compromise assessment and are worth converting:

- **A log that was empty, truncated, or missing when the hunt needed it.** That does not become an alert about attackers. It becomes catalogue entry 6 (audit logging disabled) plus the heartbeat check described in the failure modes below, plus a retention decision that belongs to [dr-3-logging-consumption-model.md](dr-3-logging-consumption-model.md).
- **A dormant object the hunt found and could not explain**: an unused administrator account, a forgotten static key, an OAuth grant nobody claims, a self-hosted runner nobody registered. The durable signal is not "this object exists", it is "an object of this kind was created or used again". That maps to catalogue entries 2, 4, 5, and 7.
- **A path the hunt could not check at all**, usually because there was no log. Record it in `RISK-REGISTER.md` with the reason, an owner, and a review date. It becomes a signal later, when the log exists, and not before.

Two constraints carry over from DR-0 and are not negotiable here. First, hunting is read-only. Nothing in this section authorises running a scan, a test, or any active probe against any system, including the company's own, without written authorisation from the system owner. Second, if a hunt turns up something that looks live rather than historical, this cell stops and [dr-1-incident-response-plan.md](dr-1-incident-response-plan.md) takes over. Do not keep writing detection rules while an intrusion is in progress.

## The walk

### Step 1: Write the signal list, no tooling, no access needed

- **Goal:** produce a ranked list that ties every candidate signal to a crown jewel, so that the first thing the human can show anyone is reasoning rather than a dashboard.
- **Do:** take the crown jewel list from discovery step zero. For each one, write the two most likely ways it gets compromised in plain language. Map each to a signal from the catalogue above. If a compromise assessment has already run, pull its unexplained findings and its "I could not check that" gaps into the same list using the conversion procedure in "Where the sixteenth signal comes from" above, because a signal derived from something real that happened at this company beats a signal derived from a catalogue every time. Cut the list to fifteen. Write it into `SECURITY-STATE.md` under `## DR-2 Top security signals` as a table with columns: signal, crown jewel it protects, log source, status (unknown / none / partial / done), evidence, origin.
- **Verify:** every row names a crown jewel. Delete any row that cannot.
- **Time:** two hours.
- **Who else is needed:** nobody. This is the reason this cell can start on day one.

### Step 2: Turn on the free built-in detections

- **Goal:** get real detections firing today without a purchase order, a vendor call, or an engineering ticket.
- **Do:** enable only the genuinely free or trial tier of the vendor-native detection service in the cloud provider, then confirm the identity provider's built-in alert centre notifications are routed to a real inbox, then turn on the code host's secret scanning and push protection if the plan already includes it. Name the tier out loud before you click anything, because the tier above the free one is where the surprise invoice lives:
  - **AWS: Amazon GuardDuty.** Thirty day free trial, then usage based billing. Open the console's usage and cost estimate page for the trial account first and read the projected monthly figure before enabling anywhere beyond a single test account.
  - **GCP: Security Command Center, Standard tier only.** Standard is offered at no additional charge. The Premium tier is paid and is priced against your total cloud spend or your protected resources, which at any real footprint reaches thousands of dollars a month. The Enterprise tier is deprecated: Google shuts it down on 21 May 2027 and migrates organisations to Premium automatically, so do not plan around it.
  - **Azure: Microsoft Defender for Cloud, foundational Cloud Security Posture Management only.** The foundational posture features are free on any Azure subscription. Every named "Defender plan" (Defender for Servers, for Storage, for Containers, for Databases, and the rest) is paid per resource or per hour and is billed separately.
  - Anything above these tiers is a spend decision. It goes through the Danger zone STOP below, unconditionally, with the budget holder's written yes recorded in `DECISION-LOG.md`. There is no threshold under which the agent may skip that approval, and "it is only a trial" is not an exemption, because trials convert to billing silently.
- **Verify:** for each one, take a screenshot showing the enabled state, the tier name, and the notification destination, and record the file path of the screenshot in `SECURITY-STATE.md`.
- **Time:** half a day.
- **Who else is needed:** somebody with administrative rights in each console if the human does not have them yet. This is usually the chief technology officer or the first infrastructure engineer. Enabling any of these is a mutating change to a cloud account, so the account owner approves it explicitly before the agent or the human clicks.
- **Cost note:** at startup scale the free tiers above cost zero and GuardDuty after its trial typically runs ten to a few hundred dollars a month, but that figure scales with account activity and with the number of accounts in the organisation. Estimate before enabling, never after. See also `se-2-understand-the-tech-stack.md`, which makes the same point about telemetry services that bill on data volume.

### Step 3: Create the destination before creating any alert

- **Goal:** make sure alerts land somewhere a human will read, because an alert with no reader is worse than no alert, since it creates false confidence.
- **Do:** do not reflexively create a channel. Channel count is owned by [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md), which sets the size gate, and creating a security channel nobody reads is worse than having none. Apply that gate here:
  - **If the company has no dedicated security alert channel yet and this cell is producing roughly five or fewer alerts a week,** send alerts into the single existing security front door (normally `#security-help`) or to an email alias the human reads daily. A private thread in an existing channel is a legitimate destination.
  - **Only when sustained volume passes roughly five alerts a week** do you split out a dedicated `#security-alerts`. That is dr-4's stated trigger for the split, and it is a volume test, not a preference.
  - **When you do split it,** make the channel private if alert content could contain customer identifiers, which it usually can. Pin a message at the top naming the daily reader and linking to the response runbook index.
  - **Do not create a separate noise or tuning channel until the dedicated alert channel exists.** Before that, mark tuning-period alerts with a prefix such as `[tuning]` in the same destination. A second channel at low volume produces two graveyards instead of one.
  - Creating a channel in the company chat workspace is a change other people see, so agree it with the chat platform owner rather than announcing it afterwards.
- **Verify:** post a test message to whichever destination you chose and confirm the human sees a notification on their phone. Record the destination name in `SECURITY-STATE.md` so DR-1 and DR-4 point at the same place.
- **Time:** thirty minutes.
- **Who else is needed:** a chat platform administrator if channel creation is restricted, and dr-4's front door decision if it has already been made.

### Step 4: Wire the three highest value alerts first

- **Goal:** prove the pipeline end to end with alerts that will almost never fire falsely.
- **Do:** implement, in this order, cloud root or break-glass use, audit logging disabled, and new long-lived cloud credential created. Use the cloud provider's native alerting (CloudWatch metric filter plus Simple Notification Service, GCP log based alerting policy, Azure Activity Log alert) rather than any third-party tool. Write the response paragraph *before* enabling each rule and put a link to it in the alert message body.
- **Verify:** trigger each one safely. For the credential alert, create a key on a throwaway identity, confirm the alert arrives, then delete the key. That is a mutating action and needs a human yes first.
- **Time:** one day.
- **Who else is needed:** an engineer with permission to create alerting resources, unless the human already has it.

### Step 5: Convert application installation from detection into prevention

- **Goal:** remove an entire attack class rather than watching it happen.
- **Do:** switch third-party application installation to admin approval in the identity provider, the chat platform, and the code host organisation. All four of the common platforms ship default-open. This is a twenty minute change with an outsized payoff.
- **Verify:** attempt an installation from a non-admin test account and confirm it lands in an approval queue rather than completing.
- **Time:** one hour plus a week of answering questions.
- **Who else is needed:** administrators of each platform, plus a heads up message to the whole company. Draft that message with `dr-4-company-comms-channel.md`.
- **Warning:** this is user-visible and will generate complaints in week one. Announce it before you enable it, not after.

### Step 6: Add the identity alerts

- **Goal:** cover account takeover, which is the most likely way this company actually gets breached.
- **Do:** enable multi-factor method change alerts, new administrator alerts, and the built-in suspicious login alert. Scope impossible travel to privileged accounts only.
- **Verify:** change your own second factor and confirm the alert fires.
- **Time:** half a day.
- **Who else is needed:** identity provider administrator.

### Step 7: Add the pipeline and code host alerts

- **Goal:** cover the build system, which the 2019 grid does not mention at all and which now holds more privilege than any human at the company.
- **Do:** add code owners on workflow definition paths, alert on branch protection or ruleset changes, alert on force pushes to the default branch using the push webhook `forced` field, and alert on self-hosted runner registration.
- **Verify:** open a pull request that touches a workflow file and confirm the review requirement blocks merge.
- **Time:** half a day.
- **Who else is needed:** code host organisation owner, and a short conversation with the engineering lead so this does not feel like an ambush.

### Step 8: Run a tuning week, then delete

- **Goal:** get to under ten alerts per week, and establish the rule that governs this cell forever.
- **Do:** for one week, log every alert with a one word verdict of true, false, or unclear. At the end of the week, apply the rule: any alert with no documented response gets deleted, and any alert that produced only false positives gets either scoped tighter or deleted. Record every deletion in `DECISION-LOG.md` with the reason, because six months later somebody will ask why you are not monitoring that.
- **Verify:** count the alerts in the channel for the following week and confirm the number is under ten.
- **Time:** one week elapsed, roughly two hours of actual work.
- **Who else is needed:** nobody.

### Step 9: Write down the on-call truth

- **Goal:** stop pretending there is twenty four by seven coverage when there is one person.
- **Do:** write a paragraph in `SECURITY-STATE.md` and in the incident response plan stating exactly what happens overnight and at weekends. The honest answer for a team of one is usually: two or three alert types page a phone at any hour, everything else waits until the next working day, and the engineering on-call rotation is the escalation path if the security hire does not answer within thirty minutes. Get the head of engineering to agree in writing to that escalation path.
- **Verify:** send a test page at an unusual hour, with prior warning, and confirm it arrives.
- **Time:** two hours, plus one conversation.
- **Who else is needed:** head of engineering, and whoever owns the paging tool.

## Decision points

**Build detections on native cloud tooling, or buy a platform?**
DEFAULT: native, free, built-in tooling for the first two quarters. Metric filters, log based alerting policies, activity log alerts, and the identity provider's own alert centre will carry the first ten detections at zero incremental cost. Change this if the company already pays for a log platform that everyone uses, in which case build there so that your detections are visible to the engineers who are already looking, or if a signed customer contract explicitly requires a security monitoring platform.

**One alert channel, or per-severity channels?**
DEFAULT: no dedicated alert channel at all until this cell sustains more than roughly five alerts a week, then exactly one channel for live alerts, and a second one for tuning only when the live channel is already busy. Splitting further at this size guarantees that the low severity channel becomes a graveyard. The full channel list and its size gate live in [dr-4-company-comms-channel.md](dr-4-company-comms-channel.md), which owns internal communication; this cell defers to it rather than inventing its own channels. Change this when total weekly alert volume passes about thirty and a second human joins the team.

**Alert on everything and tune down, or start narrow and expand?**
DEFAULT: start narrow. A first security hire has negative political capital and cannot afford a reputation for noise. Alert fatigue in the first month is the single most common way this cell fails. Change this only for a specific short investigation window with an end date.

**Page a human at night, or queue until morning?**
DEFAULT: page for exactly three things: root or break-glass use, audit logging disabled, and a confirmed endpoint compromise on a device holding production access. Everything else queues. Change this once there are two or more people who can respond.

**Free open source posture scanner, or a paid cloud security platform?**
DEFAULT: free scanner (Prowler or ScoutSuite) on a weekly schedule, and alert on the diff between runs rather than on the absolute finding count. Change this when the cloud footprint passes roughly five accounts or subscriptions, or when a customer or auditor requires continuous monitoring evidence, at which point expect a paid platform in the range of roughly fifteen to sixty thousand dollars per year and negotiate hard.

**Managed detection and response service, or do it yourself?**
DEFAULT: do it yourself at this size. Managed services typically start around thirty to eighty thousand dollars per year and require mature log plumbing to be useful, so buying one before step 8 above means paying somebody to watch a feed you have not tuned. Change this if the company has a genuine twenty four by seven availability commitment in customer contracts, or if headcount growth outpaces the security team by more than about four to one.

## Danger zone

Every item here requires an explicit human yes, spoken or written, before the agent runs it. State the risk plainly, wait for the answer, and record the approval in `DECISION-LOG.md`.

- **Revoking user sessions or resetting a password in response to an alert.** STOP. This logs a real person out of everything, possibly mid customer call. If the alert turns out to be a false positive you have caused an outage for one employee and burned trust. Confirm out of band first unless the evidence is unambiguous.
- **Isolating or quarantining an endpoint from the endpoint detection console.** STOP. This can render a laptop unusable and, on some products, is not cleanly reversible without the device being online. Never do this to an executive's device without telling them first, and never during a board meeting.
- **Disabling or deleting an OAuth grant.** STOP. Revoking a grant breaks whatever integration depended on it, which may be a production data pipeline or the revenue team's tooling. Identify the business owner before revoking anything that is not obviously malicious.
- **Enabling a new cloud detection service across an entire organisation.** STOP for cost. Usage based services can produce a surprising bill in a large or noisy account. Check the console's cost estimate, then get the budget holder's yes in writing.
- **Turning on admin approval for application installation.** STOP for user visibility. This is the right change and it will still generate complaints. Announce first, pick a low traffic day, and have the approval queue watched for the first week so people are not blocked.
- **Ingesting logs into a paid platform without a volume estimate.** STOP. Log ingest pricing is per gigabyte and cloud audit logs are larger than people expect. Estimate volume first using the log group or bucket size, then commit. See `dr-3-logging-consumption-model.md`.
- **Enabling data plane audit logging on a busy database.** STOP. Full query auditing can add measurable latency and a large amount of log volume. Test on a replica or a staging instance and agree the change with the database owner.
- **Sending an alert channel to a public chat channel.** STOP. Alert bodies frequently contain user email addresses, internet protocol addresses, and sometimes customer identifiers. Keep the channel private.

## Do not do this yet

- **Do not buy a SIEM in the first ninety days.** You do not yet know what your log volume is, what your detections are, or whether anyone will read the output. Every dollar spent here before step 8 is a dollar spent on a tool that will be reconfigured or abandoned.
- **Do not aim for full ATT&CK coverage, or any coverage matrix.** It is a lovely artifact for a team of eight. For a team of one it is a way to spend a quarter producing a spreadsheet instead of a detection.
- **Do not write custom correlation logic.** Multi-event correlation rules are the highest maintenance and lowest yield detections available to you. Single event, high signal rules win at this size.
- **Do not centralise all logs before you have any detections.** Centralisation is a prerequisite for a *later* stage. Detection can and should start against logs where they already live.
- **Do not build your own geolocation, user behaviour analytics, or anomaly scoring.** Use whatever the identity provider ships. Your version will be worse and will take a month.
- **Do not deploy a network intrusion detection sensor.** In a cloud native remote company there is often no network to sense, and the traffic that matters is encrypted anyway.
- **Do not add alerts because a vendor's default rule pack includes them.** Every rule you enable is a rule you own forever. The default pack is designed to demonstrate value in a trial, not to fit your company.
- **Do not promise a mean time to detect number to leadership yet.** You do not have the data. Promise alert coverage of named crown jewels instead, and see `05-metrics-and-comms.md` for what to report in month one.

## Evidence to capture

- `SECURITY-STATE.md`, section `## DR-2 Top security signals`: the signal table (signal, crown jewel, log source, status, evidence path), the alert destination channel name, the name of the daily reader, and the current weekly alert count.
- `SECURITY-STATE.md`, section `## DR-2 Log coverage`: for each of cloud, identity, code host, chat, endpoint, whether audit logging is enabled, the retention period in days, and who can read it.
- `RISK-REGISTER.md`: one entry per crown jewel that has no signal covering it, with severity, the owner, and whether the gap is accepted and by whom.
- `DECISION-LOG.md`: every alert you deleted or declined to build and why, every tooling choice with the alternative you rejected, and every danger zone approval with the date and the approver.
- `ACCESS-LOG.md`: each audit log read access request, who was asked, the date, and the outcome.
- `90-DAY-PLAN.md`: mark DR-2 progress against steps 1 through 9.

Artifacts an auditor or an enterprise customer will ask for, so produce them as a side effect rather than as separate work: a list of monitored security events, evidence that logs are retained for a defined period, evidence that alerts are reviewed by a named person, a sample alert with its documented response, and evidence of at least one test of the alerting path. Screenshots with a visible date are acceptable evidence at this stage. Store them in the state directory, not in a personal drive.

## Cost and effort

- Steps 1 through 4, roughly two to three days of one person's time, zero to a few hundred dollars per month if the cloud native detection service is enabled.
- Steps 5 through 7, roughly two days, zero dollars. These are configuration changes in tools you already pay for.
- Steps 8 and 9, one week elapsed and about four hours of work, zero dollars.
- Free options worth using before spending anything: cloud provider native alerting, identity provider alert centres, code host secret scanning and push protection, Prowler and ScoutSuite for posture diffs, Wazuh if you genuinely need a free open source agent and log platform, and Osquery for endpoint questions.
- Rough paid bands, for planning only, and always verify current pricing directly: cloud native threat detection, tens to low hundreds of dollars per month at startup scale. A general purpose observability platform with a security module, commonly ten to forty thousand dollars per year once log volume is real. A dedicated security data platform, commonly starting in the high tens of thousands per year. Managed detection and response, commonly thirty to eighty thousand dollars per year. None of these belong in the first ninety days.
- Ongoing cost after setup: about two hours per week for triage and about one day per quarter for tuning and testing. Budget it explicitly, because the cell decays silently when nobody has the hours.

## 2026 notes

The 2019 advice named four starting signals: cloud key usage, a cloud posture tool, identity provider application access, and corporate office domain name resolution. Three of those four are still correct. What changed:

- **Corporate office domain name resolution is now corporate device domain name resolution.** The office network largely stopped being where employees work. The equivalent control is a managed resolver pushed by the device management platform, not equipment in a wiring closet.
- **The identity layer became the primary breach path, not a supporting one.** The dominant 2026 chain is an infostealer on a laptop, a stolen session cookie, a software as a service tenant, and then the cloud. Detections 2, 3, 4, 9, 13, and 14 in the catalogue above all exist because of this, and collectively they matter more than anything you can detect in production.
- **OAuth grants became a detection category of their own.** Refresh tokens survive password rotation and second factor changes, are invisible to endpoint tooling, and are not covered by single sign on policy. The 2019 grid has no cell for this. Treat the grant register and the revocation runbook as first class detection artifacts.
- **The build pipeline needs its own detections.** It has cloud deployment rights, package publish rights, repository write access, and secret access, with no second factor and no human at the keyboard. Detections 7 and 8 exist because of the 2025 wave of continuous integration and package registry compromises.
- **Prevention beats detection more often than it did in 2019.** Several catalogue entries above, notably application installation approval and public storage blocking, are better implemented as a policy that stops the action than as an alert that observes it. A first security hire in 2026 should always ask "can I make this impossible" before asking "can I detect this".
- **Alert volume expectations have not changed at all.** A one person team can sustainably handle roughly ten alerts per week. That number is set by human attention, not by technology, and no amount of tooling raises it.

## Failure modes

**The channel nobody reads.** Alerts are wired, the channel exists, and after three weeks nobody opens it. *Early tell:* nobody reacts to an alert message for more than forty eight hours. *Recovery:* cut the rule count until the volume is low enough that each alert feels like an event, and put a named daily reader in the channel topic.

**Building the log warehouse instead of the detections.** Three months disappear into pipelines, parsers, and cost tuning, and nothing has ever fired. *Early tell:* the human is talking about ingest volume and retention tiers before a single alert exists. *Recovery:* stop, do steps 4 through 6 against native tooling this week, and resume the log project afterwards with a real requirement.

**Alerts with no response.** A rule fires, and the human genuinely does not know what to do, so they do nothing and feel worse. *Early tell:* the alert thread has a message and no reply. *Recovery:* apply the deletion rule. No documented response, no alert.

**Tuning by silencing.** Noisy rules get muted rather than fixed or deleted, so the channel looks healthy while coverage quietly goes to zero. *Early tell:* muted rules that nobody can explain. *Recovery:* audit every rule quarterly and confirm each one has fired at least once in testing, even if never in anger.

**Detection without the ability to respond.** An alert fires at 2am, and the human has no rights to revoke a session, isolate a device, or disable a key. *Early tell:* the response paragraph contains the phrase "ask an engineer to". *Recovery:* request the technical permissions needed to contain, before the first incident, and record the request in `ACCESS-LOG.md`. Holding the permission is not the same as being allowed to use it. Everything in the Danger zone above still needs an explicit human yes at the moment you act. The only actions that may ever be pre-authorised are the two agreed in [`dr-4-company-comms-channel.md`](dr-4-company-comms-channel.md) step 10, during a declared incident: revoking a named human employee's active sessions and refresh tokens, and revoking a third party application's access grant. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.

**Chasing the vendor's rule pack.** Someone enables two hundred default rules during a trial and the channel becomes unusable within a day. *Early tell:* more than thirty alerts in a week. *Recovery:* disable everything, re-enable only the rules that map to a crown jewel, and record the decision.

**Silent log loss.** The trail was deleted, the sink broke, or the retention was quietly reduced, and none of the other detections have fired in weeks. *Early tell:* a suspiciously quiet channel. *Recovery:* add a heartbeat check that alerts when a log source produces no events for twenty four hours. This is the least glamorous and most valuable rule in the whole catalogue.

## Related cells

- [`dr-0-compromise-assessment.md`](dr-0-compromise-assessment.md) is the retrospective, manual hunt for an intrusion that already happened. Its output is the best source of company-specific candidates for this catalogue, and its queries are not alert rules.
- [`dr-1-incident-response-plan.md`](dr-1-incident-response-plan.md) is the other half of this cell. A signal with no response plan is decoration.
- [`dr-3-logging-consumption-model.md`](dr-3-logging-consumption-model.md) covers where logs live, how long they are kept, and what they cost. Load it before this file whenever the conversation is about a SIEM, retention, or log spend.
- [`dr-4-company-comms-channel.md`](dr-4-company-comms-channel.md) owns the internal channel list, including whether a dedicated alert channel should exist yet, and how the rest of the company reports things to you.
- [`cs-1-identity-and-access.md`](cs-1-identity-and-access.md) produces most of the signals in this catalogue and prevents several of them from ever being needed.
- [`cs-2-endpoint-security.md`](cs-2-endpoint-security.md) is where endpoint alerts and device isolation live.
- [`cs-3-onboarding-offboarding.md`](cs-3-onboarding-offboarding.md) is the correct owner of most mass export alerts.
- [`se-3-secrets-and-keys.md`](se-3-secrets-and-keys.md) explains why the static credential alert should be near zero.
- [`07-modern-cells.md`](07-modern-cells.md) covers continuous integration, supply chain, cloud posture, and software as a service sprawl in depth.
- [`06-2019-to-2026-delta.md`](06-2019-to-2026-delta.md) explains why the original four signals moved.
- [`05-metrics-and-comms.md`](05-metrics-and-comms.md) covers what to report upward about detection without over-promising.
- [`03-90-day-plan.md`](03-90-day-plan.md) places this cell in the overall sequence.
