#!/usr/bin/env bash
# ── docker ──────────────────────────────────────────────────────────────────

alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias ddown='docker-compose down'
alias dup='docker-compose up -d'
alias dupb='docker-compose up -d --build'
alias drm='docker rm'
alias drma='docker rm $(docker ps -aq) 2>/dev/null'
alias drmi='docker rmi'
alias dprune='docker system prune -f'
alias dprunea='docker system prune -af --volumes'
alias dnet='docker network ls'
alias dvol='docker volume ls'
alias denv='docker inspect --format="{{range .Config.Env}}{{println .}}{{end}}"'
alias dinspect='docker inspect'
alias dstop='docker stop'
alias dstopa='docker stop $(docker ps -q) 2>/dev/null'
alias drestart='docker restart'
alias dpull='docker pull'
alias dbuild='docker build -t'

# open bash inside a running container
dbash() {
    local cname="${1:?usage: dbash <container>}"
    docker exec -it "$cname" bash 2>/dev/null || docker exec -it "$cname" sh
}

# tail logs with optional line count
dlogs() {
    local cname="${1:?usage: dlogs <container> [lines]}"
    local lines="${2:-100}"
    docker logs --tail "$lines" -f "$cname"
}

# show container resource usage live
dstat() {
    docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# compose shorthand — runs from cwd or parent with docker-compose.yml
dcu()  { docker-compose up -d "$@"; }
dcd()  { docker-compose down "$@"; }
dcl()  { docker-compose logs -f "$@"; }
dcps() { docker-compose ps; }
dcb()  { docker-compose build "$@"; }
dcr()  { docker-compose restart "$@"; }

# get IP of a container
dip() {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${1:?usage: dip <container>}"
}
