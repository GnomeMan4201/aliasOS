#!/usr/bin/env bash
# ── files / find / archive / clipboard ──────────────────────────────────────

# find shortcuts
alias ffind='find . -name'                                    # ffind "*.py"
alias ftype='find . -type f -name'                            # ftype "*.sh"
alias fdir='find . -type d -name'                             # fdir "node_modules"
alias fmod='find . -newer'                                    # fmod reference_file
alias fsize='find . -type f -size'                            # fsize +10M
alias fexec='find . -type f -name'                            # fexec "*.sh" -exec chmod +x {} \;
alias fgrep2='grep -rl'                                       # fgrep2 "pattern" .
alias fxargs='find . -type f -name'                           # fxargs "*.py" | xargs wc -l
alias fempty='find . -empty -type f'
alias fbig='find . -type f -size +100M -exec ls -lh {} \;'
alias frecent='find . -type f -mtime -1 | sort'               # files modified in last 24h
alias fold='find . -type f -mtime +30 | sort'                 # files older than 30 days

# better find with fd if available
ffdd() {
    if command -v fd &>/dev/null; then
        fd "$@"
    else
        find . -name "*${1}*" 2>/dev/null
    fi
}

# grep with context
alias grC='grep --color=auto -C 3'      # 3 lines context
alias grA='grep --color=auto -A 3'      # 3 lines after
alias grB='grep --color=auto -B 3'      # 3 lines before
alias gri='grep --color=auto -i'        # case insensitive
alias grr='grep --color=auto -r'        # recursive
alias grn='grep --color=auto -n'        # with line numbers
alias grv='grep --color=auto -v'        # invert

# archive — consistent interface
untar()   { tar -xzvf "${1:?usage: untar <file.tar.gz>}"; }
untarxz() { tar -xJvf "${1:?usage: untarxz <file.tar.xz>}"; }
untarbz() { tar -xjvf "${1:?usage: untarbz <file.tar.bz2>}"; }
tarball() { tar -czf "${1:?usage: tarball <name.tar.gz> <dir>}" "${2:?}"; }
tarbz()   { tar -cjf "${1:?usage: tarbz <name.tar.bz2> <dir>}" "${2:?}"; }
tarxz()   { tar -cJf "${1:?usage: tarxz <name.tar.xz> <dir>}" "${2:?}"; }
zipdir()  { zip -r "${1:?usage: zipdir <name.zip> <dir>}" "${2:?}"; }
unzip2()  { unzip "${1:?usage: unzip2 <file.zip>}" -d "${2:-.}"; }

# smart extract — detect format automatically
extract() {
    local f="${1:?usage: extract <file>}"
    case "$f" in
        *.tar.gz|*.tgz)   tar -xzvf "$f" ;;
        *.tar.bz2|*.tbz2) tar -xjvf "$f" ;;
        *.tar.xz|*.txz)   tar -xJvf "$f" ;;
        *.tar)             tar -xvf  "$f" ;;
        *.gz)              gunzip "$f" ;;
        *.bz2)             bunzip2 "$f" ;;
        *.xz)              unxz "$f" ;;
        *.zip)             unzip "$f" ;;
        *.7z)              7z x "$f" ;;
        *.rar)             unrar x "$f" ;;
        *)                 echo "unknown format: $f" ;;
    esac
}
alias ex='extract'

# clipboard — xclip primary, xsel fallback
clip() {
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --input
    else
        echo "no clipboard tool (install xclip or xsel)"
    fi
}
paste-clip() {
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard -o
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --output
    fi
}
clipfile() { cat "${1:?usage: clipfile <file>}" | clip; echo "copied: $1"; }
alias cliphist='xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null'

# file info
alias mime='file --mime-type'
alias ldd2='ldd'
alias hexview='hexdump -C | head -40'
alias strace2='strace -f -e trace=network'

# diff
alias diff='diff --color=auto'
alias cdiff='colordiff 2>/dev/null || diff --color=auto'
alias diffd='diff -r'              # recursive dir diff
alias diffstat2='diffstat'         # diffstat summary

# permissions
alias chx='chmod +x'
alias chr='chmod -x'
alias own='chown -R $(whoami):'
alias perm='stat -c "%a %n"'       # show octal perms
alias perms='find . -type f -exec stat -c "%a %n" {} \; | sort'
