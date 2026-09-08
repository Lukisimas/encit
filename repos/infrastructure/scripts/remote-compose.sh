#!/usr/bin/env bash
set -euo pipefail
HOST="${1:?host}"
DIR="${2:?directorio remoto}"
shift 2
ssh -o BatchMode=yes "$HOST" "cd '$DIR' && docker compose $*"
