# Revista Xitle (OJS)

Stack independiente para OJS 3.5.0-5 LTS. El identificador interno `revista` se conserva en
nombres de repositorio, servicios y rutas de almacenamiento; los hostnames públicos e internos
del servicio utilizan el nombre Xitle.

- DEV: `xitle.dev.encit.unam.mx`
- TEST: `xitle.test.encit.unam.mx`
- PROD: `xitle.encit.unam.mx`

La imagen incluye el código OJS; los datos se separan en:

- MariaDB
- `config.inc.php`
- `files_dir` privado
- `public/`
- `cache/`

DEV/TEST usan `sandbox=On` y Mailpit compartido. Producción usa SMTP institucional.

## Persistencia de producción

- MariaDB: `/srv/encit/data/revista/prod/mariadb` (SSD RAID1).
- Configuración: `/srv/encit/data/revista/prod/config` (SSD RAID1).
- Caché: `/srv/encit/data/revista/prod/cache` (SSD RAID1).
- Archivos privados: `/data/encit/data/revista/prod/files` (HDD RAID5).
- Archivos públicos: `/data/encit/data/revista/prod/public` (HDD RAID5).
- Respaldos: `/data/encit/backups/revista/prod` (HDD RAID5).

El bootstrap prepara los directorios y asigna los directorios de escritura de OJS a
`www-data` (33:33), identidad utilizada por la imagen basada en `php:8.3-apache-bookworm`.
El UID/GID del usuario `mysql` debe verificarse en la imagen `mariadb:11.8` antes del primer
arranque; no asignar manualmente un UID supuesto.
