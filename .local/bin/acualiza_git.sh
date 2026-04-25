#!/bin/bash

# Configuración del entorno bare
export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

echo "Sincronizando cambios y eliminaciones en el índice..."

# 1. Lista de archivos/directorios a rastrear
TARGETS=(
  ~/.nanorc ~/.bashrc ~/.config/waybar ~/.config/wallpaper 
  ~/.config/fuzzel ~/.config/nwg-look ~/.config/nvim 
  ~/.config/matugen ~/.config/niri ~/.config/kitty 
  ~/.config/pipewire ~/.config/cava ~/.local/bin
  ~/Documentos/Linux/Gentoo/etc/fstab
  ~/Documentos/Linux/Gentoo/etc/portage/make.conf
  ~/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags
)

# 2. Agregamos cambios de las rutas definidas
# --all incluye archivos nuevos, modificados y ELIMINADOS en esas rutas
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add --all "${TARGETS[@]}"

# 3. Limpieza de archivos que ya no existen (como los de systools)
# Esto busca en todo el índice y elimina lo que falte en el disco
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add -u

# 4. Verificación y Commit
if ! git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE diff-index --quiet HEAD; then
  echo "Cambios detectados. Realizando commit..."
  
  COMMIT_MSG="Sync configs: $(date +'%Y-%m-%d %H:%M:%S')"
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

  echo "Subiendo a GitHub..."
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main
  echo "Todo actualizado correctamente."
else
  echo "El sistema ya está sincronizado. Nada que hacer."
fi
