# Infrastructure

Plataforma común para todos los sistemas.

## Servidores

- `10.10.10.20`: Gitea, Jenkins, Registry, Mailpit, reverse proxy DEV/TEST y aplicaciones DEV/TEST.
- `10.10.10.30`: reverse proxy y aplicaciones productivas.

## Red

DNS, DHCP, gateways, VLAN y routing **no** viven en estos servidores. Se administran mediante el
equipo perimetral y el switch de capa 3.

La carpeta `network/` contiene la intención de configuración vendor-neutral que debe mapearse a la
marca/modelo real.

Copiar:

- `control/` -> `/srv/encit/platform/control`
- `production/` -> `/srv/encit/platform/production`

Las redes Docker externas `encit_control_edge` y `encit_prod_edge` se crean por los scripts
bootstrap.
