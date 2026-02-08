#!/bin/bash

# Directorio de aplicaciones del usuario
APP_DIR="$HOME/.local/share/applications"
# Archivo temporal para el reporte
LOG_FILE="/tmp/rofi_cleanup.log"

echo "--- Iniciando limpieza de accesos directos con iconos rotos ---"

# Buscar archivos .desktop que contienen rutas a archivos que no existen
find "$APP_DIR" -name "*.desktop" | while read -r file; do
  # Extraer el valor de la línea Icon=
  icon_path=$(grep "^Icon=" "$file" | cut -d'=' -f2)

  # Si la ruta empieza con / (es una ruta absoluta)
  if [[ "$icon_path" == /* ]]; then
    if [ ! -f "$icon_path" ]; then
      echo "Icono no encontrado: $icon_path en $(basename "$file")"

      # Opción A: Comentar la línea del icono para que use uno por defecto
      sed -i 's/^Icon=/#Icon_Broken=/g' "$file"

      # Opción B: Si prefieres borrar el archivo .desktop completo, usa:
      # rm "$file" && echo "Archivo eliminado."
    fi
  fi
done

# Limpiar caché de Rofi por si acaso
rm -rf ~/.cache/rofi-*

echo "--- Limpieza completada ---"
