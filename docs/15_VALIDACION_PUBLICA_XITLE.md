# Validación pública de Xitle

**Fecha:** 26 de noviembre de 2026  
**Nombre:** `xitle.encit.unam.mx`  
**IPv4 WAN esperada:** `132.247.168.166`  
**Destino NAT de producción:** `10.129.101.2`

## Objetivo

Comprobar, antes de solicitar el certificado de Let's Encrypt, que el nombre público resuelve a la IP WAN de OPNsense y que los puertos TCP/80 y TCP/443 son alcanzables desde Internet.

## Intento de comprobación desde el entorno de trabajo

Se intentaron las siguientes pruebas desde el entorno de ejecución disponible para esta revisión:

| Prueba | Resultado observado | Interpretación |
|---|---|---|
| Resolución A mediante el resolver del entorno (`getent ahostsv4`) | No devolvió direcciones; código 2 | No concluyente: el resolver de este entorno no resolvió el nombre |
| Resolución AAAA mediante el resolver del entorno (`getent ahostsv6`) | No devolvió direcciones; código 2 | No concluyente: no permite afirmar que el registro AAAA esté ausente |
| HTTP al nombre (`curl`) | Error 6: no se pudo resolver el host | No se llegó a probar TCP/80 |
| HTTPS al nombre (`curl`) | Error 6: no se pudo resolver el host | No se llegó a probar TCP/443 |
| HTTP a `132.247.168.166` usando `curl --resolve` | Error 7: no se pudo establecer conexión TCP/80 | No concluyente: el entorno de ejecución puede restringir conexiones salientes |
| HTTPS a `132.247.168.166` usando `curl --resolve` | Error 7: no se pudo establecer conexión TCP/443 | No concluyente: el entorno de ejecución puede restringir conexiones salientes |

También falló la consulta DNS-over-HTTPS a Cloudflare porque este entorno no pudo resolver el propio nombre del servicio DNS.

**Conclusión:** estas pruebas no demuestran que el DNS público, NAT o firewall de ENCiT estén fallando. El entorno desde el que se ejecutaron no pudo realizar consultas DNS ni conexiones salientes suficientes para validar el servicio. Tampoco constituyen evidencia de que TCP/80 o TCP/443 estén abiertos o cerrados desde Internet.

## Pruebas pendientes desde una estación externa

Ejecutar desde una conexión ajena a las VLAN de ENCiT (por ejemplo, una estación conectada a una red externa):

```bash
dig +short A xitle.encit.unam.mx @1.1.1.1
dig +short A xitle.encit.unam.mx @8.8.8.8
dig +short AAAA xitle.encit.unam.mx @1.1.1.1
curl -4 -I --connect-timeout 8 http://xitle.encit.unam.mx/
curl -4 -I --connect-timeout 8 https://xitle.encit.unam.mx/
```

Resultados esperados:

- Ambas consultas A deben devolver `132.247.168.166`.
- La consulta AAAA debe estar vacía, o devolver una dirección IPv6 que esté configurada y sea alcanzable de extremo a extremo.
- HTTP debe alcanzar el proxy de producción por TCP/80 (puede responder con redirección a HTTPS o con una respuesta HTTP temporal prevista por la configuración).
- HTTPS debe completar el handshake TLS con un certificado válido una vez que éste haya sido emitido e instalado. Antes de emitirlo, es posible que HTTPS no responda correctamente.

Si las pruebas DNS son correctas pero HTTP no conecta, revisar en OPNsense el port forward TCP/80 hacia `10.129.101.2`, la regla asociada de firewall WAN y el listener del host. No cambiar reglas sin identificar primero cuál es el punto de fallo.

## Estado

- [x] DNS A reportado como creado por el administrador y apuntando a `132.247.168.166`.
- [ ] DNS A confirmado mediante resolvers públicos independientes.
- [ ] Registro AAAA comprobado.
- [ ] TCP/80 comprobado desde una red externa.
- [ ] TCP/443 comprobado desde una red externa.
- [ ] Certificado Let's Encrypt emitido e instalado.
- [ ] HTTPS validado desde Internet.

No ejecutar Certbot hasta confirmar públicamente la resolución A y la llegada de HTTP-01 por TCP/80. No se han realizado cambios en OPNsense ni en los servidores como parte de estas pruebas.
