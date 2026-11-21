#!/usr/bin/env bash
set -euo pipefail
URL="${1:?URL}"
curl -fsS --retry 10 --retry-delay 3 "$URL/healthz"
echo
