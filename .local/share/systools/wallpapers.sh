#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
LOCKFILE="/tmp/wallpaper_change.lock"

# 1. Asegurar que swww-daemon esté vivo
if ! swww query >/dev/null 2>&1; then
  swww-daemon &
  sleep 0.5
fi

apply_changes() {
  local img="$1"
  [[ -f "$LOCKFILE" ]] && rm -f "$LOCKFILE" # Limpiar bloqueo previo si existe
  touch "$LOCKFILE"

  # 2. Matugen genera los colores
  if command -v matugen &>/dev/null; then
    matugen image "$img" &>/dev/null
    sleep 0.1
  fi

  # 3. Extraer color con fallback (evita que swww falle por sintaxis)
  # Buscamos la línea de background y limpiamos caracteres no deseados
  BG_COLOR=$(grep "background" "$WAYBAR_COLORS" | head -n 1 | awk '{print $3}' | tr -d ';')
  if [[ ! "$BG_COLOR" =~ ^# ]]; then
    BG_COLOR="#000000"
  fi

  # 4. Cambiar fondo (Si falla con parámetros extra, intenta el simple)
  swww img "$img" \
    --transition-type grow \
    --transition-pos top-right \
    --transition-duration 1.5 \
    --transition-bg "$BG_COLOR" || swww img "$img"

  # 5. Notificaciones
  echo "$img" >"$CACHE_LAST"
  touch "$WAYBAR_COLORS" # Esto activa el reinicio de Waybar en launch-waybar.sh
  niri msg action load-config-file >/dev/null 2>&1

  rm -f "$LOCKFILE"
}

# Lógica de ejecución
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
