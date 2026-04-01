#!/usr/bin/env bash
# ── python / venv / testing / linting ───────────────────────────────────────

# venv lifecycle
alias ve='python3 -m venv .venv'
alias va='source .venv/bin/activate'
alias vd='deactivate'
alias venv-here='python3 -m venv .venv && source .venv/bin/activate'

# pip
alias pipi='pip install'
alias pipiu='pip install -U'
alias pipf='pip freeze > requirements.txt'
alias pipr='pip install -r requirements.txt'
alias pipup='pip install --upgrade pip'
alias pipoutdated='pip list --outdated'
alias plock='pip freeze > requirements.lock'
alias punlock='pip install -r requirements.lock'
alias pipshow='pip show'
alias pipsearch='pip index versions'  # pip>=21.2

# testing
alias pt='pytest'
alias ptv='pytest -v'
alias ptx='pytest -x'            # stop on first failure
alias ptxv='pytest -xvs'         # stop + verbose + no capture
alias ptw='ptw --runner pytest'  # pytest-watch (install separately)
alias ptlf='pytest --lf'         # last failed only
alias cov='pytest --cov=. --cov-report=term-missing'
alias covhtml='pytest --cov=. --cov-report=html && echo "report: htmlcov/index.html"'
alias covopen='pytest --cov=. --cov-report=html && xdg-open htmlcov/index.html 2>/dev/null'
alias ptmark='pytest -m'         # run by marker: ptmark slow

# linting / formatting
alias lint='ruff check . 2>/dev/null || flake8 . 2>/dev/null || echo "no linter found"'
alias lintfix='ruff check --fix . 2>/dev/null'
alias fmt='black . 2>/dev/null || autopep8 --in-place -r . 2>/dev/null'
alias fmtcheck='black --check . 2>/dev/null'
alias fmtdiff='black --diff . 2>/dev/null'
alias types='mypy . 2>/dev/null || echo "mypy not installed"'
alias isort='isort . 2>/dev/null || echo "isort not installed"'
alias ruff='ruff check .'
alias rufffix='ruff check --fix .'

# full quality pass
alias qa='ruff check . && black --check . && mypy . && pytest -x'

# python utils
alias py='python3'
alias pyv='python3 --version'
alias pypath='python3 -c "import sys; [print(p) for p in sys.path]"'
alias pymod='python3 -c "import sys; print(sys.executable)"'
alias pycache-clean='find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; find . -name "*.pyc" -delete 2>/dev/null; echo "pycache cleared"'

# run with env from .env
dotenv-run() {
    local envfile="${1:-.env}"
    shift
    set -a; source "$envfile"; set +a
    "$@"
}
alias drun='dotenv-run'
