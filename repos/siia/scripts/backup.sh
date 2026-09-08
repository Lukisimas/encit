#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_DIR:?}"
mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
docker compose exec -T db pg_dump -Fc -U "$POSTGRES_USER" "$POSTGRES_DB" \
  >"$BACKUP_DIR/siia-$TS.dump"
sha256sum "$BACKUP_DIR/siia-$TS.dump" >"$BACKUP_DIR/siia-$TS.dump.sha256"
