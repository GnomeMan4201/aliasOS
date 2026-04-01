#!/usr/bin/env bash
# ── crypto / encoding / hashing ─────────────────────────────────────────────

# base64
alias b64e='base64'
alias b64d='base64 -d'
b64ef() { base64 < "${1:?usage: b64ef <file>}"; }
b64df() { base64 -d < "${1:?usage: b64df <file>}"; }

# URL encoding
urlencode() {
    python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "${1:?usage: urlencode <string>}"
}
urldecode() {
    python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "${1:?usage: urldecode <string>}"
}
alias urle='urlencode'
alias urld='urldecode'

# hashing — file or stdin
md5f()    { md5sum "${1:?usage: md5f <file>}"; }
sha1f()   { sha1sum "${1:?usage: sha1f <file>}"; }
sha256f() { sha256sum "${1:?usage: sha256f <file>}"; }
sha512f() { sha512sum "${1:?usage: sha512f <file>}"; }

# hash a string directly
hash-str() {
    local algo="${1:-sha256}"
    local str="${2:?usage: hash-str <algo> <string>}"
    echo -n "$str" | "${algo}sum"
}

# compare two file hashes
hash-cmp() {
    local f1="${1:?usage: hash-cmp <file1> <file2>}"
    local f2="${2:?}"
    local h1; h1=$(sha256sum "$f1" | awk '{print $1}')
    local h2; h2=$(sha256sum "$f2" | awk '{print $1}')
    if [[ "$h1" == "$h2" ]]; then
        echo "MATCH  $h1"
    else
        echo "DIFFER"
        echo "  $f1: $h1"
        echo "  $f2: $h2"
    fi
}

# hex ops
alias hex2bin='xxd -r -p'
alias bin2hex='xxd -p'
hex2dec() { python3 -c "print(int('${1:?}', 16))"; }
dec2hex() { printf '0x%x\n' "${1:?}"; }

# random
alias rng16='openssl rand -hex 16'
alias rng32='openssl rand -hex 32'
alias rngb64='openssl rand -base64 32'

# ssl cert quick ops
alias certcheck='openssl s_client -connect'           # certcheck host:443
alias certexpiry='openssl x509 -noout -dates -in'     # certexpiry cert.pem
certinfo() {
    echo | openssl s_client -servername "${1:?usage: certinfo <host>}" \
        -connect "${1}:${2:-443}" 2>/dev/null | openssl x509 -noout -text | \
        grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:)"
}

# gpg
alias gpglist='gpg --list-keys'
alias gpglistsec='gpg --list-secret-keys'
alias gpgenc='gpg --encrypt --armor -r'
alias gpgdec='gpg --decrypt'
alias gpgsign='gpg --sign --armor'
alias gpgverify='gpg --verify'
alias gpgexport='gpg --export --armor'
alias gpgimport='gpg --import'
gpgfingerprint() { gpg --fingerprint "${1:?usage: gpgfingerprint <key-id>}"; }
