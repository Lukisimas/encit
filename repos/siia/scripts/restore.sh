#!/usr/bin/env bash
set -euo pipefail
DUMP="${1:?archivo .dump}"
[[ "${CONFIRM_RESTORE:-}" == "YES" ]] || { echo "export CONFIRM_RESTORE=YES"; exit 2; }
docker compose exec -T db pg_restore --clean --if-exists --no-owner \
  -U "$POSTGRES_USER" -d "$POSTGRES_DB" <"$DUMP"
