#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source shell/operator_ctx.sh
source aliases/ultimate_badbanana.sh

tools/aliasos_doctor.sh
