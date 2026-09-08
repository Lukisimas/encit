# Checklist de go-live

## Red

- [ ] DNS interno del equipo perimetral resuelve DEV/TEST/INFRA correctamente.
- [ ] DNS público de producción preparado por DGTIC.
- [ ] Routing y ACL del switch L3 validados.
- [ ] DEV/TEST/INFRA no son accesibles desde Internet.
- [ ] Jenkins/Gitea restringidos a las VLAN/usuarios autorizados.
- [ ] Si se migró DHCP, una estación piloto recibió IP/gateway/DNS correctos y existe rollback.
- [ ] Configuración del equipo perimetral y switch respaldada.

## Aplicación

- [ ] Backups verificados y restauración ensayada.
- [ ] Imagen exacta de TEST identificada por SHA/tag.
- [ ] Variables de producción preparadas fuera de Git.
- [ ] Certificado TLS de producción instalado.
- [ ] Smoke tests automatizados.
- [ ] Ventana de mantenimiento autorizada.
- [ ] Plan de rollback documentado.
- [ ] Logs y espacio en disco monitorizados.
- [ ] Prueba de correo.
- [ ] Prueba de autenticación y roles.
- [ ] Verificación de tareas programadas.
