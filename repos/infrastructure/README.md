# Infrastructure

Plataforma común para todos los sistemas.

## Servidores

- `10.129.100.2` (VLAN 50): Gitea, Jenkins, Registry, Mailpit, reverse proxy DEV/TEST y
  aplicaciones DEV/TEST.
- `10.129.101.2` (VLAN 51): reverse proxy y aplicaciones productivas.

## Red

DNS interno, gateways, NAT y WireGuard se administran mediante OPNsense. La conectividad de
VLAN y el routing inter-VLAN siguen la configuración aprobada del switch capa 3.

La carpeta `network/` contiene la intención de configuración vendor-neutral que debe mapearse a
la configuración real de los equipos.

Copiar:

- `control/` -> `/srv/encit/platform/control`
- `production/` -> `/srv/encit/platform/production`

Las redes Docker externas `encit_control_edge` y `encit_prod_edge` se crean por los scripts
bootstrap.
