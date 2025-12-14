#!/bin/bash
# Script con persistencia para reanudar el ciclo de fondos de pantalla.

# --- Configuración ---
DIRECTORIO="$HOME/.config/wallpaper"
WAYBAR_RELOAD_SCRIPT="$HOME/.local/share/systools/launch-waybar.sh"
ESTADO_ARCHIVO="$HOME/.cache/wallpaper_state" # Archivo para guardar la lista e índice
PAUSA_SEGUNDOS=600                            # Pausa entre cada cambio de imagen (10 minutos)
PAUSA_REINTENTO=5                             # Pausa antes de reintentar si no se encuentran imágenes

# --- Funciones ---

# Función para encontrar y llenar el arreglo de imágenes.
function encontrar_imagenes() {
  echo "🔍 Buscando nuevas imágenes..."
  IMAGENES=()
  # Busca archivos de imagen y los guarda.
  while IFS= read -r archivo; do
    IMAGENES+=("$archivo")
  done < <(find "$DIRECTORIO" -type f -regextype posix-extended -iregex '.*\.(jpg|jpeg|png|gif|bmp|webp)$')
}

# Función para cargar el estado guardado.
# Lee el estado del archivo y verifica si la lista de imágenes guardada sigue siendo válida.
function cargar_estado() {
  if [ -f "$ESTADO_ARCHIVO" ]; then
    echo "📄 Intentando cargar el estado previo..."
    # Lee el índice y la lista guardada.
    ULTIMO_INDICE=$(head -n 1 "$ESTADO_ARCHIVO")
    LISTA_GUARDADA=()
    while IFS= read -r linea; do
      LISTA_GUARDADA+=("$linea")
    done < <(tail -n +2 "$ESTADO_ARCHIVO")

    # Verificación de validez: ¿El índice es válido y la lista tiene elementos?
    if [ "$ULTIMO_INDICE" -ge 0 ] && [ "$ULTIMO_INDICE" -lt ${#LISTA_GUARDADA[@]} ]; then
      echo "✅ Estado previo cargado con éxito. Reanudando desde el índice $ULTIMO_INDICE."
      IMAGENES=("${LISTA_GUARDADA[@]}")
      return 0 # Éxito en la carga
    fi
    echo "❌ Estado guardado inválido o incompleto. Se generará una nueva lista."
    rm -f "$ESTADO_ARCHIVO" # Borra el archivo inválido
  fi
  return 1 # Fallo en la carga
}

# Función para guardar el estado actual.
function guardar_estado() {
  # El primer elemento del archivo es el índice de la *próxima* imagen.
  echo "$1" >"$ESTADO_ARCHIVO"
  # El resto del archivo es la lista aleatoria actual, una imagen por línea.
  printf "%s\n" "${IMAGENES[@]}" >>"$ESTADO_ARCHIVO"
  echo "💾 Estado guardado. Próxima imagen en el índice $1."
}

# --- Ejecución ---

# 1. Verificación Inicial del Directorio
if [ ! -d "$DIRECTORIO" ]; then
  echo "Error: El directorio '$DIRECTORIO' no existe."
  exit 1
fi

# 2. Intentar cargar el estado. Si falla, inicializar variables.
INDICE_ACTUAL=0
if ! cargar_estado; then
  # Si no se pudo cargar el estado, se busca la lista completa de imágenes.
  encontrar_imagenes
  # Si se encontraron imágenes, se baraja la lista inicial.
  if [ ${#IMAGENES[@]} -gt 0 ]; then
    mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
  fi
fi

# 3. Bucle Principal
while true; do

  # A. Verificación de imágenes (si está vacío, intenta buscar de nuevo)
  if [ ${#IMAGENES[@]} -eq 0 ]; then
    encontrar_imagenes
    if [ ${#IMAGENES[@]} -eq 0 ]; then
      echo "No se encontraron archivos de imagen en '$DIRECTORIO'. Reintentando en $PAUSA_REINTENTO segundos."
      sleep $PAUSA_REINTENTO
      continue
    fi
    # Si encuentra imágenes después del reintento, las baraja y reinicia el índice.
    mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
    INDICE_ACTUAL=0
  fi

  # B. Iteración sobre las imágenes restantes (desde el INDICE_ACTUAL)
  # Se usa un bucle 'for' tradicional para controlar el índice fácilmente.
  for ((i = $INDICE_ACTUAL; i < ${#IMAGENES[@]}; i++)); do
    imagen_aleatoria="${IMAGENES[i]}"

    echo "🎨 Aplicando fondo [${i}/${#IMAGENES[@]}-1]: $imagen_aleatoria"

    # 1. Aplica la imagen y extrae la paleta de colores.
    matugen image "$imagen_aleatoria" &>/dev/null

    # 2. Llama al script para recargar Waybar.
    if [ -x "$WAYBAR_RELOAD_SCRIPT" ]; then
      "$WAYBAR_RELOAD_SCRIPT" &
    fi

    # 3. Actualiza el índice para la próxima imagen (i+1) y guarda el estado.
    guardar_estado $((i + 1))

    # 4. Pausa antes del próximo cambio.
    echo "💤 Esperando $PAUSA_SEGUNDOS segundos..."
    sleep $PAUSA_SEGUNDOS
  done

  # C. Fin de la lista: Reiniciar el ciclo.
  echo "--- Fin de la lista actual. Generando una nueva lista aleatoria. ---"

  # Genera una nueva lista, la baraja y reinicia el índice.
  encontrar_imagenes # Rebusca en caso de que se hayan añadido/eliminado archivos
  if [ ${#IMAGENES[@]} -gt 0 ]; then
    mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
  else
    # Si la búsqueda no encontró nada, vacía el estado y se reintenta en el bucle principal.
    rm -f "$ESTADO_ARCHIVO"
  fi

  INDICE_ACTUAL=0  # Reinicia el índice para el nuevo bucle
  guardar_estado 0 # Guarda el estado de la nueva lista
done
