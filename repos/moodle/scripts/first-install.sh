#!/usr/bin/env bash
set -euo pipefail
# Ejecutar una sola vez tras crear config.php y levantar db.
# La contraseña se solicita/inyecta mediante variable para no guardarla en Git.
: "${MOODLE_ADMIN_PASSWORD:?export MOODLE_ADMIN_PASSWORD=...}"
: "${MOODLE_ADMIN_EMAIL:?}"
docker compose run --rm web php admin/cli/install_database.php \
  --agree-license \
  --adminuser=admin \
  --adminpass="$MOODLE_ADMIN_PASSWORD" \
  --adminemail="$MOODLE_ADMIN_EMAIL" \
  --fullname="Educación Continua ENCiT" \
  --shortname="ENCiT EC"
