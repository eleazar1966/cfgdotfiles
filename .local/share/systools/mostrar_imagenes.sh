#!/bin/bash

# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
TRANS_DUR=2
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration $TRANS_DUR --transition-bezier .43,1.19,1,.4 --transition-step 60"

apply_changes() {
  local img="$1"

  # Validar duplicados
  [[ -f "$CACHE_LAST" ]] && [[ "$(<"$CACHE_LAST")" == "$img" ]] && return

  # 1. GENERAR COLORES PRIMERO (Matugen)
  matugen image "$img" >/dev/null 2>&1

  # 2. APLICAR WALLPAPER (swww)
  swww clear
  swww img "$img" $TRANSITION_ARGS

  # 3. RECARGA LIMPIA DE INTERFAZ
  (
    sleep $((TRANS_DUR + 1))
    killall -q waybar
    while pgrep -x waybar >/dev/null; do sleep 0.1; done
    waybar >/dev/null 2>&1 &
  ) &

  echo "$img" >"$CACHE_LAST"
}

# --- INICIALIZACIÓN ---
if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon --format xrgb &
  sleep 1
fi

# MANEJADOR DE SEÑAL: Al recibir USR1, termina el 'sleep' actual para saltar a la siguiente imagen
trap 'kill $! 2>/dev/null' USR1

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)

  for img in "${images[@]}"; do
    apply_changes "$img"
    # El sleep se ejecuta en segundo plano para poder ser interrumpido por el trap
    sleep 1800 &
    wait $!
  done
done
