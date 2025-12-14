#!/bin/bash
# Script de recarga SIMPLE (sin vigilancia)

# 1. Matar Waybar si está corriendo
if pgrep -x "waybar" >/dev/null; then
  echo "🔄 Recargando Waybar..."
  killall waybar
  sleep 0.5
fi

# 2. Inicia Waybar en segundo plano.
if ! pgrep -x "waybar" >/dev/null; then
  echo "🚀 Iniciando Waybar..."
  waybar &
fi
EOF
