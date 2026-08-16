#!/bin/bash
set -e
set -o pipefail

# =====================================================================
# actualiza_gcc.sh — Actualización segura de GCC en Gentoo Linux
# Basado en: https://wiki.gentoo.org/wiki/Upgrading_GCC/en
# =====================================================================

echo -e "\n=========================================================="
echo "   ACTUALIZACIÓN DE GCC (toolchain)"
echo "=========================================================="

SKIP_WORLD=false
if [ "${1:-}" = "--skip-world" ]; then
  SKIP_WORLD=true
  echo "  Modo: solo toolchain (sin rebuild @world)"
fi

# ─── 0. Verificar que gcc-config exista ───
if ! command -v gcc-config &>/dev/null; then
  echo "❌ gcc-config no está instalado. No se puede continuar."
  echo "   Instálelo con: sudo emerge -1 sys-devel/gcc-config"
  exit 1
fi

# ─── 1. Detectar perfil activo y nuevo ───
CURRENT_GCC=$(gcc-config -c 2>/dev/null || true)

# Lista de perfiles sin el asterisco de activo — ordenamos por versión
LATEST_GCC=$(gcc-config --list-profiles 2>/dev/null | grep -oP '\[\d+\]\s+\K\S+' | sort -V | tail -1)

if [ -z "$LATEST_GCC" ]; then
  echo "⚠️  No se encontraron perfiles de GCC en gcc-config."
  echo "   ¿Ejecutaste 'emerge -1 sys-devel/gcc' primero?"
  exit 1
fi

if [ "$LATEST_GCC" = "$CURRENT_GCC" ]; then
  echo "✅ GCC ya está en la última versión instalada y activa ($CURRENT_GCC)."
  exit 0
fi

echo "  ➜  Actual:  $CURRENT_GCC"
echo "  ➜  Nuevo:   $LATEST_GCC"

# ─── 2. Actualizar herramientas base y cabeceras ───
echo -e "\n[1/4] Instalando linux-headers y gcc..."
sudo emerge -v1 sys-kernel/linux-headers sys-devel/gcc

# ─── 3. Seleccionar nuevo compilador con gcc-config ───
echo -e "\n[2/4] Activando $LATEST_GCC con gcc-config..."

# Extraemos el número del perfil [N] de la línea que contiene el nuevo perfil
LATEST_LINE=$(gcc-config --list-profiles 2>/dev/null | grep "$LATEST_GCC" | head -1)
LATEST_NUM=$(echo "$LATEST_LINE" | grep -oP '\[\K\d+' || true)

if [ -z "$LATEST_NUM" ]; then
  echo "❌ No se pudo determinar el número del perfil $LATEST_GCC."
  echo "   Perfiles disponibles:"
  gcc-config --list-profiles
  exit 1
fi

sudo gcc-config "$LATEST_NUM"
sudo env-update
source /etc/profile
echo "  ✅ Activado perfil $LATEST_NUM: $LATEST_GCC"

# ─── 4. Reconstruir toolchain con el nuevo compilador ───
echo -e "\n[3/4] Reconstruyendo toolchain (glibc + binutils + libtool)..."
sudo emerge -v1 sys-libs/glibc sys-devel/binutils dev-build/libtool

# ─── 5. Reconstruir @world (solo si NO se pasó --skip-world) ───
if [ "$SKIP_WORLD" = false ]; then
  echo -e "\n[4/4] Reconstruyendo @world con el nuevo compilador..."
  echo "  (excluyendo linux-headers, gcc, glibc, binutils — ya actualizados)"
  sudo emerge -auvND @world --exclude 'sys-kernel/linux-headers sys-devel/gcc sys-libs/glibc sys-devel/binutils'

  # ─── 6. Limpieza ───
  echo -e "\n  Limpiando... (depclean + preserved-rebuild)"
  sudo emerge --depclean
  sudo emerge @preserved-rebuild
else
  echo -e "\n  → --skip-world activo: @world se reconstruirá desde actualizar.sh"
fi

echo -e "\n=========================================================="
echo "   ✅ ACTUALIZACIÓN DE GCC COMPLETADA"
echo "   Compilador activo: $(gcc --version | head -1)"
echo "=========================================================="
