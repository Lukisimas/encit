# Jenkins institucional

Un único Jenkins atiende todos los repositorios.

## Convención de ramas

- `feature/*`: build y pruebas, sin despliegue persistente.
- `develop`: despliegue DEV.
- `release/*`: build candidato + TEST; si pasa, crear tag `tested-<sha>`.
- `main`: despliegue de la imagen ya probada, sin reconstrucción.

## Hosts y credenciales

| Credencial Jenkins | Destino | Uso |
|---|---|---|
| `control-deploy-ssh` | `deploy@10.129.100.2` | DEV y TEST |
| `production-deploy-ssh` | `deploy@10.129.101.2` | Producción |
| `gitea-registry` | Registry institucional | Publicación/descarga de imágenes |

Las claves privadas se almacenan únicamente en Jenkins Credentials. La clave pública
correspondiente debe estar autorizada en `~deploy/.ssh/authorized_keys` del host destino.

## Cuenta operativa deploy

La cuenta `deploy` debe aprovisionarse de forma explícita en ambos servidores antes de
configurar los jobs:

1. Crear el usuario local `deploy` con shell de inicio de sesión y directorio home.
2. Instalar su clave pública SSH en `~deploy/.ssh/authorized_keys`, con propietario
   `deploy:deploy`, directorio `0700` y archivo `0600`.
3. En el host de producción, agregar `deploy` al grupo `docker` y comprobar la nueva
   sesión SSH. En el host de control, aplicar el mismo criterio si los pipelines ejecutan
   Docker Compose remotamente.
4. Confirmar que `deploy` puede ejecutar `docker info` y `docker compose version`
   sin sudo.

**Advertencia:** pertenecer al grupo `docker` concede privilegios equivalentes a root.
Debe limitarse a la cuenta técnica de despliegue y protegerse su clave SSH como credencial
privilegiada. No conceder acceso interactivo a personas ni reutilizar esa clave.

El bootstrap de producción no crea la cuenta ni instala claves. Falla de forma segura si
`deploy`, su grupo primario o el grupo `docker` no existen, o si no tiene membresía
efectiva en `docker`. También prepara `/data/encit/backups/<app>/prod` como
`deploy:deploy`, modo `0700`.

## Seguridad y operación

- `gitea-registry`: usuario/token para Registry.
- Credenciales específicas de secretos sólo cuando el pipeline realmente las requiera.
- No montar `/var/run/docker.sock` del host en Jenkins. El paquete usa Docker-in-Docker separado.
- Los despliegues de producción deben respaldar antes de actualizar y utilizar exclusivamente
  la imagen marcada como probada en TEST.
- No guardar archivos `.env`, claves privadas ni tokens en Git.

## Validaciones automatizadas

El workflow `Validate infrastructure package` se ejecuta en cada Pull Request y push a
`main` o `docs/**`. Ejecuta la validación del paquete, comprueba sintaxis Bash y valida
la configuración de Compose para los entornos declarados mediante sus archivos
`.env.example`. Un resultado verde confirma validaciones estáticas; no acredita conectividad
SSH, membresía real de `deploy`, acceso a Docker en los hosts ni disponibilidad de servicios.
