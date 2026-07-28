#!/bin/bash
# ==============================================================================
# Grabador de Pantalla Interactivo para Gentoo (Niri / Wayland)
# Versión mejorada: stty siempre se restaura, trap cubre todas las salidas
# ==============================================================================

set -euo pipefail

# 1. Configuración de rutas
TARGET_DIR="$HOME/Vídeos/Capturas_de_vídeo"
LOG_FILE="$TARGET_DIR/error_grabacion.log"

mkdir -p "$TARGET_DIR"
rm -f "$LOG_FILE"

# 2. Trap para restaurar stty en TODAS las salidas (SIGINT, SIGTERM, EXIT, ERR)
# IMPORTANTE: stty debe restaurarse siempre, incluso si el script muere anormalmente
trap_cleanup() {
  stty echo 2>/dev/null || true
}
trap trap_cleanup EXIT INT TERM

clear
echo "======================================================"
echo " 🎥 Grabador de Pantalla Pro (Controles en Vivo) "
echo "======================================================"
echo ""

# 3. Nombre del archivo
read -p "📝 Introduce el nombre del vídeo (o ENTER para usar fecha/hora): " VIDEO_NAME
if [ -z "$VIDEO_NAME" ]; then
  VIDEO_NAME="grabacion_$(date +%Y%m%d_%H%M%S)"
fi

OUTPUT_FILE="$TARGET_DIR/${VIDEO_NAME}.mp4"

echo ""
echo "🚀 Lanzando capturador..."
echo "⏳ Esperando confirmación del Portal Wayland..."

# 4. Ejecución en segundo plano
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

# 5. Panel de Control Interactivo
PAUSED=false

echo "🟢 ¡Grabación en progreso!"
echo "📌 Guardando en: $OUTPUT_FILE"
echo ""
echo "======================================================"
echo " 🎮 CONTROLES EN VIVO:"
echo "  [p] Pausar / Reanudar grabación"
echo "  [s] Finalizar y GUARDAR vídeo"
echo "======================================================"
echo ""

# stty -echo dentro del trap_cleanup garantiza restauración
stty -echo

while kill -0 $GSR_PID 2>/dev/null; do
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
          echo -e "\r▶️  Grabación REANUDADA.                          "
        fi
        ;;
      [sS])
        echo -e "\n\r🛑 Finalizando grabación..."
        kill -SIGINT $GSR_PID
        break
        ;;
    esac
  fi
done

# stty se restaura automáticamente vía trap_cleanup en EXIT

# 6. Cierre seguro
echo "⏳ Escribiendo metadatos finales..."
wait $GSR_PID 2>/dev/null

echo ""
echo "🏁 ¡Vídeo finalizado con éxito!"
echo "   📁 $OUTPUT_FILE"
