#!/usr/bin/env bash
set -Eeuo pipefail

# UUID de /dev/sdb1: volumen ext4 del RAID5 HPE destinado a /data.
readonly EXPECTED_DATA_UUID="5d642b08-fac8-48fa-8f9b-5976c66af37c"
readonly DATA_MOUNT="/data"
readonly DATA_ROOT="${DATA_MOUNT}/encit"
readonly APP_ROOT="/srv/encit"
readonly APPS=(web siia revista cursos moodle)

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "${EUID}" -eq 0 ]] || fail "Ejecuta este script como root."
command -v docker >/dev/null 2>&1 || fail "Docker no está instalado."
command -v findmnt >/dev/null 2>&1 || fail "No se encontró findmnt."
command -v mountpoint >/dev/null 2>&1 || fail "No se encontró mountpoint."

mountpoint -q "$DATA_MOUNT" || fail "$DATA_MOUNT no está montado."
actual_uuid="$(findmnt -n -o UUID --target "$DATA_MOUNT" | tr -d '[:space:]')"
[[ "$actual_uuid" == "$EXPECTED_DATA_UUID" ]] ||
  fail "El UUID montado en $DATA_MOUNT no coincide con el volumen de datos esperado (obtenido: ${actual_uuid:-vacío})."

docker info >/dev/null 2>&1 || fail "El daemon de Docker no está disponible."

install -d -m 0755 \
  "$APP_ROOT/platform/production" \
  "$APP_ROOT/apps" \
  "$APP_ROOT/data" \
  "$APP_ROOT/config"

# Estado/certificados de Certbot: mantenerlos en el SSD y restringir acceso.
install -d -m 0700 "$APP_ROOT/platform/production/letsencrypt"

for app in "${APPS[@]}"; do
  install -d -m 0755 "$APP_ROOT/apps/$app/prod"
  install -d -m 0750 "$APP_ROOT/data/$app/prod"
done

install -d -m 0755 \
  "$DATA_ROOT/data" \
  "$DATA_ROOT/backups" \
  "$DATA_ROOT/archives"

for app in "${APPS[@]}"; do
  install -d -m 0750 "$DATA_ROOT/data/$app/prod"
  install -d -m 0750 "$DATA_ROOT/backups/$app/prod"
done

# Datos voluminosos: OJS y Moodle. Los propietarios/UID de contenedor
# se ajustarán después de validar las imágenes y los servicios.
install -d -m 0750 \
  "$DATA_ROOT/data/revista/prod/files" \
  "$DATA_ROOT/data/revista/prod/public" \
  "$DATA_ROOT/data/moodle/prod/moodledata"

docker network inspect encit_prod_edge >/dev/null 2>&1 ||
  docker network create encit_prod_edge >/dev/null

printf 'Host de producción preparado.\n'
