#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-siia-inventory-$(date +%Y%m%d-%H%M%S).txt}"
{
  echo "=== OS ==="
  cat /etc/os-release || true
  uname -a
  echo "=== Python ==="
  python3 --version || true
  which python3 || true
  echo "=== Pip ==="
  python3 -m pip --version || true
  python3 -m pip freeze || true
  echo "=== Flask ==="
  python3 - <<'PY'
try:
    import flask
    print(flask.__version__)
except Exception as e:
    print(e)
PY
  echo "=== Servicios ==="
  systemctl list-units --type=service --state=running || true
  echo "=== PostgreSQL client ==="
  psql --version || true
  echo "=== PostgreSQL server ==="
  sudo -u postgres psql -Atc "select version();" 2>/dev/null || true
  echo "=== Databases ==="
  sudo -u postgres psql -Atc "\l" 2>/dev/null || true
  echo "=== Extensions ==="
  sudo -u postgres psql -Atc "select datname from pg_database where datistemplate=false;" 2>/dev/null |
  while read -r db; do
    echo "--- $db"
    sudo -u postgres psql -d "$db" -Atc "select extname||' '||extversion from pg_extension;" || true
  done
  echo "=== Disk ==="
  df -h
  du -sh /var/lib/postgresql 2>/dev/null || true
  echo "=== App candidates ==="
  find /opt /srv /var/www /home -maxdepth 4 \
    \( -name 'requirements*.txt' -o -name 'Pipfile' -o -name 'setup.py' -o -name 'wsgi.py' \) \
    -print 2>/dev/null || true
} | tee "$OUT"
echo "Inventario escrito en $OUT"
