# Secuencia inicial

## 0. Red

Antes de levantar la plataforma:

1. Configurar/probar DNS local en el equipo perimetral.
2. Verificar que `*.dev`, `*.test` y `*.infra` resuelvan a `10.10.10.20` desde una red autorizada.
3. Verificar routing/ACL entre las VLAN necesarias y `10.10.10.20`/`10.10.10.30`.
4. Mantener DHCP institucional hasta que DGTIC delegue formalmente los ámbitos.

Prueba directa contra el DNS perimetral:

```bash
./repos/infrastructure/network/check-internal-dns.sh <IP_DNS_INTERNO>
```

## Servidor control

```bash
sudo ./repos/infrastructure/bootstrap/install-docker-debian13.sh
sudo ./repos/infrastructure/bootstrap/prepare-control-host.sh
cd /srv/encit/platform/control
docker compose up -d
```

## Servidor producción

```bash
sudo ./repos/infrastructure/bootstrap/install-docker-debian13.sh
sudo ./repos/infrastructure/bootstrap/prepare-production-host.sh
cd /srv/encit/platform/production
docker compose up -d
```

Después crear repositorios y jobs de Jenkins siguiendo `docs/04_REPOSITORIOS_GITEA.md` y
`docs/05_JENKINS.md`.
