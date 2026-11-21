# Premisas

1. Existen únicamente dos servidores físicos de aplicaciones.
2. DEV y TEST comparten el servidor físico de control, pero no redes ni datos.
3. PROD vive en el servidor físico de producción.
4. Cada sistema conserva su Docker Compose independiente.
5. Gitea, Registry y Jenkins son institucionales y compartidos.
6. Las zonas DNS de DEV/TEST/INFRA no se publican en Internet.
7. DNS/DHCP se administran en el equipo perimetral; BIND/DHCP no corren en los servidores físicos.
8. El switch de capa 3 administra VLAN/SVI/routing/relay de acuerdo con el diseño autorizado.
9. Mientras DGTIC mantenga DHCP, puede utilizarse reenvío condicional temporal hacia el DNS del
   equipo perimetral.
10. La promoción de imágenes es inmutable: TEST y PROD usan el mismo digest/tag probado.
