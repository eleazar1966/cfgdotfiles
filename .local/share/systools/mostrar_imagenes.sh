#!/bin/bash
# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
COLOR_FILE="$HOME/.config/waybar/colors.css"
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration 2 --transition-bezier .43,1.19,1,.4 --transition-step 60"

apply_changes() {
  local img="$1"
  [[ "$img" == "$(cat "$CACHE_LAST" 2>/dev/null)" ]] && return

  # 1. Aplicar wallpaper
  swww img "$img" $TRANSITION_ARGS

  # 2. Generar colores y notificar al vigilante
  (
    if command -v matugen &>/dev/null; then
      matugen image "$img" >/dev/null 2>&1
      # El 'touch' dispara el inotifywait del script launch-waybar.sh
      touch "$COLOR_FILE"
    fi
  ) &

  echo "$img" >"$CACHE_LAST"
}

# --- BUCLE PRINCIPAL ---
[[ ! -d "$WALLPAPER_DIR" ]] && exit 1
pgrep -x "swww-daemon" >/dev/null || {
  swww-daemon --format xrgb &
  sleep 1
}

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
  for img in "${images[@]}"; do
    SIG_SKIP=0
    apply_changes "$img"
    for ((i = 0; i < 1800; i++)); do
      sleep 1
      [[ $SIG_SKIP -eq 1 ]] && break
    done
  done
done
