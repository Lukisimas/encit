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

## Aplicación Xitle (OJS)

- [x] Docker Engine `29.7.2`, Docker Compose `v5.5.0` y daemon activo comprobados en producción.
- [x] Usuario `deploy` (`1001:1001`) y pertenencia al grupo `docker` (`989`) comprobados.
- [x] Identidad `www-data` (`33:33`) comprobada para OJS.
- [x] Volumen `/data` comprobado: `/dev/sdb1`, ext4, UUID `5d642b08-fac8-48fa-8f9b-5976c66af37c`, montado correctamente.
- [x] Estado inicial previo al bootstrap comprobado: red `encit_prod_edge` y directorios base aún no existen; el script los crea.
- [ ] Ejecutar manualmente `repos/infrastructure/bootstrap/prepare-production-host.sh` como root (el administrador realizará la ejecución).
- [ ] Verificar directorios, propietarios/permisos y red `encit_prod_edge` tras el bootstrap.
- [ ] Variables de producción preparadas fuera de Git.
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
