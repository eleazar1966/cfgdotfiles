#!/bin/bash
echo -e "\n  Iniciando actualizacion de Kernel ... \n"

# Verificación y montaje de /boot
FOLDER2="/boot"
if [[ $(findmnt -M "$FOLDER2") ]]; then
  echo -e "\n /boot ya está montado, se inicia configuraci'on de kernel ... \n"
else
  echo -e "\n /boot no montado, se inicia el mount ... \n"
  sudo mount /dev/nvme0n1p1 /boot
  echo -e "\n /boot ya está montado, se inicia configuraci'on de kernel ... \n"
fi

# Limpieza y obtención de fuentes
sudo rm -rf /usr/src/*
sudo emerge gentoo-sources
sudo eselect kernel set 1
cd /usr/src/linux

# Configuración del Kernel
sudo make mrproper
sudo modprobed-db recall
sudo cp /boot/config-$(uname -r) /usr/src/.config
sudo make LSMOD=/home/eleazar/.config/modprobed.db localmodconfig
sudo make localmodconfig

# Compilación con optimizaciones para Zen 3
sudo make menuconfig
sudo make KCFLAGS="-march=znver3 -O3 -fgraphite-identity -floop-nest-optimize" -j $(nproc)
sudo make modules_install
sudo make install

# Post-instalación y limpieza
sudo dracut --force

# Limpieza de kernels antiguos (mantiene los 3 más recientes)
# Requiere tener instalado app-admin/eclean-kernel
if command -v eclean-kernel &>/dev/null; then
  sudo eclean-kernel -n 3
else
  echo -e "\n [!] eclean-kernel no encontrado. Saltando limpieza... \n"
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg

cd
sudo umount /boot
echo -e "\n  Finalizada actualizacion de Kernel ..."
