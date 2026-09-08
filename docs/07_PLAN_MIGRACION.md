# Plan de migración

## 0. Red institucional

1. Inventariar marca/modelo/firmware del equipo perimetral y switch L3.
2. Documentar VLAN, subredes, gateway, DNS/DHCP actuales y rutas.
3. Configurar zonas privadas DEV/TEST/INFRA en el equipo perimetral.
4. Probar resolución directa desde una estación piloto.
5. Mientras DGTIC conserve DHCP, usar reenvío condicional temporal hacia el DNS perimetral.
6. Diseñar VLAN/SVI/ACL y DHCP relay en el switch L3 sin modificar producción todavía.
7. Cuando DGTIC delegue ámbitos, migrar DHCP por VLAN con ventana y rollback.
8. Exportar/respaldar configuraciones del equipo perimetral y switch después de cada cambio.

## 1. Plataforma común

1. Preparar `10.10.10.20` con Docker y la red `encit_control_edge`.
2. Levantar Gitea, Registry, Jenkins, Mailpit y reverse proxy interno.
3. Configurar CA interna/certificados para DEV/TEST/INFRA.
4. Validar que sólo las VLAN autorizadas lleguen a Jenkins/Gitea/DEV/TEST.

## 2. Portal

1. Inventariar versiones reales y variables actuales.
2. Retirar Jenkins del Compose del portal.
3. Replicar comportamiento actual en DEV.
4. Desplegar TEST.
5. Promover a PROD.
6. Sólo después evaluar MySQL 8.4 LTS y actualización de Redis/Spring/React.

## 3. SIIA

1. Mantener VM Ubuntu 18 operativa como rollback.
2. Ejecutar inventario (`python`, `pip freeze`, PostgreSQL, extensiones, tamaño).
3. Importar código a Gitea.
4. Agregar pruebas de caracterización.
5. Containerizar primero de forma funcional.
6. Modernizar dependencias de manera incremental.
7. Migrar una copia sanitizada a TEST.
8. Ensayar dump/restore y corte.
9. Go-live.
10. Conservar VM apagada, no destruida, durante el periodo de rollback.

## 4. OJS / Cursos / Moodle

Usar los stacks incluidos con el mismo patrón DEV → TEST → PROD.

## Regla transversal

No combinar en una misma ventana cambios de red críticos (DHCP/VLAN/gateway) y cambios mayores de
aplicación/base de datos. Cada capa debe tener su propia validación y rollback.
