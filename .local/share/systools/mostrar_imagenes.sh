#!/bin/bash
# Script con persistencia para reanudar el ciclo de fondos de pantalla,
# modificado para evitar la repetición inmediata de la última imagen mostrada.

# --- Configuración ---
DIRECTORIO="$HOME/.config/wallpaper"
WAYBAR_RELOAD_SCRIPT="$HOME/.local/share/systools/reload-waybar-simple.sh"
ESTADO_ARCHIVO="$HOME/.cache/wallpaper_state" # Archivo para guardar la lista e índice
PAUSA_SEGUNDOS=600                            # Pausa entre cada cambio de imagen (10 minutos)
PAUSA_REINTENTO=5                             # Pausa antes de reintentar si no se encuentran imágenes

# --- Funciones ---

# Función para encontrar y llenar el arreglo de imágenes.
function encontrar_imagenes() {
  echo "🔍 Buscando nuevas imágenes en $DIRECTORIO..."
  IMAGENES=()
  # Busca archivos de imagen y los guarda.
  while IFS= read -r archivo; do
    IMAGENES+=("$archivo")
  done < <(find "$DIRECTORIO" -type f -regextype posix-extended -iregex '.*\.(jpg|jpeg|png|gif|bmp|webp)$')
}

# Función para cargar el estado guardado.
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
    # Se usa <= para permitir que el índice cargado sea igual al tamaño (fin de ciclo).
    if [ "$ULTIMO_INDICE" -ge 0 ] && [ "$ULTIMO_INDICE" -le ${#LISTA_GUARDADA[@]} ] && [ ${#LISTA_GUARDADA[@]} -gt 0 ]; then
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
ULTIMA_IMAGEN_MOSTRADA=""
if cargar_estado; then
  # Si se cargó el estado, ajusta el índice.
  INDICE_ACTUAL=$ULTIMO_INDICE
else
  # Si no se pudo cargar el estado, se busca la lista completa de imágenes y se baraja.
  encontrar_imagenes
  if [ ${#IMAGENES[@]} -gt 0 ]; then
    # Barajar la lista por primera vez
    mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
  fi
fi

# 3. Bucle Principal
while true; do

  # --- A. Lógica de Fin de Lista / Regeneración ---
  if [ "$INDICE_ACTUAL" -ge ${#IMAGENES[@]} ] || [ ${#IMAGENES[@]} -eq 0 ]; then
    echo "--- Fin de la lista actual o lista vacía. Generando una nueva lista aleatoria. ---"

    # 1. Guarda la última imagen mostrada del ciclo anterior.
    ULTIMA_IMAGEN_MOSTRADA=""
    if [ ${#IMAGENES[@]} -gt 0 ]; then
      # La última imagen mostrada fue la que estaba en el índice ${#IMAGENES[@]}-1.
      ULTIMA_IMAGEN_MOSTRADA="${IMAGENES[${#IMAGENES[@]}-1]}"
    fi
    
    # 2. Genera la lista completa de TODAS las imágenes (refresca).
    encontrar_imagenes

    if [ ${#IMAGENES[@]} -gt 0 ]; then
      
      # 3. FILTRADO Y BARAJADO
      if [ -n "$ULTIMA_IMAGEN_MOSTRADA" ]; then
        # Filtra la última imagen mostrada, baraja el resto.
        mapfile -t LISTA_BARAJADA < <(printf "%s\n" "${IMAGENES[@]}" | grep -v -F -x "$ULTIMA_IMAGEN_MOSTRADA" | shuf)
        
        # 4. Construir la nueva lista final: (Ultima Imagen) + (Resto Barajado).
        # Esto asegura que la última imagen que se mostró NO será la siguiente en mostrarse.
        # Sintaxis de arreglo corregida:
        IMAGENES=("$ULTIMA_IMAGEN_MOSTRADA" "${LISTA_BARAJADA[@]}")
        
      else
        # Si no había imagen anterior (es el primer inicio), simplemente baraja toda la lista.
        mapfile -t IMAGENES < <(printf "%s\n" "${IMAGENES[@]}" | shuf)
      fi
      
      # 5. Reiniciar y Guardar Estado
      INDICE_ACTUAL=0
      guardar_estado "$INDICE_ACTUAL"

    else
      echo "⚠️ Advertencia: No se encontraron imágenes en '$DIRECTORIO'. Reintentando en $PAUSA_REINTENTO segundos."
      sleep $PAUSA_REINTENTO
      continue # Vuelve al inicio del bucle while true
    fi
  fi # <--- CIERRA: Lógica de Fin de Lista

  # --- B. Lógica de Cambio de Imagen ---
  
  # 6. Muestra la imagen actual.
  IMAGEN_ACTUAL="${IMAGENES[$INDICE_ACTUAL]}"
  echo "🖼️ Mostrando imagen $((INDICE_ACTUAL + 1)) de ${#IMAGENES[@]}: $IMAGEN_ACTUAL"
  
  # Comando para establecer el fondo de pantalla (CAMBIAR SI USAS OTRO)
  # El & es importante para que el script no se quede esperando a que el fondo termine de ejecutarse.
  #swaybg -i "$IMAGEN_ACTUAL" -m fill &
  matugen image "$IMAGEN_ACTUAL" & >/dev/null
  # Opcional: Recargar Waybar
  if [ -f "$WAYBAR_RELOAD_SCRIPT" ]; then
    "$WAYBAR_RELOAD_SCRIPT" &
  fi
  
  # 7. Prepara el estado para la próxima iteración.
  INDICE_ACTUAL=$((INDICE_ACTUAL + 1))
  guardar_estado "$INDICE_ACTUAL"
  
  # 8. Pausa y espera al siguiente ciclo.
  echo "💤 Esperando $PAUSA_SEGUNDOS segundos..."
  sleep "$PAUSA_SEGUNDOS"

done # <--- CIERRA: Bucle Principal (while true)
