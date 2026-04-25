#!/bin/bash

# --- CONFIGURACIÓN ---
DESTINO="$HOME/Vídeos/Capturas_de_vídeo"
MINIMO_GB=1
mkdir -p "$DESTINO"

enviar_aviso() {
  if command -v notify-send >/dev/null; then
    notify-send -a "Grabador" "$1" "$2" >/dev/null 2>&1 || echo ">> $1: $2"
  else
    echo ">> $1: $2"
  fi
}

# 1. Comprobar espacio
ESPACIO_DISP=$(df -BG "$DESTINO" | tail -n1 | awk '{print $4}' | tr -d 'G')
if [ "$ESPACIO_DISP" -lt "$MINIMO_GB" ]; then
  enviar_aviso "Error" "Espacio insuficiente ($ESPACIO_DISP GB)"
  exit 1
fi

# 2. Evitar doble ejecución
if pgrep -x "gpu-screen-recorder" >/dev/null; then
  enviar_aviso "Error" "Ya hay una grabación activa"
  exit 1
fi

# 3. Menú interactivo
clear
echo "      [ GRABADOR RADEON (5700G) ]"
echo "------------------------------------"
echo "MODO:"
echo "1) Pantalla Completa"
echo "2) Ventana"
read -p "Opción: " MODO

case $MODO in
  1) TARGET="portal" ;;
  2) TARGET="window" ;;
  *) exit 0 ;;
esac

echo -e "\nNombre del video (ENTER para fecha):"
read -r NOMBRE_EXTRA
FECHA=$(date +"%Y-%m-%d_%H-%M")
[ -z "$NOMBRE_EXTRA" ] && NOMBRE_FINAL="${FECHA}.mp4" || NOMBRE_FINAL="${NOMBRE_EXTRA// /_}_${FECHA}.mp4"

# 4. Cuenta atrás
for i in {3..1}; do
  echo -ne "Iniciando en: $i... \r"
  sleep 1
done

echo -e "\n¡GRABANDO!"
enviar_aviso "Grabadora" "Iniciando: $NOMBRE_FINAL"

# 5. Ejecución
gpu-screen-recorder -w "$TARGET" -k h264 -f 60 -a "default_output" -o "$DESTINO/$NOMBRE_FINAL" 2>/dev/null

# 6. Finalización y Apertura de Carpeta
if [ -f "$DESTINO/$NOMBRE_FINAL" ]; then
  PESO=$(du -h "$DESTINO/$NOMBRE_FINAL" | cut -f1)
  echo -e "\n------------------------------"
  echo "LISTO: $NOMBRE_FINAL"
  echo "TAMAÑO: $PESO"
  echo "------------------------------"
  enviar_aviso "Grabación Guardada" "Tamaño: $PESO"

  # Lógica de apertura con el orden solicitado
  if command -v thunar >/dev/null; then
    nohup thunar "$DESTINO" >/dev/null 2>&1 &
  elif command -v pcmanfm >/dev/null; then
    nohup pcmanfm "$DESTINO" >/dev/null 2>&1 &
  elif command -v kitty >/dev/null && command -v ranger >/dev/null; then
    nohup kitty -e ranger "$DESTINO" >/dev/null 2>&1 &
  else
    nohup xdg-open "$DESTINO" >/dev/null 2>&1 &
  fi
  disown -a
fi

sleep 2
