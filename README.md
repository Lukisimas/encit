# Arquitectura institucional ENCiT — dos servidores físicos / tres entornos

Este repositorio maestro contiene la configuración y los esqueletos de despliegue para la
infraestructura institucional de la Escuela Nacional de Ciencias de la Tierra (ENCiT).

## Direccionamiento vigente

| Recurso | Dirección |
|---|---|
| Servidor físico de control (DEV/TEST) | `10.129.100.2/28` — VLAN 50 |
| Gateway de VLAN 50 | `10.129.100.1` |
| Servidor físico de producción | `10.129.101.2/28` — VLAN 51 |
| Gateway de VLAN 51 | `10.129.101.1` |
| WAN OPNsense | `132.247.168.166/26` |
| Gateway WAN | `132.247.168.190` |

Las direcciones son las actualmente verificadas en la infraestructura ENCiT. Los cambios de
direccionamiento deben documentarse y validarse antes de modificar los servidores.

## Modelo de operación

- Servidor de control (`10.129.100.2`): Gitea, Registry, Jenkins, DEV y TEST.
- Servidor de producción (`10.129.101.2`): reverse proxy y aplicaciones productivas.
- OPNsense administra firewall, NAT, DNS interno/Unbound y WireGuard.
- El switch capa 3 administra la conectividad de las VLAN según la configuración aprobada.
- Un repositorio / stack independiente por sistema.
- Un solo Gitea y un solo Jenkins para toda la ENCiT.
- Producción nunca reconstruye imágenes: recibe exactamente la imagen validada en TEST.
- Las bases de datos no publican puertos hacia el host.
- Sólo los servicios web que reciben tráfico del proxy se conectan a la red Docker `edge`;
  workers y schedulers permanecen en sus redes internas.
- No se instala BIND en los servidores.

## Servicios y nombres

| Sistema | DEV | TEST | PROD |
|---|---|---|---|
| Portal | `web.dev.encit.unam.mx` | `web.test.encit.unam.mx` | `encit.unam.mx` |
| SIIA | `siia.dev.encit.unam.mx` | `siia.test.encit.unam.mx` | `siia.encit.unam.mx` |
| Revista Xitle (OJS) | `xitle.dev.encit.unam.mx` | `xitle.test.encit.unam.mx` | `xitle.encit.unam.mx` |
| Cursos | `cursos.dev.encit.unam.mx` | `cursos.test.encit.unam.mx` | `cursos.encit.unam.mx` |
| Moodle | `ec.dev.encit.unam.mx` | `ec.test.encit.unam.mx` | `ec.encit.unam.mx` |

Los nombres DEV y TEST son internos. El nombre público de la revista es
`xitle.encit.unam.mx`; `revista` se conserva únicamente como identificador interno del
repositorio, los stacks, los servicios y las rutas persistentes.

## DNS y publicación

- OPNsense/Unbound proporciona resolución interna para `dev.encit.unam.mx`,
  `test.encit.unam.mx` e `infra.encit.unam.mx`.
- Los nombres DEV, TEST e infraestructura no deben publicarse en DNS público.
- El registro público A de `xitle.encit.unam.mx` apunta a la WAN de OPNsense
  (`132.247.168.166`).
- OPNsense reenvía TCP/80 y TCP/443 hacia el servidor de producción (`10.129.101.2`).
- El certificado de Xitle se administra con Certbot/Let's Encrypt en el servidor de producción.

## Validación de publicación de Xitle

El estado reportado del registro DNS y las pruebas de resolución pública, conectividad HTTP/HTTPS y prerrequisitos de Certbot se documentan en [`docs/15_VALIDACION_PUBLICA_XITLE.md`](docs/15_VALIDACION_PUBLICA_XITLE.md). No solicitar el certificado hasta completar desde una red externa la resolución DNS y la prueba de acceso HTTP por TCP/80.

## Estructura

- `repos/infrastructure`: plataforma común, reverse proxies, Jenkins/Gitea y plantillas de red.
- `repos/infrastructure/network`: intención vendor-neutral para OPNsense y switch capa 3.
- `repos/web-deploy`: portal principal conservando su stack Docker independiente.
- `repos/siia`: Dockerización y modernización progresiva del SIIA.
- `repos/revista`: OJS DEV/TEST/PROD.
- `repos/cursos`: Astro DEV/TEST/PROD, incluyendo sitio y plantillas.
- `repos/moodle`: Moodle DEV/TEST/PROD.
- `docs`: arquitectura, red, seguridad, respaldos y plan de migración.
- `tools`: validación e inicialización.

## Orden recomendado

1. Validar OPNsense, VLAN, DNS interno y publicación de los servicios.
2. Plataforma común en el servidor de control.
3. Portal actual en DEV/TEST, retirando Jenkins de su Compose.
4. Incorporación y modernización gradual de SIIA.
5. OJS/Xitle.
6. Cursos Astro.
7. Moodle.
8. Actualizaciones tecnológicas del portal como proyecto separado.

## Advertencias

- No activar DHCP ENCiT hasta que DGTIC delegue formalmente los ámbitos correspondientes.
- No ejecutar ACL/firewall ni cambios de routing con valores no verificados.
- No almacenar `.env`, claves privadas, volcados o datos personales en Git.
- El código fuente actual del SIIA no fue proporcionado; el paquete contiene infraestructura y
  esqueleto de modernización, pero las dependencias reales deben inventariarse en la VM.
- La versión real de Redis utilizada por el portal debe inventariarse antes de fijarla.
