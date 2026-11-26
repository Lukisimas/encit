#!/usr/bin/env bash
set -Eeuo pipefail

# UUID de /dev/sdb1: volumen ext4 del RAID5 HPE destinado a /data.
readonly EXPECTED_DATA_UUID="5d642b08-fac8-48fa-8f9b-5976c66af37c"
readonly DATA_MOUNT="/data"
readonly DATA_ROOT="${DATA_MOUNT}/encit"
readonly APP_ROOT="/srv/encit"
readonly APPS=(web siia revista cursos moodle)
readonly DEPLOY_USER="deploy"
readonly DEPLOY_GROUP="deploy"
readonly DOCKER_GROUP="docker"

# La imagen OJS parte de php:8.3-apache-bookworm, donde www-data es 33:33.
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
command -v id >/dev/null 2>&1 || fail "No se encontró id."

mountpoint -q "$DATA_MOUNT" || fail "$DATA_MOUNT no está montado."
actual_uuid="$(findmnt -n -o UUID --target "$DATA_MOUNT" | tr -d '[:space:]')"
[[ "$actual_uuid" == "$EXPECTED_DATA_UUID" ]] ||
  fail "El UUID montado en $DATA_MOUNT no coincide con el volumen de datos esperado (obtenido: ${actual_uuid:-vacío})."

docker info >/dev/null 2>&1 || fail "El daemon de Docker no está disponible."

# deploy es una identidad operativa preaprovisionada: no crearla aquí porque
# su acceso SSH requiere una clave pública autorizada y una decisión explícita.
getent passwd "$DEPLOY_USER" >/dev/null ||
  fail "No existe el usuario $DEPLOY_USER. Créalo y configura su acceso SSH antes del bootstrap."
getent group "$DEPLOY_GROUP" >/dev/null ||
  fail "No existe el grupo $DEPLOY_GROUP."
getent group "$DOCKER_GROUP" >/dev/null ||
  fail "No existe el grupo $DOCKER_GROUP; instala Docker correctamente."
id -nG "$DEPLOY_USER" | tr ' ' '\n' | grep -Fxq "$DOCKER_GROUP" ||
  fail "El usuario $DEPLOY_USER no pertenece al grupo $DOCKER_GROUP. Revisa conscientemente este privilegio equivalente a root."

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
  # Los pipelines Jenkins se conectan como deploy. 0700 evita que otros
  # usuarios lean respaldos; deploy puede crearlos y endurecerlos a 0700.
  install -d -o "$DEPLOY_USER" -g "$DEPLOY_GROUP" -m 0700 \
    "$DATA_ROOT/backups/$app/prod"
done

# Los directorios padre permiten traversal al grupo www-data, pero no escritura.
install -d -o root -g "$OJS_GID" -m 0750 \
  "$APP_ROOT/data/revista" \
  "$APP_ROOT/data/revista/prod" \
  "$DATA_ROOT/data/revista" \
  "$DATA_ROOT/data/revista/prod"

# OJS: directorios de escritura de Apache/PHP (UID/GID 33:33).
install -d -o "$OJS_UID" -g "$OJS_GID" -m 0750 \
  "$APP_ROOT/data/revista/prod/config" \
  "$APP_ROOT/data/revista/prod/cache" \
  "$DATA_ROOT/data/revista/prod/files" \
  "$DATA_ROOT/data/revista/prod/public"

# MariaDB administra su propiedad durante el primer arranque.
install -d -m 0750 "$APP_ROOT/data/revista/prod/mariadb"

# Moodle conserva sus archivos voluminosos en RAID5.
install -d -m 0750 "$DATA_ROOT/data/moodle/prod/moodledata"

docker network inspect encit_prod_edge >/dev/null 2>&1 ||
  docker network create encit_prod_edge >/dev/null

printf 'Host de producción preparado. Usuario deploy validado; respaldos propiedad de deploy:deploy (0700).\n'
