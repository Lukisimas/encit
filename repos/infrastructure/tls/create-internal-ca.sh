#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-./internal-pki}"
mkdir -p "$OUT"
umask 077

openssl genrsa -out "$OUT/ENCiT-Internal-Root-CA.key" 4096
openssl req -x509 -new -sha256 -days 3650 \
  -key "$OUT/ENCiT-Internal-Root-CA.key" \
  -out "$OUT/ENCiT-Internal-Root-CA.crt" \
  -subj "/C=MX/O=UNAM/OU=ENCiT/CN=ENCiT Internal Root CA"

make_cert () {
  local zone="$1"
  local name="$2"
  local cfg="$OUT/${name}.cnf"
  cat >"$cfg" <<EOF
[req]
prompt=no
distinguished_name=dn
req_extensions=req_ext
[dn]
C=MX
O=UNAM
OU=ENCiT
CN=*.${zone}
[req_ext]
subjectAltName=@alt
[alt]
DNS.1=*.${zone}
DNS.2=${zone}
[ext]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt
EOF
  openssl genrsa -out "$OUT/${name}.key" 3072
  openssl req -new -key "$OUT/${name}.key" -out "$OUT/${name}.csr" -config "$cfg"
  openssl x509 -req -sha256 -days 825 \
    -in "$OUT/${name}.csr" \
    -CA "$OUT/ENCiT-Internal-Root-CA.crt" \
    -CAkey "$OUT/ENCiT-Internal-Root-CA.key" \
    -CAcreateserial \
    -out "$OUT/${name}.crt" \
    -extensions ext -extfile "$cfg"
}
make_cert "dev.encit.unam.mx" "wildcard-dev"
make_cert "test.encit.unam.mx" "wildcard-test"
make_cert "infra.encit.unam.mx" "wildcard-infra"

cat <<EOF
Certificados generados en: $OUT

IMPORTANTE:
1. Copiar los certificados/keys de servidor a /srv/encit/platform/control/certs/.
2. Distribuir SOLO ENCiT-Internal-Root-CA.crt a equipos autorizados.
3. Guardar ENCiT-Internal-Root-CA.key OFFLINE y retirarla del servidor.
EOF
