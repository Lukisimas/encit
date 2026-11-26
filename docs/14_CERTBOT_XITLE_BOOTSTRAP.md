# Bootstrap de Let's Encrypt para Xitle

## Estado previo confirmado

Al 26 de noviembre de 2026, se confirma por información del administrador de ENCiT que el registro DNS público `xitle.encit.unam.mx` ya fue creado y apunta a la IP WAN de OPNsense (`132.247.168.166`).

Esta confirmación documenta el estado reportado; no sustituye las pruebas técnicas desde un resolver externo ni la comprobación de conectividad TCP/80 desde Internet. Antes de solicitar el certificado, comprobar también que no exista un registro AAAA publicado que dirija a una ruta IPv6 no funcional.

## Condiciones previas para emitir

- Registro público A `xitle.encit.unam.mx -> 132.247.168.166` creado (confirmado por el administrador).
- Resolución A comprobada desde un resolver público.
- Si existe AAAA, conectividad IPv6 funcional; de lo contrario, retirar/corregir el registro AAAA.
- NAT TCP/80 en OPNsense dirigido al servidor de producción `10.129.101.2`.
- Regla de firewall WAN que permita TCP/80 hacia el destino NAT.
- TCP/80 disponible en el host de producción para Certbot standalone.
- Docker y el stack de producción configurados.
- Directorio `/srv/encit/platform/production/letsencrypt` existente y accesible por root.
- Correo administrativo válido para avisos de Let's Encrypt.

La publicación DNS y el NAT son funciones distintas: que el nombre resuelva a la WAN no demuestra por sí solo que el puerto 80 llegue al servidor.

## Comprobaciones DNS previas

Desde un equipo externo o desde una estación con acceso a Internet:

```bash
dig +short A xitle.encit.unam.mx @1.1.1.1
dig +short A xitle.encit.unam.mx @8.8.8.8
dig +short AAAA xitle.encit.unam.mx @1.1.1.1
```

El resultado A esperado es `132.247.168.166`. Si la consulta AAAA devuelve una dirección, validar que IPv6 esté publicado y encaminado correctamente antes de continuar.

La prueba definitiva de HTTP-01 requiere que Let's Encrypt pueda alcanzar el puerto TCP/80 público y que OPNsense lo traduzca hasta el host de producción.

## Emisión inicial

Certbot se ejecuta en contenedor y en modo **standalone**. Por ello, requiere detener temporalmente el proxy que ocupa el puerto 80. No se ejecuta automáticamente durante el bootstrap del servidor.

Desde producción, en el directorio del stack:

```bash
cd /srv/encit/platform/production
sudo mkdir -p letsencrypt
sudo chmod 700 letsencrypt
sudo docker compose stop proxy
sudo docker run --rm -it \
  -p 80:80 \
  -v /srv/encit/platform/production/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  --preferred-challenges http \
  --email <CORREO_ADMINISTRADOR> \
  --agree-tos --no-eff-email \
  -d xitle.encit.unam.mx
```

**No continuar automáticamente si Certbot devuelve error.** Primero comprobar el código de salida y que existan ambos archivos:

```bash
sudo test -s /srv/encit/platform/production/letsencrypt/live/xitle.encit.unam.mx/fullchain.pem
sudo test -s /srv/encit/platform/production/letsencrypt/live/xitle.encit.unam.mx/privkey.pem
```

Sólo después de que ambos archivos existan, iniciar el proxy y validar su configuración:

```bash
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

Si la emisión falla, revisar resolución DNS, NAT, reglas de firewall y disponibilidad pública de TCP/80. No levantar el vhost HTTPS de Xitle mientras no existan el certificado y la llave privada, porque Nginx no podrá cargar esa configuración.

## Renovación

Certbot conserva el método standalone en su configuración de renovación. Para renovar, el puerto 80 debe volver a estar libre. Ejecutar en una ventana de mantenimiento:

```bash
cd /srv/encit/platform/production
sudo docker compose stop proxy
sudo docker run --rm \
  -p 80:80 \
  -v /srv/encit/platform/production/letsencrypt:/etc/letsencrypt \
  certbot/certbot renew
```

Si Certbot termina correctamente, iniciar y validar el proxy:

```bash
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

Si la renovación falla, restaurar el proxy y revisar el error; no dejarlo detenido. La interrupción del proxy afecta los sitios publicados.

**No instalar aún un timer automático.** Primero validar una emisión real y una renovación de prueba. Después, automatizar el ciclo con un script de host que garantice la restauración del proxy incluso ante errores (`trap`), genere logs, evite ejecuciones concurrentes y valide/reload Nginx.

## Estado del diseño y pendientes

- DNS público A creado y apuntando a la WAN de OPNsense, confirmado por el administrador.
- Pendiente registrar evidencia de consultas A desde resolvers externos.
- Pendiente confirmar que no exista un AAAA no funcional.
- Pendiente probar llegada de TCP/80 desde Internet hasta producción.
- Compose monta el estado de Certbot en el proxy como solo lectura.
- El vhost referencia el certificado en `/etc/letsencrypt/live/xitle.encit.unam.mx/`.
- Emisión y renovación siguen siendo procedimientos manuales con interrupción breve.
- No se ha ejecutado Certbot ni se ha instalado el certificado.
