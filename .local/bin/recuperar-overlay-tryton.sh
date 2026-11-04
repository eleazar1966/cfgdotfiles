#!/bin/bash
# Reconstruye el overlay local de Tryton desde la base de datos de paquetes
# instalados (/var/db/pkg), donde portage guarda una copia literal de cada
# ebuild instalado.
#
# Por qué existe: el overlay upstream (foss.heptapod.net/tryton/gentoo-overlay)
# quedó inaccesible — el sidecar Mercurial de Heptapod responde 503
# ("Heptapod is not responding") y hg recibe HTTP 500. Portage, al fallar el
# `hg pull`, borra el repo y reintenta `hg clone`; si el clone también falla,
# /var/db/repos/tryton queda vacío y todos los paquetes de Tryton se quedan sin
# ebuilds (el 2026-10-27 pasó exactamente eso).
#
# Esto reconstruye el overlay CONGELADO en las versiones instaladas. No sustituye
# al upstream: cuando Heptapod vuelva hay que resincronizar de verdad.
#
# Uso:
#   sudo recuperar-overlay-tryton.sh           # reconstruye si el repo está vacío
#   sudo recuperar-overlay-tryton.sh --force   # reconstruye igual (borra el actual)
set -euo pipefail

# Los repos del sistema están en 755/644 (ver /var/db/repos/gentoo). Sin esto, un
# umask restrictivo deja el repo en 750/640 y herramientas sin privilegios como
# `portageq get_repos /` o eselect fallan con "Permission denied" en eclass/.
umask 022

DEST="/var/db/repos/tryton"
VDB="/var/db/pkg"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: hay que correrlo con sudo (escribe en $DEST)." >&2
  exit 1
fi

if [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ] && [ "$FORCE" -ne 1 ]; then
  echo "ABORTA: $DEST no está vacío. Usá --force si de verdad querés reconstruirlo." >&2
  exit 1
fi

# 1. Esqueleto del repo
rm -rf "$DEST"
mkdir -p "$DEST/metadata" "$DEST/profiles"
printf 'masters = gentoo\nthin-manifests = true\n' >"$DEST/metadata/layout.conf"
printf 'tryton\n' >"$DEST/profiles/repo_name"

# 2. Ebuilds desde el VDB. portage exige <categoria>/<PN>/<PF>.ebuild, así que el
#    nombre del paquete y el PF se derivan con catpkgsplit (no a mano).
python3 - "$VDB" "$DEST" <<'PY'
import os
import shutil
import sys

from portage.versions import catpkgsplit

vdb, dest = sys.argv[1], sys.argv[2]
REPO = "tryton"

# La atribución NO se adivina: portage escribe /var/db/pkg/<cat>/<pf>/repository
# con el nombre del repo que instaló cada paquete. Filtrar por una lista blanca de
# nombres deja afuera dependencias (dev-python/proteus, dev-javascript/*, …): la
# primera reconstrucción recuperó 29 de los 49 reales por ese error.
copied = []
for cat in sorted(os.listdir(vdb)):
    cdir = os.path.join(vdb, cat)
    if not os.path.isdir(cdir):
        continue
    for pf in sorted(os.listdir(cdir)):
        pfdir = os.path.join(cdir, pf)
        src = os.path.join(pfdir, pf + ".ebuild")
        repo_file = os.path.join(pfdir, "repository")
        if not os.path.isdir(pfdir) or not os.path.isfile(src):
            continue
        if not os.path.isfile(repo_file):
            continue
        if open(repo_file).read().strip() != REPO:
            continue
        split = catpkgsplit(f"{cat}/{pf}")
        if split is None:
            print(f"AVISO: no pude parsear {cat}/{pf}", file=sys.stderr)
            continue
        _, pn, _ver, _rev = split
        dstdir = os.path.join(dest, cat, pn)
        os.makedirs(dstdir, exist_ok=True)
        shutil.copy2(src, os.path.join(dstdir, pf + ".ebuild"))
        copied.append(f"{cat}/{pf}")

cats = sorted({c.split("/")[0] for c in copied})
open(os.path.join(dest, "profiles", "categories"), "w").write("\n".join(cats) + "\n")
print(f"ebuilds copiados: {len(copied)}")
for c in copied:
    print(f"  {c}")
PY

# 3. Manifests a partir de los distfiles que ya están cacheados
ok=0
fails=0
while IFS= read -r f; do
  if ebuild "$f" manifest >/dev/null 2>&1; then
    ok=$((ok + 1))
  else
    fails=$((fails + 1))
    echo "AVISO: no se pudo generar el Manifest de $f (¿falta el distfile?)" >&2
  fi
done < <(find "$DEST" -name '*.ebuild' | sort)

echo
echo "Manifests generados: ok=$ok fallos=$fails"

# Permisos parejos con el resto de los repos (755 dirs / 644 ficheros)
chmod -R u=rwX,go=rX "$DEST"

echo "Repo: $DEST"
echo
echo "Recordatorio: esto es el overlay CONGELADO en las versiones instaladas."
echo "El sync de upstream sigue roto. Ver /etc/portage/repos.conf/eselect-repo.conf"
echo "([tryton] con auto-sync = no) y probar 'emaint sync -r tryton' cuando vuelva."
