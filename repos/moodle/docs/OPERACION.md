# Operación Moodle

- Cron cada minuto mediante contenedor dedicado.
- Antes de upgrades: backup DB + moodledata + config.
- Plugins/temas: probar compatibilidad y hornear en imagen.
- DEV/TEST: configurar SMTP apuntando a `mailpit:1025` desde la administración de Moodle.
- PROD: SMTP institucional.
- Usar `/public` como DocumentRoot.
- Cuando Moodle 5.3 LTS se publique y madure, evaluar migración primero en DEV/TEST.
