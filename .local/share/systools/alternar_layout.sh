#!/bin/bash

# Obtener el layout de teclado actual usando hyprctl
# Usamos 'jq' para parsear la salida JSON de hyprctl
CURRENT_LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)

# Detectar el teclado principal (el nombre puede variar)
KEYBOARD_NAME=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name')

# Definir los layouts
LAYOUT_1="English (US)"
LAYOUT_2="Spanish"

if [ "$CURRENT_LAYOUT" == "$LAYOUT_1" ]; then
  # Si el layout actual es el primero, cambiar al segundo
  #hyprctl switchxkblayout "$KEYBOARD_NAME" "$LAYOUT_2"
  #hyprctl notify -1 1500 1 "Layout cambiado a $LAYOUT_2"
  hyprctl keyword input:kb_layout es
  echo $LAYOUT_2
else
  # En cualquier otro caso, cambiar al primero
  #hyprctl switchxkblayout "$KEYBOARD_NAME" "$LAYOUT_1"
  #hyprctl notify -1 1500 1 "Layout cambiado a $LAYOUT_1"
  hyprctl keyword input:kb_layout us
  echo $LAYOUT_1
fi
