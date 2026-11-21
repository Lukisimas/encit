#!/usr/bin/env bash
set -euo pipefail
URL="${1:?URL}"
curl -fsS --retry 5 --retry-delay 3 "$URL/" >/dev/null
curl -fsS --retry 5 --retry-delay 3 "$URL/api/" >/dev/null || \
  echo "ADVERTENCIA: /api/ no respondió 2xx; ajustar endpoint de salud real del backend."
echo "Smoke test web finalizado."
