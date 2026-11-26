# Validación del inventario Docker en DEV/TEST

**Fecha:** 26 de noviembre de 2026  
**Host:** `pruebas`  
**Dirección de control reportada:** `10.129.100.2`  
**Rama de documentación:** `docs/storage-xitle-hostnames`

## Alcance

El administrador ejecutó comandos de solo lectura para identificar contenedores, imágenes locales, redes Docker y las imágenes declaradas por el Compose de la plataforma de control. No se descargaron imágenes, no se construyeron imágenes y no se inició, detuvo ni recreó ningún contenedor.

## Contenedores activos

Se reportaron seis contenedores activos, todos pertenecientes al proyecto Compose `encit-control-platform`:

| Contenedor | Imagen | Estado / puertos reportados |
|---|---|---|
| `encit-control-platform-gitea-1` | `docker.gitea.com/gitea:1.27.1` | Up 21 hours; TCP/22 del contenedor publicado como TCP/2222 en el host |
| `encit-control-platform-jenkins-1` | `encit-control-platform-jenkins` | Up 23 hours; puertos internos 8080 y 50000, sin publicación al host en la salida |
| `encit-control-platform-docker-dind-1` | `docker:29-dind` | Up 24 hours |
| `encit-control-platform-gitea-db-1` | `postgres:17` | Up 4 weeks, healthcheck healthy |
| `encit-control-platform-proxy-1` | `nginx:1.30.4` | Up 4 weeks; TCP/80 y TCP/443 publicados en el host |
| `encit-control-platform-mailpit-1` | `axllent/mailpit:v1.30.6` | Up 4 weeks, healthcheck healthy |

El único servicio de base de datos observado en esta plataforma es PostgreSQL 17 para Gitea. No se observó un contenedor MariaDB ni un servicio OJS.

## Imágenes locales

El inventario local contiene únicamente las seis imágenes utilizadas por la plataforma de control:

- `encit-control-platform-jenkins:latest`
- `postgres:17`
- `docker:29-dind`
- `nginx:1.30.4`
- `axllent/mailpit:v1.30.6`
- `docker.gitea.com/gitea:1.27.1`

No se encontraron imágenes locales que coincidan con `encit/ojs` o `mariadb`. El Compose de control declara exactamente las seis imágenes listadas arriba.

## Redes Docker

| Red | Subred | Gateway |
|---|---|---|
| `bridge` | `172.17.0.0/16` | `172.17.0.1` |
| `encit-control-platform_gitea_internal` | `172.20.0.0/16` | `172.20.0.1` |
| `encit-control-platform_jenkins_egress` | `172.21.0.0/16` | `172.21.0.1` |
| `encit-control-platform_jenkins_internal` | `172.19.0.0/16` | `172.19.0.1` |
| `encit_control_edge` | `172.18.0.0/16` | `172.18.0.1` |

Las redes `host` y `none` también existen, sin subred/gateway IPAM aplicable.

## Hallazgo de direccionamiento entre DEV/TEST y PROD

La red externa `encit_control_edge` de DEV/TEST utiliza `172.18.0.0/16`. La inspección previa en el servidor de producción encontró que `encit_prod_edge` utiliza también `172.18.0.0/16`.

Esto representa una **duplicación de subred entre dos hosts Docker distintos**. No implica por sí sola una colisión dentro de cada host ni impide automáticamente la comunicación host-a-host por las VLAN de control y producción. Sin embargo, sí puede producir ambigüedad si se intenta enrutar tráfico directamente entre las subredes de contenedores de ambos hosts, conectar esas redes mediante VPN/overlay o anunciar sus rutas. Por tanto:

- No asumir que las IP privadas de contenedores DEV/TEST y PROD son globalmente únicas.
- No configurar rutas entre ambas subredes mientras conserven el mismo prefijo.
- Antes de desplegar aplicaciones, definir si la comunicación entre entornos se hará mediante nombres/IP de host y puertos publicados, o si se requiere enrutamiento entre redes Docker.
- Si se requiere enrutamiento entre redes Docker, asignar subredes no solapadas y actualizar de forma coordinada los Compose, la documentación y las reglas de red.
- Revisar también los rangos institucionales, VPN y redes de otros hosts antes de reservar nuevos prefijos.

Las redes Docker de control `172.19.0.0/16`, `172.20.0.0/16` y `172.21.0.0/16` no se solapan entre sí en el inventario de este host. La comparación completa con redes institucionales/VPN sigue pendiente.

## Registro de imágenes y pipeline OJS

El comando `docker info --format '{{json .RegistryConfig.Mirrors}}'` devolvió `[]`. Ese campo corresponde a mirrors del daemon; **no demuestra** que no exista un registro privado ni permite determinar la URL, autenticación o disponibilidad del Container Registry de Gitea.

A partir de esta inspección no se puede concluir si la imagen OJS:
- aún debe construirse mediante Jenkins;
- ya fue construida y publicada en el Container Registry de Gitea, pero no se ha descargado en este host;
- se publica en otro registro;
- o todavía no tiene un pipeline funcional.

Antes de hacer pull, build o deploy, se debe inspeccionar el Compose de la plataforma, la configuración de Gitea/Packages, los Jenkinsfiles y scripts de construcción de `repos/revista`. Después se identificará el tag realmente construido y validado en TEST. No utilizar el marcador `REPLACE_WITH_TESTED_TAG` del `.env.example` ni inventar un tag.

## Estado y siguientes verificaciones

- [x] Identificar el host DEV/TEST y su dirección.
- [x] Inventariar contenedores activos.
- [x] Inventariar imágenes locales.
- [x] Inventariar redes y subredes Docker del host.
- [x] Confirmar las imágenes declaradas por el Compose de control.
- [ ] Inspeccionar la configuración del Container Registry de Gitea sin revelar credenciales.
- [ ] Revisar Jenkinsfiles y scripts de build/push de OJS.
- [ ] Identificar un tag OJS realmente construido y validado en TEST.
- [ ] Resolver/documentar la duplicación `172.18.0.0/16` entre DEV/TEST y PROD según el modelo de conectividad requerido.
- [ ] Comparar subredes Docker con VPN y rutas institucionales.

**Conclusión:** el servidor DEV/TEST está ejecutando la plataforma de control (Gitea, Jenkins, Docker-in-Docker, PostgreSQL, proxy y Mailpit), pero el inventario local no contiene OJS ni MariaDB. La preparación del pipeline y la procedencia/tag de la imagen OJS deben verificarse antes de desplegar. No se realizaron cambios en servidores, contenedores, redes ni OPNsense durante esta validación.
