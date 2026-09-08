#!/usr/bin/env bash
set -euo pipefail
echo "Ejecutar SOLO después de respaldo y ensayo en TEST."
docker compose stop worker scheduler
docker compose run --rm web php tools/upgrade.php check
docker compose run --rm web php tools/upgrade.php upgrade
docker compose up -d web worker scheduler
