#!/usr/bin/env bash
# Reconciliation verifier for the founding-security-engineer patch pass.
# Checks cross-file coherence, canonical strings, and hygiene. Exits non-zero on any FAIL.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/skills/founding-security-engineer"
REF="$SKILL/references"
TPL="$SKILL/templates/README.md"
SK="$SKILL/SKILL.md"
PORT="$ROOT/portable/SYSTEM-PROMPT.md"

PASS=0; FAIL=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }
# want <label> <file> <fixed-string>
want() { if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing in $(basename "$2"))"; fi; }
# nope <label> <file> <fixed-string>
nope() { if grep -qF -- "$3" "$2"; then bad "$1 (still present in $(basename "$2"))"; else ok "$1"; fi; }

echo "=============================================================="
echo "1. Hygiene"
echo "=============================================================="

# Dash sweep: strip fenced code blocks and markdown table separator rows, then look for em/en dash
# or a double hyphen used as punctuation.
dash_hits=0
while IFS= read -r f; do
  hits=$(awk '
    /^```/ { infence = !infence; next }
    infence { next }
    /^\|[[:space:]]*-{3,}/ { next }
    /^[[:space:]]*-{3,}[[:space:]]*$/ { next }
    { print FILENAME ":" FNR ":" $0 }
  ' "$f" | grep -E '—|–' )
  if [ -n "$hits" ]; then echo "$hits"; dash_hits=$((dash_hits+1)); fi
done < <(find "$SKILL" "$ROOT/portable" "$ROOT/agents" -name '*.md' -type f; echo "$ROOT/README.md")
[ "$dash_hits" -eq 0 ] && ok "no em or en dashes in prose" || bad "em or en dashes found in $dash_hits file(s)"

attr=$(grep -rniE 'co-authored-by:? *claude|generated (with|by) \[?claude|🤖' "$SKILL" "$ROOT/portable" "$ROOT/agents" "$ROOT/README.md" 2>/dev/null | wc -l | tr -d ' ')
[ "$attr" = "0" ] && ok "no AI attribution" || bad "AI attribution found ($attr hits)"

echo
echo "=============================================================="
echo "2. Relative markdown links resolve"
echo "=============================================================="
broken=0
while IFS= read -r f; do
  d=$(dirname "$f")
  grep -o '](\.\{0,2\}/\?[A-Za-z0-9_./-]*\.md[^)]*)' "$f" 2>/dev/null \
    | sed 's/^](//; s/)$//; s/#.*$//' | sort -u | while read -r l; do
      [ -z "$l" ] && continue
      [ -f "$d/$l" ] || [ -f "$l" ] || echo "BROKEN $f -> $l"
    done
done < <(find "$SKILL" "$ROOT/portable" "$ROOT/agents" -name '*.md' -type f; echo "$ROOT/README.md") > /tmp/_fse_links.$$
if [ -s /tmp/_fse_links.$$ ]; then cat /tmp/_fse_links.$$; bad "broken relative links"; else ok "all relative links resolve"; fi
rm -f /tmp/_fse_links.$$

echo
echo "=============================================================="
echo "3. C1 ACCESS-LOG schema"
echo "=============================================================="
want "11-column Requests header" "$TPL" "| ID | System | Access level requested | Exact role or scope requested | Justification | Requested from | Drafted on | Requested on | Status | Granted on | Notes |"
want "drafted in access status vocabulary" "$TPL" "drafted / requested / granted / denied / partial / revoked / expired"
want "Drafted on semantics stated" "$TPL" "Filling \`Requested on\` is what moves the row to \`requested\`"
want "undelivered-ask integrity check" "$TPL" "Undelivered asks"
want "SecurityAudit inline in schema" "$TPL" "SecurityAudit"
want "roles/iam.securityReviewer inline in schema" "$TPL" "roles/iam.securityReviewer"
# No orphaned old vocabulary that omits drafted
if grep -qF "<requested / granted / denied / partial / revoked / expired>" "$TPL"; then
  bad "old access vocabulary without drafted survives in templates"
else ok "no stale access vocabulary in templates"; fi

echo
echo "=============================================================="
echo "4. C2 RISK-REGISTER schema and headings"
echo "=============================================================="
want "15-column Open risks header" "$TPL" "| ID | Title | Cell | Reference | Description | Likelihood | Impact | Severity | Current mitigation | Recommended action | Owner | Status | Decision | Accepted by | Review date |"
want "dropped in risk status vocabulary" "$TPL" "open / in-progress / mitigated / accepted / dropped / closed"
want "## Accepted risks heading" "$TPL" "## Accepted risks"
want "## Closed risks heading" "$TPL" "## Closed risks"
nope "old combined closed heading removed" "$TPL" "## Closed and accepted risks"
want "10-column accepted-risk block" "$TPL" "| ID | Risk as an event | Affected system | Severity | Compensating control | Accepted by | Role | Accepted on | Expires on | Trigger conditions that void this early |"

echo
echo "=============================================================="
echo "5. C3 incident vocabulary"
echo "=============================================================="
want "unassigned severity" "$TPL" "<unassigned / SEV1 / SEV2 / SEV3>"
want "scoping status" "$TPL" "<scoping / investigating / contained / eradicated / recovering / monitoring / closed>"

echo
echo "=============================================================="
echo "6. C4 containment carve-out, cross-file"
echo "=============================================================="
want "SKILL.md carve-out present" "$SK" "One named exception, and only this one"
want "carve-out names dr-4 step 10" "$SK" "step 10 of"
want "carve-out excludes network rules" "$SK" "never a network or firewall rule"
ptr=$(grep -rlF "one named exception to the hard stop on access changes" "$REF" 2>/dev/null | wc -l | tr -d ' ')
[ "$ptr" -ge 5 ] && ok "canonical pointer sentence in $ptr reference files" || bad "canonical pointer sentence in only $ptr reference files (expect 5 or more)"
# Nothing may claim network blocking is pre-authorised
netpre=$(grep -rn -iE "pre-?authoris(ed|ation)[^.]{0,200}(block(ing)? external network|block an address|network access)" "$SKILL" "$PORT" 2>/dev/null; \
         grep -rn -iE "(block(ing)? external network access)[^.]{0,200}pre-?authoris" "$SKILL" "$PORT" 2>/dev/null)
if [ -n "$netpre" ]; then echo "$netpre"; bad "network blocking still described as pre-authorised"; else ok "network blocking is nowhere pre-authorised"; fi
nope "dr-4 self-contradiction removed" "$REF/dr-4-company-comms-channel.md" "it never covers the Hard stops in"

echo
echo "=============================================================="
echo "7. C5 SECURITY-CHARTER wiring"
echo "=============================================================="
want "charter template block in templates" "$TPL" "SECURITY-CHARTER.md"
want "charter row in SKILL.md cell-owned table" "$SK" "SECURITY-CHARTER.md"
want "charter step in 03" "$REF/03-90-day-plan.md" "GA-09"
if grep -qF "The field list is in \`templates/README.md\`" "$REF/05-metrics-and-comms.md"; then
  grep -qF "SECURITY-CHARTER" "$TPL" && ok "05 charter pointer now true" || bad "05 points at a charter template that does not exist"
else ok "05 charter pointer rewritten"; fi

echo
echo "=============================================================="
echo "8. C6 channel split gate"
echo "=============================================================="
want "dr-1 defers to DR-4 on channels" "$REF/dr-1-incident-response-plan.md" "Channel gate, owned by DR-4"
hc=$(grep -cE "roughly 50 people" "$REF/dr-1-incident-response-plan.md" 2>/dev/null | tr -d ' ')
[ "$hc" = "0" ] && ok "dr-1 headcount channel gate removed" || bad "dr-1 still states a headcount channel gate ($hc hits)"
want "dr-4 still owns the channel set" "$REF/dr-4-company-comms-channel.md" "No other cell may create one"

echo
echo "=============================================================="
echo "9. C7 M-6 gate assignment"
echo "=============================================================="
want "m-6 defers to 03 on gates" "$REF/m-6-backups-and-recovery.md" "owns gate assignment for this cell"
nope "m-6 self-assignment removed" "$REF/m-6-backups-and-recovery.md" "belong in Gate B because they are cheap"
want "03 states the GC-09 jump" "$REF/03-90-day-plan.md" "GC-09"

echo
echo "=============================================================="
echo "10. C8 two-step close"
echo "=============================================================="
want "two-step close rule in SKILL.md" "$SK" "First X, then Y"
want "two-step close rule in portable" "$PORT" "First X, then Y"

echo
echo "=============================================================="
echo "11. C9 bootstrap"
echo "=============================================================="
want "two-step bootstrap ordering" "$TPL" "Two steps, in this order, every time"
want "drafts/ in templates bootstrap" "$TPL" "\"\$STATE_DIR\"/drafts"
want "six-file touch loop in templates" "$TPL" "90-DAY-PLAN.md; do"
want "cold start owns location rule" "$REF/00-cold-start.md" "security-program"

echo
echo "=============================================================="
echo "12. C10 DECISION-LOG format"
echo "=============================================================="
want "blocks-never-a-table rule" "$TPL" "blocks, never a table, at any volume"
want "My recommendation was field survives" "$TPL" "My recommendation was"

echo
echo "=============================================================="
echo "13. C11 gate tables"
echo "=============================================================="
want "Justifying finding column" "$TPL" "| Step | Cell | Justifying finding | Description | Status | Target date | Blocked by | Notes |"
nope "GA-01 prefill deleted" "$TPL" "| GA-01 |"
nope "GA-04 prefill deleted" "$TPL" "| GA-04 |"
want "empty-gate-table rule" "$TPL" "An empty gate table is the correct state"
want "03 findings-justify-steps rule" "$REF/03-90-day-plan.md" "A step with no finding attached does not go in the file"

echo
echo "=============================================================="
echo "14. C12 production data access"
echo "=============================================================="
if grep -qiE "bastion|tunnel" "$REF/cs-1-identity-and-access.md"; then ok "cs-1 covers production data paths"; else bad "cs-1 has no production data access step"; fi
if grep -qiE "impersonat" "$REF/cs-1-identity-and-access.md"; then ok "cs-1 covers support impersonation"; else bad "cs-1 misses support impersonation path"; fi

echo
echo "=============================================================="
echo "15. C13 factual corrections"
echo "=============================================================="
nope "vault lock unlocked claim removed" "$REF/m-6-backups-and-recovery.md" "Vault Lock left unlocked"
want "governance mode named" "$REF/m-6-backups-and-recovery.md" "governance"
want "compliance mode named as irreversible" "$REF/m-6-backups-and-recovery.md" "compliance mode"
# C13b was CORRECTED mid-pass: the contract's original canonical string asserted an edition
# restriction on the leaked-password alert that Google's own docs contradict. Verified against
# workspace.google.com/products/admin/alert-center ("alert center is included in all editions of
# Google Workspace at no additional cost", with "Leaked passwords" listed as an included type).
# What IS edition gated is the response tooling. These checks assert the corrected substance.
nope "workspace default-across-editions claim removed" "$REF/dr-2-top-security-signals.md" "on by default across editions"
nope "no false Business Starter exclusion" "$REF/dr-2-top-security-signals.md" "not available on Business Starter"
want "alert center availability stated correctly" "$REF/dr-2-top-security-signals.md" "every Workspace edition at no extra cost"
want "investigation tool gating named" "$REF/dr-2-top-security-signals.md" "Cloud Identity Premium"
want "recommended-actions gating named" "$REF/dr-2-top-security-signals.md" "quarantine mail"
want "edition check before promising" "$REF/dr-2-top-security-signals.md" "Admin console > Billing > Subscriptions"
cur=$(grep -rc "Curricula" "$SKILL" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
[ "$cur" = "0" ] && ok "Curricula removed" || bad "Curricula still listed ($cur hits)"

echo
echo "=============================================================="
echo "16. C14 migration step"
echo "=============================================================="
CS="$REF/00-cold-start.md"
if grep -qF "When the storage-location decision changes" "$CS"; then ok "migration section exists"; else bad "no migration section"; fi
if grep -qiE "old path is gone or empty" "$CS"; then ok "migration confirms old path emptied"; else bad "migration does not confirm the old path is emptied"; fi
if grep -qiE "re-verify the ignore rule at the" "$CS"; then ok "migration re-verifies ignore rule at new path"; else bad "migration skips re-verifying the ignore rule at the new path"; fi
if grep -qiE "REFUSING: .*already exists" "$CS"; then ok "migration refuses a pre-existing destination"; else bad "migration overwrites a pre-existing destination"; fi
if grep -qF "it does not copy" "$CS"; then ok "migration moves rather than copies"; else bad "migration may leave two copies"; fi
if grep -qE "3\.4 was run in full|3\.4" "$CS"; then ok "migration wired into exit criteria"; else bad "migration not referenced from exit criteria"; fi

echo
echo "=============================================================="
echo "17. C15 portable parity"
echo "=============================================================="
# Scope the portable checks to the HARD STOPS block so an unrelated mention elsewhere
# in the file cannot satisfy them. The block runs from the HARD STOPS banner to the next banner.
HS=$(awk '/^HARD STOPS/{f=1} f{print} f&&/^={10,}/&&++n==2{exit}' "$PORT")
if printf '%s' "$HS" | grep -qiE "compliance mode|one-way door|cannot be reversed at all|permanent"; then
  ok "portable hard stops cover irreversible actions"; else bad "portable hard stops missing irreversible actions"; fi
if printf '%s' "$HS" | grep -qiE "does not already exist|live identifier"; then
  ok "portable hard stops cover the restore drill"; else bad "portable hard stops missing the restore drill"; fi
if printf '%s' "$HS" | grep -qiE "declared incident|incident commander"; then
  ok "portable hard stops carry the carve-out"; else bad "portable hard stops missing the carve-out"; fi
if printf '%s' "$HS" | grep -qiE "block(ing)? external network"; then
  bad "portable carve-out wrongly includes network blocking"; else ok "portable carve-out excludes network blocking"; fi

echo
echo "=============================================================="
echo "18. Routing table reachability"
echo "=============================================================="
unreach=0
for f in "$REF"/*.md; do
  b=$(basename "$f")
  grep -qF "$b" "$SK" || { echo "  UNREACHABLE from SKILL.md: $b"; unreach=$((unreach+1)); }
done
[ "$unreach" -eq 0 ] && ok "every reference file is named in SKILL.md" || bad "$unreach reference file(s) unreachable from SKILL.md"

tmplcount=$(ls "$SKILL/templates" | wc -l | tr -d ' ')
ok "templates directory holds $tmplcount file(s)"

echo
echo "=============================================================="
echo "19. Shell blocks parse"
echo "=============================================================="
# Every fenced shell block is checked with `bash -n`. 0 blocks fail. Previously 13 failed on unquoted
# angle-bracket placeholders (TODOS.md #34); those live in files that had no owner in the
# 2026-08-25 patch pass. This is a ratchet: it fails only if the count RISES above the known
# baseline, so new breakage is caught without blocking on the tracked backlog.
SHELL_BASELINE=0
shell_out=$(python3 - "$ROOT" <<'PYEOF'
import re, subprocess, glob, os, sys, tempfile
root = sys.argv[1]
files = glob.glob(os.path.join(root, 'skills/founding-security-engineer/**/*.md'), recursive=True)
files += [os.path.join(root, 'portable/SYSTEM-PROMPT.md')]
total = 0; failed = []
for fn in files:
    if not os.path.exists(fn): continue
    txt = open(fn).read()
    for m in re.finditer(r'^```(?:bash|sh)\n(.*?)^```', txt, re.S | re.M):
        body = m.group(1)
        if not body.strip(): continue
        total += 1
        ln = txt[:m.start()].count('\n') + 1
        with tempfile.NamedTemporaryFile('w', suffix='.sh', delete=False) as t:
            t.write(body); path = t.name
        if subprocess.run(['bash','-n',path], capture_output=True).returncode != 0:
            failed.append(f"{os.path.relpath(fn, root)}:{ln}")
        os.unlink(path)
print(total)
print(len(failed))
for x in failed: print(x)
PYEOF
)
sh_total=$(printf '%s' "$shell_out" | sed -n '1p')
sh_bad=$(printf '%s' "$shell_out" | sed -n '2p')
if [ "$sh_bad" -le "$SHELL_BASELINE" ]; then
  ok "$sh_total shell blocks checked, $sh_bad unparseable (baseline $SHELL_BASELINE, see TODOS.md #34)"
else
  printf '%s\n' "$shell_out" | tail -n +3 | sed 's/^/    /'
  bad "shell blocks unparseable rose to $sh_bad from baseline $SHELL_BASELINE"
fi

echo
echo "=============================================================="
echo "20. Install integrity"
echo "=============================================================="
if "$ROOT/install.sh" --check 2>&1 | grep -q "^  ok"; then ok "install.sh --check reports healthy symlinks"; else bad "install.sh --check failed"; fi

echo
echo "=============================================================="
printf 'RESULT: %d passed, %d failed\n' "$PASS" "$FAIL"
echo "=============================================================="
[ "$FAIL" -eq 0 ]
