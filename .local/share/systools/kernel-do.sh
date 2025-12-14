#!/bin/bash
echo -e "\n  Iniciando actualizacion de Kernel ... \n"
#FOLDER="/efi"
#if [[ $(findmnt -M "$FOLDER") ]]; then
#  echo -e "\n /efi ya está montado, se inicia configuraci'on de kernel ... \n"
#else
#  echo -e "\n /efi no montado, se inicia el mount ... \n"
#  sudo mount /dev/nvme0n1p1 /efi
#  echo -e "\n /efi ya está montado, se inicia configuraci'on de kernel ... \n"
#fi
FOLDER2="/boot"
if [[ $(findmnt -M "$FOLDER2") ]]; then
  echo -e "\n /boot ya está montado, se inicia configuraci'on de kernel ... \n"
else
  echo -e "\n /boot no montado, se inicia el mount ... \n"
  sudo mount /dev/nvme0n1p1 /boot
  echo -e "\n /boot ya está montado, se inicia configuraci'on de kernel ... \n"
fi
sudo rm -rf /usr/src/*
sudo emerge gentoo-sources
sudo eselect kernel set 1
cd /usr/src/linux
sudo make mrproper
sudo make localmodconfig
zcat /proc/config.gz >~/.oldconfig
sudo sudo mv ~/.oldconfig /usr/src/linux/.config
sudo make menuconfig
sudo make -j $(nproc)
sudo make modules_install
sudo make install
sudo dracut --force
#sudo rm /boot/*.png
cd
#sudo umount /efi
sudo umount /boot
echo -e "\n  Finalizada actualizacion de Kernel ..."
