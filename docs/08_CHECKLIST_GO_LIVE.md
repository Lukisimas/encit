# Checklist de go-live

## Red y publicación

- [ ] DNS interno del equipo perimetral resuelve DEV/TEST/INFRA correctamente.
- [x] Registro DNS público A de `xitle.encit.unam.mx` creado y apuntando a `132.247.168.166` (confirmado por el administrador).
- [ ] Resolución A de Xitle comprobada desde resolvers públicos y evidencia registrada.
- [ ] Registro AAAA ausente o, si existe, IPv6 probado de extremo a extremo.
- [ ] NAT TCP/80 y TCP/443 de OPNsense dirigido a producción (`10.129.101.2`).
- [ ] Reglas de firewall WAN permiten HTTP/HTTPS conforme al NAT.
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
