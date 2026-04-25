#!/bin/bash

# Define el directorio de trabajo (HOME) y el directorio git bare
export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

echo "Añadiendo archivos de configuración al staging area..."

# Lista unificada y limpia de todos los directorios y archivos críticos
# Se incluyen las rutas de CAVA y las plantillas de Matugen
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add \
  ~/.nanorc \
  ~/.bashrc \
  ~/.config/waybar \
  ~/.config/wallpaper \
  ~/.config/fuzzel \
  ~/.config/nwg-look \
  ~/.config/nvim \
  ~/.config/matugen \
  ~/.config/niri \
  ~/.config/kitty \
  ~/.config/pipewire \
  ~/.config/cava \
  ~/.local/bin \
  ~/Documentos/Linux/Gentoo/etc/fstab \
  ~/Documentos/Linux/Gentoo/etc/portage/make.conf \
  ~/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags

# Lógica de verificación inteligente: solo procede si hay cambios detectados
if ! git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE diff-index --quiet HEAD; then
  echo "Cambios detectados. Realizando commit..."
  
  # Mensaje de commit descriptivo con marca de tiempo
  COMMIT_MSG="Auto-update configurations (CAVA/Matugen included) @ $(date +'%Y-%m-%d %H:%M:%S')"
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

  echo "Sincronizando con GitHub via SSH..."
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main
  echo "Proceso de actualización completado con éxito."
else
  echo "No se detectaron cambios en las configuraciones. Nada que actualizar."
fi
