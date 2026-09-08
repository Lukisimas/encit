#!/usr/bin/env bash
set -euo pipefail
: "${MYSQL_ROOT_PASSWORD:?}"
: "${MYSQL_DATABASE:?}"
: "${BACKUP_DIR:?}"
mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
docker compose exec -T mysql mysqldump \
  --single-transaction --routines --triggers \
  -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" | gzip >"$BACKUP_DIR/mysql-$TS.sql.gz"
tar -C "${UPLOADS_DIR}" -czf "$BACKUP_DIR/uploads-$TS.tar.gz" . 2>/dev/null || true
sha256sum "$BACKUP_DIR"/*"$TS"* >"$BACKUP_DIR/SHA256SUMS-$TS"
echo "$BACKUP_DIR"
