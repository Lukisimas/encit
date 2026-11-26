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
- [ ] Conectividad IP del servidor con el gateway y salida de red comprobadas.
- [ ] Firewall local del servidor permite los puertos requeridos.
- [ ] Proxy de producción instalado y escuchando en TCP/80 y TCP/443.
- [ ] TCP/80 y TCP/443 comprobados desde una red externa después de instalar el proxy (la prueba previa a la instalación quedó registrada como línea base no concluyente en `docs/15_VALIDACION_PUBLICA_XITLE.md`).
- [ ] Routing y ACL del switch L3 validados.
- [ ] DEV/TEST/INFRA no son accesibles desde Internet.
- [ ] Jenkins/Gitea restringidos a las VLAN/usuarios autorizados.
- [ ] Si se migró DHCP, una estación piloto recibió IP/gateway/DNS correctos y existe rollback.
- [ ] Configuración del equipo perimetral y switch respaldada.

## Aplicación Xitle (OJS)

- [ ] Directorios persistentes creados y permisos/UID/GID comprobados.
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
