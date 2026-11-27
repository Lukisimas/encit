# Validación de imagen OJS y preflight de Compose TEST

**Fecha:** 27 de noviembre de 2026  
**Host inspeccionado:** `pruebas` — `10.129.100.2`, VLAN 50  
**Rama documental:** `docs/storage-xitle-hostnames` (PR #1)  
**Repositorio de aplicación:** Gitea privado `encit/revista`, rama `feature/ojs-3.5-dockerfile`

## 1. Alcance y estado

Se contrastó la imagen OJS construida en el repositorio de aplicación con los manifiestos y la configuración del proxy versionados en este repositorio. La inspección del host fue de sólo lectura. No se inició OJS ni MariaDB, no se modificaron redes o proxy y no se tocaron servicios de producción.

El repositorio de aplicación contiene el commit local `c8ffebc` en `feature/ojs-3.5-dockerfile`. Ese commit todavía no se ha publicado en Gitea según el estado comunicado durante esta revisión.

## 2. Imagen OJS disponible en TEST

En el host `pruebas` se verificó la imagen local:

- Etiqueta: `encit/revista:ojs-3.5.0-6-test`.
- ID reportado por Docker: `sha256:fc6c786114056dc70319c2a04f4a26389ab80f9b85613cbba1074b6a792146c5`.
- Tamaño: 297,988,323 bytes.
- Docker Engine: 29.7.2.
- Docker Compose: 5.5.0.

Las validaciones registradas en el repositorio Gitea confirman la ausencia de `config.inc.php` en la imagen, la presencia del template oficial protegido, las siete extensiones PHP requeridas y `apache2ctl configtest` con `Syntax OK`.

Esta imagen existe localmente en TEST. No se ha confirmado su publicación en Gitea Container Registry ni existe todavía una etiqueta remota aprobada para Compose.

## 3. Redes y proxy de TEST

El proxy compartido `encit-control-platform-proxy-1` está conectado a la red externa `encit_control_edge` (bridge, `172.18.0.0/16`) con dirección `172.18.0.3`. Monta la configuración desde:

- `/srv/encit/platform/control/proxy/nginx.conf`
- `/srv/encit/platform/control/proxy/conf.d`
- `/srv/encit/platform/control/proxy/security`
- `/srv/encit/platform/control/certs`

El virtual host versionado `xitle.test.encit.unam.mx` reenvía a `http://revista-test-web:80`. Por tanto, el servicio web OJS debe conectarse a `encit_control_edge` con el alias `revista-test-web`.

**Decisión de aislamiento:** sólo el servicio web OJS necesita conectarse a la red edge. MariaDB, worker y scheduler deben permanecer únicamente en la red privada `ojs_internal`. No conectar estos servicios a las redes internas de Gitea/Jenkins ni modificar el proxy compartido durante esta fase.

## 4. Estructura de la imagen y persistencia

La inspección de la imagen confirmó:

| Ruta dentro del contenedor | Estado observado |
|---|---|
| `/var/www/html` | Raíz de OJS |
| `/var/www/html/public` | Existe e incluye `index.html` |
| `/var/www/html/cache` | Existe e incluye `_db`, `t_cache`, `t_compile` y `t_config` |
| `/var/ojs-files` | Existe, fuera del DocumentRoot |
| `/var/www/html/config.inc.php` | No existe en la imagen |
| `/var/www/html/config.TEMPLATE.inc.php` | Existe, propiedad `root:root`, modo `0640` |

En el host existen `mariadb`, `config`, `files` y `public` bajo `/srv/encit/data/revista/test`. El directorio `cache` no apareció en la inspección. Los directorios `files` y `public` estaban vacíos. No se creó ni inicializó ningún directorio durante esta validación.

Antes de montar `public` y `cache`, sembrar sus contenidos iniciales desde la imagen: un bind mount vacío oculta los archivos y subdirectorios que ya existen en la imagen. Crear el directorio persistente `cache` con propietario y permisos mínimos después de verificar el mapeo de UID/GID.

## 5. Hallazgos en los Compose versionados

La revisión de `repos/revista/deploy/testing/docker-compose.yml` encontró:

1. **Ruta de archivos privados incorrecta:** el Compose monta `OJS_FILES_DIR` en `/var/www/ojs-files`, pero la imagen y el diseño de OJS utilizan `/var/ojs-files`. El destino debe corregirse antes de ejecutar Compose.
2. **Red edge excesiva:** `worker` y `scheduler` aparecen conectados a `encit_control_edge`. Deben conectarse sólo a `ojs_internal`; únicamente `web` necesita el alias `revista-test-web` en edge.
3. **Imagen MariaDB:** el tag solicitado `mariadb:11.8.10` no está publicado en Docker Hub (respuesta `not found`). Se verificó en TEST la imagen `mariadb:11.8.9`, versión `11.8.9-MariaDB-ubu2404`, arquitectura `linux/amd64`, ID y RepoDigest `sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`. Se fija esa referencia por digest en Compose TEST y PROD para evitar el tag flotante `mariadb:11.8`. La disponibilidad de descarga de ese digest desde PROD queda pendiente de validación antes de cualquier despliegue.
4. **Etiqueta OJS obsoleta en el ejemplo de entorno:** `IMAGE_TAG` contiene un marcador de OJS 3.5.0-5, mientras que la imagen construida y validada localmente corresponde a OJS 3.5.0-6. No sustituir el marcador por una etiqueta de Registry hasta que se publique y valide una imagen remota.
5. **Precondiciones pendientes:** `config.inc.php` todavía no existe en el almacenamiento TEST y el directorio de caché no está creado. No iniciar el stack con el archivo de configuración ausente ni con los bind mounts sin inicializar.

El Compose de producción comparte el destino incorrecto `/var/www/ojs-files`; se corrige a `/var/ojs-files`, que es la ruta privada preparada por la imagen OJS. El manifiesto PROD se modifica únicamente en GitHub; no se ejecuta ni se valida contra el host PROD durante esta fase.

## 6. Estado operativo

- [x] Confirmar host TEST, rama y commit de aplicación.
- [x] Confirmar imagen OJS local y su ID.
- [x] Inspeccionar rutas y contenido inicial de la imagen.
- [x] Inspeccionar red, montajes y dirección del proxy compartido.
- [x] Revisar Compose TEST/PROD y ejemplo de entorno versionados.
- [x] Confirmar imagen MariaDB local, versión exacta, digest, arquitectura y UID/GID efectivo.
- [x] Fijar MariaDB 11.8.9 por digest en Compose TEST y PROD.
- [x] Corregir estáticamente ruta de archivos y aislamiento de red en Compose TEST.
- [x] Corregir el destino de `files_dir` en Compose PROD sin ejecutarlo.
- [ ] Crear/sembrar los directorios persistentes TEST después de validar las imágenes y permisos.
- [ ] Generar configuración TEST sin guardar secretos en Git.
- [ ] Ejecutar primero MariaDB y validar healthcheck/persistencia.
- [ ] Iniciar OJS en TEST y validar instalación, proxy y persistencia.
- [ ] Publicar la imagen OJS en Gitea Registry mediante el pipeline aprobado.

**Conclusión:** la imagen OJS 3.5.0-6 está construida y validada a nivel de imagen en TEST, pero los Compose versionados aún tienen inconsistencias de rutas y aislamiento de red, y faltan precondiciones de configuración y persistencia. No hay despliegue OJS/MariaDB y no se modificó PROD.


## 7. Validación de imagen MariaDB y UID/GID (27-nov-2026)

En el host TEST se inspeccionó la imagen MariaDB disponible localmente:

- Etiqueta: `mariadb:11.8.9`.
- ID de imagen: `sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`.
- RepoDigest local: `mariadb@sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`.
- Versión reportada por `mariadbd`: `11.8.9-MariaDB-ubu2404`.
- Usuario/grupo del proceso: `mysql`, UID/GID `999:999`.

El directorio persistente TEST `/srv/encit/data/revista/test/mariadb` tiene propietario numérico `999:999` y modo `0750`. El nombre de grupo que muestra el host (`systemd-journal`) no cambia la coincidencia numérica con el GID del contenedor. **No cambiar propietario ni permisos de este directorio por el momento.**

La inspección de almacenamiento confirmó:

| Directorio | Propietario numérico | Modo | Estado |
|---|---:|---:|---|
| `mariadb` | `999:999` | `0750` | Existe, vacío |
| `config` | `33:33` | `0750` | Existe, vacío |
| `files` | `33:33` | `0750` | Existe, vacío |
| `public` | `33:33` | `0750` | Existe, vacío |
| `cache` | — | — | No existe |

La imagen MariaDB está disponible localmente y su RepoDigest permite fijar una referencia inmutable. Se decidió usar la versión 11.8.9 porque el tag 11.8.10 no está publicado. El mismo digest queda especificado en Compose TEST y PROD para mantener una versión idéntica; falta validar su descarga desde PROD antes de cualquier despliegue.

## 8. Resultado actualizado y siguientes precondiciones

- [x] Confirmar MariaDB 11.8.9 local y registrar ID/digest.
- [x] Confirmar UID/GID MariaDB `999:999`.
- [x] Confirmar que el directorio de datos MariaDB ya coincide numéricamente con `999:999`.
- [x] Confirmar que `cache` no existe.
- [x] Decidir y fijar la referencia por digest de MariaDB 11.8.9 en Compose TEST y PROD; la descarga desde PROD sigue pendiente de validación.
- [ ] Corregir el destino de `files_dir` y el aislamiento de redes en Compose.
- [ ] Crear `cache` con propietario `33:33` y modo mínimo después de validar el procedimiento.
- [ ] Inicializar `public` desde la imagen OJS antes de montar el bind mount vacío.
- [ ] Generar y revisar la configuración TEST de forma segura, sin registrar secretos.
- [ ] Validar Compose estáticamente antes de iniciar contenedores.


## 9. Decisión y cambios de Compose (27-nov-2026)

- El intento de descargar `mariadb:11.8.10` falló con `manifest not found`; no se presume que exista esa versión/tag.
- Se adopta `mariadb:11.8.9-MariaDB-ubu2404`, `linux/amd64`, RepoDigest `mariadb@sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`.
- Compose TEST y PROD fijan la imagen como `mariadb:11.8.9@sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`.
- Ambos Compose montan `OJS_FILES_DIR` en `/var/ojs-files`, fuera del DocumentRoot.
- En TEST, sólo `web` se conecta a `encit_control_edge`; `db`, `worker` y `scheduler` permanecen en `ojs_internal`.
- En PROD se conserva el aislamiento ya definido: sólo `web` se conecta a `encit_prod_edge`; `db`, `worker` y `scheduler` permanecen en `ojs_internal`.
- Estos cambios son manifiestos versionados. No se ejecutó Compose, no se descargó la imagen en PROD y no se inició ningún contenedor OJS/MariaDB.
- Pendiente: validar que PROD pueda descargar la referencia exacta por digest antes de aprobar un despliegue.
