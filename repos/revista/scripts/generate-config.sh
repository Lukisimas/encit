#!/usr/bin/env bash
set -euo pipefail
# Genera config.inc.php desde el config.TEMPLATE.inc.php que trae EXACTAMENTE la imagen OJS.
# Uso: desde el directorio del entorno con .env:
#   ../../scripts/generate-config.sh

ENV_FILE="${1:-.env}"
set -a
source "$ENV_FILE"
set +a

mkdir -p "$OJS_CONFIG_DIR" "$OJS_FILES_DIR" "$OJS_PUBLIC_DIR" "$OJS_CACHE_DIR"
TMP="$(mktemp)"
docker run --rm "${REGISTRY}/encit/ojs:${IMAGE_TAG}" \
  cat /var/www/html/config.TEMPLATE.inc.php >"$TMP"

python3 - "$TMP" "$OJS_CONFIG_DIR/config.inc.php" <<'PY'
import os,re,sys
src,dst=sys.argv[1:3]
s=open(src,encoding='utf-8').read()
def setv(key, val):
    global s
    pat=rf'(?m)^({re.escape(key)}\s*=\s*).*$'
    if not re.search(pat,s):
        raise SystemExit(f"No se encontró {key} en config.TEMPLATE.inc.php")
    # OJS INI acepta valores entre comillas.
    val=str(val).replace('"','\\"')
    s=re.sub(pat, rf'\1"{val}"', s, count=1)

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
rm -f "$TMP"
chmod 0640 "$OJS_CONFIG_DIR/config.inc.php"
echo "Generado: $OJS_CONFIG_DIR/config.inc.php"
