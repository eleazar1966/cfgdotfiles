#!/bin/bash
set -e

# Configuración de rutas (Basadas en tu script anterior)
BACKUP_DIR="/home/eleazar/.config/kernel_backups"
CONFIG_MAESTRA="$BACKUP_DIR/last_working_config"
DIR_FUENTES="/usr/src/linux"

mkdir -p "$BACKUP_DIR"

echo -e "\n=== Iniciando Actualización y Consolidación de Kernel (Optimizado para Zen 3) ===\n"

# 1. Gestión de espacio y montaje de /boot
if ! mountpoint -q /boot; then
  echo "🔹 Montando /boot..."
  sudo mount /dev/nvme0n1p1 /boot
fi

echo "🔹 Liberando espacio preventivo en /boot..."
sudo rm -f /boot/*.old /boot/initramfs*.old

# 2. Respaldo o Migración Inicial de Configuración
if [ -f "$DIR_FUENTES/.config" ]; then
  echo "🔹 Respaldando configuración actual del directorio activo..."
  cp "$DIR_FUENTES/.config" "$CONFIG_MAESTRA"
elif [ ! -f "$CONFIG_MAESTRA" ]; then
  echo "🔍 No hay configuración previa en $CONFIG_MAESTRA. Buscando kernel-dist original..."
  CONFIG_DETECTADA=$(ls -vt /boot/config-*-gentoo-dist 2>/dev/null | head -n 1)

  if [ -z "$CONFIG_DETECTADA" ]; then
    CONFIG_DETECTADA=$(ls -vt /boot/config-* 2>/dev/null | head -n 1)
  fi

  if [ -n "$CONFIG_DETECTADA" ] && [ -f "$CONFIG_DETECTADA" ]; then
    echo "✅ Se detectó la configuración base de distribución: $CONFIG_DETECTADA"
    cp "$CONFIG_DETECTADA" "$CONFIG_MAESTRA"
  else
    echo "⚠️  Intentando extraer la configuración del kernel en ejecución (/proc/config.gz)..."
    if [ -f /proc/config.gz ]; then
      zcat /proc/config.gz >"$CONFIG_MAESTRA"
    else
      echo "❌ Error: No se encontró ninguna configuración base en /boot ni en /proc/config.gz"
      exit 1
    fi
  fi
fi

# 3. Sincronización de fuentes de gentoo-sources
echo "🔹 Actualizando gentoo-sources de forma limpia..."
sudo rm -rf /usr/src/*
sudo emerge sys-kernel/gentoo-sources

# 4. Selección dinámica de la versión más reciente (gentoo-sources)
K_INDEX=$(eselect kernel list | grep -oP '\[\K\d+(?=\])' | sort -rn | head -n1)

if [ -n "$K_INDEX" ]; then
  echo "🔹 Seleccionando kernel índice de eselect: $K_INDEX"
  sudo eselect kernel set "$K_INDEX"
else
  echo "❌ Error: No se detectaron fuentes en /usr/src después del emerge."
  exit 1
fi

cd "$DIR_FUENTES"

# 5. Preparación y Actualización de la Configuración (.config)
echo "🔹 Aplicando configuración guardada..."
sudo cp "$CONFIG_MAESTRA" .config
sudo make olddefconfig

# 6. Configuración Manual (Activa BRIDGE y NAT para Blueman aquí si es necesario)
echo "🔹 Abriendo menuconfig para ajustes personalizados..."
sudo make menuconfig

# Resguardamos inmediatamente los cambios hechos en menuconfig para las sucesivas versiones
cp .config "$CONFIG_MAESTRA"

# 7. Compilación con optimización nativa Cezanne (Zen 3)
echo "🚀 Compilando para Ryzen 7 5700G con $(nproc) hilos..."
sudo make KCFLAGS="-march=znver3 -O3 -pipe" -j$(nproc)

# 8. Instalación del nuevo Kernel personalizado
echo "🔹 Instalando módulos y binarios del kernel..."
sudo make modules_install
sudo make install
sudo rm -f /boot/*.old /boot/initramfs*.old

if command -v eclean-kernel &>/dev/null; then
  sudo eclean-kernel -n 2
fi

# 9. Initramfs y GRUB
echo "🔹 Generando Initramfs y actualizando GRUB..."
sudo dracut --force
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 10. Desinstalación automatizada del Kernel de Distribución (-dist)
echo -e "\n=== Verificación de Remoción de Kernel-Dist ==="
PAQUETE_DIST=""
if qlist -I sys-kernel/gentoo-kernel-bin &>/dev/null; then
  PAQUETE_DIST="sys-kernel/gentoo-kernel-bin"
elif qlist -I sys-kernel/gentoo-kernel &>/dev/null; then
  PAQUETE_DIST="sys-kernel/gentoo-kernel"
fi

if [ -n "$PAQUETE_DIST" ]; then
  echo "⚠️  Se detectó el paquete original: $PAQUETE_DIST"
  read -p "¿Deseas desinstalarlo ahora para mantener solo tus gentoo-sources? (s/N): " responder
  if [[ "$responder" == "s" || "$responder" == "S" ]]; then
    echo "🔹 Removiendo $PAQUETE_DIST de Portage..."
    sudo emerge --unmerge "$PAQUETE_DIST"
    echo "🔹 Limpiando dependencias del sistema..."
    sudo emerge --depclean
    echo "✅ El kernel de distribución ha sido eliminado."
  fi
else
  echo "✅ No quedan kernels de distribución (-dist) pendientes por remover."
fi

# 11. Finalización y Desmontaje
cd ~
sudo umount /boot
echo -e "\n🎉 ¡Proceso completado exitosamente! Tu configuración se mantendrá intacta para las siguientes versiones en: $CONFIG_MAESTRA\n"
