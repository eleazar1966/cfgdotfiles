#!/bin/bash
echo -e "\n  Iniciando actualización de Kernel optimizada... \n"

# 1. Gestión de /boot
FOLDER2="/boot"
if [[ $(findmnt -M "$FOLDER2") ]]; then
  echo -e "\n /boot ya está montado. \n"
else
  echo -e "\n Montando /boot... \n"
  sudo mount /dev/nvme0n1p1 /boot
fi

# 2. Preparación de fuentes
sudo rm -rf /usr/src/*
sudo emerge gentoo-sources
sudo eselect kernel set 1
cd /usr/src/linux

# 3. Sincronización de módulos y configuración actual
echo "Sincronizando base de datos de módulos..."
modprobed-db store  # Guarda el estado actual de los módulos cargados
modprobed-db recall # Recupera la lista completa para la configuración

sudo make mrproper
# Copiamos el config funcional actual como base
sudo cp /boot/config-$(uname -r) /usr/src/linux/.config

# 4. Configuración inteligente
# Genera un .config basado en los módulos que modprobed-db sabe que usas
sudo make LSMOD=$HOME/.config/modprobed.db localmodconfig

# Permitir ajustes manuales para nuevos periféricos
echo "Abriendo menuconfig para ajustes manuales adicionales..."
sudo make menuconfig

# 5. Compilación y optimización Zen 3
echo "Compilando kernel y módulos..."
sudo make KCFLAGS="-march=znver3 -O3 -fgraphite-identity -floop-nest-optimize" -j$(nproc)

# 6. Instalación
sudo make modules_install
sudo make install

# 7. Post-instalación
sudo dracut --force
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 8. Limpieza de kernels antiguos
if command -v eclean-kernel &>/dev/null; then
  sudo eclean-kernel -n 3
fi

cd ~
sudo umount /boot
echo -e "\n Procesos completados. El nuevo kernel incluye tus módulos actuales y nuevos cambios."
