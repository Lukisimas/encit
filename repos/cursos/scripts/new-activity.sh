#!/usr/bin/env bash
set -euo pipefail
TYPE="${1:?curso|diplomado}"
SLUG="${2:?slug}"
SRC="templates/$TYPE"
DST="src/data/oferta/$SLUG"
test -d "$SRC" || { echo "Tipo desconocido"; exit 1; }
test ! -e "$DST" || { echo "Ya existe $DST"; exit 1; }
cp -a "$SRC" "$DST"
python3 - "$DST/curso.json" "$SLUG" <<'PY'
import json,sys
p,slug=sys.argv[1:3]
d=json.load(open(p,encoding='utf8'))
d['slug']=slug
json.dump(d,open(p,'w',encoding='utf8'),ensure_ascii=False,indent=2)
open(p,'a').write('\n')
PY
rm -f "$DST/LEEME.txt"
echo "$DST"
