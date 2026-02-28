#!/bin/bash
set -e

# Función para cambiar el título de la terminal actual
set_title() {
  echo -ne "\033]0;$1\007"
}

# Guardar título original
ORIGINAL_TITLE="Terminal"

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

# 2. Verificación de integridad y limpieza profunda
echo "[2/9] Limpiando índices de binarios y sesiones previas..."
set_title "limpieza"

# Crear directorio y archivos de índice vacíos (silencia errores de Packages/Packages.gz)
sudo mkdir -p /var/cache/binpkgs
sudo touch /var/cache/binpkgs/Packages
echo -n "" | sudo gzip -c >/tmp/Packages.gz
sudo mv /tmp/Packages.gz /var/cache/binpkgs/Packages.gz

# Limpieza total de archivos de 'resume' para evitar mensajes de paquetes pendientes
sudo rm -f /var/cache/edb/resume /var/cache/edb/resume_backup

# Verificación de integridad de Portage
sudo emaint --check all
sudo emaint --fix all

# 3. Sincronización
echo "[3/9] Sincronizando repositorios de Portage..."
set_title "emerge"
sudo emerge --sync --quiet

# 4. Actualización de @world
echo "[4/9] Calculando y aplicando actualizaciones de @world..."
sudo emerge -uDvN --with-bdeps=y @world

# 5. Gestión de archivos de configuración
set_title "actualizar.sh"
echo "[5/9] Revisando cambios en archivos de configuración (/etc)..."
# Sustitución de dispatch-conf por etc-update
sudo etc-update

# 6. Limpieza de dependencias y reconstrucción
set_title "emerge"
echo "[6/9] Limpiando dependencias huérfanas (--depclean)..."
sudo emerge --depclean
echo "[6.1/9] Reconstruyendo paquetes con librerías preservadas..."
sudo emerge @preserved-rebuild
echo "[6.2/9] Buscando binarios con enlaces rotos (revdep-rebuild)..."
sudo revdep-rebuild

# 7. Mantenimiento de Kernel y Distfiles
echo "[7/9] Limpiando fuentes de paquetes antiguos (distfiles)..."
sudo eclean-dist --deep
echo "[7.1/9] Limpiando kernels antiguos (manteniendo los últimos 2)..."
sudo eclean-kernel -n 2

# 8. Indexación de archivos
set_title "actualizar.sh"
echo "[8/9] Actualizando base de datos de búsqueda rápida (locate)..."
sudo updatedb

# 9. Finalización
echo "[9/9] Desmontando /boot y finalizando..."
sudo umount /boot

set_title "$ORIGINAL_TITLE"

echo "=========================================================="
echo "   ¡SISTEMA ACTUALIZADO, LIMPIO Y OPTIMIZADO CON ÉXITO!   "
echo "=========================================================="
