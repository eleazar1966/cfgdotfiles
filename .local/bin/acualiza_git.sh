#!/bin/bash

export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

echo "Actualizando el índice de Git (incluyendo borrados y cambios)..."

# Definimos los targets
TARGETS=(
  ~/.nanorc
  ~/.bashrc
  ~/.config/waybar
  ~/.config/wallpaper
  ~/.config/fuzzel
  ~/.config/nwg-look
  ~/.config/nvim
  ~/.config/matugen
  ~/.config/niri
  ~/.config/kitty
  ~/.config/pipewire
  ~/.config/cava
  ~/.local/bin
  ~/Documentos/Linux/Gentoo/etc/fstab
  ~/Documentos/Linux/Gentoo/etc/portage/make.conf
  ~/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags
)

# Agregamos cambios con --all para capturar borrados en las rutas rastreadas
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add --all "${TARGETS[@]}"

# Si nvim sigue dando problemas, forzamos el rastro (si no es submódulo)
if [ -d "$HOME/.config/nvim" ]; then
    git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add ~/.config/nvim
fi

# Verificación de cambios
if ! git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE diff-index --quiet HEAD; then
  echo "Cambios detectados. Realizando commit..."
  
  COMMIT_MSG="Auto-update configs (Full Sync) @ $(date +'%Y-%m-%d %H:%M:%S')"
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

  echo "Sincronizando con GitHub via SSH..."
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main
  echo "Proceso completado."
else
  echo "No hay cambios pendientes."
fi
