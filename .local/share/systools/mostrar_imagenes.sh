#!/bin/bash
# Script con persistencia, swww para Niri y soporte para salto manual.

# --- Configuración ---
DIRECTORIO="$HOME/.config/wallpaper"
WAYBAR_RELOAD_SCRIPT="$HOME/.local/share/systools/reload-waybar-simple.sh"
ESTADO_ARCHIVO="$HOME/.cache/wallpaper_state"
PAUSA_SEGUNDOS=600
PAUSA_REINTENTO=5

# --- Funciones ---

# Trampa para saltar el sleep cuando se recibe SIGUSR1
next_wallpaper() {
  echo "⏭️ Salto manual detectado..."
}
trap next_wallpaper SIGUSR1

function encontrar_imagenes() {
  echo "🔍 Buscando nuevas imágenes en $DIRECTORIO..."
  IMAGENES=()
  while IFS= read -r archivo; do
    IMAGENES+=("$archivo")
  done < <(find "$DIRECTORIO" -type f -regextype posix-extended -iregex '.*\.(jpg|jpeg|png|gif|bmp|webp)$')
}

function cargar_estado() {
  if [ -f "$ESTADO_ARCHIVO" ]; then
    echo "📄 Intentando cargar el estado previo..."
    ULTIMO_INDICE=$(head -n 1 "$ESTADO_ARCHIVO")
    LISTA_GUARDADA=()
    while IFS= read -r linea; do
      LISTA_GUARDADA+=("$linea")
    done < <(tail -n +2 "$ESTADO_ARCHIVO")

    if [ "$ULTIMO_INDICE" -ge 0 ] && [ "$ULTIMO_INDICE" -le ${#LISTA_GUARDADA[@]} ] && [ ${#LISTA_GUARDADA[@]} -gt 0 ]; then
      echo "✅ Estado previo cargado con éxito. Reanudando desde el índice $ULTIMO_INDICE."
      IMAGENES=("${LISTA_GUARDADA[@]}")
      return 0
    fi
    rm -f "$ESTADO_ARCHIVO"
  fi
  return 1
}

function guardar_estado() {
  echo "$1" >"$ESTADO_ARCHIVO"
  printf "%s\n" "${IMAGENES[@]}" >>"$ESTADO_ARCHIVO"
}

# --- Ejecución ---

if [ ! -d "$DIRECTORIO" ]; then
  echo "Error: El directorio '$DIRECTORIO' no existe."
  exit 1
fi

if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon &
  sleep 1
fi
swww clear >/dev/null 2>&1

INDICE_ACTUAL=0
if cargar_estado; then
  INDICE_ACTUAL=$ULTIMO_INDICE
else
  encontrar_imagenes
  if [ ${#IMAGENES[@]} -gt 0 ]; then
    mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
  fi
fi

while true; do
  if [ "$INDICE_ACTUAL" -ge ${#IMAGENES[@]} ] || [ ${#IMAGENES[@]} -eq 0 ]; then
    echo "--- Fin de la lista actual. Regenerando... ---"
    ULTIMA_IMAGEN_MOSTRADA="${IMAGENES[${#IMAGENES[@]} - 1]}"
    encontrar_imagenes
    if [ ${#IMAGENES[@]} -gt 0 ]; then
      if [ -n "$ULTIMA_IMAGEN_MOSTRADA" ]; then
        mapfile -t LISTA_BARAJADA < <(printf "%s\n" "${IMAGENES[@]}" | grep -v -F -x "$ULTIMA_IMAGEN_MOSTRADA" | shuf)
        IMAGENES=("$ULTIMA_IMAGEN_MOSTRADA" "${LISTA_BARAJADA[@]}")
      else
        mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
      fi
      INDICE_ACTUAL=0
      guardar_estado "$INDICE_ACTUAL"
    else
      sleep $PAUSA_REINTENTO
      continue
    fi
  fi

  IMAGEN_ACTUAL="${IMAGENES[$INDICE_ACTUAL]}"
  echo "🖼️ Mostrando $((INDICE_ACTUAL + 1))/${#IMAGENES[@]}: $(basename "$IMAGEN_ACTUAL")"

  swww img "$IMAGEN_ACTUAL" --transition-type random --transition-step 90 >/dev/null 2>&1 &
  matugen image "$IMAGEN_ACTUAL" >/dev/null 2>&1 &

  if [ -f "$WAYBAR_RELOAD_SCRIPT" ]; then
    (sleep 1 && "$WAYBAR_RELOAD_SCRIPT") &
  fi

  INDICE_ACTUAL=$((INDICE_ACTUAL + 1))
  guardar_estado "$INDICE_ACTUAL"

  echo "💤 Esperando $PAUSA_SEGUNDOS segundos..."
  # El sleep debe ser interrumpible
  sleep "$PAUSA_SEGUNDOS" &
  wait $!
done
