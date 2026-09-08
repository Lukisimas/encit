# Migración SIIA

No saltar directamente de Python 3.6/Flask 1.x a producción moderna.

1. Ejecutar inventario en VM.
2. Crear snapshot/backup.
3. Importar Git sin secretos ni datos.
4. Registrar `pip freeze` como evidencia, no como requirements definitivo.
5. Crear pruebas de caracterización de rutas y procesos críticos.
6. Containerizar una versión funcional en DEV.
7. Actualizar dependencias incompatibles por etapas.
8. Probar Python 3.13 + Flask 3.1.
9. Inventariar PostgreSQL y probar dump/restore hacia PostgreSQL 17 en TEST.
10. Sanitizar datos de prueba cuando contengan información personal.
11. Ensayar el cutover completo.
12. PROD y rollback.
