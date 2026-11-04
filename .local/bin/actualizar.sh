#!/bin/bash
set -e

set_title() {
  echo -ne "\033]0;$1\007"
}

ORIGINAL_TITLE="Terminal"
BOOT_WAS_MOUNTED=0

# Marcador de estado de la corrida.
# `set -e` (abajo) corta el script en silencio si `emerge` devuelve un exit distinto
# de cero, y en ese caso los pasos 5-9 (limpieza/optimización) nunca corren. El exit code
# del script NO distingue "actualización completa" de "a medias": ambos son un fallo.
# Este archivo es la única señal en disco que sí lo distingue:
#   running <ts>  = la corrida empezó y no terminó bien (quedó un "running" viejo)
#   ok <ts>       = la corrida llegó al final
# Ojo: el sync (paso 2) ya NO es fatal — un repo caído se reporta y se sigue. El
# trap de /boot de más abajo garantiza el desmontaje en cualquier salida.
STATUS_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/gentoo-updates"
STATUS_FILE="$STATUS_DIR/last-run.status"

mark_running() {
  mkdir -p "$STATUS_DIR"
  printf 'running %s\n' "$(date -Is)" >"$STATUS_FILE"
}

mark_ok() {
  mkdir -p "$STATUS_DIR"
  printf 'ok %s\n' "$(date -Is)" >"$STATUS_FILE"
}

mark_running

# Red de seguridad para /boot.
# El script monta /boot en el paso 1 y lo desmontaba recién en el paso 9, así que
# cualquier muerte intermedia (set -e, Ctrl-C, repos caídos) lo dejaba montado
# para siempre. Con este trap el desmontaje ocurre en TODA salida.
al_salir() {
  local rc=$?
  trap - EXIT
  if [ "$BOOT_WAS_MOUNTED" -eq 0 ] && mountpoint -q /boot; then
    echo "🧹 Desmontando /boot antes de salir (rc=$rc)..."
    sudo umount /boot || echo "⚠️  No se pudo desmontar /boot."
  fi
  exit "$rc"
}
trap al_salir EXIT

# Configuración balanceada para Zen 3 con 32GB RAM + tmpfs
LOAD=8.0

echo "=========================================================="
echo "   INICIANDO ACTUALIZACIÓN Y OPTIMIZACIÓN GENTOO (Zen 3)  "
echo "=========================================================="

# 1. Montaje de /boot
if mountpoint -q /boot; then
  echo "[1/9] /boot ya está montado."
  BOOT_WAS_MOUNTED=1
else
  echo "[1/9] Montando partición /boot..."
  sudo mount /boot
fi

# 2. Sincronización
echo "[2/9] Sincronizando repositorios..."
set_title "sync"
# Un repo inalcanzable hace que `emerge --sync` devuelva error aunque el resto haya
# sincronizado bien. Antes eso mataba el script acá mismo por `set -e`: pasó el
# 2026-10-27 con el overlay tryton, y la corrida quedó a medias sin tocar @world.
# Ahora se reporta qué repo falló y se sigue.
SYNC_LOG=$(mktemp "${TMPDIR:-/tmp}/actualizar-sync.XXXXXX")
set +e
sudo emerge --sync 2>&1 | tee "$SYNC_LOG"
SYNC_RC=${PIPESTATUS[0]}
set -e
if [ "$SYNC_RC" -eq 0 ]; then
  echo "✅ Sync completo."
else
  echo
  echo "⚠️  El sync devolvió error (rc=$SYNC_RC). Repos afectados:"
  {
    grep -oP 'error in /var/db/repos/\K\S+' "$SYNC_LOG" || true
    sed -n 's/^Action: sync for repo: \([^,]*\), returned code = [1-9].*/\1/p' "$SYNC_LOG" || true
  } | sort -u | sed 's/^/     - /'
  echo "   La actualización continúa: un repo caído no debe frenar @world."
  echo "   Si ese repo no se va a recuperar pronto, agregale 'auto-sync = no'"
  echo "   en su sección de /etc/portage/repos.conf/ para que deje de intentarlo."
fi
rm -f "$SYNC_LOG"

# 2b. Integridad: paquetes instalados que se quedaron sin ebuild disponible.
# Es el síntoma exacto de un overlay vacío o borrado por un sync fallido (así se
# descubrió el tryton roto: 23 paquetes sin ebuild y @world seguía diciendo "0").
#
# OJO: 'emaint --check world' solo mira los paquetes de @world. Las DEPENDENCIAS
# quedan invisibles, y son la mayoría de un overlay de apps (dev-python/proteus,
# dev-javascript/*, ...). Aquí se consultan TODOS los instalados contra el árbol.
HUERFANOS_HALLAZGO=$(sudo python3 - <<'PY' 2>/dev/null || true
import os
import portage

pdb = portage.portdb
vdb = "/var/db/pkg"
missing = []
for cat in sorted(os.listdir(vdb)):
    if not os.path.isdir(os.path.join(vdb, cat)):
        continue
    for pf in sorted(os.listdir(os.path.join(vdb, cat))):
        if not os.path.exists(os.path.join(vdb, cat, pf, pf + ".ebuild")):
            continue
        if not pdb.cpv_exists(f"{cat}/{pf}"):
            missing.append(f"{cat}/{pf}")
print(len(missing))
for m in missing[:10]:
    print(m)
PY
)
HUERFANOS=$(printf '%s\n' "$HUERFANOS_HALLAZGO" | head -1)
if [ "${HUERFANOS:-0}" -gt 0 ]; then
  echo
  echo "⚠️  $HUERFANOS paquete(s) instalados sin ebuild disponible en ningún repo:"
  printf '%s\n' "$HUERFANOS_HALLAZGO" | tail -n +2 | sed 's/^/     /'
  echo "   No se pueden reconstruir hasta recuperar el repo de origen (si es Tryton:"
  echo "   sudo ~/.local/bin/recuperar-overlay-tryton.sh --force)."
fi

eselect news list | grep -q "read" && echo "(!) Hay noticias de Gentoo sin leer."

# 3. Integridad de Portage
echo "[3/9] Verificando y reparando integridad..."
set_title "emaint"
# --check all funciona bien (solo lectura), --fix all incluye binhost/movebin
# que requieren PKGDIR — los excluimos explícitamente.
sudo emaint --check all || true
# logs usa --clean (no --fix), y ya tienes clean-logs en FEATURES — lo omitimos.
# vdb (agregado 2026-10-03) repuebla la metadata consolidada de /var/db/pkg para los
# paquetes que emaint reporta como "missing, stale, or use an older format". Solo escribe
# metadata en el VDB: no toca archivos del sistema ni paquetes instalados.
SAFE_FIX_CMDS=("cleanconfmem" "cleanresume" "merges" "moveinst" "vdb" "world")
for cmd in "${SAFE_FIX_CMDS[@]}"; do
  sudo emaint --fix "$cmd" || true
done

# =====================================================================
# DETECCIÓN DE NUEVO KERNEL (comparando fuentes instaladas vs activas)
# =====================================================================
echo "🔍 Verificando si hay fuentes de kernel más recientes sin compilar..."
DETECTAR_NUEVO_KERNEL=0

LATEST_SRC_DIR=$(ls -1d /usr/src/linux-*-gentoo 2>/dev/null | sort -V | tail -1)
CURRENT_SRC_LINK=$(readlink /usr/src/linux 2>/dev/null)

if [ -n "$LATEST_SRC_DIR" ] && [ -n "$CURRENT_SRC_LINK" ]; then
  LATEST_BASENAME=$(basename "$LATEST_SRC_DIR")
  if [ "$LATEST_BASENAME" != "$CURRENT_SRC_LINK" ]; then
    echo "✨ ¡Se detectó $LATEST_BASENAME sin compilar! Se ejecutará kernel-do.sh..."
    DETECTAR_NUEVO_KERNEL=1
  else
    echo "✅ El kernel activo ya es la última versión instalada ($CURRENT_SRC_LINK)."
  fi
elif [ -z "$CURRENT_SRC_LINK" ]; then
  echo "⚠️  No hay un kernel seleccionado. Se ejecutará kernel-do.sh..."
  DETECTAR_NUEVO_KERNEL=1
else
  echo "⚠️  No se encontraron fuentes en /usr/src/."
fi

# ── Check adicional: ¿Portage ofrece fuentes de kernel NUEVAS aún no instaladas? ──
# El check de /usr/src/ solo ve lo ya instalado. Como @world descarga las fuentes
# en ESTA pasada, si Portage tiene una versión más reciente que la activa debemos
# marcarlo AHORA (tras sync) para que kernel-do.sh corra al final de esta misma
# actualización. Un "[ebuild   R ]" = misma versión (sin novedad); cualquier otro
# estado (U, N, NS) = hay fuente más reciente disponible.
EMERGE_KERNEL=$(emerge -p sys-kernel/gentoo-sources 2>/dev/null | grep '^\[ebuild' | grep 'sys-kernel/gentoo-sources' | grep -vP '\[ebuild\s+R' | head -1 || true)
if [ -n "$EMERGE_KERNEL" ] && [ "$DETECTAR_NUEVO_KERNEL" -eq 0 ]; then
  KERNEL_NUEVA=$(echo "$EMERGE_KERNEL" | grep -oP 'gentoo-sources-\K\S+' | head -1 || echo "desconocida")
  echo "✨ Portage ofrece fuentes de kernel más recientes: gentoo-sources-$KERNEL_NUEVA — se generan al final de esta actualización."
  DETECTAR_NUEVO_KERNEL=1
fi
# =====================================================================
# DETECCIÓN DE NUEVO GCC
#   - Revisa si hay un slot diferente instalado pero no activo (gcc-config)
#   - Revisa si Portage tiene una actualización de slot (ej. gcc:16 → gcc:17)
#   - Revisa si Portage tiene un parche menor (mismo slot, emerge @world lo maneja)
# =====================================================================
echo "🔍 Verificando si hay una versión más reciente de GCC..."
DETECTAR_NUEVO_GCC=0

CURRENT_GCC_VER=$(gcc --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+[^\s]*' | head -1 || echo "desconocido")
CURRENT_GCC_SLOT=$(gcc --version 2>/dev/null | head -1 | grep -oP 'Gentoo\s+\K\d+' || echo "")

# ── Check 1: ¿Slot instalado pero no activo (gcc-config)? ──
if command -v gcc-config &>/dev/null; then
  CURRENT_GCC_PROFILE=$(gcc-config -c 2>/dev/null || true)
  LATEST_INSTALLED_PROFILE=$(gcc-config --list-profiles 2>/dev/null | grep -oP '\[\d+\]\s+\K\S+' | sort -V | tail -1)

  if [ -n "$LATEST_INSTALLED_PROFILE" ] && [ -n "$CURRENT_GCC_PROFILE" ] &&
    [ "$LATEST_INSTALLED_PROFILE" != "$CURRENT_GCC_PROFILE" ]; then
    echo "✨ Nuevo slot GCC instalado sin activar: $LATEST_INSTALLED_PROFILE"
    DETECTAR_NUEVO_GCC=1
  fi
fi

# ── Check 2: ¿Portage tiene un GCC más nuevo disponible? ──
# Esto captura tanto cambios de slot como parches menores que emerge @world
# actualizaría de todas formas.
EMERGE_PREVIEW=$(emerge -p sys-devel/gcc 2>/dev/null | grep '^\[ebuild' | grep 'sys-devel/gcc' | grep -v '\[ebuild[[:space:]]*R' | head -1 || true)

if [ -n "$EMERGE_PREVIEW" ]; then
  # Extraer versión disponible: "gcc-16.1.1_p20260718"
  AVAILABLE_GCC=$(echo "$EMERGE_PREVIEW" | grep -oP 'gcc-\S+' | head -1)
  # Extraer slot (primer número de versión, ej: 16 de gcc-16.1.1_p20260718)
  AVAILABLE_SLOT=$(echo "$AVAILABLE_GCC" | grep -oP 'gcc-\K\d+')

  if [ "$DETECTAR_NUEVO_GCC" -eq 0 ]; then
    if [ -n "$AVAILABLE_SLOT" ] && [ "$AVAILABLE_SLOT" != "$CURRENT_GCC_SLOT" ]; then
      echo "✨ Nuevo slot GCC disponible en Portage: $AVAILABLE_GCC — requiere toolchain upgrade"
      DETECTAR_NUEVO_GCC=1
    elif [ -n "$AVAILABLE_GCC" ]; then
      echo "ℹ️  Parche menor GCC disponible en Portage: $AVAILABLE_GCC (lo maneja emerge @world)"
    fi
  fi
elif [ "$DETECTAR_NUEVO_GCC" -eq 0 ]; then
  echo "✅ GCC ya está en la última versión ($CURRENT_GCC_VER)."
fi
# =====================================================================

# ─── Ejecutar actualización de GCC si se detectó cambio de slot ───
if [ "$DETECTAR_NUEVO_GCC" -eq 1 ]; then
  echo -e "\n=========================================================="
  echo "🚀 EJECUTANDO ACTUALIZACIÓN DE GCC (toolchain)"
  echo "=========================================================="

  RUTA_GCC="$HOME/.local/bin/actualiza_gcc.sh"

  if [ -f "$RUTA_GCC" ]; then
    chmod +x "$RUTA_GCC"
    # --skip-world: omitimos el @world interno porque actualizar.sh lo hará
    # tras la activación del nuevo compilador
    bash "$RUTA_GCC" --skip-world
  else
    echo "❌ ERROR: No se encontró el script actualiza_gcc.sh en: $RUTA_GCC"
    echo "   La actualización de GCC se omitirá."
  fi

  # Recargar entorno para que el resto del script vea el nuevo GCC
  source /etc/profile 2>/dev/null || true
  echo -e "==========================================================\n"
fi
# =====================================================================

# 4. Actualización @world
echo "[4/9] Aplicando actualizaciones (Optimización Zen 3)..."
set_title "emerge: @world"
# IMPORTANTE: --jobs=1 para no saturar tmpfs con múltiples paquetes pesados simultáneos
# Los hilos de compilación se manejan internamente con el -j de MAKEOPTS
sudo emerge -uDvN --with-bdeps=y --keep-going --jobs=1 --load-average="$LOAD" @world

# =====================================================================
# EJECUCIÓN AUTOMÁTICA DE KERNEL-DO
# =====================================================================
if [ "$DETECTAR_NUEVO_KERNEL" -eq 1 ]; then
  echo -e "\n=========================================================="
  echo "🚀 EJECUTANDO ACTUALIZACIÓN Y CONSOLIDACIÓN DEL KERNEL"
  echo "=========================================================="

  # Asegúrate de que esta ruta coincida con la ubicación real de tu script
  RUTA_KERNEL_DO="$HOME/.local/bin/kernel-do.sh"

  if [ -f "$RUTA_KERNEL_DO" ]; then
    chmod +x "$RUTA_KERNEL_DO"
    bash "$RUTA_KERNEL_DO"
  else
    echo "❌ ERROR: No se encontró el script kernel-do.sh en la ruta: $RUTA_KERNEL_DO"
    echo "Por favor, verifica la ubicación del archivo para automatizar el proceso."
  fi
  echo -e "==========================================================\n"
fi
# =====================================================================

# 5. Configuración
echo "[5/9] Revisando cambios en /etc..."
set_title "config"
# sudo dispatch-conf # dispatch-conf es generalmente más seguro/rápido que etc-update
sudo etc-update # revisando cambios en configuraciones con etc-update

# 6. Limpieza y Reconstrucción
echo "[6/9] Depurando sistema..."
set_title "limpieza"
sudo emerge --depclean
sudo emerge @preserved-rebuild

# 7. Mantenimiento
echo "[7/9] Limpiando distfiles y kernels..."
sudo eclean-dist --deep
# Solo eliminar si no es el kernel activo (basado en tus preferencias previas)
command -v eclean-kernel >/dev/null 2>&1 && sudo eclean-kernel -n 2

# 8. Indexación
echo "[8/9] Actualizando base de datos..."
sudo updatedb

# 9. Desmontaje
echo "[9/9] Finalizando..."
if [ "$BOOT_WAS_MOUNTED" -eq 0 ]; then
  echo "El trap de salida desmonta /boot."
else
  echo "/boot se mantendrá montado tal como estaba al inicio."
fi

set_title "$ORIGINAL_TITLE"
mark_ok
echo "🎉 ¡Sistema completamente actualizado y optimizado!"
