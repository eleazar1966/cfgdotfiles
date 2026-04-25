#!/bin/bash
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

# Matar instancias duplicadas del propio script
for pid in $(pgrep -f "launch-waybar.sh"); do
  if [ "$pid" != "$$" ]; then kill "$pid" 2>/dev/null; fi
done

# Vigilante: Cuando cambian los colores, mata waybar
(
  while true; do
    inotifywait -q -e close_write $CONFIG_FILES
    killall waybar 2>/dev/null
  done
) &

# Supervisor: Si waybar muere, lo revive (con la nueva paleta)
while true; do
  waybar >/dev/null 2>&1
  sleep 0.5
done
