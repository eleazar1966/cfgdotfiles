#!/bin/bash

# --- CONFIGURACIÓN ---
DESTINO="$HOME/Videos"
MINIMO_GB=1
mkdir -p "$DESTINO"

# Función para notificar de forma segura en Gentoo/OpenRC
enviar_aviso() {
    # Solo intenta enviar si notify-send existe y no falla el bus
    if command -v notify-send >/dev/null; then
        notify-send -a "Grabador" "$1" "$2" >/dev/null 2>&1 || echo ">> $1: $2"
    else
        echo ">> $1: $2"
    fi
}

# 1. Comprobar espacio disponible
ESPACIO_DISP=$(df -BG "$DESTINO" | tail -n1 | awk '{print $4}' | tr -d 'G')

if [ "$ESPACIO_DISP" -lt "$MINIMO_GB" ]; then
    enviar_aviso "Error" "Espacio insuficiente ($ESPACIO_DISP GB)"
    exit 1
fi

# 2. Evitar doble ejecución
if pgrep -x "gpu-screen-recorder" > /dev/null; then
    enviar_aviso "Error" "Ya hay una grabación activa"
    exit 1
fi

# 3. Menú interactivo
clear
echo "      [ GRABADOR GPU - GENTOO/NIRI ]"
echo "------------------------------------"
echo "1) Pantalla Completa"
echo "2) Seleccionar Ventana"
echo "3) Salir"
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
for i in {5..1}; do
    echo -ne "Iniciando en: $i... \r"
    sleep 1
done

echo -e "\n¡GRABANDO!"
enviar_aviso "Grabadora" "Iniciando: $NOMBRE_FINAL"

# 5. Ejecución (Redirigimos errores de stderr a un log o a /dev/null para no ensuciar Kitty)
gpu-screen-recorder -w "$TARGET" -k h264 -f 60 -a "default_output" -a "default_input" -o "$DESTINO/$NOMBRE_FINAL" 2>/dev/null

# 6. Finalización y Resumen
if [ -f "$DESTINO/$NOMBRE_FINAL" ]; then
    PESO=$(du -h "$DESTINO/$NOMBRE_FINAL" | cut -f1)
    echo -e "\n------------------------------"
    echo "LISTO: $NOMBRE_FINAL"
    echo "TAMAÑO: $PESO"
    echo "------------------------------"

    enviar_aviso "Grabación Guardada" "Tamaño: $PESO"
    
    # Abrir el gestor de archivos de forma independiente
    # Usamos nohup para que no se cierre al morir la terminal
    if command -v thunar >/dev/null; then
        nohup thunar "$DESTINO" >/dev/null 2>&1 &
    elif command -v pcmanfm >/dev/null; then
        nohup pcmanfm "$DESTINO" >/dev/null 2>&1 &
    else
        nohup xdg-open "$DESTINO" >/dev/null 2>&1 &
    fi
    
    # Este comando es vital para "soltar" el proceso en bash
    disown -a
fi

sleep 2
