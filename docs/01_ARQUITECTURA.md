# Arquitectura

## Topología física y ambientes

```text
                         DGTIC / INTERNET
                               |
                         OPNsense
                  Firewall / NAT / WireGuard
                               |
                         Switch capa 3
                   VLAN / SVI / routing / ACL
                               |
             +-----------------+-----------------+
             |                                   |
       VLAN 50 - TEST                       VLAN 51 - PROD
        10.129.100.0/28                     10.129.101.0/28
             |                                   |
       10.129.100.2                         10.129.101.2
     CONTROL / DEV / TEST                       PROD
             |                                   |
     +-------+--------+                   +------+--------------------+
     |       |        |                   |      |      |      |     |
   Gitea   Jenkins  Registry             Web    SIIA   Xitle Cursos Moodle
     |       |
   CI/CD   DEV + TEST
           Web / SIIA / Xitle / Cursos / Moodle
```

El servidor de control aloja Gitea, Jenkins, el registro de imágenes y los ambientes DEV y TEST. El servidor de producción aloja los servicios productivos y su proxy inverso. Las direcciones indicadas son las interfaces de los servidores dentro de sus respectivas VLAN; las puertas de enlace son administradas por OPNsense.

## Ambientes y nombres DNS

| Servicio | DEV (interno) | TEST (interno) | PROD |
|---|---|---|---|
| Sitio web | `web.dev.encit.unam.mx` | `web.test.encit.unam.mx` | `encit.unam.mx` |
| SIIA | `siia.dev.encit.unam.mx` | `siia.test.encit.unam.mx` | `siia.encit.unam.mx` |
| Revista Xitle (OJS) | `xitle.dev.encit.unam.mx` | `xitle.test.encit.unam.mx` | `xitle.encit.unam.mx` |
| Cursos | `cursos.dev.encit.unam.mx` | `cursos.test.encit.unam.mx` | `cursos.encit.unam.mx` |
| Moodle / Educación continua | `ec.dev.encit.unam.mx` | `ec.test.encit.unam.mx` | `ec.encit.unam.mx` |

Los nombres DEV y TEST son de uso interno. El nombre público de OJS es `xitle.encit.unam.mx`; reemplaza a `revista.encit.unam.mx`. El nombre interno del repositorio y de los stacks OJS permanece como `revista` para evitar renombrados innecesarios de componentes.

## DNS interno

OPNsense/Unbound proporciona resolución para las zonas locales:

- `dev.encit.unam.mx` -> wildcard `10.129.100.2`
- `test.encit.unam.mx` -> wildcard `10.129.100.2`
- `infra.encit.unam.mx` -> wildcard `10.129.100.2`

Los nombres de DEV, TEST e infraestructura no deben publicarse en DNS público. No existe BIND en el servidor de control.

El DNS público de los servicios productivos se administra conforme a la delegación institucional. El tráfico HTTP/HTTPS público llega a OPNsense y se traduce hacia el servidor de producción (`10.129.101.2`).

## Redes Docker

- `encit_control_edge`: reverse proxy del servidor de control y frontends DEV/TEST.
- `encit_prod_edge`: reverse proxy de producción y frontends PROD.
- Cada stack crea además una red interna no accesible desde otras aplicaciones.

## Persistencia y almacenamiento

Los archivos de despliegue y configuración operativa se guardan bajo `/srv/encit/apps/<app>/<entorno>`. Los datos de baja latencia (bases de datos, configuración de aplicaciones y cachés) se alojan bajo `/srv/encit/data/<app>/<entorno>`, en el SSD RAID1.

Los archivos voluminosos y respaldos locales de producción se alojan en el RAID5 montado en `/data`, bajo `/data/encit/data/<app>/prod` y `/data/encit/backups/<app>/prod`, respectivamente. El detalle del hardware, sistema de archivos y rutas se documenta en [Almacenamiento de producción](13_ALMACENAMIENTO_PRODUCCION.md).

## Separación de capas

La red física (OPNsense + switch capa 3) no depende del ciclo de vida de Docker. Reiniciar Jenkins, Gitea o cualquier stack no afecta DNS, gateways ni routing de la ENCiT.
