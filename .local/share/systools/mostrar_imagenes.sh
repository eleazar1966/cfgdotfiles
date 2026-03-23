#!/bin/bash
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_LAST="/tmp/last_wallpaper"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
LOCKFILE="/tmp/wallpaper_change.lock"

[[ ! -d "$WALLPAPER_DIR" ]] && exit 1

apply_changes() {
  local img="$1"

  [[ "$img" == "$(cat "$CACHE_LAST" 2>/dev/null)" ]] && return
  [[ -f "$LOCKFILE" ]] && return

  touch "$LOCKFILE"

  # 1. Cambiar fondo
  swww img "$img" --transition-type random &

  # 2. Generar colores con Matugen
  if command -v matugen &>/dev/null; then
    matugen image "$img" &>/dev/null 2>&1

    # Pausa crítica para asegurar escritura completa de archivos
    sleep 0.5

    # 3. Notificar a Waybar mediante el trigger de inotify
    touch "$WAYBAR_COLORS"

    # 4. Notificar a Niri
    if command -v niri &>/dev/null; then
      niri msg action load-config-file
    fi
  fi

  echo "$img" >"$CACHE_LAST"
  rm -f "$LOCKFILE"
}

# Ejecución manual (Mod+Shift+W)
if [[ -n "$1" ]]; then
  img=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
  apply_changes "$img"
  exit 0
fi

# Bucle automático
while true; do
  mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf)
  for img in "${images[@]}"; do
    apply_changes "$img"
    sleep 1800
  done
done
