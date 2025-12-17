#!/bin/bash
clear

# --- 1. Definición de Variables y Montaje ---
# NOTA: Asegúrate de que /dev/nvme0n1p1 sea realmente tu Partición de Sistema EFI (ESP).

echo -e "\n## 📁 Verificación y Montaje de /boot (Partición EFI)"
echo "--------------------------------------------------------"
PARTITION="/dev/nvme0n1p1"
FOLDER="/boot" # Punto de montaje para la ESP
set -e

# Comprueba si /boot ya está montado
if [[ $(findmnt -M "$FOLDER") ]]; then
  echo -e "\n /boot ya está montado ..."
else
  echo -e "\n /boot no montado, se inicia el mount ..."
  sudo mount /dev/nvme0n1p1 /boot
  echo -e "\n /boot ya está montado ..."
fi

echo -e "\n## 🧹 Limpieza Pre-Actualización y Sincronización"
echo "--------------------------------------------------------"

# Limpieza y Sincronización
sudo rm -rf /var/db/repos/*
echo "✅ Directorios de repositorios eliminados."
sudo emaint sync -a
echo "✅ Sincronización de Portage completada."
sudo eclean -d distfiles
echo "✅ Distfiles obsoletos limpiados."
# --- 2. Actualización del Sistema ---

echo -e "\n## 🔄 Instalación de @world"
echo "--------------------------------------------------------"

# Actualización del sistema (World Set)
# -u: update, -D: deep, -v: verbose, -N: new use/slot. --jobs usa todos los núcleos disponibles.
# sudo emerge -uDvN --jobs=$(nproc) @world
sudo emerge -uDvN @world
echo "✅ Actualización de @world completada. Código de salida: $?"

# --- 3. Mantenimiento y Limpieza Post-Actualización ---

echo -e "\n##   Mantenimiento y Reconstrucción"
echo "--------------------------------------------------------"

# Tareas de mantenimiento estándar
sudo emerge --depclean
sudo revdep-rebuild
sudo emerge @preserved-rebuild
sudo qcheck --update
sudo emaint -c all

# Limpieza final de la caché
sudo eclean -d packages
sudo eclean --destructive distfiles

echo "✅ Tareas de mantenimiento y limpieza finalizadas."

# --- 4. Finalización ---

echo -e "\n##   Desmontaje y Fin"
echo "--------------------------------------------------------"

# Desmonta la partición /boot (ESP)
# Se utiliza $FOLDER que es la variable definida para /boot.
sudo umount "$FOLDER"
echo -e "\n✅ $FOLDER ha sido desmontado."
echo -e "\n󰦖 ¡Actualización de Gentoo finalizada con éxito! 󰦕 "
