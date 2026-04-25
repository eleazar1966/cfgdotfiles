#!/bin/bash

export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

echo "Añadiendo archivos de configuración al staging area..."

# Definimos las rutas en un array para manejarlas mejor
rutas=(
  "$HOME/.nanorc"
  "$HOME/.bashrc"
  "$HOME/.config/waybar"
  "$HOME/.config/wallpaper"
  "$HOME/.config/fuzzel"
  "$HOME/.config/nwg-look"
  "$HOME/.config/nvim"
  "$HOME/.config/matugen"
  "$HOME/.config/niri"
  "$HOME/.config/kitty"
  "$HOME/.config/pipewire"
  "$HOME/.config/cava"
  "$HOME/.local/bin"
  "$HOME/Documentos/Linux/Gentoo/etc/fstab"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/make.conf"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags"
)

# Añadimos cada ruta solo si existe, evitando que el script falle
for ruta in "${rutas[@]}"; do
  if [ -e "$ruta" ]; then
    git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add "$ruta"
  fi
done

# También es recomendable añadir los borrados de archivos que YA estaban en el repo
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add -u

# Lógica de verificación
if ! git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE diff-index --quiet HEAD; then
  echo "Cambios detectados. Realizando commit..."
  COMMIT_MSG="Auto-update configurations @ $(date +'%Y-%m-%d %H:%M:%S')"
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

  echo "Sincronizando con GitHub via SSH..."
  git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main
  echo "Proceso de actualización completado con éxito."
else
  echo "No se detectaron cambios en las configuraciones."
fi
