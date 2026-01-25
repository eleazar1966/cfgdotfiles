#!/bin/bash

# Define el directorio de trabajo (HOME) y el directorio git bare
export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

echo "Añadiendo archivos de configuracion al staging area..."

# Se eliminó la duplicación de .bashrc
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add \
  ~/.nanorc \
  ~/.bashrc \
  ~/.config/waybar \
  ~/.config/wallpaper \
  ~/.config/rofi \
  ~/.config/nwg-look \
  ~/.config/nvim \
  ~/.config/matugen \
  ~/.config/hypr \
  ~/.config/niri \
  ~/.config/kitty \
  ~/.local/share/systools \
  ~/.local/share/nvim \
  ~/.local/state/nvim \
  ~/Documentos/Linux/Gentoo/etc/fstab \
  ~/Documentos/Linux/Gentoo/etc/portage/make.conf \
  ~/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags

# Verificar si hay cambios antes de proceder
if ! git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE diff-index --quiet HEAD; then
  echo "Realizando commit de los cambios..."
  COMMIT_MSG="Auto-update configurations @ $(date +'%Y-%m-%d %H:%M:%S')"
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

  echo "Sincronizando con GitHub via SSH..."
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main
  echo "Proceso de actualizacion completado."
else
  echo "No se detectaron cambios. Nada que actualizar."
fi
