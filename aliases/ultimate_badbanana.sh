#!/usr/bin/env bash
# =============================================================================
# ultimate_badbanana.sh — badBANANA operator pack for aliasOS
# PHILOSOPHY:
#   (1) Primitives shape behavior. Shortcuts save keystrokes. Build primitives.
#   (2) Everything machine-parseable by default.
#   (3) The alias layer enforces discipline on the operator.
#   (4) Composable small tools beat monolithic wrappers.
#   (5) Destructive actions require stated intent. Always.
#   (6) Your environment is an observable system. Observe it.
# =============================================================================

# =============================================================================
# 1. EXPORTS & PATHS
# =============================================================================
export OPLOG="${OPLOG:-$HOME/.oplog}"
export OPSCRATCH="${OPSCRATCH:-$HOME/.scratch}"
export OPPARK="${OPPARK:-$HOME/.parked}"
export REPO_ROOT="${REPO_ROOT:-$HOME/research_hub/repos}"
export ALIASOS_REPO="${ALIASOS_REPO:-$REPO_ROOT/aliasOS}"
export DRIFT_REPO="${DRIFT_REPO:-$REPO_ROOT/drift_orchestrator}"
export DEVTO_REPO="${DEVTO_REPO:-$REPO_ROOT/devto-analytics-pro}"
export GNOME_BOOK="${GNOME_BOOK:-$HOME/gnome_book}"
export VIDEO_REPO="${VIDEO_REPO:-$REPO_ROOT/gnome_video_lab_fixed}"
export LAB_ROOT="${LAB_ROOT:-$HOME/research_hub/lab}"
export DOSSIER_ROOT="${DOSSIER_ROOT:-$HOME/research_hub/dossiers}"
export STAGED_ROOT="${STAGED_ROOT:-$HOME/research_hub/gnome_staging/evidence_packets}"
export DECAY_ROOT="${DECAY_ROOT:-$HOME/research_hub/gnome_decay}"
export SURVIVE_ROOT="${SURVIVE_ROOT:-$HOME/research_hub/gnome_survivors}"
export INTENT_STORE="${INTENT_STORE:-$HOME/research_hub/intents}"

mkdir -p "$LAB_ROOT" "$DOSSIER_ROOT" "$STAGED_ROOT" "$DECAY_ROOT" \
         "$SURVIVE_ROOT" "$INTENT_STORE" /tmp/.opsnaps 2>/dev/null || true

# =============================================================================
# 2. TIME & SESSION ANCHORS
# =============================================================================
alias ts='date -Iseconds'
alias nowms='date +%s%3N'
alias epoch='date +%s'
alias tsfile='date +%Y%m%d_%H%M%S'
alias now='date +"%Y-%m-%d %H:%M:%S"'

[ -z "$SESSION_ID" ] && export SESSION_ID="$(date +%s)"

session_start() {
  export SESSION_ID="$(date +%s)"
  emit session_start "id=$SESSION_ID user=$(id -un) cwd=$(pwd)"
  echo "[session:$SESSION_ID] started"
}

session_end() {
  emit session_end "id=$SESSION_ID"
  echo "[session:$SESSION_ID] ended"
}

alias ss.start='session_start'
alias ss.end='session_end'

mark() {
  local msg="${*:-checkpoint}"
  local line="--- MARK [$(date -Iseconds)] $msg ---"
  echo "$line" | tee -a "$OPLOG"
}

# =============================================================================
# 3. STRUCTURED LOGGING PRIMITIVES
# =============================================================================
emit() {
  local ev="${1:-event}"
  shift 2>/dev/null || true
  local data="${*:-}"
  python3 - "$ev" "$data" "$OPLOG" <<'PY'
import json, sys, time, os
ev   = sys.argv[1]
data = sys.argv[2]
path = sys.argv[3]
sid  = os.environ.get("SESSION_ID", "")
row  = {
    "t":    int(time.time()),
    "ts":   time.strftime("%Y-%m-%dT%H:%M:%S"),
    "sid":  sid,
    "ev":   ev,
    "data": data,
}
line = json.dumps(row, ensure_ascii=False)
print(line)
with open(path, "a", encoding="utf-8") as f:
    f.write(line + "\n")
PY
}

think() { echo "[$(date -Iseconds)] $*" >> "$OPSCRATCH"; }

alias scratch='cat "$OPSCRATCH" 2>/dev/null || echo "(scratch empty)"'
alias scratch.clear='> "$OPSCRATCH" && echo "[scratch cleared]"'

park() {
  {
    echo "--- PARKED [$(date -Iseconds)] ---"
    echo "SID:  $SESSION_ID"
    echo "CWD:  $(pwd)"
    echo "CMD:  $*"
    history 1 2>/dev/null || true
    echo
  } >> "$OPPARK"
  emit parked "cwd=$(pwd) cmd=$*"
  echo "[parked]"
}

alias unpark='tail -40 "$OPPARK" 2>/dev/null || echo "(nothing parked)"'
alias park.clear='> "$OPPARK" && echo "[park cleared]"'
alias oplog='tail -f "$OPLOG"'
alias oplog.today='grep "$(date +%Y-%m-%d)" "$OPLOG" 2>/dev/null || true'
alias oplog.last='tail -50 "$OPLOG" 2>/dev/null || true'
alias oplog.events='jq -r ".ev" "$OPLOG" 2>/dev/null | sort | uniq -c | sort -rn'
# =============================================================================
# 4. ENVIRONMENT INTEGRITY
# =============================================================================
toolcheck() {
  local bins=(git python3 pip3 curl wget jq sqlite3 rg fd nmap nc socat ssh
              openssl gpg ollama gh tmux docker)
  printf "%-14s %-14s %s\n" "BINARY" "SHA256:12" "PATH"
  printf "%-14s %-14s %s\n" "------" "---------" "----"
  for bin in "${bins[@]}"; do
    local loc
    loc="$(command -v "$bin" 2>/dev/null || true)"
    if [ -n "$loc" ]; then
      local hash
      hash="$(sha256sum "$loc" 2>/dev/null | awk '{print $1}' | cut -c1-12)"
      printf "%-14s %-14s %s\n" "$bin" "$hash" "$loc"
    else
      printf "%-14s %-14s %s\n" "$bin" "MISSING" "-"
    fi
  done
}

whereami() {
  echo "=== IDENTITY ==="; id
  echo; echo "=== HOST ==="; hostname -f 2>/dev/null || hostname
  echo; echo "=== RUNTIME ==="
  systemd-detect-virt 2>/dev/null || true
  [ -f /.dockerenv ] && echo "[!] inside docker container"
  [ -n "$VIRTUAL_ENV" ] && echo "[venv] $VIRTUAL_ENV"
  echo; echo "=== CWD ==="; pwd
  echo; echo "=== SHELL ==="; echo "$SHELL ($BASH_VERSION)"
  echo; echo "=== ROUTE ==="; ip route 2>/dev/null | head -5 || true
  echo; echo "=== EXTERNAL IP ==="
  curl -s --max-time 3 ifconfig.me 2>/dev/null && echo || echo "(offline or timeout)"
}

shellstate() {
  printf "%-14s %s\n" "shell:"     "$SHELL"
  printf "%-14s %s\n" "bash:"      "${BASH_VERSION:-n/a}"
  printf "%-14s %s\n" "user:"      "$(id -un)"
  printf "%-14s %s\n" "host:"      "$(hostname)"
  printf "%-14s %s\n" "cwd:"       "$(pwd)"
  printf "%-14s %s\n" "session:"   "$SESSION_ID"
  printf "%-14s %s\n" "aliases:"   "$(alias | wc -l)"
  printf "%-14s %s\n" "functions:" "$(declare -F | wc -l)"
  printf "%-14s %s\n" "env vars:"  "$(env | wc -l)"
  printf "%-14s %s\n" "oplog:"     "$(wc -l < "$OPLOG" 2>/dev/null || echo 0) events"
}

env_snapshot() {
  local out="$LAB_ROOT/env_${SESSION_ID}.log"
  env | sort | sed 's/\(KEY\|TOKEN\|SECRET\|PASS\|CRED\)=.*/\1=[REDACTED]/I' > "$out"
  echo "[env saved] $out"
  emit env_snapshot "$out"
}
alias env.snap='env_snapshot'
alias sys.state='uptime && echo && free -h && echo && df -h'

# =============================================================================
# 5. NETWORK BASELINES & DRIFT
# =============================================================================
netbase() {
  local out="/tmp/.opsnaps/netbase_$(date +%s).snap"
  ss -tulnp 2>/dev/null | sort > "$out"
  echo "[netbase] $out"
  emit netbase "$out"
}

netdrift() {
  local latest
  latest="$(ls -t /tmp/.opsnaps/netbase_*.snap 2>/dev/null | head -1)"
  if [ -z "$latest" ]; then
    echo "[!] no network baseline — run netbase first"; return 1
  fi
  local delta
  delta="$(diff "$latest" <(ss -tulnp 2>/dev/null | sort) | grep '^[<>]' || true)"
  if [ -z "$delta" ]; then
    echo "[netdrift] no change"
  else
    echo "[netdrift] DELTA:"; echo "$delta"
    emit netdrift "$(echo "$delta" | wc -l) lines changed"
  fi
}

netstate() {
  echo "=== LISTENERS ==="; ss -tulnp
  echo; echo "=== ESTABLISHED ==="; ss -tnp state established
  echo; echo "=== ROUTE ==="; ip route
  echo; echo "=== ARP ==="; arp -n 2>/dev/null || ip neigh
}

alias ports='ss -tulnp'
alias established='ss -tnp state established'
alias netbase.list='ls -lt /tmp/.opsnaps/netbase_*.snap 2>/dev/null'

# =============================================================================
# 6. PROCESS BASELINES & DRIFT
# =============================================================================
procbase() {
  local out="/tmp/.opsnaps/procbase_$(date +%s).snap"
  ps aux --sort=pid > "$out"
  echo "[procbase] $out"
  emit procbase "$out"
}

procdrift() {
  local prev curr
  prev="$(ls -t /tmp/.opsnaps/procbase_*.snap 2>/dev/null | sed -n '2p')"
  curr="$(ls -t /tmp/.opsnaps/procbase_*.snap 2>/dev/null | head -1)"
  if [ -z "$curr" ]; then
    echo "[!] no process baseline — run procbase first"; return 1
  fi
  if [ -z "$prev" ]; then
    echo "[!] only one snapshot — run procbase again after changes"; return 1
  fi
  local delta
  delta="$(diff "$prev" "$curr" | grep '^[<>]' || true)"
  if [ -z "$delta" ]; then
    echo "[procdrift] no change"
  else
    echo "[procdrift] DELTA:"; echo "$delta"
    emit procdrift "$(echo "$delta" | wc -l) lines changed"
  fi
}

alias procs='ps aux --sort=-%cpu | head -20'
alias memhogs='ps aux --sort=-%mem | head -15'
alias cpuhogs='ps aux --sort=-%cpu | head -15'
alias zombies='ps aux | awk "$8 == \"Z\""'

killzombies() {
  ps aux | awk '$8 == "Z" {print $3}' | while read -r ppid; do
    echo "[!] HUP parent PID $ppid"
    kill -HUP "$ppid" 2>/dev/null || true
  done
}
# =============================================================================
# 7. DISCIPLINE WRAPPERS
# =============================================================================
justify() {
  if [ "$#" -eq 0 ]; then echo "usage: justify <command> [args...]"; return 1; fi
  local reason
  read -r -p "reason: " reason
  if [ -z "$reason" ]; then echo "[!] state your reason — command aborted"; return 1; fi
  emit justified_run "$reason :: $*"
  "$@"
}

careful() {
  if [ "$#" -eq 0 ]; then echo "usage: careful <command> [args...]"; return 1; fi
  echo "about to run:"
  printf '  %q' "$@"; echo
  local confirm
  read -r -p "confirm [yes/no]: " confirm
  if [ "$confirm" != "yes" ]; then
    echo "[aborted]"; emit careful_abort "$*"; return 1
  fi
  emit careful_exec "$*"
  "$@"
}

blast() {
  if [ "$#" -eq 0 ]; then echo "usage: blast <command> [args...]"; return 1; fi
  emit blast_start "$*"
  echo "=== PRE-BLAST: NET BASELINE ==="; netbase
  echo "=== PRE-BLAST: PROC BASELINE ==="; procbase
  echo; echo "=== EXECUTING: $* ==="
  "$@"; local rc=$?
  echo; echo "=== POST-BLAST: PROC BASELINE ==="; procbase
  emit blast_end "rc=$rc cmd=$*"
  echo; echo "=== NET DRIFT ==="; netdrift
  echo; echo "=== PROC DRIFT ==="; procdrift
  echo; echo "=== EXIT CODE: $rc ==="; return "$rc"
}

timed() {
  if [ "$#" -eq 0 ]; then echo "usage: timed <command> [args...]"; return 1; fi
  local s; s="$(date +%s%3N)"
  "$@"; local rc=$?
  local elapsed=$(( $(date +%s%3N) - s ))
  emit timed_run "cmd=$* rc=$rc ms=$elapsed"
  echo "[timed] ${elapsed}ms  rc=$rc"; return "$rc"
}

alias git.reset='careful git reset --hard'
alias git.clean='careful git clean -fd'
alias docker.prune='careful docker system prune -a'
alias rm.rf='careful rm -rf'

# =============================================================================
# 8. ARTIFACT & BINARY ANALYSIS
# =============================================================================
what() {
  if [ -z "$1" ]; then echo "usage: what <file>"; return 1; fi
  echo "=== TYPE ===";    file "$1"
  echo "=== SIZE ===";    du -sh "$1"
  echo "=== HASH ===";    sha256sum "$1"
  echo "=== MAGIC ===";   xxd -l 16 "$1"
  echo "=== ENTROPY ==="; python3 - "$1" <<'PY'
import math, sys
with open(sys.argv[1], "rb") as f:
    data = f.read()
if not data:
    print("0.0 (empty)"); sys.exit()
freq = {}
for b in data:
    freq[b] = freq.get(b, 0) + 1
entropy = sum(-(c/len(data))*math.log2(c/len(data)) for c in freq.values())
label = 'HIGH - possibly encrypted/packed' if entropy > 7.0 else 'NORMAL' if entropy > 4.0 else 'LOW - text/structured'
print(f"{entropy:.4f}  ({label})")
PY
  echo "=== STRINGS (top 20) ==="
  strings -n 8 "$1" | sort | uniq -c | sort -rn | head -20
}

entropy() {
  python3 - "$1" <<'PY'
import math, sys
with open(sys.argv[1], "rb") as f:
    data = f.read(65536)
if not data:
    print("0.0"); sys.exit()
freq = {}
for b in data:
    freq[b] = freq.get(b, 0) + 1
ent = sum(-(c/len(data))*math.log2(c/len(data)) for c in freq.values())
print(f"{ent:.4f}")
PY
}

bindiff() {
  if [ "$#" -ne 2 ]; then echo "usage: bindiff <file1> <file2>"; return 1; fi
  diff <(strings "$1" | sort) <(strings "$2" | sort)
}

hashit() {
  if [ -d "${1:-.}" ]; then
    find "${1:-.}" -type f | sort | xargs sha256sum 2>/dev/null
  else
    sha256sum "$1"
  fi
}

filetriage() {
  if [ -z "$1" ]; then echo "usage: filetriage <file>"; return 1; fi
  echo "[type]";  file "$1"
  echo "[size]";  du -sh "$1"
  echo "[hash]";  sha256sum "$1"
  echo "[exif]";  exiftool "$1" 2>/dev/null | head -20 || echo "(exiftool not available)"
  echo "[strings - sensitive patterns]"
  strings -n 6 "$1" | grep -iE \
    "(key|secret|token|pass|auth|bearer|api|http|https|192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))" \
    | head -30
}

hexhead()  { head -c 256 "$1" | xxd -g 1; }
logburst() { grep "$(date +"%H:%M")" "$1" 2>/dev/null | wc -l; }

alias hex='xxd -g 1 -c 16'
alias binpeek='xxd -l 256'
alias stringsx='strings -n 6'
alias strings.hard='strings -a -n 4'
alias ips='grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}"'
alias urls='grep -Eo "https?://[a-zA-Z0-9./?=_%&#@:+-]+"'
alias emails='grep -Eo "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"'
alias b64='grep -Eo "[A-Za-z0-9+/]{40,}={0,2}"'
alias findexec='find . -type f -executable ! -name "*.sh" ! -name "*.py" 2>/dev/null'
alias findsuid='find / -perm -4000 -type f 2>/dev/null'
alias findguid='find / -perm -2000 -type f 2>/dev/null'
alias findwrite='find / -writable -not -path "/proc/*" -not -path "/sys/*" -type d 2>/dev/null | head -20'
alias findmod='find / -newer /tmp -not -path "/proc/*" -not -path "/sys/*" -type f 2>/dev/null | head -20'
alias findworld='find / -perm -o+w -not -path "/proc/*" -not -path "/sys/*" -type f 2>/dev/null | head -20'
alias findconfig='find / -name "*.conf" -o -name "*.cfg" -o -name "*.ini" 2>/dev/null | grep -v "/proc\|/sys"'
alias findsecrets='find / \( -name "*.key" -o -name "*.pem" -o -name "id_rsa" -o -name ".env" \) 2>/dev/null | grep -v "/proc\|/sys"'
alias errwatch='tail -f *.log 2>/dev/null | grep -iE "error|fail|critical|exception|traceback"'
# =============================================================================
# 9. LAB NETWORK DIAGNOSTICS / AUTHORIZED RECON ONLY
# =============================================================================
authorized_only() {
  echo "[!] Authorized use only — systems/networks you own or have explicit written permission to test."
  read -r -p "confirm authorized [yes/no]: " c
  [ "$c" = "yes" ] || { echo "[aborted]"; return 1; }
  "$@"
}

probe() {
  local t="${1:?usage: probe <target>}"
  local rtt
  rtt="$(ping -c1 -W2 "$t" 2>/dev/null | grep -oP 'time=\K[0-9.]+' || echo null)"
  echo "{\"target\":\"$t\",\"ts\":$(date +%s),\"rtt_ms\":$rtt}"
  nmap -sV --open -T4 "$t" 2>/dev/null | grep -E "^[0-9]+/(tcp|udp)"
  emit recon_probe "target=$t rtt=$rtt"
}

passive() {
  local target="${1:?usage: passive <domain>}"
  echo "[dns:A]";    dig +short "$target" A
  echo "[dns:AAAA]"; dig +short "$target" AAAA
  echo "[dns:MX]";   dig +short "$target" MX
  echo "[dns:TXT]";  dig +short "$target" TXT
  echo "[dns:NS]";   dig +short "$target" NS
  echo "[whois]";    whois "$target" 2>/dev/null | grep -iE "registrar|created|expires|org|country" | head -10
  echo "[cert]";     echo | openssl s_client -connect "$target":443 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "(no TLS)"
  emit passive_recon "target=$target"
}

certlook() {
  local domain="${1:?usage: certlook <domain>}"
  curl -s "https://crt.sh/?q=%25.${domain}&output=json" \
    | python3 -c "
import json,sys
data=json.load(sys.stdin)
names=sorted(set(e['name_value'] for e in data))
[print(n) for n in names]
" 2>/dev/null
  emit certlook "domain=$domain"
}

headers() {
  local target="${1:?usage: headers <url>}"
  curl -sI -w "\nTime-Total: %{time_total}s  Size: %{size_download}b  HTTP: %{http_code}\n" "$target"
}

portcheck() {
  local host="${1:?usage: portcheck <host> <port>}"
  local port="${2:?usage: portcheck <host> <port>}"
  timeout 3 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null \
    && echo "[$host:$port] OPEN" || echo "[$host:$port] CLOSED/FILTERED"
}

alias lan.hosts='nmap -sn $(ip route | grep src | awk "{print \$1}" | head -1) 2>/dev/null'
alias lan.arp='arp -n 2>/dev/null || ip neigh'
alias lan.route='ip route'

nmap.quick()   { nmap -T4 -F --open "$@"; }
nmap.full()    { authorized_only nmap -sC -sV -p- --open -T4 "$@"; }
nmap.udp()     { nmap -sU -T4 --open "$@"; }
nmap.vuln()    { authorized_only nmap --script vuln "$@"; }
nmap.stealth() { authorized_only nmap -sS -T2 -f "$@"; }

# =============================================================================
# 10. NETWORK PRIMITIVES
# =============================================================================
catchall() {
  local port="${1:?usage: catchall <port>}"
  local out="/tmp/catch_$(date +%s).log"
  echo "[listening on $port -> $out]"
  nc -lvnp "$port" | tee "$out"
  emit catchall "port=$port file=$out"
}

httplab() {
  local port="${1:-8080}"
  python3 - "$port" <<'PY'
import http.server, time, sys
port = int(sys.argv[1])
class LogHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        ts = time.strftime("%Y-%m-%dT%H:%M:%S")
        print(f"[{ts}] {self.address_string()} {fmt % args}")
    def log_request(self, code='-', size='-'):
        ts = time.strftime("%Y-%m-%dT%H:%M:%S")
        print(f"[{ts}] {self.address_string()} \"{self.requestline}\" {code} {size}")
srv = http.server.HTTPServer(("", port), LogHandler)
print(f"[httplab] serving on :{port}")
try:
    srv.serve_forever()
except KeyboardInterrupt:
    print("\n[httplab] stopped")
PY
}

pcapsum() {
  local cap="${1:?usage: pcapsum <file.pcap>}"
  tcpdump -r "$cap" -nn 2>/dev/null \
    | awk '{print $3, "->", $5}' | sed 's/\.[0-9]*$//' \
    | sort | uniq -c | sort -rn | head -30
}

tcptime() {
  local host="${1:?usage: tcptime <host> <port>}"
  local port="${2:?}"
  local s; s="$(date +%s%3N)"
  timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
  echo "$(( $(date +%s%3N) - s ))ms"
}

portwho()  { ss -tulnp | grep ":${1} "; }

killport() {
  local pid
  pid="$(ss -tulnp | grep ":${1} " | grep -oP 'pid=\K[0-9]+' | head -1)"
  if [ -z "$pid" ]; then echo "nothing on :$1"; return 1; fi
  echo "killing PID $pid on :$1"
  read -r -p "confirm [yes/no]: " c
  [ "$c" = "yes" ] && kill -9 "$pid" && echo "[killed]"
}

alias sniff.http='tcpdump -i any -A -s 0 "tcp port 80 or tcp port 443"'
alias sniff.dns='tcpdump -i any -nn udp port 53'
alias sniff.icmp='tcpdump -i any icmp'
# =============================================================================
# 11. AI / OLLAMA RUNTIME
# =============================================================================
alias oll='ollama list'
alias ollps='ollama ps'
alias ollpull='ollama pull'
alias ollrun='ollama run'
alias ollshow='ollama show'
alias aimodels='ollama list && echo && ollama ps'
alias aiping='curl -s --max-time 3 http://localhost:11434/api/tags >/dev/null && echo "[ollama] UP" || echo "[ollama] DOWN"'

aistate() {
  echo "=== OLLAMA PROCESS ==="
  ps aux | grep ollama | grep -v grep || echo "(not running)"
  echo; echo "=== MODELS ==="
  ollama list 2>/dev/null || curl -s http://localhost:11434/api/tags | python3 -m json.tool 2>/dev/null
  echo; echo "=== ACTIVE ==="; ollama ps 2>/dev/null || echo "(none)"
  echo; echo "=== PORTS ==="; ss -tulnp | grep 11434 || echo "(11434 not bound)"
}

modelprobe() {
  local model="${1:-llama3.1}"
  local resp
  resp="$(curl -s --max-time 10 http://localhost:11434/api/generate \
    -d "{\"model\":\"$model\",\"prompt\":\"Reply only the word: ALIVE\",\"stream\":false}" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response','NO_RESPONSE'))" 2>/dev/null)"
  echo "[$model] $resp"
  emit modelprobe "model=$model response=$resp"
}

modeltiming() {
  local model="${1:-llama3.1}"
  local s; s="$(date +%s%3N)"
  modelprobe "$model" > /dev/null
  local elapsed=$(( $(date +%s%3N) - s ))
  echo "[$model] ${elapsed}ms"
  emit modeltiming "model=$model ms=$elapsed"
}

llmask() {
  local model="${1:?usage: llmask <model> <prompt>}"
  shift; local prompt="$*"
  curl -s http://localhost:11434/api/generate \
    -d "{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null
}

alias ollwatch='watch -n2 "ollama ps 2>/dev/null; echo; ps aux | grep ollama | grep -v grep"'

# =============================================================================
# 12. GIT OPERATIONS
# =============================================================================
alias gs='git status --short --branch'
alias gst='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git log --oneline --decorate --graph -20'
alias gla='git log --oneline --decorate --graph --all -30'
alias gd='git diff'
alias gds='git diff --stat'
alias gdc='git diff --cached'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch --show-current'
alias gba='git branch -a'
alias gf='git fetch --all --prune'
alias gpull='git pull --ff-only'
alias grs='git restore'
alias grst='git restore --staged'
alias gclean='git clean -fdn'
alias last='git show --stat --oneline HEAD'
alias fileschanged='git diff --name-only'
alias staged='git diff --cached --name-only'
alias branchrecent='git for-each-ref --sort=-committerdate refs/heads/ --format="%(committerdate:short) %(refname:short)" | head -20'
alias wip='git add -A && git commit -m "WIP: checkpoint $(date +%Y%m%d_%H%M%S)"'
alias savepoint='git add -A && git commit -m "Savepoint: $(date -Iseconds)"'

safecommit() {
  local msg="${1:?usage: safecommit \"message\"}"
  git diff --stat --cached; echo
  read -r -p "commit staged changes? [yes/no]: " confirm
  [ "$confirm" = "yes" ] || { echo "[aborted]"; return 1; }
  git commit -m "$msg"; emit safecommit "$msg"
}

rstat() {
  for d in "$REPO_ROOT"/*/.git; do
    local repo="${d%/.git}"
    echo; echo "== ${repo##*/} =="
    git -C "$repo" status --short --branch
  done
}

dirtyrepos() {
  for d in "$REPO_ROOT"/*/.git; do
    local repo="${d%/.git}"
    local out; out="$(git -C "$repo" status --porcelain)"
    [ -n "$out" ] && echo "DIRTY: ${repo##*/}"
  done
}

recentrepos() {
  find "$REPO_ROOT" -maxdepth 2 -type d -name .git -printf "%T@ %h\n" 2>/dev/null \
    | sort -nr | head -20 | cut -d' ' -f2-
}

# =============================================================================
# 13. PYTHON & BUILD
# =============================================================================
alias py='python3'
alias pipup='python3 -m pip install --upgrade pip'
alias mkvenv='python3 -m venv .venv'
alias va='source .venv/bin/activate'
alias vd='deactivate 2>/dev/null || true'
alias venv.new='python3 -m venv .venv && source .venv/bin/activate'
alias pyc='find . -type d -name __pycache__ -prune -exec rm -rf {} +'
alias req='python3 -m pip install -r requirements.txt'
alias freeze='python3 -m pip freeze'
alias serve='python3 -m http.server 8000'
alias jsonpp='python3 -m json.tool'
alias sqlite='sqlite3'

bootpy() {
  python3 -m venv .venv && source .venv/bin/activate && \
  python3 -m pip install --upgrade pip && \
  { [ -f requirements.txt ] && python3 -m pip install -r requirements.txt || true; }
  emit bootpy "cwd=$(pwd)"
}

pyall() {
  find . -name "*.py" -not -path "./.venv/*" -print0 \
    | xargs -0 python3 -m py_compile && echo "[pyall] all OK"
}

alias py.audit='bandit -r . --exclude .venv -ll 2>/dev/null || echo "(bandit not installed)"'
alias py.safety='safety check 2>/dev/null || pip-audit 2>/dev/null || echo "(safety/pip-audit not installed)"'

builddetect() {
  [ -f Makefile ]         && echo "[make] Makefile"
  [ -f pyproject.toml ]   && echo "[python] pyproject.toml"
  [ -f requirements.txt ] && echo "[python] requirements.txt"
  [ -f Cargo.toml ]       && echo "[rust] Cargo.toml"
  [ -f package.json ]     && echo "[node] package.json"
  [ -f go.mod ]           && echo "[go] go.mod"
  [ -f Dockerfile ]       && echo "[docker] Dockerfile"
}

alias build.fast='make -j$(nproc)'
alias build.clean='make clean'
alias pytest.q='pytest -q'
alias pytest.v='pytest -vv'
alias pytest.fast='pytest -q --maxfail=1'
# =============================================================================
# 14. REPO NAVIGATION
# =============================================================================
alias rh='cd "$HOME/research_hub"'
alias rr='cd "$REPO_ROOT" && ls -1'
alias repos='cd "$REPO_ROOT" && ls -1'
alias lab='cd "$LAB_ROOT"'
alias dossiers='cd "$DOSSIER_ROOT"'
alias cdaos='cd "$ALIASOS_REPO"'
alias cddrift='cd "$DRIFT_REPO"'
alias cddevto='cd "$DEVTO_REPO"'
alias cdbook='cd "$GNOME_BOOK"'
alias cdvideo='cd "$VIDEO_REPO"'
alias cdlan='cd "$REPO_ROOT/LANimals"'
alias cdshenron='cd "$REPO_ROOT/shenron"'
alias cdzero='cd "$REPO_ROOT/zer0DAYSlater"'
alias cdbanana='cd "$REPO_ROOT/BANANA_TREE"'
alias cdblack='cd "$REPO_ROOT/Blackglass_Suite"'
alias cdopen='cd "$REPO_ROOT/OpenSight"'
alias cdhydra='cd "$REPO_ROOT/HYDRA"'
alias cdchain='cd "$REPO_ROOT/chain"'
alias cddecoy='cd "$REPO_ROOT/Decoy-Hunter"'
alias cdreflexive='cd "$REPO_ROOT/reflexive-identity"'
alias cdartifact='cd "$REPO_ROOT/drift-artifact"'
alias cdgateway='cd "$REPO_ROOT/localai_gateway"'
alias cdforge='cd "$REPO_ROOT/repo_alias_forge"'

# =============================================================================
# 15. PROJECT SHORTCUTS
# =============================================================================
alias driftstat='cd "$DRIFT_REPO" && git status --short --branch'

driftcheck() {
  cd "$DRIFT_REPO" || return 1
  [ -d .venv ] && source .venv/bin/activate
  python3 -m py_compile $(find . -name "*.py" -not -path "./.venv/*")
  pytest tests/ -q
}

alias devtostat='cd "$DEVTO_REPO" && git status --short --branch'

devtoserve() {
  cd "$DEVTO_REPO" || return 1
  [ ! -s "$HOME/.devto_api_key" ] && echo "[!] missing ~/.devto_api_key" && return 1
  [ -d .venv ] && source .venv/bin/activate
  python3 devto_proxy.py "$(cat ~/.devto_api_key)"
}

devtome() {
  [ ! -s "$HOME/.devto_api_key" ] && echo "[!] missing ~/.devto_api_key" && return 1
  curl -s -H "api-key: $(cat ~/.devto_api_key)" https://dev.to/api/users/me | python3 -m json.tool
}

alias bookrecent='cd "$GNOME_BOOK" && find . -type f -printf "%TY-%Tm-%Td %TH:%TM %p\n" 2>/dev/null | sort -r | head -40'
alias mdheads='grep -RIn "^#\|^##\|^###" . --include="*.md"'
alias mdwc='find . -name "*.md" -print0 | xargs -0 wc -w | sort -n'
alias aos='cd "$ALIASOS_REPO" && python3 aliasOS_tui.py'
alias aosstat='cd "$ALIASOS_REPO" && git status --short --branch'
alias aoscount='grep -R "^alias " "$ALIASOS_REPO/aliases"/*.sh 2>/dev/null | wc -l'

aosbackup() {
  local stamp; stamp="$(date +%Y%m%d_%H%M%S)"
  tar -czf "$ALIASOS_REPO/aliasOS_backup_$stamp.tar.gz" \
    -C "$ALIASOS_REPO" aliases aliasOS_tui.py README.md 2>/dev/null
  echo "[backup] aliasOS_backup_$stamp.tar.gz"
}

# =============================================================================
# 16. INTENT GRAPH
# =============================================================================
intent() {
  export INTENT_ID="$(date +%s%N)"
  local dir="$INTENT_STORE/$INTENT_ID"
  mkdir -p "$dir"
  echo "$*" > "$dir/intent.txt"
  emit intent_open "$INTENT_ID :: $*"
  echo "[intent:$INTENT_ID] $*"
}

hypothesis() {
  [ -z "$INTENT_ID" ] && echo "[!] no active intent — run: intent <goal>" && return 1
  echo "$*" > "$INTENT_STORE/$INTENT_ID/hypothesis.txt"
  emit intent_hypothesis "$INTENT_ID :: $*"
}

because() {
  [ -z "$INTENT_ID" ] && echo "[!] no active intent" && return 1
  echo "[$(date -Iseconds)] $*" >> "$INTENT_STORE/$INTENT_ID/edges.log"
  emit intent_edge "$INTENT_ID :: $*"
}

outcome() {
  [ -z "$INTENT_ID" ] && echo "[!] no active intent" && return 1
  echo "$*" > "$INTENT_STORE/$INTENT_ID/outcome.txt"
  emit intent_outcome "$INTENT_ID :: $*"
  echo "[intent:$INTENT_ID] outcome recorded"
}

signal() {
  [ -z "$INTENT_ID" ] && echo "[!] no active intent" && return 1
  python3 - "$INTENT_ID" "$*" "$INTENT_STORE" <<'PY'
import json, sys, time, os
iid, sig, store = sys.argv[1], sys.argv[2], sys.argv[3]
row = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "signal": sig}
path = os.path.join(store, iid, "signals.jsonl")
line = json.dumps(row, ensure_ascii=False)
print(line)
with open(path, "a") as f:
    f.write(line + "\n")
PY
}

intent.view() {
  local id="${1:-$INTENT_ID}"
  [ -z "$id" ] && echo "[!] no intent id" && return 1
  local dir="$INTENT_STORE/$id"
  echo "=== INTENT ===";     cat "$dir/intent.txt"     2>/dev/null || echo "(none)"
  echo "=== HYPOTHESIS ==="; cat "$dir/hypothesis.txt" 2>/dev/null || echo "(none)"
  echo "=== EDGES ===";      cat "$dir/edges.log"      2>/dev/null || echo "(none)"
  echo "=== SIGNALS ===";    cat "$dir/signals.jsonl"  2>/dev/null || echo "(none)"
  echo "=== OUTCOME ===";    cat "$dir/outcome.txt"    2>/dev/null || echo "(none)"
}

intent.ls()    { ls -lt "$INTENT_STORE" | grep -v "^total\|graph_edges" | head -20; }
intent.graph() { cat "$INTENT_STORE/graph_edges.log" 2>/dev/null || echo "(no edges)"; }

link.intent() {
  local from="${1:?usage: link.intent <from_id>}"
  echo "$from -> $INTENT_ID" >> "$INTENT_STORE/graph_edges.log"
  emit intent_link "$from -> $INTENT_ID"
}

alias intent.find='grep -Rni "$INTENT_STORE" -e'
alias intent.signals='find "$INTENT_STORE" -name "signals.jsonl" -exec cat {} \;'

# =============================================================================
# 17. DOSSIER & STAGING
# =============================================================================
alias dossier.list='ls -lt "$DOSSIER_ROOT" | head -20'
alias dossier.grep='grep -Rni "$DOSSIER_ROOT" -e'
alias dossier.open='xdg-open "$DOSSIER_ROOT" 2>/dev/null || ls "$DOSSIER_ROOT"'
alias dossier.staged='ls -lt "$STAGED_ROOT" | head -20'
alias dossier.decayed='ls -lt "$DECAY_ROOT" | head -20'
alias dossier.survivors='ls -lt "$SURVIVE_ROOT" | head -20'
alias dossier.review='${EDITOR:-nano} "$STAGED_ROOT/$(ls -t "$STAGED_ROOT" | head -1)"'
alias dossier.stagegrep='grep -Rni "$STAGED_ROOT" -e'

dossier.stage() {
  local file="${1:-$(ls -t "$DOSSIER_ROOT"/intent_*.md 2>/dev/null | head -1)}"
  [ ! -f "$file" ] && echo "[!] dossier not found" && return 1
  mkdir -p "$STAGED_ROOT"
  local base; base="$(basename "$file")"
  cp "$file" "$STAGED_ROOT/$base"
  { echo ""; echo "---"; echo "## Editorial Status"; echo ""
    echo "- Status: staged"; echo "- Staged: $(date -Iseconds)"
    echo "- Book candidate: undecided"; echo "- Needs rewrite: yes"
    echo "- Evidence quality: unreviewed"; echo "- Chapter target: TBD"
    echo "- Public-safe: unreviewed"; } >> "$STAGED_ROOT/$base"
  emit dossier_staged "$base"; echo "[staged] $STAGED_ROOT/$base"
}

dossier.survive() {
  local file="${1:?usage: dossier.survive <file>}"
  cp "$file" "$SURVIVE_ROOT/"; emit dossier_survive "$(basename "$file")"
  echo "[survive] $(basename "$file")"
}

dossier.purge() {
  local file="${1:?usage: dossier.purge <file>}"
  careful rm -f "$file"; emit dossier_purge "$(basename "$file")"
}

# =============================================================================
# 18. FILE & SYSTEM UTILITY
# =============================================================================
alias ll='ls -lah'
alias la='ls -A'
alias lt='ls -lah --sort=time'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias tree2='find . -maxdepth 2 | sort'
alias tree3='find . -maxdepth 3 | sort'
alias ducks='du -h --max-depth=1 2>/dev/null | sort -h'
alias newest='find . -type f -printf "%TY-%Tm-%Td %TH:%TM %p\n" 2>/dev/null | sort -r | head -30'
alias grepall='grep -RIn --exclude-dir=.git --exclude-dir=.venv'
alias rgpy='rg --glob "*.py"'
alias mkdirp='mkdir -p'
alias path='echo "$PATH" | tr ":" "\n"'
alias c='clear'
alias h='history | tail -50'
alias q='exit'
alias reload='source ~/.bashrc && echo "[reloaded]"'
alias jp='jq .'
alias clipin='xclip -selection clipboard 2>/dev/null || pbcopy 2>/dev/null'
alias clipout='xclip -selection clipboard -o 2>/dev/null || pbpaste 2>/dev/null'

jsonpaths() { jq -r 'path(..)|map(tostring)|join(".")' "$1"; }

biggest() {
  find . -type f -printf "%s %p\n" 2>/dev/null \
    | sort -nr | head -20 | numfmt --field=1 --to=iec
}

sessioncapture() {
  local out="$LAB_ROOT/sessioncap_${SESSION_ID}.txt"
  { echo "=== SESSION CAPTURE ==="; echo "Time:  $(date -Iseconds)"
    echo "User:  $(id)"; echo "Host:  $(hostname)"; echo "CWD:   $(pwd)"
    echo; echo "=== PORTS ==="; ss -tulnp
    echo; echo "=== PROCESSES ==="; ps aux --sort=-%cpu | head -20
    echo; echo "=== GIT ==="; git status --short --branch 2>/dev/null || echo "(not a repo)"
    echo; echo "=== ENV (redacted) ==="
    env | sort | sed 's/\(KEY\|TOKEN\|SECRET\|PASS\)=.*/\1=[REDACTED]/I' | head -40
  } > "$out"
  echo "[session captured] $out"; emit session_capture "$out"
}

alias tmpdir='cd "$(mktemp -d)"'
alias sandbox='firejail --private'

# =============================================================================
# 19. META / SELF-INSPECTION
# =============================================================================
whichalias() { alias | grep "$1"; }
whichfn()    { declare -f "$1"; }

alias aliascount='alias | wc -l'
alias fncount='declare -F | wc -l'

hotcmds() {
  history | awk '{print $2}' | sort | uniq -c | sort -rn | head -20
}

oplog.top() {
  python3 - "$OPLOG" <<'PY'
import json, sys, collections
path = sys.argv[1]
counts = collections.Counter()
try:
    with open(path) as f:
        for line in f:
            try:
                counts[json.loads(line.strip()).get("ev","unknown")] += 1
            except Exception:
                pass
except FileNotFoundError:
    print("(oplog not found)"); sys.exit()
for ev, n in counts.most_common(20):
    print(f"{n:5d}  {ev}")
PY
}

alias.dupes() {
  alias | awk -F= '{print $1}' | awk '{print $2}' | sort | uniq -d
}

ultimate.check() {
  echo "[1] bash syntax"
  bash -n "$ALIASOS_REPO/aliases/ultimate_badbanana.sh" && echo "  OK" || echo "  FAIL"
  echo "[2] alias count";    echo "  $(alias | wc -l) loaded"
  echo "[3] function count"; echo "  $(declare -F | wc -l) defined"
  echo "[4] oplog";          echo "  $(wc -l < "$OPLOG" 2>/dev/null || echo 0) events"
  echo "[5] intent store";   echo "  $(ls "$INTENT_STORE" 2>/dev/null | wc -l) intents"
  echo "[6] critical binaries"
  for b in git python3 nmap nc jq ollama; do
    command -v "$b" >/dev/null \
      && printf "  %-12s OK\n" "$b" \
      || printf "  %-12s MISSING\n" "$b"
  done
}

# =============================================================================
# LOADED
# =============================================================================
emit alias_pack_loaded "ultimate_badbanana.sh session=$SESSION_ID" 2>/dev/null || true
echo "[ultimate_badbanana] loaded: session=$SESSION_ID aliases=$(alias | wc -l) functions=$(declare -F | wc -l)"
