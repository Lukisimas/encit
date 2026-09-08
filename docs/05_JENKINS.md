# Jenkins institucional

Un único Jenkins atiende todos los repositorios.

Convención de ramas:

- `feature/*`: build y pruebas, sin despliegue persistente.
- `develop`: despliegue DEV.
- `release/*`: build candidato + TEST; si pasa, crear tag `tested-<sha>`.
- `main`: despliegue de la imagen ya probada, sin reconstrucción.

Credenciales mínimas:

- `gitea-registry`: usuario/token para Registry.
- `control-deploy-ssh`: SSH al host 10.10.10.20.
- `production-deploy-ssh`: SSH al host 10.10.10.30.
- credenciales específicas de secrets sólo cuando el pipeline realmente las requiera.

No montar `/var/run/docker.sock` del host en Jenkins. El paquete usa Docker-in-Docker separado.
