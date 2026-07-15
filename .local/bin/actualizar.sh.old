#!/bin/bash
set -e

set_title() {
  echo -ne "\033]0;$1\007"
}

ORIGINAL_TITLE="Terminal"
BOOT_WAS_MOUNTED=0

# Configuración balanceada para Zen 3 con 32GB RAM + tmpfs
# Bajamos de 16 a 9 para evitar desbordamiento de RAM/tmpfs
THREADS=9
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
# Usamos -v para detectar errores de configuración como el de ionice
sudo emerge --sync
eselect news list | grep -q "read" && echo "(!) Hay noticias de Gentoo sin leer."

# 3. Integridad de Portage
echo "[3/9] Verificando y reparando integridad..."
set_title "emaint"
sudo emaint --check all || sudo emaint --fix all

# =====================================================================
# DETECCIÓN DE NUEVO KERNEL (PRE-ACTUALIZACIÓN)
# =====================================================================
echo "🔍 Analizando si hay una nueva versión de gentoo-sources en camino..."
DETECTAR_NUEVO_KERNEL=0

# Simulamos la actualización para buscar específicamente 'sys-kernel/gentoo-sources'
if sudo emerge -pDuNv --with-bdeps=y @world | grep -E "sys-kernel/gentoo-sources"; then
  echo "✨ ¡Se detectó una nueva versión de gentoo-sources! Se programará kernel-do.sh al finalizar la compilación."
  DETECTAR_NUEVO_KERNEL=1
else
  echo "✅ No hay actualizaciones pendientes para las fuentes del kernel."
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
  RUTA_KERNEL_DO="/home/eleazar/kernel-do.sh"

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
# revdep-rebuild es antiguo; emerge @preserved-rebuild suele ser suficiente en sistemas modernos
command -v revdep-rebuild >/dev/null 2>&1 && sudo revdep-rebuild

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
  echo "Desmontando /boot de manera segura..."
  sudo umount /boot || echo "⚠️ No se pudo desmontar /boot automáticamente."
else
  echo "/boot se mantendrá montado tal como estaba al inicio."
fi

set_title "$ORIGINAL_TITLE"
echo "🎉 ¡Sistema completamente actualizado y optimizado!"
