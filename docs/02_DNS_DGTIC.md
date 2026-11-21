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

DGTIC continúa publicando únicamente servicios de producción, con los nombres confirmados:

- `encit.unam.mx`
- `siia.encit.unam.mx`
- `xitle.encit.unam.mx`
- `cursos.encit.unam.mx`
- `ec.encit.unam.mx`

No crear una zona privada completa `encit.unam.mx`; sólo las tres subzonas internas.

## Validación de autoridad DNS (20 de noviembre de 2026)

Se ejecutó desde Windows:

```text
nslookup -type=ns xitle.encit.unam.mx 8.8.8.8
```

La respuesta mostró el SOA de `unam.mx`, con servidor primario `ns1.unam.mx`, correo
responsable `dns.unam.mx` y serial `2026112001`. Esto indica que la consulta se atendió en el
contexto de la zona padre `unam.mx`; **no demuestra por sí sola que el registro A/AAAA de
`xitle.encit.unam.mx` exista o apunte a la IP pública de OPNsense**. Como `xitle.encit.unam.mx`
es un nombre de host y no se ha solicitado una delegación de subzona, la consulta NS no es la
prueba apropiada para confirmar su publicación.

Pendiente comprobar el registro de dirección y conectividad:

```text
nslookup -type=a xitle.encit.unam.mx 8.8.8.8
nslookup -type=aaaa xitle.encit.unam.mx 8.8.8.8
```

Si se usa IPv6, confirmar también que exista ruta y publicación funcional. Antes de emitir el
certificado Let's Encrypt, confirmar el A (y cualquier AAAA publicado) y la llegada de TCP/80 desde
Internet al proxy de producción.
