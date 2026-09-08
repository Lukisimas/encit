#!/usr/bin/env bash
set -euo pipefail
echo "=== Docker ==="
docker version || true
docker compose version || true
echo "=== Contenedores ==="
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
echo "=== Imágenes Redis ==="
docker inspect redis-encit-server redis-local-server \
  --format '{{.Name}} image={{.Config.Image}} id={{.Image}}' 2>/dev/null || true
echo "=== Redis INFO ==="
for c in redis-encit-server redis-local-server; do
  echo "--- $c"
  docker exec "$c" redis-server --version 2>/dev/null || true
done
echo "=== MySQL ==="
docker exec mysql-encit-server mysql --version 2>/dev/null || true
echo "=== Backend Java ==="
docker exec encit-back-end java -version 2>&1 || true
echo "=== Frontend image metadata ==="
docker inspect encit-front-end --format '{{json .Config.Env}}' 2>/dev/null | jq . || true
echo "Guardar esta salida antes de cambiar la infraestructura."
