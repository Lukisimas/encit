# Red institucional ENCiT — equipo perimetral + switch de capa 3

Esta carpeta sustituye completamente la implementación BIND que antes estaba prevista en
`10.10.10.20`.

## Responsabilidades

### Equipo perimetral

Debe asumir, según las capacidades del modelo adquirido y la autorización de DGTIC:

- DNS local para `dev.encit.unam.mx`, `test.encit.unam.mx` e `infra.encit.unam.mx`.
- DNS recursivo/caché o DNS proxy para los clientes ENCiT.
- Forwarding hacia `132.248.10.2` y `132.248.204.1` para nombres que no pertenezcan a las zonas internas.
- DHCP de las VLAN ENCiT cuando DGTIC delegue los ámbitos.
- Políticas perimetrales de acceso y, si corresponde, NAT/routing institucional.

### Switch de capa 3

Debe asumir:

- VLAN de usuarios, administración y servidores según el diseño autorizado.
- SVI/default gateway de cada VLAN, si el diseño de red así lo establece.
- Enrutamiento inter-VLAN.
- ACL entre VLAN.
- DHCP relay hacia el equipo perimetral si éste aloja DHCP en una VLAN distinta.

## Lo que ya NO corre en 10.10.10.20

- BIND.
- DHCP.
- DNS autoritativo/recursivo.

`10.10.10.20` queda para Gitea, Jenkins, Registry, Mailpit, reverse proxy interno, DEV y TEST.

## Archivos

- `network-values.example.yml`: parámetros que deben completarse con Redes/DGTIC.
- `dns-policy.example.yml`: zonas internas, forwarders y registros deseados.
- `dhcp-policy.example.yml`: política DHCP vendor-neutral.
- `l3-switch-policy.example.txt`: intención de VLAN, SVI, ACL y relay.
- `perimeter-policy.example.txt`: intención de firewall/DNS/DHCP.
- `check-internal-dns.sh`: prueba funcional desde un equipo ENCiT.
- `MIGRACION_RED.md`: secuencia de transición sin afectar producción.

Estas plantillas describen intención. Deben traducirse a la sintaxis real del fabricante una vez
conocidos marca, modelo y versión del sistema operativo del equipo perimetral y del switch.
