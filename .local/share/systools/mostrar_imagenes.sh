#!/bin/bash

# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
TRANS_DUR=2
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration $TRANS_DUR --transition-bezier .43,1.19,1,.4 --transition-step 60"

apply_changes() {
  local img="$1"
  [[ -f "$CACHE_LAST" ]] && [[ "$(<"$CACHE_LAST")" == "$img" ]] && return

  # 1. Matugen asíncrono (no bloquea)
  matugen image "$img" >/dev/null 2>&1 &

  # 2. Aplicar wallpaper
  swww img "$img" $TRANSITION_ARGS

  # 3. Recarga Waybar solo si ya existe (evita colisión en primer arranque)
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

# --- INICIALIZACIÓN SEGURA ---
sleep 3 # Tiempo para que Niri registre el teclado y la salida de video

until swww query >/dev/null 2>&1; do
  sleep 0.5
done

trap 'kill $! 2>/dev/null' USR1

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)

  for img in "${images[@]}"; do
    apply_changes "$img"
    sleep 1800 &
    wait $!
  done
done
