#!/bin/bash
set -euo pipefail

TARGET="$HOME/fonts"
TEMP_DIR="$HOME/fonts_clean_temp"

rm -rf "$TEMP_DIR"
mkdir -p "$TARGET"

echo "==> Paso 1: Buscando fuentes en directorios estándar (sin escanear /)..."
FONT_DIRS=(
  "/usr/share/fonts"
  "/usr/local/share/fonts"
  "$HOME/.fonts"
  "$HOME/.local/share/fonts"
)
for dir in "${FONT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "   Escaneando: $dir"
    find "$dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$TARGET" \; 2>/dev/null || true
  fi
done

echo "==> Paso 2: Eliminando duplicados..."
[ -f "$TARGET/$(ls "$TARGET" 2>/dev/null | head -1)" ] && jdupes -rdN "$TARGET" 2>/dev/null || true

echo "==> Paso 3: Copiando a /usr/share/fonts/custom-imported/..."
sudo mkdir -p /usr/share/fonts/custom-imported
sudo cp -r "$TARGET"/* /usr/share/fonts/custom-imported/ 2>/dev/null || true
sudo chown -R root:root /usr/share/fonts/custom-imported
sudo fc-cache -rfv >/dev/null 2>&1

echo "✅ Fuentes procesadas. Directorio: $TARGET"
echo "   Sistema: /usr/share/fonts/custom-imported"
