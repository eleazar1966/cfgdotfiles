#!/bin/bash

# Rutas de configuración
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

# --- SINGLETON: Evitar duplicados del monitor y de Waybar ---
# Mata cualquier instancia previa de este script para evitar que varios bucles lancen Waybar
for pid in $(pgrep -f "launch-waybar.sh"); do
  if [ "$pid" != "$$" ]; then
    kill "$pid" 2>/dev/null
  fi
done

# Limpieza inicial de procesos huérfanos
killall waybar 2>/dev/null

# --- VIGILANTE DE ARCHIVOS (Segundo plano) ---
# Este bucle solo espera cambios. Si detecta uno, mata Waybar.
# El bucle principal (abajo) detectará que Waybar murió y lo reiniciará.
(
  while true; do
    inotifywait -q -e close_write $CONFIG_FILES
    # Al tocar un archivo, matamos el proceso para forzar la recarga
    killall waybar 2>/dev/null
  done
) &

# --- BUCLE PRINCIPAL (Supervisor) ---
# Ejecuta Waybar en primer plano. Si termina (por killall o error), espera y reinicia.
while true; do
  waybar >/dev/null 2>&1
  # Pausa de seguridad para que el sistema de archivos asiente cambios (Matugen)
  sleep 0.5
done
