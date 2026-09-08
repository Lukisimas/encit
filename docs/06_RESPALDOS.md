# Respaldos

Principios:

- Base de datos + archivos persistentes + configuración.
- Backup antes de toda migración de esquema.
- Copia local y una copia externa/offsite.
- Verificación periódica de restauración en TEST.
- Cifrar respaldos que contengan datos personales o académicos.

Directorios sugeridos:

`/srv/encit/backups/<app>/<entorno>/YYYY-MM-DD/`

Retención de ejemplo:
- diarios: 14
- semanales: 8
- mensuales: 12

Ajustar a las políticas de conservación de la UNAM/ENCiT.
