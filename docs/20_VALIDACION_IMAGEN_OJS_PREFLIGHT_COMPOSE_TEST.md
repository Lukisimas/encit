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

- [x] Inspeccionar contenido inicial y permisos de `public` y `cache` en la imagen.
- [x] Confirmar UID/GID OJS `33:33` y modos `0750` de los directorios.
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
