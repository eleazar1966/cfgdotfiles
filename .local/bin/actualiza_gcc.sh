#!/bin/bash
set -e # Detiene el script si ocurre un error

echo -e "\n  Iniciando actualización GCC ..."

# 1. Actualización de herramientas base y headers
sudo emerge -v1 sys-kernel/linux-headers
sudo emerge -v1 sys-devel/gcc

# --- MEJORA CRÍTICA: Selección del nuevo compilador ---
# Obtenemos la versión instalada para seleccionarla automáticamente
NEW_GCC_VER=$(gcc-config -l | grep '16' | head -n1 | awk '{print $1}' | tr -d '[]')
if [ -n "$NEW_GCC_VER" ]; then
  sudo gcc-config "$NEW_GCC_VER"
  source /etc/profile
  echo -e "  Cambiado a GCC versión 16 correctamente."
fi

# 2. Reconstrucción de la Toolchain con el nuevo compilador
sudo emerge -v1 sys-libs/glibc
sudo emerge -v1 sys-devel/binutils

# 3. Limpieza de librerías antiguas (libtool)
# Esto previene problemas de enlace con versiones previas de GCC
sudo emerge -v1 dev-build/libtool

# 4. Actualización del sistema completo (@world)
# Reconstruye todo lo que dependa de las librerías del compilador anterior
sudo emerge -auvND @world --exclude 'sys-kernel/linux-headers sys-devel/gcc sys-libs/glibc sys-devel/binutils'

# 5. Limpieza de dependencias huérfanas
sudo emerge --ask --depclean

echo -e "\n  Finalizada actualización GCC ..."
