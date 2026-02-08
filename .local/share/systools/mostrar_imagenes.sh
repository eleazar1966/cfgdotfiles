#!/bin/bash

# --- CONFIGURACIÓN ---
WALLPAPER_DIR="$HOME/.config/wallpaper" # Ruta corregida
CACHE_LAST="/tmp/last_wallpaper"
TRANSITION_ARGS="--transition-fps 60 --transition-type random --transition-duration 2 --transition-bezier .43,1.19,1,.4"

# --- LÓGICA DE PERSISTENCIA ---
trap 'SIG_SKIP=1' SIGUSR1

apply_changes() {
  local img="$1"

  # 1. Cambio de Wallpaper
  swww img "$img" $TRANSITION_ARGS

  # 2. Generación de colores con Matugen
  # Si matugen intenta llamar a hyprctl, asegúrate de configurar su config.toml sin hooks de Hyprland
  matugen image "$img"

  # 3. Recarga forzada de Waybar
  if pgrep -x "waybar" >/dev/null; then
    killall waybar
    sleep 0.5
  fi
  waybar &

  echo "$img" >"$CACHE_LAST"
}

# --- BUCLE PRINCIPAL ---
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "❌ Error: $WALLPAPER_DIR no existe."
  exit 1
fi

while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)

  for img in "${images[@]}"; do
    SIG_SKIP=0
    apply_changes "$img"

    for ((i = 0; i < 1800; i++)); do
      sleep 1
      if [[ $SIG_SKIP -eq 1 ]]; then break; fi
    done
  done
done
