#!/bin/bash

# Colores para una interfaz de usuario limpia y legible
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RED='\e[31m'
BOLD='\e[1m'
NC='\e[0m' # Sin color

# Limpiar pantalla y mostrar el encabezado
clear
echo -e "${BLUE}${BOLD}====================================================${NC}"
echo -e "${BLUE}${BOLD}      CREADOR INTERACTIVO DE MÁQUINAS VIRTUALES     ${NC}"
echo -e "${BLUE}${BOLD}                 QEMU / KVM + UEFI                  ${NC}"
echo -e "${BLUE}${BOLD}====================================================${NC}\n"

# 1. Verificar dependencias necesarias en el sistema
echo -e "${BLUE}[*] Verificando dependencias en el sistema...${NC}"
DEPENDENCIAS=("qemu-system-x86_64" "qemu-img")
for dep in "${DEPENDENCIAS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    echo -e "${RED}[ERROR] No se encontró '$dep'. Por favor, instálalo antes de continuar.${NC}"
    exit 1
  fi
done
echo -e "${GREEN}[OK] QEMU y herramientas de disco listas.${NC}\n"

# 2. Detección automática de Firmware UEFI (OVMF)
OVMF_CODE_PATHS=(
  "/usr/share/OVMF/OVMF_CODE.fd"
  "/usr/share/OVMF/OVMF_CODE_4M.fd"
  "/usr/share/edk2/x64/OVMF_CODE.fd"
  "/usr/share/edk2-ovmf/OVMF_CODE.fd"
)

OVMF_VARS_PATHS=(
  "/usr/share/OVMF/OVMF_VARS.fd"
  "/usr/share/OVMF/OVMF_VARS_4M.fd"
  "/usr/share/edk2/x64/OVMF_VARS.fd"
  "/usr/share/edk2-ovmf/OVMF_VARS.fd"
)

DETECTED_UEFI_CODE=""
DETECTED_UEFI_VARS=""

for path in "${OVMF_CODE_PATHS[@]}"; do
  if [ -f "$path" ]; then
    DETECTED_UEFI_CODE="$path"
    break
  fi
done

for path in "${OVMF_VARS_PATHS[@]}"; do
  if [ -f "$path" ]; then
    DETECTED_UEFI_VARS="$path"
    break
  fi
done

# 3. Selección del directorio de las ISOs y del archivo ISO
echo -e "${BLUE}[*] Configuración del directorio de las ISOs${NC}"
echo -e "Selecciona una ubicación predeterminada o ingresa una personalizada:"
echo -e "  1) ~/Downloads"
echo -e "  2) /mnt/ssd/ISOS/"
echo -e "  3) Introducir otra ruta personalizada"
read -rp "Selecciona una opción [1-3] [Por defecto: 1]: " ISO_DIR_OPT
ISO_DIR_OPT="${ISO_DIR_OPT:-1}"

case "$ISO_DIR_OPT" in
  2)
    ISO_DIR="/mnt/ssd/ISOS"
    ;;
  3)
    read -rp "Ingresa la ruta personalizada de tus ISOs: " ISO_DIR
    ;;
  *)
    ISO_DIR="$HOME/Downloads"
    ;;
esac

# Expandir la virgulilla (~) a la ruta del Home si es necesario
ISO_DIR="${ISO_DIR/#\~/$HOME}"

# Comprobar si el directorio existe
if [ ! -d "$ISO_DIR" ]; then
  echo -e "${YELLOW}[!] El directorio '$ISO_DIR' no existe. ¿Deseas crearlo o usar otra ruta?${NC}"
  echo -e "  1) Crear el directorio automáticamente"
  echo -e "  2) Introducir otra ruta de directorio manualmente"
  read -rp "Selecciona una opción [1-2]: " ISO_DIR_ERR_OPT
  if [ "$ISO_DIR_ERR_OPT" = "2" ]; then
    read -rp "Ingresa la ruta correcta del directorio de tus ISOs: " ISO_DIR
    ISO_DIR="${ISO_DIR/#\~/$HOME}"
  else
    mkdir -p "$ISO_DIR"
    echo -e "${GREEN}[OK] Directorio creado en: $ISO_DIR${NC}"
  fi
fi

# Buscar archivos .iso en el directorio seleccionado
mapfile -t ISO_LIST < <(find "$ISO_DIR" -maxdepth 1 -name "*.iso" 2>/dev/null)

if [ ${#ISO_LIST[@]} -eq 0 ]; then
  echo -e "${YELLOW}[!] No se encontraron archivos .iso en '$ISO_DIR'.${NC}"
  read -rp "Ingresa manualmente la ruta completa de tu archivo ISO: " ISO_PATH
  ISO_PATH="${ISO_PATH/#\~/$HOME}"
  while [ ! -f "$ISO_PATH" ]; do
    echo -e "${RED}[ERROR] El archivo no existe o la ruta ingresada es inválida.${NC}"
    read -rp "Por favor, ingresa una ruta de ISO válida: " ISO_PATH
    ISO_PATH="${ISO_PATH/#\~/$HOME}"
  done
else
  echo -e "\n${BLUE}ISOs disponibles en $ISO_DIR:${NC}"
  for i in "${!ISO_LIST[@]}"; do
    echo -e "  ${GREEN}[$((i + 1))]${NC} $(basename "${ISO_LIST[$i]}")"
  done
  echo -e "  ${GREEN}[0]${NC} Introducir manualmente otra ruta de archivo ISO"

  while true; do
    read -rp "Selecciona una opción (introduce el número correspondiente): " ISO_OPT
    if [[ "$ISO_OPT" =~ ^[0-9]+$ ]]; then
      if [ "$ISO_OPT" -eq 0 ]; then
        read -rp "Ingresa la ruta completa del archivo ISO: " ISO_PATH
        ISO_PATH="${ISO_PATH/#\~/$HOME}"
        while [ ! -f "$ISO_PATH" ]; do
          echo -e "${RED}[ERROR] Archivo no encontrado.${NC}"
          read -rp "Ingresa una ruta de ISO válida: " ISO_PATH
          ISO_PATH="${ISO_PATH/#\~/$HOME}"
        done
        break
      elif [ "$ISO_OPT" -le "${#ISO_LIST[@]}" ] && [ "$ISO_OPT" -gt 0 ]; then
        ISO_PATH="${ISO_LIST[$((ISO_OPT - 1))]}"
        break
      fi
    fi
    echo -e "${RED}[ERROR] Opción no válida. Inténtalo de nuevo.${NC}"
  done
fi
echo -e "${GREEN}[OK] ISO seleccionada: $(basename "$ISO_PATH")${NC}\n"

# 4. Determinar el Tipo de Ejecución (Live vs Instalación)
echo -e "${BLUE}[*] Selección del modo de ejecución${NC}"
echo -e "Elige cómo deseas iniciar esta ISO:"
echo -e "  1) Modo Live / Prueba (Arranca la ISO directamente, sin crear discos ni guardar cambios)"
echo -e "  2) Modo Instalación (Crea directorio de máquina, disco duro virtual y scripts de arranque)"
read -rp "Selecciona opción [1-2] [Por defecto: 1]: " EXEC_MODE
EXEC_MODE="${EXEC_MODE:-1}"

# Auto-obtención del nombre de VM más corto y limpio posible basado en la ISO
ISO_FILENAME=$(basename "$ISO_PATH" .iso)
SUGGESTED_NAME=$(echo "$ISO_FILENAME" | sed -E 's/-(x86_64|amd64|desktop|live|minimal|netinst|dvd|minimal-netinst|64bit).*//i' | sed 's/[^a-zA-Z0-9_-]//g')

# 5. Configuración de hardware común (RAM, CPU, Firmware)
echo -e "\n${BLUE}[*] Configuración de hardware${NC}"
read -rp "Memoria RAM (ejemplo: 2G, 4G, 4096M) [Por defecto: 4G]: " VM_RAM
VM_RAM="${VM_RAM:-4G}"

HOST_CORES=$(nproc)
read -rp "Núcleos de CPU (Máximos en tu host: $HOST_CORES) [Por defecto: 2]: " VM_CORES
VM_CORES="${VM_CORES:-2}"

echo -e "\nSelecciona el tipo de firmware (arranque) para la VM:"
echo -e "  1) BIOS clásica (Legacy - Recomendada para sistemas antiguos)"
echo -e "  2) UEFI moderno (Recomendada para sistemas de 64 bits modernos)"
read -rp "Selección [1-2] [Por defecto: 1]: " FW_OPT
FW_OPT="${FW_OPT:-1}"

BOOT_TYPE="bios"
if [ "$FW_OPT" = "2" ]; then
  if [ -n "$DETECTED_UEFI_CODE" ] && [ -n "$DETECTED_UEFI_VARS" ]; then
    BOOT_TYPE="uefi"
    echo -e "${GREEN}[OK] Firmware UEFI detectado en el sistema.${NC}"
  else
    echo -e "${RED}[ADVERTENCIA] No se detectó el paquete OVMF (UEFI) en tu sistema operativo.${NC}"
    echo -e "Se forzará el uso de BIOS clásica para evitar fallos de ejecución."
    BOOT_TYPE="bios"
  fi
fi

# Comprobación del soporte para KVM
KVM_SUPPORT="n"
if [ -e /dev/kvm ]; then
  KVM_SUPPORT="y"
fi

# ==================== RAMIFICACIÓN DE LOS MODOS ====================

if [ "$EXEC_MODE" = "1" ]; then
  # --- MODO LIVE: EJECUCIÓN DIRECTA ---
  echo -e "\n${GREEN}[*] Iniciando en Modo Live. No se crearán archivos ni carpetas.${NC}"

  ARGS=(
    -name "live_${SUGGESTED_NAME}"
    -m "$VM_RAM"
    -smp "$VM_CORES"
    -vga virtio
    -display default,show-cursor=on
    -device qemu-xhci
    -device usb-tablet
    -device intel-hda
    -device hda-duplex
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0,romfile=
    -drive "file=$ISO_PATH,media=cdrom,readonly=on,if=none,id=cd0"
    -device "ide-cd,drive=cd0,bootindex=1"
  )

  if [ "$KVM_SUPPORT" = "y" ]; then
    ARGS+=(-enable-kvm -cpu host)
  else
    ARGS+=(-cpu max)
  fi

  TEMP_VARS=""
  if [ "$BOOT_TYPE" = "uefi" ]; then
    TEMP_VARS=$(mktemp /tmp/uefi_vars_XXXXXX.fd)
    cp "$DETECTED_UEFI_VARS" "$TEMP_VARS"
    ARGS+=(
      -drive "if=pflash,format=raw,readonly=on,file=$DETECTED_UEFI_CODE"
      -drive "if=pflash,format=raw,file=$TEMP_VARS"
    )
  fi

  echo -e "${BLUE}Ejecutando QEMU de forma inmediata...${NC}"
  qemu-system-x86_64 "${ARGS[@]}"

  [ -n "$TEMP_VARS" ] && rm -f "$TEMP_VARS"
  exit 0

else
  # --- MODO INSTALACIÓN: CREACIÓN DE DISCOS Y SCRIPTS ---
  echo -e "\n${BLUE}[*] Configuración de Instalación Permanente${NC}"

  read -rp "Nombre de la Máquina Virtual [Sugerido: $SUGGESTED_NAME]: " VM_NAME
  VM_NAME="${VM_NAME:-$SUGGESTED_NAME}"
  VM_NAME=$(echo "$VM_NAME" | sed 's/[^a-zA-Z0-9_-]//g')

  VM_DIR="$HOME/qemu_vms/$VM_NAME"
  read -rp "Directorio de destino para almacenar la VM [Por defecto: $VM_DIR]: " USER_VM_DIR
  if [ -n "$USER_VM_DIR" ]; then
    VM_DIR="${USER_VM_DIR/#\~/$HOME}"
  fi

  echo -e "\nFormatos de disco virtual disponibles:"
  echo -e "  1) qcow2 (Recomendado: tamaño dinámico, soporta snapshots)"
  echo -e "  2) raw (Rendimiento plano, reserva todo el espacio de inmediato)"
  read -rp "Selecciona el formato de disco [1-2] [Por defecto: 1]: " FORMAT_OPT
  case "$FORMAT_OPT" in
    2) DISK_FORMAT="raw" ;;
    *) DISK_FORMAT="qcow2" ;;
  esac

  read -rp "Tamaño del disco duro virtual (ejemplo: 20G, 40G) [Por defecto: 20G]: " DISK_SIZE
  DISK_SIZE="${DISK_SIZE:-20G}"

  echo -e "\n${BLUE}[*] Preparando almacenamiento y ficheros de sistema...${NC}"
  mkdir -p "$VM_DIR"
  DISK_PATH="$VM_DIR/${VM_NAME}.${DISK_FORMAT}"

  if [ -f "$DISK_PATH" ]; then
    echo -e "${YELLOW}[!] Ya existe un disco duro en '$DISK_PATH'. ¿Deseas reemplazarlo? (¡Perderás los datos!)${NC}"
    read -rp "¿Sobrescribir disco virtual? [s/N]: " REEMPLAZAR_DISCO
    if [[ "$REEMPLAZAR_DISCO" =~ ^[sS]$ ]]; then
      rm -f "$DISK_PATH"
      qemu-img create -f "$DISK_FORMAT" "$DISK_PATH" "$DISK_SIZE"
    else
      echo -e "${GREEN}[*] Usando el disco duro existente.${NC}"
    fi
  else
    qemu-img create -f "$DISK_FORMAT" "$DISK_PATH" "$DISK_SIZE"
  fi

  VM_VARS=""
  if [ "$BOOT_TYPE" = "uefi" ]; then
    VM_VARS="$VM_DIR/${VM_NAME}_VARS.fd"
    if [ ! -f "$VM_VARS" ]; then
      cp "$DETECTED_UEFI_VARS" "$VM_VARS"
      echo -e "${GREEN}[OK] NVRAM privada creada para guardar la configuración UEFI de la VM.${NC}"
    fi
  fi

  # Rutas para los dos scripts independientes
  INSTALL_SCRIPT="$VM_DIR/install_${VM_NAME}.sh"
  BOOT_SCRIPT="$VM_DIR/boot_${VM_NAME}.sh"

  # ==================== SCRIPT 1: INSTALADOR (CON ISO) ====================
  echo -e "${BLUE}[*] Escribiendo cargador de instalación en: $INSTALL_SCRIPT${NC}"
  cat <<EOF >"$INSTALL_SCRIPT"
#!/bin/bash

VM_NAME="$VM_NAME"
VM_DIR="$VM_DIR"
DISK_PATH="$DISK_PATH"
DISK_FORMAT="$DISK_FORMAT"
ISO_PATH="$ISO_PATH"
VM_RAM="$VM_RAM"
VM_CORES="$VM_CORES"
KVM_SUPPORT="$KVM_SUPPORT"
BOOT_TYPE="$BOOT_TYPE"
UEFI_CODE="$DETECTED_UEFI_CODE"
VM_VARS="$VM_VARS"

clear
echo "=========================================================="
echo "      Iniciando VM en Modo Instalador: \$VM_NAME"
echo "=========================================================="
echo "Se arrancará prioritariamente desde la ISO seleccionada."

ARGS=(
    -name "\$VM_NAME"
    -m "\$VM_RAM"
    -smp "\$VM_CORES"
    -vga virtio
    -display default,show-cursor=on
    -device qemu-xhci
    -device usb-tablet
    -device intel-hda
    -device hda-duplex
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0,romfile=
    -drive "file=\$DISK_PATH,format=\$DISK_FORMAT,if=none,id=hd0"
    -device "virtio-blk-pci,drive=hd0,bootindex=2"
    -drive "file=\$ISO_PATH,media=cdrom,readonly=on,if=none,id=cd0"
    -device "ide-cd,drive=cd0,bootindex=1"
)

if [ "\$KVM_SUPPORT" = "y" ]; then
    ARGS+=(-enable-kvm -cpu host)
else
    ARGS+=(-cpu max)
fi

if [ "\$BOOT_TYPE" = "uefi" ]; then
    ARGS+=(
        -drive "if=pflash,format=raw,readonly=on,file=\$UEFI_CODE"
        -drive "if=pflash,format=raw,file=\$VM_VARS"
    )
fi

echo "Ejecutando QEMU..."
qemu-system-x86_64 "\${ARGS[@]}"
EOF
  chmod +x "$INSTALL_SCRIPT"

  # ==================== SCRIPT 2: USO DIARIO (SOLO DISCO) ====================
  echo -e "${BLUE}[*] Escribiendo cargador de arranque normal en: $BOOT_SCRIPT${NC}"
  cat <<EOF >"$BOOT_SCRIPT"
#!/bin/bash

VM_NAME="$VM_NAME"
VM_DIR="$VM_DIR"
DISK_PATH="$DISK_PATH"
DISK_FORMAT="$DISK_FORMAT"
VM_RAM="$VM_RAM"
VM_CORES="$VM_CORES"
KVM_SUPPORT="$KVM_SUPPORT"
BOOT_TYPE="$BOOT_TYPE"
UEFI_CODE="$DETECTED_UEFI_CODE"
VM_VARS="$VM_VARS"

clear
echo "=========================================================="
echo "          Iniciando Máquina Virtual: \$VM_NAME"
echo "=========================================================="
echo "Iniciando directamente desde el disco duro principal..."

ARGS=(
    -name "\$VM_NAME"
    -m "\$VM_RAM"
    -smp "\$VM_CORES"
    -vga virtio
    -display default,show-cursor=on
    -device qemu-xhci
    -device usb-tablet
    -device intel-hda
    -device hda-duplex
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0,romfile=
    -drive "file=\$DISK_PATH,format=\$DISK_FORMAT,if=none,id=hd0"
    -device "virtio-blk-pci,drive=hd0,bootindex=1"
)

if [ "\$KVM_SUPPORT" = "y" ]; then
    ARGS+=(-enable-kvm -cpu host)
else
    ARGS+=(-cpu max)
fi

if [ "\$BOOT_TYPE" = "uefi" ]; then
    ARGS+=(
        -drive "if=pflash,format=raw,readonly=on,file=\$UEFI_CODE"
        -drive "if=pflash,format=raw,file=\$VM_VARS"
    )
fi

echo "Ejecutando QEMU..."
qemu-system-x86_64 "\${ARGS[@]}"
EOF
  chmod +x "$BOOT_SCRIPT"

  # ==================== MENÚ FINAL DE CONFIRMACIÓN ====================
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${GREEN}      ¡Configuración completada exitosamente!       ${NC}"
  echo -e "Directorio de la VM: ${BOLD}$VM_DIR${NC}"
  echo -e "Script para Instalar (Arrancar desde ISO): ${BOLD}$INSTALL_SCRIPT${NC}"
  echo -e "Script para Lanzar (Sistema ya instalado): ${BOLD}$BOOT_SCRIPT${NC}"
  echo -e "${BLUE}====================================================${NC}\n"

  read -rp "¿Deseas lanzar la máquina virtual en modo instalación ahora mismo? [S/n]: " ARRANCAR_YA
  ARRANCAR_YA="${ARRANCAR_YA:-S}"

  if [[ "$ARRANCAR_YA" =~ ^[sS]$ ]]; then
    echo -e "${GREEN}[*] Lanzando instalación desde la ISO de manera inmediata...${NC}"
    "$INSTALL_SCRIPT"

    # Bloque de mensaje al cerrar la VM que se acaba de instalar
    echo -e "\n${BLUE}====================================================${NC}"
    echo -e "${GREEN}[*] Proceso de QEMU finalizado.${NC}"
    echo -e "Ubicación de tu máquina virtual: ${BOLD}$VM_DIR${NC}"
    echo -e "Cuando termine de instalarse el sistema, arráncala siempre usando:"
    echo -e "  ${BOLD}$BOOT_SCRIPT${NC}"
    echo -e "${BLUE}====================================================${NC}\n"
  else
    # Bloque de mensaje si decide guardar la configuración para después
    echo -e "\n${BLUE}====================================================${NC}"
    echo -e "${YELLOW}[*] Operación guardada para ejecutar más tarde.${NC}"
    echo -e "Ubicación de tu máquina virtual: ${BOLD}$VM_DIR${NC}\n"
    echo -e "1. Para realizar la instalación (arrancar desde ISO), ejecuta:"
    echo -e "   ${BOLD}$INSTALL_SCRIPT${NC}\n"
    echo -e "2. Una vez terminada la instalación, arranca siempre usando:"
    echo -e "   ${BOLD}$BOOT_SCRIPT${NC}"
    echo -e "${BLUE}====================================================${NC}\n"
  fi
fi
