# Checklist de go-live

## Red y publicación

- [ ] DNS interno del equipo perimetral resuelve DEV/TEST/INFRA correctamente.
- [x] Registro DNS público A de `xitle.encit.unam.mx` creado y apuntando a `132.247.168.166` (confirmado por el administrador).
- [x] Resolución A de Xitle comprobada desde Cloudflare y Google; ambos devuelven `132.247.168.166` (ver `docs/15_VALIDACION_PUBLICA_XITLE.md`).
- [x] Consulta AAAA realizada; no se observa registro AAAA publicado.
- [x] Port Forward TCP/80 y TCP/443 de OPNsense revisados: WAN address hacia `10.129.101.2`, conservando los puertos.
- [x] Regla WAN automática de HTTP confirmada como Pass y habilitada, con destino `10.129.101.2:80`.
- [x] Regla WAN automática de HTTPS confirmada como Pass y habilitada, con destino `10.129.101.2:443`.
- [x] Interfaz de producción `ens15f0` y ruta predeterminada del servidor revisadas (`10.129.101.2/28`, gateway `10.129.101.1`).
- [x] Conectividad IP del servidor de producción con el gateway `10.129.101.1` comprobada: 4/4 respuestas, 0 % de pérdida, RTT promedio 0.233 ms (ver `docs/15_VALIDACION_PUBLICA_XITLE.md`).
- [x] Salida IP a Internet desde el servidor de producción comprobada mediante `ping` a `1.1.1.1` (2/2 respuestas, 0 % de pérdida, RTT promedio 4.095 ms; prueba interrumpida manualmente tras dos respuestas; ver `docs/15_VALIDACION_PUBLICA_XITLE.md`).
- [ ] Firewall local del servidor permite los puertos requeridos.
- [ ] Proxy de producción instalado y escuchando en TCP/80 y TCP/443 (inspección actual: solo SSH escucha en TCP/22; HTTP/HTTPS aún sin listeners, condición esperada antes de instalar el proxy).
- [ ] TCP/80 y TCP/443 comprobados desde una red externa después de instalar el proxy (la prueba previa a la instalación quedó registrada como línea base no concluyente en `docs/15_VALIDACION_PUBLICA_XITLE.md`).
- [ ] Routing y ACL del switch L3 validados.
- [ ] DEV/TEST/INFRA no son accesibles desde Internet.
- [ ] Jenkins/Gitea restringidos a las VLAN/usuarios autorizados.
- [ ] Si se migró DHCP, una estación piloto recibió IP/gateway/DNS correctos y existe rollback.
- [ ] Configuración del equipo perimetral y switch respaldada.

## Plataforma de control (Gitea/Jenkins)

- [x] Primera implementación de Gitea 1.27.1, PostgreSQL 17, Jenkins, Docker-in-Docker, Nginx y Mailpit documentada en `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`.
- [x] Seis contenedores de la plataforma observados activos en el host de control.
- [x] Persistencia de Gitea y Jenkins, volúmenes de Docker-in-Docker y montaje de CA institucional observados.
- [x] Gitea Packages / Container Registry habilitado en el Compose versionado.
- [x] Gitea Packages confirmado habilitado en `app.ini` y en `GITEA__packages__ENABLED` (ver `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`).
- [x] Corregir la entrada local de `/etc/hosts` en `pruebas`: `git.infra.encit.unam.mx` apunta a `10.129.100.2`, servidor DEV/TEST que aloja Gitea y el proxy; `getent ahostsv4` confirma la dirección.
- [ ] Mantener separado el direccionamiento: `132.247.168.166` es la IP WAN de OPNsense para publicación de producción (NAT a `10.129.101.2`), no el destino de Gitea.
- [ ] Crear/validar el registro o override DNS interno para los demás equipos autorizados. Las consultas A a DNS institucionales y públicos devolvieron `NXDOMAIN`; configurar, si corresponde, un override interno hacia `10.129.100.2`. No publicar el hostname de infraestructura en DNS público ni considerar modificada la configuración de OPNsense.
- [x] Inventariar y eliminar los seis jobs temporales de Jenkins (`gitea-api-auth-test`, `gitea-connectivity-test`, `gitea-healthcheck`, `gitea-registry-login-test`, `gitea-registry-smoke-test` y `prueba-gitea`); verificación final: `TOTAL_WORKFLOW_JOBS_RESTANTES=0` (ver `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`, sección 12).
- [ ] Confirmar versión Java en runtime y conectividad TLS Jenkins → Docker-in-Docker.
- [x] Cuenta local `jenkins` creada en Gitea y confirmada por el administrador como identidad técnica prevista.
- [x] Credencial Jenkins `gitea-jenkins-token` registrada en el almacén System / Global; descripción: `Token API Gitea - cuenta técnica Jenkins ENCiT`.
- [x] Credencial Jenkins `gitea-jenkins-api` registrada en el ámbito System scope / System / Global; descripción: `Token API Gitea - integración Jenkins`.
- [ ] Verificar vigencia y scopes de ambas credenciales sin revelar sus valores; confirmar cuál se utilizará para API de Gitea y cuál para Container Registry.
- [x] Confirmar permisos efectivos de la cuenta técnica `jenkins` sobre el namespace de prueba mediante push/pull.
- [x] Cliente Docker disponible en `pruebas`: CLI y Engine `29.7.2`; `sudo docker version` e `info` respondieron correctamente. Usuario `administrador` (UID 1000), sin pertenencia al grupo `docker`; se utilizará `sudo`.
- [x] Validar desde Jenkins `docker login`, `docker push` y `docker pull` de una imagen temporal en Gitea Container Registry.
- [ ] Conciliar plugins instalados con `control/jenkins/plugins.txt`.
- [ ] Adaptar las ACL de `git`, `jenkins` y `mail` a las redes autorizadas reales; actualmente conservan el ejemplo `10.10.10.0/24`.
- [x] Validar HTTPS local de Gitea: `HTTP/2 200`; certificado wildcard vigente, SAN compatible con `git.infra.encit.unam.mx`, emitido por `ENCiT Internal Root CA`.
- [x] Validar endpoint Registry `/v2/` por hostname: `HTTP/2 401` con desafío Bearer y cabecera `docker-distribution-api-version: registry/2.0` (respuesta esperada sin autenticación).
- [x] CA raíz ENCiT localizada en `/usr/local/share/ca-certificates/encit-internal-root-ca.crt` en el host `pruebas`; `curl` sin `-k` validó HTTPS de Gitea (HTTP 200) y Registry `/v2/` (HTTP 401 esperado), con `TLS verify result: 0` en ambos casos. Validación documentada en `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`. Alcance limitado al host `pruebas`; falta validar otros clientes, Jenkins y Docker-in-Docker.
- [x] Validar autenticación y publicación/descarga de imagen de prueba en Gitea Container Registry; digest registrado en `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`.

## Aplicación Xitle (OJS)

- [x] Docker Engine `29.7.2`, Docker Compose `v5.5.0` y daemon activo comprobados en producción.
- [x] Usuario `deploy` (`1001:1001`) y pertenencia al grupo `docker` (`989`) comprobados.
- [x] Identidad `www-data` (`33:33`) comprobada para OJS.
- [x] Volumen `/data` comprobado: `/dev/sdb1`, ext4, UUID `5d642b08-fac8-48fa-8f9b-5976c66af37c`, montado correctamente.
- [x] Estado inicial previo al bootstrap comprobado: red `encit_prod_edge` y directorios base aún no existen; el script los crea.
- [x] Ejecutar manualmente `repos/infrastructure/bootstrap/prepare-production-host.sh` como root; el administrador reportó el mensaje final esperado sin errores.
- [x] Verificar directorios, propietarios/permisos y red `encit_prod_edge` tras el bootstrap; directorios y modos coinciden con el diseño. Pendiente revisar solapamiento de la subred Docker `172.18.0.0/16` con rutas institucionales/VPN.
- [ ] Variables de producción preparadas fuera de Git.
- [x] Inventario Docker del host DEV/TEST documentado en `docs/16_VALIDACION_DOCKER_DEVTEST.md`; no se encontraron imágenes/containers OJS ni MariaDB locales. Pendiente identificar el pipeline y tag probado.
- [ ] Resolver la duplicación de subred `172.18.0.0/16` entre `encit_control_edge` (DEV/TEST) y `encit_prod_edge` (PROD), según el modelo de conectividad requerido.
- [ ] Imagen OJS identificada por tag probado en TEST.
- [ ] MariaDB inicia y supera healthcheck.
- [ ] OJS responde correctamente detrás del proxy.
- [ ] Certificado TLS de Let's Encrypt emitido e instalado.
- [ ] HTTPS validado desde Internet y redirección HTTP -> HTTPS comprobada.
- [ ] Backups verificados y restauración ensayada.
- [ ] Smoke tests automatizados.
- [ ] Ventana de mantenimiento autorizada.
- [ ] Plan de rollback documentado.
- [ ] Logs y espacio en disco monitorizados.
- [ ] Prueba de correo.
- [ ] Prueba de autenticación y roles.
- [ ] Verificación de tareas programadas.


### Jenkins: resolución interna de Gitea

- [x] Diagnosticar desde el agente Jenkins `built-in`: el nombre `git.infra.encit.unam.mx` no resolvía; Docker DNS `127.0.0.11` reenviaba a DNS institucionales que no conocen el nombre interno.
- [x] Confirmar que el host `pruebas` resuelve `git.infra.encit.unam.mx` a `10.129.100.2`.
- [x] Añadir `extra_hosts: ["git.infra.encit.unam.mx:10.129.100.2"]` al servicio `jenkins` en `/srv/encit/platform/control/docker-compose.yml`.
- [x] Validar sintaxis y configuración efectiva con `sudo docker compose config -q`; Compose muestra `git.infra.encit.unam.mx=10.129.100.2`.
- [x] Aplicar el cambio al contenedor Jenkins de forma controlada; se recreó únicamente Jenkins y se conservó el volumen persistente.
- [x] Verificar resolución desde el contenedor Jenkins después de recrearlo: `git.infra.encit.unam.mx` resuelve a `10.129.100.2`.
- [x] Validar TLS desde el contenedor Jenkins sin `curl -k`: HTTPS `HTTP=200`, `TLS_VERIFY=0`, después de recrear el servicio con la CA incorporada a la imagen.
- [x] Validar autenticación API de Gitea desde un Pipeline sin exponer tokens en consola/logs.

**Estado actualizado (26-nov-2026):** `extra_hosts` ya está aplicado y verificado en el contenedor Jenkins; el hostname resuelve a `10.129.100.2`. La CA raíz ENCiT se incorporó al Dockerfile local, la imagen se reconstruyó y Jenkins se recreó conservando su volumen. HTTPS desde el contenedor responde `HTTP=200` con `TLS_VERIFY=0`, sin `-k`. La prueba inicial de API no llegó a TLS ni autenticación por el fallo DNS que ya fue corregido. Siguen pendientes la prueba API autenticada, login y push/pull del Registry y validación independiente de Docker-in-Docker. No se modificaron DNS institucionales ni OPNsense.


### Jenkins / Docker-in-Docker: DNS y Container Registry (26-nov-2026)

- [x] Confirmar que Jenkins usa el daemon Docker-in-Docker remoto `tcp://docker-dind:2376`.
- [x] Configurar DNS `10.129.100.1` exclusivamente en el servicio `docker-dind` del Compose operativo.
- [x] Recrear únicamente Docker-in-Docker y verificar que resuelve `git.infra.encit.unam.mx` a `10.129.100.2`.
- [x] Validar API de salud desde Jenkins: `HTTP=200`, `TLS_VERIFY=0`.
- [x] Validar API autenticada de Gitea: `HTTP=200`, login `jenkins`.
- [x] Identificar que el token previo carecía de scopes de Packages; emitir token técnico con `read:package` y `write:package` y actualizar `gitea-jenkins-token` sin revelar el secreto.
- [x] Validar `docker login` desde Jenkins: `Login Succeeded`.
- [x] Construir y publicar `git.infra.encit.unam.mx/jenkins/registry-smoke-test:smoke-1`.
- [x] Eliminar la copia local y descargar de nuevo la imagen con `docker pull`.
- [x] Verificar digest `sha256:7355685748d5f6c0af030b9cc154385b223b3050e481f4a0a1b46ae145af13a8`.
- [ ] Decidir y, con autorización, eliminar el paquete remoto temporal `jenkins/registry-smoke-test:smoke-1`.
- [ ] Incorporar la configuración DNS y el flujo de publicación en la configuración versionada/automatizada apropiada, después de revisar el Compose operativo frente al repositorio.
- [ ] Diseñar y probar el Jenkinsfile real de OJS/Xitle y el flujo de promoción de la misma imagen de TEST a PROD.

**Estado actualizado:** la integración de red, TLS, API y Container Registry entre Jenkins y Gitea está validada con una imagen temporal. No se han probado todavía los pipelines de construcción ni despliegue de OJS.


### Limpieza de jobs temporales de Jenkins (26-nov-2026)

- [x] Inventario de sólo lectura: seis jobs, todos `WorkflowJob` y habilitados.
- [x] Eliminar los seis jobs temporales identificados en el inventario.
- [x] Verificación posterior: `TOTAL_WORKFLOW_JOBS_RESTANTES=0`.
- [x] Confirmar que la operación se limitó a jobs de Jenkins; no se eliminaron credenciales ni paquetes del Container Registry.
- [ ] Diseñar e implementar el Jenkinsfile versionado para CI/CD de OJS/Xitle.

La eliminación de los jobs temporales no elimina el paquete remoto `jenkins/registry-smoke-test:smoke-1` que se publicó durante la prueba de Registry; su limpieza se mantiene como decisión independiente.


### Diseño CI/CD de Revista Xitle (26-nov-2026)

- [x] Definir arquitectura objetivo build once/promote many, digest OCI inmutable, separación TEST/PROD, aprobación manual y rollback (ver `docs/18_DISENO_CICD_XITLE_OJS.md`).
- [x] Documentar etapas, contrato de imagen, controles de seguridad y decisiones pendientes.
- [x] Elaborar el diseño técnico de OJS, contenedores, redes, persistencia, seguridad, operación y CI/CD (ver `docs/19_DISENO_TECNICO_REVISTA_XITLE_OJS.md`).
- [ ] Definir namespace definitivo de imagen en Gitea y permisos mínimos.
- [ ] Validar método de despliegue remoto Jenkins → TEST/PROD y host keys.
- [ ] Implementar Jenkinsfile desde SCM y validar primero build/test/push.
- [ ] Implementar y probar despliegue TEST y smoke tests.
- [ ] Ensayar backup/restauración y rollback de OJS/MariaDB/archivos.
- [ ] Añadir aprobación manual y promoción del mismo digest a PROD.

El documento describe una arquitectura propuesta; no implica que exista ya un Jenkinsfile, job productivo, Compose OJS funcional o conectividad SSH validada.

### Creación del repositorio Gitea de Revista Xitle (26-nov-2026)

- [x] Crear repositorio privado `encit/revista` dentro de la organización institucional `encit`.
- [x] Confirmar visualmente la rama predeterminada `main`.
- [x] Confirmar acceso del administrador al repositorio desde la interfaz web.
- [ ] Agregar `README.md` y `.gitignore` y verificar el primer commit.
- [ ] Inspeccionar el árbol y contenido real del repositorio ya inicializado.
- [ ] Definir e incorporar Dockerfile, Compose, configuración no secreta, pruebas y Jenkinsfile según la inspección y el diseño aprobado.

La API consultada sin autenticación respondió HTTP 404; no se interpreta como inexistencia porque el repositorio es privado y el administrador confirmó acceso autenticado. El repositorio todavía no contiene `README.md` según la inspección visual reportada. No se ha implementado ni desplegado OJS.


### Repositorio Gitea de Revista Xitle inicializado (26-nov-2026)

- [x] Crear y publicar el primer commit en la rama `main` del repositorio privado `encit/revista`.
- [x] Incorporar `README.md` y `.gitignore`.
- [x] Verificar la publicación mediante `git push origin main` y el árbol del commit.

Commit inicial: `9d1f0ce` — `docs: inicializar repositorio de Revista Xitle`. Autor: Alan Uriel Gil Casas (`alan.gil@encit.unam.mx`). La identidad Git se configuró sólo a nivel local del repositorio.

**Pendiente:** inspeccionar el árbol y los archivos reales antes de diseñar e incorporar Dockerfile, Compose, Jenkinsfile y componentes OJS. La inicialización del repositorio no equivale a tener OJS instalado ni desplegado.


### Copia local de Revista Xitle en TEST

- [x] Confirmar que el repositorio remoto privado `encit/revista` está inicializado en Gitea, rama `main`, commit `9d1f0ce`, con `README.md` y `.gitignore`.
- [x] Localizar rutas candidatas en TEST: `/home/administrador/encit_arquitectura_institucional/repos/revista`, `/srv/encit/apps/revista` y `/srv/encit/backups/revista`.
- [x] Comprobar que la primera ruta no contiene `.git`; no es una copia Git verificada.
- [ ] Inspeccionar contenido y propósito de `/srv/encit/apps/revista` y `/srv/encit/backups/revista` antes de usarlas.
- [ ] Al iniciar la fase de implementación, acordar ubicación de trabajo y clonar `encit/revista` en TEST.
- [ ] En la fase de implementación, verificar rama `main`, SHA del commit, `git status` y árbol de archivos en TEST.

**Estado (26-nov-2026):** el repositorio remoto está publicado, pero todavía no está clonado en el servidor `pruebas` (TEST). La inspección terminó con “No se encontró una copia Git de revista en las rutas inspeccionadas”. No hay Dockerfile, Compose, Jenkinsfile ni instalación OJS local verificados en ese host.


### Diseño técnico de Revista Xitle (26-nov-2026)

- [x] Documentar arquitectura objetivo de OJS 3.5.x, PHP, MariaDB, Apache/PHP, Nginx, redes y persistencia.
- [x] Definir separación de TEST/PROD y criterios de seguridad, backups, operación y aceptación.
- [x] Definir el flujo CI/CD build once/promote many por digest OCI y aprobación manual de PROD.
- [ ] Revisar y aprobar las decisiones técnicas y requisitos editoriales pendientes del documento docs/19_DISENO_TECNICO_REVISTA_XITLE_OJS.md.
- [ ] Inspeccionar capacidad y montajes de almacenamiento en ambos hosts antes de fijar rutas persistentes.
- [ ] Iniciar la implementación en encit/revista después de aprobar el diseño; clonar será una actividad de implementación, no una condición para diseñar.
- [ ] Fijar parche OJS, PHP y MariaDB exactos tras validar compatibilidad con el paquete oficial.
- [ ] Construir imagen y Compose TEST; instalar y probar el flujo editorial.
- [ ] Implementar Jenkinsfile y validar build/test/push/deploy TEST.
- [ ] Ensayar backup/restauración de base de datos y archivos.
- [ ] Preparar PROD y promover el mismo digest con autorización explícita.

**Estado:** el diseño técnico está documentado, pero no está implementado. El repositorio remoto contiene únicamente su inicialización. No hay instalación OJS ni despliegue de Xitle confirmado.


### Revisión de base de datos y almacenamiento (26-nov-2026)

- [x] Descartar reutilización de un MySQL de PROD: no se encontró una instancia confirmada en el inventario disponible.
- [x] Adoptar MariaDB 11.8.10 dedicada como versión candidata, fijada por tag/digest; validar OJS 3.5.0-6 y backup/restauración en TEST.
- [x] Definir distribución de persistencia PROD: MariaDB/config/cache en SSD RAID1; `files_dir` y `public` en HDD RAID5.
- [x] Documentar rutas objetivo PROD sin crearlas.
- [x] Incorporar redes Docker existentes de TEST y aislar la base de datos de la red de borde.
- [ ] Inspeccionar almacenamiento de TEST (discos, RAID, filesystem, capacidad, montajes y Docker Root Dir) antes de fijar rutas OJS.
- [ ] Validar UID/GID y permisos de la imagen MariaDB y del proceso PHP antes de crear directorios persistentes.
- [ ] Definir destino de backup independiente del host PROD y ensayar restauración integral DB + archivos.
- [ ] Confirmar paquete oficial OJS 3.5.0-6, checksum y PHP 8.3 mediante pruebas de plataforma.

**Nota:** los inventarios de PROD corresponden a la inspección del 21-nov-2026. Los directorios indicados son rutas objetivo de diseño, no rutas creadas en el servidor.


### Validación de almacenamiento y redes de Revista Xitle (26-nov-2026)

- [x] Inventariar almacenamiento TEST: disco único `/dev/sda`, ext4 en `/`, 847 GiB disponibles; sin `/data` ni segundo disco.
- [x] Confirmar Docker Root Dir TEST en `/var/lib/docker` y revisar persistencia existente de Gitea/Jenkins.
- [x] Confirmar que `/srv/encit/data/revista` todavía no existe en TEST; proponer rutas independientes bajo `/srv/encit/data/revista/test/` sin crearlas.
- [x] Inventariar redes Docker TEST: edge 172.18.0.0/16; Jenkins internal 172.19.0.0/16; Gitea internal 172.20.0.0/16; Jenkins egress 172.21.0.0/16.
- [x] Confirmar almacenamiento PROD: SSD ext4 en `/` con 392 GiB libres y HDD ext4 en `/data` con aproximadamente 62 TiB libres.
- [x] Confirmar que existen vacíos los directorios PROD de MariaDB, config, cache, files y public, con propietarios/permisos observados y separación SSD/HDD.
- [x] Confirmar red `encit_prod_edge` 172.18.0.0/16 y ausencia de contenedores Docker en el inventario de PROD.
- [ ] Validar UID/GID de las imágenes exactas de OJS y MariaDB antes de montar persistencia.
- [ ] Crear las rutas TEST únicamente cuando se autorice iniciar la implementación.
- [ ] Definir destino de backup independiente del host PROD y ensayar restauración integral DB + archivos.

**Alcance de la validación:** inspección de solo lectura. No se crearon directorios ni contenedores; no se cambiaron propietarios/permisos ni se modificaron DNS, OPNsense, NAT o proxy.
