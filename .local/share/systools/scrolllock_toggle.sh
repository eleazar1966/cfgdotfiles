#!/bin/bash

# Ruta al script de bucle infinito (Paso 1.1)
SCROLL_SCRIPT="$HOME/.local/share/systools/scrolllock_inotify.py" # <--- ¡ACTUALIZA ESTA RUTA!
# Ruta al script de Python
# Ubicación del archivo PID
PID_FILE="/tmp/scrolllock_toggle.pid"

# Comprueba si el archivo PID existe (proceso activo)
if [ -f "$PID_FILE" ]; then
  # El proceso está activo: Detenerlo

  PID=$(cat "$PID_FILE")

  # Matar el proceso
  kill "$PID" 2>/dev/null

  # Borrar el archivo PID
  rm "$PID_FILE"

  echo "Scroll Lock Forzado APAGADO."
else
  # El proceso NO está activo: Iniciarlo

  # Ejecutar el script de Python en segundo plano con nohup
  nohup python3 "$SCROLL_SCRIPT" &

  echo "Scroll Lock Forzado ENCENDIDO."
fi
