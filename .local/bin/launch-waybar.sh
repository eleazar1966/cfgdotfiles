#!/bin/bash
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

cleanup() {
  kill "$MONITOR_PID" 2>/dev/null
  exit 0
}
trap cleanup SIGINT SIGTERM

# Matar otras instancias de este mismo script (evitar duplicados)
for pid in $(pgrep -f "launch-waybar.sh"); do
  if [ "$pid" != "$$" ]; then kill "$pid" 2>/dev/null; fi
done

HAS_INOTIFY=0
command -v inotifywait &>/dev/null && HAS_INOTIFY=1

if [ "$HAS_INOTIFY" -eq 1 ]; then
  (
    while true; do
      inotifywait -q -e close_write $CONFIG_FILES
      killall waybar 2>/dev/null
    done
  ) &
  MONITOR_PID=$!
else
  MONITOR_PID=""
fi

while true; do
  waybar >/dev/null 2>&1
  sleep 0.5
done
