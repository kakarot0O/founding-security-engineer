# CS-2: Endpoint security

> **Grid coordinate:** CS-2, Corporate Security, cell 2.
> **Original 2019 wording:** "Endpoint 🎁" (the gift emoji was the speaker's marker that endpoint security is the cheap win, the tablestakes item you should just go buy). His note: "It's tablestakes for the long term. It's better to get it sooner rather than later, because it's easier the fewer the people you have."
> **Load when:** the human asks about laptops, devices, MDM (mobile device management), antivirus, EDR (endpoint detection and response), disk encryption, browser extensions, infostealer malware, a lost or stolen laptop, BYOD (bring your own device), contractor machines, or a customer questionnaire asks "do you manage and encrypt employee devices". Also load whenever CS-1 (identity) work surfaces a session-theft or token-theft question, because the answer to that usually lives on the laptop, and whenever someone proposes enrolling devices belonging to people employed in another country, which has consultation and privacy constraints covered in Multi-country employment constraints below.

## Why this cell exists

The laptop is where the company actually gets breached. An attacker does not usually break your web application: they get one employee to run one program, that program steals the passwords and the logged-in browser sessions saved on that machine, and then the attacker walks into your email, your code host, and your cloud console as that person, with the multi-factor prompt already satisfied because they stole the session cookie rather than the password.

Everything else in corporate security assumes the laptop is trustworthy. Your identity provider trusts the device to hold the session. Your code host trusts the device to hold the git credentials. Your cloud trusts the device to hold the command line credentials. If the device is owned by an attacker, none of those trust assumptions hold, and no amount of policy fixes it.

The good news is that this is the most solvable cell on the grid. The controls are well understood, mostly built into the operating system, and cheap. The bad news is that it is a people problem: you are asking every person in the company to let you install something on the computer they use all day, and if you handle that badly you burn the political capital you need for everything else.

## Definition of done

Good enough for a 20 to 100 person startup:

- [ ] You have a **device inventory** with one row per machine: serial number, model, operating system and version, assigned human, ownership (company or personal), enrolment status, and last check-in date. It is generated from a tool, not typed by hand, and it reconciles against the HR (human resources) roster and the finance purchase records.
- [ ] Every company-owned laptop is **enrolled in an MDM** (mobile device management tool, the thing that lets you push settings and see the state of a machine remotely). Zero unenrolled company laptops, including the founders' machines.
- [ ] **Full disk encryption is on and the recovery key is escrowed** to the MDM, on every machine. Verified from the MDM report, not from asking people.
- [ ] **Automatic operating system and browser updates are enforced with a deadline**, not a suggestion. A machine that ignores updates for N days gets forced. Pick N between 7 and 14 for critical patches.
- [ ] **Screen lock** with a password on wake, after at most 5 minutes idle.
- [ ] **Host firewall on**, inbound connections blocked by default.
- [ ] A **documented decision about local administrator rights**, written down with the reason. Either everyone is a local admin and you compensate with detection, or nobody is and you have a way to grant it temporarily. Both are defensible. Undocumented drift is not.
- [ ] **Managed browser policy** on the browser people actually use, with an extension allowlist or at minimum a blocklist plus visibility into what is installed.
- [ ] Malware protection: at minimum the built-in defenses are on and verified. Ideally a real EDR agent on every machine with alerts going somewhere a human reads.
- [ ] A **lost or stolen device runbook** that has been read out loud once by the person who would run it at 2am.
- [ ] A written **BYOD and contractor policy**: what personal or contractor devices may touch, and what they may not.
- [ ] For any population employed outside your own jurisdiction, a **written clearance from people operations or counsel** that enrolment may proceed, plus the transparency notice that was given to those people at enrolment. See Multi-country employment constraints below.
- [ ] A **decision recorded about which machines hold the only copy of something**, and what happens to that data if the machine dies. See [m-6-backups-and-recovery.md](m-6-backups-and-recovery.md).

Explicitly **not** required at this size: a data loss prevention (DLP) product, fleet-wide full disk backup for every employee (targeted backup for the small number of machines that hold the only copy of something is a different matter and is covered below), a hardened custom operating system image, USB port blocking, a virtual desktop infrastructure, application allowlisting on every machine (Santa or WDAC are excellent and out of scope for your first quarter), mobile threat defense agents on phones, or an ISO 27001 style asset management procedure document. Those are all real controls. None of them belongs in your first ninety days.

## Discovery

Your first job is enumeration, because you cannot secure what you cannot count. At most startups nobody knows how many laptops exist. The count from finance, the count from IT, and the count from the identity provider will all disagree, and the difference is your risk.

### Step 1: build the inventory from four independent sources, then reconcile

1. **Finance or the company card.** Every laptop was bought with money. Ask for every hardware purchase since founding: vendor, date, serial or order number, who received it. This is the only source that catches machines nobody ever enrolled.
2. **The identity provider.** Every laptop signs into something. Sign-in logs give you device names, operating systems, and browser user agents.
3. **The MDM or device management console**, if one exists.
4. **The people.** A single spreadsheet column asked in the company chat: "what is the serial number of every company machine you currently have, including the old one in your closet."

Any machine appearing in fewer than all four is a finding.

### Vendor-branched read-only discovery

**Identity provider device signals (this is the highest yield first move, because it needs no agent on any machine):**

- Google Workspace: Admin console at `admin.google.com`, then Devices, then Overview and Endpoints. Google Workspace has basic endpoint management on by default for anything that signed into a Google account, so this list often already exists and nobody has looked at it. Also Reporting, then Audit and investigation, then Login audit log.
- Microsoft 365 or Entra ID: `entra.microsoft.com`, then Devices, then All devices, which shows join type (Entra joined, Entra registered, hybrid) and compliance state. Also `admin.microsoft.com`, then Health, then a device inventory if Intune is licensed.
- Okta: Admin console, then Directory, then Devices, if Okta Verify or Okta Device Access is deployed. Also Reports, then System Log, filtered on `eventType eq "user.session.start"` to see device and browser strings.
- JumpCloud: Admin console, then Devices.
- If the answer is "we do not have an identity provider yet": that is a CS-1 problem, and CS-1 outranks this cell. Say so and go do CS-1 first.

**MDM consoles, if one exists:** Jamf Pro or Jamf Now (macOS), Kandji (macOS), Mosyle (macOS), Microsoft Intune (Windows, macOS, mobile, in the Intune admin center at `intune.microsoft.com`), Google Workspace endpoint management, Fleet (open source, osquery based, cross platform), Hexnode, Rippling IT, Workspace ONE. In every one of these, the report you want is the same: enrolled devices, encryption status, operating system version, last check-in. Export it to CSV and store it.

**Single machine spot checks the human can run on their own laptop right now.** These are all read-only. Run them on the human's machine first, then ask two or three engineers to run them and paste the output.

macOS:

```bash
# Model, serial, and macOS version
system_profiler SPHardwareDataType | grep -E "Model Name|Serial Number|Chip|Memory"
sw_vers

# Full disk encryption (FileVault) status
fdesetup status

# System Integrity Protection
csrutil status

# Host firewall global state
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Automatic update settings
defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist 2>/dev/null
defaults read /Library/Preferences/com.apple.commerce.plist AutoUpdate 2>/dev/null

# Is the machine enrolled in an MDM, and is enrolment user-approved
profiles status -type enrollment

# Configuration profiles installed (needs sudo to see device-level profiles)
sudo profiles -P

# Screen lock: does waking require a password, and after how long
sysadminctl -screenLock status 2>&1

# Local accounts that have admin rights
dscl . -read /Groups/admin GroupMembership

# Installed Chrome extensions on this machine, by extension ID
ls ~/Library/Application\ Support/Google/Chrome/*/Extensions 2>/dev/null
```

Windows (PowerShell, run as a normal user unless noted):

```powershell
# Machine identity and OS build
Get-ComputerInfo -Property CsName,CsManufacturer,CsModel,OsName,OsVersion,OsBuildNumber
(Get-CimInstance Win32_BIOS).SerialNumber

# BitLocker full disk encryption status (elevated shell required)
Get-BitLockerVolume
# or, without PowerShell module:
manage-bde -status

# Built-in antivirus and its real-time protection state
Get-MpComputerStatus | Select-Object AMServiceEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,IsTamperProtected

# Host firewall profiles
Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction

# Local administrators
Get-LocalGroupMember -Group "Administrators"

# Is the device joined or MDM enrolled
dsregcmd /status

# Patch level. Read the build number first: it is the real signal.
(Get-ComputerInfo).OsBuildNumber
# Quick fix engineering entries, for context only. Most modern cumulative
# updates are not registered here, so a short list does NOT mean an unpatched
# machine. Never judge patch level from this alone.
Get-CimInstance Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 10
```

On the patch check specifically: the operating system build number is the number that tells you whether a machine has this month's cumulative update. Compare it against the current build Microsoft publishes for that Windows release. The hotfix list is a legacy view that misses most cumulative updates, so a machine showing three entries can be fully current and a machine showing thirty can be months behind.

Linux (varies by distribution, so check before you trust):

```bash
# Distribution and kernel
cat /etc/os-release; uname -a

# Is the root filesystem on an encrypted LUKS volume
lsblk -o NAME,FSTYPE,MOUNTPOINT
sudo cryptsetup status /dev/mapper/$(lsblk -o NAME,TYPE | awk '$2=="crypt"{print $1; exit}' | tr -d '`|- ')

# Firewall, whichever is present
sudo ufw status verbose 2>/dev/null || sudo firewall-cmd --state 2>/dev/null || sudo nft list ruleset 2>/dev/null | head -20

# Unattended upgrade configuration (Debian and Ubuntu)
cat /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null
# (Fedora and RHEL)
systemctl status dnf-automatic.timer 2>/dev/null

# Users with sudo
getent group sudo wheel 2>/dev/null
```

### When you have no access at all

If you cannot log into any console and cannot run anything on anyone's machine, you can still finish this discovery in a day:

1. Ask finance for the hardware purchase list. Finance almost always says yes to a security hire and almost never needs a ticket.
2. Ask three engineers, one designer, and one salesperson to run the single relevant spot check for their operating system and paste the output into a thread. Five machines is enough to know whether the fleet is healthy or feral.
3. Read the offer letter or handbook for any device language.
4. Record everything you could not check as `unknown` in `SECURITY-STATE.md` under the CS-2 section. Unknown is a legitimate and useful status. Do not write `none` for something you simply could not see.

## Ask the human

Ask these as closed questions, one at a time, and record the answers in `SECURITY-STATE.md` under CS-2:

1. How many people are at the company today, and roughly how many laptops do you believe exist? (Expect the second number to be higher.)
2. What operating systems are in use, and roughly what split? (macOS only, mixed macOS and Windows, or any Linux?)
3. Are laptops bought by the company and shipped to people, or do people use their own machines and get reimbursed?
4. Is there any device management tool in place today, even a trial or a free tier? Name it.
5. Is everyone a local administrator on their own machine right now? (Default answer at a startup: yes.)
6. Which browser do most people use, and is there any policy on extensions?
7. Do contractors, agencies, or offshore developers have access to company systems, and on whose hardware?
8. Has a laptop ever been lost or stolen, and what happened?
9. Who would sign off on spending roughly ten to fifteen dollars per device per month, and what is the approval path?
10. Who is the most senior person most likely to refuse enrolment, and do you have the CEO's explicit backing to include them?

Question 10 matters more than it looks. Endpoint rollouts fail politically, not technically.

### Copy-pasteable message to get the access you need

Send to the person who runs IT, operations, or whoever set up the laptops:

> Hi, I am putting together the first device inventory so we can answer customer security questionnaires and know what we actually have. Three asks, all read-only:
>
> 1. Read-only or admin access to whatever device management tool we use, if we have one. If we do not have one, just tell me that and I will stop looking.
> 2. A list of every laptop or desktop the company has purchased since founding: date, model, serial number if we have it, and who it went to. Finance card statements are fine if that is all that exists.
> 3. Admin console access (read-only is fine to start) to our identity provider so I can pull the device and sign-in report.
>
> I am not going to change any settings without telling you first. The goal this week is only to count what exists and find machines nobody is tracking. Happy to walk through what I find before it goes anywhere else.

Send to a small pilot group when you are ready to enrol:

> Hi, I am setting up device management so we can prove to customers that our laptops are encrypted and patched, and so we can wipe a laptop if one gets stolen. You are in the pilot group of five. Enrolment takes about ten minutes and you can do it whenever you like today or tomorrow. Here is exactly what it does and does not do: it reports your operating system version, disk encryption status, and installed applications, and it lets us push security settings and remotely lock or wipe a company laptop. It does not read your files, your messages, your browsing history, or your personal accounts. If anything about it annoys you or breaks your workflow, tell me and I will fix it before this goes to everyone else. That is the whole point of the pilot.

## The walk

Do these in order. Step 1 produces something useful on day one with no tool purchase and no permission.

**Step 1: Count the machines.**
Goal: a single CSV file listing every device you believe exists, with a confidence marker per row.
Do: pull the four sources from Discovery, reconcile them, and write `devices.csv` next to your state files. Add a `status` column with values `confirmed`, `unaccounted`, or `suspected-personal`.
Verify: the row count matches or exceeds the headcount, and every unaccounted row has a name next to it or an explicit note saying who to ask.
Time: half a day to two days depending on how fast finance responds.
Who else: finance or the office manager, plus whoever runs the identity provider.

**Step 2: Measure the baseline on the machines you can see.**
Goal: know what percentage of the fleet already has encryption, updates, screen lock, and firewall.
Do: run the spot checks from Discovery on five to ten machines across roles, or pull the report from the MDM if one exists. Record percentages, not anecdotes.
Verify: you can state a number like "6 of 8 sampled machines have full disk encryption on, 2 unknown."
Time: half a day.
Who else: five volunteers.

**Step 3: Fix full disk encryption on the machines that lack it.**
Goal: zero unencrypted company laptops.
Do: ask each affected person to turn it on themselves, with a link to the exact instructions for their operating system, and ask them to send you the confirmation screen. On macOS this is System Settings, then Privacy and Security, then FileVault. On Windows it is Settings, then Privacy and security, then Device encryption or BitLocker. Note that Windows Home edition does not have BitLocker, only the lighter "device encryption" on supported hardware, which is a real gap to record.
Verify: a screenshot per machine or an MDM report. Store the count in `SECURITY-STATE.md`.
Time: one to three days of chasing.
Who else: every affected person. This is your first real ask of the company, so make it small and easy.

**Step 4: Pick and buy an MDM.**
Goal: a tool that can report state and push settings.
Do: use the Decision points section below. Buy the smallest tier. Do not run a four-vendor bake-off.
Verify: you can log in and see zero devices, which is correct on day one.
Time: half a day to choose, one to three weeks for procurement and legal review at some companies. Start the paperwork early and keep working on other steps in parallel.
Who else: whoever approves spend.

**Step 5: Pilot enrolment with five people.**
Goal: find the workflow breakage before it hits everyone.
Do: enrol yourself first, then four volunteers who span operating systems and roles. Include one engineer with an unusual setup, because that person will find the problem. Send the pilot message from Ask the human. Push exactly one policy group in the pilot: encryption reporting, screen lock, firewall, and update deadlines. Nothing else.
Verify: all five devices check in, report encryption on, and nobody has filed a complaint you have not answered.
Time: one week.
Who else: five volunteers.

**Step 6: Roll out to everyone, with the leadership team first.**
Goal: full enrolment with no exemptions.
Do: announce in the company channel with the same honest description you used in the pilot. Enrol the CEO and the executive team in the first wave and say publicly that you did. Give a two-week window with a named deadline. Chase individually, never publicly shame.
Verify: enrolled device count equals your inventory count. Every exception is a named row in `RISK-REGISTER.md` with an owner and an expiry date.
Time: two to four weeks of calendar time, a few hours a week of yours.
Who else: the CEO or the person who runs people operations, to send or co-sign the announcement.

**Step 7: Enforce patching with a deadline.**
Goal: operating system and browser updates install on a schedule instead of being deferred forever.
Do: set a policy of automatic download and install, with a maximum deferral of 7 to 14 days for critical updates and a forced restart at the end of it. On macOS use MDM software update settings, on Windows use Intune update rings or Windows Update for Business policy, on Linux enable unattended upgrades and document per-machine ownership. Separately, enforce browser auto-update, which is often the more important one.
Verify: MDM report showing operating system version distribution, with fewer than a small number of machines more than one release behind.
Time: one day to configure, ongoing to enforce.
Who else: nobody, but warn the company that restarts will start happening.

**Step 8: Take control of the browser.**
Goal: know what extensions are installed and stop the worst ones.
Do: enrol browsers into management. Chrome Browser Cloud Management is free and works on macOS, Windows, and Linux, and reports installed extensions per machine, with allowlist and blocklist controls, from the Google Admin console under Devices, then Chrome, then Apps and extensions. Microsoft Edge has equivalent policy management through Intune or group policy. Firefox uses an enterprise `policies.json` file. Start in reporting mode, look at the list, then move to a blocklist, then consider an allowlist.
Verify: you can produce a list of every extension installed anywhere in the fleet, sorted by how many users have it.
Time: one day to enrol, one day to read the results, and a real conversation about anything you want to remove.
Who else: whoever owns the Google or Microsoft admin console.

**Step 9: Decide on malware protection and turn it on.**
Goal: something is watching for malicious code execution, and its alerts reach a human.
Do: see Decision points. At minimum verify the built-in protections are on and tamper-protected. If you buy an EDR, deploy through the MDM you already have, and route alerts into the security channel you built in DR-4.
Verify: trigger a benign test detection using the EICAR test file, which is a harmless standard string every antivirus recognises, and confirm an alert reaches the channel. Do this once, deliberately, and tell people you are doing it.
Time: two to five days.
Who else: whoever gets paged.

**Step 10: Write the lost device runbook and the BYOD policy.**
Goal: the 2am path is written down before 2am.
Do: use the runbook template below. Write the BYOD and contractor rules as one page.
Verify: read the runbook to one other person and have them tell you where they would get stuck.
Time: half a day.
Who else: one reviewer.

## Decision points

**MDM choice.**
DEFAULT: pick the one that matches the fleet you already have, and buy it this week.
- Mostly or entirely macOS: choose a Mac-native MDM. Kandji and Mosyle are the two common startup answers, Jamf is the incumbent with the deepest feature set and the heaviest setup. Mosyle is the cheapest credible option, Kandji is the most pleasant to operate, Jamf is what you will be asked about by an auditor and by a future IT hire.
- Mostly Windows, or already paying for Microsoft 365 Business Premium or E3: use Microsoft Intune. You already own it. Do not buy a second tool.
- Genuinely mixed and you already use Google Workspace: Google Workspace endpoint management covers the basics for free and is a fine starting point for a 20 person company. It is weaker than a real MDM. Treat it as a stepping stone and say so.
- Budget is truly zero and you have engineering time: Fleet is open source, osquery based, cross platform, and gives excellent visibility. Note carefully that visibility is not the same as control: read-only inventory does not enforce settings.
CHANGES IF: you already have an identity provider that bundles device management (JumpCloud, Rippling) and the bundle is adequate. Then use the bundle and skip the extra vendor.

**Corporate owned versus BYOD.**
DEFAULT: company-owned laptops for everyone who touches production, customer data, or the code host. This is not negotiable and it is cheaper than the alternative. A laptop is roughly one to two weeks of an engineer's fully loaded cost.
CHANGES IF: the company is pre-seed and cannot buy hardware, or you are in a market where personal devices are the norm. Then you split the fleet: personal devices get access only to email, chat, and documents through the browser, with no local data and no production credentials, and you enforce that with conditional access rules in the identity provider rather than with an agent on a machine you do not own.

**Local administrator rights.**
DEFAULT at a 20 to 100 person startup: engineers keep local admin, everyone else does not, and you compensate for the engineers with EDR and browser control. Removing admin from engineers on day one costs you more political capital than it buys in risk reduction, and they will work around you.
CHANGES IF: you handle regulated data, you are pursuing a framework that expects least privilege on endpoints, or you have had an incident caused by a bad install. Then move to a temporary elevation model (a request that grants admin for a fixed window) rather than a flat removal.
Either way, write the decision and the reason into `DECISION-LOG.md` with a date and the approver.

**Built-in antivirus versus a real EDR product.**
DEFAULT: on Windows, Microsoft Defender Antivirus is genuinely good and is already there. Turn on tamper protection, cloud-delivered protection, and attack surface reduction rules. On macOS, XProtect and Gatekeeper are on by default and catch known families but give you no telemetry and no alerts. So the real question is not "do we have antivirus", it is "would we know". The upgrade to EDR is justified the moment any of these is true: you have more than about 25 employees, you have paying customers asking about endpoint controls, you handle customer data on laptops, you are pursuing SOC 2, or you have had one malware incident. At a Mac-heavy startup that is usually within the first year.
CHANGES IF: money is genuinely unavailable this quarter. Then the interim answer is: built-ins verified and tamper-protected, browser management on, extension control on, and phishing-resistant multi-factor on the identity provider. That combination stops more real attacks than an EDR agent nobody reads the alerts from.

**Who watches the alerts.**
DEFAULT: route EDR alerts into the dedicated security channel from DR-4 and accept that you are the only responder during business hours. Be honest in `RISK-REGISTER.md` that nights and weekends are uncovered.
CHANGES IF: you can afford a managed option. Several EDR vendors sell a managed tier where their analysts triage for you, which for a solo security hire is often worth more than the product itself.

**Which laptops, if any, need backing up.**
At a small company the laptop is routinely the only copy of something that matters: the analyst's spreadsheet that the board deck is built from, the designer's working files, an engineer's uncommitted branch, a local database dump taken for debugging, the finance lead's reconciliation workbook. Every control in this cell makes that worse rather than better, because remote wipe, forced reinstall, and hardware failure all destroy local data, and the lost device runbook below tells you to wipe.
DEFAULT: do not deploy a backup agent across the fleet. Instead, ask one question of every team during the inventory in Step 1: "is there anything on your machine that exists nowhere else?" Then fix the answers at the source. Most of them are fixed for free by moving the work into the file sync the company already pays for (Google Drive, OneDrive, Dropbox) or by pushing the branch. What is left after that, typically a handful of machines, is a real backup requirement.
CHANGES IF: the answers include customer data, financial records, or anything with a retention obligation, or the count of genuinely-only-on-the-laptop machines is more than a few. Then this stops being a CS-2 question and becomes an M-6 question. [m-6-backups-and-recovery.md](m-6-backups-and-recovery.md) owns backup scope, restore testing, immutability, and the recovery time and recovery point numbers you will be asked for in a questionnaire. Do not invent a laptop backup scheme here that contradicts the one M-6 sets. Record which machines are in scope in `devices.csv` as an extra column, and record the decision and its reason in `DECISION-LOG.md`.
Note the ordering trap: verify that a machine's data is recoverable **before** you wipe it, not after. The lost device runbook below is written to lock first and wipe only on a decision, partly for this reason.

## Multi-country employment constraints

Everything above assumes you may enrol a laptop because the company bought it. In several countries that is not true, or is true only after steps you have not taken. A distributed team is not only a shipping problem, it is a legal one, and the constraint lands squarely on this cell because device management is the control that generates employee personal data.

Read this before you enrol a single device belonging to someone employed outside your own jurisdiction. Nothing here is legal advice, and you are not the person who decides any of it. The point of this section is to make sure you ask before you act, rather than discovering the requirement from an angry email after enrolment.

**1. Consultation, and who owns it.** In several European jurisdictions, notably Germany, the Netherlands, France, and Austria, a works council or equivalent employee representative body must be consulted, and in some cases must agree, before an employer deploys technology capable of monitoring employees. Endpoint management and endpoint detection and response both qualify, because both can report what a person is doing on their machine. This consultation is not yours to run. It belongs to people operations, the local employing entity, or outside employment counsel. Your job is to say, early and in writing, "we intend to deploy X, it reports Y, please tell me what consultation this needs and how long it takes", and then to build that duration into the rollout plan rather than being surprised by it. Consultation can take weeks. Start it while you are still choosing the tool.

**2. The transparency notice that has to accompany enrolment.** Wherever a general data protection regime applies, and the European Union's General Data Protection Regulation (GDPR) is the one you will meet first, telemetry from a managed device is personal data about the employee. That triggers an obligation to tell the employee, in advance and in specific terms, what is collected, why, on what lawful basis, how long it is retained, who can see it, and where it goes. The honest, plain-language description you already wrote for the pilot message in Ask the human is most of this. Turn it into a short written notice, get people operations and counsel to check it, and give it to every person at enrolment rather than after. Practically, this is also your best defence against the revolt failure mode below: a written list of what the tool can and cannot see, issued before enrolment, is both a compliance artifact and a trust artifact.

**3. Data minimisation, which is a configuration choice you make.** The rule that survives contact with every regime is: collect device posture, not human activity. Concretely, that means yes to operating system version, patch level, disk encryption state, firewall state, screen lock configuration, installed application and extension inventory, and serial number. It means no to browsing history, keystrokes, screenshots, application usage timing, location tracking beyond what a lost-device feature genuinely requires, and file content. Many endpoint tools ship with some of the second list available and switchable. Turn those off deliberately, write down that you turned them off, and record the decision in `DECISION-LOG.md`. Capability you do not need is capability you have to justify later.

**4. Where the management console itself lives.** The tool is a cross-border data flow in its own right. European employee device telemetry landing in a United States console is a transfer that someone has to have a basis for. Ask each vendor two questions in the sales conversation, before you sign anything: in which region is our tenant's data stored, and can we choose a European region. Some vendors offer a European Union region and some do not, and this is much cheaper to establish before purchase than after. Record the answer in `DECISION-LOG.md` alongside the tool choice, and hand it to counsel rather than deciding yourself whether the transfer is acceptable.

**5. The rule.** Before enrolling any device belonging to a person employed in a European Union or European Economic Area jurisdiction, or in any country where you do not personally know the employment rules, route it through people operations and counsel first and get a written yes. Do not enrol and ask afterwards. If the answer takes weeks, enrol the jurisdictions that are already cleared, record the rest as `partial` in `SECURITY-STATE.md` with the blocking jurisdiction named, and put the gap in `RISK-REGISTER.md` with people operations as the owner. A jurisdiction you cannot enrol yet is an honest partial, not a failure.

**6. Employer of record and professional employer organisation populations.** Where an employer of record (EOR) is the legal employer of a person who works for you, the EOR, not your company, controls the employment relationship and often the device. That has consequences for this cell and much larger consequences for CS-3, because the EOR also controls the termination signal that offboarding depends on. See the EOR and PEO branch in [cs-3-onboarding-offboarding.md](cs-3-onboarding-offboarding.md).

## Danger zone

Every action below requires an explicit human yes before you run it. State the risk out loud, name what breaks, and wait.

- **STOP: Remote wipe.** Wiping a device destroys any local data that was never synced, including uncommitted code and local database dumps. On a personal device under BYOD, wiping the whole device may be unlawful in some jurisdictions and is always a relationship-ending event. Always prefer remote lock first, then wipe only when the device is confirmed unrecoverable and the human owner and their manager have both agreed. If the MDM supports a selective or corporate-data-only wipe, use that on personal devices.
- **STOP: Enforcing full disk encryption remotely on a machine already in use.** On macOS, enabling FileVault through MDM on a machine with existing data prompts the user and requires a restart, and if the recovery key escrow is misconfigured you can lose access to the data. Confirm escrow works on your own machine first. On Windows, enabling BitLocker without confirming the recovery key is saved to the directory can lock a user out of their own machine permanently at the next firmware update.
- **STOP: Removing local administrator rights fleet-wide.** This breaks development environments, printer drivers, virtual private network clients, and package managers, all at once, and every one of those becomes your ticket. Pilot it with volunteers before it is ever policy.
- **STOP: Blocking browser extensions with an allowlist before you have looked at the list.** You will block the password manager, the screen recorder sales uses, and the accessibility tool one person depends on. Run reporting mode for at least two weeks first.
- **STOP: Forced restarts for updates with no warning.** A forced restart during a customer demo or a production deploy will cost you the trust you need for the rest of the program. Always configure a user-visible countdown and never let a deadline expire during a known company event.
- **STOP: Enrolling a device you do not own.** Enrolling a contractor's or an employee's personal machine into MDM gives you the technical ability to wipe their family photos. Get written consent, or do not enrol it.
- **STOP: Enrolling any device belonging to a person employed outside your own jurisdiction, before people operations and counsel have said yes in writing.** Failure mode: you deploy monitoring-capable software to a population where consultation with a works council was required first, which is an employment law problem for the company and a credibility problem for you that no amount of good intent repairs. See Multi-country employment constraints above. This applies to endpoint detection and response as well as to device management, and it applies even when the company bought the laptop.
- **Cost warning:** per-device pricing multiplies quietly. A tool at 15 dollars per device per month across 60 devices is 10,800 dollars per year, and device counts grow faster than headcount because of spares and old machines. Cancel licences on offboarding, which is CS-3.

## Do not do this yet

- Do not buy data loss prevention. It generates enormous false positive volume, it needs a tuning owner you do not have, and at your size the data leaves through SaaS grants and shared links, not through USB sticks.
- Do not build a custom golden image or a hardened operating system build. Use vendor defaults plus a small policy set. Custom images rot and become a full-time job.
- Do not deploy application allowlisting (Santa on macOS, Windows Defender Application Control) in blocking mode in your first quarter. In monitor mode it is a great source of intelligence. In blocking mode it is a support queue.
- Do not attempt to fully manage personal phones. Enforce screen lock, encryption, and the ability to remove company data through application-level controls in the identity provider or the mail platform, and stop there.
- Do not write a fifteen page endpoint security policy document. Write one page that describes the controls that are actually turned on. A policy that describes controls you have not implemented is worse than no policy, because it is a documented gap.
- Do not chase every extension and every unsigned binary you find. Rank them, fix the top three, log the rest.
- Do not deploy an agent to production servers because it is called "endpoint" security. Servers are a different problem with different tooling and a different owner. Keep this cell about human-operated machines.

## Evidence to capture

Write into `SECURITY-STATE.md`, section CS-2, one line per control with a status of `unknown`, `none`, `partial`, or `done`, plus the evidence:

- Device inventory: the path to `devices.csv`, the source systems reconciled, the date generated, and the count of unaccounted machines.
- MDM: vendor name, enrolled device count, total device count, and the export date of the enrolment report.
- Encryption: percentage encrypted, whether recovery keys are escrowed, and where they are escrowed.
- Patching: the deferral deadline you set, and the current operating system version distribution.
- Browser: whether browser management is enrolled, the count of distinct extensions in the fleet, and whether you are in reporting, blocklist, or allowlist mode.
- Malware protection: built-in status per platform, EDR vendor and coverage percentage if any, and where alerts land.

Write into `DECISION-LOG.md`: the MDM choice with the alternatives you rejected and why, the local administrator decision, the BYOD boundary, and the EDR buy-or-defer decision, each with a date and the person who approved it.

Write into `RISK-REGISTER.md`: every unenrolled device with a named owner, every machine that cannot be encrypted (older Windows Home machines, some Linux setups), the after-hours alerting gap, and every contractor machine you do not control. Each row needs a severity, an owner, a decision, and an accepted-by name.

Write into `ACCESS-LOG.md`: the date you requested MDM and identity provider console access, from whom, and whether it was granted, denied, or is still pending.

Artifacts a future auditor or enterprise customer will ask for, so save them as you go: a dated device inventory export, a dated encryption compliance report from the MDM, a screenshot of the update deferral policy, the one-page endpoint policy, the lost device runbook, and evidence that the runbook has been exercised at least once.

## Cost and effort

- Inventory, baseline measurement, and manual encryption fixes: 3 to 5 days of your time. Zero dollars.
- MDM selection and pilot: 1 to 2 days of your time plus one week of calendar time. Software cost roughly 2 to 15 dollars per device per month depending on vendor and tier. For 50 devices that is roughly 1,200 to 9,000 dollars per year. Free options first: Google Workspace endpoint management (included if you pay for Workspace), Microsoft Intune (included in Microsoft 365 Business Premium and in E3 and E5), Fleet open source (self-hosted, costs engineering time instead of money). Check current Jamf entry-level options before recommending one, because the packaging and the free allowance have changed more than once; Mosyle and Kandji both have credible small-fleet tiers and are the safer default suggestion for a Mac fleet under fifty machines.
- Full rollout: 2 to 4 weeks of calendar time, roughly 1 day per week of your time.
- Browser management: 1 to 2 days. Chrome Browser Cloud Management is free. Edge management is included with Microsoft 365 licensing you likely already have.
- EDR: 1 week to deploy and tune. Roughly 3 to 10 dollars per endpoint per month depending on vendor and tier, so roughly 2,000 to 6,000 dollars per year for 50 machines. Managed tiers, where a vendor analyst triages alerts for you, run higher but replace headcount you do not have. Free and built-in first: Microsoft Defender Antivirus is included with Windows at no extra cost, and Defender for Business is bundled with Microsoft 365 Business Premium.
- Total realistic first-year spend for a 50 person startup doing this properly: roughly 5,000 to 15,000 dollars. That is small enough that you should ask for it in one conversation rather than building a business case deck.

## 2026 notes

The 2019 slide treated endpoint as a solved commodity you should just go buy, and it marked it with a gift emoji for exactly that reason. That framing is still correct about the purchase and badly wrong about the priority. Three things changed:

**Infostealer malware became the dominant path in.** The modern attack is not a targeted exploit, it is commodity malware such as the Lumma, RedLine, Vidar, and Atomic macOS Stealer families, distributed through search engine advertisements for popular software, fake browser update pages, cracked applications, malicious npm and Python packages that run install scripts, and the ClickFix pattern where a fake verification page instructs the user to paste a command into Terminal or the Windows Run box. The malware runs once, harvests saved passwords, browser cookies, session tokens, cloud command line credentials in files such as `~/.aws/credentials`, secure shell keys, and cryptocurrency wallets, then exits. There is often no persistence to find. The stolen data is sold, and the actual intrusion happens weeks later from a different actor and a different country. macOS is fully in scope now, which was not true in 2019.

**What actually defends against that:** stolen session cookies bypass multi-factor authentication entirely, so the primary control is not on the endpoint at all, it is phishing-resistant authentication plus short session lifetimes plus device-bound sessions in the identity provider (CS-1). On the endpoint, the controls that matter are browser and extension management, blocking the install-script execution path, EDR that detects credential file access, and telling people plainly that no legitimate website will ever ask them to paste a command into a terminal. Add that single sentence to onboarding.

**The browser became the real operating system.** Nearly all company data now flows through a browser tab, which means a single malicious or hijacked extension with broad host permissions can read every page and exfiltrate every session cookie. Extensions change ownership and get sold, and a benign extension can turn malicious in an update with no user action. So the practical controls are: enrol browsers in management, keep an inventory of every installed extension, review anything requesting access to all sites, and use separate browser profiles so that the profile holding production and admin sessions is not the one used for general browsing.

**Cloud and code credentials sit on the laptop in plain files.** In 2019 the laptop held documents. In 2026 it holds long-lived cloud keys, package registry tokens, and code host personal access tokens, which is why the malicious package and the stolen laptop are now the same incident class. This is the direct link to SE-3 (secrets) and to the supply chain material in the modern cells file: your "malicious package" response and your "stolen laptop" response both begin with rotating every credential that machine could reach.

## Failure modes

**The founders exempt themselves.** Early tell: the enrolment report is at 90 percent and the missing names are all executives. Why it is fatal: executives are the highest-value phishing targets and their accounts have the broadest access, so an exempt fleet is precisely inverted risk. Recovery: get the CEO enrolled first and announce it, then re-run the campaign. If leadership refuses, log it in `RISK-REGISTER.md` as an accepted risk with their name in the accepted-by field and move on. Do not fight it twice.

**The inventory is a spreadsheet that goes stale in three weeks.** Early tell: someone leaves and nobody knows which serial number to collect. Recovery: make the MDM the source of truth, delete the hand-maintained spreadsheet, and tie device assignment into the onboarding and offboarding checklist in CS-3.

**You deploy an EDR and nobody reads the alerts.** Early tell: an unread alert count above about fifty, or you cannot say when the last alert was triaged. Why it matters: you are paying for the control and getting the false comfort without the detection. Recovery: tune aggressively so that only high and critical alerts page anyone, route them into the DR-4 channel, and if you still cannot keep up, buy the managed tier or turn off the noisy detections deliberately and write down that you did.

**The rollout triggers a revolt.** Early tell: a thread in the company chat about surveillance, or an engineer saying they will quit before installing an agent. Why it happens: you announced control before you explained purpose, or the tool actually does something invasive and you did not check. Recovery: stop the rollout, publish an explicit list of what the tool can and cannot see, remove any capability you cannot justify (for example, do not enable web content filtering or activity logging you do not need), and restart with a volunteer pilot. You get one recovery from this, so avoid it in the first place.

**The Linux fleet is quietly unmanaged.** Early tell: the MDM report count is exactly the number of Mac and Windows machines and the engineers running Linux are not in it. Be honest about this: Linux endpoint management is genuinely harder, coverage across MDM vendors is thin and inconsistent, and the encryption, patching, and firewall stories differ by distribution. Recovery: define a small written baseline for Linux (LUKS full disk encryption at install time, unattended security upgrades, a host firewall, screen lock, no shared accounts), have each Linux user attest to it with pasted command output quarterly, and record the fleet as `partial` rather than pretending it is covered. If you have more than a handful of Linux machines, evaluate Fleet with osquery, which handles Linux better than most commercial MDM products, and accept that you get visibility without enforcement.

**Remote wipe does not work when you need it.** Early tell: nobody has ever tested it. Why it fails in practice: wipe commands only execute when the device comes online and checks in, a powered-off or offline laptop is untouchable, and a wiped machine that was never encrypted may still have had its drive imaged before the wipe landed. Recovery: test lock and wipe once on a spare or newly wiped machine, document the actual observed behaviour and timing, and stop treating remote wipe as the primary control. Encryption is the control. Wipe is cleanup.

**Contractors are invisible.** Early tell: a name in the code host that does not appear in the HR roster or the device inventory. Recovery: enumerate contractors from accounts payable, decide per contractor whether they get a company machine or a browser-only access boundary, and write the decision into `RISK-REGISTER.md`.

## Lost or stolen device runbook

Keep this short enough to run while upset. Store it wherever the incident plan from DR-1 lives, and link it from there.

1. **Report.** The person tells you in the security channel or by phone. No blame, ever. The number one predictor of a bad outcome is a delayed report, and the number one cause of a delayed report is fear.
2. **Record.** Open an entry in the incident log: time reported, time lost, device serial, assigned user, location, whether it was powered on, whether it was locked, and whether encryption was confirmed on that device.
3. **Suspend the human's sessions, not just the device.** Revoke all sessions and refresh tokens per the runbook in [cs-1-identity-and-access.md](cs-1-identity-and-access.md), then reset the password. This is the single highest-value action in this runbook and it takes under a minute. **This locks the person out of every device they still have, so tell them first**, which in this case is easy because they are already on the phone to you.
4. **Rotate credentials the device could reach.** Cloud command line keys, code host personal access tokens, secure shell keys, package registry tokens, and any secret in a local `.env` file. Treat this exactly like the malicious-package rotation list.
5. **Lock the device remotely** from the MDM. Set a lock message with a contact phone number. Do not wipe yet.
6. **Decide on wipe** with the user and their manager, and record who approved it. This needs an explicit yes from a named human, never your own judgement alone. Wipe when recovery is unlikely, when the device held sensitive local data, or when encryption status was not confirmed. Before you send the command, ask the user the one question they will not think to raise while upset: is there anything on that machine that exists nowhere else. If the answer is yes and the device is still reachable, the answer is not automatically "wipe anyway", it is a conversation about whether the data or the exposure matters more, and the person who decides is not you. See the backup decision point above and [m-6-backups-and-recovery.md](m-6-backups-and-recovery.md).
7. **Assess the data exposure.** If full disk encryption was confirmed on and the machine was powered off or locked, the practical exposure is low and you should say so plainly. If encryption was off, or the machine was awake and unlocked when taken, treat local data as compromised and escalate to the incident plan in DR-1, which is where any customer notification decision belongs.
8. **File a police report** if the company will claim insurance or if the jurisdiction requires it for a data incident, and keep the reference number.
9. **Replace the hardware** and remove the lost device from the inventory with a status of `lost` and the date, rather than deleting the row.
10. **Write it up within 48 hours:** what happened, what worked, what did not, and one change you are making. Put the change in `DECISION-LOG.md`. If the failure was "we could not confirm encryption", that is a CS-2 gap and it goes back on the plan.

## Related cells

- [CS-1: Identity and access management](cs-1-identity-and-access.md), which owns session revocation, phishing-resistant multi-factor authentication, and device-based conditional access. CS-1 outranks this cell if you can only do one.
- [CS-3: Onboarding and offboarding](cs-3-onboarding-offboarding.md), which is where device assignment, collection, and licence reclamation actually get enforced.
- [CS-4: Workplace security](cs-4-workplace-security.md), for physical office and travel considerations.
- [SE-3: Secrets and keys](se-3-secrets-and-keys.md), because the credentials an infostealer takes are the ones sitting in files on the laptop.
- [DR-1: Incident response plan](dr-1-incident-response-plan.md), which the lost device runbook escalates into.
- [M-6: Backups and recovery](m-6-backups-and-recovery.md), because at a small company a laptop is frequently the only copy of something, and every control in this cell (remote wipe, reinstall, hardware replacement) destroys local data. M-6 owns backup scope and restore testing; this cell only identifies which machines are in scope.
- [DR-2: Top security signals](dr-2-top-security-signals.md), for routing endpoint alerts into something that gets read.
- [DR-4: Company communication channel](dr-4-company-comms-channel.md), the channel enrolment announcements and endpoint alerts should use.
- [CO-2: Questionnaire knowledge base](co-2-questionnaire-knowledge-base.md), because the encryption and device management answers you produce here are asked in almost every questionnaire.
- [references/07-modern-cells.md](07-modern-cells.md), for the supply chain and browser-layer material this cell depends on.
- [references/06-2019-to-2026-delta.md](06-2019-to-2026-delta.md), for why corporate security moved from the fourth quadrant to the first.
