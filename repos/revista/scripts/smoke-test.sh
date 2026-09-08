#!/usr/bin/env bash
set -euo pipefail
URL="${1:?URL}"
curl -fsS --retry 10 --retry-delay 3 "$URL/" >/dev/null
curl -fsS --retry 10 --retry-delay 3 "$URL/index.php/index" >/dev/null || true
echo "OJS responde."
