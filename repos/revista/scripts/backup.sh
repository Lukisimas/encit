#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_DIR:?}"
mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
docker compose exec -T db mariadb-dump \
  -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" --single-transaction "$MARIADB_DATABASE" \
  | gzip >"$BACKUP_DIR/ojs-db-$TS.sql.gz"
tar -C "$OJS_FILES_DIR" -czf "$BACKUP_DIR/ojs-files-$TS.tar.gz" .
tar -C "$OJS_PUBLIC_DIR" -czf "$BACKUP_DIR/ojs-public-$TS.tar.gz" .
cp "$OJS_CONFIG_DIR/config.inc.php" "$BACKUP_DIR/config-$TS.inc.php"
sha256sum "$BACKUP_DIR"/*"$TS"* >"$BACKUP_DIR/SHA256SUMS-$TS"
