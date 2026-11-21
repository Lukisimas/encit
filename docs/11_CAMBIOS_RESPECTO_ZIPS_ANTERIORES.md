# Cambios respecto a los paquetes anteriores

Los paquetes `encit_ojs_3entornos.zip` y `encit_cursos_3entornos.zip` quedan conceptualmente
reemplazados por la arquitectura institucional.

Cambios acumulados:

1. Gitea/Jenkins/Registry se extraen del proyecto OJS y pasan a `infrastructure`.
2. DNS/DHCP se extraen por completo de los servidores físicos y pasan al equipo perimetral.
3. El switch de capa 3 asume VLAN/SVI/routing/ACL/DHCP-relay según el diseño autorizado.
4. Se eliminan BIND, `named.conf`, archivos de zona y scripts `install-bind.sh` del repositorio.
5. Se mantienen reverse proxies institucionales separados control/prod.
6. OJS se adapta a las redes compartidas institucionales.
7. Cursos contiene la aplicación Astro completa.
8. Se incorpora el portal principal sin mezclar Jenkins con su Compose.
9. Se incorpora SIIA con estrategia de inventario/migración.
10. Se incorpora Moodle.
11. Todos los despliegues usan la misma regla: imagen TESTED exacta -> PROD.
