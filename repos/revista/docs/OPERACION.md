# Operación OJS

## Identidad y permisos

La imagen de aplicación se construye desde `php:8.3-apache-bookworm`; Apache/PHP ejecuta como
`www-data` (UID/GID 33:33). El bootstrap de producción valida esa identidad y prepara los
directorios de escritura de OJS con propietario 33:33 y modo 0750.

Generar `config.inc.php` como root para que el archivo quede con propietario 33:33 y modo 0640:

```bash
sudo ./scripts/generate-config.sh
```

No aplicar `chmod 777` ni asignar permisos recursivos sin evaluar el impacto. El directorio de
MariaDB se deja preparado, pero su propietario no se fija desde el bootstrap: antes del primer
arranque, descargar la imagen aprobada y consultar el UID/GID real de `mysql`:

```bash
docker run --rm mariadb:11.8 id mysql
```

La imagen oficial inicializa el volumen y administra su propiedad durante el primer arranque.
Verificar los logs y el estado healthy de MariaDB antes de iniciar OJS.

## Operación

- Plugins y temas deben versionarse / incorporarse a la imagen, no editarse dentro del contenedor.
- Antes de upgrades: backup DB + files + public + config.
- Ensayar `tools/upgrade.php` en TEST con una copia sanitizada o controlada.
- DEV/TEST: `sandbox=On`, Mailpit.
- PROD: `sandbox=Off`, SMTP institucional.
- Revisar logs del `worker` y `scheduler`.
- `worker` y `scheduler` ejecutan como UID/GID 33:33 (`www-data`) y sólo se conectan a
  `ojs_internal`; el servicio `web` es el único que se conecta a `encit_prod_edge`.
