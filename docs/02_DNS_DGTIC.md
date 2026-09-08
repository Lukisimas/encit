# DNS, DHCP y coordinación con DGTIC

## Arquitectura objetivo

Los clientes ENCiT utilizarán DNS administrado en el equipo perimetral cuando el DHCP de las VLAN
haya sido delegado a ENCiT. El equipo perimetral resolverá las zonas privadas y reenviará cualquier
otra consulta hacia:

- `132.248.10.2`
- `132.248.204.1`

No se instala BIND en `10.10.10.20` ni `10.10.10.30`.

## Zonas privadas

Configurar en el equipo perimetral como Local DNS Zone / DNS Host Override / equivalente:

- `dev.encit.unam.mx`
- `test.encit.unam.mx`
- `infra.encit.unam.mx`

Preferentemente con wildcard `A -> 10.10.10.20`. Si el producto no admite wildcard local, crear
los registros explícitos definidos en `repos/infrastructure/network/dns-policy.example.yml`.

## Etapa transitoria si DGTIC conserva DHCP

Mientras los clientes continúen recibiendo `132.248.10.2` y `132.248.204.1` por DHCP, solicitar a
DGTIC reenvío condicional de las tres zonas privadas hacia **el IP DNS del equipo perimetral**, no
hacia `10.10.10.20`.

Esto permite usar DEV/TEST/INFRA sin modificar estaciones y sin instalar BIND.

## Después de delegar DHCP

El DHCP ENCiT entregará:

- gateway de cada VLAN según el diseño del switch L3;
- DNS interno del equipo perimetral;
- dominio de búsqueda institucional si se aprueba.

Cuando todos los clientes utilicen el DNS ENCiT, el reenvío condicional temporal de DGTIC puede
retirarse si ya no es necesario.

## DNS público

DGTIC continúa publicando únicamente servicios de producción:

- `encit.unam.mx`
- `siia.encit.unam.mx`
- `revista.encit.unam.mx`
- `cursos.encit.unam.mx`
- `ec.encit.unam.mx`

No crear una zona privada completa `encit.unam.mx`; sólo las tres subzonas internas.
