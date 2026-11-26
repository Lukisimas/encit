# DNS, DHCP y coordinación con DGTIC

## Arquitectura objetivo

Los clientes ENCiT utilizarán DNS administrado en el equipo perimetral cuando el DHCP de las VLAN
haya sido delegado a ENCiT. El equipo perimetral resolverá las zonas privadas y reenviará cualquier
otra consulta hacia:

- `132.248.10.2`
- `132.248.204.1`

No se instala BIND en los servidores de control ni de producción.

## Zonas privadas

Configurar en el equipo perimetral como Local DNS Zone / DNS Host Override / equivalente:

- `dev.encit.unam.mx`
- `test.encit.unam.mx`
- `infra.encit.unam.mx`

Preferentemente con wildcard `A -> 10.129.100.2`. Si el producto no admite wildcard local, crear
los registros explícitos definidos en `repos/infrastructure/network/dns-policy.example.yml`.

## Etapa transitoria si DGTIC conserva DHCP

Mientras los clientes continúen recibiendo `132.248.10.2` y `132.248.204.1` por DHCP, solicitar a
DGTIC reenvío condicional de las tres zonas privadas hacia **el IP DNS del equipo perimetral**, no
hacia la IP de los servidores.
Esto permite usar DEV/TEST/INFRA sin modificar estaciones y sin instalar BIND.

## Después de delegar DHCP

El DHCP ENCiT entregará:

- gateway de cada VLAN según el diseño;
- DNS interno del equipo perimetral;
- dominio de búsqueda institucional si se aprueba.

Cuando todos los clientes utilicen el DNS ENCiT, el reenvío condicional temporal de DGTIC puede
retirarse si ya no es necesario.

## DNS público

DGTIC continúa publicando los nombres públicos de los servicios productivos:

- `encit.unam.mx`
- `siia.encit.unam.mx`
- `xitle.encit.unam.mx`
- `cursos.encit.unam.mx`
- `ec.encit.unam.mx`

**Estado de Xitle al 26 de noviembre de 2026:** el administrador confirma que el registro público
A de `xitle.encit.unam.mx` ya fue creado y apunta a `132.247.168.166`, la IP WAN de OPNsense.
Esta es una confirmación operativa reportada por el administrador; la evidencia de consultas DNS
desde resolvers externos debe conservarse como parte de la validación de publicación.

La publicación del registro A no acredita por sí sola que el servicio HTTP sea alcanzable. OPNsense
debe traducir TCP/80 y TCP/443 hacia el servidor de producción `10.129.101.2`, y las reglas de
firewall deben permitir el tráfico correspondiente.

No crear una zona privada completa `encit.unam.mx`; sólo las tres subzonas internas. Los nombres
DEV, TEST e infraestructura no deben publicarse en DNS público.

## Validación DNS y conectividad de Xitle

Ejecutar desde una estación con acceso a Internet:

```bash
dig +short A xitle.encit.unam.mx @1.1.1.1
dig +short A xitle.encit.unam.mx @8.8.8.8
dig +short AAAA xitle.encit.unam.mx @1.1.1.1
```

El resultado A esperado es `132.247.168.166`. Si existe un registro AAAA, comprobar que la
conectividad IPv6 esté configurada y llegue al servicio; no mantener un AAAA que apunte a una ruta
no funcional.

Después, comprobar desde una red externa que TCP/80 sea accesible y llegue al proxy de producción.
Esta prueba es requisito para la validación HTTP-01 de Let's Encrypt. La consulta NS del nombre de
host no sustituye la comprobación A/AAAA.
