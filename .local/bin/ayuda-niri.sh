#!/bin/bash

# Lista de atajos en español
OPCIONES="Super + Q : Cerrar ventana
Super + Enter : Abrir Terminal (Kitty)
Super + D : Lanzador de aplicaciones (Fuzzel)
Super + E : Gestor de archivos (Thunar)
Super + T : Telegram Desktop
Super + M : Reproductor de Música (MOCP)
Super + Y : YouTube (yt-x flotante)
Super + H / L : Enfocar Columna Izquierda / Derecha
Super + J / K : Enfocar Ventana Abajo / Arriba
Super + Shift + H / L : Mover Columna Izquierda / Derecha
Super + Shift + J / K : Mover Ventana Abajo / Arriba
Super + V : Alternar Ventana Flotante / Mosaico
Super + O : Vista General (Overview)
Super + R : Cambiar Ancho de Columna (Presets)
Super + F : Maximizar Columna
Super + Shift + F : Pantalla Completa
Super + Page Down / Up : Cambiar Espacio de Trabajo
PrtSc : Captura de pantalla interactiva
Super + G : Iniciar/Detener Grabación de Video
Super + Shift + W : Cambiar Fondo de Pantalla
Super + Shift + E : Salir de Niri"

# Mostrar en fuzzel y obtener la selección (solo informativo)
echo -e "$OPCIONES" | fuzzel --dmenu --prompt=" Atajos de Niri: " --lines=22 --width=50
