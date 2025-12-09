#!/bin/bash

# Define el directorio de trabajo (HOME) y el directorio git bare
export GIT_DIR=$HOME/.cfgdotfiles/
export GIT_WORK_TREE=$HOME

# --- Comandos Git ---

echo "Añadiendo archivos de configuracion al staging area..."

# Usamos 'git --git-dir... --work-tree...' en lugar del alias para que funcione dentro del script
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE add \
    ~/.nanorc \
    ~/.bashrc \
    ~/.config/waybar \
    ~/.config/wallpaper \
    ~/.bashrc \
    ~/.config/rofi \
    ~/.config/nwg-look \
    ~/.config/nvim \
    ~/.config/matugen \
    ~/.config/hypr \
    ~/.config/niri \
    ~/.config/kitty \
    ~/.local/share/systools \
    ~/Documentos/Linux/Gentoo/etc/fstab \
    ~/Documentos/Linux/Gentoo/etc/portage/make.conf \
    ~/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags

echo "Realizando commit de los cambios..."

# Usamos una fecha y hora como mensaje de commit automático
COMMIT_MSG="Auto-update configurations @ $(date +'%Y-%m-%d %H:%M:%S')"
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE commit -m "$COMMIT_MSG"

echo "Sincronizando con GitHub via SSH..."

# Empujar los cambios a la rama main remota
git --git-dir=$GIT_DIR --work-tree=$GIT_WORK_TREE push origin main

echo "Proceso de actualizacion completado."
