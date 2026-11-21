#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

echo "== Bash =="
while IFS= read -r -d '' f; do
  if ! bash -n "$f"; then FAIL=1; fi
done < <(find "$ROOT" -type f -name '*.sh' -print0)

echo "== JSON =="
python3 - "$ROOT" <<'PY'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
bad=[]
for p in root.rglob("*.json"):
    try: json.load(open(p,encoding="utf-8"))
    except Exception as e: bad.append((p,e))
if bad:
    for p,e in bad: print(p,e,file=sys.stderr)
    raise SystemExit(1)
print("JSON OK")
PY

echo "== YAML =="
python3 - "$ROOT" <<'PY'
import pathlib,sys
try:
    import yaml
except ImportError:
    print("ERROR: PyYAML es requisito para validar YAML.", file=sys.stderr)
    raise SystemExit(1)
root=pathlib.Path(sys.argv[1])
bad=[]
for p in list(root.rglob("*.yml"))+list(root.rglob("*.yaml")):
    try:
        with open(p,encoding="utf8") as f:
            for _ in yaml.safe_load_all(f): pass
    except Exception as e: bad.append((p,e))
if bad:
    for p,e in bad: print(p,e,file=sys.stderr)
    raise SystemExit(1)
print("YAML OK")
PY

echo "== Respaldos y cuenta de despliegue =="
BOOTSTRAP="$ROOT/repos/infrastructure/bootstrap/prepare-production-host.sh"
grep -Fq 'DEPLOY_USER="deploy"' "$BOOTSTRAP" || { echo "Falta validar deploy en bootstrap" >&2; FAIL=1; }
grep -Fq 'DOCKER_GROUP="docker"' "$BOOTSTRAP" || { echo "Falta validar grupo docker en bootstrap" >&2; FAIL=1; }
grep -Fq 'install -o "$DEPLOY_USER" -g "$DEPLOY_GROUP" -m 0700' "$BOOTSTRAP" || { echo "Los directorios de backup no se asignan a deploy:deploy 0700" >&2; FAIL=1; }
for f in "$ROOT"/repos/{revista,moodle,siia,web-deploy}/scripts/backup.sh; do
  grep -Eq '^umask 077$' "$f" || { echo "Falta umask 077: $f" >&2; FAIL=1; }
done

echo "== Restricciones =="
if grep -R --line-number -E 'image:[[:space:]]*[^#]*:latest([[:space:]]|$)' "$ROOT/repos" \
  --include='*.yml' --include='*.yaml' --exclude-dir='source-reference' ; then
  echo "ERROR: hay imágenes :latest" >&2
  FAIL=1
fi
if grep -R --line-number '/var/run/docker.sock' "$ROOT/repos/infrastructure/control"; then
  echo "ERROR: Jenkins/control no debe montar docker.sock del host" >&2
  FAIL=1
fi
if find "$ROOT/repos/infrastructure" -type f \( -name 'named.conf*' -o -name 'install-bind.sh' -o -name 'db.*.encit.unam.mx' \) | grep -q .; then
  echo "ERROR: se reintrodujeron archivos BIND; DNS pertenece al equipo perimetral" >&2
  FAIL=1
fi

echo "== Cursos =="
if command -v node >/dev/null 2>&1; then
  if [[ -d "$ROOT/repos/cursos/src/data/oferta" ]]; then
    (cd "$ROOT/repos/cursos" && node scripts/validate-content.mjs)
  else
    echo "No hay catálogo versionado en repos/cursos/src/data/oferta; se omite validate-content.mjs"
  fi
else
  echo "Node no instalado; se omite validate-content.mjs"
fi

[[ "$FAIL" -eq 0 ]] || exit "$FAIL"
echo "VALIDACIÓN DEL PAQUETE: OK"
