# Respaldos

## Principios

- Respaldar base de datos, archivos persistentes y configuración.
- Generar un respaldo antes de toda migración de esquema o actualización mayor.
- Mantener una copia local y otra externa/offsite. La copia local en el mismo servidor no constituye recuperación ante desastre.
- Verificar periódicamente la integridad mediante SHA-256 y probar restauraciones en TEST.
- Cifrar respaldos que contengan datos personales o académicos.
- Definir retención, acceso y eliminación conforme a las políticas de la UNAM/ENCiT.

## Ubicación y permisos

En producción, los respaldos locales se almacenan en el RAID5 montado en `/data`:

```text
/data/encit/backups/<app>/prod/
```

El bootstrap crea estos directorios con propietario `deploy:deploy` y modo `0700`.
Los pipelines Jenkins se conectan al servidor como `deploy`, por lo que esa cuenta puede
escribir los artefactos sin permisos globales ni cambios de propietario. Los scripts de
respaldo aplican `umask 077`; OJS y Moodle endurecen además el directorio a `0700`.

En el servidor de control, DEV y TEST conservan sus respaldos en:

```text
/srv/encit/backups/<app>/<entorno>/
```

Cada ejecución crea archivos con marca de tiempo. No mezclar respaldos de ambientes distintos.
No usar `chmod 777` ni ejecutar los respaldos como root para eludir permisos incorrectos.

## Contenido mínimo

- Dump consistente de la base de datos.
- Archivos persistentes (por ejemplo, OJS files/public y Moodle moodledata).
- Archivos de configuración necesarios para restaurar el servicio.
- Manifiesto SHA-256 de los artefactos generados.

Las contraseñas, claves de aplicación y otros secretos deben protegerse; no deben almacenarse en el repositorio Git. El respaldo de configuración debe tener controles de acceso y cifrado cuando corresponda.

## Retención de referencia

- diarios: 14
- semanales: 8
- mensuales: 12

La retención definitiva y la copia externa deben ajustarse a las políticas institucionales y a la capacidad del destino.

## Recuperación

Una restauración de prueba debe comprobar base de datos, archivos, configuración, permisos y funcionamiento de la aplicación. Documentar fecha, versión restaurada, resultado y tiempo de recuperación. El RAID5 protege frente a la falla de un disco, pero no sustituye los respaldos ni una copia fuera del servidor.
