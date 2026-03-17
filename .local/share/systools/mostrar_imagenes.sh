#!/bin/bash

# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_DIR="$HOME/.cache/wallpaper_logic"
PID_FILE="/tmp/mostrar_imagenes.pid"
CACHE_LAST="/tmp/last_wallpaper"
NIRI_COLORS="$HOME/.config/niri/colors.kdl"
TRANS_DUR=2
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration $TRANS_DUR --transition-bezier .43,1.19,1,.4 --transition-step 60"

echo $$ >"$PID_FILE"
mkdir -p "$CACHE_DIR"

# BOOTSTRAP: Crea el archivo si no existe para evitar errores en config.kdl
if [ ! -f "$NIRI_COLORS" ]; then
  echo "layout { }" >"$NIRI_COLORS"
fi

apply_changes() {
  local img="$1"
  [[ -f "$CACHE_LAST" ]] && [[ "$(<"$CACHE_LAST")" == "$img" ]] && return

  # 1. Matugen genera colores
  matugen image "$img" >/dev/null 2>&1

  # 2. Aplicar wallpaper
  swww img "$img" $TRANSITION_ARGS

  # 3. Recargar Niri para aplicar colores
  niri msg action reload-config

  # 4. Recarga Waybar
  if pgrep -x waybar >/dev/null; then
    (
      sleep $((TRANS_DUR + 1))
      killall -q waybar
      sleep 0.5
      waybar >/dev/null 2>&1 &
    ) &
  fi

  echo "$img" >"$CACHE_LAST"
}

trap 'kill $! 2>/dev/null' USR1

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)

  for img in "${images[@]}"; do
    apply_changes "$img"
    sleep 1800 &
    wait $!
  done
done
