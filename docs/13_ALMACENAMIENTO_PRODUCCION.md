# Almacenamiento del servidor de producción

## Hardware y RAID identificados

Inventario observado en el servidor de producción:

| Componente | Configuración | Capacidad / estado |
|---|---|---|
| Controladora SSD | HPE MR416i-p Gen11 | RAID1, Optimal |
| Discos SSD | 2 × SATA SSD de 480 GB | Logical Drive de 446.625 GiB |
| Sistema | `/dev/sda` | ext4 en `/`, EFI y swap |
| Controladora HDD | HPE MR408i-o Gen11 | RAID5, Optimal |
| Discos HDD | 4 × SATA HDD de 24 TB | Logical Drive de 65.482 TiB |
| Volumen de datos | `/dev/sdb1` | ext4, montado en `/data` |

El RAID1 de SSD tolera la falla de uno de sus dos discos. El RAID5 de cuatro discos tolera la falla de un disco; durante la degradación y reconstrucción existe mayor exposición a una segunda falla. La capacidad utilizable no equivale a la suma nominal de los discos.

## Distribución de cargas

### SSD RAID1

Se reserva para el sistema operativo y operaciones sensibles a latencia:

- Debian y Docker Engine (incluido `/var/lib/docker`).
- Bases de datos MariaDB de OJS y Moodle.
- Configuración de aplicaciones, archivos de despliegue y cachés.
- Configuración y estado operativo de Certbot/Let's Encrypt.
- Configuración del proxy inverso.

### HDD RAID5 montado en /data

Se reserva para datos voluminosos y copias locales:

- OJS: archivos privados y directorio público.
- Moodle: `moodledata`.
- Respaldos locales por aplicación.
- Archivos históricos y exportaciones.

## Rutas propuestas

```text
/srv/encit/
  platform/production/
    letsencrypt/              # estado y certificados Certbot (SSD)
  apps/<app>/prod/             # despliegues
  data/<app>/prod/             # MariaDB, configuración y caché

/data/encit/
  data/revista/prod/files/
  data/revista/prod/public/
  data/moodle/prod/moodledata/
  backups/<app>/prod/
  archives/
```

Las rutas de OJS y Moodle se declaran en sus respectivos `.env.example`. Los respaldos locales se escriben en `/data/encit/backups/<app>/prod`. El almacenamiento local no sustituye una copia externa/offsite.

## Montaje y protección

El volumen de datos se identifica por UUID `5d642b08-fac8-48fa-8f9b-5976c66af37c` y se monta en `/data` mediante `/etc/fstab`. El bootstrap de producción compara ese UUID antes de crear directorios; así evita escribir accidentalmente en el directorio `/data` del filesystem raíz cuando el RAID no esté montado.

No formatear, reparticionar ni modificar RAID como parte del bootstrap. La comprobación de UUID no reemplaza la supervisión de salud de las controladoras y discos.

## Permisos

Los directorios se crean inicialmente con permisos restrictivos. Antes de desplegar servicios deben definirse los UID/GID efectivos de cada imagen y asignarse propietarios/permisos mínimos necesarios. No aplicar `chmod 777` como solución.

## Respaldos y recuperación

RAID protege disponibilidad ante ciertas fallas físicas; no protege contra borrado, corrupción lógica, ransomware, errores administrativos ni pérdida del servidor. Mantener una copia externa, verificar checksums y probar restauraciones en TEST. Consultar [Respaldos](06_RESPALDOS.md).
