#!/bin/bash
DIR1="/mnt/snaps/"
nomsnap="snap_$(date +%Y-%m-%d_%H%M%S)"
ARCH="$DIR1$nomsnap"
sudo btrfs subvol snapshot / "$ARCH"
echo "Se ha creado el snapshot: $ARCH"
