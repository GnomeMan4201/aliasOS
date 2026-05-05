#!/usr/bin/env bash
# ── network advanced / nmap / ssh / firewall / tmux ─────────────────────────

# ── nmap ─────────────────────────────────────────────────────────────────────
alias nmap_quick='nmap -T4 -F'                                       # top 100 ports fast
alias nmap_full='nmap -T4 -A -p-'                                    # all ports + OS + scripts
alias nmap_vuln='nmap -T4 --script=vuln'                             # vuln scan
alias nmap_udp='nmap -sU -T4 --top-ports 200'                        # UDP top 200
alias nmap_stealth='nmap -sS -T2 -f'                                 # stealth SYN fragmented
alias nmap_ping='nmap -sn'                                           # host discovery only
alias nmap_os='nmap -O --osscan-guess'                               # OS fingerprint
alias nmap_scripts='nmap -sC -sV'                                    # default scripts + version
alias nmap_http='nmap --script=http-enum,http-headers,http-methods'  # HTTP recon

nmap_range() {
    local target="${1:?usage: nmap_range <cidr>}"
    nmap -T4 -sn "$target" -oG - | grep 'Up' | awk '{print $2}'
}

# ── curl extended ─────────────────────────────────────────────────────────────
alias curlj='curl -s -H "Content-Type: application/json" -H "Accept: application/json"'
alias curlh='curl -I -s'                                             # headers only
alias curlf='curl -sL'                                               # follow redirects silently
alias curld='curl -OL'                                               # download to current dir
alias curlpost='curl -s -X POST -H "Content-Type: application/json" -d'
alias curlauth='curl -s -H "Authorization: Bearer"'
alias curlv='curl -v'                                                # verbose
alias curltrace='curl --trace-ascii -'                               # full wire trace
alias curlip='curl -s https://ipinfo.io/json | jq .'
alias curllatency='curl -w "DNS:%{time_namelookup} TCP:%{time_connect} TLS:%{time_appconnect} TTFB:%{time_starttransfer} Total:%{time_total}\n" -o /dev/null -s'

# http server one-liners
alias serve='python3 -m http.server 8000'
alias serv8='python3 -m http.server 8080'
servdir() { python3 -m http.server "${2:-8000}" --directory "${1:-.}"; }

# ── SSH ───────────────────────────────────────────────────────────────────────
alias sshkeys='ls -la ~/.ssh/'
alias sshconfig='${EDITOR:-nano} ~/.ssh/config'
sshkeygen() {
    local name="${1:?usage: sshkeygen <key-name> [comment]}"
    local comment="${2:-$USER@$(hostname)}"
    ssh-keygen -t ed25519 -C "$comment" -f "$HOME/.ssh/$name"
}
sshcp() {
    ssh-copy-id -i "${2:-$HOME/.ssh/id_ed25519.pub}" "${1:?usage: sshcp <user@host> [pubkey]}"
}
alias sshadd='ssh-add'
alias sshlist='ssh-add -l'
alias sshagent='eval $(ssh-agent -s)'

# SSH tunnel shortcuts
sshtunnel() {
    # sshtunnel local_port remote_host remote_port [jump_host]
    local lport="${1:?usage: sshtunnel <local_port> <remote_host> <remote_port>}"
    local rhost="${2:?}"
    local rport="${3:?}"
    ssh -N -L "${lport}:localhost:${rport}" "$rhost"
}
sshsocks() {
    # SOCKS5 proxy through a jump host
    local port="${1:-1080}"
    local host="${2:?usage: sshsocks [port] <jump_host>}"
    ssh -N -D "$port" "$host"
    echo "# SOCKS5 proxy on localhost:$port"
}

# ── Firewall (ufw) ────────────────────────────────────────────────────────────
alias fwstatus='sudo ufw status verbose'
alias fwallow='sudo ufw allow'
alias fwdeny='sudo ufw deny'
alias fwdelete='sudo ufw delete'
alias fwreset='sudo ufw reset'
alias fwenable='sudo ufw enable'
alias fwdisable='sudo ufw disable'
alias fwlog='sudo tail -f /var/log/ufw.log'
alias fwrules='sudo ufw show added'

# ── Tmux ──────────────────────────────────────────────────────────────────────
alias tma='tmux attach -t'
alias tmls='tmux ls 2>/dev/null || echo "no tmux sessions"'
alias tmnew='tmux new-session -s'
alias tmkill='tmux kill-session -t'
alias tmkillall='tmux kill-server'
alias tmsplit='tmux split-window -h'
alias tmsplitv='tmux split-window -v'
alias tmrename='tmux rename-session'
alias tmwin='tmux new-window'
alias tmwinls='tmux list-windows'

# attach or create
tmat() {
    local name="${1:-main}"
    tmux attach -t "$name" 2>/dev/null || tmux new-session -s "$name"
}

# ── MTR / traceroute ──────────────────────────────────────────────────────────
alias mtr2='mtr --report --report-cycles 10'
alias traceroute6='traceroute6 2>/dev/null || traceroute -6'
alias tracert='traceroute'

# ── Network info ──────────────────────────────────────────────────────────────
alias arp2='arp -n'
alias mac='ip link show | grep ether | awk "{print \$2}"'
alias routes='ip route show'
alias route6='ip -6 route show'
alias dns='cat /etc/resolv.conf'
alias hostsfile='cat /etc/hosts'
alias nstat='netstat -s 2>/dev/null || ss -s'
alias bandmon='iftop -i any 2>/dev/null || echo "install iftop"'

# whois quick
alias whois2='whois -H'

# ── Process network ops ───────────────────────────────────────────────────────
alias pskill='pkill -9 -f'
alias psgrep='pgrep -a -f'
alias pswait='wait'
alias psnice='renice -n'
alias pslimit='ulimit -a'
pstop() { kill -STOP "${1:?usage: pstop <pid>}"; }
psresume() { kill -CONT "${1:?usage: psresume <pid>}"; }

# ── SQLite quick ops ──────────────────────────────────────────────────────────
sqlopen()  { sqlite3 "${1:?usage: sqlopen <file.db>}"; }
sqlschema(){ sqlite3 "${1:?usage: sqlschema <file.db>}" ".schema"; }
sqlquery() { sqlite3 "${1:?usage: sqlquery <file.db> <query>}" "${2:?}"; }
sqldump()  { sqlite3 "${1:?usage: sqldump <file.db>}" ".dump" > "${2:-dump.sql}"; echo "dumped to ${2:-dump.sql}"; }
sqlimport(){ sqlite3 "${1:?usage: sqlimport <file.db> <dump.sql>}" < "${2:?}"; }
sqltables(){ sqlite3 "${1:?usage: sqltables <file.db>}" ".tables"; }
sqlcsv()   {
    sqlite3 -csv -header "${1:?usage: sqlcsv <file.db> <query>}" "${2:?}"
}
