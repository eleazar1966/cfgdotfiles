#!/bin/bash
set -e

BACKUP_DIR="/home/eleazar/.config/kernel_backups"
mkdir -p "$BACKUP_DIR"

echo -e "\n  Actualización de Kernel: Fuentes Limpias + Configuración Preservada \n"

# 1. Gestión de /boot y limpieza de espacio
if ! mountpoint -q /boot; then
  sudo mount /dev/nvme0n1p1 /boot
fi

echo "Liberando espacio en /boot..."
sudo rm -f /boot/*.old /boot/initramfs*.old

# 2. Respaldo preventivo
[ -f /usr/src/linux/.config ] && cp /usr/src/linux/.config "$BACKUP_DIR/last_working_config"

# 3. Gestión de fuentes (Evita el error 'out of range')
# Si borraste /usr/src/* manualmente, necesitamos forzar la descarga de nuevo
if [ ! -d "/usr/src/linux-*" ]; then
  echo "Fuentes no detectadas. Forzando instalación de gentoo-sources..."
  sudo emerge --oneshot gentoo-sources
else
  echo "Actualizando fuentes..."
  sudo emerge --update --newuse gentoo-sources
fi

# 4. Selección dinámica del kernel más reciente
# Obtenemos el índice más alto de la lista de eselect
K_INDEX=$(eselect kernel list | grep -oP '\[\K\d+(?=\])' | sort -rn | head -n1)

if [ -n "$K_INDEX" ]; then
  echo "Seleccionando kernel índice: $K_INDEX"
  sudo eselect kernel set "$K_INDEX"
else
  echo "Error crítico: No se pudieron encontrar ni instalar fuentes en /usr/src"
  exit 1
fi

cd /usr/src/linux

# 5. Integración de Configuración (Limpia + Backup)
# Limpiamos el árbol de fuentes para asegurar que sea una compilación 'desde cero'
sudo make mrproper

if [ -f "$BACKUP_DIR/last_working_config" ]; then
  echo "Cargando configuración de respaldo..."
  sudo cp "$BACKUP_DIR/last_working_config" .config
  # Integra opciones nuevas sin quitar las anteriores
  sudo make olddefconfig
else
  echo "Usando configuración del sistema actual..."
  zcat /proc/config.gz | sudo tee .config >/dev/null
  sudo make olddefconfig
fi

# 6. Ajustes manuales y Compilación Zen 3
echo "Abriendo menuconfig para ajustes finales..."
sudo make menuconfig

echo "Compilando para Ryzen 7 5700G (Cezanne)..."
sudo make KCFLAGS="-march=znver3 -O3 -pipe" -j$(nproc)

# 7. Instalación y limpieza de espacio final
sudo make modules_install
sudo make install
sudo rm -f /boot/*.old /boot/initramfs*.old

# 8. Post-instalación
sudo dracut --force
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 9. Finalización
cd ~
sudo umount /boot
echo -e "\n Proceso completado exitosamente con fuentes nuevas y config preservada."
