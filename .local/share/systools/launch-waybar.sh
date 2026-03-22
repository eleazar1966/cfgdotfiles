#!/bin/bash
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILES="$WAYBAR_CONFIG_DIR/config.jsonc $WAYBAR_CONFIG_DIR/style.css $WAYBAR_CONFIG_DIR/colors.css"

function reload_waybar {
  if [ -f /tmp/waybar_reloading ]; then return; fi
  touch /tmp/waybar_reloading
  pkill -x waybar
  while pgrep -x waybar >/dev/null; do sleep 0.1; done
  waybar >/dev/null 2>&1 &
  sleep 0.5
  rm /tmp/waybar_reloading
}

pkill -x waybar
reload_waybar

while true; do
  inotifywait -e modify,close_write $CONFIG_FILES >/dev/null 2>&1
  sleep 0.3
  reload_waybar
done
