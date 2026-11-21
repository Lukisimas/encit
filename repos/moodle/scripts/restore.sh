#!/usr/bin/env bash
set -euo pipefail
DUMP="${1:?archivo .sql.gz}"
[[ "${CONFIRM_RESTORE:-}" == "YES" ]] || { echo "export CONFIRM_RESTORE=YES"; exit 2; }
gunzip -c "$DUMP" | docker compose exec -T db mariadb \
  -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"
