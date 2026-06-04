#!/bin/bash

# Configuración del repositorio bare
export GIT_DIR="$HOME/.cfgdotfiles/"
export GIT_WORK_TREE="$HOME"

# Función interna para simplificar comandos
function config() {
  /usr/bin/git --git-dir="$GIT_DIR" --work-tree="$GIT_WORK_TREE" "$@"
}

echo "Iniciando sincronización de dotfiles..."

# 1. Definición de rutas (Targets)
TARGETS=(
  "$HOME/.nanorc" "$HOME/.bashrc" "$HOME/.config/waybar" "$HOME/.config/wallpaper"
  "$HOME/.config/fuzzel" "$HOME/.config/nwg-look" "$HOME/.config/nvim"
  "$HOME/.config/matugen" "$HOME/.config/niri" "$HOME/.config/kitty"
  "$HOME/.config/pipewire" "$HOME/.config/cava" "$HOME/.local/bin"
  "$HOME/.config/mako" "$HOME/.config/ranger" "$HOME/.moc" "$HOME/.config/yt-dlp"
  "$HOME/.config/yt-x" "$HOME/.config/fuzzel"
  "$HOME/.local/share/applications/" "$HOME/Documentos/Linux/Gentoo/etc/fstab"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/make.conf"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags"
)

# 2. Filtrar solo rutas que existen físicamente
EXISTING_TARGETS=()
for target in "${TARGETS[@]}"; do
  if [ -e "$target" ]; then
    EXISTING_TARGETS+=("$target")
  else
    # Si el archivo fue borrado, Git add -u lo detectará globalmente después
    echo "Aviso: $target no encontrado, se omitirá el agregado directo."
  fi
done

# 3. Sincronizar el índice
# --all maneja adiciones, cambios y eliminaciones en las rutas existentes
if [ ${#EXISTING_TARGETS[@]} -gt 0 ]; then
  config add --all "${EXISTING_TARGETS[@]}"
fi

# Elimina del índice cualquier archivo que ya no esté en el árbol de trabajo (limpieza global)
config add -u

# 4. Verificación y Commit
if ! config diff-index --quiet HEAD; then
  echo "Cambios detectados. Realizando commit..."

  COMMIT_MSG="Sync configs: $(date +'%Y-%m-%d %H:%M:%S')"
  config commit -m "$COMMIT_MSG"

  echo "Subiendo a GitHub..."
  if config push origin main; then
    echo "Todo actualizado correctamente."
  else
    echo "Error: No se pudo subir a GitHub. Verifica tu conexión o credenciales."
    exit 1
  fi
else
  echo "El sistema ya está sincronizado. Nada que hacer."
fi
