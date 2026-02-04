#!/bin/bash

# --- CONFIGURACIÓN ---
REPOS=("/var/db/repos/guru" "/var/db/repos/wayland-desktop" "/var/db/repos/tryton")

# Eclasses que NO soportan EAPI 8
INCOMPATIBLE_ECLASSES="font-ebdftopcf"
# Eclasses que EXIGEN EAPI 8
MODERN_ECLASSES="cmake|cargo|python-r1|python-single-r1"

for REPO in "${REPOS[@]}"; do
  if [ ! -d "$REPO" ]; then continue; fi

  echo ">>> Saneando repositorio: $REPO"

  find "$REPO" -name "*.ebuild" | while read -r EBUILD; do
    CAMBIO=0

    # 1. Corrección de EAPI (CMake/Cargo)
    if grep -E -q "inherit.*($MODERN_ECLASSES)" "$EBUILD" && grep -q "EAPI=7" "$EBUILD"; then
      echo "  [ EAPI ] -> 8: $(basename "$EBUILD")"
      sudo sed -i 's/EAPI=7/EAPI=8/' "$EBUILD"
      CAMBIO=1
    fi

    # 2. Correcciones específicas para TRYTON (Instrucción 2026-02-04)
    if [[ "$EBUILD" == *"tryton"* ]]; then
      # Eliminar línea de tokens (Falla de lectura)
      if grep -q "tokens" "$EBUILD"; then
        echo "  [TRYTON] Limpiando tokens: $(basename "$EBUILD")"
        sudo sed -i '/tokens/d' "$EBUILD"
        CAMBIO=1
      fi

      # Corregir Átomos Inválidos (Error de sintaxis python-stdnum)
      if grep -q "=dev-python/python-stdnum" "$EBUILD"; then
        echo "  [TRYTON] Corrigiendo átomo stdnum: $(basename "$EBUILD")"
        sudo sed -i 's/=dev-python\/python-stdnum/dev-python\/python-stdnum/g' "$EBUILD"
        CAMBIO=1
      fi
    fi

    # 3. Regenerar manifest si hubo cambios
    if [ $CAMBIO -eq 1 ]; then
      sudo ebuild "$EBUILD" manifest
    fi
  done
done

echo ">>> Sistema saneado. Intenta la instalación ahora."
