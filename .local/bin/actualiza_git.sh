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
  "$HOME/.nanorc" "$HOME/.bashrc" "$HOME/.config/wallpaper"
  "$HOME/.config/nwg-look" "$HOME/.config/nvim"
  "$HOME/.config/matugen" "$HOME/.config/niri" "$HOME/.config/kitty"
  "$HOME/.config/pipewire" "$HOME/.config/cava" "$HOME/.local/bin"
  "$HOME/.config/ranger" "$HOME/.moc" "$HOME/.config/yt-dlp"
  "$HOME/.config/DankMaterialShell"
  "$HOME/.config/yt-x"
  "$HOME/.config/opencode"
  "$HOME/.local/share/applications/" "$HOME/Documentos/Linux/Gentoo/etc/fstab"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/make.conf"
  "$HOME/Documentos/Linux/Gentoo/etc/portage/package.use/00cpu-flags"
  "$HOME/Documentos/Linux/Gentoo/plymouth-backups"
  "$HOME/Documentos/Tryton_lista.sh" "$HOME/Documentos/btrfs_snapshot.sh"
  "$HOME/Documentos/led.sh" "$HOME/Documentos/noblanck.sh" "$HOME/Documentos/tmux.sh"
)

# 2. Filtrar solo rutas que existen físicamente
EXISTING_TARGETS=()
for target in "${TARGETS[@]}"; do
  if [ -e "$target" ]; then
    EXISTING_TARGETS+=("$target")
  else
    echo "Aviso: $target no encontrado, se omitirá el agregado directo."
  fi
done

# 2b. Respaldo y protección del .bashrc
#   - Guarda una copia fechada en el home (red de seguridad independiente de git).
#   - Si detecta que una reinstalación de oh-my-bash lo sobrescribió con su
#     template, lo restaura desde el backup más reciente o desde git HEAD,
#     para no commitear nunca una versión pisada.
BASHRC="$HOME/.bashrc"
OMB_TEMPLATE="$HOME/.oh-my-bash/templates/bashrc.osh-template"

# Compara un .bashrc contra el template de oh-my-bash, ignorando la línea
# 'export OSH=' (el instalador la reescribe con la ruta real).
es_template_omb() {
  [ -f "$OMB_TEMPLATE" ] || return 1
  diff -q <(grep -v '^export OSH=' "$1" 2>/dev/null) \
          <(grep -v '^export OSH=' "$OMB_TEMPLATE" 2>/dev/null) >/dev/null 2>&1
}

if [ -f "$BASHRC" ]; then
  if es_template_omb "$BASHRC"; then
    echo "Aviso: ~/.bashrc quedó como el template por defecto de oh-my-bash (fue sobrescrito)."
    RESTAURADO=0
    while IFS= read -r candidato; do
      [ -f "$candidato" ] || continue
      es_template_omb "$candidato" && continue
      cp -f "$candidato" "$BASHRC" && chmod 600 "$BASHRC"
      echo "Restaurado ~/.bashrc desde $candidato"
      RESTAURADO=1
      break
    done < <(printf '%s\n' "$HOME"/.bashrc.omb-backup-* | sort -r)
    if [ "$RESTAURADO" -eq 0 ] && config cat-file -e HEAD:.bashrc 2>/dev/null; then
      config show HEAD:.bashrc > "$BASHRC" && chmod 600 "$BASHRC"
      echo "Restaurado ~/.bashrc desde git HEAD."
      RESTAURADO=1
    fi
    if [ "$RESTAURADO" -eq 0 ]; then
      echo "Error: no se encontró de dónde recuperar ~/.bashrc. Revisalo a mano antes de commitear."
    fi
  fi

  RESPALDO="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"
  if cp -f "$BASHRC" "$RESPALDO"; then
    chmod 600 "$RESPALDO"
    echo "Respaldo del .bashrc: $RESPALDO"
  else
    echo "Aviso: no se pudo crear el respaldo $RESPALDO"
  fi

  # Conserva sólo los 10 respaldos más recientes
  # shellcheck disable=SC2012
  ls -1t "$HOME"/.bashrc.bak.* 2>/dev/null | tail -n +11 | while IFS= read -r viejo; do
    rm -f -- "$viejo"
  done
fi

# 3. Sincronizar el índice
if [ ${#EXISTING_TARGETS[@]} -gt 0 ]; then
  config add --all "${EXISTING_TARGETS[@]}"
fi

# Elimina del índice cualquier archivo que ya no esté en el árbol de trabajo
config add -u

# 4. Verificación, Registro y Commit
if ! config diff-index --quiet HEAD; then
  echo -e "\n--- Archivos modificados detectados ---"
  # Muestra los cambios en tiempo real en la terminal (M = Modificado, A = Añadido, D = Eliminado)
  config status --short
  echo -e "---------------------------------------\n"

  # Guardia de secretos: aborta el commit si se están agregando claves.
  # El repo se publica en GitHub, así que una API key commiteada queda expuesta.
  PATRON_SECRETO='(API_KEY|APIKEY|SECRET|TOKEN|PASSWORD|PASSWD)[A-Za-z0-9_]*[[:space:]]*=[[:space:]]*[[:punct:]]?[A-Za-z0-9_.+/=-]{16,}'
  SECRETOS=$(config diff --cached -U0 | grep -E '^\+[^+]' | grep -E "$PATRON_SECRETO" || true)
  if [ -n "$SECRETOS" ]; then
    echo "Error: se detectaron claves/secretos en los cambios a commitear:"
    printf '%s\n' "$SECRETOS" | sed -E 's/(=[[:space:]]*[[:punct:]]?).*/\1***/'
    echo "Commit abortado. Movés esas claves a un archivo 0600 fuera del repo y volvés a correr."
    exit 1
  fi

  echo "Realizando commit con registro detallado..."

  # Creamos el título del commit
  COMMIT_TITLE="Sync configs: $(date +'%Y-%m-%d %H:%M:%S')"

  # Generamos el cuerpo del commit con la lista de archivos modificados
  COMMIT_BODY=$(config status --short)

  # Hacemos el commit combinando título y cuerpo
  config commit -m "$COMMIT_TITLE" -m "$COMMIT_BODY"

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
