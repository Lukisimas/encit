#!/usr/bin/env bash
set -euo pipefail
umask 077

# Generar como root para que el archivo quede legible por www-data (33:33).
[[ "${EUID}" -eq 0 ]] || { echo "Ejecuta este script como root (sudo)." >&2; exit 1; }
readonly OJS_UID=33
readonly OJS_GID=33
# Genera config.inc.php desde el config.TEMPLATE.inc.php que trae EXACTAMENTE la imagen OJS.
# Uso: desde el directorio del entorno con .env:
#   ../../scripts/generate-config.sh

ENV_FILE="${1:-.env}"
set -a
source "$ENV_FILE"
set +a

host_ojs_uid="$(getent passwd www-data | cut -d: -f3)"
host_ojs_gid="$(getent passwd www-data | cut -d: -f4)"
[[ "$host_ojs_uid" == "$OJS_UID" && "$host_ojs_gid" == "$OJS_GID" ]] || { echo "www-data debe ser 33:33." >&2; exit 1; }
install -d -o "$OJS_UID" -g "$OJS_GID" -m 0750 "$OJS_CONFIG_DIR" "$OJS_FILES_DIR" "$OJS_PUBLIC_DIR" "$OJS_CACHE_DIR"
TMP="$(mktemp)"
TMP_CONFIG="$(mktemp)"
trap 'rm -f "$TMP" "$TMP_CONFIG"' EXIT
docker run --rm "${REGISTRY}/encit/ojs:${IMAGE_TAG}" \
  cat /var/www/html/config.TEMPLATE.inc.php >"$TMP"

python3 - "$TMP" "$TMP_CONFIG" <<'PY'
import os,re,sys
src,dst=sys.argv[1:3]
s=open(src,encoding='utf-8').read()
def setv(key, val):
    global s
    pat=rf'(?m)^({re.escape(key)}\s*=\s*).*$'
    if not re.search(pat,s):
        raise SystemExit(f"No se encontró {key} en config.TEMPLATE.inc.php")
    # JSON quoting protege comillas y barras inversas en valores/secretos.
    encoded=json.dumps(str(val), ensure_ascii=False)
    s=re.sub(pat, lambda match: match.group(1) + encoded, s, count=1)

setv("installed", "On")
setv("base_url", os.environ["PUBLIC_BASE_URL"])
setv("files_dir", os.environ["OJS_FILES_DIR"])
setv("driver", "mysqli")
setv("host", "db")
setv("username", os.environ["MARIADB_USER"])
setv("password", os.environ["MARIADB_PASSWORD"])
setv("name", os.environ["MARIADB_DATABASE"])
setv("force_ssl", "On")
setv("trust_x_forwarded_for", "On")
setv("sandbox", os.environ["OJS_SANDBOX"])
setv("app_key", os.environ["OJS_APP_KEY"])

# allowed_hosts en OJS 3.5 es JSON.
host=re.sub(r'^https?://','',os.environ["PUBLIC_BASE_URL"]).split('/')[0]
pat=r'(?m)^(allowed_hosts\s*=\s*).*$'
if re.search(pat,s):
    s=re.sub(pat, rf'\1\'["{host}"]\'', s, count=1)

# SMTP si existen claves del template.
smtp = os.environ.get("SMTP_HOST","")
if smtp:
    for key,val in [
        ("smtp","On"),("smtp_server",smtp),("smtp_port",os.environ.get("SMTP_PORT","25")),
        ("smtp_auth", "tls" if os.environ.get("SMTP_USER") else "none"),
        ("smtp_username",os.environ.get("SMTP_USER","")),
        ("smtp_password",os.environ.get("SMTP_PASSWORD",""))
    ]:
        if re.search(rf'(?m)^{re.escape(key)}\s*=',s):
            setv(key,val)

open(dst,'w',encoding='utf-8').write(s)
PY
install -o "$OJS_UID" -g "$OJS_GID" -m 0640 "$TMP_CONFIG" "$OJS_CONFIG_DIR/config.inc.php"
echo "Generado: $OJS_CONFIG_DIR/config.inc.php (propietario 33:33, modo 0640)"
