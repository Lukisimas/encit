#!/usr/bin/env bash
set -euo pipefail

DNS_SERVER="${1:-}"
if [[ -z "$DNS_SERVER" ]]; then
  echo "Uso: $0 <IP_DNS_INTERNO>" >&2
  exit 2
fi

names=(
  web.dev.encit.unam.mx
  siia.dev.encit.unam.mx
  revista.dev.encit.unam.mx
  cursos.dev.encit.unam.mx
  ec.dev.encit.unam.mx
  web.test.encit.unam.mx
  siia.test.encit.unam.mx
  revista.test.encit.unam.mx
  cursos.test.encit.unam.mx
  ec.test.encit.unam.mx
  git.infra.encit.unam.mx
  jenkins.infra.encit.unam.mx
  registry.infra.encit.unam.mx
  mail.infra.encit.unam.mx
)

command -v dig >/dev/null || { echo "Se requiere dig (dnsutils/bind-utils)." >&2; exit 1; }

for n in "${names[@]}"; do
  ip="$(dig +short A "$n" @"$DNS_SERVER" | tail -n1)"
  printf '%-40s -> %s\n' "$n" "${ip:-SIN RESPUESTA}"
  [[ "$ip" == "10.10.10.20" ]] || {
    echo "ERROR: $n debe resolver a 10.10.10.20" >&2
    exit 1
  }
done

# Prueba de forwarding: no se fuerza una IP concreta, sólo que exista respuesta.
if ! dig +short A www.unam.mx @"$DNS_SERVER" | grep -q .; then
  echo "ERROR: el forward DNS externo no respondió para www.unam.mx" >&2
  exit 1
fi

echo "DNS INTERNO: OK"
