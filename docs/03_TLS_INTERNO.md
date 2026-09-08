# TLS

## Producción

Usar los certificados institucionales entregados / autorizados por DGTIC para los nombres públicos.

## DEV / TEST / INFRA

Se incluye un script para crear una CA interna y certificados wildcard:

- `*.dev.encit.unam.mx`
- `*.test.encit.unam.mx`
- `*.infra.encit.unam.mx`

La clave privada de la CA raíz **no debe permanecer en el servidor**. Debe custodiarse offline.
El certificado raíz sí debe instalarse en los equipos que necesiten confiar en los entornos internos.

Como alternativa institucional, sustituir esta CA por la PKI aprobada por DGTIC si existe.
