#!/usr/bin/env bash
set -euo pipefail
DIR="${1:?directorio compose}"
cd "$DIR"
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
