# The modern cells: supply chain, CI/CD, cloud posture, SaaS and OAuth, AI and LLM, backups

> **Load when:** something you have already found in this company points at dependencies or a package registry, the build pipeline (continuous integration and continuous delivery, written CI/CD), cloud configuration, a third party software as a service (SaaS) tool or an open authorisation (OAuth) grant, or use of artificial intelligence and large language models (LLMs), and none of the sixteen original grid cells covers it. Concretely: a credential was exposed by a dependency or by a build step (a credential exposed by a commit belongs to `references/se-3-secrets-and-keys.md` instead); a third party application holds a token against a company platform and you need the grant register or the revocation runbook (the login side, single sign on and multi factor authentication, belongs to `references/cs-1-identity-and-access.md` instead); a storage bucket or database is reachable from the internet; the product or the team sends data to a model provider. Also load when the human asks "what is missing from this plan" or when `references/06-2019-to-2026-delta.md` has told you the 2019 grid is incomplete and you need the actual playbooks.

## What this file is

The 2019 grid has sixteen cells across four domains. Those cells are still correct. They are not complete. Six things that were minor or nonexistent in 2019 are now among the most common ways a startup actually gets compromised or loses its data, and none of them has a home in the original grid.

This file adds five cells, numbered `M-1` through `M-5`, and points at a sixth, `M-6`, which lives in its own file because it is long. The `M` stands for modern. They are numbered separately so the original grid keeps its canonical numbering forever. Never renumber `SE`, `DR`, `CO`, or `CS` cells to make room for these.

| Cell | Name | Closest original cell | Why it needed its own cell |
|------|------|-----------------------|----------------------------|
| M-1 | Software supply chain | SE-2 (understand your tech stack) | SE-2 is about code you wrote. Most of your executing code is code you did not write. |
| M-2 | CI/CD and build system security | SE-1, CS-1 | The pipeline holds production credentials, runs untrusted code by design, and has less protection than production. |
| M-3 | Cloud posture | none | The 2019 grid has no cloud cell at all. The perimeter is now an access policy document. |
| M-4 | SaaS sprawl and OAuth grants | CS-1 (identity and access) | Identity and access management covers logins. It does not cover a third party application holding a refresh token to your customer data. |
| M-5 | AI and LLM security | none | Three separate surfaces appeared after 2019 and teams conflate them. |
| M-6 | Backups and recovery | none | Every other cell is about data being read. This one is about the data not being there any more. |

`M-6` is not written out below. Its playbook is `references/m-6-backups-and-recovery.md`. **Load that file when** anything here points at losing data rather than leaking it: someone asks about backups, restores, disaster recovery, business continuity, recovery time objective, recovery point objective, ransomware, or immutability; a questionnaire or a contract asks you to state a recovery time; a destructive event has happened; or a finding shows that the identity which runs production also holds deletion rights over the backups. Do not duplicate its content here.

Record whichever of these you actually work in `SECURITY-STATE.md` under the `### Modern cells` subsection of `## Grid state`, which covers `M-1` through `M-6`, using the same status vocabulary as the original cells: `unknown`, `none`, `partial`, `done`, `n/a`. A cell moves to `done` only with recorded evidence, and to `n/a` only with a written reason (for example, "no cloud footprint, the product runs entirely on a customer's own hardware").

**Dependency note, not a running order.** `M-2` (pipeline) and `M-4` (third party grants) both assume there is an identity foundation to hang them on. If you reach one of them and `CS-1` (identity and access management) or `SE-3` (secrets and keys) has produced nothing yet, say so, because a federation change or a grant revocation with no authoritative identity provider behind it will not hold. That is a prerequisite, not a schedule.

**Partner behaviour reminder.** Findings decide what happens next, never this table. Do not present the list of cells to the human and do not narrate cell identifiers turn by turn; those are your bookkeeping. Propose one piece of work, justify it with a fact about this specific company ("the deploy role can be assumed from any branch in the repository, including a fork's"), and ask for a go or no-go. If nothing you have found in this company points at a cell here, that cell is not worked, and closing it as `n/a` with a written reason is a legitimate outcome. If the human wants something different, take it and note the reordering in `DECISION-LOG.md`.

---

## M-1 Software supply chain

### Why this exists (plain language)

Your application is mostly other people's code. When an engineer runs the install command for the package manager, that code lands on a laptop and often executes immediately, before anybody deploys anything. So the question is no longer "does one of our dependencies have a known bug." It is "did one of our dependencies get taken over last night, and did it steal the credentials sitting on a developer laptop or a build machine."

These are two different problems and most teams only solve the first one:

- **Known vulnerability scanning** (sometimes called software composition analysis, SCA) compares your installed versions against a public database of reported flaws. It finds old code with published problems. It cannot find a brand new malicious release, because a malicious release has no database entry for the first several hours, and often never gets one.
- **Malicious package detection** looks at behaviour: does this new version suddenly read environment variables, phone home to an address nobody has seen before, write files outside the project, or run a script on install. This is what catches an active attack.

You need both. If the company only has one, it is almost always the first one.

The 2025 and 2026 wave of self replicating package worms made this concrete. The pattern is: a maintainer gets phished or has a token stolen, the attacker publishes a poisoned version, the poisoned version runs on install, harvests registry tokens and code host tokens and cloud credentials from the machine, then uses those stolen maintainer tokens to publish poisoned versions of further packages. The victim laptop is the initial target, not production. And if a stolen token belongs to one of your maintainers, you become the source of the next wave and you owe your own customers a disclosure.

### Definition of done

`M-1` is `done` when all of the following are true and you can show evidence for each:

1. Every application repository has a committed lockfile, and continuous integration installs from the lockfile in a mode that fails if the lockfile is out of date.
2. Install scripts do not run by default on developer machines or in continuous integration, with a short explicit allowlist for the handful of packages that genuinely need them.
3. There is a policy against installing package versions younger than some cooldown window (7 to 14 days), with a documented waiver path.
4. Something looks at new dependency versions for malicious behaviour, not only for known vulnerabilities.
5. You can answer "are we running package X at version Y anywhere, including build images" in under 30 minutes.
6. A written malicious dependency runbook exists whose first step is credential rotation, not package removal.
7. Anything the company publishes publicly is published from continuous integration with provenance, and no human holds a long lived publish token.

### Discovery

Run these in the working directory or the repository root. All are read only.

```bash
# 1. Which ecosystems and package managers are in play
ls -a | grep -Ei 'package.json|requirements|pyproject|Gemfile|go.mod|Cargo.toml|composer.json|pom.xml|build.gradle'
find . -maxdepth 3 -name 'package.json' -not -path '*/node_modules/*' | head -50

# 2. Lockfile presence per ecosystem (the answer you want is: exactly one, committed)
ls package-lock.json npm-shrinkwrap.json yarn.lock pnpm-lock.yaml 2>/dev/null
ls poetry.lock uv.lock requirements.txt Pipfile.lock 2>/dev/null
ls go.sum Cargo.lock Gemfile.lock composer.lock 2>/dev/null

# 3. Is the lockfile actually committed and tracked
git ls-files | grep -E 'lock|\.sum$'

# 4. Direct dependency count versus total installed (the gap is the real surface)
[ -f package.json ] && node -e "const p=require('./package.json');console.log('direct:',Object.keys({...p.dependencies,...p.devDependencies}).length)"
[ -d node_modules ] && ls node_modules | wc -l

# 5. Install script posture for Node projects
cat .npmrc 2>/dev/null
npm config get ignore-scripts

# 6. Do we already have any scanning at all
grep -RIl --exclude-dir=node_modules -E 'dependabot|renovate|snyk|osv-scanner|trivy|grype|socket|npm audit|pip-audit' . | head -20
ls .github/dependabot.yml renovate.json .renovaterc* 2>/dev/null
```

If a package manager is present that you do not know, ask rather than guess. If the directory contains no code at all, this cell is discovered by interview only: use the dependency questions in `references/02-intake-questions.md` and mark `M-1` as `unknown` in `SECURITY-STATE.md` until you get repository access. Log the access request in `ACCESS-LOG.md`.

### The walk

**Step 1. Lockfiles and reproducible installs.** A lockfile pins the exact version and content hash of every package, direct and transitive. Without one, two machines installing on the same day can get different code. Confirm one lockfile per project, committed, and that continuous integration installs in strict mode. Strict install commands by ecosystem:

| Ecosystem | Command to use in continuous integration | Note |
|-----------|------------------------------------------|------|
| npm | `npm ci` | |
| pnpm | `pnpm install --frozen-lockfile` | |
| Yarn Berry (version 2 and later) | `yarn install --immutable` | Yarn 1 uses `yarn install --frozen-lockfile` |
| Poetry | `poetry sync` | Poetry 1 used `poetry install --sync`, deprecated in Poetry 2 |
| uv | `uv sync --frozen` | |
| pip | `pip install --require-hashes -r requirements.txt` | Requires a hash pinned requirements file, for example one generated by `pip-compile --generate-hashes` |
| Bundler | `bundle config set --local deployment true` then `bundle install` | `bundle install --deployment` is the deprecated Bundler 1 form |
| Go | `go mod verify` plus `go build -mod=readonly` | |
| Cargo | `cargo build --locked` | |
| Composer | `composer install --no-interaction` plus a separate `composer validate --no-check-publish --strict` step | |

All of these except `composer install` fail outright if the lockfile disagrees with the manifest, which is exactly what you want. Composer only prints a warning and carries on with a stale `composer.lock`, so for Composer projects the `composer validate --strict` step is what actually enforces agreement, and it has to be its own continuous integration step that can fail the build.

**Step 2. Turn off install scripts.** For Node, `ignore-scripts=true` in a committed `.npmrc` stops `preinstall`, `install`, and `postinstall` hooks running automatically. This is the single cheapest control in this cell because install hooks are the main delivery mechanism for package malware. Expect breakage in native modules and in a handful of tools. The pattern that works: set it globally, then keep a short allowlist and run those specific packages' scripts explicitly (`npm rebuild <pkg>`) or use pnpm's `onlyBuiltDependencies` allowlist. In Python, the equivalent is preferring wheels over source distributions, because a source distribution executes `setup.py` at install time: `pip install --only-binary=:all:` where the ecosystem permits.

**Step 3. Cooldown on new versions.** Malicious releases are usually pulled within hours to a few days. A rule that says "no package version younger than seven days without a named approver" defuses most published malware campaigns and costs almost nothing in developer experience, because urgent security patches get the waiver. Implement it wherever your update automation lives: Renovate supports a minimum release age setting, and Dependabot has a comparable cooldown configuration. If neither is in use, write the rule down and enforce it in review until tooling exists.

**Step 4. Add behavioural detection, not just vulnerability scanning.** Free and near free options to raise first: `osv-scanner` (Google, open source, reads lockfiles and reports known vulnerabilities), `pip-audit`, `npm audit`, `grype`, and `trivy` for known issues. For malicious behaviour, the practical options are a commercial supply chain product that reviews new versions for capability changes (Socket, Phylum style products, often free for open source and small teams, then in the low thousands per year), or a homegrown check that diffs the new version's install scripts and network calls. Say the price band honestly and recommend starting with the free known vulnerability scanner plus the cooldown rule, then buying behavioural detection when the company can afford it. **You never buy, trial, or sign up for anything yourself.** Present the option, the price band, and what it would catch, and let the human decide and purchase.

**Step 5. Typosquatting and slopsquatting.** Typosquatting is a package named one character away from a real one. Slopsquatting is newer and specific to 2025 and after: a code generating model hallucinates a package name that does not exist, an attacker notices the hallucination is repeatable, registers that name, and waits for engineers to install what the assistant suggested. The control is the same for both: no new direct dependency enters the codebase without a human confirming the exact name, the repository link, and that it has a plausible download history and maintenance record. Put this in the pull request checklist for any diff that adds a manifest line. Link `SE-1` for how that review gets embedded.

**Step 6. Pinning and vendoring decisions.** Give the human a rule, not a debate. Applications commit a lockfile and pin exactly. Libraries you publish use ranges in the manifest so consumers can resolve, and pin only in the development lockfile. Vendoring (copying dependency source into your repository) is worth it for a very small number of tiny, critical, rarely changing dependencies, and is a maintenance burden everywhere else. Do not propose vendoring the dependency tree.

**Step 7. SBOM with one job.** A software bill of materials is a machine readable list of everything in a build. Generate it in continuous integration and store it somewhere queryable. `syft dir:. -o cyclonedx-json=sbom.json` produces one, and `grype sbom:sbom.json` scans it. The only test that matters: when a package is reported malicious at 9pm, can somebody grep every service and every build image for it and answer in under 30 minutes. If the answer lives in a compliance folder nobody opens, the artifact is theatre. Say that plainly.

**Step 8. Provenance for what you publish.** If the company publishes any package, container image, or binary, publishing should happen only from continuous integration, with a short lived credential, and with an attestation that says which commit and which workflow built it. On npm that is trusted publishing plus `npm publish --provenance`. On PyPI it is Trusted Publishers. For containers and binaries, `cosign` signing or the code host's build attestation feature (on GitHub, `actions/attest-build-provenance`, verified with `gh attestation verify <file> --owner <org>`). Verify signatures where the registry supports it: `npm audit signatures` checks registry signatures on your installed tree.

### Danger zone

- **STOP before setting `ignore-scripts=true` repository wide without a build test.** It can break native module compilation and therefore break every developer's environment and the build. Propose it, test on a branch, get a named engineer to confirm the build passes, then land it. Record the approval in `DECISION-LOG.md`.
- **STOP before yanking, deprecating, or unpublishing anything the company owns.** That is a customer visible action.
- **Do not rotate a shared registry publish token unilaterally.** It will break every release pipeline that still uses it. Coordinate with whoever owns releases.
- **Do not run an unknown package to "see what it does" on a work laptop or a machine with cloud credentials.** If dynamic analysis is needed, use a disposable virtual machine with no credentials and no corporate network access, or hand it to a service built for it.
- **Never paste suspected malicious package source into a chat with customers or a public forum before you understand whether it names your company.**

### The malicious dependency runbook (write this before you need it)

Save it as part of the incident response material referenced by `DR-1`. The ordering is the whole point.

1. **Assume credentials are gone first, packages second.** Determine which machines installed the affected version and when: developer laptops, continuous integration runners, container build steps, and any production image built during the window.
2. **Rotate everything reachable from those machines in the exposure window.** Registry tokens, code host personal access tokens and deploy keys, cloud credentials, secrets manager values pulled during builds, and any session cookies for administrative consoles. Two different approval rules apply here and you must keep them apart. Rotating a credential that **production** uses, including a service account key, a deploy key, or a registry publish token, breaks running systems: **STOP, get an explicit human yes**, and do it with the owner of that system on the call. Revoking a **human** user's sessions and refresh tokens, and revoking a third party OAuth grant, may instead proceed on the incident commander's authority once an incident is declared, provided the standing pre-authorisation in step 10 of `references/dr-4-company-comms-channel.md` was agreed in advance and recorded in `DECISION-LOG.md`. This is the one named exception to the hard stop on access changes in `SKILL.md`, and it covers no other hard stop.
3. **Only then remove or pin the package** and rebuild affected images, which is a deploy and needs the same explicit yes. Before the package is deleted anywhere, have somebody save a copy of the exact malicious version and the install logs to `evidence/`. Do that in parallel, never as a reason to delay step 2. If nobody can capture it in the next few minutes, rotate anyway and accept the lost evidence.
4. **Check outbound.** Did any package your company publishes get republished during the window. Compare published versions against your release records.
5. **Search for the payload's indicators**, typically an added workflow file, a new outbound domain, or a modified script hook, across all repositories.
6. **Decide on disclosure** with whoever owns customer communication. If a customer facing artifact was built from a poisoned tree, this is a customer notification decision, not a security team decision alone. Route through `DR-4` and `CO-3`. You never send, publish, or approve an external statement yourself, and you never tell a customer that a control existed or that a date will be met.
7. Record the incident in `incidents/INC-<YYYY>-<NNN>-<slug>.md` per `references/dr-1-incident-response-plan.md`, with the timeline, and put the residual exposure in `RISK-REGISTER.md` and the decisions in `DECISION-LOG.md`.

### First action

Ask the human for read access to one representative repository. Then run the discovery block above and report exactly three things: which package managers are in use, whether a lockfile is committed for each, and whether install scripts run by default. Propose the cooldown rule as the first change because it is a policy change with no engineering cost. Ask for a go or no-go on that one change.

---

## M-2 CI/CD and build system security

### Why this exists (plain language)

CI/CD stands for continuous integration and continuous delivery, the automated system that builds, tests, and deploys the code. It typically has the ability to write to production, holds every secret the application needs, and runs code written by strangers (dependencies, test tools, third party pipeline steps) by design, with no human watching. In most startups it has weaker protection than the production it deploys to, and nobody has ever read its audit log.

The realistic attack is not exotic. Someone compromises a third party pipeline step or a dependency, that step reads the runner's memory or environment, secrets leak into the build log, and the attacker now has a deploy credential. In 2025 a single popular pipeline action used by tens of thousands of repositories was repointed at a payload that dumped runner memory into public logs, and it had been enabled by an earlier compromise of a different action that leaked a token. Step to step lateral movement inside a pipeline is a normal technique now.

### Definition of done

1. No long lived cloud credential exists in the pipeline. Cloud access is via short lived federated identity, scoped to a specific repository and branch.
2. Every third party pipeline step is pinned to an immutable commit digest, enforced by a check.
3. The job that runs untrusted code (build, test, dependency install) is a different job from the one that holds deploy credentials.
4. Secrets are scoped to the smallest possible unit (environment or job), not available to every workflow in the organisation.
5. Default token permissions are read only, with write granted per job where needed.
6. Branch protection exists on default branches, applies to administrators, and any change to protection settings or to pipeline definition files raises an alert.
7. There is a current, generated list of every identity that can deploy to production.

### Discovery

Branch on code host. Everything here is read only.

**If the company uses GitHub:**

```bash
# Where the pipeline definitions live
ls -la .github/workflows/ 2>/dev/null && cat .github/workflows/*.y*ml | head -200

# Highest signal grep: dangerous trigger, unpinned actions, broad permissions
grep -RnE 'pull_request_target|workflow_run|self-hosted|permissions:|uses: .*@(v[0-9]|main|master)' .github/workflows/ 2>/dev/null

# Org and repo level settings (needs a token with the right read scope)
# gh api substitutes only {owner}, {repo}, and {branch} from the current repository.
# Anything else, including an organisation slug, must be a shell variable.
gh api /repos/{owner}/{repo}/actions/permissions
gh api /repos/{owner}/{repo}/actions/permissions/workflow
gh secret list --repo {owner}/{repo}
gh variable list --repo {owner}/{repo}
gh api /repos/{owner}/{repo}/environments
gh api /repos/{owner}/{repo}/branches/main/protection

ORG="<org-slug>"
gh api "/orgs/$ORG/actions/permissions"
```

Listing secret names is safe and is what you want. `gh secret list` prints names and update times, never values, and there is no supported way to read a repository secret's value back out. If you ever find a path that does print a value, do not run it.

**If the company uses GitLab:**

```bash
ls -la .gitlab-ci.yml .gitlab/ 2>/dev/null && cat .gitlab-ci.yml
grep -nE 'image:|services:|include:|rules:|when: manual|CI_JOB_TOKEN' .gitlab-ci.yml
glab api projects/:id/variables          # masked and protected flags matter
glab api projects/:id/protected_branches
glab api projects/:id/runners
```

**Any host, static analysis of the workflow files:** `actionlint` catches syntax and shell injection patterns, and `zizmor` is a purpose built security linter for GitHub Actions workflows. Both are free and run locally. For pinning, `pinact` and `ratchet` rewrite tags to digests.

If you cannot get code host access yet, ask for it explicitly with the copy-pasteable request text in `references/02-intake-questions.md`, and log it in `ACCESS-LOG.md`.

### The walk

**Step 1. Enumerate the pipeline's identities and rank them by privilege.** Write the list into `SECURITY-STATE.md` under `M-2`. In most startups, the deploy identity outranks every human. When you show that to leadership, do it with the list, not with an adjective.

**Step 2. Kill long lived cloud keys in the pipeline.** This is the highest value control in this file and it is roughly a day of work. Instead of storing a static cloud key as a pipeline secret, the pipeline requests a short lived token from the code host and exchanges it with the cloud provider for temporary credentials. This is called OpenID Connect federation, and the walkthrough below is the only full one in this skill, so `references/06-2019-to-2026-delta.md` and `references/se-3-secrets-and-keys.md` point here rather than repeating it. Branch by cloud:
   - **Amazon Web Services:** create an identity provider for the code host, then a role with a trust policy that checks the audience claim and the subject claim. Scope the subject claim to the exact repository and the exact branch or environment, for example a subject of `repo:acme/api:ref:refs/heads/main` or `repo:acme/api:environment:production`. A wildcard on the repository is the classic mistake, because a fork or a feature branch can then assume the deploy role.
   - **Google Cloud:** Workload Identity Federation, with an attribute condition restricting the repository and reference, bound to a dedicated service account.
   - **Microsoft Azure:** a federated credential on an application registration, with subject and issuer restricted the same way.
   Creating the identity provider, the role, and the trust policy are themselves mutating changes to the cloud account, so they need an explicit human yes and an owner watching before you or anybody else applies them. After the federated path works, deactivate the old static key first, wait out a failure window of at least a week so nightly and weekly jobs have a chance to break visibly, then delete it. Deletion is a mutating action that can break deploys: **STOP and get a human yes**, and do it during business hours with the deploy owner watching.

**Step 3. Pin third party steps to digests.** A version tag is mutable. The maintainer, or anyone who steals the maintainer's account, can repoint `v4` at new code tonight and every repository consumes it on the next run. Pin to the full commit hash instead, with the readable version left in a trailing comment. Enforce with `zizmor` or a simple grep gate in the pipeline. GitHub organisations can also restrict which actions are allowed at all, which is a stronger and simpler control if the team tolerates it. On GitLab, the equivalent exposure is `include:` of remote files and container images referenced by mutable tag: pin images by digest.

**Step 4. Fix triggers that run untrusted input with secrets.** On GitHub, `pull_request_target` runs in the context of the base repository, meaning it has access to secrets, while checking out code that a stranger proposed. Combined with a checkout of the pull request head, that is remote code execution with your secrets. Ban it unless a named person reviewed the specific workflow. Same class of problem: interpolating untrusted values (branch names, pull request titles, issue bodies) directly into a shell `run:` block, which lets an attacker inject shell commands. The fix is to pass them as environment variables and quote them, never to interpolate into the script body.

**Step 5. Split build identity from deploy identity.** Build runs untrusted code. Deploy runs no untrusted code and holds the privileged credential. If the same job does both, one poisoned dependency is a production compromise. Structurally: build produces an artifact, a separate job with an environment protection rule consumes it and deploys.

**Step 6. Scope secrets and add environment protection.** Organisation wide secrets available to every repository are a lateral movement gift. Move production secrets to a protected environment that only the deploy job and only the default branch can use, with a required reviewer where the team tolerates it. On GitLab, mark variables both protected (only protected branches and tags) and masked (redacted in logs), and check that masking is actually possible for the value format.

**Step 7. Default permissions read only.** Set the pipeline's built in token to read only by default at the organisation level, then grant write per job with an explicit `permissions:` block. This is a one line change with a large blast radius reduction. It is also an organisation wide setting that will break any workflow currently relying on the implicit write, so it needs an explicit yes from whoever owns the pipeline, a scan of the workflow files for jobs that push tags, comment on pull requests, or publish packages, and the per job `permissions:` blocks landed before the default flips.

**Step 8. Self hosted runners.** If the company runs its own runners, they must be ephemeral (destroyed after each job) and must not be reachable from public repository pull requests. A persistent self hosted runner attached to a public repository is one of the most reliably exploited configurations in existence. If runners are persistent, that is a `RISK-REGISTER.md` entry with an owner today.

**Step 9. Egress and integrity monitoring on runners.** If a build step suddenly resolves a domain nobody has used before, somebody should know. Free options exist as a pipeline step that monitors runner network calls and file writes (StepSecurity Harden-Runner has a free tier for public repositories and a paid tier otherwise). If budget is zero, the fallback is logging outbound domain name system (DNS) lookups from the runner network and reviewing them weekly, which ties into `DR-2` and `DR-3`. Turning on a new log source can move a cloud bill, so check the expected volume and get a yes before enabling it.

**Step 10. Branch protection and the ways it gets bypassed.** Required reviews are routinely defeated by: administrator bypass, force push allowed, a bot account whose approvals count, allowing a pull request author to approve their own changes via a second account, and rulesets that exempt certain apps. Verify by reading the protection settings, not by asking. Then add an alert on changes to protection settings and on any pull request touching pipeline definition files. Treat pipeline files as production infrastructure, because they are.

**Step 11. Artifact integrity.** Whatever the pipeline produces should be verifiable later: signed images, build attestations, and a deployment process that refuses unsigned or unattested artifacts. Start with generating attestations, then add verification at deploy once the generation side is stable. Do not turn on enforcement first, it will break the deploy and burn political capital.

### Danger zone

- **STOP before deleting any pipeline credential.** Removing a key that a nightly job silently uses breaks the build at 2am and the team will remember it. Confirm the new path works, then delete with a named human present.
- **STOP before enabling required reviews or restricting who can merge.** These change how every engineer works. This needs the engineering lead's explicit yes, and an announcement in the channel from `DR-4`.
- **Never print a secret to a log to test whether it is set.** Test with a length check or a masked assertion.
- **Never enable "allow all actions" or loosen a restriction to unblock a build** without writing the decision and an expiry date into `DECISION-LOG.md`.
- Do not modify workflows on the default branch directly. Use a branch and a pull request, so the change itself gets reviewed by the process you are trying to establish.

### First action

Run the discovery block for the correct code host, then produce one artifact: a table of every pipeline secret with what it grants, and a yes or no on whether cloud access is federated. Bring that table to the human and propose OpenID Connect federation for the single highest privilege credential as the first change. Ask for a go or no-go.

---

## M-3 Cloud posture

### Why this exists (plain language)

Most cloud incidents at startups are not clever attacks against software. They are configuration mistakes that make data reachable: storage exposed to the public internet, a database with a public address and a weak password, a backup snapshot marked public, a role that grants everything to everyone, and long lived keys that leaked into a repository. These failures need no exploit and no lateral movement. They go straight from mistake to notification obligation.

This is also the domain where a solo security hire produces the most reduction per hour, because the failure modes are enumerable by a machine and the fixes are configuration.

### Definition of done

1. A posture scan runs at least weekly and somebody reads the diff, not the score.
2. No storage bucket or container is publicly readable unless it is deliberately a public asset host, and that exception is written down.
3. No public snapshots, images, or database instances reachable from the internet without an explicit, documented reason.
4. Zero long lived static keys for human users. Humans use single sign on, workloads use roles, pipelines use federation (see `M-2`).
5. The root or global administrator account has a hardware security key, no access keys, an alert on any use, and its recovery path is documented.
6. Organisation level guardrails prevent the worst mistakes centrally rather than fixing them per resource.
7. A one page architecture diagram exists with every data store marked, and next to each, who can read it.

### Discovery

First establish which cloud or clouds, then run the read only inventory. Never assume a provider.

**Ask for the right role, and be honest about what it reads.** The obvious read only roles are broader than their names suggest, and a security hire who asks for one while claiming it cannot touch customer data has misled the person granting it.

- **Amazon Web Services:** ask for `SecurityAudit` plus `ViewOnlyAccess`. Do **not** ask for `ReadOnlyAccess` as a shorthand for "I cannot see anything sensitive": it includes `s3:Get*` and `dynamodb:Scan`, so it grants bulk read of customer data.
- **Google Cloud:** ask for `roles/iam.securityReviewer` plus `roles/browser`, plus a service specific viewer role only where a command below needs one. Do **not** ask for `roles/viewer` on that basis: it includes `storage.objects.get`, which is bulk read of customer data.
- **Microsoft Azure:** ask for `Reader` plus `Security Reader`. `Reader` alone is genuinely control plane only and does not read blob or database contents, which makes Azure the one case where you can say that truthfully.

If the human grants you a broader role anyway because it is faster, that is their call to make, but record what you were granted and when in `ACCESS-LOG.md`, and say plainly in the same breath that it reads customer data.

```bash
# Which command line tools are even installed and authenticated
command -v aws gcloud az kubectl terraform 2>/dev/null
aws sts get-caller-identity 2>/dev/null
gcloud config list 2>/dev/null && gcloud projects list --limit=20 2>/dev/null
az account show 2>/dev/null && az account list --output table 2>/dev/null

# Infrastructure as code in the repository is often faster than the console
find . -name '*.tf' -o -name 'cdk.json' -o -name 'serverless.yml' -o -name 'main.bicep' | head -30
grep -RnE '0\.0\.0\.0/0|::/0|"\*"|allUsers|allAuthenticatedUsers|publicAccess' --include='*.tf' --include='*.yml' --include='*.yaml' --include='*.json' . | head -40
```

**Amazon Web Services, read only:**

```bash
aws organizations describe-organization
aws iam get-account-summary
aws iam list-users
aws iam list-access-keys --user-name "<user>"
aws iam generate-credential-report && aws iam get-credential-report --query Content --output text | base64 -d
aws s3api list-buckets --query 'Buckets[].Name' --output text
aws s3api get-public-access-block --bucket "<bucket>"
aws ec2 describe-snapshots --owner-ids self --restorable-by-user-ids all
aws ec2 describe-security-groups --query "SecurityGroups[?IpPermissions[?contains(IpRanges[].CidrIp, '0.0.0.0/0')]].GroupId"
aws cloudtrail describe-trails
aws accessanalyzer list-analyzers
```

**Google Cloud, read only:**

```bash
gcloud organizations list
gcloud projects get-iam-policy "<project>" --format=json
gcloud storage buckets list --format='value(name)'
gcloud storage buckets get-iam-policy "gs://<bucket>" --format=json   # look for allUsers
gcloud compute firewall-rules list --format='table(name,sourceRanges.list(),allowed[].map().firewall_rule().list())'
gcloud resource-manager org-policies list --organization="<org-id>"
gcloud logging sinks list
```

**Microsoft Azure, read only:**

```bash
az account list --output table
az role assignment list --all --include-inherited --output table
az storage account list --query "[].{name:name, publicBlob:allowBlobPublicAccess, httpsOnly:enableHttpsTrafficOnly}" --output table
az network nsg list --query "[].{name:name, rules:securityRules[?access=='Allow' && sourceAddressPrefix=='*'].name}" --output json
az policy assignment list --output table
```

**If nobody knows which cloud or nobody has access:** stop and ask. The exact closed question is in `references/02-intake-questions.md`. Mark `M-3` as `unknown`, log the access request in `ACCESS-LOG.md`, and do not guess from the repository alone.

### The walk

**Step 1. Run a free posture baseline.** A posture scanner enumerates the company's own cloud accounts through the provider's application programming interface. It is read only, but it is still a scan of a live system, so get written authorisation from whoever owns the cloud account before the first run, even though the company is your own employer, and keep that authorisation with the results. `prowler` supports Amazon Web Services, Google Cloud, Azure, and Kubernetes, is open source, and is the right first tool at zero budget: `prowler aws`, `prowler gcp`, `prowler azure`. `ScoutSuite` is a reasonable alternative. Native options: AWS Security Hub with the Foundational Security Best Practices standard, Google Security Command Center, Microsoft Defender for Cloud with Secure Score. Native ones cost money per resource but need no credentials of your own. Commercial cloud security platforms are excellent and start in the tens of thousands per year, which is usually out of reach for a first hire. Recommend free first and say why.

The first scan will return hundreds of findings and the human will feel defeated. Tell them in advance: the first run is not a to do list, it is a baseline. What matters is the weekly diff, and the six or seven findings that map to the failures listed under definition of done.

**Step 2. The prioritised first pass.** These seven are where the reduction is, and everything else waits. Investigating each one is read only and yours to do. Closing each one is a configuration change to a live system: propose it, name what could break, get an explicit yes from the person who owns that system, and record the change in `DECISION-LOG.md`. Never close one because it is obviously right.
   1. Public storage. Anything world readable that should not be.
   2. Public snapshots, machine images, and database instances reachable from the internet.
   3. Static long lived keys belonging to humans or applications, especially any that have appeared in a repository. Cross reference `SE-3`.
   4. Wildcard permissions on data stores, meaning a role that grants all actions on all resources.
   5. Root or global administrator account hygiene: hardware key, no keys, alert on use.
   6. Audit logging enabled and going somewhere retained. This feeds `DR-3`.
   7. A break glass account with a hardware key held physically, documented, monitored, and tested once.

**Step 3. Fix with guardrails, not with clicks.** Fixing one public bucket teaches nobody. Blocking public buckets at the organisation level means the mistake becomes impossible. Branch by cloud: Amazon Web Services uses Service Control Policies at the organisation or organisational unit level plus account level block public access; Google Cloud uses Organization Policy constraints, notably the one that prevents granting to public principals and the one restricting service account key creation; Azure uses Azure Policy assignments at the management group scope. Applying a policy at organisation scope is a **mutating action with wide blast radius: STOP, get an explicit yes, apply in a non production account or a dry run mode first, and record the decision in `DECISION-LOG.md`.**

**Step 4. Network defaults.** The default virtual network in every cloud is permissive. Confirm that data stores are not on public addresses, that administrative ports are not open to the whole internet, and that the default security group or firewall rule has been tightened. If everything is behind a load balancer with a private data tier, say so and move on. Do not build a network project as a first hire.

**Step 5. Draw the diagram.** One page. Boxes for services, cylinders for data stores, an arrow for every path data takes, and next to each data store the list of who and what can read it. Every enterprise questionnaire (`CO-2`) and every audit (`CO-4`) asks for this, so it pays for itself twice. If you cannot draw it, you do not understand the environment yet, and that is a `SE-2` gap.

### Danger zone

- **STOP before applying any organisation level policy.** A service control policy or org policy can deny an action the production system relies on, in every account, immediately. Test in an isolated account, announce it, then apply.
- **STOP before deleting or deactivating any access key.** Deactivate is reversible, delete is not. Prefer deactivate, wait for the failure window (a week covers most nightly jobs), then delete.
- **STOP before changing anything on the root or global administrator account.** Locking yourself out of the cloud account is a company ending mistake. Confirm the recovery path, the backup multi factor method, and who holds the physical key before touching it.
- **Do not run a remediation flag on a posture scanner.** Some tools offer auto fix. Never enable it in a company you have been at for under 90 days.
- Do not make a bucket private without asking what reads it. Public asset buckets that serve a marketing site or product images exist for a reason.

### First action

Establish which cloud provider and whether you have read only access. If you do, run the free posture baseline and report only the count of findings in the seven prioritised categories, not the full list. Propose closing the single highest one and ask for a go or no-go. If you do not have access, produce the access request text and stop.

---

## M-4 SaaS sprawl and OAuth grants

### Why this exists (plain language)

The company's most sensitive data is probably not in its own database. It is in the chat tool, the document tool, the customer relationship tool, the ticket tracker, the code host, and the data warehouse. Third party applications get connected to those tools through a consent screen where an employee clicks Authorize. That grant hands out a token that keeps working, often for years, that survives password changes and multi factor authentication, that your laptop tooling cannot see, and that most teams have never inventoried.

The 2025 case that made this concrete: attackers stole the tokens belonging to one widely installed third party integration and used them to query the customer relationship platforms of over seven hundred organisations, then searched the extracted text for cloud keys and warehouse credentials. Nobody was phished at those seven hundred companies. Their only action was clicking Authorize, sometimes years earlier.

There is a second half to this cell, which is plain sprawl: tools bought on a personal credit card, never reviewed, holding customer data, with no single sign on and no offboarding path.

This cell owns the register of third party applications and vendors, and the runbook for cutting one off. It does not own the login side. Single sign on, multi factor authentication, joiner and leaver mechanics, and who is an administrator belong to `references/cs-1-identity-and-access.md`, and you will be handing work back and forth across that line constantly.

### Definition of done

1. Every major platform (identity provider, chat, code host, customer relationship tool, data warehouse) requires administrator approval before an employee can grant a third party application access.
2. One register exists covering both third party application grants and purchased vendors, with the fields listed in step 2 below, reviewed quarterly, and it is the single source that `CO-1` publishes the subprocessor list from and that `CS-3` offboards from.
3. A revocation runbook exists per platform with the exact administrative page, tested once.
4. The register includes tools discovered from expense records, not only tools visible in the identity provider.
5. There is exactly one trigger that puts a new vendor in front of you before it holds any data, and it is wired into how the company already spends money rather than depending on anyone remembering to tell you.
6. Single sign on and automated user provisioning are a purchasing requirement for any tool that will hold customer data.
7. Offboarding covers tools that are not behind single sign on. This is the same list `CS-3` needs.

### Discovery

Branch by platform. Most of this is console work, not command line, so give the human the exact navigation path.

**Identity and email platform:**
- **Google Workspace:** Admin console, Security, Access and data control, API controls, Manage Third-Party App Access shows every application with access and lets you set the default to blocked. Reporting, Audit and investigation, Token log lists every grant event with user, application, and scopes. Export it.
- **Microsoft 365 and Entra ID:** Entra admin centre, Enterprise applications lists every application with a grant; Permissions on each application shows the scopes. Identity, Enterprise applications, Consent and permissions, User consent settings controls whether employees can consent at all. Also review the admin consent request workflow.
- **If neither, ask which identity provider is authoritative** before doing anything else. This is a `CS-1` dependency.

**Code host:**
- **GitHub:** Organisation Settings, Third-party Access, OAuth app access restrictions (turn restrictions on, then approve individually), and Settings, GitHub Apps for installed applications. Also check personal access tokens with organisation access under the organisation's Personal access tokens policy. Command line, remembering that `gh api` only substitutes `{owner}`, `{repo}`, and `{branch}` for you, so an organisation slug has to be a shell variable: `ORG=<org-slug>` then `gh api "/orgs/$ORG/installations"` lists app installations for an organisation owner.
- **GitLab:** Admin area, Applications, plus group level settings for allowed integrations and access tokens. `glab api /applications` for instance level applications if self managed.

**Chat:**
- **Slack:** Settings and administration, Manage apps, then the Settings tab to require approval for app installation, and the Installed Apps list for what already exists.
- **Microsoft Teams:** Teams admin centre, Teams apps, Permission policies and Manage apps.

**Shadow purchasing, cheapest and most effective discovery there is:**
```
Ask finance for a 12 month export of card and vendor payments, filtered to software.
Cross reference against the identity provider application list.
Everything in the finance list that is not in the identity provider list is shadow IT.
```
Do this monthly. It costs one email and finds more than most tooling. A software as a service security posture product is worth buying later, roughly five figures per year, and is not worth it at seed stage. Present the option and the price band; the purchase decision and the purchase itself are the human's.

### The walk

**Step 1. Close the front door before cleaning the house.** In each platform, switch third party application installation from open to administrator approval required. This is roughly twenty minutes of work across four consoles and it stops the problem growing while you inventory. It changes what an entire population of employees is allowed to do, so it is not yours to flip: **STOP, get an explicit yes from the platform's owner, then announce it in the company channel from `DR-4` before it takes effect**, because the next person who tries to connect a tool will file a complaint. Give them the approval request path in the same announcement.

**Step 2. Export what already has access, into one register.** There is one artifact here, not two. It is the `## Vendor and grant register` section of `SECURITY-STATE.md`, whose canonical columns are defined in `templates/README.md` (move it into its own file only if the human asks, and if you do, keep exactly one copy). One row per third party application or purchased vendor, with these columns:

| Column | What goes in it |
|--------|-----------------|
| Name | The application or vendor as the company calls it |
| Platform or purchase route | Which platform holds the grant, or "purchased, no grant" |
| Scopes or access | The raw scope strings, or the account type |
| What that actually reaches | Plain language. A scope that reads all messages in all conversations is written down as exactly that |
| Tier | 1, 2, or 3, per step 5 below |
| Data categories | Customer data, personal data, employee data, or none |
| Data processing agreement | Signed, requested, not needed, or unknown |
| Single sign on | Yes, no, or not offered |
| Subprocessor | Yes or no. This is the column `CO-1` publishes from |
| Business owner | A named person, not a team |
| Approved by | Who said yes, and the date |
| Review date | When it gets looked at again |
| Decision | Keep, reduce, or revoke |

The translation from scope string to plain language is the value you add here; nobody else in the company will do it. Two other cells consume this table directly, so it has to stay current: `CO-1` publishes the subprocessor list from the subprocessor column, and `CS-3` builds the manual offboarding list from every row where single sign on is "no". If those two are working from their own separate copies, you have three lists that will disagree within a quarter, and the failure mode `CO-1` warns about, a customer finding a vendor you never listed, becomes a certainty rather than a risk.

**Step 2a. One trigger, and who owns what.** A register with no intake point is a snapshot that starts rotting the day you finish it. Wire exactly one trigger and do not try for more: **the corporate card or accounts payable approval step notifies security before the first charge.** Whoever approves spend already sees every new tool before it is paid for, which makes finance the only reliable sensor in a startup. Ask for a standing rule that no software charge is approved without security being copied, and accept that free tiers will slip through, which is what the monthly expense cross reference above is for.

Split the accountability explicitly, in writing, so nobody thinks you are the bottleneck:

- **Finance approves the spend.** They decide whether the company pays for it.
- **Security answers two questions only**, within one working day: what tier is this, and what data may it hold. That is your entire role in the intake. You are not approving vendors.
- **The requesting manager owns the vendor** for its whole life: the business need, the named owner in the register, and telling you when it is no longer used.

The intake is five questions, and it fits in a chat message or a short form:

1. What is the tool and what will it be used for?
2. What data will it hold or be able to reach: customer data, personal data, employee data, or none?
3. Does it offer single sign on, and will we use it?
4. Who is the named owner, and who else will have accounts?
5. Will it process customer personal data on our behalf, meaning we may have to list it publicly as a subprocessor?

Answers go straight into a register row. If question 2 says customer data and question 3 says no single sign on, you have a tier 1 vendor that fails the purchasing rule in step 5, and that conversation happens before the contract is signed rather than during the next customer questionnaire.

**Step 3. Triage in three buckets.** Keep (known vendor, named owner, scopes proportionate). Reduce (needed, but the scopes are broader than the use case, so ask the vendor for narrower ones or reinstall with fewer). Revoke (nobody claims it, the vendor is defunct, or it was a personal experiment). Revocation is a mutating action that breaks whatever the tool was doing: **STOP, notify the owner if there is one, give a deadline, then revoke.**

**Step 4. Write the revocation runbook now.** For each platform, the exact page and the exact button that kills a grant, plus how long tokens take to actually stop working. Test it once on something harmless. Discovering the revoke path during an incident costs the hour that matters most. This belongs alongside the `DR-1` incident response plan.

**Step 5. Proportionate vendor review.** Do not build an enterprise vendor risk programme. Three tiers, decided by what the vendor touches:
   - **Tier 1, touches customer data or production:** requires single sign on, automated provisioning where available, a current independent audit report or a completed security questionnaire, a data processing agreement, and a named internal owner.
   - **Tier 2, touches employee or internal data:** requires single sign on and a named owner.
   - **Tier 3, touches nothing sensitive:** a line in the register, nothing more.
   Write "no single sign on, no customer data" into the purchasing policy. At seed stage that one sentence is worth more than any tool you could buy.

**Step 6. Connect this to the two cells that consume the register.** Every row where single sign on is "no" becomes a manual line item when somebody leaves, so that filtered view is the offboarding list `CS-3` needs, and it should be generated from the register rather than typed out again. Every row marked subprocessor is what `CO-1` publishes, and every change to that column is a publication decision with contractual notice periods attached, so it goes to whoever owns customer contracts before it goes on a web page. If the "no single sign on" list is long, that is the business case for consolidating onto single sign on, and it is a much better argument than an abstract one.

### Danger zone

- **STOP before revoking any grant that has no identified owner.** No owner does not mean no user. Announce a deadline in the company channel, wait, then revoke.
- **STOP before enabling administrator approval in a platform mid launch or mid quarter close.** It will block somebody's critical workflow. Time it and announce it.
- Do not remove a person's individual grants as a test. Test on an application you installed yourself.
- Do not put the grant register in a public wiki. It is a map of where data lives.
- Note that revoking a grant does not undo data already copied out. If a grant was abused, that is an incident under `DR-1`, not a cleanup task.

### First action

Pick the single platform holding the most sensitive data (usually the customer relationship tool, the code host, or the document platform, ask if unsure), pull its current third party application list, and translate the top five broadest scopes into plain language. Show the human that list. Propose switching that one platform to administrator approval required, and ask for a go or no-go.

---

## M-5 AI and LLM security

### Why this exists (plain language)

LLM stands for large language model, the kind of artificial intelligence model behind assistants and model powered product features. There are three different surfaces and teams conflate them. Separate them out loud every time, because the controls are different:

1. **The product uses a model.** Users or content reach a model that has access to data or tools. The core problem is prompt injection: text the model reads can act as instructions, and there is no reliable general fix. Treat it as an unsolved input trust problem, not a bug that gets patched.
2. **The company uses agents internally.** Assistants with tool access, connected through server integrations (the Model Context Protocol is the common standard), reading tickets, repositories, and inboxes. These have the same injection problem with less review than the product path.
3. **Engineers write code with assistants.** More code per engineer, more dependencies added without a human ever looking at the maintainer, more secrets pasted into prompts, and hallucinated package names that attackers register (see slopsquatting in `M-1`).

The single most useful test for the first surface is the lethal trifecta, as Simon Willison named it: private data access, exposure to untrusted content, and an outbound communication channel. Any two are usually survivable. All three means anyone who can put text where the system reads can cause data to leave. Most deployed agents have all three, because that combination is what makes them useful.

### Definition of done

1. An inventory exists of every model provider, every application feature that calls a model, and every internal agent or tool integration, including usage nobody approved.
2. For each, it is written down what data leaves the company, to which vendor, under which contract terms, and whether the vendor may train on it.
3. Every model integration has been assessed against the lethal trifecta, and any with all three has a documented compensating control or an accepted risk with a named accepter in `RISK-REGISTER.md`.
4. Every tool an agent can call is classified as read only or state changing, and state changing tools with real world effect require a human confirmation step.
5. Every server integration or plugin the company connects is pinned, from a known source, and re-reviewed when it changes.
6. Model provider keys are held per environment, scoped, budget limited, and rotatable, under the same regime as `SE-3`.
7. A one page acceptable use policy for artificial intelligence exists that engineers can follow without asking permission for the normal case.

### Discovery

Every command here reports file names and locations, never the contents of a credential. Two of them deliberately use `grep -l` (file names only) and exclude environment files, because the obvious `grep -n` form would print a line like `OPENAI_API_KEY=sk-proj-...` straight into your transcript, which is exactly the thing `references/00-cold-start.md` tells you never to do. Report the path and the class of the secret. Never the value.

```bash
# 1. Does the product call a model, and which provider
grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude='.env*' \
  -E 'openai|anthropic|claude|gemini|vertexai|bedrock|azure.*openai|mistral|cohere|ollama|huggingface|langchain|llamaindex|litellm' . | head -40

# 2. Which files define model provider keys. File names only, on purpose:
#    printing the matched line would put a live key in this transcript.
grep -RIl --exclude-dir=node_modules --exclude-dir=.git \
  -E '(OPENAI|ANTHROPIC|GEMINI|GOOGLE_API|AZURE_OPENAI|MISTRAL|COHERE|HF)_[A-Z_]*KEY' . | head -20
ls .env .env.* 2>/dev/null

# 3. Agent and tool integrations. Look for Model Context Protocol server configuration
grep -RIl --exclude-dir=node_modules -E 'mcpServers|modelcontextprotocol|mcp\.json' . 2>/dev/null | head -20
ls .mcp.json .cursor/mcp.json .vscode/mcp.json 2>/dev/null

# 4. Where prompts are constructed, which is where injection surface lives
grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude='.env*' \
  -E 'system_prompt|systemPrompt|messages:\s*\[|role:\s*.system' . | head -30

# 5. Assistant usage by engineers, visible in the repository
ls CLAUDE.md .cursorrules .github/copilot-instructions.md .aider* 2>/dev/null
```

If you need to know which key names a file defines rather than which files exist, read the names alone and never the values: `sed -n 's/^\([A-Z0-9_][A-Z0-9_]*\)=.*/\1/p' .env`. That prints `OPENAI_API_KEY` and stops there. Verify the output before pasting it anywhere. If a key does turn up in a committed file, that finding belongs to `references/se-3-secrets-and-keys.md`, which owns credentials exposed by a commit; come back here for the model provider specific consequences in step 7.

Shadow usage will not appear in the repository. Find it through the same finance export used in `M-4`, through the identity provider's third party application list (many assistants are OAuth applications against the document platform or code host), and by simply asking in the company channel from `DR-4`. Asking works better than scanning here, because people will tell you if you have not made it punitive.

### The walk

**Step 1. Inventory first, policy second.** Write the three surfaces into `SECURITY-STATE.md` as three separate lists. Do not write a policy before you know what people already do, because a policy that bans the current workflow gets ignored and costs you credibility.

**Step 2. Read what the contract actually says.** For each provider, determine the tier in use, whether inputs may be used for training, the retention period, whether zero retention is available, whether a data processing agreement is signed, and where processing happens geographically. Consumer tiers and business or enterprise tiers of the same product routinely differ on training and retention. This matters for `CO-4` (data inventory and privacy commitments) and it will appear in customer questionnaires (`CO-2`) within months. If an engineer is using a personal consumer account for work data, that is a finding, and the fix is to buy the team tier, not to send a scolding message.

**Step 3. Apply the trifecta test to every model integration.** For each one, answer three yes or no questions: does it have access to private data, does it process content from a source you do not control, can it send data outward (network call, email, message, tool, or even a rendered image URL). Three yeses means assume exfiltration is possible. Compensating controls, in order of usefulness: remove one leg of the trifecta (the cleanest fix by far), restrict outbound to an allowlist, strip or refuse to render remote images and links in model output, require human confirmation before any outbound action, and keep the model's data access scoped to the requesting user's own permissions rather than a service account that can read everything. Input filtering and instructing the model to ignore injections are weak controls. Say so; do not let the team treat a prompt as a security boundary.

**Step 4. Authorisation is yours, not the model's.** The most common serious flaw in a model powered feature is that the retrieval layer or the tool runs as a privileged service identity, so the model can be talked into returning another tenant's data. Enforce access control below the model, on the data layer, per request, using the calling user's identity. This is an ordinary authorisation review and it belongs in the `SE-1` design review checklist for any feature that touches a model.

**Step 5. Treat tool integrations as dependencies.** A server integration you connect to an assistant is code from a third party that can read what the assistant reads and act with its permissions. Documented failure modes include a tool description carrying hidden instructions, a server silently redefining a tool after you approved it, one server's description influencing another server's tool, and a well behaved integration that ships many clean versions to earn trust before adding an exfiltration line. Practical rules: pin versions, prefer official first party servers, review what a server can reach before connecting it, never connect an unauthenticated server exposed on a network, run them with the least data access that works, and re-review on update. This is `M-1` thinking applied to a younger ecosystem with a worse review culture.

**Step 6. Coding assistants.** Two concrete controls beat a policy document. First, secrets: assistants read the working directory, so the fix is that secrets do not live in the working directory in the first place, which is a `SE-3` control you are already building. Second, dependencies: any diff that adds a manifest entry gets the name and repository confirmed by a human, which is the `M-1` slopsquatting control. Beyond those two, review generated code the same way as any other code and do not create a separate slower process for it, because you cannot enforce it and it makes security look like an obstacle.

**Step 7. Keys and cost abuse.** Model provider keys are high value in an unusual way: they are directly monetisable, so a leaked key produces a bill rather than a breach, sometimes tens of thousands within a day. Controls: separate keys per environment and per service, spending limits and budget alerts at the provider, never a provider key in a mobile or browser client (proxy through your backend), per user rate limits on any model powered endpoint, and a billing alert that reaches a human out of hours. Fold these into the `SE-3` inventory and the `DR-2` signal list, since a sudden spend spike is one of the better cheap detections available.

**Step 8. Write the acceptable use policy people will actually follow.** One page, three lists, no legal prose.
   - **Green, use freely:** approved tools on the company account, for code, drafting, and research on non sensitive material.
   - **Yellow, allowed with a condition:** customer data, personal data, or unreleased material only in an approved tool on the business tier with training disabled, and never in a personal account.
   - **Red, ask first:** connecting an agent to production systems, giving an agent the ability to change state or spend money without confirmation, shipping a model powered feature that reads untrusted content, and pasting credentials or secrets anywhere.
   A policy tells the whole company what it may and may not do, so it is signed off by whoever actually has that authority (usually the chief technology officer or the chief executive at this size) before it goes anywhere. Once you have that yes, publish it in the internal channel from `DR-4`, include the request path for the red list, and say who to ask. It is an internal document: putting any version of it on a public page is a `CO-1` decision, not this one. If the policy bans something everybody is already doing productively, you will be routed around and you will not know it.

### Danger zone

- **STOP before revoking a model provider key or cutting off an assistant everyone uses.** You will halt engineering and you will be the person who did it. Provide the sanctioned path first.
- **STOP before enabling a company wide block on assistant tools.** It moves usage to personal accounts and personal devices, which is strictly worse and now invisible.
- Never test prompt injection against a production system holding customer data. Use a test tenant with synthetic data and get written approval before any adversarial testing.
- Never paste real customer data into a model to demonstrate a vulnerability. Synthesise it.
- Do not let the team accept "we told the model not to do that" as a control. Record it as an accepted risk with a named accepter in `RISK-REGISTER.md` if leadership wants to ship anyway, but do not call it a control.

### First action

Ask one closed question: "Does our product send any customer data to a model provider today, yes or no." If yes, inventory that path first and apply the trifecta test to it. If no, inventory internal assistant usage instead, because that is where the exposure is. Report the single highest exposure you found and propose one fix. Ask for a go or no-go.

---

## Recording and cross references

After working any cell in this file:

- Update `SECURITY-STATE.md` under the `### Modern cells` subsection of `## Grid state` with the cell identifier, a status of `unknown`, `none`, `partial`, `done`, or `n/a`, and the evidence (the command output, the console screenshot the human confirmed, or the artifact path). Never mark `done` without evidence.
- Add any unresolved exposure to `RISK-REGISTER.md` with a severity, a named owner, a decision, and who accepted it if it was accepted.
- Record every configuration change, every waiver, and every deliberate deviation in `DECISION-LOG.md` with the date, the reasoning, and the approver.
- Record access you needed and did not have in `ACCESS-LOG.md`, along with the exact request you sent.
- Regenerate the relevant week of `90-DAY-PLAN.md` if a discovery changed the ordering, and say out loud what moved and why.
- If you interrupt a cell partway through, push the state onto `CONTEXT-STACK.md` per `references/04-interrupts.md` before switching.

Related files, with the boundary stated so you do not work the same finding twice:

- `references/06-2019-to-2026-delta.md` for why these cells exist at all.
- `references/03-90-day-plan.md` for where work from here lands in the gates.
- `references/m-6-backups-and-recovery.md` for `M-6`, which is a cell of this set but has its own file.
- `references/se-3-secrets-and-keys.md` for the credential inventory that `M-1`, `M-2`, and `M-5` all depend on. **Boundary:** a credential exposed by a commit is `SE-3`. A credential exposed by a dependency or by a build step is this file, `M-1` or `M-2`. Rotation mechanics are `SE-3` either way.
- `references/cs-1-identity-and-access.md` for the identity foundation `M-4` sits on. **Boundary:** `CS-1` owns the login side, meaning single sign on, multi factor authentication, administrators, and joiner and leaver mechanics. `M-4` owns the third party grant register and the revocation runbook, meaning what a connected application can reach after somebody clicked Authorize.
- `references/dr-1-incident-response-plan.md` for the plan the `M-1` malicious dependency runbook plugs into.
- `references/co-4-data-inventory-and-framework.md` for where model provider data flows get recorded, and `references/co-1-public-security-docs.md` for the subprocessor list published from the `M-4` register.
