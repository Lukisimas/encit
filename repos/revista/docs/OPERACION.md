# Operación OJS

- Plugins y temas deben versionarse / incorporarse a la imagen, no editarse dentro del contenedor.
- Antes de upgrades: backup DB + files + public + config.
- Ensayar `tools/upgrade.php` en TEST con una copia sanitizada o controlada.
- DEV/TEST: `sandbox=On`, Mailpit.
- PROD: `sandbox=Off`, SMTP institucional.
- Revisar logs del `worker` y `scheduler`.
