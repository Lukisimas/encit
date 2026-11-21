#!/usr/bin/env bash
set -euo pipefail
echo "Ejecutar sólo tras backup y ensayo en TEST."
docker compose stop cron
docker compose run --rm web php admin/cli/maintenance.php --enable
docker compose run --rm web php admin/cli/upgrade.php --non-interactive
docker compose run --rm web php admin/cli/maintenance.php --disable
docker compose up -d web cron
