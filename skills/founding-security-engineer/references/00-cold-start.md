# Cold start: the first session in a brand new environment

> **Load when:** the skill has just been invoked and `SECURITY-STATE.md` does not exist at `./.security/` or at `~/security-program/<org-slug>/`, or the human says anything like "I just started", "day one", "I am the first security hire", "where do I even begin", or the environment is unrecognised. This file is the entry point. Run it top to bottom.
>
> **The cold start test is the file, not the directory.** A `./.security/` directory can exist while the program has never actually been started, because someone created the folder and stopped. The single test used everywhere in this skill, including `references/04-interrupts.md`, is whether `SECURITY-STATE.md` exists at one of those two paths. If it does not, this is a cold start regardless of what else is on disk.

This protocol covers the first 60 to 90 minutes. It is deterministic on purpose. Do not improvise the order. The order exists because every step after step 1 depends on facts gathered in step 1, and because the human sitting next to you is judging whether this partnership is worth their time within the first ten minutes.

The single most important outcome of session one is not a plan. It is that the human ends the session with one real finding, one written page, and one specific next action. Evan Johnson's framing of the original playbook applies here: every item is short in scope, and you can get most of the way to addressing all of them in a quarter. Session one is the first hour of that quarter, not a strategy offsite.

**Time budget.** Phase 0 through Phase 3 should take about 25 minutes. Phase 4 through Phase 6 should take about 45 minutes. Phase 7 takes 10 minutes. If you are running long, cut Phase 4 depth, never Phase 6 or Phase 7. The section between Phase 3 and Phase 4, "You are not the first, or the company is not small", is a branch rather than a phase. It costs nothing when it does not apply and it reorders the rest of the session when it does.

---

## Phase 0: Orient without touching anything

**Why this comes first, in plain terms.** You do not know whether this directory is the company's main product, an empty folder on a new laptop, or a Terraform repo that controls production. Running the wrong command in the wrong place on day one is how a security hire loses credibility permanently. So the first pass is read-only, local, and touches nothing over the network.

**Rules for this phase.**

- Every command below is read-only. Do not run anything that writes, installs, authenticates, or reaches the company's own infrastructure yet.
- Do not run any command against a host or domain until you have confirmed the company owns it. That confirmation happens in Phase 4.
- If a command is not installed, that is a finding, not an error. Record it and move on.
- Do not read the contents of files that look like they contain live secrets. Note the file path and the fact that it exists. Reading a `.env` file into your context window puts a production credential into a transcript. Report the path, not the value.

### 0.1 Classify the working directory

Run these together and read the results as one picture.

```bash
pwd
ls -la
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_A_GIT_REPO"
git remote -v 2>/dev/null
git log -1 --format='%cd %an' 2>/dev/null
git rev-list --count HEAD 2>/dev/null
```

Interpret with this decision table. Pick the first row that matches.

| Signal | Classification | What it means for you |
| --- | --- | --- |
| `ls -la` returns only `.` and `..`, or only dotfiles you created | **Empty directory** | The human has a laptop and nothing else. Go to 0.4. This is normal and common. |
| Only `.md`, `.pdf`, `.docx`, `.png` files, no source code, no lockfile | **Docs directory** | Likely a policy or notes folder. Treat existing docs as claims to verify, not as truth. |
| `*.tf`, `*.tfvars`, `Pulumi.yaml`, `cdk.json`, `serverless.yml`, `main.bicep`, `Chart.yaml`, `kustomization.yaml`, `ansible.cfg` present | **Infrastructure repo** | Highest value and highest risk directory in the company. Every file here is production. Do not run any `apply`, `destroy`, `plan -out`, or `kubectl` write command. |
| `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `go.work`, root `Cargo.toml` with `[workspace]`, or `package.json` containing a `workspaces` key | **Monorepo** | Multiple services in one tree. Your inventory work is easier than usual. Enumerate packages before anything else. |
| A single lockfile plus source, one app | **Single service repo** | Normal case. Ask in Phase 2 how many other repos exist. |
| Repo exists but `git rev-list --count HEAD` is under 50 and last commit is old | **Stale or scratch repo** | Do not build the program around this directory. Ask where the real code lives. |

Follow-up commands for the monorepo and infrastructure cases:

```bash
# Monorepo: list the workspace members
cat pnpm-workspace.yaml 2>/dev/null
ls -1 packages apps services 2>/dev/null
find . -maxdepth 3 -name package.json -not -path '*/node_modules/*' 2>/dev/null | head -50

# Infrastructure repo: what providers and what backends
grep -rl 'provider "' --include='*.tf' . 2>/dev/null | head -20
grep -rhoE 'provider "[a-z]+"' --include='*.tf' . 2>/dev/null | sort -u
grep -rhoE 'backend "[a-z0-9]+"' --include='*.tf' . 2>/dev/null | sort -u
```

The provider names tell you the cloud without asking. `aws` means Amazon Web Services, `google` means Google Cloud Platform, `azurerm` means Microsoft Azure. If you see more than one, the company is multi-cloud and your Phase 2 questions change.

### 0.2 Inventory available tooling

**Why.** You need to know what you can do without asking anyone for anything. Every tool that is installed and authenticated is free discovery. Every tool that is missing is either something to install later or a signal that the company does not use that platform.

```bash
for c in git gh glab aws gcloud az kubectl helm terraform tofu pulumi docker podman jq yq \
         npm pnpm yarn bun pip pip3 python3 go cargo mvn gradle \
         trivy grype syft gitleaks trufflehog semgrep osv-scanner op vault sops age; do
  command -v "$c" >/dev/null 2>&1 && printf '%-12s %s\n' "$c" "$(command -v "$c")"
done
```

Read the output like this:

- **`gh` or `glab` present** means the code host is probably GitHub or GitLab respectively. Do not conclude it from absence.
- **`aws`, `gcloud`, `az` present** tells you which clouds someone on this laptop has worked with. Presence is not proof of use, and absence is not proof of non-use.
- **`op`, `vault`, `sops`, `age` present** are strong hints about how secrets are managed. This directly informs cell SE-3.
- **No scanner at all** (`trivy`, `grype`, `semgrep`, `gitleaks` all missing) is the normal startup case. Do not treat it as a scandal.

### 0.3 Check which tools are authenticated, and as whom

**Why.** An authenticated cloud command line on a new hire's laptop on day one is itself a finding. If your brand new security laptop already has long-lived admin keys sitting in a plaintext file in your home directory, that is your first quick win and you found it in five minutes.

Each command below is read-only and only tells you who you are. Run only those whose binary exists.

```bash
# Code host
gh auth status 2>&1 | head -20
glab auth status 2>&1 | head -20

# Amazon Web Services: who am I, and where do my credentials come from
aws sts get-caller-identity 2>&1
ls -la ~/.aws 2>/dev/null
grep -c 'aws_access_key_id' ~/.aws/credentials 2>/dev/null

# Google Cloud Platform
gcloud auth list 2>&1
gcloud config list 2>&1

# Microsoft Azure
az account show --output table 2>&1

# Kubernetes: context only, no cluster call yet
kubectl config current-context 2>&1
kubectl config get-contexts 2>&1

# Containers
docker info --format '{{.ServerVersion}} {{.OperatingSystem}}' 2>&1
```

Interpretation rules, applied in order:

1. **`aws sts get-caller-identity` returns an Amazon Resource Name (ARN, the unique identifier Amazon Web Services gives every principal and resource) containing `:user/`** means a long-lived Identity and Access Management (IAM) user with static keys is in use. An IAM user is a permanent identity with a password or an access key that never expires on its own. This goes straight into `RISK-REGISTER.md` as a candidate finding. If it returns `:assumed-role/` the company is using federated or role-based access, which is the good outcome.
2. **`grep -c 'aws_access_key_id' ~/.aws/credentials` returns 1 or more** means static access keys are stored in plaintext on this laptop. Note the count, never the value.
3. **`gcloud auth list` shows an account ending in `.iam.gserviceaccount.com`** means a service account key file is active on a human's laptop. Same severity class as the point above.
4. **`kubectl config get-contexts` lists a context with `prod` in the name** means this laptop can likely reach production Kubernetes. Do not run any `kubectl get` yet. Note it and raise it in Phase 2.
5. **Any command returns "not logged in" or an expired token error** is fine and expected. Record `unknown` for that platform in `SECURITY-STATE.md`.

### 0.4 The empty directory case

This is the most common real starting point for a first security hire, and it is not a problem. You have a laptop, an email address, and no access to anything yet.

When the directory is empty:

1. Do not ask the human to `git clone` anything yet. You do not know what they are allowed to clone.
2. Skip the repo-specific parts of Phase 4 entirely.
3. Move directly to Phase 1, then Phase 2, then create the state directory under `~/security-program/<org-slug>/` rather than in the working directory (see Phase 3).
4. Weight session one toward Phase 5 (the access ask) and Phase 6 quick wins that need no code access at all. Identity provider settings, third-party application install policy, and public-facing information cost nothing and are among the highest-value cells in 2026.
5. Say this out loud to the human so they do not think something is wrong: an empty directory means the program starts with identity and access, which is where a modern startup program should start anyway.

---

## Phase 1: Establish the partnership

**Why.** The human does not yet know how you behave. If you start firing commands and dumping a 90 day plan, they will either disengage or, worse, follow instructions they do not understand. Set the contract in under 150 words, then ask exactly one question.

Send this message verbatim, substituting only the bracketed detection result from Phase 0. Do not add a menu of options. Do not add a summary of the 4x4 grid. One question, then stop and wait.

### Verbatim opening script

```
I am going to work with you as your security partner, not as a tool you have to
drive. That means I will have opinions, I will tell you when I think you are about
to do something that will not work, and I will always propose a specific next step
rather than asking what you want to do.

Three ground rules so you know what to expect:

1. One step at a time. I will not hand you a 90 day plan today. I will name the
   next single action, and you say go or no go.
2. I will never change anything that could lock someone out, break a deploy, cost
   money, or reach a customer without stopping and asking you first, in writing.
3. If I cannot find something out on my own, I will ask you one specific question,
   or hand you copy-pasteable text to send to a colleague. I will not guess and I
   will not stall.

I have looked at this directory only, read only, nothing over the network. It looks
like [DETECTED: empty directory / a single service repo / a monorepo with N packages
/ an infrastructure repo using <providers> / a docs directory].

First question, and it is the one that changes everything downstream: does your
company sell to other businesses or to consumers?
```

**Why that question first.** Evan Johnson's original talk is explicit that business-to-business versus business-to-consumer is the biggest single factor in what a first security hire should prioritise. Business-to-business means compliance and customer questionnaires arrive early and will eat your calendar if you do not build self-service. Business-to-consumer means account takeover, abuse, and privacy regulation dominate, and nobody will hand you a questionnaire until much later.

**If the human answers something other than the question**, take the answer, record it, and ask the question again in one sentence. Do not move on without it.

---

## Phase 2: Round one of intake

**Why.** You need about eight facts to make any decision at all. You do not need forty. An interrogation on day one makes the human feel audited by their own new hire.

The full question banks live in `references/02-intake-questions.md`. This phase uses only the round one subset.

**Hard rules for intake.**

- Ask at most **three questions per turn**. Never four.
- Every question offers an explicit "I do not know" path. When the human takes it, do not repeat the question. Convert it into a discovery task, write it to `SECURITY-STATE.md` under `## Open questions`, and tell the human it is now a task rather than a gap in their knowledge.
- Prefer closed questions with named options. "Is your identity provider Google Workspace, Microsoft 365, Okta, something else, or you are not sure?" beats "how do you handle identity?"
- After each round, state one thing you learned and why it matters, in one sentence. This is how the human learns the shape of a security program while you work.

### What you are actually collecting, and why the order is what it is

Round one is not a generic questionnaire. It collects six specific dimensions, in a specific order, because those six are what make a priority order defensible when someone asks you why you are doing this instead of that. Evan Johnson's slide on this is titled "It all depends", and the six things it lists are, in his order: business-to-business or business-to-consumer, company size, customer base, product, engineering velocity, and company culture. His own note on the first one is that it is, in his opinion, the biggest thing that will inform your priorities.

| Dimension | Where you get it | What it changes |
| --- | --- | --- |
| Business-to-business or business-to-consumer | Phase 1, asked before anything else | Business-to-business pulls customer questionnaires, contractual commitments, and framework choice forward. Business-to-consumer pulls account takeover, abuse, and privacy regulation forward, and pushes most of the Compliance column back. |
| Company size | Round one, turn 1, question 1 | Ten people means you can talk to everyone individually and skip process entirely. Two hundred means process is the only thing that scales and onboarding and offboarding stop being manageable by hand. |
| Customer base | Round one, turn 2, questions 5 and 6, plus who the named customers are | One regulated enterprise customer with an audit clause outweighs a thousand self-serve signups in what it forces you to do first. |
| Product | Round one, turn 1, questions 2 and 3 | What the product does determines what an attacker gains by breaking it. A payments product, a data warehouse, and a scheduling tool have different worst days. |
| Engineering velocity | Round one, turn 1, question 1, plus the commit counts from Phase 4.1 | Twenty deploys a day means controls must live in the pipeline, because review gates will be bypassed. One deploy a month means a human review step is genuinely affordable. |
| Company culture | Observed, not asked | Whether people will accept a control depends on whether the company runs on trust and speed or on process. Read it from how the human answers, not from a question. |

Write all six into `SECURITY-STATE.md` before you write a single line of plan. When you later tell someone why a particular thing is next, the reason cites one of these plus a specific finding, never a framework and never a checklist position.

### Round one, turn 1 (after the business-to-business answer)

1. Roughly how many people work here, and roughly how many of them are engineers?
2. Where does the code live: GitHub, GitLab, Bitbucket, self-hosted, something else, or you are not sure?
3. Where does the product run: Amazon Web Services, Google Cloud Platform, Microsoft Azure, a platform like Vercel, Render, Fly, or Heroku, on-premise, or you are not sure?

### Round one, turn 2

4. What does everyone log in to work with: Google Workspace, Microsoft 365, Okta, something else, or you are not sure? (This is your identity provider, the system that owns everyone's accounts.)
5. Do you hold any customer personal data, payment data, or health data? A yes to any one of those changes the legal picture.
6. Has anything already been promised to a customer or investor about security or compliance? For example, a SOC 2 report (an audit report produced by an external accounting firm on a company's security controls), ISO 27001 (an international certification standard for an information security management system), or a penetration test by a certain date.

Question 6 matters more than it looks. Evan Johnson's specific warning is that businesses routinely commit to compliance standards before hiring anyone who could deliver them, and a first security hire frequently discovers a signed contract promising a SOC 2 Type 2 report in three months. Find that out on day one, not in month two.

### Round one, turn 3

7. Why now? What happened that made the company decide to hire for security?
8. Who do you report to, and who is the one person whose yes unblocks everything?
9. What is the one thing that would keep your chief executive awake at night if it appeared in the news tomorrow?

Question 7 is the highest-signal question in the whole bank. Security teams usually start a few months after something bad happened. If there was an incident, its cleanup is your first project and you will have political capital for it. If nobody can name a trigger, the mandate is softer and you will need to earn attention with visible wins.

**Hard branch on question 7.** If the answer mentions an incident, a breach, a scare, a near miss, a phishing wave, a lost or stolen laptop, an account someone "thinks" was accessed, a customer asking whether they were affected, or an investor or acquirer asking the same, then stop the normal sequence in this session. Do not wait for Phase 4.

Which file you open depends on one thing: whether the event has a name. If someone can point at a **specific past event** ("the phishing thing in March", "when Dev's laptop went missing"), open the "An incident that happened before you arrived" section of `references/dr-1-incident-response-plan.md` first, because a named event carries legal questions and there are things you must not write down before counsel has been asked. If the signal is **unnamed** (a rumour, a general worry, an investor asking, a customer asking whether they were affected, nobody able to say what actually happened), open `references/dr-0-compromise-assessment.md`, which is built for exactly that: going looking when no incident has ever been declared. The reason is arithmetic, not drama: default log retention across identity providers, chat platforms, code hosts, and clouds is commonly somewhere between 7 and 90 days, as `references/dr-3-logging-consumption-model.md` sets out. Every day spent drawing architecture diagrams is a day of evidence that ages out and never comes back. The first instruction in that file is to record the retention window of every source before doing anything else, because that window tells you how many days you actually have.

Two supporting branches that change what you load next:

- **Question 2, where the code lives, answered with an agency, an outsourcing partner, contractors, or "an external team built it".** Load `references/09-outsourced-engineering.md`. Almost every assumption in the software development lifecycle cells changes when the people writing the code are not employees and their laptops are not yours.
- **Phase 1's business model answer was business-to-consumer.** Load `references/se-5-consumer-account-security.md` when you reach the software development lifecycle work. Account takeover, credential stuffing, and abuse become the dominant risk, and most of the Compliance column drops in priority because no consumer is going to send you a security questionnaire.

**After turn 3, stop asking questions.** Write everything to state and move to Phase 3. Remaining question banks are used later, in the cell playbooks.

---

## Phase 3: Create the state directory

**Why.** Everything you learn is worthless if it evaporates when the session ends. The state directory is the security program's memory. It also becomes the artifact the human shows their manager in week two.

### 3.1 Choose the location

**This file owns the location rule.** `templates/README.md` points here rather than restating it. If you find a shorter version of this rule anywhere else in the skill, this one wins.

Apply these in order and stop at the first that matches.

1. **The human already has a preferred location.** Use theirs, even when it is neither of the two paths below. They know where their company keeps things and they are the person who has to find this folder again in six months. If their preference is inside a repository, 3.3 still applies to it in full, including the warning about the product monorepo.
2. **The working directory is inside a git repository, and the human confirms in this session that it is a repository they are allowed to commit to.** Use `./.security/`. Both halves are required. Being inside a repository is not the test, the confirmation is the test, because the repository sitting on a new hire's laptop is very often the product monorepo. Using `./.security/` inside it is still the right location, and 3.3 is then not optional: the folder gets ignored rather than committed, because an ordered list of the company's weaknesses does not belong in a tree the whole engineering organisation can read.
3. **Anything else.** An empty directory, a docs directory, a repository they do not own, a repository they own but may not commit to, or a clone of somebody else's code. Use `~/security-program/<org-slug>/`, where `<org-slug>` is the company name lowercased with spaces replaced by hyphens.
4. **You cannot tell which of the above applies.** Do not guess, and in particular do not pick `./.security/` because you happen to be standing in a repository. Ask one closed question: "Is this repository one you are allowed to commit to, yes or no?" If no answer arrives in this turn, use `~/security-program/<org-slug>/` and say out loud that you did and why. That direction is recoverable: a folder in the home directory can be moved into a repository later with the migration in 3.4. The other direction is not: a risk register accidentally committed to a repository the whole company can read cannot be un-read.

Record the chosen path, the rule that chose it, and who confirmed it in `DECISION-LOG.md` before you run the bootstrap block, and set `STATE_DIR` in that block to the path you recorded.

### 3.2 Create the files

Mutating command, but only inside the chosen state directory. Announce it, then run it.

This is the single bootstrap for the whole skill. It is defined in `templates/README.md` and repeated here so that cold start does not need a second file open. Run it as one block. Creating the subdirectories and the six files separately is what produces a half-started state directory, where the folder exists but `SECURITY-STATE.md` does not, so do not split it.

```bash
# MUTATES: creates directories and empty state files. Nothing outside this path is touched.
STATE_DIR="./.security"   # or ~/security-program/<org-slug>
mkdir -p "$STATE_DIR"/evidence "$STATE_DIR"/incidents "$STATE_DIR"/drafts
for f in SECURITY-STATE.md RISK-REGISTER.md CONTEXT-STACK.md DECISION-LOG.md ACCESS-LOG.md 90-DAY-PLAN.md; do
  [ -f "$STATE_DIR/$f" ] || touch "$STATE_DIR/$f"
done
ls -la "$STATE_DIR"
```

The three subdirectories have specific owners. `evidence/` holds command output and screenshots that back a `done` status. `incidents/` holds one file per incident, named `INC-<YYYY>-<NNN>-<slug>.md`, per `references/dr-1-incident-response-plan.md`. `drafts/` holds text that is not published yet, including customer-facing answers and any external statement, per `references/04-interrupts.md`. Treat `drafts/` as sensitive: a draft breach notification or a half-written questionnaire answer is more damaging in the wrong hands than a finished one.

The only cell-owned files created later, on demand rather than now, are `COMMITMENT-REGISTER.md`, `QUESTIONNAIRE-KB.md`, `QUESTIONNAIRE-LOG.md`, `sdlc-map.md`, `devices.csv`, and `session-01-summary.md`. Do not create them empty at bootstrap. A file that exists and is empty reads as a control that failed rather than as work not yet started.

Populate each of the six files from the templates in `templates/README.md`. At the end of Phase 3, `SECURITY-STATE.md` must already contain every row in the grid state tables of `templates/README.md`, which is SE-1 to SE-5, DR-0 to DR-4, CO-1 to CO-4, CS-1 to CS-4, and M-1 to M-6. Do not count from the 2019 slide: SE-5 and DR-0 were added later and are neither in the original sixteen nor in the modern-cell block, so counting will drop exactly the two that were added most recently. Each row carries a status of `unknown`, `none`, `partial`, `done`, or `n/a`. On day one almost everything is `unknown`, and that is the correct and honest answer. Do not write `none` for something you have not checked. `unknown` and `none` are different facts and the difference matters when you report upward. A status moves to `done` only with recorded evidence, and to `n/a` only with a written reason.

### 3.3 The version control question

Ask this explicitly. Do not decide silently.

> Do you want this security folder committed to version control, or ignored?

**Recommended default: commit it, to a private repository that only you and your manager can read.** Give the reasoning in these terms:

- The risk of committing is that the folder contains an ordered list of your weaknesses. If the repository is public, or readable by the whole engineering organisation, that list is a roadmap for anyone who wants to hurt the company.
- The risk of not committing is worse in practice. Ungoverned security programs die on laptops. If the only copy of the risk register is in a local folder, it is gone the day the laptop dies, and there is no history showing that a risk was raised on a date and accepted by a named person. That history is the thing that protects you personally when something goes wrong later.
- The compromise that works: a private repository, separate from the product repository, with access limited to the security owner and one executive. Never the product monorepo, because engineering-wide read access defeats the point.

**If the human chooses not to commit**, add the state directory to the repository's ignore file so it cannot be committed by accident:

```bash
# MUTATES: appends one line to the repo ignore file
grep -qxF '.security/' .gitignore 2>/dev/null || echo '.security/' >> .gitignore
# Verify it landed. Fire and forget is how the risk register ends up one `git add -A` from being committed.
grep -qxF '.security/' .gitignore && echo "OK: .security/ is ignored" || echo "FAILED: add .security/ to .gitignore by hand before writing anything else"
```

**If the human chooses to commit**, the same private repository still must not carry everything. Ignore `evidence/` and `drafts/` inside it, because evidence files hold raw command output that may include identifiers, and drafts hold unpublished customer-facing text that must never leak before it is approved and sent.

```bash
# MUTATES: appends two lines to an ignore file inside the state directory
printf 'evidence/\ndrafts/\n' >> "$STATE_DIR/.gitignore"
```

**Never write real secret values, customer data, or full credentials into any state file.** Record the location and the fact, for example "a static access key exists in `~/.aws/credentials` on the security laptop", not the key itself.

Record the decision, the reasoning, and who approved it in `DECISION-LOG.md`.

### 3.4 When the storage-location decision changes

A decision to move the state directory that leaves the files where they were is worse than never making the decision, because `DECISION-LOG.md` now says the artifacts are somewhere they are not, and the next session reads the log rather than the disk. The common shape of this failure is a decision in week one to move the folder into a separate private repository, followed by nothing at all, because the decision closed and no step moved anything.

So the decision does not close when it is agreed. It closes when the files are at the new path and that has been verified. Run the whole of this in the same turn the decision is made.

1. Say it before you run it, the same as the bootstrap in 3.2: name the old path, the new path, and the six state files plus the three subdirectories that are about to move, and get a yes.
2. Run the move block. It moves, it does not copy, because two copies of a risk register is the same defect as none of them being current.
3. Confirm the old path is gone or empty.
4. Confirm the new path holds all six state files and all three of `evidence/`, `incidents/` and `drafts/`.
5. Re-verify the ignore rule at the **new** location. This is the step that gets skipped, and skipping it is how the folder gets committed: an ignore rule that covered `.security/` in the old repository protects nothing in the new one.
6. Only then append the closing entry to `DECISION-LOG.md`, naming both paths, the date, and the verification output from steps 3 and 4 as the evidence.

```bash
# MUTATES: moves the entire state directory to a new path. Nothing outside these two paths is touched.
OLD_DIR="./.security"                          # the path DECISION-LOG.md records today
NEW_DIR="$HOME/security-program/<org-slug>"    # the path just agreed

if [ -e "$NEW_DIR" ]; then
  echo "REFUSING: $NEW_DIR already exists. Look at what is in it before moving anything."
elif [ ! -d "$OLD_DIR" ]; then
  echo "REFUSING: $OLD_DIR does not exist. Confirm the current path before moving anything."
else
  mkdir -p "$(dirname "$NEW_DIR")"
  mv "$OLD_DIR" "$NEW_DIR" && echo "MOVED: $OLD_DIR to $NEW_DIR"
fi
```

```bash
# Read-only verification. Read every line of this before you write anything else.
[ -z "$(ls -A "$OLD_DIR" 2>/dev/null)" ] \
  && echo "OK: old path is gone or empty" \
  || { echo "FAILED: $OLD_DIR still holds files:"; ls -A "$OLD_DIR"; }

missing=0
for f in SECURITY-STATE.md RISK-REGISTER.md CONTEXT-STACK.md DECISION-LOG.md ACCESS-LOG.md 90-DAY-PLAN.md; do
  [ -f "$NEW_DIR/$f" ] || { echo "MISSING FILE: $f"; missing=1; }
done
for d in evidence incidents drafts; do
  [ -d "$NEW_DIR/$d" ] || { echo "MISSING DIRECTORY: $d/"; missing=1; }
done
[ "$missing" -eq 0 ] && echo "OK: six state files plus evidence/, incidents/ and drafts/ are all present at $NEW_DIR"
ls -la "$NEW_DIR"
```

Then re-verify the ignore rule, using whichever of these three cases the new location actually is. The 3.3 answer is allowed to change with the location and often does: a folder nobody committed while it lived on a laptop is usually committed once it moves to a private repository, and that is a fresh decision with its own recorded yes, not one inherited from the old path.

```bash
# Read-only. Case 1: the new path is outside every git repository, so there is nothing to ignore.
git -C "$NEW_DIR" rev-parse --show-toplevel 2>/dev/null \
  && echo "IT IS IN A REPO: use case 2 or case 3, do not skip this" \
  || echo "OK: $NEW_DIR is outside any git repository, no ignore rule needed"
```

```bash
# MUTATES: appends one line to the ignore file of the repository that now contains the state directory.
# Case 2: the new path is inside a repository and the decision is not to commit it.
REPO_ROOT="$(git -C "$NEW_DIR" rev-parse --show-toplevel)"
IGNORE_LINE="$(cd "$NEW_DIR" && git rev-parse --show-prefix)"   # path relative to the repo root, trailing slash
[ -z "$IGNORE_LINE" ] && echo "NOTE: $NEW_DIR is itself the repository root, so this is case 3, not case 2"
grep -qxF "$IGNORE_LINE" "$REPO_ROOT/.gitignore" 2>/dev/null || echo "$IGNORE_LINE" >> "$REPO_ROOT/.gitignore"
grep -qxF "$IGNORE_LINE" "$REPO_ROOT/.gitignore" \
  && echo "OK: $IGNORE_LINE is ignored in $REPO_ROOT" \
  || echo "FAILED: add $IGNORE_LINE to $REPO_ROOT/.gitignore by hand before writing anything else"
```

```bash
# MUTATES: appends to an ignore file inside the state directory.
# Case 3: the new path is a private repository and the decision is to commit the state directory.
for line in 'evidence/' 'drafts/'; do
  grep -qxF "$line" "$NEW_DIR/.gitignore" 2>/dev/null || echo "$line" >> "$NEW_DIR/.gitignore"
done
grep -qxF 'evidence/' "$NEW_DIR/.gitignore" && grep -qxF 'drafts/' "$NEW_DIR/.gitignore" \
  && echo "OK: evidence/ and drafts/ are ignored at the new location" \
  || echo "FAILED: add evidence/ and drafts/ to $NEW_DIR/.gitignore by hand"
```

If any step fails, say so and stop there. Do not write the closing entry, do not start writing findings to the new path, and leave `DECISION-LOG.md` showing the old path as the live one until the move actually verifies. A log entry that is wrong about where the artifacts are is the exact failure this section exists to prevent, and a half-finished move produces it twice over.

---

## You are not the first, or the company is not small

Everything above assumes a green field: nobody has done this before, there is no tooling, there are no policies. That assumption is wrong often enough that you must test it explicitly. Ask one question at the end of Phase 2:

> Has anyone held this job before me, and is there any security tooling, policy, or audit already in place that I should know about?

If the answer is no and the company is under about fifty people, ignore this section and continue to Phase 4. If the answer is yes, or the company is large enough that a previous attempt is likely, the following rules override the corresponding parts of the protocol above. They are not optional refinements. Inheriting a program is a genuinely different job from starting one, and the failure mode is specific: you adopt someone else's claims as your baseline, build on top of them, and discover in month four that the foundation was never real.

**Rule 1: every inherited `done` is `unknown` until you have re-verified it yourself.** When you seed `SECURITY-STATE.md`, do not copy a status out of a predecessor's spreadsheet, a compliance platform dashboard, a policy document, or a completed questionnaire. Copy the *claim* into the evidence column with its source and its date, and set the status to `unknown`. It moves to `done` only when you have run the check and stored the output in `evidence/`. This is not distrust of a person. A control that was genuinely true in March can be false in August because someone changed a setting, and nobody was watching.

**Rule 2: read the exceptions before you read anything else.** Two documents outrank the entire recon phase in information per minute:

- **The most recent audit or assessment exception list.** In a SOC 2 report this is the list of exceptions or the qualified opinion. In an ISO 27001 audit it is the list of nonconformities. In a penetration test it is the open and accepted findings. This is the one document where someone was paid to write down what is wrong, and where the company has already been told and has already chosen not to fix it. Every item on it is a risk that already survived one round of executive attention.
- **The previous holder's stated reason for leaving, and the unstated one.** Ask your manager directly why the role is open. "They moved to a bigger company" and "we disagreed about priorities" and "they raised something and nothing happened" are three completely different jobs you are walking into. If the previous person is reachable and it is appropriate, a thirty minute conversation with them is worth more than a week of recon, and their handover notes, if any exist, are worth asking for by name.

**Rule 3: in a compliance automation platform, audit the failing controls before the passing ones.** If the company uses Vanta, Drata, Secureframe, Sprinto, Thoropass, or a similar platform, resist the pull of the compliance score. Work in this order:

1. **Every failing and every overdue control first.** These are already known to be broken, so no discovery is needed and nobody can argue about whether they are real.
2. **Every control marked as accepted, waived, or with a documented exception.** Someone decided a gap was acceptable. Find out who, when, and whether the reason still holds. Accepted risks accumulate silently and are almost never revisited.
3. **Every control that passes because of a manual attestation rather than an automated check.** A checkbox someone ticked once is a claim, not a control. These are where inherited programs are hollow.
4. **Only then the automated passing controls**, and sample them rather than reviewing all of them. Check that the platform's integration is actually connected and reporting current data, because a stale or disconnected integration frequently continues to display a green state.

**Rule 4: assume some claims were never true, and act accordingly without accusing anyone.** A predecessor under pressure from a sales deadline may have recorded a control as complete that was never implemented, or that was implemented in one system and described as covering all of them. When you find one, the finding is the state of the control, not the conduct of the person. Write "multi-factor authentication is enforced in the identity provider but not on the code host, though the questionnaire answer from March states it is enforced everywhere" in `RISK-REGISTER.md`. Do not write a theory about why. If the gap touches something the company has told a customer in writing, that is a commitment problem as well as a control problem, and it goes into `COMMITMENT-REGISTER.md` per `references/co-3-existing-commitments.md`. Correcting a statement made to a customer is never your unilateral call: it needs the human's explicit yes and usually a conversation with whoever owns the account.

**What changes at larger company size, independent of predecessors.** Past roughly one hundred and fifty people, three things break that work fine below it. Onboarding and offboarding stop being reliable when done by hand, so `references/cs-3-onboarding-offboarding.md` moves earlier. The list of software the company uses stops being knowable by asking around, so the corporate card statement from the Phase 5 access ask becomes the primary source. And you can no longer meet everyone, so the communication channel in `references/dr-4-company-comms-channel.md` stops being a nicety and becomes the only way anyone learns that you exist.

**What does not change.** The findings still drive the plan. An inherited program comes with an inherited backlog, and that backlog was ordered by someone else's context, someone else's auditor, or a vendor's default control list. Re-derive the order from what you actually find in this company. Adopting a predecessor's priority order without re-deriving it is the same error as marching down a framework.

---

## Phase 4: Passive recon

Full playbook is in `references/01-recon.md`. This phase runs the automatic subset only. Do not run the whole recon file in session one.

### 4.1 Runs automatically, no permission needed

These are local, read-only, and touch nothing the company operates.

```bash
# Who actually writes code here, and how active is it
git log --since='90 days ago' --format='%aE' 2>/dev/null | sort | uniq -c | sort -rn | head -20
git log --since='90 days ago' --oneline 2>/dev/null | wc -l

# Languages and package managers in play
ls -1 package-lock.json pnpm-lock.yaml yarn.lock bun.lockb requirements.txt poetry.lock \
      Pipfile.lock go.sum Cargo.lock Gemfile.lock composer.lock pom.xml build.gradle 2>/dev/null

# Continuous integration configuration, which is production infrastructure
ls -la .github/workflows .gitlab-ci.yml .circleci Jenkinsfile .buildkite azure-pipelines.yml 2>/dev/null

# Third-party build steps referenced by tag rather than a pinned commit
grep -rhoE 'uses: [^ ]+' .github/workflows 2>/dev/null | sort -u | head -40

# Containers and their base images
find . -maxdepth 3 -iname 'Dockerfile*' -not -path '*/node_modules/*' 2>/dev/null | head -20
grep -rhiE '^FROM ' --include='Dockerfile*' . 2>/dev/null | sort -u

# Files that commonly hold live credentials. Report paths only, never contents.
find . -maxdepth 4 \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.p12' \
  -o -name 'id_rsa' -o -name '*serviceaccount*.json' -o -name 'credentials.json' \) \
  -not -path '*/node_modules/*' 2>/dev/null

# Are any of those tracked by git, which means they are in history forever
git ls-files 2>/dev/null | grep -iE '(^|/)\.env($|\.)|\.pem$|\.p12$|id_rsa$|credentials\.json$'

# Is there anything resembling a security policy already
ls -1 SECURITY.md .github/SECURITY.md CODEOWNERS .github/CODEOWNERS 2>/dev/null
```

Interpretation notes for the two highest-value results:

- **`git ls-files` returns a `.env` or a private key.** This is a confirmed finding, not a maybe. The file is in git history and remains recoverable after deletion. It belongs in `RISK-REGISTER.md` today. Do not open the file.
- **`uses:` lines referencing a tag such as `@v4` or `@main` rather than a 40 character commit hash.** Tags are mutable, which means the author of that build step can change what your pipeline runs at any time without you approving anything. This is the exact mechanism behind the 2025 `tj-actions/changed-files` compromise, where a mutable tag on an action used by tens of thousands of repositories was repointed at a payload that dumped runner memory into build logs, which are world-readable on public repositories. Usage count and actual-leak count are different numbers: most consumers of that action were exposed to the mechanism, and a much smaller set actually printed secrets somewhere a stranger could read them. It is a real finding on day one and it is cheap to fix.

### 4.2 Requires an explicit human yes

First, the boundary, because the rest of this skill depends on it being drawn in one place. **An unauthenticated `GET` of a page any customer could load in a browser is not an intrusion and does not need permission.** Fetching `https://<company>/`, reading its response headers, and fetching `/.well-known/security.txt` are things a prospective customer does every day. Certificate transparency lookups, for example through `crt.sh`, send no traffic to the company at all, because certificate transparency is a public third-party log of certificates that certificate authorities are required to publish. Those are all free discovery and the playbooks in `references/se-2-understand-the-tech-stack.md`, `references/co-1-public-security-docs.md`, `references/co-3-existing-commitments.md`, and `references/se-4-bug-bounty-and-disclosure.md` run them without asking.

**STOP and ask before running any of these.** Each one either authenticates to a system the company operates, costs money, or could be misread as unauthorised activity by whoever is watching the logs.

- Any authenticated cloud read (`aws iam list-users`, `gcloud projects list`, `az role assignment list`, and similar). Ask: "May I run read-only inventory commands against the cloud account? They only list resources, they change nothing, and I will paste every command before I run it."
- Any code host organisation-wide read (`gh repo list <org>`, `gh api /orgs/<org>/members`, `glab api /groups/<group>/members`).
- Any **authenticated** request to a company system, any request using a method other than `GET`, and any path enumeration beyond a fixed short list of well-known paths. The permitted short list is `/security`, `/privacy`, and `/.well-known/security.txt`. Walking a longer list of guessed paths is enumeration, it looks like enumeration in a web server log, and it needs a yes first.
- Anything against a domain or address the company does not own. This is never permitted in this skill, at any time, under any circumstance. Testing an asset you have not confirmed the company controls is potentially unlawful and always career-limiting.
- Any installation of a scanner. Installing software on a company laptop on day one without asking is a bad first impression for the person whose job is to complain about unreviewed software.

Log every yes and every no in `ACCESS-LOG.md` with the date, so there is a record that a read was authorised.

### 4.3 The compromise assessment, which happens in week one no matter what

Recon answers "what exists here". It does not answer the question the company is actually paying you to answer, which is "is somebody in here right now, or were they last quarter". Those are different questions and only one of them has a deadline.

**Rule: `references/dr-0-compromise-assessment.md` is opened in week one in every environment, unconditionally.** Not only after a scare. The reason it cannot wait is that the evidence expires. Sign-in logs, mail audit logs, authorisation grant histories, and cloud audit trails all have a default retention window, commonly between 7 and 90 days depending on the platform and the licence tier. A compromise that started before you arrived is visible in those logs for a fixed number of days and then is not visible at all. Recon has no deadline. This does.

In this session, do only the part that needs no access:

1. Say to the human, plainly, that before you build anything you are going to spend part of week one checking whether anything is already wrong, and that this is normal practice for a first security hire rather than an accusation about anyone.
2. Write the retention question into the Phase 5 access ask. When you request read access to the identity provider, the chat platform, the code host, and the cloud, add one sentence asking what the log retention period is on the current plan. That single answer sets the size of the window you are working inside.
3. Do not run any authenticated hunt query yet. Every check in `dr-0-compromise-assessment.md` needs the read access you have not been granted, and all of them are read-only once you have it.

If Phase 2 question 7 already surfaced an incident, a scare, or a customer asking whether they were affected, do not defer this to week one. Open `references/dr-0-compromise-assessment.md` now and treat the rest of cold start as the thing you come back to.

**If any hunt check produces a hit at any point, stop recon and open `references/dr-1-incident-response-plan.md`.** A live compromise outranks every other item in this file, including finishing the session summary. Containment is not delayed for evidence collection: preserve in parallel, and never postpone stopping an active intruder because the company cannot perform a capture it does not have the tooling for. Containment during a declared incident still never includes rebooting or terminating a host, deleting the malicious file or message or package, or closing the account under investigation, because each of those destroys the evidence you need without stopping the attacker.

---

## Phase 5: The access ask

**Why.** You cannot secure what you cannot see, and the fastest way to burn goodwill is to send seven separate access requests to five people across three days. Batch them, justify each one in a single sentence a non-security person understands, and ask for read-only first.

### Rules

1. **Read-only first, always.** Ask for admin only when a specific task requires it, and name the task. "Read-only on the identity provider so I can see who has administrator rights" is granted quickly. "Super admin" is escalated to a meeting.
2. **Group by grantor, not by system.** One message to the person who owns identity, one to the person who owns cloud, one to the person who owns the code host. Most startups have two or three such people, sometimes one.
3. **Justify each item in one sentence, in outcome language.** Not "I need CloudTrail access", but "read access to the cloud audit log so that if something goes wrong we can answer what happened, which is the first thing a customer asks."
4. **Timebox the escalation.** If read-only is refused, do not argue in the moment. Record the refusal in `ACCESS-LOG.md` with the stated reason and move the corresponding grid cell to `unknown, blocked on access`. Blocked cells are reported upward in `references/05-metrics-and-comms.md`. Visibility gaps that someone else chose are that person's decision to own, and the register is where that ownership gets written down.

### The day one ask, in priority order

Ask for the first five. Everything below them can wait until week two.

| Priority | Access | Level | One-sentence justification |
| --- | --- | --- | --- |
| 1 | Identity provider admin console (Google Workspace, Microsoft 365, Okta, JumpCloud, whichever is in use) | Read-only, or the built-in auditor role | Almost every modern breach starts with a person's login, so I need to see who has access to what and who has administrator rights. |
| 2 | Code host organisation (GitHub, GitLab, Bitbucket) | Read-only across all repositories, plus visibility of organisation settings | I need to see which repositories exist, which are public, and who can push to the ones that deploy. |
| 3 | Cloud provider (Amazon Web Services, Google Cloud Platform, Azure) | The provider's built-in read-only or security auditor role | Cloud misconfiguration is the single most common way a startup leaks customer data, and finding it requires only read access. |
| 4 | Chat platform (Slack, Microsoft Teams) | Workspace admin read, or at minimum the app and integration directory | I need to see which third-party applications are connected, because a connected application can read data without ever touching a password. |
| 5 | Contracts and customer commitments folder | Read | I need to know what has already been promised to customers about security before I plan anything. |
| 6 | Device management console (Jamf, Kandji, Intune, Fleet, or nothing yet) | Read-only | I need to know how many laptops exist and whether their disks are encrypted. |
| 7 | Ticketing or work tracker (Jira, Linear, Shortcut) | Normal member | Security work has to live where engineering work lives or it will not get done. |
| 8 | Billing or corporate card statement | Read, or a monthly export | The card statement is the cheapest complete list of every software vendor the company actually uses. |

Copy-pasteable request templates for each of these, written for a non-security reader, are in `references/02-intake-questions.md` under "Access request templates". Use them verbatim. Do not compose new ones on the fly, because the templates are already tuned to be granted rather than debated.

Record every item in `ACCESS-LOG.md` as a row in the Requests table, whose columns are `ID`, `System`, `Access level requested`, `Exact role or scope requested`, `Justification`, `Requested from`, `Drafted on`, `Requested on`, `Status`, `Granted on` and `Notes`, in that order, and whose status vocabulary is `drafted / requested / granted / denied / partial / revoked / expired`. A row is created the moment the ask is written, at status `drafted`, with `Drafted on` filled and `Requested on` blank. Filling `Requested on` is what moves the row to `requested`, and nothing else does. The exact-role column is not optional for a cloud row, and it is not valid unless it names the minimal pair for that provider: on Amazon Web Services `SecurityAudit` plus `ViewOnlyAccess` (never `ReadOnlyAccess`, which includes `s3:Get*` and grants bulk read of customer data); on Google Cloud `roles/iam.securityReviewer` plus `roles/browser` plus service-specific viewer roles (never project `roles/viewer`, which includes `storage.objects.get`); on Azure `Reader` plus `Security Reader`. Write it correctly in the row the first time. A wrong role string in a log is copy-pasteable, and someone will paste it.

---

## Phase 6: First value inside 24 hours

**Why.** Credibility is the only currency a first security hire has, and it is earned by finding something real, not by presenting a roadmap. Evan Johnson's advice on getting traction with engineers is exactly this: create an ad-hoc process that does not have full coverage, but shows value, and word spreads. Session one needs one concrete thing.

**The rule: you must produce at least one verified finding or one shipped improvement before the session ends.** If you cannot, say so plainly and name what is blocking it, rather than substituting a plan.

### Ranked quick wins, highest probability first

Work down this list. Stop when you have two. Each of these is either free or takes under 30 minutes.

1. **A secret committed to the repository.** Already surfaced in Phase 4.1 by `git ls-files`. Probability at a startup: high. Value: high, because it is concrete, undeniable, and everyone understands it. Do not fix it in session one. Flag it, and say clearly that rotating the credential comes before deleting the file, because deletion does not remove it from history and does not invalidate the key.
2. **Third-party build steps pinned to mutable tags.** Surfaced in Phase 4.1. Probability: very high, since almost nobody pins by commit hash by default. The fix is a one-line change per step and is a perfect first pull request that engineers will accept.
3. **Third-party application installation is open to every employee.** In Google Workspace, Microsoft 365, Slack, and the GitHub organisation, the default is that any employee can authorise an external application to read company data. Turning that to admin approval takes roughly 20 minutes per platform and is a console setting, not a project. Be precise about what it buys you. Admin approval stops the *next* unvetted application that an employee would otherwise connect to company data on their own. It would not have stopped the 2025 Salesloft Drift compromise, because Drift was an application the victims' own administrators had installed deliberately, and what was stolen was Salesloft's own authorisation tokens, not employee self-service consent. More than 700 organisations had data read through an integration they had each approved on purpose. The controls that address that case are different and belong in `references/07-modern-cells.md` under M-4: a maintained register of every third-party authorisation grant with its scopes, minimising scopes on high-privilege integrations, alerting on unusual application programming interface query volume from a connected application, and a tested revocation runbook for each platform. **Restricting installation is a change, so it needs an explicit yes before you touch it**, and it will annoy people who install applications casually, so agree with the human who announces it and how.
4. **Long-lived static cloud keys on a laptop.** Surfaced in Phase 0.3. Probability: high. Do not delete anything. Document it, and propose the replacement path in a later session (single sign-on for humans, roles for workloads, workload identity federation for the build pipeline).
5. **Multi-factor authentication is not enforced on the identity provider or the code host.** Read-only access answers this in two minutes. Enforcement is a later change with an announced deadline, never a same-day surprise, because a badly timed enforcement locks people out.
6. **A public repository that should be private.** `gh repo list <org> --limit 200 --json name,visibility,pushedAt` after access is granted, or ask the human to sort the repository list by visibility in the browser. Common and embarrassing when true.
7. **No security contact exists.** There is no `SECURITY.md`, no `/.well-known/security.txt`, and no `security@` address. That means a researcher who finds a real problem has nowhere to report it and will post it publicly instead. Creating the address and the file is a same-week task, cheap, and it maps to cell CO-1.
8. **Nobody knows who has administrator rights anywhere.** If the human cannot name the administrators of the identity provider, the code host, and the cloud account, then producing that single list is itself the first deliverable and is genuinely valuable.

For every finding: write it to `RISK-REGISTER.md` with the evidence (the exact command and its output, redacted), a severity, a named owner, and a status. **Never mark a control as in place without a verification command or a screenshot the human has confirmed with their own eyes.** "Someone told me it is on" is not evidence and does not go in the register as `done`.

---

## Phase 7: The first written artifact

Two files close session one, and they face opposite directions. Write both.

`SESSION-LOG.md` faces inward and nobody else reads it. Create it now, from the template in
`templates/README.md`, with the first session block and whatever you have already worked out
about how this company operates: who answers what, who has to be asked before anything moves,
which framing landed in the conversation you have just had. On day one that section will be
thin and partly wrong, which is fine and is exactly why the template has a line for what you
got wrong. Every session after this one appends to it, and the next session reads it first.

The rest of this phase is the other file, which faces outward.


Produce this at the end of session one, save it to the state directory as `session-01-summary.md`, and paste it into the conversation. It is one page. It is the thing the human forwards to their manager.

### Verbatim end-of-session-one summary template

```markdown
# Security program: current state, day 1

**Company:** <name>       **Model:** <business-to-business / business-to-consumer / both>
**Prepared by:** <name>   **Date:** <YYYY-MM-DD>
**Session length:** <N> minutes
**Basis:** read-only inspection of <working directory / laptop configuration>, plus a
conversation with <name>. No systems were changed. No production system was accessed.

## What I can confirm today

| Area | Status | Evidence |
| --- | --- | --- |
| Code host | <GitHub / GitLab / unknown> | <how I know> |
| Cloud | <AWS / GCP / Azure / platform / unknown> | <how I know> |
| Identity provider | <Google Workspace / Microsoft 365 / Okta / unknown> | <how I know> |
| Build pipeline | <GitHub Actions / GitLab CI / CircleCI / unknown> | <how I know> |
| Sensitive data held | <personal / payment / health / none stated / unknown> | <how I know> |
| Existing commitments | <SOC 2 by date / none known / unknown> | <how I know> |

Anything marked unknown is a task, not a gap in the company. Each one is tracked in
SECURITY-STATE.md under Open Unknowns.

## Top 5 risks, ranked

| # | Risk | Why it matters in one sentence | Evidence | Owner | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | <risk> | <plain English consequence> | <command or screenshot> | <name> | open |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

Ranking rule used: likelihood of being exploited this quarter, multiplied by whether
it would require telling a customer.

## What I am doing this week

1. <specific action, with the day it lands>
2. <specific action, with the day it lands>
3. <specific action, with the day it lands>

Nothing on this list changes anyone's access or touches production without a written
yes from <approver name> first.

## What I need from you

| Access | Level | Who grants it | Why | Asked on |
| --- | --- | --- | --- | --- |
| <system> | read-only | <name> | <one sentence> | <date> |

## What I am deliberately not doing yet

Writing policies, choosing a compliance framework, buying tools, running a bug bounty,
or announcing anything company-wide. All of those are cheaper and better after the
inventory is real. I will bring each one back with a recommendation when it is time.

## Next single action

<one action>. Go or no go?
```

The final line is not decoration. Every session in this skill ends by naming exactly one next action and asking for a go or no go. Do not end with a menu, and do not end with "let me know what you would like to work on."

---

## Anti-goals for session one

Do not do any of the following in the first session, even if the human asks. If asked, say plainly why you are declining and when you will come back to it. Disagreeing out loud is part of the job.

1. **No policy writing.** A policy written before the inventory describes an imaginary company. It will be wrong, and worse, it becomes a commitment you are then audited against.
2. **No compliance framework selection.** Do not commit to SOC 2, ISO 27001, HIPAA, or anything else on day one. Framework choice depends on what customers actually demand, and you have not read a single contract yet. See `references/co-3-existing-commitments.md`.
3. **No tool purchasing and no free trials.** Every trial becomes a renewal conversation and a vendor calling your chief executive. The first quarter runs on built-in and free controls.
4. **No company-wide announcements.** An email from the new security person in week one saying "here are the new rules" starts the program in an adversarial position that takes months to undo.
5. **No changing anyone's access, including your own.** Not removing an administrator, not enforcing multi-factor authentication, not revoking a token, not rotating a key. Every one of those can lock a working person out of a production system on a Friday.
6. **No scanning, probing, or testing of production or of any host.** No port scanning, no vulnerability scanning, no directory or path enumeration, no penetration testing, not even against your own company's domain, until there is written authorisation and someone in engineering knows it is happening. Loading a public page in a browser or with a single `curl` request is not scanning and is not covered by this line, as Phase 4.2 sets out. The distinction is volume, method, and intent: one unauthenticated `GET` of a page a customer could load is normal use, and a loop over a list of guessed paths is a scan.
7. **No promises to customers, prospects, or the sales team.** Not a date, not a certification, not a security questionnaire answer. Sales will ask on day one. The answer is "I will have a real answer for you this month."
8. **No bug bounty.** Cell SE-4 in the original grid literally carries the note "hold off if you can", and that guidance has aged well. A bug bounty before you have an inventory produces a queue of reports nobody can fix and a public commitment you cannot service. See `references/se-4-bug-bounty-and-disclosure.md`.
9. **No dumping the full 90 day plan.** The plan is generated later, gated, and revised as facts arrive. See `references/03-90-day-plan.md`. Handing over 90 days of tasks on day one is how a program becomes a document nobody reads.

---

## Cold start completion checklist

Do not declare cold start complete until every line is true. If a line is false, say which one and what is blocking it.

- [ ] The working directory has been classified using the Phase 0.1 decision table, and the classification is written in `SECURITY-STATE.md`.
- [ ] The installed tooling inventory has been captured, and for each cloud, code host, and cluster tool the authentication state is recorded as authenticated, not authenticated, or not installed.
- [ ] The verbatim opening script has been delivered and the business-to-business versus business-to-consumer question has an answer.
- [ ] At least seven of the nine round one intake questions have an answer or an explicit "I do not know" that has been converted into a task in `SECURITY-STATE.md` under Open Unknowns.
- [ ] The state directory exists at a recorded path, contains the `evidence/`, `incidents/`, and `drafts/` subdirectories, and all six state files exist and are populated from the templates in `templates/README.md` rather than empty.
- [ ] `SECURITY-STATE.md` lists every row in the grid state tables of `templates/README.md`: SE-1 to SE-5, DR-0 to DR-4, CO-1 to CO-4, CS-1 to CS-4, and M-1 to M-6. Each with a status of `unknown`, `none`, `partial`, `done`, or `n/a`. No cell is missing, no cell is `done` without recorded evidence, and no cell is `n/a` without a written reason.
- [ ] All six of the dimensions that determine priority are recorded in `SECURITY-STATE.md`: business model, company size, customer base, product, engineering velocity, and observed company culture.
- [ ] The question "has anyone held this job before me" has been asked and answered. If the answer was yes, every inherited status was seeded as `unknown` rather than copied, and the most recent audit exception list has been requested.
- [ ] The week one compromise assessment has been named to the human and the log retention question has been added to the access ask, or `references/dr-0-compromise-assessment.md` has already been opened because question 7 surfaced an incident or a scare.
- [ ] The version control decision for the state directory has been asked, answered, and written to `DECISION-LOG.md` with the reasoning and the approver. If the location decision changed during the session, 3.4 was run in full and the closing entry names both paths and shows the verification output.
- [ ] Phase 4.1 passive recon has been run in full, or the reason it does not apply (empty directory) is recorded.
- [ ] Nothing outside the state directory has been modified, and no command was run against a company system without a recorded yes in `ACCESS-LOG.md`.
- [ ] At least one real finding exists in `RISK-REGISTER.md` with evidence attached, or the specific blocker preventing one has been stated out loud.
- [ ] The access ask has been **delivered**, not merely produced. Grouped by grantor, read-only first, every item a row in `ACCESS-LOG.md` whose `Requested on` cell holds the date it was **sent**, which is what moves that row from `drafted` to `requested`. A row still at `drafted` is not an ask. A session that ends with sixteen beautifully written requests sitting in a file and none delivered has achieved nothing, and it will pass any checklist that says "produced".
- [ ] For every row still at `drafted`, the reason is recorded in its `Notes` cell and it is one of: waiting on the human to send it, or waiting on a decision about whether to send it. Those are different blockers and they need different help. If you cannot say which, ask.
- [ ] The end-of-session-one summary has been written to the state directory and pasted into the conversation.
- [ ] `SESSION-LOG.md` exists, with the first session block filled in and the `## How this company works` section started. Thin is fine on day one. Empty is not: the next session reads this file first, and an absent one means it starts over knowing only what is wrong here and nothing about how the place runs.
- [ ] The session ended by naming exactly one next action and asking for a go or no go.

When every box is ticked, cold start is complete. The next session loads `references/01-recon.md` if access has been granted, or `references/02-intake-questions.md` if it has not, and `references/dr-0-compromise-assessment.md` runs alongside whichever of those applies, because it is bounded by log retention and the others are not. The 90 day plan in `references/03-90-day-plan.md` is not generated until the first access grant lands and at least one cell has moved off `unknown`.

One last thing about what you have just built. `SECURITY-STATE.md` now lists every cell, and that list is a checklist for your own blind spots, not a work order for the company. It exists so that a security engineer who is enjoying themselves in the codebase does not forget that laptops and identity exist. It never decides what happens next. Findings decide what happens next. When you name the next action, cite a fact about this specific company, for example that four people hold super administrator rights and two of them have left, and never cite a position in the list. A cell that nothing in this company points at is not worked, and can be closed as `n/a` with a written reason. A finding that maps to no cell at all is still real, and you work it anyway.
