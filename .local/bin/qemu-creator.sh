#!/bin/bash

# ==============================================================================
# QEMU CREATOR - GENERADOR DE MÁQUINAS VIRTUALES
# ==============================================================================

GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RED='\e[31m'
BOLD='\e[1m'
NC='\e[0m'

# Verificar dependencias
for dep in qemu-system-x86_64 qemu-img; do
  command -v "$dep" &>/dev/null || {
    echo -e "${RED}[ERROR] $dep no instalado.${NC}"
    exit 1
  }
done

# Detección de Firmware
OVMF_CODE_PATHS=("/usr/share/OVMF/OVMF_CODE.fd" "/usr/share/OVMF/OVMF_CODE_4M.fd" "/usr/share/edk2/x64/OVMF_CODE.fd" "/usr/share/edk2-ovmf/OVMF_CODE.fd")
OVMF_VARS_PATHS=("/usr/share/OVMF/OVMF_VARS.fd" "/usr/share/OVMF/OVMF_VARS_4M.fd" "/usr/share/edk2/x64/OVMF_VARS.fd" "/usr/share/edk2-ovmf/OVMF_VARS.fd")
for p in "${OVMF_CODE_PATHS[@]}"; do [[ -f "$p" ]] && UEFI_CODE="$p" && break; done
for p in "${OVMF_VARS_PATHS[@]}"; do [[ -f "$p" ]] && UEFI_VARS="$p" && break; done

# 1. Configuración del Directorio ISO
read -rp "Directorio ISO [1: ~/Downloads, 2: /mnt/ssd/ISOS, 3: Personalizada] [1]: " ISO_DIR_OPT
ISO_DIR_OPT="${ISO_DIR_OPT:-1}"
case "$ISO_DIR_OPT" in
  2) ISO_DIR="/mnt/ssd/ISOS" ;;
  3) read -rp "Ruta personalizada: " ISO_DIR ;;
  *) ISO_DIR="$HOME/Downloads" ;;
esac
ISO_DIR="${ISO_DIR/#\~/$HOME}"

mapfile -t ISO_LIST < <(find "$ISO_DIR" -maxdepth 1 -name "*.iso" 2>/dev/null)
if [ ${#ISO_LIST[@]} -eq 0 ]; then
  read -rp "Ruta completa archivo ISO: " ISO_PATH
else
  for i in "${!ISO_LIST[@]}"; do echo "  [$((i + 1))] $(basename "${ISO_LIST[$i]}")"; done
  read -rp "Selección [1-${#ISO_LIST[@]}]: " ISO_OPT
  ISO_PATH="${ISO_LIST[$((ISO_OPT - 1))]}"
fi

# 2. Configuración VM
read -rp "Modo [1: Live, 2: Instalación] [1]: " EXEC_MODE
EXEC_MODE="${EXEC_MODE:-1}"
DEFAULT_NAME=$(basename "$ISO_PATH" .iso | sed -E 's/-(x86_64|amd64|desktop|live|minimal|netinst|dvd).*//i' | sed 's/[^a-zA-Z0-9_-]//g')
read -rp "Nombre VM [$DEFAULT_NAME]: " VM_NAME
VM_NAME="${VM_NAME:-$DEFAULT_NAME}"
read -rp "RAM [4G]: " VM_RAM
VM_RAM="${VM_RAM:-4G}"
read -rp "Núcleos CPU [2]: " VM_CORES
VM_CORES="${VM_CORES:-2}"

BOOT_TYPE="bios"
[[ -n "$UEFI_CODE" && -n "$UEFI_VARS" ]] && BOOT_TYPE="uefi"
KVM_ENABLED="-machine q35,accel=kvm -cpu host"
[[ ! -e /dev/kvm ]] && KVM_ENABLED="-machine q35 -cpu max"

# 3. Preparación
VM_DIR="$HOME/qemu_vms/$VM_NAME"
mkdir -p "$VM_DIR"
DISK_PATH="$VM_DIR/${VM_NAME}.qcow2"

if [ "$EXEC_MODE" = "2" ]; then
  qemu-img create -f qcow2 "$DISK_PATH" 20G
  [[ "$BOOT_TYPE" == "uefi" ]] && cp "$UEFI_VARS" "$VM_DIR/${VM_NAME}_VARS.fd"
fi

# 4. Generación de Scripts
for mode in "install" "boot"; do
  SCRIPT_PATH="$VM_DIR/${mode}_${VM_NAME}.sh"
  cat <<'EOF' >"$SCRIPT_PATH"
#!/bin/bash
VM_NAME="VAR_VM_NAME"
VM_DIR="VAR_VM_DIR"
DISK_PATH="VAR_DISK_PATH"
ISO_PATH="VAR_ISO_PATH"
UEFI_CODE="VAR_UEFI_CODE"
VARS_PATH="VAR_VARS_PATH"
VM_RAM="VAR_VM_RAM"
VM_CORES="VAR_VM_CORES"
KVM_ENABLED="VAR_KVM_ENABLED"
BOOT_TYPE="VAR_BOOT_TYPE"
MODE="VAR_MODE"

ARGS=(
    $KVM_ENABLED
    -name "$VM_NAME" -m "$VM_RAM" -smp "$VM_CORES"
    -vga virtio -display default,show-cursor=on
    -device virtio-balloon-pci,id=balloon0
    -device virtio-rng-pci
    -device qemu-xhci -device usb-tablet
    -device intel-hda -device hda-duplex
    -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0,romfile=
    -device virtio-serial-pci
    -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
    -chardev socket,path=/tmp/qga-${VM_NAME}.sock,server=on,wait=off,id=qga0
    -drive "file=$DISK_PATH,format=qcow2,if=none,id=hd0"
    -device "virtio-blk-pci,drive=hd0,bootindex=$([[ "$MODE" == "install" ]] && echo 2 || echo 1)"
)

# Añadir no-reboot solo en modo instalación para forzar la salida al terminar
[ "$MODE" == "install" ] && ARGS+=(-no-reboot)

[ "$MODE" == "install" ] && ARGS+=(-drive "file=$ISO_PATH,media=cdrom,readonly=on,if=none,id=cd0" -device "ide-cd,drive=cd0,bootindex=1")
[ "$BOOT_TYPE" == "uefi" ] && ARGS+=(-drive "if=pflash,format=raw,readonly=on,file=$UEFI_CODE" -drive "if=pflash,format=raw,file=$VARS_PATH")

qemu-system-x86_64 "${ARGS[@]}"

if [ "$MODE" == "install" ]; then
    echo -e "\n${GREEN}[*] Instalación detectada como terminada (apagado/reinicio).${NC}"
    echo -e "${YELLOW}[!] Para iniciar el sistema instalado, ejecuta:${NC}"
    echo -e "${BOLD}    $VM_DIR/boot_${VM_NAME}.sh${NC}"
fi
EOF
  sed -i "s|VAR_VM_NAME|$VM_NAME|g" "$SCRIPT_PATH"
  sed -i "s|VAR_VM_DIR|$VM_DIR|g" "$SCRIPT_PATH"
  sed -i "s|VAR_DISK_PATH|$DISK_PATH|g" "$SCRIPT_PATH"
  sed -i "s|VAR_ISO_PATH|$ISO_PATH|g" "$SCRIPT_PATH"
  sed -i "s|VAR_UEFI_CODE|$UEFI_CODE|g" "$SCRIPT_PATH"
  sed -i "s|VAR_VARS_PATH|$VM_DIR/${VM_NAME}_VARS.fd|g" "$SCRIPT_PATH"
  sed -i "s|VAR_VM_RAM|$VM_RAM|g" "$SCRIPT_PATH"
  sed -i "s|VAR_VM_CORES|$VM_CORES|g" "$SCRIPT_PATH"
  sed -i "s|VAR_KVM_ENABLED|$KVM_ENABLED|g" "$SCRIPT_PATH"
  sed -i "s|VAR_BOOT_TYPE|$BOOT_TYPE|g" "$SCRIPT_PATH"
  sed -i "s|VAR_MODE|$mode|g" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
done

# 5. Ejecución
echo -e "\n${BOLD}${BLUE}Scripts generados correctamente:${NC}"
echo -e "  * Instalador: ${VM_DIR}/install_${VM_NAME}.sh"
echo -e "  * Arranque:   ${VM_DIR}/boot_${VM_NAME}.sh${NC}\n"

if [ "$EXEC_MODE" = "1" ]; then
  echo -e "${BLUE}[*] Iniciando modo LIVE...${NC}"
  qemu-system-x86_64 $KVM_ENABLED -name "live_${VM_NAME}" -m "$VM_RAM" -smp "$VM_CORES" \
    -vga virtio -display default,show-cursor=on -device virtio-balloon-pci,id=balloon0 -device virtio-rng-pci \
    -device qemu-xhci -device usb-tablet -device intel-hda -device hda-duplex \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0,romfile= \
    -drive "file=$ISO_PATH,media=cdrom,readonly=on,if=none,id=cd0" -device "ide-cd,drive=cd0,bootindex=1"
else
  echo -e "${BLUE}[*] Iniciando modo INSTALACIÓN...${NC}"
  "$VM_DIR/install_${VM_NAME}.sh"
fi
