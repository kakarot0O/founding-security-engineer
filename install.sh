#!/usr/bin/env bash
#
# Founding Security Engineer: installer.
#
# Installs the founding-security-engineer skill and the security-recon agent
# into a Claude Code home directory on any machine (macOS, Linux, WSL).
#
# Usage:
#   ./install.sh                 symlink into ~/.claude (default, recommended: git pull updates it)
#   ./install.sh --copy          copy instead of symlink (for machines where the repo will not stay put)
#   ./install.sh --prefix DIR    install into DIR instead of ~/.claude
#   ./install.sh --uninstall     remove what this installer put there
#   ./install.sh --check         report what is installed and exit
#
# Environment:
#   CLAUDE_HOME    overrides the install prefix (default: $HOME/.claude)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${CLAUDE_HOME:-$HOME/.claude}"
MODE="link"

SKILL_NAME="founding-security-engineer"
AGENT_FILE="security-recon.md"

SRC_SKILL="$SCRIPT_DIR/skills/$SKILL_NAME"
SRC_AGENT="$SCRIPT_DIR/agents/$AGENT_FILE"

# ---------- output helpers ----------

if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  BOLD=""; RED=""; GRN=""; YLW=""; DIM=""; RST=""
fi

info() { printf '%s\n' "  $*"; }
ok()   { printf '%s\n' "  ${GRN}ok${RST}    $*"; }
warn() { printf '%s\n' "  ${YLW}warn${RST}  $*"; }
die()  { printf '%s\n' "  ${RED}error${RST} $*" >&2; exit 1; }
head1(){ printf '\n%s\n' "${BOLD}$*${RST}"; }

# ---------- arguments ----------

while [ $# -gt 0 ]; do
  case "$1" in
    --copy)      MODE="copy"; shift ;;
    --link)      MODE="link"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --check)     MODE="check"; shift ;;
    --prefix)    [ $# -ge 2 ] || die "--prefix needs a directory"; PREFIX="$2"; shift 2 ;;
    -h|--help)   awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"; exit 0 ;;
    *)           die "unknown argument: $1 (try --help)" ;;
  esac
done

DST_SKILL="$PREFIX/skills/$SKILL_NAME"
DST_AGENT="$PREFIX/agents/$AGENT_FILE"

# ---------- checks ----------

check_state() {
  head1 "Installed state"
  info "prefix: $PREFIX"
  for target in "$DST_SKILL" "$DST_AGENT"; do
    if [ -L "$target" ]; then
      ok "$target -> $(readlink "$target")"
    elif [ -e "$target" ]; then
      ok "$target (copied)"
    else
      warn "$target (not installed)"
    fi
  done
}

if [ "$MODE" = "check" ]; then
  check_state
  exit 0
fi

# ---------- uninstall ----------

remove_target() {
  target="$1"
  if [ -L "$target" ]; then
    rm -- "$target"
    ok "removed symlink $target"
  elif [ -e "$target" ]; then
    rm -rf -- "$target"
    ok "removed $target"
  else
    info "nothing at $target"
  fi
}

if [ "$MODE" = "uninstall" ]; then
  head1 "Uninstalling founding-security-engineer"
  remove_target "$DST_SKILL"
  remove_target "$DST_AGENT"
  printf '\n%s\n' "  Done. Your program state under .security/ and ~/security-program/ was NOT touched."
  exit 0
fi

# ---------- install ----------

[ -d "$SRC_SKILL" ] || die "source skill not found at $SRC_SKILL (are you running this from the repo root?)"
[ -f "$SRC_SKILL/SKILL.md" ] || die "$SRC_SKILL/SKILL.md is missing; the pack looks incomplete"
[ -f "$SRC_AGENT" ] || die "source agent not found at $SRC_AGENT"

head1 "Installing founding-security-engineer"
info "source: $SCRIPT_DIR"
info "prefix: $PREFIX"
info "mode:   $MODE"

mkdir -p "$PREFIX/skills" "$PREFIX/agents"

# Backups go to a dedicated directory, never alongside the target. A stale copy left
# inside skills/ or agents/ is discovered as a second, duplicate skill or agent.
BACKUP_DIR="$PREFIX/.founding-security-engineer-backups"

backup_if_needed() {
  target="$1"
  if [ -L "$target" ]; then
    # An existing symlink is ours to replace; no data lives inside it.
    rm -- "$target"
    return
  fi
  if [ -e "$target" ]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    dest="$BACKUP_DIR/$(basename "$target").bak.$stamp"
    mv -- "$target" "$dest"
    warn "existing $target moved to $dest"
    warn "it is outside skills/ and agents/ on purpose, so it is not loaded as a duplicate"
  fi
}

install_one() {
  src="$1"; dst="$2"
  backup_if_needed "$dst"
  if [ "$MODE" = "link" ]; then
    ln -s -- "$src" "$dst"
    ok "linked $dst"
  else
    if [ -d "$src" ]; then
      cp -R -- "$src" "$dst"
    else
      cp -- "$src" "$dst"
    fi
    ok "copied $dst"
  fi
}

install_one "$SRC_SKILL" "$DST_SKILL"
install_one "$SRC_AGENT" "$DST_AGENT"

# ---------- verify ----------

head1 "Verifying"

fail=0
[ -f "$DST_SKILL/SKILL.md" ] || { warn "SKILL.md not reachable at $DST_SKILL/SKILL.md"; fail=1; }
[ -f "$DST_AGENT" ] || { warn "agent not reachable at $DST_AGENT"; fail=1; }

ref_count=0
if [ -d "$DST_SKILL/references" ]; then
  ref_count="$(find "$DST_SKILL/references" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
fi
if [ "$ref_count" -lt 20 ]; then
  warn "only $ref_count reference files found under $DST_SKILL/references (expected 24)"
  fail=1
else
  ok "$ref_count reference playbooks reachable"
fi

[ "$fail" -eq 0 ] || die "install completed with warnings above; the skill may not work correctly"

ok "install verified"

# ---------- next steps ----------

cat <<'NEXT'

  Next steps

    1. cd into whatever you want to secure. A repo, an infrastructure repo,
       or an empty directory if you have nothing yet.

         cd ~/work/acme

    2. Start Claude Code and invoke the partner:

         claude
         /founding-security-engineer

    3. Tell it where you are. Plain language is fine:

         I started Monday as the first security hire. 40 people, mostly remote.
         I have a laptop and a work email. That is all I have so far.

  It keeps program state in ./.security/ in whatever directory you launch from,
  or in ~/security-program/<org>/ when there is no repo. Nothing is written
  outside those two places without asking you first.

  To update later:   git pull   (symlink installs pick it up immediately)
  To remove:         ./install.sh --uninstall
  To inspect:        ./install.sh --check

NEXT
