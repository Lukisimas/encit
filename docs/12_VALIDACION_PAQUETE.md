# Validación realizada

Se ejecutan localmente:

- `bash -n` sobre todos los scripts `.sh`.
- Parseo JSON de todas las plantillas.
- Parseo YAML de todos los Compose.
- Regla que prohíbe `:latest` en la nueva arquitectura.
- Regla que prohíbe montar `/var/run/docker.sock` en la plataforma Jenkins.
- Regla que prohíbe reintroducir BIND/named.conf/install-bind en la infraestructura nueva.
- Validación propia del contenido de Cursos (`node scripts/validate-content.mjs`).
- Integridad ZIP y SHA-256 del paquete final.

El `docker compose config` y los builds de imágenes deben ejecutarse en el servidor de control,
porque el entorno de generación de este paquete puede no disponer de Docker Engine.

La sintaxis real del equipo perimetral y switch L3 no puede validarse hasta conocer fabricante,
modelo y firmware. Los archivos de `repos/infrastructure/network/` son políticas vendor-neutral.
