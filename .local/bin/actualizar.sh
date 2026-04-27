#!/bin/bash
set -e

set_title() {
  echo -ne "\033]0;$1\007"
}

ORIGINAL_TITLE="Terminal"
BOOT_WAS_MOUNTED=0

echo "=========================================================="
echo "   INICIANDO ACTUALIZACIÓN Y OPTIMIZACIÓN GENTOO (Zen 3)  "
echo "=========================================================="

# 1. Montaje inteligente de /boot
if mountpoint -q /boot; then
  echo "[1/10] /boot ya está montado."
  BOOT_WAS_MOUNTED=1
else
  echo "[1/9] Montando partición /boot..."
  sudo mount /boot
fi

# 2. Sincronización y Noticias
echo "[2/9] Sincronizando repositorios y revisando noticias..."
set_title "sync"
sudo emerge --sync --quiet
# Verificar si hay noticias críticas antes de proceder
eselect news list | grep -q "read" && echo "(!) Hay noticias de Gentoo sin leer. Revísalas con 'eselect news read'."

# 3. Limpieza de integridad
echo "[3/9] Verificando integridad de Portage..."
set_title "emaint"
sudo emaint --check all
sudo emaint --fix all

# 4. Actualización de @world
echo "[4/9] Aplicando actualizaciones de @world..."
set_title "emerge: @world"
# Añadido --keep-going para que no se detenga por un solo fallo
sudo emerge -uDvN --with-bdeps=y --keep-going @world

# 5. Gestión de configuración
echo "[5/9] Revisando cambios en /etc..."
set_title "config"
sudo etc-update

# 6. Limpieza y Reconstrucción
echo "[6/9] Depurando sistema y reconstruyendo librerías..."
set_title "limpieza"
sudo emerge --depclean
sudo emerge @preserved-rebuild
sudo revdep-rebuild

# 7. Mantenimiento de Kernel y Cache
echo "[7/9] Limpiando distfiles y kernels antiguos..."
sudo eclean-dist --deep
# Solo intenta eclean-kernel si la herramienta está instalada
command -v eclean-kernel >/dev/null 2>&1 && sudo eclean-kernel -n 2

# 8. Indexación
echo "[8/9] Actualizando base de datos de búsqueda..."
sudo updatedb

# 9. Finalización y Desmontaje
echo "[9/9] Finalizando proceso..."
if [ "$BOOT_WAS_MOUNTED" -eq 0 ]; then
  sudo umount /boot && echo "/boot desmontado con éxito."
fi

set_title "$ORIGINAL_TITLE"

echo "=========================================================="
echo "   ¡SISTEMA ACTUALIZADO, LIMPIO Y OPTIMIZADO CON ÉXITO!   "
echo "=========================================================="
