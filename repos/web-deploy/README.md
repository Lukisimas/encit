# Portal principal ENCiT

Adaptación del `docker-compose.yaml` actual.

Cambios principales:
- Jenkins servidor/agente se eliminan de este stack.
- MySQL y Redis dejan de publicar puertos al host.
- Nginx del portal se convierte en gateway interno y sólo se conecta al `edge` institucional.
- MySQL permanece inicialmente en 8.2.0 para no mezclar migración arquitectónica con upgrade.
- La versión de Redis se deja como variable obligatoria hasta ejecutar el inventario.
- `encit-micro-sites` se mantiene temporalmente bajo perfil `legacy-microsites`.
- Frontend/backend se consumen como imágenes del Registry; sus builds se ejecutan en Jenkins.
- Se recomienda que el frontend use `/api` relativo para que la imagen sea idéntica en DEV/TEST/PROD.

Antes de desplegar, ejecutar `scripts/inventory-current.sh` en el host/stack actual.
