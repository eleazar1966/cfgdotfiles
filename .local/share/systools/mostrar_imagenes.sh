#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
COLOR_FILE="$HOME/.config/waybar/colors.css"
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration 2"

[[ ! -d "$WALLPAPER_DIR" ]] && exit 1
pgrep -x "swww-daemon" >/dev/null || {
  swww-daemon --format xrgb &
  sleep 1
}

apply_changes() {
  local img="$1"
  [[ "$img" == "$(cat "$CACHE_LAST" 2>/dev/null)" ]] && return

  swww img "$img" $TRANSITION_ARGS &

  if command -v matugen &>/dev/null; then
    matugen image "$img" -t scheme-dark --contrast extreme >/dev/null 2>&1
    touch "$COLOR_FILE"
  fi

  echo "$img" >"$CACHE_LAST"
}

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
  for img in "${images[@]}"; do
    apply_changes "$img"
    sleep 1800
  done
done
