#!/bin/bash
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

function reload_waybar {
  if pgrep -x "waybar" >/dev/null; then
    killall waybar
    sleep 0.5
  fi
  waybar &
}

trap "killall waybar 2>/dev/null; exit 0" EXIT

reload_waybar

while true; do
  inotifywait -q -qq -e close_write $CONFIG_FILES
  sleep 0.3
  reload_waybar
done
