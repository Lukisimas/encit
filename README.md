# Arquitectura institucional ENCiT — dos servidores físicos / tres entornos

Este repositorio maestro contiene la configuración y los esqueletos de despliegue para la
infraestructura institucional de la Escuela Nacional de Ciencias de la Tierra (ENCiT).

## Supuestos de red utilizados en los ejemplos

| Recurso | IP / nombre |
|---|---|
| Servidor físico de control | `10.10.10.20` |
| Servidor físico de producción | `10.10.10.30` |
| Gateway actual usado en el ejemplo | `10.10.10.40` |
| DNS institucional 1 | `132.248.10.2` |
| DNS institucional 2 | `132.248.204.1` |
| Equipo perimetral | `<IP_EQUIPO_PERIMETRAL>` |
| Switch capa 3 | `<IP_GESTION_SWITCH_L3>` |

**Sustituir valores de ejemplo por los aprobados por Redes/DGTIC antes de aplicar configuraciones.**

## Modelo de operación

- Servidor 1 (`10.10.10.20`): control, Gitea, Registry, Jenkins, DEV y TEST.
- Servidor 2 (`10.10.10.30`): producción.
- Equipo perimetral: DNS interno, forwarding DNS, firewall y DHCP cuando los ámbitos sean delegados.
- Switch de capa 3: VLAN/SVI, routing inter-VLAN, ACL y DHCP relay cuando aplique.
- Un repositorio / stack independiente por sistema.
- Un solo Gitea y un solo Jenkins para toda la ENCiT.
- Producción nunca reconstruye imágenes: recibe exactamente la imagen validada en TEST.
- Las bases de datos no publican puertos hacia el host.
- Las aplicaciones sólo comparten la red `edge`; sus redes internas son independientes.
- **No se instala BIND ni DHCP en `10.10.10.20` o `10.10.10.30`.**

## Servicios

| Sistema | DEV | TEST | PROD |
|---|---|---|---|
| Portal | `web.dev.encit.unam.mx` | `web.test.encit.unam.mx` | `encit.unam.mx` |
| SIIA | `siia.dev.encit.unam.mx` | `siia.test.encit.unam.mx` | `siia.encit.unam.mx` |
| Revista | `revista.dev.encit.unam.mx` | `revista.test.encit.unam.mx` | `revista.encit.unam.mx` |
| Cursos | `cursos.dev.encit.unam.mx` | `cursos.test.encit.unam.mx` | `cursos.encit.unam.mx` |
| Moodle | `ec.dev.encit.unam.mx` | `ec.test.encit.unam.mx` | `ec.encit.unam.mx` |

Infraestructura interna:

- `git.infra.encit.unam.mx`
- `jenkins.infra.encit.unam.mx`
- `registry.infra.encit.unam.mx`
- `mail.infra.encit.unam.mx`

## DNS / DHCP

Las zonas privadas viven en el **equipo perimetral**, no en los servidores:

- `dev.encit.unam.mx`
- `test.encit.unam.mx`
- `infra.encit.unam.mx`

Cada zona puede usar wildcard hacia `10.10.10.20`. Nginx del servidor de control enruta el
hostname al stack correcto.

Mientras DHCP siga bajo DGTIC, el equipo perimetral puede ponerse en servicio como DNS interno y
DGTIC reenviar condicionalmente esas tres zonas hacia él. Cuando los ámbitos DHCP sean delegados,
el DHCP ENCiT entregará directamente el DNS del equipo perimetral y éste reenviará el resto de
consultas a `132.248.10.2` y `132.248.204.1`.

## Estructura

- `repos/infrastructure`: plataforma común, reverse proxies, Jenkins/Gitea y plantillas de red.
- `repos/infrastructure/network`: intención vendor-neutral para equipo perimetral y switch capa 3.
- `repos/web-deploy`: portal principal conservando su stack Docker independiente.
- `repos/siia`: Dockerización y modernización progresiva del SIIA.
- `repos/revista`: OJS DEV/TEST/PROD.
- `repos/cursos`: Astro DEV/TEST/PROD, incluyendo sitio y plantillas.
- `repos/moodle`: Moodle DEV/TEST/PROD.
- `docs`: arquitectura, red, seguridad, respaldos y plan de migración.
- `tools`: validación e inicialización.

## Orden recomendado

1. Instalar/configurar equipo perimetral y switch L3; documentar red.
2. Plataforma común en `10.10.10.20`.
3. Portal actual en DEV/TEST, retirando Jenkins de su Compose.
4. Incorporación y modernización gradual de SIIA.
5. OJS.
6. Cursos Astro.
7. Moodle.
8. Actualizaciones tecnológicas del portal como proyecto separado.

## Advertencias

- No activar DHCP ENCiT hasta que DGTIC delegue formalmente los ámbitos correspondientes.
- No ejecutar ACL/firewall ni cambios de SVI con valores de ejemplo.
- No almacenar `.env`, claves privadas, volcados o datos personales en Git.
- El código fuente actual del SIIA no fue proporcionado; el paquete contiene infraestructura y
  esqueleto de modernización, pero las dependencias reales deben inventariarse en la VM.
- La versión real de Redis utilizada por el portal debe inventariarse antes de fijarla.
