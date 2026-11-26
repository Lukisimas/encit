# Validación pública de Xitle

**Fecha:** 26 de noviembre de 2026  
**Nombre:** `xitle.encit.unam.mx`  
**IPv4 WAN esperada:** `132.247.168.166`  
**Destino NAT de producción:** `10.129.101.2`

## Objetivo

Documentar la validación de la publicación DNS y establecer una línea base de conectividad externa antes de instalar servicios en el servidor de producción. Las pruebas TCP realizadas antes de que exista un listener no sirven, por sí solas, para validar o descartar la configuración de NAT y firewall.

## Resultados de DNS desde la estación externa del administrador

**Fecha de recepción:** 26 de noviembre de 2026  
**Herramienta:** PowerShell `Resolve-DnsName`  
**Resolvers consultados:** Cloudflare (`1.1.1.1`) y Google (`8.8.8.8`).

| Consulta | Resultado | Estado |
|---|---|---|
| A mediante `1.1.1.1` | `132.247.168.166`, TTL 7200 | Confirmado |
| A mediante `8.8.8.8` | `132.247.168.166`, TTL 7200 | Confirmado |
| AAAA mediante `1.1.1.1` | No se devolvió registro AAAA; la respuesta mostró el SOA de `unam.mx` en Authority | Sin registro AAAA publicado |

Las dos consultas A independientes coinciden con la IP WAN esperada de OPNsense. La respuesta de AAAA con el SOA en la sección Authority y sin respuesta AAAA indica que no hay un registro AAAA publicado para este nombre en el momento de la consulta.

**Conclusión DNS:** la publicación IPv4 de `xitle.encit.unam.mx` queda validada desde dos resolvers públicos. No se observa un registro IPv6 que requiera validación adicional.

## Línea base de conectividad TCP anterior a la instalación

**Fecha:** 26 de noviembre de 2026  
**Origen:** estación Windows del administrador, conectada por Wi-Fi a una red externa a las VLAN de ENCiT.  
**Herramienta:** PowerShell `Test-NetConnection`.

| Destino | Resultado TCP | Ping | Interpretación |
|---|---|---|---|
| `xitle.encit.unam.mx:80` (`132.247.168.166`) | `TcpTestSucceeded: False` | Timeout | No se estableció conexión TCP/80 |
| `xitle.encit.unam.mx:443` (`132.247.168.166`) | `TcpTestSucceeded: False` | Timeout | No se estableció conexión TCP/443 |

La estación reportó como dirección de origen `10.28.203.52` e interfaz `Wi-Fi`.

**Condición conocida del servidor:** en el momento de estas pruebas todavía no se había instalado ningún servicio en el servidor de producción `10.129.101.2`. Por tanto, no se esperaba que existiera un proceso escuchando en TCP/80 o TCP/443.

**Interpretación:** los resultados son coherentes con la ausencia de servicios/listeners en el servidor. No demuestran que NAT o las reglas de firewall estén fallando, pero tampoco confirman que estén correctamente configurados. El ping fallido tampoco es concluyente, porque ICMP puede estar filtrado independientemente de TCP.

Esta prueba queda registrada como línea base previa a la instalación; no debe tratarse como una prueba de aceptación de NAT, firewall, proxy HTTP ni TLS.

## Validaciones pendientes en el orden correcto

1. Revisar la configuración de port forward TCP/80 y TCP/443 en OPNsense hacia `10.129.101.2`, junto con sus reglas WAN asociadas. Esta revisión de configuración no requiere que el servidor tenga servicios instalados.
2. Preparar el servidor de producción e instalar/configurar el proxy inverso.
3. Confirmar que el proxy escucha en los puertos previstos y que el firewall local permite el tráfico correspondiente.
4. Repetir las pruebas desde una red externa:
   ```powershell
   Test-NetConnection xitle.encit.unam.mx -Port 80
   Test-NetConnection xitle.encit.unam.mx -Port 443
   ```
5. Comprobar respuesta HTTP y, después de emitir e instalar el certificado, validar el handshake TLS y HTTPS.
6. Emitir el certificado de Let's Encrypt únicamente cuando se haya confirmado que el desafío HTTP-01 puede llegar al servicio por TCP/80, o se haya definido y probado otro método de validación.

## Estado

- [x] DNS A reportado como creado por el administrador y apuntando a `132.247.168.166`.
- [x] DNS A confirmado mediante resolvers públicos independientes (Cloudflare y Google devuelven `132.247.168.166`).
- [x] Registro AAAA consultado; no se observa registro AAAA publicado.
- [x] Prueba TCP/80 y TCP/443 ejecutada desde una estación externa antes de instalar servicios; resultados registrados como línea base no concluyente para NAT/firewall.
- [ ] Configuración de NAT TCP/80 y TCP/443 revisada en OPNsense.
- [ ] Reglas de firewall WAN y firewall local revisadas.
- [ ] Servicios de producción instalados y listeners HTTP/HTTPS activos.
- [ ] TCP/80 comprobado desde una red externa después de instalar el proxy.
- [ ] TCP/443 comprobado desde una red externa después de instalar el proxy.
- [ ] Certificado Let's Encrypt emitido e instalado.
- [ ] HTTPS validado desde Internet.

No se han realizado cambios en OPNsense ni en los servidores como parte de estas pruebas.