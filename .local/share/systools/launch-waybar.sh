#!/bin/bash
# --- Configuración ---
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
# Es vital vigilar colors.css para que reaccione a matugen
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

function reload_waybar {
  echo "🔄 Limpiando instancias de Waybar..."
  pkill -x waybar

  # Espera activa para asegurar que el proceso se cerró
  while pgrep -x waybar >/dev/null; do sleep 0.1; done

  echo "🚀 Iniciando Waybar con nueva configuración..."
  waybar &
}

# Cerrar al salir
trap "pkill -x waybar; exit 0" EXIT

# Lanzamiento inicial
reload_waybar

echo "👀 Vigilando cambios en: $CONFIG_FILES"
while true; do
  # Escuchamos 'modify' para detectar cuando matugen sobrescribe el archivo
  inotifywait -q -qq -e modify -e close_write $CONFIG_FILES

  # Breve pausa para que el sistema de archivos termine de escribir
  sleep 0.2
  reload_waybar

  notify-send -t 2000 "Waybar" "Interfaz recargada con nuevos colores" -i active-cache
done
