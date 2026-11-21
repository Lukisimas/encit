# Migración de DNS/DHCP al equipo perimetral y switch de capa 3

## Objetivo

Retirar completamente DNS/DHCP del servidor de control. Los servidores físicos quedan dedicados
a aplicaciones/CI-CD; los servicios de red pasan a infraestructura de red especializada.

## Fase 0 — inventario

- Confirmar marca/modelo/firmware del equipo perimetral y switch L3.
- Exportar configuración actual del gateway/red.
- Documentar VLAN, subredes, gateway, DHCP actual, DNS actual y rutas.
- Confirmar con DGTIC qué ámbitos DHCP se delegan y cuándo.

## Fase 1 — DNS sin cambiar DHCP

Si DHCP aún sigue bajo DGTIC:

1. Crear en el equipo perimetral las zonas privadas `dev`, `test` e `infra`.
2. Probar directamente contra el IP DNS del equipo con `check-internal-dns.sh`.
3. Pedir temporalmente a DGTIC reenvío condicional de esas tres zonas al IP DNS del equipo
   perimetral.
4. Validar desde estaciones ENCiT usando todavía `132.248.10.2/132.248.204.1`.

Esto permite retirar BIND de 10.10.10.20 desde el primer día.

## Fase 2 — delegación DHCP

Cuando DGTIC delegue los ámbitos:

1. Preparar scopes en el equipo perimetral SIN activarlos.
2. Configurar DHCP relay en las SVI del switch L3, si aplica.
3. Coordinar ventana de corte del DHCP anterior.
4. Desactivar/retirar el scope institucional correspondiente.
5. Activar DHCP ENCiT.
6. Renovar una estación piloto y comprobar IP, gateway, DNS y acceso.
7. Ampliar el cambio por VLAN.

## Fase 3 — operación estable

Con clientes usando directamente DNS ENCiT:

- retirar el reenvío condicional temporal de DGTIC si ya no es necesario;
- mantener `132.248.10.2` y `132.248.204.1` como upstream forwarders;
- conservar las zonas privadas únicamente en el equipo perimetral;
- respaldar la configuración del perimetral y del switch después de cada cambio.

## Rollback

Antes de cualquier corte DHCP:

- conservar configuración anterior exportada;
- mantener los parámetros del DHCP institucional documentados;
- disponer de una ventana para regresar el relay/scope al estado anterior;
- no modificar simultáneamente DHCP, VLAN y servicios productivos en una sola ventana.
