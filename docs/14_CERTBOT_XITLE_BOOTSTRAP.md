# Bootstrap de Let's Encrypt para Xitle

## Condiciones previas

Antes de solicitar el certificado:

- El registro público `xitle.encit.unam.mx` debe resolver a la IP WAN de OPNsense.
- NAT TCP/80 debe llegar al servidor de producción.
- TCP/80 debe estar libre para Certbot en modo standalone.
- Docker y el stack de producción deben estar configurados.
- El directorio `/srv/encit/platform/production/letsencrypt` debe existir y ser accesible por root.

Este procedimiento usa Certbot en contenedor y el modo **standalone**, por lo que requiere detener temporalmente el proxy que ocupa el puerto 80. No se ejecuta automáticamente durante el bootstrap del servidor.

## Emisión inicial

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
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

Si Certbot falla, revisar DNS público, NAT, firewall y que TCP/80 sea accesible desde Internet. No continuar con el proxy HTTPS hasta que existan `fullchain.pem` y `privkey.pem`.

## Renovación

Certbot conserva el método standalone en su configuración de renovación. Para renovar, el puerto 80 debe volver a estar libre. Ejecutar una ventana de mantenimiento:

```bash
cd /srv/encit/platform/production
sudo docker compose stop proxy
sudo docker run --rm \
  -p 80:80 \
  -v /srv/encit/platform/production/letsencrypt:/etc/letsencrypt \
  certbot/certbot renew
sudo docker compose up -d proxy
sudo docker compose exec proxy nginx -t
```

La interrupción del proxy afecta los sitios publicados. **No instalar aún un timer automático**: primero validar una emisión real, una renovación de prueba y el comportamiento de arranque. Después, automatizar el ciclo con un script de host que pare el proxy, ejecute `certbot renew`, lo vuelva a levantar incluso ante errores (`trap`) y valide/reload Nginx. El script debe generar log, evitar ejecuciones concurrentes y no dejar el proxy detenido si Certbot falla.

## Estado del diseño

- Compose monta el estado de Certbot en el proxy como solo lectura.
- El certificado de Xitle se referencia en el vhost desde `/etc/letsencrypt/live/xitle.encit.unam.mx/`.
- Emisión y renovación aún son procedimientos manuales con interrupción breve.
- No se ha ejecutado Certbot ni validado el DNS/NAT real desde Internet.
