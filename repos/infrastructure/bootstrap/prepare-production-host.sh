#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /srv/encit/{platform/production,apps,data,backups,config}
for app in web siia revista cursos moodle; do
  install -d -m 0755 "/srv/encit/apps/${app}/prod"
  install -d -m 0750 "/srv/encit/data/${app}/prod"
  install -d -m 0750 "/srv/encit/backups/${app}/prod"
done

docker network inspect encit_prod_edge >/dev/null 2>&1 || \
  docker network create encit_prod_edge

echo "Host de producción preparado."
