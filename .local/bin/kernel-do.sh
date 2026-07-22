#!/bin/bash
set -e

# Configuración de rutas
BACKUP_DIR="$HOME/.config/kernel_backups"
CONFIG_MAESTRA="$BACKUP_DIR/last_working_config"
DIR_FUENTES="/usr/src/linux"

# Flag para saltar menuconfig (útil en ejecución automática/no-interactiva)
SKIP_MENUCONFIG=0
[ "$1" = "--no-menuconfig" ] && SKIP_MENUCONFIG=1

mkdir -p "$BACKUP_DIR"

echo -e "\n=== Iniciando Actualización y Consolidación de Kernel (Optimizado para Zen 3) ===\n"

# 1. Montaje de /boot (recordar estado original)
BOOT_WAS_MOUNTED=0
if mountpoint -q /boot; then
  echo "🔹 /boot ya está montado."
  BOOT_WAS_MOUNTED=1
else
  echo "🔹 Montando /boot..."
  sudo mount /boot
fi

echo "🔹 Liberando espacio preventivo en /boot..."
sudo rm -f /boot/*.old /boot/initramfs*.old

# 2. Identificar la última versión de gentoo-sources ya instalada
echo "🔹 Identificando última versión de gentoo-sources instalada..."
LATEST_SRC=$(ls -1d /usr/src/linux-*-gentoo 2>/dev/null | sort -V | tail -1)

if [ -z "$LATEST_SRC" ]; then
  echo "❌ Error: No se encontraron fuentes de kernel en /usr/src/."
  echo "   Ejecute: sudo emerge sys-kernel/gentoo-sources"
  exit 1
fi

NEW_SRC_BASENAME=$(basename "$LATEST_SRC")
echo "   ✅ Fuentes detectadas: $NEW_SRC_BASENAME"

# 3. Seleccionar el nuevo kernel con eselect
K_INDEX=$(eselect kernel list | grep -F "$NEW_SRC_BASENAME" | grep -oP '\[\K\d+(?=\])' | head -1)

if [ -n "$K_INDEX" ]; then
  echo "🔹 Seleccionando kernel índice $K_INDEX → $NEW_SRC_BASENAME..."
  sudo eselect kernel set "$K_INDEX"
else
  echo "❌ Error: No se pudo seleccionar $NEW_SRC_BASENAME en eselect."
  eselect kernel list
  exit 1
fi

cd "$DIR_FUENTES"

# 4. Config: restaurar la última configuración funcional
if [ -f "$CONFIG_MAESTRA" ]; then
  echo "🔹 Usando configuración respaldada: $CONFIG_MAESTRA"
  sudo cp "$CONFIG_MAESTRA" .config
elif [ -f /proc/config.gz ]; then
  echo "🔹 Extrayendo configuración del kernel en ejecución (/proc/config.gz)..."
  zcat /proc/config.gz | sudo tee .config > /dev/null
else
  echo "❌ Error: No se encontró configuración en $CONFIG_MAESTRA ni en /proc/config.gz."
  exit 1
fi

echo "🔹 Actualizando configuración a la nueva versión del kernel..."
sudo make olddefconfig

# 5. Opcional: menuconfig (saltear en automático con --no-menuconfig)
if [ "$SKIP_MENUCONFIG" -eq 1 ]; then
  echo "🔹 Saltando menuconfig (modo automático)."
else
  echo "🔹 Abriendo menuconfig para ajustes personalizados..."
  sudo make menuconfig
fi

# Resguardar configuración inmediatamente
sudo cp .config "$CONFIG_MAESTRA"
echo "✅ Configuración respaldada en $CONFIG_MAESTRA"

# 6. Compilación optimizada para Zen 3 (Cezanne)
echo "🚀 Compilando para Ryzen 7 5700G con $(nproc) hilos..."
echo "   Flags: -march=znver3 -O3 -pipe"
sudo make KCFLAGS="-march=znver3 -O3 -pipe" -j$(nproc)

# 7. Instalación de módulos y binarios del kernel
echo "🔹 Instalando módulos del kernel..."
sudo make modules_install
echo "🔹 Instalando binarios del kernel..."
sudo make install
sudo rm -f /boot/*.old /boot/initramfs*.old

# 8. Limpiar kernels antiguos (mantener solo los 2 más recientes)
if command -v eclean-kernel &>/dev/null; then
  echo "🔹 Limpiando kernels antiguos del disco..."
  sudo eclean-kernel -n 2
fi

# 9. Eliminar fuentes de kernels anteriores (dejar solo la nueva)
echo "🔹 Eliminando fuentes de kernels anteriores..."
for dir in /usr/src/linux-*-gentoo; do
  if [ -d "$dir" ] && [ "$(basename "$dir")" != "$NEW_SRC_BASENAME" ]; then
    echo "   🗑  Eliminando: $(basename "$dir")"
    sudo rm -rf "$dir"
  fi
done

# 10. Initramfs y GRUB
echo "🔹 Generando Initramfs..."
sudo dracut --force
echo "🔹 Actualizando GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 11. Desmontaje condicional de /boot
if [ "$BOOT_WAS_MOUNTED" -eq 0 ]; then
  echo "🔹 Desmontando /boot..."
  sudo umount /boot
else
  echo "🔹 /boot se mantiene montado (ya lo estaba al iniciar)."
fi

cd ~
echo -e "\n🎉 ¡Proceso completado exitosamente!"
echo "   ✔ Nuevo kernel: $NEW_SRC_BASENAME"
echo "   ✔ Configuración respaldada en: $CONFIG_MAESTRA"
echo "   ✔ Versiones anteriores eliminadas de /usr/src/ y /boot"
echo ""
echo "   ⚡  Para usar el nuevo kernel, ejecute: sudo reboot"
