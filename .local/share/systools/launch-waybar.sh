#!/bin/bash
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

function reload_waybar {
  # Evita que se ejecuten recargas simultáneas si inotify detecta varios cambios rápidos
  if pgrep -x "waybar_reloading" >/dev/null; then return; fi
  touch /tmp/waybar_reloading

  echo "🔄 Recargando Waybar..."
  pkill -x waybar
  while pgrep -x waybar >/dev/null; do sleep 0.1; done

  waybar >/dev/null 2>&1 &

  sleep 1 # Tiempo de asentamiento
  rm /tmp/waybar_reloading
  notify-send -t 2000 "Waybar" "Interfaz actualizada con éxito" -i active-cache
}

trap "pkill -x waybar; rm /tmp/waybar_reloading; exit 0" EXIT

# Lanzamiento inicial
reload_waybar

while true; do
  # Vigila los archivos de configuración y el de colores generado por matugen
  inotifywait -q -qq -e modify -e close_write $CONFIG_FILES
  sleep 0.5 # Espera a que matugen termine de escribir el archivo completamente
  reload_waybar
done
