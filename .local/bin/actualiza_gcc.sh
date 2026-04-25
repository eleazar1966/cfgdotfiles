#!/bin/bash
echo -e "\n  Iniciando actualizacion GCC ..."
sudo emerge -v1 sys-kernel/linux-headers
sudo emerge -v1 sys-devel/gcc
sudo emerge -v1 sys-libs/glibc
sudo emerge -v1 sys-devel/binutils
sudo emerge -auvND @world --exclude 'sys-kernel/linux-headers sys-devel/gcc sys-libs/glibc sys-devel/binutils'

echo -e "\n  Finalizada actualizacion GCC ..."
