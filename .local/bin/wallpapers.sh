#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
LOCKFILE="/tmp/wallpaper_change.lock"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"

cleanup_swaybg() {
  pkill -x swaybg 2>/dev/null
  sleep 0.1
}

apply_changes() {
  local img="$1"
  [[ -f "$LOCKFILE" ]] && rm -f "$LOCKFILE"
  touch "$LOCKFILE"

  if command -v matugen &>/dev/null; then
    if [[ -f "$MATUGEN_CONFIG" ]]; then
      matugen --config "$MATUGEN_CONFIG" --prefer=saturation image "$img"
    else
      matugen --prefer=saturation image "$img"
    fi
    sleep 0.2
  fi

  cleanup_swaybg
  swaybg -i "$img" -m fill &

  echo "$img" >"$CACHE_LAST"
  niri msg action load-config-file >/dev/null 2>&1
  pkill -x -USR2 waybar 2>/dev/null

  rm -f "$LOCKFILE"
}

if [[ -n "$1" ]]; then
  img=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
  [[ -n "$img" ]] && apply_changes "$img"
else
  while true; do
    mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
    for img in "${images[@]}"; do
      apply_changes "$img"
      sleep 1800
    done
  done
fi
