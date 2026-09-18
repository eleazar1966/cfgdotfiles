#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
STATE_DIR="$HOME/.local/share/wallpaper"
CACHE_LAST="$STATE_DIR/last"
LOCKFILE="$STATE_DIR/apply.lock"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
QUEUE_FILE="$STATE_DIR/queue"

# Ensure the persistent state dir exists (created on first run; survives reboots)
mkdir -p "$STATE_DIR"

cleanup_swaybg() {
  pkill -x swaybg 2>/dev/null
  sleep 0.1
}

apply_changes() {
  local img="$1"
  # Atomic lock with flock: releases automatically when the fd closes,
  # even if the process is killed — no stale locks, no /tmp dependence
  exec 9>"$LOCKFILE"
  if ! flock -n 9; then
    return 1
  fi

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

  flock -u 9
}

list_wallpapers() {
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \)
}

# Rebuild a fresh shuffled queue, excluding the last applied wallpaper so the
# first of a new cycle can never equal the last of the previous one.
regen_queue() {
  local last=""
  [[ -f "$CACHE_LAST" ]] && last="$(<"$CACHE_LAST")"
  if [[ -n "$last" ]]; then
    list_wallpapers | grep -vxF "$last" | shuf > "$QUEUE_FILE"
  else
    list_wallpapers | shuf > "$QUEUE_FILE"
  fi
  # Fallback: exclusion emptied the list (e.g. dir with a single image) — use the full list
  if [[ ! -s "$QUEUE_FILE" ]]; then
    list_wallpapers | shuf > "$QUEUE_FILE"
  fi
}

# Consume the pop from the shared queue atomically: concurrent invocations
# (daemon + Mod+Shift+W) never see the same entry.
next_from_queue() {
  exec 8>"$LOCKFILE"
  flock 8

  # Regenerate the queue if missing or empty (persists across reboots)
  if [[ ! -f "$QUEUE_FILE" || ! -s "$QUEUE_FILE" ]]; then
    regen_queue
  fi

  local img
  read -r img < "$QUEUE_FILE" || { flock -u 8; return 1; }

  # Remove consumed entry from queue
  tail -n +2 "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"

  flock -u 8
  echo "$img"
}

if [[ -n "$1" ]]; then
  # Single-shot mode (Mod+Shift+W): pop from the shared queue, never repeat
  img=$(next_from_queue)

  # Safety net: if the queue failed somehow, regenerate and retry once
  if [[ -z "$img" || ! -f "$img" ]]; then
    rm -f "$QUEUE_FILE"
    img=$(next_from_queue)
  fi

  [[ -f "$img" ]] && apply_changes "$img"
else
  # Daemon mode (startup): consume the SAME queue as the bind
  while true; do
    img=$(next_from_queue)

    if [[ -z "$img" || ! -f "$img" ]]; then
      rm -f "$QUEUE_FILE"
      img=$(next_from_queue)
    fi

    [[ -f "$img" ]] && apply_changes "$img"
    sleep 1800
  done
fi