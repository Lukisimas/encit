#!/usr/bin/env bash
set -euo pipefail
DUMP="${1:?archivo .sql.gz}"
[[ "${CONFIRM_RESTORE:-}" == "YES" ]] || { echo "export CONFIRM_RESTORE=YES"; exit 2; }
gunzip -c "$DUMP" | docker compose exec -T mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"
