#!/usr/bin/env bash
set -u

fail=0

ok()   { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
bad()  { printf '[FAIL] %s\n' "$*"; fail=1; }

section() {
  printf '\n== %s ==\n' "$*"
}

section "git hygiene"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "inside git repo"
else
  bad "not inside git repo"
fi

if [ -z "$(git status --short 2>/dev/null)" ]; then
  ok "working tree clean"
else
  warn "working tree has changes"
  git status --short
fi

tracked_venv_count="$(git ls-files .venv 2>/dev/null | wc -l | tr -d ' ')"
if [ "$tracked_venv_count" = "0" ]; then
  ok ".venv not tracked"
else
  bad ".venv tracked files: $tracked_venv_count"
fi

if git check-ignore -q .venv 2>/dev/null; then
  ok ".venv ignored"
else
  warn ".venv is not ignored"
fi

section "required environment"

: "${OPLOG:="$HOME/.oplog"}"
: "${OPSCRATCH:="$HOME/.scratch"}"
: "${OPPARK:="$HOME/.parked"}"

mkdir -p "$(dirname "$OPLOG")" "$OPSCRATCH" "$OPPARK" 2>/dev/null || bad "could not create core paths"
touch "$OPLOG" 2>/dev/null || bad "could not touch OPLOG: $OPLOG"

[ -f "$OPLOG" ] && ok "OPLOG file exists: $OPLOG" || bad "OPLOG missing: $OPLOG"
[ -d "$OPSCRATCH" ] && ok "OPSCRATCH dir exists: $OPSCRATCH" || bad "OPSCRATCH missing: $OPSCRATCH"
[ -d "$OPPARK" ] && ok "OPPARK dir exists: $OPPARK" || bad "OPPARK missing: $OPPARK"

section "required functions"

for fn in emit session_start operator_ctx; do
  if declare -F "$fn" >/dev/null; then
    ok "function exists: $fn"
  else
    bad "function missing: $fn"
  fi
done

section "required aliases"

for al in oplog; do
  if alias "$al" >/dev/null 2>&1; then
    ok "alias exists: $al"
  else
    warn "alias missing: $al"
  fi
done

section "counts"

alias_count="$(alias | wc -l | tr -d ' ')"
func_count="$(declare -F | wc -l | tr -d ' ')"

printf 'aliases=%s\n' "$alias_count"
printf 'functions=%s\n' "$func_count"

if [ "$alias_count" -ge 150 ]; then
  ok "alias count looks healthy"
else
  warn "alias count lower than expected"
fi

if [ "$func_count" -ge 120 ]; then
  ok "function count looks healthy"
else
  warn "function count lower than expected"
fi

section "stdlib shadow files"

shadow_names='shlex threading json logging pathlib subprocess socket asyncio sqlite3 re os sys tempfile glob fnmatch'
for name in $shadow_names; do
  if [ -e "$name" ]; then
    bad "repo root shadows stdlib/module name: $name"
  fi
done

section "dangerous shell patterns"

scan_paths="aliases shell tools tests"
patterns='rm -rf|sudo |curl .*sh|wget .*sh|chmod 777|eval '
matches="$(grep -RInE "$patterns" $scan_paths 2>/dev/null || true)"

if [ -n "$matches" ]; then
  warn "potential dangerous patterns found"
  printf '%s\n' "$matches" | head -80
else
  ok "no obvious dangerous patterns found"
fi

section "event logging"

doctor_id="doctor_$(date +%s)"
if declare -F emit >/dev/null; then
  emit doctor_check "$doctor_id"
  if tail -20 "$OPLOG" | grep -q "$doctor_id"; then
    ok "emit wrote to OPLOG"
  else
    bad "emit did not appear in OPLOG"
  fi
else
  bad "cannot test emit; function missing"
fi

section "session context"

if declare -F session_start >/dev/null && declare -F operator_ctx >/dev/null; then
  session_start >/dev/null
  ctx="$(operator_ctx)"
  case "$ctx" in
    "[$SESSION_ID]") ok "operator_ctx matches SESSION_ID: $ctx" ;;
    *) bad "operator_ctx mismatch: ctx=$ctx SESSION_ID=${SESSION_ID:-unset}" ;;
  esac
fi

section "summary"

if [ "$fail" -eq 0 ]; then
  ok "aliasOS doctor passed"
else
  bad "aliasOS doctor found failures"
fi

exit "$fail"
