#!/bin/bash

# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration 2 --transition-bezier .43,1.19,1,.4 --transition-step 60"

# --- LÓGICA DE PERSISTENCIA ---
trap 'SIG_SKIP=1' SIGUSR1

apply_changes() {
  local img="$1"

  # Validar si la imagen es la misma que la actual para evitar doble ejecución
  if [[ -f "$CACHE_LAST" ]]; then
    local last_img=$(cat "$CACHE_LAST")
    if [[ "$last_img" == "$img" ]]; then
      return
    fi
  fi

  # 1. Aplicar wallpaper (swww gestiona su propia transición)
  swww img "$img" $TRANSITION_ARGS

  # 2. Procesos paralelos con retraso controlado
  (
    # Pausa estratégica para dejar que la transición de swww se estabilice
    sleep 0.5
    # Generar colores
    matugen image "$img" >/dev/null 2>&1

    # Recarga de Waybar
    if pgrep -x "waybar" >/dev/null; then
      killall -q waybar
      while pgrep -x waybar >/dev/null; do sleep 0.1; done
    fi
    waybar >/dev/null 2>&1 &
  ) &

  echo "$img" >"$CACHE_LAST"
}

# --- BUCLE PRINCIPAL ---
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "❌ Error: $WALLPAPER_DIR no existe."
  exit 1
fi

if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon --format xrgb &
  sleep 1
fi

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
