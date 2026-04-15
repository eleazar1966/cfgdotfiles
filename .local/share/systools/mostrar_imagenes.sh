#!/bin/bash
# Configuración de rutas persistentes
WALLPAPER_DIR="$HOME/.config/wallpaper"
CACHE_DIR="$HOME/.cache/wallpaper_script"
TODO_FILE="$CACHE_DIR/wallpaper_todo"
DONE_FILE="$CACHE_DIR/wallpaper_done"
CACHE_LAST="/tmp/last_wallpaper"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
LOCKFILE="/tmp/wallpaper_change.lock"

mkdir -p "$CACHE_DIR"
touch "$TODO_FILE" "$DONE_FILE"

# 1. Asegurar daemon
if ! swww query >/dev/null 2>&1; then
  swww-daemon &
  sleep 0.5
fi

apply_changes() {
  local img="$1"
  [[ -f "$LOCKFILE" ]] && rm -f "$LOCKFILE"
  touch "$LOCKFILE"

  if command -v matugen &>/dev/null; then
    matugen image "$img" &>/dev/null
    sleep 0.1
  fi

  BG_COLOR=$(grep "background" "$WAYBAR_COLORS" | head -n 1 | awk '{print $3}' | tr -d ';')
  [[ ! "$BG_COLOR" =~ ^# ]] && BG_COLOR="#000000"

  swww img "$img" \
    --transition-type grow \
    --transition-pos top-right \
    --transition-duration 1.5 \
    --transition-bg "$BG_COLOR" || swww img "$img"

  echo "$img" >"$CACHE_LAST"
  touch "$WAYBAR_COLORS"
  niri msg action load-config-file >/dev/null 2>&1
  rm -f "$LOCKFILE"
}

# --- Lógica de Sincronización Dinámica ---
sync_images() {
  # 1. Obtener lista actual del disco
  local current_images
  current_images=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort)

  # 2. Si todo está vacío (primera vez o ciclo terminado), llenar todo
  if [[ ! -s "$TODO_FILE" && ! -s "$DONE_FILE" ]]; then
    echo "$current_images" | shuf >"$TODO_FILE"
    return
  fi

  # 3. Identificar imágenes nuevas (que no están ni en TODO ni en DONE)
  # Usamos grep para filtrar lo que ya conocemos
  echo "$current_images" | while read -r line; do
    if ! grep -qx "$line" "$TODO_FILE" && ! grep -qx "$line" "$DONE_FILE"; then
      echo "$line" >>"$TODO_FILE"
    fi
  done

  # 4. Si el TODO se vació pero hay historial en DONE, reiniciar ciclo
  if [[ ! -s "$TODO_FILE" ]]; then
    cat "$DONE_FILE" | shuf >"$TODO_FILE"
    >"$DONE_FILE"
  fi
}

# Ejecución
if [[ -n "$1" ]]; then
  # Modo manual (mantiene tu lógica)
  img=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
  [[ -n "$img" ]] && apply_changes "$img"
else
  while true; do
    sync_images

    # Leer la siguiente imagen del TODO
    img=$(head -n 1 "$TODO_FILE")

    # Mover de TODO a DONE de forma atómica
    sed -i '1d' "$TODO_FILE"

    if [[ -f "$img" ]]; then
      echo "$img" >>"$DONE_FILE"
      apply_changes "$img"
      sleep 1800
    else
      # Si el archivo ya no existe, simplemente seguimos sin añadirlo a DONE
      continue
    fi
  done
fi
