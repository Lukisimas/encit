# Versiones de referencia

Valores de referencia usados para construir los ejemplos. Deben actualizarse mediante el
pipeline y probarse en DEV/TEST antes de llegar a producción.

| Componente | Referencia |
|---|---|
| Debian | 13 |
| Jenkins LTS | 2.568.2 + JDK 21 |
| Gitea | 1.27.1 |
| PostgreSQL Gitea | 17 |
| OJS | 3.5.0-5 LTS |
| Astro | 7.2.x |
| Node build Astro | 24 LTS |
| Moodle | 5.2.2 |
| PHP Moodle | 8.4 |
| MariaDB Moodle | 11.8 |
| SIIA objetivo | Python 3.13 + Flask 3.1.x + Gunicorn |
| PostgreSQL SIIA objetivo | 17 |
| Portal MySQL | **8.2.0 inicialmente, igual al actual** |
| Portal Redis | **inventariar la versión actual antes de fijar** |
| Equipo perimetral / switch L3 | **fabricante, modelo y firmware por inventariar** |

No mezclar la reorganización de infraestructura con la actualización de MySQL/Redis del portal.
