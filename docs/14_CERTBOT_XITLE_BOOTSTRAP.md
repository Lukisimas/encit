# Bootstrap de Let's Encrypt para Xitle

## Estado previo confirmado

Al 26 de noviembre de 2026, se confirma por información del administrador de ENCiT que el registro DNS público `xitle.encit.unam.mx` ya fue creado y apunta a la IP WAN de OPNsense (`132.247.168.166`).

Esta confirmación documenta el estado reportado; no sustituye las pruebas técnicas desde un resolver externo ni la comprobación de conectividad TCP/80 desde Internet. Antes de solicitar el certificado, comprobar también que no exista un registro AAAA publicado que dirija a una ruta IPv6 no funcional.

## Condiciones previas para emitir

- Registro público A `xitle.encit.unam.mx -> 132.247.168.166` creado (confirmado por el administrador).
- Resolución A comprobada desde dos resolvers públicos (Cloudflare `1.1.1.1` y Google `8.8.8.8`), ambos devuelven `132.247.168.166`.
- Consulta AAAA realizada desde Cloudflare; no se observó registro AAAA publicado.
- NAT TCP/80 en OPNsense dirigido al servidor de producción `10.129.101.2`.
- Regla de firewall WAN que permita TCP/80 hacia el destino NAT.
- TCP/80 disponible en el host de producción para Certbot standalone.
- Docker y el stack de producción configurados.
- Directorio `/srv/encit/platform/production/letsencrypt` existente y accesible por root.
- Correo administrativo válido para avisos de Let's Encrypt.

La publicación DNS y el NAT son funciones distintas: que el nombre resuelva a la WAN no demuestra por sí solo que el puerto 80 llegue al servidor.

## Evidencia de validación

El intento de comprobación desde el entorno de trabajo del 26 de noviembre de 2026 no fue concluyente: el resolver de ese entorno no pudo resolver el nombre y tampoco se pudieron establecer conexiones salientes directas a la IP WAN. Esto no demuestra una falla en DNS, OPNsense o producción. Registrar las pruebas repetidas desde una estación externa en `docs/15_VALIDACION_PUBLICA_XITLE.md` antes de ejecutar Certbot.

## Comprobaciones DNS previas

Desde un equipo externo o desde una estación con acceso a Internet:

```bash
dig +short A xitle.encit.unam.mx @1.1.1.1
dig +short A xitle.encit.unam.mx @8.8.8.8
dig +short AAAA xitle.encit.unam.mx @1.1.1.1
```

El resultado A esperado es `132.247.168.166`. Si la consulta AAAA devuelve una dirección, validar que IPv6 esté publicado y encaminado correctamente antes de continuar.

La prueba definitiva de HTTP-01 requiere que Let's Encrypt pueda alcanzar el puerto TCP/80 público y que OPNsense lo traduzca hasta el host de producción.

## Emisión inicial

Certbot se ejecuta en contenedor y en modo **standalone**. Por ello, requiere detener temporalmente el proxy que ocupa el puerto 80. No se ejecuta automáticamente durante el bootstrap del servidor.

Desde producción, en el directorio del stack:

```bash
cd /srv/encit/platform/production
sudo mkdir -p letsencrypt
sudo chmod 700 letsencrypt
sudo docker compose stop proxy
sudo docker run --rm -it \
  -p 80:80 \
  -v /srv/encit/platform/production/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  --preferred-challenges http \
  --email <CORREO_ADMINISTRADOR> \
  --agree-tos --no-eff-email \
  -d xitle.encit.unam.mx
```

**No continuar automáticamente si Certbot devuelve error.** Primero comprobar el código de salida y que existan ambos archivos:

```bash
sudo test -s /srv/encit/platform/production/letsencrypt/live/xitle.encit.unam.mx/fullchain.pem
sudo test -s /srv/encit/platform/production/letsencrypt/live/xitle.encit.unam.mx/privkey.pem
```

Sólo después de que ambos archivos existan, iniciar el proxy y validar su configuración:

```bash
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

Si la emisión falla, revisar resolución DNS, NAT, reglas de firewall y disponibilidad pública de TCP/80. No levantar el vhost HTTPS de Xitle mientras no existan el certificado y la llave privada, porque Nginx no podrá cargar esa configuración.

## Renovación

Certbot conserva el método standalone en su configuración de renovación. Para renovar, el puerto 80 debe volver a estar libre. Ejecutar en una ventana de mantenimiento:

```bash
cd /srv/encit/platform/production
sudo docker compose stop proxy
sudo docker run --rm \
  -p 80:80 \
  -v /srv/encit/platform/production/letsencrypt:/etc/letsencrypt \
  certbot/certbot renew
```

Si Certbot termina correctamente, iniciar y validar el proxy:

```bash
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

Si la renovación falla, restaurar el proxy y revisar el error; no dejarlo detenido. La interrupción del proxy afecta los sitios publicados.

**No instalar aún un timer automático.** Primero validar una emisión real y una renovación de prueba. Después, automatizar el ciclo con un script de host que garantice la restauración del proxy incluso ante errores (`trap`), genere logs, evite ejecuciones concurrentes y valide/reload Nginx.

## Estado del diseño y pendientes

- DNS público A creado y apuntando a la WAN de OPNsense, confirmado por el administrador.
- Resolución A confirmada desde Cloudflare y Google; ambos devuelven `132.247.168.166`.
- Consulta AAAA a Cloudflare sin registro AAAA en la respuesta.
- Pendiente probar llegada de TCP/80 desde Internet hasta producción.
- Compose monta el estado de Certbot en el proxy como solo lectura.
- El vhost referencia el certificado en `/etc/letsencrypt/live/xitle.encit.unam.mx/`.
- Emisión y renovación siguen siendo procedimientos manuales con interrupción breve.
- No se ha ejecutado Certbot ni se ha instalado el certificado.


## Auditoría del repositorio antes del primer despliegue

**Fecha:** 26 de noviembre de 2026  
**Rama revisada:** `docs/storage-xitle-hostnames`.

Se inspeccionaron `repos/infrastructure/production/docker-compose.yml`, la configuración Nginx de producción, los virtual hosts, `repos/infrastructure/bootstrap/prepare-production-host.sh` y el stack OJS `repos/revista/deploy/production/`.

### Configuración encontrada

- El Compose de infraestructura define el servicio `proxy` con Nginx `1.30.4`, publica TCP/80 y TCP/443 y monta la configuración de Nginx, los certificados institucionales y el estado de Certbot.
- El estado de Certbot se monta en el proxy desde `/srv/encit/platform/production/letsencrypt` como solo lectura.
- El virtual host `xitle.encit.unam.mx` redirige HTTP a HTTPS y referencia `fullchain.pem` y `privkey.pem` de Certbot.
- El upstream de Xitle es `revista-prod-web:80`.
- El stack OJS declara el alias `revista-prod-web` para su servicio `web` en la red externa `encit_prod_edge`; MariaDB, worker y scheduler permanecen en la red interna OJS.
- El `.env.example` de producción establece `PUBLIC_BASE_URL=https://xitle.encit.unam.mx` y rutas persistentes en SSD (`/srv/encit/data/revista/prod`) y RAID de datos (`/data/encit/data/revista/prod`). Contiene valores de ejemplo que deben sustituirse fuera de Git; no es un archivo de secretos utilizable directamente.
- El bootstrap `prepare-production-host.sh` valida el montaje `/data` contra el UUID esperado, comprueba Docker, la identidad operativa `deploy`, la pertenencia de `deploy` al grupo `docker`, la identidad `www-data` 33:33, crea directorios y la red Docker `encit_prod_edge`. Requiere ejecutarse como root y falla si sus precondiciones no se cumplen.

### Dependencias y pendientes identificados

- El host debe tener Docker Engine y Compose plugin funcionales; la salida `ss` no demuestra por sí sola su instalación ni el estado del daemon.
- Antes de ejecutar el bootstrap deben verificarse las precondiciones de usuario/grupo `deploy`, grupo `docker` e identidad `www-data` 33:33. No se debe crear ni modificar automáticamente el acceso SSH de `deploy` sin decisión administrativa.
- La red externa `encit_prod_edge` debe existir antes de levantar el proxy y OJS; el bootstrap la crea si no existe.
- El stack OJS debe desplegarse con un `.env` real, seguro y fuera de Git, imagen aprobada en TEST y credenciales/llaves generadas. El `.env.example` no debe copiarse sin sustituir los marcadores.
- El proxy referencia el certificado de Xitle. Por ello, no debe levantarse con el vhost HTTPS activo antes de que Certbot haya emitido ambos archivos requeridos. La guía contempla detener el proxy, emitir por HTTP-01 standalone y volver a levantarlo sólo tras validar los archivos.
- La guía de Certbot sigue pendiente de ejecución real. No se ha ejecutado Certbot, no se ha iniciado el proxy ni OJS y no se ha probado la llegada pública de TCP/80 con un listener activo.

**Estado de la auditoría:** los archivos necesarios para proxy, virtual host y stack OJS están presentes en Git y sus referencias de red/alias coinciden. Esto acredita preparación del repositorio, no instalación ni funcionamiento en producción. No se realizaron cambios en el servidor, OPNsense ni servicios.


### Validación de precondiciones del host de producción

**Fecha:** 26 de noviembre de 2026.

El administrador ejecutó las comprobaciones de versiones/estado de Docker, cuentas y grupos requeridos por `prepare-production-host.sh`. Resultado:

- Docker Engine `29.7.2` instalado.
- Docker Compose `v5.5.0` disponible.
- Servicio `docker` en estado `active`.
- Usuario `deploy`: UID/GID `1001:1001`, shell `/bin/bash`.
- Grupo `deploy`: GID `1001`.
- Grupo `docker`: GID `989`; `deploy` pertenece a dicho grupo.
- Usuario/grupo `www-data`: UID/GID `33:33`, coincide con la identidad esperada por la imagen OJS.

**Conclusión:** se satisfacen las precondiciones de Docker y de identidad de `deploy`/`www-data` verificadas en esta etapa. Esta validación no ejecuta el bootstrap ni comprueba todavía las demás precondiciones que el script consulta (montaje y UUID de `/data`, existencia de rutas, red Docker, entre otras). No se realizaron cambios en el servidor.


### Validación de montaje y estado inicial de rutas/red

**Fecha:** 26 de noviembre de 2026.

El administrador confirmó en el host de producción:

- `/data` es punto de montaje activo, origen `/dev/sdb1`, filesystem `ext4`, UUID `5d642b08-fac8-48fa-8f9b-5976c66af37c`, coincidente con `EXPECTED_DATA_UUID` del bootstrap.
- La red Docker externa `encit_prod_edge` todavía no existe. El script `prepare-production-host.sh` contempla crearla si falta.
- Los directorios `/srv/encit`, `/srv/encit/platform` y `/data/encit` todavía no existen, consistente con el estado previo al bootstrap; el script contempla crearlos.

**Conclusión:** montaje y estado inicial de rutas/red son compatibles con la ejecución prevista del bootstrap. La red y los directorios no se crearon manualmente. No se ha ejecutado todavía el script ni se han iniciado servicios.


### Corrección del bootstrap: creación de directorios de respaldos

**Fecha:** 26 de noviembre de 2026.

Durante la ejecución manual del bootstrap en producción, el administrador reportó:

`install: missing destination file operand after '/data/encit/backups/web/prod'`.

La inspección del bloque correspondiente identificó que el comando usaba `install` sin la opción `-d`. En ese modo, `install` espera un archivo de origen y un destino; para crear un directorio con propietario, grupo y modo debe utilizarse `install -d`.

Se corrigió `repos/infrastructure/bootstrap/prepare-production-host.sh` en la rama `docs/storage-xitle-hostnames`:

```bash
install -d -o "$DEPLOY_USER" -g "$DEPLOY_GROUP" -m 0700 \\
  "$DATA_ROOT/backups/$app/prod"
```

La corrección quedó registrada en el commit `33c541a67652664dbfffc1b396d342104832d3e4`.

**Estado de producción:** la ejecución anterior se interrumpió al encontrar el error. No asumir que el bootstrap terminó ni que todos los directorios/red quedaron creados. Antes de reintentar, actualizar la copia del repositorio en producción a este commit y revisar el estado parcial de las rutas. El administrador ejecutará manualmente el script actualizado. No se ejecutó ningún comando remoto ni se modificó el servidor desde esta actualización documental.


### Inspección del estado parcial tras la primera ejecución

**Fecha:** 26 de noviembre de 2026.

Después de actualizar el script corregido en producción, el administrador inspeccionó las rutas sin modificarlas. Se observó:

- En SSD, existen los directorios base `/srv/encit/{platform/production,apps,data,config}`, los subdirectorios `apps/{web,siia,revista,cursos,moodle}/prod`, los directorios `data/{web,siia,revista,cursos,moodle}/prod` y `platform/production/letsencrypt`.
- El directorio de Certbot aparece como `root:root`, modo `0700`, conforme al diseño.
- En RAID, existen `/data/encit/{data,backups,archives}` y `/data/encit/data/web/prod`.
- No se observaron aún directorios `/data/encit/backups/<app>/prod` ni los directorios de datos RAID de las otras aplicaciones.
- La red Docker `encit_prod_edge` continúa sin existir.

**Interpretación:** el primer intento se interrumpió durante la primera iteración del bucle de respaldos (aplicación `web`), al ejecutar `install` sin `-d`. Los directorios listados antes de ese punto quedaron creados; las operaciones posteriores del script no se completaron. La inspección no detectó ni modificó servicios o contenedores.

Los directorios ya existentes no deben eliminarse. El bootstrap corregido utiliza `install -d` para crear directorios y establecer sus modos/propietarios; puede volver a recorrer las rutas previstas. La red externa se creará al final si aún no existe.

**Pendiente:** repetir manualmente el bootstrap ya actualizado y revisar su salida completa. Después, verificar estructura, propietarios/permisos y red. No se ha desplegado OJS ni el proxy y no se ha ejecutado Certbot.
