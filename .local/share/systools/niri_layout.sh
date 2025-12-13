#!/bin/bash

# Este comando pide a Niri los layouts de teclado. 
# La salida se ve algo así:
# Keyboard layouts:
# 0 English (US)
# 1 Spanish *

# Usamos 'grep' para encontrar la línea con el layout activo (marcada con '*')
# Usamos 'awk' para imprimir el último campo (que es el nombre corto: ES, US, etc.)
# Si usas nombres largos como "Spanish", el script puede variar. 
# Para este ejemplo, asumiremos que solo quieres mostrar las dos primeras letras (ES, US, etc.).

niri msg keyboard-layouts | \
grep '*' | \
awk '{print $NF}' | \
cut -c 1-2
