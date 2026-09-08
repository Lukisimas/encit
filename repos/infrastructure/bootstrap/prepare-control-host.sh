#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /srv/encit/{platform/control,apps,data,backups,config}
install -d -m 0755 /srv/encit/apps/{web,siia,revista,cursos,moodle}/{dev,test}
install -d -m 0750 /srv/encit/data/{gitea,jenkins}
install -d -m 0750 /srv/encit/backups/{web,siia,revista,cursos,moodle}

docker network inspect encit_control_edge >/dev/null 2>&1 || \
  docker network create encit_control_edge

echo "Host de control preparado."
