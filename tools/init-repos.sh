#!/usr/bin/env bash
set -euo pipefail
echo "Repositorios sugeridos en Gitea:"
cat <<'EOF'
encit/infrastructure
encit/encit-front-end
encit/encit-back-end
encit/encit-deploy
encit/siia
encit/revista
encit/cursos
encit/moodle
EOF
echo
echo "Este script no crea repositorios automáticamente para no almacenar tokens de Gitea."
