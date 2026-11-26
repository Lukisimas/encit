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
- [ ] Inspeccionar el job inicial `prueba-gitea` y validar checkout/ejecución desde Gitea.
- [ ] Confirmar versión Java en runtime y conectividad TLS Jenkins → Docker-in-Docker.
- [x] Cuenta local `jenkins` creada en Gitea y confirmada por el administrador como identidad técnica prevista.
- [x] Credencial Jenkins `gitea-jenkins-token` registrada en el almacén System / Global; descripción: `Token API Gitea - cuenta técnica Jenkins ENCiT`.
- [x] Credencial Jenkins `gitea-jenkins-api` registrada en el ámbito System scope / System / Global; descripción: `Token API Gitea - integración Jenkins`.
- [ ] Verificar vigencia y scopes de ambas credenciales sin revelar sus valores; confirmar cuál se utilizará para API de Gitea y cuál para Container Registry.
- [ ] Confirmar permisos de `jenkins` sobre el namespace/paquete de prueba.
- [x] Cliente Docker disponible en `pruebas`: CLI y Engine `29.7.2`; `sudo docker version` e `info` respondieron correctamente. Usuario `administrador` (UID 1000), sin pertenencia al grupo `docker`; se utilizará `sudo`.
- [ ] Ejecutar `docker login` de forma interactiva y validar publicación/descarga de una imagen de prueba en Gitea Container Registry.
- [ ] Conciliar plugins instalados con `control/jenkins/plugins.txt`.
- [ ] Adaptar las ACL de `git`, `jenkins` y `mail` a las redes autorizadas reales; actualmente conservan el ejemplo `10.10.10.0/24`.
- [x] Validar HTTPS local de Gitea: `HTTP/2 200`; certificado wildcard vigente, SAN compatible con `git.infra.encit.unam.mx`, emitido por `ENCiT Internal Root CA`.
- [x] Validar endpoint Registry `/v2/` por hostname: `HTTP/2 401` con desafío Bearer y cabecera `docker-distribution-api-version: registry/2.0` (respuesta esperada sin autenticación).
- [x] CA raíz ENCiT localizada en `/usr/local/share/ca-certificates/encit-internal-root-ca.crt` en el host `pruebas`; `curl` sin `-k` validó HTTPS de Gitea (HTTP 200) y Registry `/v2/` (HTTP 401 esperado), con `TLS verify result: 0` en ambos casos. Validación documentada en `docs/17_IMPLEMENTACION_PLATAFORMA_CONTROL.md`. Alcance limitado al host `pruebas`; falta validar otros clientes, Jenkins y Docker-in-Docker.
- [ ] Validar autenticación y publicación/descarga de imagen de prueba en Gitea Container Registry.

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
- [ ] Validar autenticación API de Gitea desde un Pipeline sin exponer tokens en consola/logs.

**Estado actualizado (26-nov-2026):** `extra_hosts` ya está aplicado y verificado en el contenedor Jenkins; el hostname resuelve a `10.129.100.2`. La CA raíz ENCiT se incorporó al Dockerfile local, la imagen se reconstruyó y Jenkins se recreó conservando su volumen. HTTPS desde el contenedor responde `HTTP=200` con `TLS_VERIFY=0`, sin `-k`. La prueba inicial de API no llegó a TLS ni autenticación por el fallo DNS que ya fue corregido. Siguen pendientes la prueba API autenticada, login y push/pull del Registry y validación independiente de Docker-in-Docker. No se modificaron DNS institucionales ni OPNsense.
