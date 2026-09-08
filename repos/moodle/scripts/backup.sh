#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_DIR:?}"
mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
docker compose exec -T db mariadb-dump \
  -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" --single-transaction "$MARIADB_DATABASE" \
  | gzip >"$BACKUP_DIR/moodle-db-$TS.sql.gz"
tar -C "$MOODLEDATA_DIR" -czf "$BACKUP_DIR/moodledata-$TS.tar.gz" .
cp "$MOODLE_CONFIG_DIR/config.php" "$BACKUP_DIR/config-$TS.php"
sha256sum "$BACKUP_DIR"/*"$TS"* >"$BACKUP_DIR/SHA256SUMS-$TS"
