# Equipo perimetral y switch de capa 3

## Objetivo

Sacar completamente DNS/DHCP de los servidores físicos y administrar la red ENCiT en equipos
dedicados de infraestructura.

## Equipo perimetral

Responsabilidades objetivo:

- DNS local de DEV/TEST/INFRA.
- Forwarding a DNS institucionales.
- DHCP únicamente para ámbitos delegados por DGTIC.
- firewall/NAT/routing perimetral según diseño institucional.
- logs y respaldos de configuración.

## Switch capa 3

Responsabilidades objetivo:

- VLAN y SVI.
- gateway por VLAN cuando corresponda.
- routing inter-VLAN.
- ACL de segmentación.
- DHCP relay hacia el equipo perimetral.

## Principio de seguridad

DEV/TEST/INFRA no deben ser accesibles desde Internet. Gitea/Jenkins deben restringirse todavía
más a VLAN administrativas o usuarios autorizados.

## Importante

La compra del equipo no implica por sí misma que ENCiT pueda activar un nuevo DHCP en las VLAN.
La delegación/retirada del DHCP institucional debe coordinarse con DGTIC para evitar dos servidores
DHCP concurrentes.

Consultar `repos/infrastructure/network/MIGRACION_RED.md` para la secuencia de transición.
