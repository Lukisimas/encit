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
- [x] Corregir el destino de `files_dir` y el aislamiento de redes en Compose.
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


## 10. Comprobación de disponibilidad de manifiestos en TEST (27-nov-2026)

Se verificó en el host `pruebas` el repositorio local `/srv/encit/apps/revista/dev`:

- Rama: `feature/ojs-3.5-dockerfile`.
- Estado Git: limpio (`## feature/ojs-3.5-dockerfile`).
- HEAD: `c8ffebc Build hardened OJS 3.5.0-6 Docker image`.
- Docker Engine: `29.7.2`, build `a7dcaa6`.
- Docker Compose: `v5.5.0`.

No existen en ese checkout los archivos `deploy/testing/docker-compose.yml`, `deploy/testing/.env`, `deploy/testing/.env.example` ni `deploy/production/docker-compose.yml`. Esto es consistente con la separación de repositorios: el checkout Gitea `encit/revista` contiene el artefacto de aplicación OJS; los manifiestos de despliegue pertenecen al repositorio GitHub `Lukisimas/encit`, rama `docs/storage-xitle-hostnames`, PR #1.
Se volvieron a consultar los manifiestos directamente en la rama del PR. Se confirmó que TEST y PROD mantienen los destinos de volumen `/var/ojs-files`, la referencia MariaDB fijada por digest y el aislamiento de red documentado en la sección 9. El ejemplo de entorno TEST conserva `IMAGE_TAG=3.5.0-5-REPLACE_WITH_TESTED_TAG`; es un marcador pendiente y no debe usarse como etiqueta de despliegue.

**Resultado:** todavía no se ejecutó `docker compose config`. No se copiarán manifiestos a Gitea ni se crearán archivos en TEST hasta definir un procedimiento de validación que use exactamente los archivos versionados del PR y valores de entorno de prueba no secretos. No se inició ningún contenedor ni se modificó persistencia o PROD.

- [x] Confirmar rama, estado y commit del checkout Gitea en TEST.
- [x] Confirmar ausencia de manifiestos de despliegue en el checkout Gitea.
- [x] Reconsultar Compose TEST/PROD y `.env.example` en la rama del PR.
- [x] Ejecutar la validación estática de sintaxis del Compose TEST con resultado correcto.


## 11. Resultado de validación estática de Compose TEST (27-nov-2026)

Se ejecutó en el host `pruebas` la validación estática del manifiesto Compose TEST, utilizando los archivos preparados para la comprobación.

**Resultado reportado:** `Compose TEST válido sintácticamente`.

Esta comprobación confirma únicamente que el manifiesto supera la validación sintáctica realizada. No acredita la disponibilidad de las imágenes en un Registry, la resolución efectiva de variables/secretos de un entorno real, la creación de redes o volúmenes, la conectividad con MariaDB, ni el funcionamiento de OJS detrás del proxy.

La validación no inició contenedores ni modificó la persistencia. No se ejecutó ninguna acción en PROD.

**Siguientes pasos pendientes:** preparar e inicializar los directorios persistentes de TEST, generar la configuración OJS de TEST sin exponer secretos y, con autorización antes de iniciar servicios, validar primero MariaDB y después OJS y el proxy. La descarga del digest MariaDB desde PROD continúa pendiente y requiere autorización específica antes de acceder a ese host.


## 12. Revisión actual de persistencia TEST (27-nov-2026)

En una nueva inspección de sólo lectura del host `pruebas` se confirmó que actualmente no existe la ruta raíz `/srv/encit/data/revista/test`; por tanto, tampoco existen sus subdirectorios previstos `mariadb`, `config`, `files`, `public` y `cache`. No se encontró `config.inc.php` y no aparecen contenedores OJS/MariaDB en `docker ps -a`.

La imagen local `encit/revista:ojs-3.5.0-6-test` sigue presente con ID `sha256:fc6c786114056dc70319c2a04f4a26389ab80f9b85613cbba1074b6a792146c5`, tamaño 297,988,323 bytes y fecha de creación `2026-11-27T14:04:08.741685589-06:00`.

Este resultado difiere de la inspección anterior registrada en las secciones 4 y 7, donde se reportaron directorios persistentes existentes. Se conserva el resultado más reciente como estado observado; no se infiere si los directorios fueron eliminados, movidos o si la inspección anterior correspondía a otra ruta/momento. La aclaración de arquitectura y la decisión de ruta para TEST quedan registradas en la sección 13: TEST utiliza el disco único del servidor de control y no requiere un montaje independiente en `/data`.

No se crearon directorios, no se cambiaron permisos, no se generó configuración, no se inició ningún contenedor y no se modificó PROD.

- [x] Reinspeccionar la ruta de persistencia TEST y la presencia de contenedores.
- [x] Confirmar la ruta de persistencia TEST conforme a la arquitectura de disco único (véase sección 13).
- [ ] Crear la estructura de persistencia TEST con propietarios y permisos verificados.
- [ ] Sembrar `public` y preparar `cache` desde la imagen OJS.
- [ ] Generar `config.inc.php` de TEST sin guardar secretos en Git.


## 13. Aclaración de almacenamiento y ruta de persistencia TEST (27-nov-2026)

Se corrige la interpretación de la inspección anterior: **TEST no tiene dos discos**. Desde el diseño inicial, el servidor de control que aloja DEV/TEST dispone de un solo disco. El esquema de dos arreglos (SSD RAID1 y HDD RAID5 montado en `/data`) corresponde exclusivamente al servidor de producción.

La consulta de sólo lectura en `pruebas` confirmó:

- Host: `pruebas`; usuario de sesión: `administrador`.
- `/data` no existe, lo cual es esperado en este servidor y no constituye una anomalía.
- `/srv/encit` reside en el filesystem raíz: `/dev/sda1`, ext4.
- El filesystem raíz reportó 901 GB totales, 14 GB usados y 842 GB disponibles en el momento de la consulta.
**Decisión de persistencia TEST:** utilizar `/srv/encit/data/revista/test`, consistente con `repos/revista/deploy/testing/.env.example`. Los directorios de MariaDB, configuración, archivos privados, `public` y `cache` se alojarán bajo esa raíz en el único disco disponible. No se debe crear ni esperar un montaje adicional en `/data` para TEST.

Esta decisión elimina el bloqueo documental relacionado con la ausencia de `/data`. La existencia y el estado de la estructura persistente se actualizaron con una inspección posterior en la sección 14; no debe interpretarse esta decisión como evidencia de que todos los directorios estén completos o listos para el despliegue.

La desconexión SSH durante la primera consulta no produjo cambios conocidos; la consulta posterior fue de sólo lectura. No se crearon directorios, no se modificaron propietarios/permisos, no se inició ningún contenedor y no se tocó PROD.

- [x] Confirmar que TEST utiliza un solo disco y no requiere `/data`.
- [x] Confirmar que `/srv/encit` reside en el filesystem raíz `/dev/sda1`.
- [x] Definir `/srv/encit/data/revista/test` como raíz de persistencia TEST.
- [ ] Crear la estructura persistente TEST con propietarios y permisos verificados.
- [ ] Sembrar `public` y preparar `cache` desde la imagen OJS.
- [ ] Generar `config.inc.php` de TEST sin guardar secretos en Git.


## 14. Inspección de permisos y estructura persistente TEST (27-nov-2026)

Se realizó una inspección de sólo lectura en `pruebas`. El filesystem sigue siendo el disco único `/dev/sda1` montado en `/`, con 901 GB totales, 14 GB usados y 842 GB disponibles en el momento de la consulta.

La ruta existe, pero la sesión de `administrador` no puede recorrerla por los permisos del directorio padre:

| Ruta | Propietario:grupo | Modo |
|---|---|---:|
| `/srv` | `root:root` | 755 |
| `/srv/encit` | `root:root` | 755 |
| `/srv/encit/data` | `root:root` | 755 |
| `/srv/encit/data/revista` | `root:root` | 750 |
| `/srv/encit/data/revista/test` | `root:root` | 750 |
| `.../files` | `www-data:www-data` | 750 |
| `.../public` | `www-data:www-data` | 750 |
| `.../config` | `www-data:www-data` | 750 |
| `.../mariadb` | UID 999, GID 999 (nombre de grupo local: `systemd-journal`) | 750 |

La identidad local `administrador` es UID/GID `1000:1000` y pertenece a `sudo`, entre otros grupos; no pertenece a `root` ni a `www-data`. El modo `750` de `/srv/encit/data/revista` impide que el usuario sin privilegios recorra el directorio. No se instaló `getfacl` ni `setfacl`; por tanto, esta inspección no evaluó ACL extendidas.

La imagen OJS utiliza `www-data` UID/GID `33:33`; MariaDB utiliza `mysql` UID/GID `999:999`. En el host, el GID numérico 999 se resuelve al nombre local `systemd-journal`; la identidad efectiva dentro del contenedor se determina por el número UID/GID, no por el nombre mostrado por NSS en el host. No cambiar propietario/grupo de `mariadb` sin una comprobación adicional y una decisión explícita.

La estructura observada contiene `files`, `public`, `config` y `mariadb`; no se observó `cache` en el listado de primer nivel. El comando de inspección no confirmó la existencia de `config.inc.php` dentro de `config`, ni la inicialización de MariaDB. Es necesario verificar contenidos, modos y propietarios numéricos de cada ruta antes de decidir cualquier corrección.

**Estado operativo:** la estructura base existe parcialmente, pero no se considera lista para desplegar. No se modificaron permisos, propietarios, ACL ni contenidos; no se instalaron paquetes, no se inició ningún contenedor OJS/MariaDB y no se tocó PROD.

- [x] Confirmar identidad UID/GID de `www-data` (33:33) y `mysql` (999:999) en sus imágenes.
- [x] Identificar el bloqueo de recorrido en `/srv/encit/data/revista` (modo 750, root:root).
- [x] Identificar las carpetas persistentes existentes en TEST.
- [ ] Verificar contenido, propietarios numéricos y permisos de cada subdirectorio.
- [ ] Determinar el acceso administrativo mínimo sin abrir innecesariamente la ruta.
- [ ] Confirmar si existe `config.inc.php` y si MariaDB contiene datos antes de cualquier inicialización.
- [ ] Preparar cualquier cambio de permisos/propiedad para autorización explícita.

## 15. Verificación de contenido de persistencia TEST (27-nov-2026)

Se amplió la inspección de sólo lectura para determinar si las carpetas existentes contienen datos previos:

- \`/srv/encit/data/revista/test\` contiene únicamente los directorios \`config\`, \`files\`, \`public\` y \`mariadb\`; no se encontraron archivos en los niveles inspeccionados.
- \`config.inc.php\` no existe dentro de \`config\`.
- El directorio \`cache\` no existe.
- \`mariadb\` ocupa 4.0 KiB y no contiene entradas en los niveles inspeccionados; se considera sin inicialización visible, pero no se ejecutó ninguna prueba de arranque.
- \`files\`, \`public\` y \`config\` ocupan 4.0 KiB cada uno y no contienen archivos observados.
- Los propietarios numéricos siguen siendo \`33:33\` para \`config\`, \`files\` y \`public\`, y \`999:999\` para \`mariadb\`. El directorio raíz \`test\` permanece \`root:root\` con modo \`0750\`; su padre \`revista\` también es \`root:root\` \`0750\`.
- \`administrador\` es UID/GID \`1000:1000\` y no tiene permiso de recorrido directo a través de \`revista\` sin privilegios elevados. No se instalaron herramientas ACL, ni se consultaron ACL extendidas.

**Conclusión:** las carpetas de persistencia observadas están vacías a nivel de contenido visible y no hay configuración OJS creada ni datos de MariaDB visibles. La estructura todavía no está lista para iniciar servicios: falta crear \`cache\`, generar \`config.inc.php\` de TEST y resolver el acceso administrativo de forma mínima. Antes de sembrar \`public\` desde la imagen, debe definirse y ejecutar explícitamente el procedimiento de copia preservando \`www-data:33:33\` y sin ocultar los archivos originales de la imagen con un bind mount vacío.

No se cambiaron propietarios, permisos, ACL ni contenidos. No se creó \`cache\`, no se generó configuración, no se inició ningún contenedor y no se modificó PROD.

- [x] Inspeccionar contenido de \`config\`, \`files\`, \`public\` y \`mariadb\`.
- [x] Confirmar ausencia de \`config.inc.php\` y \`cache\`.
- [x] Registrar propietarios numéricos y tamaños observados.
- [ ] Definir acceso administrativo mínimo a la ruta sin ampliar permisos innecesariamente.
- [ ] Crear \`cache\` y preparar \`public\` desde la imagen OJS con autorización.
- [ ] Generar \`config.inc.php\` de TEST sin guardar secretos en Git.
- [ ] Validar Compose y, con autorización, iniciar primero MariaDB y después OJS.


## 16. Contenido inicial de `public` y `cache` en la imagen OJS (27-nov-2026)

Se inspeccionaron ambas rutas dentro de la imagen local `encit/revista:ojs-3.5.0-6-test` mediante contenedores temporales `--rm`; no se inició el servicio OJS ni se modificó el host.

Resultado observado:

| Ruta de imagen | Contenido | Propietario | Modo |
|---|---|---|---:|
| `/var/www/html/public` | `index.html` (0 bytes) | `www-data:www-data` (33:33) | archivo 0640; directorio 0750 |
| `/var/www/html/cache` | `_db`, `t_cache`, `t_compile`, `t_config` | `www-data:www-data` (33:33) | directorios 0750 |
| `/var/ojs-files` | directorio de archivos privados | `www-data:www-data` (33:33) | 0750 |

La raíz `/var/www/html` tiene modo 1777 y propietario 33:33; esto no modifica los permisos requeridos para los volúmenes dedicados.

En el host TEST, los directorios persistentes `public` y `files` existen vacíos, `cache` todavía no existe y `config` está vacío. Por tanto, antes de iniciar OJS:

1. Copiar el contenido inicial de `/var/www/html/public` de la imagen al bind mount persistente `public`, preservando propietario numérico 33:33 y modos.
2. Crear el directorio persistente `cache` con propietario 33:33 y modo 0750, y copiar sus subdirectorios iniciales desde la imagen, preservando modos y propietario.
3. Mantener `files` con propietario 33:33 y modo 0750; no necesita sembrado desde `/var/ojs-files`, que es el punto de montaje de archivos privados.
4. Mantener `mariadb` con UID/GID 999:999 y modo 0750.
5. Generar `config.inc.php` por separado, sin incluir credenciales en Git ni en la documentación.

La copia/creación anterior es un procedimiento propuesto, no una operación ya realizada. No se cambiaron permisos, propietarios ni contenidos; no se creó `cache`, no se generó `config.inc.php`, no se inició ningún contenedor OJS/MariaDB y no se modificó PROD.

- [x] Inspeccionar contenido inicial y permisos de `public` y `cache` en la imagen.- [x] Confirmar UID/GID OJS `33:33` y modos `0750` de los directorios.
- [ ] Sembrar `public` y `cache` en TEST, preservando propietario y modos, con autorización explícita.
- [ ] Generar `config.inc.php` de TEST sin secretos en Git.
- [ ] Validar Compose con los valores de entorno previstos antes de iniciar servicios.


## 17. Montajes Compose TEST y recorrido de directorios padre (27-nov-2026)

Se releyó el manifiesto `repos/revista/deploy/testing/docker-compose.yml` y su `.env.example` directamente desde esta rama del PR.

Los bind mounts definidos son:

| Variable | Origen en TEST | Destino |
|---|---|---|
| `MARIADB_DATA_DIR` | `/srv/encit/data/revista/test/mariadb` | `/var/lib/mysql` |
| `OJS_CONFIG_DIR` + `config.inc.php` | `/srv/encit/data/revista/test/config/config.inc.php` | `/var/www/html/config.inc.php` |
| `OJS_FILES_DIR` | `/srv/encit/data/revista/test/files` | `/var/ojs-files` |
| `OJS_PUBLIC_DIR` | `/srv/encit/data/revista/test/public` | `/var/www/html/public` |
| `OJS_CACHE_DIR` | `/srv/encit/data/revista/test/cache` | `/var/www/html/cache` |

El manifiesto comparte estos volúmenes entre `web`, `worker` y `scheduler`; MariaDB monta únicamente su propio directorio de datos. El ejemplo de entorno conserva `IMAGE_TAG=3.5.0-5-REPLACE_WITH_TESTED_TAG`, por lo que no es apto para iniciar el stack hasta que exista una etiqueta de imagen publicada y aprobada.

La inspección del host mostró `/srv/encit/data/revista` y su hijo `test` como `root:root`, modo `0750`. Los procesos de los contenedores usan UID/GID OJS `33:33` y MariaDB `999:999`. Los permisos de recorrido de los directorios padre también se aplican a los procesos dentro de los contenedores: un bind mount no elimina las comprobaciones DAC del filesystem del host. Por tanto, antes de iniciar los servicios hay que conceder permiso de búsqueda (execute) a los UID que correspondan en ambos directorios padre, sin conceder lectura/listado innecesario ni abrirlos a todos los usuarios.

No se ha aplicado ACL ni cambiado modo/propietario. `getfacl` y `setfacl` no están instalados en TEST, de modo que aún no se ha consultado ni configurado ACL extendida. Debe elegirse un mecanismo mínimo (preferentemente ACL nominativa para UID 33 y 999) y autorizarse antes de modificar el host. No se ha instalado ningún paquete.

No se ejecutó Compose, no se inició ningún contenedor, no se creó `cache` ni `config.inc.php`, no se copiaron archivos de la imagen y no se modificó PROD.

- [x] Releer Compose TEST y `.env.example` desde la rama del PR.
- [x] Relacionar cada variable de persistencia con su destino de montaje.
- [x] Identificar que los procesos de contenedor requieren recorrido de los directorios padre del host.
- [ ] Definir y autorizar permisos mínimos de recorrido para UID 33 y 999.
- [ ] Crear/sembrar `cache` y `public` con propietarios y modos correctos.
- [ ] Generar `config.inc.php` de TEST fuera de Git.
- [ ] Sustituir el marcador de `IMAGE_TAG` por una referencia publicada y validada antes de desplegar.


## 18. Autorización para ACL de recorrido en TEST y estado de ejecución (27-nov-2026)

El administrador autorizó aplicar en el host TEST `pruebas` un ajuste mínimo para que los procesos OJS (UID 33) y MariaDB (UID 999) puedan atravesar los directorios padre `/srv/encit/data/revista` y `/srv/encit/data/revista/test`, sin conceder permiso de listado ni modificar propietarios.

**Procedimiento autorizado, pendiente de ejecución y verificación en el host:**

1. Instalar el paquete Debian `acl`.
2. Aplicar ACL nominativas de sólo búsqueda/recorrido a ambos UID en ambos directorios:
   `setfacl -m u:33:--x,u:999:--x /srv/encit/data/revista /srv/encit/data/revista/test`.
3. Consultar las ACL efectivas con `getfacl -p` y comprobar recorrido como UID 33 y UID 999 con pruebas `test -x` sobre la ruta completa.
4. Confirmar que los permisos tradicionales y propietarios no fueron alterados y que los UID no pueden listar el contenido de los directorios padre.

**Limitación de ejecución en esta sesión:** no hay una conexión de terminal/SSH disponible para administrar el host. Por tanto, el paquete no se ha instalado, las ACL no se han aplicado y no se puede reportar una validación efectiva. La autorización del administrador queda registrada, pero no equivale a ejecución. No se modificó TEST ni PROD.

Bloque propuesto para ejecutar directamente en `pruebas`:

```bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y acl

sudo setfacl -m u:33:--x,u:999:--x \
  /srv/encit/data/revista \
  /srv/encit/data/revista/test

echo "========== ACL =========="
sudo getfacl -p \
  /srv/encit/data/revista \
  /srv/encit/data/revista/test

echo "========== RECORRIDO OJS (UID 33) =========="
sudo setpriv --reuid=33 --regid=33 --clear-groups \
  sh -c 'test -x /srv/encit/data/revista && test -x /srv/encit/data/revista/test && echo OK'

echo "========== RECORRIDO MARIADB (UID 999) =========="
sudo setpriv --reuid=999 --regid=999 --clear-groups \
  sh -c 'test -x /srv/encit/data/revista && test -x /srv/encit/data/revista/test && echo OK'

echo "========== LISTADO DENEGADO =========="
if sudo setpriv --reuid=33 --regid=33 --clear-groups \
  sh -c 'ls /srv/encit/data/revista >/dev/null 2>&1'; then
  echo "ERROR: UID 33 puede listar revista"
  exit 1
else
  echo "OK: UID 33 no puede listar revista"
fi

if sudo setpriv --reuid=999 --regid=999 --clear-groups \
  sh -c 'ls /srv/encit/data/revista/test >/dev/null 2>&1'; then
  echo "ERROR: UID 999 puede listar test"
  exit 1
else
  echo "OK: UID 999 no puede listar test"
fi
```

Nota: la prueba de listado denegado valida que la ACL `--x` no haya otorgado lectura. Si una ACL previa o un permiso adicional permite listar, detenerse y revisar antes de continuar; no ampliar ni sustituir permisos automáticamente.

- [x] Obtener autorización explícita para instalar `acl` y aplicar ACL mínimas en TEST.
- [ ] Instalar `acl` en TEST.
- [ ] Aplicar ACL nominativas de sólo recorrido a UID 33 y 999.
- [ ] Verificar ACL, recorrido y ausencia de permiso de listado.
- [ ] Registrar resultado real de ejecución en esta sección antes de preparar la siembra de `public` y `cache`.

## 19. Resultado de aplicación y validación de ACL en TEST (27-nov-2026)

El administrador ejecutó el procedimiento autorizado en el host `pruebas` y compartió la salida de `getfacl` y de las pruebas de acceso. El resultado fue satisfactorio:

- En `/srv/encit/data/revista` y `/srv/encit/data/revista/test` aparecen entradas nominativas `user:www-data:--x` (UID 33) y `user:999:--x` (UID 999).
- La máscara ACL mostrada es `r-x`; no amplía los permisos efectivos de las entradas nominativas, que permanecen en `--x`.
- La prueba de recorrido como UID 33 terminó en `OK`.
- La prueba de recorrido como UID 999 terminó en `OK`.
- La prueba de listado confirmó que UID 33 no puede listar `/srv/encit/data/revista` y que UID 999 no puede listar `/srv/encit/data/revista/test`.

La salida confirma que ambos procesos pueden atravesar los directorios padre sin recibir permiso de lectura/listado mediante estas ACL. Los propietarios siguen siendo `root:root`; no se reportó cambio de propietarios ni de modos tradicionales. La salida compartida no incluyó el registro de `apt-get`, por lo que se documenta la disponibilidad funcional de `getfacl` y las ACL observadas, sin atribuir detalles adicionales al proceso de instalación del paquete.

**Alcance:** esta validación se limita a las ACL y al recorrido de los dos directorios indicados. No valida todavía los permisos/contenidos de los bind mounts internos, el arranque de OJS/MariaDB ni el Compose completo. No se ha sembrado `public` ni `cache`, no se ha generado `config.inc.php`, no se ha iniciado el stack y no se ha modificado PROD.

- [x] Observar ACL nominativas para UID 33 y UID 999 en ambos directorios padre.
- [x] Validar recorrido de la ruta como UID 33.
- [x] Validar recorrido de la ruta como UID 999.
- [x] Confirmar denegación de listado en las rutas comprobadas.
- [ ] Sembrar `public` y `cache` en TEST, con autorización explícita.
- [ ] Generar `config.inc.php` de TEST fuera de Git.
- [ ] Validar Compose con los valores de entorno previstos antes de iniciar servicios.


## 20. Autorización para sembrar `public` y `cache` en TEST (27-nov-2026)

El administrador autorizó preparar los directorios persistentes `public` y `cache` de OJS en el host TEST `pruebas`, tomando como origen el contenido incluido en la imagen local `encit/revista:ojs-3.5.0-6-test`.

**Alcance autorizado:**
- Copiar `/var/www/html/public` y `/var/www/html/cache` desde la imagen a `/srv/encit/data/revista/test/public` y `/srv/encit/data/revista/test/cache`.
- Preservar propietarios/grupos numéricos y modos mediante archivo tar.
- Verificar propietario, modo y contenido resultante.

**Guardas del procedimiento:** antes de copiar, comprobar que `public` existe y está vacío, y que `cache` todavía no existe. Si alguna condición no se cumple, detenerse sin sobrescribir ni borrar datos. La extracción conserva UID/GID numéricos y modos del contenido de la imagen. La ejecución se realiza en TEST por el administrador; esta sesión no dispone de acceso SSH al host.

**No incluido en esta autorización:** crear o modificar `config.inc.php`, iniciar Compose o contenedores, publicar la imagen, modificar PROD o cambiar otros directorios persistentes.

**Estado:** autorizado; procedimiento entregado para ejecución. La siembra y su validación efectiva quedan pendientes de la salida del host.

- [x] Obtener autorización explícita para sembrar `public` y `cache` en TEST.
- [ ] Confirmar guardas de directorios vacíos/ausentes.
- [ ] Copiar contenido inicial preservando UID/GID y modos.
- [ ] Verificar resultado en TEST.

## 21. Siembra y validación de `public` y `cache` en TEST (27-nov-2026)

El administrador ejecutó en el host `pruebas` la copia autorizada desde la imagen local `encit/revista:ojs-3.5.0-6-test`. La prevalidación confirmó el ID de imagen `sha256:fc6c786114056dc70319c2a04f4a26389ab80f9b85613cbba1074b6a792146c5`, que `public` existía vacío y que `cache` no existía antes de la extracción.

La operación utilizó un contenedor temporal con `tar` para exportar `/var/www/html/public` y `/var/www/html/cache`, y extrajo el archivo en el host con `tar --numeric-owner -xpf`. El comando terminó sin error y las comprobaciones posteriores reportaron:

| Ruta persistente TEST | Propietario numérico | Modo | Contenido verificado |
|---|---:|---:|---|
| `/srv/encit/data/revista/test/public` | `33:33` | `0750` | `index.html`, propietario `www-data:www-data`, modo `0640` |
| `/srv/encit/data/revista/test/cache` | `33:33` | `0750` | `_db`, `t_cache`, `t_compile`, `t_config`; todos directorios `0750`, propietario `www-data:www-data` |

La validación final del administrador comprobó explícitamente que ambos directorios raíz conservan UID/GID `33:33` y modo `0750`. El listado recursivo confirmó el contenido inicial esperado. La operación no requirió modificar propietarios ni modos después de la extracción.

**Resultado:** siembra de `public` y `cache` completada y verificada en TEST. Queda resuelta esta precondición de persistencia para los bind mounts OJS.

**Límites y estado restante:** esta operación no creó ni modificó `config.inc.php`, no inició Compose ni contenedores OJS/MariaDB, no publicó la imagen en Registry, no sustituyó el marcador de `IMAGE_TAG` y no modificó PROD. Antes de iniciar servicios todavía deben prepararse y validar la configuración privada de TEST, confirmar una referencia de imagen publicada/validada y completar el preflight de Compose.

- [x] Confirmar que `public` existía vacío y `cache` no existía antes de copiar.
- [x] Copiar ambos directorios desde la imagen OJS preservando UID/GID numéricos y modos.
- [x] Verificar `public` con propietario `33:33`, modo `0750` y archivo `index.html` modo `0640`.
- [x] Verificar `cache` con propietario `33:33`, modo `0750` y los cuatro subdirectorios esperados modo `0750`.
- [ ] Generar y validar `config.inc.php` de TEST fuera de Git.
- [ ] Confirmar/publicar una referencia inmutable de la imagen OJS antes de Compose.
- [ ] Validar Compose y obtener autorización independiente antes de iniciar servicios.


## 22. Inspección estática de herramientas CLI de OJS (27-nov-2026)

Se inspeccionaron, dentro de la imagen local `encit/revista:ojs-3.5.0-6-test`, las herramientas CLI de PKP/OJS para determinar cómo ejecutar el procesamiento de colas y las tareas programadas. La inspección fue de sólo lectura; no se creó configuración ni se inició ningún servicio.

### Resultado de ejecución inicial

Se intentó consultar la ayuda de:

- `lib/pkp/tools/jobs.php`
- `lib/pkp/tools/scheduler.php`

Ambos archivos existen en la imagen. Sin embargo, la ejecución terminó con `Cannot read configuration file /var/www/html/config.inc.php`, porque dicho archivo todavía no existe. Este resultado es una dependencia de configuración esperada y no demuestra un defecto de la imagen ni de las herramientas CLI.

### Comportamiento confirmado por inspección del código

- `php lib/pkp/tools/jobs.php work` inicia el worker daemon de colas. Lee la conexión y la cola desde `[queues]` y admite parámetros para nombre, backoff, memoria, timeout, sleep, intentos, máximo de trabajos y tiempo máximo.
- `php lib/pkp/tools/scheduler.php work` inicia el modo daemon del scheduler. El proceso espera el cambio de minuto y lanza la operación `run` una vez por minuto.
- `php lib/pkp/tools/scheduler.php run` procesa las tareas programadas que estén vencidas.
- Tanto el worker como el scheduler comprueban el modo mantenimiento y `[general] sandbox`. Si `sandbox = On`, ambos se niegan a procesar trabajos/tareas y muestran un mensaje de error.
- `[queues] job_runner = On` habilita el procesamiento integrado de trabajos al final de solicitudes web.
- `[schedule] task_runner = On` habilita el scheduler integrado al final de solicitudes web.
- `[queues] process_jobs_at_task_scheduler` controla si las tareas programadas procesan también trabajos de la cola; su valor predeterminado en la plantilla es `Off`.

### Decisiones para el diseño de servicios

Para una arquitectura con procesos externos dedicados, la configuración deberá considerar:

- `job_runner = Off`, para evitar que las solicitudes web procesen trabajos además del worker daemon.
- `task_runner = Off`, para evitar ejecutar el scheduler integrado en cada ciclo de solicitudes web.
- Mantener `process_jobs_at_task_scheduler = Off` si el worker dedicado es el único consumidor de la cola; cambiarlo sólo si se decide explícitamente que el scheduler también procese trabajos.
- No usar `sandbox = On` durante las pruebas funcionales de worker y scheduler: el código inspeccionado impide que ambos procesen mientras ese modo esté activo. La política de sandbox de TEST debe ajustarse antes de esas pruebas, sin confundirla con el aislamiento de red y credenciales del entorno.

Los comandos anteriores son los puntos de entrada identificados en el código; todavía no se han ejecutado satisfactoriamente porque falta `config.inc.php`. No se ha validado el comportamiento de los procesos contra una base de datos real.

### Estado y límites

No se generó `config.inc.php`, no se creó el generador, no se inició Compose ni contenedores OJS/MariaDB, no se modificaron directorios persistentes, no se publicaron imágenes y no se realizó ninguna operación en PROD. La preparación de los archivos `.env.example` y `deploy/README.md` pertenece al repositorio Gitea `encit/revista`, rama `feature/ojs-3.5-dockerfile`; no se copia esa implementación al repositorio de infraestructura.

- [x] Confirmar que existen los scripts CLI de jobs y scheduler en la imagen.
- [x] Identificar los modos `work` y `run` y sus funciones mediante inspección estática.
- [x] Confirmar que el modo sandbox bloquea el worker y el scheduler.
- [x] Identificar los ejecutores integrados `job_runner` y `task_runner`.
- [ ] Generar y validar `config.inc.php` de TEST fuera de Git.
- [ ] Ejecutar y validar worker/scheduler con configuración y base de datos funcionales.
- [ ] Validar Compose y obtener autorización independiente antes de iniciar servicios.

## 23. Decisión de sandbox para TEST y ejecución de procesos externos (27-nov-2026)

El administrador confirmó que el entorno TEST debe operar con `sandbox = Off` para permitir la validación funcional de los procesos CLI dedicados de OJS identificados en la sección 22.

La decisión se basa en el comportamiento comprobado del código de OJS 3.5.0-6: tanto `jobs.php work` como `scheduler.php work` se niegan a procesar trabajos/tareas cuando `general.sandbox` está activado. Por tanto, mantener `sandbox = On` sería incompatible con el objetivo de probar esos procesos.

**Configuración acordada para TEST:**
- `[general] sandbox = Off`.
- `[queues] job_runner = Off`, para que las solicitudes web no ejecuten también el procesador integrado.
- `[schedule] task_runner = Off`, para delegar las tareas programadas al scheduler externo.
- `[queues] process_jobs_at_task_scheduler = Off`, manteniendo al worker dedicado como consumidor de la cola y evitando que el scheduler procese trabajos en paralelo.
- El worker dedicado se ejecutará mediante `php lib/pkp/tools/jobs.php work`.
- El scheduler dedicado se ejecutará mediante `php lib/pkp/tools/scheduler.php work`.

**Control de integraciones externas:** al desactivar sandbox, TEST ya no cuenta con esa barrera de OJS frente a interacciones con sistemas externos. El correo de TEST deberá configurarse explícitamente hacia Mailpit (SMTP interno, puerto 1025) y no hacia servidores SMTP reales. Cualquier otra integración externa deberá permanecer sin configurar o bloqueada durante las pruebas, salvo autorización específica.

La variable `OJS_SANDBOX` del ejemplo de entorno TEST debe cambiar a `Off` para reflejar esta decisión. La plantilla de PROD permanece independiente y no se modifica con esta decisión.

**Estado actualizado:** el administrador confirmó que `OJS_SANDBOX=Off` ya está aplicado en `deploy/testing/.env.example` del checkout local de Gitea. La rama observada es `feature/ojs-3.5-dockerfile`, HEAD `c8ffebc`; Git reporta `?? deploy/`, por lo que los archivos de despliegue siguen sin seguimiento y no se ha confirmado commit ni push en Gitea. El cambio queda aplicado en el árbol de trabajo local, no publicado.

No se ha generado `config.inc.php`, no se ha iniciado Compose ni contenedores, no se ha probado worker/scheduler contra una base de datos y no se ha modificado PROD.

- [x] Aprobar `sandbox = Off` para TEST con el fin de validar worker y scheduler.
- [x] Definir el worker dedicado como consumidor de la cola.
- [x] Definir scheduler externo sin procesamiento de cola integrado.
- [x] Establecer Mailpit como destino SMTP de TEST y excluir SMTP real.
- [x] Aplicar `OJS_SANDBOX=Off` en el ejemplo TEST del árbol de trabajo Gitea (pendiente de seguimiento/commit).
- [ ] Generar y validar `config.inc.php` de TEST fuera de Git.
- [ ] Ejecutar y validar worker/scheduler con configuración y base de datos funcionales.

## 24. Inspección de secretos OJS y política del generador de configuración (27-nov-2026)

Se inspeccionó el template oficial `config.TEMPLATE.inc.php` y el código fuente incluido en la imagen local `encit/revista:ojs-3.5.0-6-test`. La inspección fue estática y de sólo lectura.

### Formato de los secretos

- `[general] app_key`: `PKP\\core\\PKPAppKey::generate()` genera una clave con formato `base64:` seguido de Base64 de una clave criptográfica. El cifrado predeterminado es `aes-256-cbc`, que requiere 32 bytes. El generador externo podrá reproducir el algoritmo oficial mediante 32 bytes obtenidos con un CSPRNG y codificación Base64, conservando el prefijo `base64:`.
- `[security] salt`: se utiliza como clave de `hash_hmac` para generar hashes de restablecimiento de contraseña. No se encontró una restricción de formato en el uso inspeccionado. Se propone un valor aleatorio independiente de 32 bytes representado como 64 caracteres hexadecimales.
- `[security] api_key_secret`: se utiliza como secreto de JWT con algoritmo HS256 para firmar y validar tokens de API. Se propone un valor aleatorio independiente de 32 bytes representado como 64 caracteres hexadecimales.

Los valores deberán generarse con un generador criptográficamente seguro, ser únicos por entorno, mantenerse persistentes y no imprimirse en consola ni incorporarse a Git. La longitud/formato propuestos para `salt` y `api_key_secret` son decisiones de implementación basadas en los usos inspeccionados; no se afirma que OJS exija exclusivamente esa representación.

### Política de creación y protección

El administrador aprobó que el generador se niegue a sobrescribir un `config.inc.php` existente. La implementación deberá fallar sin modificarlo, evitando reemplazar claves o configuración de una instalación ya inicializada. Se acordó además que el proceso:

1. Lea la imagen desde la variable `IMAGE` del entorno, sin usar etiquetas placeholder.
2. Obtenga el template oficial `/var/www/html/config.TEMPLATE.inc.php` de esa imagen.
3. Modifique únicamente las directivas acordadas y preserve el resto del template, incluidos comentarios.
4. Valide variables, rutas y precondiciones antes de escribir.
5. Genere secretos independientes sin mostrarlos.
6. Cree el archivo de forma exclusiva y atómica, usando un temporal en el mismo directorio y sin reemplazar un destino existente.

### Implementación y revisión estática del generador (27-nov-2026)

El administrador implementó en el checkout local de Gitea `encit/revista`, rama `feature/ojs-3.5-dockerfile`, el archivo `deploy/scripts/generate-config.sh`. La salida de Git continúa mostrando `?? deploy/`: el directorio y sus archivos todavía no están seguidos por Git y no se ha confirmado commit ni push en Gitea.

Se revisó el contenido completo del script y se ejecutaron las siguientes validaciones, con resultados reportados por el administrador:

- `bash -n deploy/scripts/generate-config.sh`: correcto.
- Extracción del bloque Python incrustado y `python3 -m py_compile`: correcto.
- La referencia de imagen `encit/revista:ojs-3.5.0-6-test` queda admitida por la expresión regular de `IMAGE`.
- La ruta del host `OJS_FILES_DIR` se valida como directorio existente, pero la configuración de OJS utiliza la ruta interna `/var/ojs-files`, que es el destino previsto del volumen Docker.
- `OJS_PUBLIC_DIR` se valida como directorio existente y `public_files_dir` conserva el valor relativo `public`.
- El script exige ejecución como root, comprueba que `config.inc.php` no exista, crea un temporal en el mismo directorio, aplica propietario numérico `33:33` y modo `0640`, y publica con `os.link` para no reemplazar un destino existente.
- Se comprobó que el template de la imagen contiene las directivas requeridas, incluidas las líneas SMTP comentadas que el script activa y configura.
- Los directorios `files`, `public` y `config` de TEST se observaron con propietario `33:33` y modo `0750`. Las ACL de los directorios padre restringen el acceso de otros usuarios; el usuario de sesión `administrador` no puede inspeccionar directamente la ruta sin privilegios.

El generador configura SMTP sin autenticación, acorde con Mailpit en TEST (`mailpit:1025`). Aunque el ejemplo de entorno contiene `SMTP_USER` y `SMTP_PASSWORD`, el script no utiliza esas variables; deben permanecer vacías para esta configuración. La autenticación SMTP no está implementada por este generador.

### Estado y límites

La revisión anterior confirma sintaxis y correspondencia estática con el template, pero **no equivale a una prueba de ejecución del generador**. No se ha ejecutado `generate-config.sh`, no se ha creado `config.inc.php`, no se han generado secretos, no se ha iniciado Compose ni contenedores OJS/MariaDB, no se han modificado ACL o permisos y no se ha realizado ninguna operación en PROD.

- [x] Inspeccionar el generador oficial de `app_key` y confirmar el cifrado predeterminado.
- [x] Identificar el uso de `salt` en HMAC para recuperación de contraseñas.
- [x] Identificar el uso de `api_key_secret` para JWT HS256.
- [x] Aprobar la política de no sobrescritura de `config.inc.php`.
- [x] Implementar `deploy/scripts/generate-config.sh` en el árbol de trabajo local de Gitea (sin commit/push).
- [x] Validar sintaxis Bash y Python del script.
- [x] Revisar estáticamente las guardas, directivas del template, rutas y escritura exclusiva.
- [x] Ejecutar una prueba controlada del generador en TEST con autorización y validar el archivo sin revelar secretos.
- [ ] Incorporar los artefactos `deploy/` al seguimiento Git y publicarlos en Gitea mediante el flujo autorizado.
- [ ] Generar `config.inc.php` de TEST fuera de Git, sólo después de la prueba controlada y autorización expresa.


## 25. Primera ejecución controlada del generador: directiva duplicada (27-nov-2026)

El administrador ejecutó en el host TEST `pruebas` la prueba controlada de `deploy/scripts/generate-config.sh`, usando un directorio temporal y valores ficticios. La precondición reportó que la imagen local y los directorios de referencia estaban disponibles. La ejecución se detuvo con el error:

```text
ERROR: directiva duplicada: [general] time_zone.
```

La inspección posterior del template oficial incluido en `encit/revista:ojs-3.5.0-6-test` confirmó que `[general]` ya contiene la directiva activa `time_zone = "UTC"` (línea 63 del template observado). Por tanto, el generador no debe insertar una segunda directiva: debe actualizar la existente preservando el resto del template. La salida compartida no incluyó el fragmento del generador que realiza la sustitución; la corrección concreta queda pendiente de revisar ese bloque.

**Resultado y alcance:** la prueba no fue satisfactoria. No se considera validado el generador y no se generó una configuración válida. El procedimiento de prueba utilizaba un directorio temporal con datos ficticios; no se reportó modificación de la configuración persistente TEST, inicio de OJS/MariaDB ni operación en PROD. La conexión SSH se cerró después del error.

- [x] Confirmar disponibilidad de imagen y directorios de referencia para la prueba.
- [x] Registrar el error de directiva duplicada en `[general] time_zone`.
- [x] Confirmar que el template oficial ya contiene `time_zone = "UTC"`.
- [ ] Revisar el bloque del generador que actualiza las directivas de `[general]`.
- [ ] Corregir la actualización de `time_zone` sin duplicar la directiva.
- [ ] Repetir la prueba controlada y validar todas las propiedades del archivo temporal.
- [ ] Generar `config.inc.php` persistente de TEST sólo con autorización expresa posterior.


## 26. Corrección y validación satisfactoria del generador (27-nov-2026)

Después de la primera ejecución fallida registrada en la sección 25, se corrigió el bloque Python de `deploy/scripts/generate-config.sh` en el checkout local de Gitea `encit/revista`, rama `feature/ojs-3.5-dockerfile`.

### Correcciones aplicadas

1. La búsqueda de directivas distingue coincidencias activas y comentadas. Si existe una directiva activa, se actualiza esa línea y se conserva la muestra comentada; si sólo existe una línea comentada, se activa y configura. Los duplicados activos continúan provocando un error.
2. Se inicializa explícitamente `lines = content.splitlines(keepends=True)` después de leer el template, conservando los finales de línea antes de recorrer y reconstruir el contenido. Esta inicialización corrigió el `NameError: name 'lines' is not defined` encontrado en la primera repetición de la prueba.

El administrador reportó `bash -n` correcto y verificó que la inicialización de `lines` aparece una sola vez y antes del recorrido y la concatenación.

### Prueba controlada final

La prueba se ejecutó en TEST con la imagen local `encit/revista:ojs-3.5.0-6-test`, un directorio temporal y valores ficticios de base de datos. No se utilizó la ruta persistente de configuración OJS.

El generador terminó con los mensajes:

- `OK: config.inc.php creado de forma exclusiva.`
- `OK: template oficial preservado con directivas acordadas.`
- `OK: secretos generados sin mostrarlos.`
- `OK: installed=Off; sandbox=Off; ejecutores integrados desactivados.`

Las comprobaciones del archivo temporal confirmaron:

- Cabecera de protección del template preservada.
- `installed=Off`, `sandbox=Off` y `time_zone=America/Mexico_City`, con una sola directiva activa `time_zone`.
- URL de TEST y base de datos ficticia.
- `files_dir="/var/ojs-files"` y `public_files_dir="public"`.
- `force_ssl=On`, SMTP configurado hacia `mailpit:1025`, worker y scheduler integrados desactivados.
- `app_key` Base64 decodifica a 32 bytes; `salt` y `api_key_secret` tienen 64 caracteres hexadecimales y son distintos.
- Propietario numérico `33:33`, modo `0640` y lectura efectiva por el usuario `www-data`.
- Un segundo intento rechazó la existencia de `config.inc.php`; el SHA-256 del archivo permaneció idéntico, confirmando que no se sobrescribió.

Durante la prueba de lectura se ajustó el permiso de recorrido del directorio temporal de prueba a `0711`. El archivo conservó `33:33` y `0640`; el ajuste no se aplicó a la persistencia de OJS.

**Resultado:** prueba controlada satisfactoria. Queda validado el comportamiento de generación, permisos, lectura y no sobrescritura del generador con la imagen y valores de prueba observados.

### Límites y estado operativo

La prueba generó únicamente un archivo temporal, eliminado al finalizar el procedimiento. No se creó `config.inc.php` en `/srv/encit/data/revista/test/config`, no se inició Compose ni ningún contenedor OJS/MariaDB, no se publicaron artefactos en Gitea y no se modificó PROD. La configuración persistente de TEST sigue pendiente de autorización expresa independiente.

- [x] Corregir la selección de directivas activas/comentadas y la inicialización de `lines`.
- [x] Repetir la prueba controlada con valores ficticios.
- [x] Validar contenido, formato de secretos, propietario, modo y lectura por `www-data`.
- [x] Verificar rechazo de sobrescritura y conservación del archivo.
- [ ] Generar `config.inc.php` persistente de TEST sólo con autorización expresa posterior.
- [ ] Validar Compose y obtener autorización independiente antes de iniciar servicios.
