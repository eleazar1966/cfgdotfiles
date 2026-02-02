#!/bin/bash
set -e

echo "=========================================================="
echo "   INICIANDO ACTUALIZACIÓN Y OPTIMIZACIÓN GENTOO (Zen 3)  "
echo "=========================================================="

# 1. Montaje seguro de /boot
if ! mountpoint -q /boot; then
  echo "[1/9] Montando partición /boot..."
  sudo mount /boot
else
  echo "[1/9] /boot ya está montado."
fi

# 2. Sincronización
echo "[2/9] Sincronizando repositorios de Portage..."
sudo emerge --sync --quiet

# 3. Actualización de @world
echo "[3/9] Calculando y aplicando actualizaciones de @world..."
echo "      (Esto puede tomar tiempo dependiendo de los paquetes)"
sudo emerge -uDvN --with-bdeps=y @world

# 4. Gestión de archivos de configuración
echo "[4/9] Revisando cambios en archivos de configuración (/etc)..."
echo "      (Usa 'u' para actualizar, 'z' para descartar)"
sudo dispatch-conf

# 5. Limpieza de dependencias y reconstrucción
echo "[5/9] Limpiando dependencias huérfanas (--depclean)..."
sudo emerge --depclean
echo "[5.1/9] Reconstruyendo paquetes con librerías preservadas..."
sudo emerge @preserved-rebuild
echo "[5.2/9] Buscando binarios con enlaces rotos (revdep-rebuild)..."
sudo revdep-rebuild

# 6. Mantenimiento de Kernel y Distfiles
echo "[6/9] Limpiando fuentes de paquetes antiguos (distfiles)..."
sudo eclean-dist --deep
echo "[6.1/9] Limpiando kernels antiguos (manteniendo los últimos 3)..."
sudo eclean-kernel -n 22
# 7. Optimización y Salud de BTRFS
# echo "[7/9] Iniciando verificación de salud BTRFS (Scrub)..."
# sudo btrfs scrub start -B /
# echo "[7.1/9] Desfragmentando metadatos de Portage y Distfiles..."
# sudo btrfs filesystem defragment -r /var/db/repos/gentoo
# sudo btrfs filesystem defragment -r /var/cache/distfiles

# 8. Indexación de archivos
echo "[8/9] Actualizando base de datos de búsqueda rápida (locate)..."
sudo updatedb

# 9. Finalización
echo "[9/9] Desmontando /boot y finalizando..."
sudo umount /boot

echo "=========================================================="
echo "   ¡SISTEMA ACTUALIZADO, LIMPIO Y OPTIMIZADO CON ÉXITO!   "
echo "=========================================================="
