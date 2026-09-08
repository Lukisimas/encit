#!/usr/bin/env bash
set -euo pipefail
CERT="${1:-}"
if [[ -z "$CERT" || ! -f "$CERT" ]]; then
  echo "Uso: $0 /ruta/ENCiT-Internal-Root-CA.crt" >&2
  exit 1
fi
install -m 0644 "$CERT" /usr/local/share/ca-certificates/encit-internal-root-ca.crt
update-ca-certificates
systemctl restart docker || true
echo "CA interna instalada en el host."
