#!/usr/bin/env bash
set -Eeuo pipefail

# UUID de /dev/sdb1: volumen ext4 del RAID5 HPE destinado a /data.
readonly EXPECTED_DATA_UUID="5d642b08-fac8-48fa-8f9b-5976c66af37c"
readonly DATA_MOUNT="/data"
readonly DATA_ROOT="${DATA_MOUNT}/encit"
readonly APP_ROOT="/srv/encit"
readonly APPS=(web siia revista cursos moodle)

# La imagen OJS parte de php:8.3-apache-bookworm, donde www-data es 33:33.
# Fallar explícitamente si la identidad del host deja de coincidir.
readonly OJS_UID="33"
readonly OJS_GID="33"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "${EUID}" -eq 0 ]] || fail "Ejecuta este script como root."
command -v docker >/dev/null 2>&1 || fail "Docker no está instalado."
command -v findmnt >/dev/null 2>&1 || fail "No se encontró findmnt."
command -v mountpoint >/dev/null 2>&1 || fail "No se encontró mountpoint."
command -v getent >/dev/null 2>&1 || fail "No se encontró getent."

mountpoint -q "$DATA_MOUNT" || fail "$DATA_MOUNT no está montado."
actual_uuid="$(findmnt -n -o UUID --target "$DATA_MOUNT" | tr -d '[:space:]')"
[[ "$actual_uuid" == "$EXPECTED_DATA_UUID" ]] ||
  fail "El UUID montado en $DATA_MOUNT no coincide con el volumen de datos esperado (obtenido: ${actual_uuid:-vacío})."

docker info >/dev/null 2>&1 || fail "El daemon de Docker no está disponible."

host_ojs_uid="$(getent passwd www-data | cut -d: -f3)"
host_ojs_gid="$(getent passwd www-data | cut -d: -f4)"
[[ "$host_ojs_uid" == "$OJS_UID" && "$host_ojs_gid" == "$OJS_GID" ]] ||
  fail "www-data en el host debe ser ${OJS_UID}:${OJS_GID}; se obtuvo ${host_ojs_uid}:${host_ojs_gid}."

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

# Los directorios padre permiten traversal al grupo www-data, pero no escritura.
# Las hojas OJS quedan a nombre de www-data; MariaDB conserva su gestión propia.
install -d -o root -g "$OJS_GID" -m 0750 \
  "$APP_ROOT/data/revista" \
  "$APP_ROOT/data/revista/prod" \
  "$DATA_ROOT/data/revista" \
  "$DATA_ROOT/data/revista/prod"

# OJS: los directorios montados sobre rutas de escritura de Apache/PHP
# deben pertenecer al usuario www-data de la imagen (UID/GID 33:33).
# No se asigna propietario a MariaDB aquí: su UID/GID se valida en la imagen
# mariadb:11.8 antes del primer arranque.
install -d -o "$OJS_UID" -g "$OJS_GID" -m 0750 \
  "$APP_ROOT/data/revista/prod/config" \
  "$APP_ROOT/data/revista/prod/cache" \
  "$DATA_ROOT/data/revista/prod/files" \
  "$DATA_ROOT/data/revista/prod/public"

# MariaDB usa un directorio dedicado en SSD; su entrypoint inicializa y
# ajusta la propiedad del volumen según el usuario mysql de la imagen.
install -d -m 0750 "$APP_ROOT/data/revista/prod/mariadb"

# Moodle conserva sus archivos voluminosos en RAID5.
install -d -m 0750 "$DATA_ROOT/data/moodle/prod/moodledata"

docker network inspect encit_prod_edge >/dev/null 2>&1 ||
  docker network create encit_prod_edge >/dev/null

printf 'Host de producción preparado.\n'
