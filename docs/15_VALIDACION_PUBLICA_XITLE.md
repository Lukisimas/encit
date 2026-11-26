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

## Revisión de Port Forward y reglas WAN en OPNsense

**Fecha:** 26 de noviembre de 2026  
**Interfaz revisada:** WAN  
**Destino interno de producción:** `10.129.101.2`

El administrador compartió las dos reglas de Port Forward para la publicación de Xitle:

| Parámetro | HTTP | HTTPS |
|---|---|---|
| Interfaz | WAN | WAN |
| Protocolo | TCP | TCP |
| Dirección de destino | WAN address | WAN address |
| Puerto de destino | 80 (http) | 443 (https) |
| IP de redirección | `10.129.101.2` | `10.129.101.2` |
| Puerto de redirección | 80 (http) | 443 (https) |
| Descripción | Publicación xitle.encit.unam.mx | Publicación xitle.encit.unam.mx |

También se observaron en **Firewall → Rules → WAN**, dentro de las reglas generadas automáticamente por Port Forward, las entradas TCP hacia `10.129.101.2:80` y `10.129.101.2:443`, ambas con la descripción `Publicación xitle.encit.unam.mx`.

El administrador confirmó individualmente que ambas reglas automáticas están configuradas con acción `Pass`, habilitadas, y con los destinos/puertos esperados:

| Regla WAN | Acción | Estado | Destino | Puerto |
|---|---|---|---|---|
| HTTP | Pass | Habilitada | `10.129.101.2` | 80 |
| HTTPS | Pass | Habilitada | `10.129.101.2` | 443 |

**Conclusión de configuración:** los dos Port Forward y sus reglas WAN asociadas están configurados con los destinos y puertos previstos. La presencia y configuración de estas reglas no prueba por sí sola la conectividad extremo a extremo; ésta se verificará cuando el servidor tenga listeners activos.

## Configuración de red del servidor de producción

**Fecha de recepción:** 26 de noviembre de 2026  
**Comandos ejecutados por el administrador:** `ip -br addr` y `ip route`.

### Direccionamiento de interfaces

| Interfaz | Estado | Direcciones observadas | Observación |
|---|---|---|---|
| `lo` | UNKNOWN | `127.0.0.1/8`, `::1/128` | Loopback |
| `ens15f0` | UP | `10.129.101.2/28`, `fe80::6e83:75ff:fe4b:945e/64` | Interfaz activa de producción |
| `ens4f0np0` | DOWN | Sin dirección reportada | No activa |
| `ens4f1np1` | DOWN | Sin dirección reportada | No activa |
| `ens15f1` | DOWN | Sin dirección reportada | No activa |
| `ens15f2` | DOWN | Sin dirección reportada | No activa |
| `ens15f3` | DOWN | Sin dirección reportada | No activa |
| `docker0` | DOWN | `172.17.0.1/16` | Bridge Docker reportado abajo |

### Tabla de enrutamiento

| Destino | Gateway/interfaz | Origen |
|---|---|---|
| Ruta predeterminada | `10.129.101.1` vía `ens15f0`, marcada `onlink` | — |
| Red conectada `10.129.101.0/28` | Directamente por `ens15f0` | `10.129.101.2` |
| Red Docker `172.17.0.0/16` | `docker0` (linkdown) | `172.17.0.1` |

**Evaluación:** la interfaz activa, la dirección IPv4 y la ruta predeterminada coinciden con el diseño de producción documentado: servidor `10.129.101.2/28`, gateway `10.129.101.1`. Las demás interfaces físicas aparecen abajo; no se consideran un fallo por sí mismas si `ens15f0` es la interfaz destinada al servicio. La presencia de `docker0` en estado DOWN no acredita que Docker esté instalado o funcionando.

**Pendiente:** comprobar conectividad IP con el gateway y salida de red antes de instalar servicios. Esta comprobación debe hacerse separadamente de las pruebas HTTP/HTTPS.

## Validaciones pendientes en el orden correcto

1. Comprobar conectividad IP del servidor de producción con el gateway `10.129.101.1` y la salida de red.
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
- [x] Port Forward TCP/80 y TCP/443 revisados: WAN address hacia `10.129.101.2`, conservando los puertos.
- [x] Regla WAN automática de HTTP confirmada (Pass, habilitada, destino `10.129.101.2:80`).
- [x] Regla WAN automática de HTTPS confirmada (Pass, habilitada, destino `10.129.101.2:443`).
- [x] Configuración IP de `ens15f0` y ruta predeterminada revisadas; coinciden con `10.129.101.2/28` vía `10.129.101.1`.
- [ ] Conectividad IP del servidor con el gateway y salida de red comprobadas.
- [ ] Firewall local del servidor revisado.
- [ ] Servicios de producción instalados y listeners HTTP/HTTPS activos.
- [ ] TCP/80 comprobado desde una red externa después de instalar el proxy.
- [ ] TCP/443 comprobado desde una red externa después de instalar el proxy.
- [ ] Certificado Let's Encrypt emitido e instalado.
- [ ] HTTPS validado desde Internet.

No se han realizado cambios en OPNsense ni en los servidores como parte de estas pruebas.