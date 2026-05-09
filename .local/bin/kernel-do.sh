#!/bin/bash
set -e

BACKUP_DIR="/home/eleazar/.config/kernel_backups"
mkdir -p "$BACKUP_DIR"

echo -e "\n  Iniciando actualización de Kernel (Optimizado para Zen 3) \n"

# 1. Gestión de espacio y montaje de /boot
if ! mountpoint -q /boot; then
  sudo mount /dev/nvme0n1p1 /boot
fi

echo "Liberando espacio preventivo en /boot..."
sudo rm -f /boot/*.old /boot/initramfs*.old

# 2. Respaldo de seguridad del .config actual
if [ -f /usr/src/linux/.config ]; then
  cp /usr/src/linux/.config "$BACKUP_DIR/last_working_config"
fi

# 3. Sincronización de fuentes
echo "Actualizando gentoo-sources..."
sudo emerge --update --newuse gentoo-sources

# 4. Selección dinámica de la versión más reciente
K_INDEX=$(eselect kernel list | grep -oP '\[\K\d+(?=\])' | sort -rn | head -n1)

if [ -n "$K_INDEX" ]; then
  echo "Seleccionando kernel índice: $K_INDEX"
  sudo eselect kernel set "$K_INDEX"
else
  echo "Error: No se detectaron fuentes en /usr/src"
  exit 1
fi

cd /usr/src/linux

# 5. Preparación y Configuración
sudo make mrproper

if [ -f "$BACKUP_DIR/last_working_config" ]; then
  echo "Restaurando configuración previa..."
  sudo cp "$BACKUP_DIR/last_working_config" .config
  sudo make olddefconfig
else
  echo "Usando configuración del kernel en ejecución..."
  zcat /proc/config.gz | sudo tee .config >/dev/null
  sudo make olddefconfig
fi

# 6. Configuración Manual (Asegúrate de activar BRIDGE y NAT para Blueman)
echo "Abriendo menuconfig..."
sudo make menuconfig

# 7. Compilación con optimización nativa Cezanne
echo "Compilando para Ryzen 7 5700G con $(nproc) hilos..."
sudo make KCFLAGS="-march=znver3 -O3 -pipe" -j$(nproc)

# 8. Instalación
sudo make modules_install
sudo make install
sudo rm -f /boot/*.old /boot/initramfs*.old
sudo eclean-kernel -n 2
# 9. Initramfs y GRUB
echo "Generando Initramfs y actualizando GRUB..."
sudo dracut --force
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 10. Finalización
cd ~
sudo umount /boot
echo -e "\n Proceso completado exitosamente."
