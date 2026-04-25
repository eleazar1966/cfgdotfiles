#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
LOCKFILE="/tmp/wallpaper_change.lock"

# 1. Función de limpieza para asegurar que no queden procesos huérfanos
cleanup_swaybg() {
  pkill swaybg
  sleep 0.1
}

apply_changes() {
  local img="$1"
  [[ -f "$LOCKFILE" ]] && rm -f "$LOCKFILE"
  touch "$LOCKFILE"

  # 2. Generar colores con Matugen
  if command -v matugen &>/dev/null; then
    matugen image "$img" &>/dev/null
    sleep 0.1
  fi

  # 3. Aplicar fondo con swaybg
  # swaybg no tiene transiciones, por lo que matamos el anterior y lanzamos el nuevo
  cleanup_swaybg
  swaybg -i "$img" -m fill & 

  # 4. Notificaciones y caché
  echo "$img" >"$CACHE_LAST"
  touch "$WAYBAR_COLORS"
  niri msg action load-config-file >/dev/null 2>&1

  rm -f "$LOCKFILE"
}

# Lógica de ejecución
if [[ -n "$1" ]]; then
  # Si se pasa un argumento (aunque el script original buscaba aleatorio igual)
  img=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
  [[ -n "$img" ]] && apply_changes "$img"
else
  # Modo bucle
  while true; do
    mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
    for img in "${images[@]}"; do
      apply_changes "$img"
      sleep 1800
    done
  done
fi
