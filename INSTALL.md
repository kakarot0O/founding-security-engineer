# Install

This pack is portable by design. It is a plain directory of markdown plus one shell script. Nothing in it is tied to a machine, a company, a cloud, or a stack. Take it to whatever company you land at next.

Four ways to install, from most to least integrated.

---

## 1. Clone and run the installer (recommended)

Works on macOS, Linux, and WSL. Requires only bash, git, and Claude Code.

```bash
git clone <your-repo-url> founding-security-engineer
cd founding-security-engineer
./install.sh
```

That symlinks two things into `~/.claude`:

| Source in the pack | Installed to |
|---|---|
| `skills/founding-security-engineer/` | `~/.claude/skills/founding-security-engineer` |
| `agents/security-recon.md` | `~/.claude/agents/security-recon.md` |

Because it symlinks, `git pull` updates your install with no reinstall step.

**Options**

```bash
./install.sh --copy               # copy instead of symlink (for machines where the repo will not stay put)
./install.sh --prefix /path/.claude   # install somewhere other than ~/.claude
./install.sh --check              # report what is currently installed
./install.sh --uninstall          # remove it; your .security/ program state is never touched
CLAUDE_HOME=/opt/claude ./install.sh  # same as --prefix, via environment
```

The installer backs up anything already at the destination to `<name>.bak.<timestamp>` rather than overwriting it, and verifies the reference playbooks are reachable before declaring success.

---

## 2. As a Claude Code plugin

The pack ships `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, so it can be installed through the plugin system instead of the shell script. Push the repo somewhere reachable, then in Claude Code:

```
/plugin marketplace add <your-repo-url>
/plugin install founding-security-engineer
```

This is the right path if you want to hand it to a team rather than to one laptop, or if you want version pinning.

---

## 3. Manual copy (no git, no shell, locked-down machine)

Copy two things by hand:

```
skills/founding-security-engineer/   ->  ~/.claude/skills/founding-security-engineer/
agents/security-recon.md             ->  ~/.claude/agents/security-recon.md
```

On Windows without WSL the Claude home is typically `%USERPROFILE%\.claude`.

Verify by starting Claude Code anywhere and running `/founding-security-engineer`. If the skill does not appear, the skill directory is in the wrong place or `SKILL.md` is missing from it.

---

## 4. No Claude Code at all

Some companies will not let you install anything. Use `portable/SYSTEM-PROMPT.md`.

It is a single self-contained block you can paste as a system prompt, as custom instructions, as a project instruction, or simply as the first message of a chat in whatever assistant you are allowed to use. It carries the behaviour, the framework, the sequencing, the cold-start protocol, the interrupt protocol, and the stop conditions.

It is lossier than the full pack: you lose the 24 detailed playbooks with their commands, templates, and decision trees. It is still a usable program spine, and it reads fine as a plain human runbook with no model involved at all.

---

## Multiple companies on one machine

The install is global; the program state is not. State lives with the work:

- `./.security/` in whatever directory you launch from, if that directory is a repo
- `~/security-program/<org-slug>/` if there is no repo

So a consultant, or anyone who changes jobs, gets one install and as many independent programs as they have clients or employers. The partner asks which one it is working on when the answer is ambiguous.

---

## What gets written where

| Path | What | Written when |
|---|---|---|
| `~/.claude/skills/founding-security-engineer/` | The skill and its playbooks | Install only |
| `~/.claude/agents/security-recon.md` | The read-only recon worker | Install only |
| `./.security/` or `~/security-program/<org>/` | Your program state | During work, after asking you on first run |

Nothing is written anywhere else. The partner is instructed to stop and ask before touching anything outside those paths, and before any action against a live system.

---

## Uninstall

```bash
./install.sh --uninstall
```

Removes the skill and the agent. Deliberately does not touch `.security/` or `~/security-program/`, because that is your work, not the tool's.
