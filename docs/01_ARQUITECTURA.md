# Arquitectura

```text
                         DGTIC / INTERNET
                               |
                         Equipo perimetral
                    DNS / DHCP* / Firewall
                               |
                         Switch capa 3
                   VLAN / SVI / routing / ACL
                               |
             +-----------------+-----------------+
             |                                   |
        10.10.10.20                         10.10.10.30
     CONTROL / DEV / TEST                       PROD
             |                                   |
     +-------+--------+                   +------+--------------------+
     |       |        |                   |      |      |      |     |
   Gitea   Jenkins  Registry             Web    SIIA   OJS   Cursos Moodle
     |       |
   CI/CD   DEV + TEST
           Web / SIIA / OJS / Cursos / Moodle
```

`*` DHCP sólo después de delegación formal de ámbitos por DGTIC.

## DNS interno

El equipo perimetral aloja/representa las zonas locales:

- `dev.encit.unam.mx` -> wildcard `10.10.10.20`
- `test.encit.unam.mx` -> wildcard `10.10.10.20`
- `infra.encit.unam.mx` -> wildcard `10.10.10.20`

No existe BIND en `10.10.10.20`.

## Redes Docker

- `encit_control_edge`: reverse proxy del servidor de control y frontends DEV/TEST.
- `encit_prod_edge`: reverse proxy de producción y frontends PROD.
- Cada stack crea además una red `internal` no accesible desde otras aplicaciones.

## Persistencia

Los datos persistentes se guardan bajo `/srv/encit/data/<app>/<entorno>`.
Los archivos de despliegue se guardan bajo `/srv/encit/apps/<app>/<entorno>`.

## Separación de capas

La red física (perimetral + switch L3) no depende del ciclo de vida de Docker. Reiniciar Jenkins,
Gitea o cualquier stack no afecta DNS, DHCP, gateways ni routing de la ENCiT.
