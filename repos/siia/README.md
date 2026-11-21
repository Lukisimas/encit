# SIIA — incorporación a Git, CI/CD y Docker

Estado conocido:
- Ubuntu 18 (VM)
- Python 3.6
- Flask 1.x
- PostgreSQL (versión aún por inventariar)

Objetivo:
- Python 3.13
- Flask 3.1.x
- Gunicorn
- PostgreSQL 17
- Docker
- DEV / TEST / PROD con una sola imagen promovida

## Muy importante

No se proporcionó el código fuente del SIIA ni su `pip freeze`. Por ello este directorio contiene:
- Dockerfile objetivo.
- aplicación mínima de validación (`scaffold/`) **sólo para probar la infraestructura**.
- Compose de los tres entornos.
- scripts de inventario/exportación/backup.
- Jenkinsfile.
- plan de migración.

Antes de sustituir el scaffold debe importarse el código real y generarse un `requirements.txt`
controlado a partir del inventario de la VM.

La VM actual debe conservarse intacta como rollback hasta terminar la validación productiva.
