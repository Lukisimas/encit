#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE="${1:?control|production}"

install -d -m 0755 /srv/encit/config/web
cp "$ROOT/repos/web-deploy/deploy/nginx/default.conf.template" /srv/encit/config/web/default.conf.template
if [[ ! -f /srv/encit/config/web/redis.conf ]]; then
  cp "$ROOT/repos/web-deploy/config/redis.conf.example" /srv/encit/config/web/redis.conf
fi
if [[ ! -f /srv/encit/config/web/users.acl ]]; then
  cp "$ROOT/repos/web-deploy/config/users.acl.example" /srv/encit/config/web/users.acl
  echo "ADVERTENCIA: edite /srv/encit/config/web/users.acl con el inventario real antes de levantar Redis."
fi
install -d -m 0755 /srv/encit/config/web/sql-scripts

copy_env () {
  local app="$1" src="$2" dst="$3"
  install -d -m 0755 "$dst"
  cp "$src/docker-compose.yml" "$dst/docker-compose.yml"
  if [[ ! -f "$dst/.env" ]]; then
    cp "$src/.env.example" "$dst/.env"
    chmod 0600 "$dst/.env"
  fi
  if [[ -d "$ROOT/repos/$app/scripts" ]]; then
    rm -rf "$dst/scripts"
    cp -a "$ROOT/repos/$app/scripts" "$dst/scripts"
  fi
  if [[ -d "$ROOT/repos/$app/config" ]]; then
    rm -rf "$dst/config"
    cp -a "$ROOT/repos/$app/config" "$dst/config"
  fi
}

if [[ "$ROLE" == control ]]; then
  install -d /srv/encit/platform/control
  cp -a "$ROOT/repos/infrastructure/control/." /srv/encit/platform/control/
  copy_env web-deploy "$ROOT/repos/web-deploy/deploy/development" /srv/encit/apps/web/dev
  copy_env web-deploy "$ROOT/repos/web-deploy/deploy/testing" /srv/encit/apps/web/test
  copy_env siia "$ROOT/repos/siia/deploy/development" /srv/encit/apps/siia/dev
  copy_env siia "$ROOT/repos/siia/deploy/testing" /srv/encit/apps/siia/test
  copy_env revista "$ROOT/repos/revista/deploy/development" /srv/encit/apps/revista/dev
  copy_env revista "$ROOT/repos/revista/deploy/testing" /srv/encit/apps/revista/test
  copy_env cursos "$ROOT/repos/cursos/deploy/development" /srv/encit/apps/cursos/dev
  copy_env cursos "$ROOT/repos/cursos/deploy/testing" /srv/encit/apps/cursos/test
  copy_env moodle "$ROOT/repos/moodle/deploy/development" /srv/encit/apps/moodle/dev
  copy_env moodle "$ROOT/repos/moodle/deploy/testing" /srv/encit/apps/moodle/test
elif [[ "$ROLE" == production ]]; then
  install -d /srv/encit/platform/production
  cp -a "$ROOT/repos/infrastructure/production/." /srv/encit/platform/production/
  copy_env web-deploy "$ROOT/repos/web-deploy/deploy/production" /srv/encit/apps/web/prod
  copy_env siia "$ROOT/repos/siia/deploy/production" /srv/encit/apps/siia/prod
  copy_env revista "$ROOT/repos/revista/deploy/production" /srv/encit/apps/revista/prod
  copy_env cursos "$ROOT/repos/cursos/deploy/production" /srv/encit/apps/cursos/prod
  copy_env moodle "$ROOT/repos/moodle/deploy/production" /srv/encit/apps/moodle/prod
else
  echo "ROLE debe ser control o production" >&2; exit 2
fi
echo "Estructura $ROLE instalada. Edite todos los .env antes de levantar servicios."
