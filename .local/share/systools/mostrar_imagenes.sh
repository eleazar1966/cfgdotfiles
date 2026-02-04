#!/bin/bash
# Script: mostrar_imagenes.sh
# Versión: 39.1 (Estandarizado)

# --- Configuración ---
DIRECTORIO="$HOME/.config/wallpaper"
WAYBAR_RELOAD_SCRIPT="$HOME/.local/share/systools/reload-waybar-simple.sh"
ESTADO_ARCHIVO="$HOME/.cache/wallpaper_state"
LOG_FILE="$HOME/.cache/wallpaper_manager.log"
MAX_LOG_SIZE=1048576 # 1MB en bytes
PAUSA_SEGUNDOS=600
PAUSA_REINTENTO=5

# --- Funciones ---

log_msg() {
  # Rotación de logs: si supera 1MB, se reinicia
  if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
    echo "--- Rotación de Log: $(date) ---" >"$LOG_FILE"
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

next_wallpaper() {
  log_msg "⏭️ SIGUSR1: Saltando imagen manualmente."
  pkill -P $$ -x sleep
}
trap next_wallpaper SIGUSR1

function encontrar_imagenes() {
  log_msg "🔍 Escaneando directorio..."
  IMAGENES=()
  while IFS= read -r archivo; do
    IMAGENES+=("$archivo")
  done < <(find "$DIRECTORIO" -type f -regextype posix-extended -iregex '.*\.(jpg|jpeg|png|gif|bmp|webp)$')
}

function cargar_estado() {
  if [ -f "$ESTADO_ARCHIVO" ]; then
    ULTIMO_INDICE=$(head -n 1 "$ESTADO_ARCHIVO")
    mapfile -t LISTA_GUARDADA < <(tail -n +2 "$ESTADO_ARCHIVO")

    if [[ "$ULTIMO_INDICE" =~ ^[0-9]+$ ]] && [ "$ULTIMO_INDICE" -lt ${#LISTA_GUARDADA[@]} ]; then
      log_msg "✅ Estado cargado (Índice: $ULTIMO_INDICE)."
      IMAGENES=("${LISTA_GUARDADA[@]}")
      return 0
    fi
  fi
  return 1
}

function guardar_estado() {
  echo "$1" >"$ESTADO_ARCHIVO"
  printf "%s\n" "${IMAGENES[@]}" >>"$ESTADO_ARCHIVO"
}

# --- Ejecución ---

if [ ! -d "$DIRECTORIO" ]; then
  log_msg "❌ ERROR: No existe $DIRECTORIO"
  exit 1
fi

# Asegurar que swww-daemon esté activo
pgrep -x "swww-daemon" >/dev/null || {
  swww-daemon &
  log_msg "🚀 Daemon iniciado."
}

INDICE_ACTUAL=0
if ! cargar_estado; then
  encontrar_imagenes
  [ ${#IMAGENES[@]} -gt 0 ] && mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
fi

while true; do
  # Lógica de regeneración de lista
  if [ "$INDICE_ACTUAL" -ge ${#IMAGENES[@]} ] || [ ${#IMAGENES[@]} -eq 0 ]; then
    log_msg "🔄 Ciclo completado. Barajando de nuevo..."
    ULTIMA="${IMAGENES[-1]}"
    encontrar_imagenes
    if [ ${#IMAGENES[@]} -gt 1 ]; then
      mapfile -t LISTA_BARAJADA < <(printf "%s\n" "${IMAGENES[@]}" | grep -v -F -x "$ULTIMA" | shuf)
      IMAGENES=("$ULTIMA" "${LISTA_BARAJADA[@]}")
      INDICE_ACTUAL=1
    else
      INDICE_ACTUAL=0
    fi
  fi

  IMAGEN_ACTUAL="${IMAGENES[$INDICE_ACTUAL]}"
  log_msg "🖼️  $((INDICE_ACTUAL + 1))/${#IMAGENES[@]} | $(basename "$IMAGEN_ACTUAL")"

  # Cambio secuencial: swww -> matugen -> waybar
  swww img "$IMAGEN_ACTUAL" --transition-type random --transition-step 90

  if ! matugen image "$IMAGEN_ACTUAL" >/dev/null 2>&1; then
    log_msg "⚠️ Matugen falló en la imagen actual."
  fi

  if [ -f "$WAYBAR_RELOAD_SCRIPT" ]; then
    bash "$WAYBAR_RELOAD_SCRIPT" &
  fi

  INDICE_ACTUAL=$((INDICE_ACTUAL + 1))
  guardar_estado "$INDICE_ACTUAL"

  log_msg "💤 Dormir por $PAUSA_SEGUNDOS s."
  sleep "$PAUSA_SEGUNDOS" &
  wait $!
done
