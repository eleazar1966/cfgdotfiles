#!/bin/bash
# 1. Eliminar la variable que causa el conflicto de GPU en tu Zen 3
unset DRI_PRIME

# 2. Limpiar sockets huérfanos de reinicios fallidos
# Esto evitará que Niri salte a wayland-1 o wayland-2
rm -f /run/user/1000/wayland-*
rm -f /run/user/1000/x11-*

# 3. Forzar el backend DRM para evitar que Niri use 'winit' (el modo ventana)
export NIRI_BACKEND=drm

# 4. (Opcional) Un pequeño retraso para asegurar que el driver amdgpu cargó
sleep 1

exec niri >~/niri.log 2>&1
