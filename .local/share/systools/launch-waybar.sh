#!/bin/bash
# --- Configuración ---
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
# Lista de archivos a vigilar por inotifywait.
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css $WAYBAR_CONFIG_DIR/power_menu.xml"

# --- Funciones ---

# Función para matar y relanzar Waybar
function reload_waybar {
  # 1. Matar Waybar si está corriendo (silenciosamente)
  if pgrep -x "waybar" >/dev/null; then
    echo "🔄 Recargando Waybar..."
    killall waybar
    # Espera para asegurar que el proceso muera completamente antes de reiniciar.
    sleep 0.5
  fi

  # 2. Inicia Waybar en segundo plano.
  # Esta comprobación es útil si el script se usa como 'exec' y Waybar ya se había lanzado antes
  # (aunque 'reload_waybar' ya lo mata, es una capa extra de seguridad).
  if ! pgrep -x "waybar" >/dev/null; then
    echo "🚀 Iniciando Waybar..."
    waybar &
  fi
}

# --- Ejecución ---

# 1. Trampa (trap) para asegurar que Waybar se cierre si el script termina (ej. si cierras la terminal)
trap "killall waybar 2>/dev/null; exit 0" EXIT

# 2. Inicialización: Lanza Waybar por primera vez (o lo recarga si ya estaba)
reload_waybar

# 3. Bucle de vigilancia de archivos
echo "👀 Vigilando archivos: $CONFIG_FILES"

while true; do
  # inotifywait espera un evento 'close_write' (el editor terminó de guardar el archivo)
  inotifywait -q -qq -e close_write $CONFIG_FILES

  # Pequeño retardo para agrupar múltiples guardados rápidos
  sleep 0.1

  # Recarga Waybar
  reload_waybar
done

# NOTA: Asegúrate de tener instalado 'inotify-tools' (el paquete que contiene inotifywait).
