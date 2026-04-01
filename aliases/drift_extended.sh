#!/usr/bin/env bash
# ── drift_orchestrator extended ──────────────────────────────────────────────

# core nav (already exists: driftcd, driftlog, driftsess)
alias driftv='drift verify'
alias driftsnap='drift snapshot'
alias driftrpt='drift report'
alias driftreset='drift reset'
alias driftdiff='drift diff'
alias driftwatch='watch -n 5 "drift status 2>/dev/null"'
alias driftstatus='drift status'
alias driftinit='drift init'
alias driftrun='drift run'
alias driftclean='drift clean'

# session management
alias dsn='drift sessions new'
alias dsl='drift sessions ls'
alias dss='drift sessions status'
alias dse='drift sessions export'
alias dsc='drift sessions close'

# verification
alias dvcheck='drift verify --check'
alias dvfull='drift verify --full'
alias dvquick='drift verify --quick'

# snapshot workflow
dsnap() {
    local label="${1:-$(date +%Y%m%d_%H%M%S)}"
    drift snapshot --label "$label" && echo "snapshot: $label"
}

# diff two snapshots
ddiff() {
    local s1="${1:?usage: ddiff <snap1> <snap2>}"
    local s2="${2:?}"
    drift diff "$s1" "$s2"
}

# tail drift log with filter
dlogtail() {
    local filter="${1:-}"
    if [[ -n "$filter" ]]; then
        drift logs 200 2>/dev/null | grep "$filter"
    else
        drift logs 100 2>/dev/null
    fi
}

# full drift health check
dhealth() {
    echo "=== drift_orchestrator health ==="
    drift status 2>/dev/null || echo "status: unavailable"
    echo ""
    echo "=== recent sessions ==="
    drift sessions ls 2>/dev/null | head -10
    echo ""
    echo "=== recent log ==="
    drift logs 20 2>/dev/null
}

# export session to file
dexport() {
    local session="${1:?usage: dexport <session_id>}"
    local outfile="${2:-drift_export_$(date +%Y%m%d_%H%M%S).json}"
    drift sessions export "$session" > "$outfile" && echo "exported: $outfile"
}

# watch drift sessions live
alias dwatch='watch -n 3 "drift sessions ls 2>/dev/null | head -20"'

# alias for common drift + AI workflow
drift-analyze() {
    local session="${1:?usage: drift-analyze <session_id>}"
    echo "# verifying session $session..."
    drift verify "$session" 2>/dev/null
    echo "# generating report..."
    drift report "$session" 2>/dev/null
}
alias dana='drift-analyze'
