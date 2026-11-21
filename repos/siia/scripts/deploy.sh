#!/usr/bin/env bash
set -euo pipefail
DIR="${1:?directorio}"
cd "$DIR"
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
