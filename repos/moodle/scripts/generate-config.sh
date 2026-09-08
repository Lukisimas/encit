#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="${1:-.env}"
set -a; source "$ENV_FILE"; set +a
mkdir -p "$MOODLE_CONFIG_DIR" "$MOODLEDATA_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../config/config.php.template"
sed \
  -e "s|__DB_NAME__|${MARIADB_DATABASE}|g" \
  -e "s|__DB_USER__|${MARIADB_USER}|g" \
  -e "s|__DB_PASS__|${MARIADB_PASSWORD//|/\\|}|g" \
  -e "s|__WWWROOT__|${PUBLIC_BASE_URL}|g" \
  "$TEMPLATE" >"$MOODLE_CONFIG_DIR/config.php"
chmod 0640 "$MOODLE_CONFIG_DIR/config.php"
echo "$MOODLE_CONFIG_DIR/config.php"
