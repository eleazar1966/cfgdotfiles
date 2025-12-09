#!/bin/bash
# --- Configuración ---
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css $WAYBAR_CONFIG_DIR/power_menu.xml"
waybar &
# --- Funciones ---

# Función para matar y esperar a Waybar
function reload_waybar {
  # Evita matar el proceso de Waybar si no está corriendo.
  if pgrep -x "waybar" >/dev/null; then
    echo "🔄 Recargando Waybar..."
    killall waybar
    # Espera un momento para asegurar que el proceso anterior haya terminado.
    # Esto previene que se lance una nueva instancia antes de que muera la anterior.
    sleep 0.5
  fi
  # Inicia Waybar en segundo plano.
  waybar &
}

# --- Ejecución ---
# 1. Trampa para asegurar el cierre de Waybar al terminar el script.
trap "killall waybar 2>/dev/null; exit 0" EXIT

# 2. Manejo de eventos más robusto en inotifywait.
#    -e close_write es mejor que modify, ya que solo se dispara cuando el editor termina de escribir
#    y cierra el archivo, evitando múltiples reinicios por un solo 'Guardar'.

echo "👀 Vigilando archivos: $CONFIG_FILES"
reload_waybar # Inicia Waybar por primera vez

while true; do
  # inotifywait se silencia con -q y -qq
  inotifywait -q -qq -e close_write $CONFIG_FILES

  # Un pequeño retardo antes de recargar. Útil si se guardan varios archivos rápidamente.
  sleep 0.1

  reload_waybar
done

# NOTA: Asegúrate de tener instalado 'inotify-tools' (el paquete que contiene inotifywait).
:q
