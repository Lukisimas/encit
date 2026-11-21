# Moodle — Educación Continua

Referencia inicial: Moodle 5.2.2.

- DEV: `ec.dev.encit.unam.mx`
- TEST: `ec.test.encit.unam.mx`
- PROD: `ec.encit.unam.mx`

La imagen se construye una vez y se promueve. Plugins/temas institucionales deben incorporarse al
repositorio/imagen, no instalarse manualmente en producción.

Persistencia:
- MariaDB
- `moodledata`
- `config.php`

Moodle 5.2 usa `/public` como DocumentRoot.
