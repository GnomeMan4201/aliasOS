#!/usr/bin/env bash
# ── operator flow / dev tools / env / monitoring ─────────────────────────────

# ── dev server / data format tools ───────────────────────────────────────────
alias jsonpp='python3 -m json.tool'                              # pretty-print JSON
alias xmlpp='python3 -c "import sys,xml.dom.minidom; print(xml.dom.minidom.parseString(sys.stdin.read()).toprettyxml())"'
alias yamlpp='python3 -c "import sys,yaml; yaml.dump(yaml.safe_load(sys.stdin), sys.stdout, default_flow_style=False)" 2>/dev/null || cat'
alias tomlpp='python3 -c "import sys,tomllib; import pprint; pprint.pprint(tomllib.loads(sys.stdin.read()))" 2>/dev/null || cat'
alias csvpp='column -t -s,'                                      # pretty CSV columns

# jq shortcuts
alias jqkeys='jq "keys"'
alias jqlen='jq "length"'
alias jqraw='jq -r'
alias jqc='jq -c'                                                # compact output
alias jqnull='jq "del(..|nulls)"'                               # strip nulls

# env management
envdiff() {
    # compare .env files or show diff vs current env
    local f1="${1:-.env}"
    local f2="${2:-.env.example}"
    diff <(sort "$f1") <(sort "$f2")
}
envshow() {
    # pretty-print a .env file
    local f="${1:-.env}"
    grep -v '^#' "$f" | grep '=' | sort | column -t -s=
}
alias dotenv='set -a; source .env; set +a'
alias envgrep='env | grep -i'
alias envls='env | sort | less'
alias envdump='env | sort > env_dump_$(date +%Y%m%d_%H%M%S).txt && echo "dumped"'

# ── operator session flow ─────────────────────────────────────────────────────
# These wrap your existing sess/tt tooling into a full op start/stop ritual
opstart() {
    local opname="${1:?usage: opstart <op-name>}"
    echo "# starting op: $opname"
    sess new "$opname" 2>/dev/null
    tt start "$opname" 2>/dev/null
    echo "# op started: $opname — $(date)"
    ctx
}

opstop() {
    local opname="${1:-$(ctx 2>/dev/null | awk '{print $2}')}"
    echo "# stopping op: $opname"
    tt stop 2>/dev/null
    sess close "$opname" 2>/dev/null
    echo "# op stopped: $opname — $(date)"
}

opstatus() {
    echo "=== op status ==="
    tt status 2>/dev/null
    sess status 2>/dev/null
    ctx
}

oplog() {
    local opname="${1:-}"
    if [[ -n "$opname" ]]; then
        sess log "$opname" 2>/dev/null
    else
        sess log 2>/dev/null
    fi
}

opsnap() {
    local label="${1:-snap_$(date +%Y%m%d_%H%M%S)}"
    ctxsnap 2>/dev/null
    tt note "snapshot: $label" 2>/dev/null
    echo "# snapshot: $label"
}

opexport() {
    local outdir="${1:-op_export_$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$outdir"
    sess export > "$outdir/sessions.json" 2>/dev/null
    tt report  > "$outdir/timelog.txt"   2>/dev/null
    echo "# exported to $outdir/"
}

opingest() {
    local f="${1:?usage: opingest <file>}"
    python3 ingest_cli.py "$f" 2>/dev/null || echo "ingest_cli.py not found in cwd"
}

alias opst='opstatus'
alias opx='opexport'
alias ops='opstart'

# ── monitoring extended ───────────────────────────────────────────────────────
alias monstart='mon start 2>/dev/null || echo "mon: not available"'
alias monrestart='mon restart 2>/dev/null || echo "mon: not available"'
alias monadd='mon add'
alias monwatch='watch -n 5 "mon status 2>/dev/null"'
alias monalert='mon alert'

# ── system quick ops ──────────────────────────────────────────────────────────
alias sysinfo='uname -a && lsb_release -a 2>/dev/null && echo "kernel: $(uname -r)"'
alias memfree='free -h && echo "" && cat /proc/meminfo | grep -E "MemAvailable|SwapFree"'
alias cpuinfo='grep "model name" /proc/cpuinfo | head -1 && nproc'
alias diskio='iostat -x 1 3 2>/dev/null || echo "install sysstat"'
alias irqwatch='watch -n 1 "cat /proc/interrupts | head -30"'
alias swapwatch='watch -n 2 "free -h && cat /proc/swaps"'
alias fdwatch='watch -n 2 "ls /proc/\$\$/fd | wc -l"'

# ── recon extended ────────────────────────────────────────────────────────────
alias rls='recon ls 2>/dev/null'
alias rnew='recon new'
alias rstop='recon stop'
alias rexp='recon export'

# nmap quick wrappers that feed into your recon layer
rnmap() {
    local target="${1:?usage: rnmap <target>}"
    local label="${2:-nmap_$(date +%Y%m%d_%H%M%S)}"
    nmap -T4 -sC -sV "$target" -oA "$label" 2>/dev/null
    echo "# saved: $label.{nmap,gnmap,xml}"
}

rffuf() {
    local url="${1:?usage: rffuf <url/FUZZ> [wordlist]}"
    local wl="${2:-/usr/share/wordlists/dirb/common.txt}"
    ffuf -u "$url" -w "$wl" -mc 200,301,302,403 2>/dev/null || echo "install ffuf"
}

rgobuster() {
    local url="${1:?usage: rgobuster <url> [wordlist]}"
    local wl="${2:-/usr/share/wordlists/dirb/common.txt}"
    gobuster dir -u "$url" -w "$wl" -t 50 2>/dev/null || echo "install gobuster"
}

# ── fzf integration ───────────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    # fuzzy cd
    fzf_cd() {
        local dir
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf --preview 'ls -la {}') && cd "$dir"
    }
    alias fcd='fzf_cd'

    # fuzzy file open
    fzf_edit() {
        local file
        file=$(find . -type f 2>/dev/null | fzf --preview 'head -50 {}') && ${EDITOR:-nano} "$file"
    }
    alias fe='fzf_edit'

    # fuzzy git log
    fzf_git_log() {
        git log --oneline --all | fzf --preview 'git show --stat {1}' | awk '{print $1}'
    }
    alias fgl='fzf_git_log'

    # fuzzy kill
    fzf_kill() {
        local pid
        pid=$(ps aux | fzf --header-lines=1 | awk '{print $2}')
        [[ -n "$pid" ]] && kill "$pid" && echo "killed: $pid"
    }
    alias fkill='fzf_kill'

    # fuzzy alias run (complement to aliasOS TUI)
    fzf_alias() {
        local chosen
        chosen=$(alias | fzf --preview 'echo {}' | sed "s/alias //;s/=.*//" )
        [[ -n "$chosen" ]] && echo "running: $chosen" && eval "$chosen"
    }
    alias fa='fzf_alias'
fi

# ── quick benchmarking ────────────────────────────────────────────────────────
alias time3='time for i in 1 2 3; do'   # prefix: time3 <cmd>; done
bench() {
    local n="${1:-5}"
    shift
    echo "# running $n times: $*"
    for i in $(seq "$n"); do time "$@" 2>&1; done
}

# ── one-liner utilities ───────────────────────────────────────────────────────
alias myports='ss -tulnp | grep $(whoami)'
alias listening-pids='ss -tlnp | awk "NR>1 {print \$NF}" | grep -oP "pid=\K[0-9]+"'
alias dnsflush='sudo systemd-resolve --flush-caches && echo "DNS cache flushed"'
alias hosts='cat /etc/hosts'
alias hostsadd='sudo tee -a /etc/hosts'
alias cron='crontab -e'
alias cronls='crontab -l'
alias at2='at'                                    # schedule: echo "cmd" | at2 now + 5 minutes
alias watch2='watch -n 2'
alias watch5='watch -n 5'
alias wcl='wc -l'
alias wcc='wc -c'
alias wcw='wc -w'
alias head10='head -10'
alias tail10='tail -10'
alias tailf='tail -f'
alias sortu='sort -u'
alias sortn='sort -n'
alias sortc='sort | uniq -c | sort -rn'           # frequency count
alias tee2='tee /tmp/last_output.txt'             # capture + pass through
alias nullout='2>/dev/null'
alias ltime='date "+%H:%M:%S"'
alias ltimed='date "+%Y-%m-%d %H:%M:%S"'
