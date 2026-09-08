#!/usr/bin/env bash
set -euo pipefail
DB="${1:?base de datos}"
OUT="${2:-./siia-db-export}"
mkdir -p "$OUT"
TS="$(date +%Y%m%d-%H%M%S)"
sudo -u postgres pg_dump -Fc --no-owner --no-acl "$DB" >"$OUT/${DB}-${TS}.dump"
sudo -u postgres pg_dumpall --globals-only >"$OUT/globals-${TS}.sql"
sha256sum "$OUT"/*"$TS"* >"$OUT/SHA256SUMS-${TS}"
echo "$OUT"
