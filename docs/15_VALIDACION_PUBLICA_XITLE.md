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

### Prueba de conectividad con el gateway de producción

**Fecha de recepción:** 26 de noviembre de 2026  
**Equipo:** servidor de producción  
**Comando ejecutado:** `ping -c 4 10.129.101.1`

Resultado reportado por el administrador:

```text
PING 10.129.101.1 (10.129.101.1) 56(84) bytes of data.
64 bytes from 10.129.101.1: icmp_seq=1 ttl=64 time=0.199 ms
64 bytes from 10.129.101.1: icmp_seq=2 ttl=64 time=0.235 ms
64 bytes from 10.129.101.1: icmp_seq=3 ttl=64 time=0.264 ms
64 bytes from 10.129.101.1: icmp_seq=4 ttl=64 time=0.235 ms

--- 10.129.101.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3067ms
rtt min/avg/max/mdev = 0.199/0.233/0.264/0.023 ms
```

| Métrica | Resultado |
|---|---:|
| Paquetes transmitidos | 4 |
| Paquetes recibidos | 4 |
| Pérdida | 0 % |
| RTT mínimo | 0.199 ms |
| RTT promedio | 0.233 ms |
| RTT máximo | 0.264 ms |
| TTL observado | 64 |

**Conclusión:** el servidor de producción puede comunicarse por IP con el gateway `10.129.101.1` de la VLAN 51. La conectividad local servidor-gateway queda comprobada.

### Prueba de salida IP a Internet

**Fecha de recepción:** 26 de noviembre de 2026  
**Equipo:** servidor de producción  
**Comando ejecutado:** `ping -c 4 1.1.1.1`; el administrador interrumpió la prueba después de recibir dos respuestas (`Ctrl+C`).

Resultado reportado:

```text
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=54 time=4.09 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=54 time=4.10 ms
^C
--- 1.1.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 4.088/4.095/4.103/0.007 ms
```

| Métrica | Resultado |
|---|---:|
| Paquetes transmitidos | 2 |
| Paquetes recibidos | 2 |
| Pérdida | 0 % |
| RTT mínimo | 4.088 ms |
| RTT promedio | 4.095 ms |
| RTT máximo | 4.103 ms |
| TTL observado | 54 |

**Conclusión:** el servidor de producción tiene conectividad IP hacia una dirección pública de Internet (`1.1.1.1`). La prueba fue interrumpida manualmente tras dos respuestas, ambas satisfactorias. Esto valida salida IP/ICMP; no comprueba por sí sola resolución DNS desde el servidor, acceso HTTP/HTTPS, ni publicación entrante de los puertos 80/443.

**Estado de conectividad de red:** interfaz y ruta predeterminada revisadas; gateway de VLAN 51 alcanzable; salida IP a Internet comprobada. Se puede continuar con las comprobaciones de firewall local y preparación del servicio web, manteniendo las pruebas de publicación entrante para cuando exista un listener.

## Validaciones pendientes en el orden correcto

1. Revisar el firewall local del servidor y preparar el servidor de producción.
2. Instalar/configurar el proxy inverso cuando se autorice.
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
- [x] Conectividad IP del servidor de producción con el gateway `10.129.101.1` comprobada mediante `ping -c 4` (4/4 respuestas, 0 % de pérdida, RTT promedio 0.233 ms).
- [x] Salida IP a Internet desde el servidor de producción comprobada mediante `ping` a `1.1.1.1` (2/2 respuestas, 0 % de pérdida, RTT promedio 4.095 ms; prueba interrumpida manualmente tras dos respuestas).
- [ ] Firewall local del servidor revisado.
- [ ] Servicios de producción instalados y listeners HTTP/HTTPS activos.
- [ ] TCP/80 comprobado desde una red externa después de instalar el proxy.
- [ ] TCP/443 comprobado desde una red externa después de instalar el proxy.
- [ ] Certificado Let's Encrypt emitido e instalado.
- [ ] HTTPS validado desde Internet.

No se han realizado cambios en OPNsense ni en los servidores como parte de estas pruebas.

## Inspección inicial del firewall local (`nftables`)

**Fecha de recepción:** 26 de noviembre de 2026  
**Equipo:** servidor de producción  
**Comando ejecutado:** `sudo nft list ruleset`.

### Hallazgos observados

- Se muestran las tablas `ip nat` e `ip filter`, ambas advertidas por el propio sistema como administradas por `iptables-nft`; no deben modificarse directamente con `nft`.
- En IPv4, la cadena `FORWARD` tiene política `drop` y salta a las cadenas `DOCKER-USER` y `DOCKER-FORWARD`. Esta política corresponde al tráfico reenviado, no determina por sí misma si se aceptan conexiones dirigidas al host.
- La salida compartida no muestra una cadena `INPUT` ni reglas explícitas de filtrado de entrada para el host en la tabla `ip filter`.
- Las cadenas Docker mostradas están vacías, salvo las reglas de forwarding/aislamiento y masquerade para la red `172.17.0.0/16`. Los contadores visibles están en cero.
- También aparecen tablas IPv6 `ip6 nat` e `ip6 filter`, con cadenas Docker sin reglas de entrada del host visibles.
- La existencia de las cadenas Docker no demuestra que haya contenedores o servicios publicados; anteriormente se observó `docker0` en estado DOWN y el administrador indicó que aún no se habían instalado servicios en producción.

### Interpretación y límites

En el ruleset compartido no se observa una política `INPUT` que bloquee conexiones entrantes al propio servidor. La política `drop` de `FORWARD` no debe confundirse con un bloqueo de los puertos locales 80/443. No obstante, esta inspección no descarta que UFW, firewalld u otro mecanismo de administración del firewall esté activo, ni valida todavía la recepción de conexiones públicas.

**No se modificó ninguna regla ni configuración del servidor.** Las advertencias de `iptables-nft` se registran como indicación de propiedad de esas tablas; no se deben editar directamente con `nft`.

**Siguiente comprobación:** consultar el estado de UFW antes de concluir la revisión del firewall local.


### Comprobación de UFW

**Fecha de recepción:** 26 de noviembre de 2026  
**Comando ejecutado:** `sudo ufw status verbose`.

El servidor respondió:

```text
sudo: ufw: command not found
```

**Conclusión:** el ejecutable de UFW no está disponible en el servidor (UFW no está instalado o no está en el PATH). Por tanto, no hay un estado ni reglas de UFW que consultar mediante este comando. Esto no descarta que otro gestor, como firewalld, esté instalado o activo.

No se instaló UFW ni se modificaron reglas del firewall.
