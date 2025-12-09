#!/bin/bash
fecha=$(date)
nomsnap=$(echo $fecha | awk '{print $1 "-" $2 "-" $3 "-" $4 "-" $5 "" $6 ""}')
DIR1="/mnt/snaps/"
ARCH=$DIR1$nomsnap
sudo btrfs subvol snapshot / $ARCH
echo "Se ha creado e snapshot con el nombre: $ARCH"
