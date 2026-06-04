#!/bin/bash
# ==============================================================================
# Grabador de Pantalla Interactivo para Gentoo (Niri / Wayland)
# ==============================================================================

# 1. Configuración de rutas
TARGET_DIR="$HOME/Vídeos/Capturas_de_vídeo"
LOG_FILE="$TARGET_DIR/error_grabacion.log"

mkdir -p "$TARGET_DIR"
rm -f "$LOG_FILE"

clear
echo "======================================================"
echo " 🎥 Grabador de Pantalla Pro (Controles en Vivo) "
echo "======================================================"
echo ""

# 2. Nombre del archivo
read -p "📝 Introduce el nombre del vídeo (o ENTER para usar fecha/hora): " VIDEO_NAME
if [ -z "$VIDEO_NAME" ]; then
  VIDEO_NAME="grabacion_$(date +%Y%m%d_%H%M%S)"
fi

OUTPUT_FILE="$TARGET_DIR/${VIDEO_NAME}.mp4"

echo ""
echo "🚀 Lanzando capturador..."
echo "⏳ Esperando confirmación del Portal Wayland..."

# 3. Ejecución en segundo plano
gpu-screen-recorder -w portal -a "default_output" -o "$OUTPUT_FILE" >/dev/null 2>"$LOG_FILE" &
GSR_PID=$!

# Esperar para verificar que no muera al arrancar
sleep 1.5

if ! kill -0 $GSR_PID 2>/dev/null; then
  echo "❌ ERROR: El grabador no pudo iniciar."
  echo "--------------------------------------------------------"
  cat "$LOG_FILE"
  echo "--------------------------------------------------------"
  exit 1
fi

# 4. Panel de Control Interactivo (Bucle de Escucha)
PAUSED=false

echo "🟢 ¡Grabación en progreso!"
echo "📌 Guardando en: $OUTPUT_FILE"
echo ""
echo "======================================================"
echo " 🎮 CONTROLES EN VIVO (Presiona la tecla en esta terminal):"
echo "  [p] Pausar / Reanudar grabación"
echo "  [s] Finalizar y GUARDAR vídeo de forma segura"
echo "======================================================"
echo ""

# Desactivar el eco de la terminal temporalmente para una experiencia limpia
stty -echo

while kill -0 $GSR_PID 2>/dev/null; do
  # Lee un carácter con un timeout de 1 segundo para no congelar el bucle
  if read -r -n 1 -t 1 key; then
    case "$key" in
      [pP])
        if [ "$PAUSED" = false ]; then
          kill -STOP $GSR_PID
          PAUSED=true
          echo -e "\r⏸️  Grabación PAUSADA. Presiona [p] para reanudar..."
        else
          kill -CONT $GSR_PID
          PAUSED=false
          echo -e "\r▶️  Grabación REANUDADA. Continúa capturando...          "
        fi
        ;;
      [sS])
        echo -e "\n\r🛑 Finalizando grabación..."
        # SIGINT (Señal 2) le dice a gpu-screen-recorder que cierre el archivo MP4 correctamente
        kill -SIGINT $GSR_PID
        break
        ;;
    esac
  fi
done

# Restaurar el eco de la terminal
stty echo

# 5. Cierre seguro
echo "⏳ Escribiendo metadatos finales en el archivo..."
wait $GSR_PID 2>/dev/null

echo "🏁 ¡Vídeo finalizado con éxito y guardado sin corrupción!"
