# Implementación inicial de la plataforma de control (Gitea y Jenkins)

**Fecha de inspección:** 26 de noviembre de 2026  
**Host:** `pruebas` — `10.129.100.2/28`, VLAN 50  
**Rama:** `docs/storage-xitle-hostnames`  
**Compose:** `repos/infrastructure/control/docker-compose.yml`

## Alcance y criterio

Esta nota registra la primera implementación de la plataforma común de control y la contrasta con el inventario que el administrador ejecutó en el host. Se separan explícitamente:

- **Implementado en el repositorio:** configuración declarada en Compose, Dockerfile, plugins y Nginx.
- **Observado en el host:** contenedores, imágenes, montajes, job y plugins instalados reportados.
- **Pendiente de validación:** comportamiento funcional, conectividad, integración y publicación real de imágenes.

La inspección reportada fue de lectura. No se hicieron cambios en los servidores, contenedores, redes, OPNsense ni credenciales.

## 1. Servicios de la plataforma

El Compose define un único proyecto `encit-control-platform` con seis servicios:

| Servicio | Imagen / construcción | Función |
|---|---|---|
| `gitea-db` | `postgres:17` | Base PostgreSQL de Gitea; red interna y healthcheck con `pg_isready`. |
| `gitea` | `docker.gitea.com/gitea:1.27.1` | Repositorios Git y Packages/Container Registry. |
| `docker-dind` | `docker:29-dind` | Daemon Docker dedicado para los builds ejecutados por Jenkins. |
| `jenkins` | Imagen construida desde `control/jenkins/Dockerfile` | Orquestación de pipelines. |
| `mailpit` | `axllent/mailpit:v1.30.6` | Captura de correo para DEV/TEST. |
| `proxy` | `nginx:1.30.4` | Reverse proxy HTTPS para servicios de infraestructura y entornos. |

El inventario del host reportó los seis contenedores activos correspondientes a estos servicios. También reportó PostgreSQL y Mailpit saludables en el momento de la inspección. Esto confirma que los contenedores estaban ejecutándose; no equivale a una prueba funcional de cada aplicación.

## 2. Gitea y su almacenamiento

Configuración declarada:

- Gitea `1.27.1`, con PostgreSQL 17.
- URL canónica: `https://git.infra.encit.unam.mx/`.
- Dominio HTTP y SSH: `git.infra.encit.unam.mx`.
- Servidor SSH integrado habilitado dentro del contenedor en el puerto 22; publicado en el host como TCP/2222.
- Large File Storage (LFS) con secreto configurado mediante variable de entorno.
- Gitea Packages habilitado mediante `GITEA__packages__ENABLED=true`.
- Persistencia de Gitea: `/srv/encit/data/gitea/data -> /data`.
- Persistencia de PostgreSQL: `/srv/encit/data/gitea/postgres -> /var/lib/postgresql/data`.
- Gitea participa en `gitea_internal` y `encit_control_edge`; el alias de red es `gitea`.

### Container Registry

La implementación seleccionada es el Container Registry integrado en Gitea Packages, no un servicio `registry:2` separado. El endpoint se deriva del host de Gitea, por lo que la referencia prevista para imágenes es del tipo:

`git.infra.encit.unam.mx/OWNER/IMAGE:TAG`

La ruta exacta de imagen, namespace, permisos y credenciales debe definirse con las cuentas y organizaciones reales. No registrar tokens ni contraseñas en Git.

**Estado:** habilitado y confirmado en runtime. La inspección de sólo lectura encontró `packages.ENABLED=true` en `/data/gitea/conf/app.ini` y `GITEA__packages__ENABLED=true` en el entorno del contenedor. Ambos indicadores coinciden. Esta comprobación confirma que la función está habilitada en la configuración efectiva; no demuestra todavía autenticación, permisos, login, push/pull ni publicación desde Jenkins. Esas operaciones requieren una prueba controlada posterior.

## 3. Jenkins y Docker-in-Docker

### Jenkins

El Dockerfile construye sobre `jenkins/jenkins:2.568.2-jdk21` y añade:

- Cliente Docker CLI copiado desde `docker:29-cli`.
- `git`, `openssh-client`, `curl`, `jq` y `ca-certificates`.
- Plugins declarados en `control/jenkins/plugins.txt`.

El volumen persistente observado es `/srv/encit/data/jenkins/home -> /var/jenkins_home`. Jenkins no publica puertos directamente en el host; se expone a través del proxy en la red `encit_control_edge`, puerto interno 8080.

El Compose configura Jenkins para usar el daemon dedicado:

- `DOCKER_HOST=tcp://docker-dind:2376`
- TLS habilitado con `DOCKER_TLS_VERIFY=1`.
- Certificados cliente compartidos mediante el volumen `jenkins_docker_certs`, montado de sólo lectura en Jenkins.

### Docker-in-Docker

El servicio `docker-dind`:

- Usa `docker:29-dind` y modo `privileged: true`.
- Escucha para el cliente Docker por TLS (2376).
- Conserva los datos del daemon en el volumen `jenkins_docker_data`.
- Comparte el volumen de certificados TLS con Jenkins.
- Recibe la CA raíz institucional en modo sólo lectura y ejecuta `update-ca-certificates` al iniciar.
- Permanece en la red interna `jenkins_internal`, no en la red del proxy.

La salida del host confirmó los montajes de datos y certificados de Docker-in-Docker y el montaje de la CA institucional en ambos contenedores. No se validó todavía una conexión TLS efectiva desde Jenkins al daemon ni la confianza de la CA contra Gitea. En el host físico `pruebas`, la CA raíz está instalada y la conexión HTTPS a Gitea ya fue validada sin `-k`; esta prueba no cubre los contenedores Jenkins ni DinD.

### Plugins

El archivo versionado `control/jenkins/plugins.txt` declara ocho plugins directos:

- `workflow-aggregator`
- `git`
- `credentials-binding`
- `ssh-agent`
- `docker-workflow`
- `pipeline-stage-view`
- `configuration-as-code`
- `matrix-auth`

El inventario del host reportó un conjunto mayor de plugins instalados, incluyendo `gitea`, `github`, `github-branch-source`, `docker-commons`, `git-client`, `credentials`, `workflow-multibranch` y dependencias transitivas. La lista instalada no coincide uno a uno con el archivo de plugins directos; antes de normalizarla se debe identificar qué plugins fueron añadidos manualmente, cuáles son dependencias y cuáles se requieren para los jobs actuales.

La versión Java no quedó confirmada: el comando de inspección terminó con error en `head` (`invalid number of lines: ‘2}’`). El Dockerfile sí declara JDK 21 como base, pero falta comprobar la versión del proceso en ejecución.

## 4. Jobs y estado inicial de Jenkins

El inventario inicial del directorio de Jenkins reportó un único job: `prueba-gitea`. La inspección de sólo lectura del XML confirmó que era un job Pipeline (`flow-definition`) con definición `CpsFlowDefinition` y un script inline de 14 líneas, sin SCM, triggers, builders ni publishers declarados.

El job fue creado únicamente como prueba puntual de comunicación entre Jenkins y Gitea; no era un pipeline de despliegue ni evidencia de checkout automatizado, uso de un `Jenkinsfile` desde un repositorio, construcción de imágenes o publicación al Container Registry. **Actualización del 26 de noviembre de 2026:** el job fue eliminado junto con los demás trabajos temporales, según el inventario y la limpieza documentados en la sección 12.

No se deben inferir pipelines de OJS a partir de estos jobs de prueba. El pipeline real de construcción/publicación y despliegue de OJS permanece pendiente de diseño e implementación.

## 5. Reverse proxy y certificados

El proxy Nginx escucha en TCP/80 y TCP/443 en el host y monta:

- `proxy/nginx.conf`
- `proxy/conf.d/`
- `proxy/security/`
- `certs/`

El inventario del host confirmó los puertos publicados 80 y 443. El Compose conecta el proxy a la red externa `encit_control_edge`.

Los virtual hosts revisados son:

| Host | Backend declarado |
|---|---|
| `git.infra.encit.unam.mx` | `gitea:3000` |
| `jenkins.infra.encit.unam.mx` | `jenkins:8080` |
| `mail.infra.encit.unam.mx` | `mailpit:8025` |

Los tres redirigen HTTP a HTTPS y declaran certificados `wildcard-infra.crt` y `wildcard-infra.key`. El repositorio indica que las claves privadas no deben versionarse.

### Hallazgo: ACL de ejemplo sin adaptar

Los tres virtual hosts contienen:

```nginx
allow 10.10.10.0/24;
deny all;
```

El comentario del repositorio dice que debe ajustarse a las subredes internas reales. El rango no coincide con las VLAN actuales documentadas para los servidores ENCiT (VLAN 50: `10.129.100.0/28`; VLAN 51: `10.129.101.0/28`). Esta ACL puede bloquear a usuarios legítimos o no representar el límite de acceso deseado.

**Acción pendiente:** definir las redes y orígenes autorizados (incluidas VPN y administración) y modificar las ACL sólo después de verificar el origen real que observa Nginx. No reemplazar el rango por una suposición. Mientras tanto, no declarar los virtual hosts de infraestructura como correctamente restringidos.

## 6. Mailpit

Mailpit se incorpora como servicio de soporte para pruebas y se publica internamente en el proxy como `mail.infra.encit.unam.mx`. El Compose permite autenticación SMTP de prueba aceptando cualquier usuario y contraseña y permite autenticación sin cifrado; esta configuración debe permanecer aislada en DEV/TEST y nunca reutilizarse como servidor SMTP de producción.

## 7. Redes y límites de confianza

El Compose declara:

- `gitea_internal`: red interna para Gitea y PostgreSQL.
- `jenkins_internal`: red interna para Jenkins y Docker-in-Docker.
- `encit_control_edge`: red externa compartida por proxy y servicios web de control.

El diseño separa los backends de datos y el daemon Docker del borde del proxy. Gitea y Jenkins tienen una interfaz adicional en el edge para recibir tráfico del proxy. PostgreSQL y Docker-in-Docker no se conectan al edge.

La inspección anterior reportó que `encit_control_edge` usa `172.18.0.0/16`; la red `encit_prod_edge` de producción también usa ese prefijo. Sigue pendiente decidir el modelo de conectividad entre contenedores y evitar solapamientos si se pretende enrutar entre ambas redes.

## 8. Observaciones de seguridad y operación

1. Docker-in-Docker requiere modo privilegiado. Su alcance debe limitarse al host de control y a los pipelines autorizados; no montar el socket Docker del host físico en Jenkins.
2. La CA institucional se monta como archivo de sólo lectura en Jenkins y Docker-in-Docker. Falta verificar que el almacén de confianza se actualice y que TLS hacia Gitea funcione.
3. Los secretos de Gitea y Jenkins se inyectan por variables de entorno. Los valores reales deben permanecer en el archivo local `.env`, fuera del repositorio y con permisos restrictivos.
4. El archivo `.env.example` sólo contiene marcadores `CHANGE_ME`; no usarlo como configuración operativa.
5. Los virtual hosts de infraestructura tienen una ACL de ejemplo pendiente de adaptar.
6. No se debe habilitar acceso público a Jenkins, Gitea ni Mailpit. El DNS interno y el firewall deben restringirlos a las redes autorizadas.
7. El proxy del servidor de control publica 80/443 en ese host; esto no demuestra por sí solo que los nombres de infraestructura estén publicados o accesibles desde Internet. Debe validarse DNS, NAT y firewall por separado.

## 9. Estado de validación

| Elemento | Estado |
|---|---|
| Compose de seis servicios en el repositorio | Implementado |
| Seis contenedores observados activos en el host | Observado |
| PostgreSQL y Mailpit healthy en la salida | Observado |
| Persistencia de Gitea y Jenkins | Montajes observados |
| Gitea Packages habilitado en Compose y runtime | Confirmado: `app.ini` y variable de entorno indican `true` |
| SSH de Gitea publicado en TCP/2222 | Declarado en Compose e inventariado |
| Jenkins con Docker CLI y JDK 21 | Declarado en Dockerfile |
| Docker-in-Docker con TLS y volumen persistente | Declarado; montajes observados |
| CA institucional montada en Jenkins y DinD | Montajes observados |
| Jobs temporales de Jenkins | Se eliminaron los seis jobs de prueba; verificación final: cero `WorkflowJob` restantes |
| Integración funcional Jenkins–Gitea | Pendiente |
| Login y push/pull del Container Registry | Pendiente |
| Pipeline y tag OJS probados en TEST | Pendiente |
| ACL de infraestructura adaptada a redes ENCiT | Pendiente |
| Certificado wildcard de Gitea | SAN cubre `git.infra.encit.unam.mx`; vigente y emitido por `ENCiT Internal Root CA` |
| Confianza TLS en host `pruebas` | Confirmada; `curl` sin `-k` valida Gitea y `/v2/` con resultado TLS 0. Otros clientes y contenedores pendientes |
| Versión Java runtime | Pendiente |

## 10. Siguientes pasos recomendados (sólo lectura inicialmente)

1. Definir una prueba controlada de autenticación y publicación/descarga de una imagen de prueba en Gitea Container Registry; no usar todavía imágenes productivas.
2. Diseñar el pipeline CI/CD real para OJS y decidir su ubicación (Jenkinsfile versionado en el repositorio); no reutilizar `prueba-gitea` como pipeline de despliegue.
3. Comparar plugins instalados con `plugins.txt` y decidir si el archivo versionado debe declarar explícitamente el plugin `gitea` y los demás requeridos.
4. Verificar versión Java y conectividad TLS Jenkins → Docker-in-Docker y Jenkins → Gitea, sin publicar secretos.
5. Revisar la ACL de los virtual hosts contra las redes autorizadas reales.
6. Inspeccionar los Jenkinsfiles y scripts de `repos/revista`; identificar el flujo build → test → publicación a Gitea Packages → promoción de la misma imagen a PROD.
7. Resolver el solapamiento de `172.18.0.0/16` antes de requerir routing entre redes Docker de control y producción.

**Conclusión:** la primera plataforma común de control ya está desplegada en el host de pruebas y el repositorio contiene su definición: Gitea/PostgreSQL, Jenkins, Docker-in-Docker, Nginx y Mailpit. Gitea Packages está habilitado en la configuración versionada, por lo que el Container Registry forma parte del diseño. Todavía no hay evidencia suficiente para afirmar que Jenkins consume Gitea, construye imágenes OJS o publica tags utilizables por producción. La siguiente fase debe validar esas integraciones y adaptar las ACL antes de usar la plataforma para el ciclo de promoción de Xitle.


## 11. Validación HTTP del Container Registry y resolución interna

**Fecha:** 26 de noviembre de 2026  
**Host de origen:** `pruebas` — `10.129.100.2/28`

### Configuración efectiva de Packages

Se leyó `/data/gitea/conf/app.ini` sin mostrar el resto de la configuración y se comprobó la variable de entorno específica:

- `packages.ENABLED=true` en `app.ini`.
- `GITEA__packages__ENABLED=true` en el entorno del contenedor.

Ambos valores coinciden. Gitea Packages está habilitado en la configuración efectiva.

### Pruebas del endpoint Registry

- Desde el host, `http://172.18.0.4:3000/api/healthz` respondió `HTTP 200 OK`.
- El proxy resolvió el alias Docker `gitea` a `172.18.0.4`.
- El proxy publica TCP/80 y TCP/443 en el host.
- El virtual host local `git.infra.encit.unam.mx` respondió `301` en HTTP y `HTTP/2 200` en HTTPS al forzar la conexión a `127.0.0.1`.
- El endpoint `https://git.infra.encit.unam.mx/v2/`, forzado al proxy local, respondió `HTTP 401`. Esta respuesta es esperada sin autenticación y confirma que el endpoint Registry responde.
- La misma URL por resolución habitual no conectó y agotó el tiempo de espera.

### Validación HTTPS local y Container Registry

Con la entrada local de `/etc/hosts` apuntando a `10.129.100.2`, se repitieron las pruebas directamente contra el servidor de pruebas:

- `https://git.infra.encit.unam.mx/` respondió `HTTP/2 200` a través de Nginx y Gitea.
- `https://git.infra.encit.unam.mx/v2/` respondió `HTTP/2 401` e incluyó `docker-distribution-api-version: registry/2.0` y un desafío Bearer para `container_registry`. El `401` es el comportamiento esperado sin autenticación y confirma que el endpoint del Container Registry está respondiendo.
- El certificado presentado tiene sujeto `CN=*.infra.encit.unam.mx`, SAN `DNS:*.infra.encit.unam.mx` y `DNS:infra.encit.unam.mx`, emisor `CN=ENCiT Internal Root CA`, vigencia del 21 de agosto de 2026 al 23 de noviembre de 2028 y huella SHA-256 `CE:BC:B3:6D:A4:56:C7:FE:CE:83:44:C5:0F:E3:17:9C:FE:DE:6D:81:5B:24:34:F6:74:D5:00:64:10:49:12:AB`.

El SAN comodín cubre el hostname `git.infra.encit.unam.mx` y el certificado de servidor no es autofirmado: fue emitido por la CA raíz interna de ENCiT. El error previo de `curl` sin `-k` indica que el cliente no confía en esa CA o no dispone de la cadena de confianza necesaria; no indica un error de coincidencia del hostname ni que el certificado de servidor haya expirado. Las pruebas anteriores usaron `-k` sólo para diagnóstico y no validan la confianza TLS del cliente.

**Pendiente:** instalar/confiar en la CA raíz interna en los clientes que deban acceder a Gitea y validar posteriormente con `curl` sin `-k`. Después realizar login y push/pull de una imagen de prueba. No se registran claves privadas ni secretos.

### Resolución interna y direccionamiento correcto

El diagnóstico inicial encontró en `/etc/hosts` del host `pruebas` una entrada explícita que asociaba `git.infra.encit.unam.mx` con `132.247.168.160`. Las consultas A directas a los DNS institucionales `132.248.10.2` y `132.248.204.1`, y como referencia a `1.1.1.1` y `8.8.8.8`, devolvieron `NXDOMAIN`; por tanto, no se encontró un registro DNS A para ese nombre en los resolvers consultados.

Se corrigió la entrada local de `/etc/hosts` en `pruebas` para que `git.infra.encit.unam.mx` apunte a **`10.129.100.2`**, dirección del propio servidor de pruebas donde se ejecutan Gitea y el proxy Nginx. La salida posterior de `getent ahostsv4 git.infra.encit.unam.mx` confirmó `10.129.100.2` para STREAM, DGRAM y RAW.

**Aclaración de direccionamiento:** `132.247.168.166` es la IP WAN de OPNsense utilizada para la publicación de los servicios de producción, cuyo servidor es `10.129.101.2`. No es la dirección de Gitea. El hostname interno `git.infra.encit.unam.mx` debe llegar al servidor de pruebas `10.129.100.2`; no debe enviarse a la IP WAN de producción.

La modificación de `/etc/hosts` sólo corrige la resolución local en `pruebas`; no crea un registro DNS ni cambia OPNsense. Para que otros equipos autorizados resuelvan el nombre se deberá definir un registro/override DNS interno hacia `10.129.100.2`. No publicar el hostname de infraestructura en DNS público.

### Estado actualizado

| Elemento | Estado |
|---|---|
| Gitea Packages en `app.ini` y entorno | Confirmado habilitado |
| Salud HTTP de Gitea desde el host | HTTP 200 |
| Proxy local y virtual host de Gitea | HTTP 301 / HTTPS 200 |
| Endpoint Registry local `/v2/` | HTTP 401 esperado sin autenticación; desafío Bearer `container_registry` confirmado por hostname |
| Resolución de `git.infra.encit.unam.mx` en `pruebas` | Corregida localmente: `/etc/hosts` apunta a `10.129.100.2`; `getent` verificado |
| IP WAN de OPNsense para publicación de producción | `132.247.168.166` (NAT hacia `10.129.101.2`; no corresponde a Gitea) |
| Registro/override DNS interno para otros equipos | Pendiente; destino previsto `10.129.100.2`; no se modificó OPNsense |
| Login, push y pull autenticados | Pendientes |


### Validación de confianza TLS desde el host de control

**Fecha:** 26 de noviembre de 2026  
**Host:** `pruebas` (`10.129.100.2/28`)

Se localizó la CA raíz institucional en:

`/usr/local/share/ca-certificates/encit-internal-root-ca.crt`

El certificado tiene como sujeto `C=MX, O=UNAM, OU=ENCiT, CN=ENCiT Internal Root CA`, coincidente con el emisor del certificado wildcard presentado por Gitea. Posteriormente se ejecutó `curl` sin `-k` y sin especificar una CA manualmente, con estos resultados:

| URL | HTTP | TLS verify result | Código de salida |
|---|---:|---:|---:|
| `https://git.infra.encit.unam.mx/` | 200 | 0 | 0 |
| `https://git.infra.encit.unam.mx/v2/` | 401 | 0 | 0 |

Esto confirma que el host `pruebas` confía en la CA institucional y valida correctamente el certificado TLS de Gitea. El HTTP 401 de `/v2/` es esperado sin autenticación y no representa un fallo TLS.

**Alcance:** esta validación corresponde únicamente al host `pruebas`. No demuestra que otros equipos, Jenkins o Docker-in-Docker tengan instalada y utilicen la misma CA. Tampoco valida aún login, push ni pull de imágenes. No se modificó el almacén de certificados durante esta comprobación.


### Cliente Docker disponible en el host de control

**Fecha:** 26 de noviembre de 2026  
**Host:** `pruebas`  
**Usuario de sesión:** `administrador` (UID/GID 1000)

La inspección reportó:

- Docker CLI disponible en `/usr/bin/docker`.
- Docker CLI versión `29.7.2`, build `a7dcaa6`.
- Docker Engine versión `29.7.2`.
- `sudo docker version` y `sudo docker info` respondieron correctamente.
- El usuario `administrador` pertenece al grupo `sudo`, pero no al grupo `docker`; por tanto, las operaciones de Docker se ejecutan con `sudo`.

Esta comprobación valida la disponibilidad del cliente y del daemon en el host de control. No se ejecutó `docker login`, no se guardaron credenciales y no se realizó push/pull de imágenes.

**Criterio para la siguiente prueba:** antes de autenticar, definir si se utilizará una cuenta técnica dedicada de Gitea con un token de alcance mínimo para Packages (lectura/escritura según la prueba), en lugar de reutilizar la cuenta administrativa. Las credenciales deben introducirse de forma interactiva y nunca documentarse en Git.


### Cuenta técnica de Gitea para Jenkins

**Fecha:** 26 de noviembre de 2026

El administrador confirmó que ya existe en Gitea el usuario local `jenkins`. La cuenta se utilizará como identidad técnica para la integración Jenkins–Gitea y las pruebas del Container Registry; no se utilizará la cuenta administrativa personal para automatizar publicaciones.

Además, el administrador confirmó que ya están registradas en Jenkins las siguientes credenciales de integración:

| ID de credencial | Ámbito / almacén reportado | Descripción |
|---|---|---|
| `gitea-jenkins-token` | System / Global | Token API Gitea - cuenta técnica Jenkins ENCiT |
| `gitea-jenkins-api` | System scope / System / Global | Token API Gitea - integración Jenkins |

Se documentan únicamente los identificadores, el ámbito y las descripciones visibles. Los valores secretos de ambas credenciales no se consultaron ni se incorporan al repositorio. La existencia de estas entradas confirma que las credenciales están registradas en Jenkins; por sí sola no demuestra que los tokens sigan vigentes, que sus scopes sean suficientes, que Jenkins pueda autenticarse contra Gitea ni que Docker Registry acepte login, push o pull.

**Validaciones pendientes:** comprobar de forma controlada qué credencial corresponde a la API de Gitea y cuál se utilizará para Container Registry; verificar los permisos mínimos/scopes y la vigencia sin revelar los valores; validar conectividad TLS desde el contenedor Jenkins; y realizar login y push/pull de una imagen de prueba. No imprimir secretos en consola ni logs, y no copiar tokens a archivos versionados.


### Diagnóstico de resolución DNS desde Jenkins y corrección declarada

**Fecha:** 26 de noviembre de 2026  
**Host:** `pruebas` — `10.129.100.2/28`  
**Servicio:** `encit-control-platform-jenkins-1`  
**Archivo Compose operativo inspeccionado:** `/srv/encit/platform/control/docker-compose.yml`

Se ejecutó un Pipeline temporal de diagnóstico en el nodo `built-in` de Jenkins. La prueba inicial de API Gitea no llegó a establecer conexión: `curl` devolvió `Could not resolve host: git.infra.encit.unam.mx`. Por tanto, en esa ejecución no se alcanzó la fase TLS ni se probó la autenticación.

El diagnóstico desde el mismo agente mostró:

- Hostname del contenedor: `fedb4139c9de`; nodo Jenkins: `built-in`; executor: `0`.
- Resolver del contenedor: `127.0.0.11` (DNS embebido de Docker).
- DNS upstream informados por Docker: `132.248.10.2` y `132.248.204.1`.
- Sin entrada para `git.infra.encit.unam.mx` en `/etc/hosts` del contenedor.
- El host `pruebas`, en cambio, resuelve el nombre a `10.129.100.2` mediante su resolución local.

La inspección de Docker confirmó que Jenkins pertenece a las redes `encit-control-platform_jenkins_internal` (`172.19.0.3`) y `encit_control_edge` (`172.18.0.5`). El servicio Compose `jenkins` ya monta la CA raíz ENCiT en modo de sólo lectura en `/usr/local/share/ca-certificates/encit-internal-root-ca.crt`; la existencia del montaje no demuestra por sí sola que Java/curl dentro del contenedor confíen en ella.

#### Cambio aplicado al archivo Compose operativo

Se añadió al servicio `jenkins` la siguiente declaración:

```yaml
extra_hosts:
  - "git.infra.encit.unam.mx:10.129.100.2"
```

La configuración efectiva de Compose se validó con `sudo docker compose config -q` sin errores. La representación JSON de Compose confirmó:

```
['git.infra.encit.unam.mx=10.129.100.2']
```

**Estado de aplicación:** el cambio fue guardado y la configuración Compose validada, pero en el momento de documentar aún no se había recreado ni reiniciado el contenedor Jenkins. Por ello, todavía no se ha comprobado que la nueva entrada esté presente en el contenedor en ejecución ni que el agente resuelva Gitea.

#### Alcance y siguientes verificaciones

1. Aplicar el cambio de forma controlada recreando únicamente el servicio Jenkins, previa revisión de impacto y autorización operativa.
2. Verificar desde el agente `built-in` que `getent ahostsv4 git.infra.encit.unam.mx` devuelve `10.129.100.2`.
3. Repetir la prueba HTTPS sin `-k` para comprobar confianza TLS desde el contenedor.
4. Sólo después de confirmar TLS, ejecutar la prueba autenticada a `/api/v1/user` con la credencial Jenkins, sin imprimir tokens, encabezados ni cuerpos sensibles.
5. Validar por separado el tipo y uso de la credencial Gitea Personal Access Token y la credencial Secret text.

No se modificaron DNS institucionales, OPNsense ni redes Docker. No se revelaron ni documentaron valores de credenciales. La prueba inicial de autenticación quedó **sin ejecutar efectivamente** debido al fallo DNS.


### Resolución y confianza TLS persistentes desde Jenkins

**Fecha:** 26 de noviembre de 2026  
**Host:** `pruebas` — `10.129.100.2/28`  
**Servicio:** `encit-control-platform-jenkins-1`  
**Contexto de construcción:** `/srv/encit/platform/control/jenkins`  
**Compose operativo:** `/srv/encit/platform/control/docker-compose.yml`

#### Resolución interna

Se aplicó la configuración `extra_hosts` del servicio Jenkins y se recreó únicamente ese servicio mediante `sudo docker compose up -d --no-deps --no-build jenkins`. La inspección del contenedor confirmó `git.infra.encit.unam.mx:10.129.100.2` y `getent ahostsv4` devolvió `10.129.100.2`. El contenedor quedó `Running=true`. No se modificaron DNS institucionales ni OPNsense.

#### Confianza TLS

La CA raíz `ENCiT Internal Root CA` se encontró en el host en `/usr/local/share/ca-certificates/encit-internal-root-ca.crt`. Se verificó su sujeto/emisor y se obtuvo la huella SHA-256:

`3dd2b8219386495e2f651b1d091e83007191a07f6a4618cc762f7d56e6feceb5`

La CA se copió al contexto local de construcción `/srv/encit/platform/control/jenkins/encit-internal-root-ca.crt`; las huellas del original y la copia coincidieron. Este archivo se mantiene local en el host de control y no debe agregarse al repositorio público.

El Dockerfile local de Jenkins se modificó para copiar el certificado a `/usr/local/share/ca-certificates/encit-internal-root-ca.crt` y ejecutar `update-ca-certificates` durante la construcción, bajo `USER root`. La imagen se reconstruyó correctamente:

- Imagen: `encit-control-platform-jenkins`
- ID: `sha256:6db69f3b28ea6b3d3e542137c9fc366c4e2cb386ef034621e8607620e20761fb`

Se recreó únicamente Jenkins con `sudo docker compose up -d --no-deps --no-build jenkins`, conservando el volumen persistente `/srv/encit/data/jenkins/home`. Después de la recreación, desde el contenedor nuevo se ejecutó `curl` a `https://git.infra.encit.unam.mx/` sin `-k` y sin credenciales. Resultado:

| Comprobación | Resultado |
|---|---|
| Estado del contenedor | `Running=true` |
| Resolución del hostname | `10.129.100.2` |
| HTTP | `200` |
| TLS verify result | `0` |

Una prueba temporal anterior dentro del contenedor confirmó que `update-ca-certificates` requiere privilegios root; ejecutada como root, agregó una CA. La solución definitiva quedó incorporada en el Dockerfile y en la imagen reconstruida, por lo que no depende de la modificación temporal del contenedor anterior.

#### Alcance y pendientes

La resolución interna y la confianza TLS desde el contenedor Jenkins están confirmadas después de recrearlo. Esto todavía no demuestra que la API autenticada de Gitea funcione ni que el Container Registry acepte login, push o pull. La siguiente validación debe ejecutarse desde un Pipeline, primero contra un endpoint público de salud/API sin credenciales y después con la credencial técnica mediante un mecanismo que no imprima el token. Docker-in-Docker y sus operaciones de build/push se validarán por separado.

No se imprimieron ni documentaron secretos. No se modificaron DNS institucionales, OPNsense, Gitea ni Docker-in-Docker.


### Integración Jenkins–Gitea y Container Registry validada

**Fecha:** 26 de noviembre de 2026  
**Host de control:** `pruebas` — `10.129.100.2/28`  
**Jenkins:** agente `built-in`  
**Daemon de builds:** Docker-in-Docker `docker:29-dind`

Se completaron pruebas controladas desde Pipelines temporales de Jenkins, sin imprimir ni registrar los valores de los tokens.

#### API de Gitea y conectividad desde Jenkins

- El Pipeline de salud resolvió `git.infra.encit.unam.mx` a `10.129.100.2`.
- La consulta HTTPS a `/api/healthz` devolvió `HTTP=200` y `TLS_VERIFY=0`.
- La consulta autenticada a la API devolvió `HTTP=200` e identificó el login técnico `jenkins`.
- La credencial Jenkins `gitea-jenkins-token` es de tipo Secret text. Se actualizó su valor para utilizar un token técnico con permisos de Packages; el secreto no se incorpora a esta documentación.

#### Corrección DNS de Docker-in-Docker

El cliente Docker de Jenkins utiliza el daemon remoto `tcp://docker-dind:2376`. Se comprobó que el contenedor Jenkins resolvía el hostname interno, pero el daemon DinD reenviaba consultas a DNS públicos `8.8.8.8` y `8.8.4.4`, que no conocen el dominio interno.

La consulta desde el contenedor DinD confirmó que OPNsense, en `10.129.100.1`, responde correctamente con `git.infra.encit.unam.mx -> 10.129.100.2`; los DNS institucionales consultados devolvieron NXDOMAIN para ese hostname y la dirección del servidor Gitea no ofrece servicio DNS.

Se modificó el Compose operativo local `/srv/encit/platform/control/docker-compose.yml`, agregando exclusivamente al servicio `docker-dind`:

```yaml
dns:
  - 10.129.100.1
```

La configuración se validó con `sudo docker compose config -q` y se recreó únicamente `docker-dind` mediante `sudo docker compose up -d --no-deps docker-dind`. Después de la recreación, `nslookup git.infra.encit.unam.mx 10.129.100.1` desde el contenedor DinD devolvió `10.129.100.2`. No se modificaron DNS institucionales ni OPNsense.

#### Permisos de Packages y prueba Registry

El primer token revisado, `jenkins-encit-integration`, tenía los scopes `read:misc`, `read:repository` y `read:user`, sin permisos de Packages. Por ello el primer `docker login` alcanzó `/v2/` pero recibió `unauthorized`.

Se generó un token técnico nuevo con `read:package` y `write:package`, además de los permisos que la integración requiera. Se actualizó la credencial Jenkins existente `gitea-jenkins-token` (Secret text, Global) sin revelar el valor. Después, `docker login` respondió `Login Succeeded`.

Finalmente se ejecutó desde Jenkins una prueba completa sobre la imagen temporal:

- Referencia: `git.infra.encit.unam.mx/jenkins/registry-smoke-test:smoke-1`.
- Construcción local con Docker: correcta.
- `docker push`: correcto.
- Digest publicado: `sha256:7355685748d5f6c0af030b9cc154385b223b3050e481f4a0a1b46ae145af13a8`.
- Eliminación de la copia local y `docker pull` posterior: correcto.
- Inspección local de la imagen descargada: correcta.
- Resultado final del Pipeline: `REGISTRY_PUSH_PULL=SUCCESS`.

La imagen de prueba quedó publicada en Gitea como paquete remoto. El Pipeline eliminó la copia local al finalizar, pero no eliminó el paquete remoto. Su limpieza remota queda pendiente de autorización/decisión.

#### Estado resultante

Quedan confirmadas la resolución DNS interna desde Jenkins y desde Docker-in-Docker, la confianza TLS desde Jenkins, la consulta API autenticada y las operaciones de autenticación, publicación y descarga del Container Registry. Esto valida el canal técnico Jenkins → Gitea Packages para imágenes de prueba; todavía no valida un pipeline de OJS, la promoción de imágenes entre TEST y PROD, ni el despliegue de Xitle.

La advertencia de Docker sobre almacenamiento no cifrado en el `config.json` temporal apareció durante `docker login`. El Pipeline usó un directorio temporal `DOCKER_CONFIG` y una limpieza `trap` al finalizar; no se mostró el token. También apareció el aviso deprecando el legacy builder; la construcción terminó correctamente. La adopción de BuildKit/buildx puede planearse por separado.


## 12. Inventario y eliminación de jobs temporales de Jenkins

**Fecha:** 26 de noviembre de 2026  
**Host:** plataforma de control en `pruebas`  
**Interfaz utilizada:** Manage Jenkins → Script Console

Se ejecutó primero un inventario de sólo lectura de todos los elementos `Job` de Jenkins. El resultado mostró exactamente seis jobs, todos de tipo `WorkflowJob`, habilitados:

| Job | Tipo | Estado antes de la limpieza |
|---|---|---|
| `gitea-api-auth-test` | `WorkflowJob` | Habilitado |
| `gitea-connectivity-test` | `WorkflowJob` | Habilitado |
| `gitea-healthcheck` | `WorkflowJob` | Habilitado |
| `gitea-registry-login-test` | `WorkflowJob` | Habilitado |
| `gitea-registry-smoke-test` | `WorkflowJob` | Habilitado |
| `prueba-gitea` | `WorkflowJob` | Habilitado |

El administrador autorizó eliminar todos los trabajos de prueba. Se ejecutó la eliminación explícita de los seis nombres anteriores y Jenkins confirmó individualmente cada operación con `ELIMINADO=`. La verificación final reportó:

- `TOTAL_WORKFLOW_JOBS_RESTANTES=0`.
- Los seis jobs inventariados fueron eliminados.
- No se reportaron errores en la salida compartida.

**Alcance:** esta limpieza afectó únicamente los seis jobs Pipeline de prueba enumerados. No se eliminaron credenciales de Jenkins, configuración global, contenedores, repositorios ni paquetes del Container Registry. En particular, la imagen temporal `jenkins/registry-smoke-test:smoke-1` publicada en Gitea es un paquete remoto independiente y no forma parte de esta eliminación; su eventual limpieza debe decidirse por separado.

**Estado operativo:** la fase de pruebas puntuales de integración Jenkins–Gitea concluyó y sus jobs temporales fueron retirados. El pipeline CI/CD versionado para OJS/Xitle todavía debe diseñarse e implementarse; esta limpieza no equivale a desplegar ni retirar un pipeline productivo.
