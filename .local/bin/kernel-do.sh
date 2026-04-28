#!/bin/bash
set -e

BACKUP_DIR="/home/eleazar/.config/kernel_backups"
mkdir -p "$BACKUP_DIR"

echo -e "\n  Iniciando actualización con Limpieza de Espacio en /boot \n"

# 1. Montaje y Limpieza Inmediata (Para liberar espacio antes de compilar)
if ! mountpoint -q /boot; then
  sudo mount /dev/nvme0n1p1 /boot
fi

echo "Liberando espacio en /boot..."
# Borramos archivos .old inmediatamente para ganar espacio
if ls /boot/*.old 1>/dev/null 2>&1; then
  sudo rm -f /boot/*.old
  sudo rm -f /boot/initramfs*.old
fi

# Usamos eclean-kernel si está disponible (como sugirió el error)
if command -v eclean-kernel &>/dev/null; then
  sudo eclean-kernel -n 1 # Mantenemos solo el kernel actual
fi

# 2. Respaldo de configuración
if [ -f /usr/src/linux/.config ]; then
  cp /usr/src/linux/.config "$BACKUP_DIR/last_working_config"
fi

# 3. Preparación de fuentes
sudo find /usr/src -maxdepth 1 -type l -delete
sudo emerge --update --newuse gentoo-sources
sudo eselect kernel set 1
cd /usr/src/linux

# 4. Configuración (Preservando todo lo existente)
if [ -f "$BACKUP_DIR/last_working_config" ]; then
  sudo cp "$BACKUP_DIR/last_working_config" .config
elif [ -f /proc/config.gz ]; then
  zcat /proc/config.gz | sudo tee .config >/dev/null
fi

# Mantenemos todas las opciones, incluidas las no usadas
sudo make olddefconfig
sudo make menuconfig

# 5. Compilación optimizada para Zen 3
echo "Compilando para Ryzen 7 5700G (Cezanne)..."
sudo make KCFLAGS="-march=znver3 -O3 -pipe" -j$(nproc)
echo "Liberando espacio en /boot..."
# Borramos archivos .old inmediatamente para ganar espacio

if ls /boot/*.old 1>/dev/null 2>&1; then
  sudo rm -f /boot/*.old
  sudo rm -f /boot/initramfs*.old
fi
# 6. Instalación (Ahora con espacio disponible)
sudo make modules_install
sudo make install

# 7. Post-instalación y GRUB
sudo dracut --force
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 8. Finalización
cd ~
sudo umount /boot
echo -e "\n Proceso completado exitosamente."
