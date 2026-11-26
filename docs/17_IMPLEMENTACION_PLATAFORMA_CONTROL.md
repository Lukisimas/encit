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

**Estado:** habilitado en el Compose del repositorio. La inspección del host no pudo leer los valores filtrados de `app.ini` porque el comando `awk` terminó con error de sintaxis. Por tanto, falta confirmar la configuración efectiva del contenedor y probar una operación de login/pull/push en una ventana autorizada. No se ha demostrado todavía una publicación real desde Jenkins.

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

La salida del host confirmó los montajes de datos y certificados de Docker-in-Docker y el montaje de la CA institucional en ambos contenedores. No se validó todavía una conexión TLS efectiva desde Jenkins al daemon ni la confianza de la CA contra Gitea.

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

El inventario del directorio de Jenkins reportó un único job:

- `prueba-gitea`

Esto documenta que existe una primera configuración de job en Jenkins. No se obtuvo su tipo, repositorio SCM, rama, Jenkinsfile, credenciales referenciadas, triggers ni resultado de ejecución. Tampoco se ha validado que el job haga checkout de Gitea o que ejecute un build con Docker-in-Docker.

No se deben inferir pipelines de OJS a partir de la existencia de este job. La integración Jenkins–Gitea y el pipeline de construcción/publicación de OJS permanecen pendientes de inspección.

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
| Gitea Packages habilitado en Compose | Implementado; runtime pendiente |
| SSH de Gitea publicado en TCP/2222 | Declarado en Compose e inventariado |
| Jenkins con Docker CLI y JDK 21 | Declarado en Dockerfile |
| Docker-in-Docker con TLS y volumen persistente | Declarado; montajes observados |
| CA institucional montada en Jenkins y DinD | Montajes observados |
| Job `prueba-gitea` | Nombre observado; configuración/ejecución pendiente |
| Integración funcional Jenkins–Gitea | Pendiente |
| Login y push/pull del Container Registry | Pendiente |
| Pipeline y tag OJS probados en TEST | Pendiente |
| ACL de infraestructura adaptada a redes ENCiT | Pendiente |
| Certificados wildcard y HTTPS funcional | Pendiente de validación de contenido y handshake |
| Versión Java runtime | Pendiente |

## 10. Siguientes pasos recomendados (sólo lectura inicialmente)

1. Corregir la extracción de parámetros no sensibles de `app.ini` y confirmar Gitea Packages en runtime sin mostrar secretos.
2. Inspeccionar selectivamente la configuración XML del job `prueba-gitea`: tipo, URL SCM sin credenciales, rama, Jenkinsfile/script y triggers.
3. Comparar plugins instalados con `plugins.txt` y decidir si el archivo versionado debe declarar explícitamente el plugin `gitea` y los demás requeridos.
4. Verificar versión Java y conectividad TLS Jenkins → Docker-in-Docker y Jenkins → Gitea, sin publicar secretos.
5. Revisar la ACL de los virtual hosts contra las redes autorizadas reales.
6. Inspeccionar los Jenkinsfiles y scripts de `repos/revista`; identificar el flujo build → test → publicación a Gitea Packages → promoción de la misma imagen a PROD.
7. Resolver el solapamiento de `172.18.0.0/16` antes de requerir routing entre redes Docker de control y producción.

**Conclusión:** la primera plataforma común de control ya está desplegada en el host de pruebas y el repositorio contiene su definición: Gitea/PostgreSQL, Jenkins, Docker-in-Docker, Nginx y Mailpit. Gitea Packages está habilitado en la configuración versionada, por lo que el Container Registry forma parte del diseño. Todavía no hay evidencia suficiente para afirmar que Jenkins consume Gitea, construye imágenes OJS o publica tags utilizables por producción. La siguiente fase debe validar esas integraciones y adaptar las ACL antes de usar la plataforma para el ciclo de promoción de Xitle.
