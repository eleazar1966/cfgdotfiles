#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
LOCKFILE="/tmp/wallpaper_change.lock"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
QUEUE_DIR="$HOME/.cache/wallpaper"
QUEUE_FILE="$QUEUE_DIR/queue"

cleanup_swaybg() {
  pkill -x swaybg 2>/dev/null
  sleep 0.1
}

apply_changes() {
  local img="$1"
  # Lock atómico con mkdir (evita race conditions)
  mkdir "$LOCKFILE.lock" 2>/dev/null || return 1

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

  rmdir "$LOCKFILE.lock" 2>/dev/null
}

# Consume next wallpaper from shuffled queue — never repeats until all shown
next_from_queue() {
  mkdir -p "$QUEUE_DIR"

  # Regenerate queue if missing or empty
  if [[ ! -f "$QUEUE_FILE" || ! -s "$QUEUE_FILE" ]]; then
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
      \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) \
      | shuf > "$QUEUE_FILE"
  fi

  local img
  read -r img < "$QUEUE_FILE" || return 1

  # Remove consumed entry from queue
  tail -n +2 "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"

  echo "$img"
}

if [[ -n "$1" ]]; then
  # Single-shot mode (Mod+Shift+W): pop from shuffled queue, never repeat
  img=$(next_from_queue)

  # Safety net: if queue failed somehow, regenerate and retry once
  if [[ -z "$img" || ! -f "$img" ]]; then
    rm -f "$QUEUE_FILE"
    img=$(next_from_queue)
  fi

  [[ -f "$img" ]] && apply_changes "$img"
else
  while true; do
    mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
    for img in "${images[@]}"; do
      apply_changes "$img"
      sleep 1800
    done
  done
fi
