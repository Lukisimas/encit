# Revista OJS

Stack independiente para OJS 3.5.0-5 LTS.

- DEV: `revista.dev.encit.unam.mx`
- TEST: `revista.test.encit.unam.mx`
- PROD: `revista.encit.unam.mx`

La imagen incluye el código OJS; los datos se separan en:
- MariaDB
- `config.inc.php`
- `files_dir` privado
- `public/`
- `cache/`

DEV/TEST usan `sandbox=On` y Mailpit compartido. Producción usa SMTP institucional.
