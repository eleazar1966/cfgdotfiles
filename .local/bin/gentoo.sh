#!/bin/sh
# Author: Eleazar Anzola
# Montando sistema para instalar Gentoo

#mkdir -p /mnt/gentoo
mount /dev/sda2 /mnt/gentoo
mount /dev/sda1 /mnt/gentoo/boot
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
cd /mnt/gentoo
chroot /mnt/gentoo /bin/bash
#source /etc/profile
#export PS1="(chroot) ${PS1}"
#env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
