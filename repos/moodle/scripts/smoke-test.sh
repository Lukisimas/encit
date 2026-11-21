#!/usr/bin/env bash
set -euo pipefail
URL="${1:?URL}"
curl -fsS --retry 10 --retry-delay 3 "$URL/" >/dev/null
curl -fsS --retry 10 --retry-delay 3 "$URL/login/index.php" >/dev/null
echo "Moodle responde."
