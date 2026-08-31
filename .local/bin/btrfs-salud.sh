#!/bin/bash
# Mantenimiento preventivo Btrfs - Gentoo
# Versión mejorada con SMART, reportes y logging
set -euo pipefail

LOGFILE="/var/log/btrfs-salud.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$DATE] $*" | sudo tee -a "$LOGFILE" >/dev/null; echo "$*"; }

echo "=============================================="
echo "  Btrfs Salud — Mantenimiento Preventivo"
echo "  $DATE"
echo "=============================================="

# --- 1. SCRUB de integridad ---
echo -e "\n--- 1. SCRUB (Integridad de datos) ---"
log "Iniciando scrub en /"
sudo btrfs scrub start -B / | tail -5
log "Scrub / completado"

if findmnt /mnt/ssd &>/dev/null; then
  log "Iniciando scrub en /mnt/ssd"
  sudo btrfs scrub start -B /mnt/ssd | tail -5 || true
  log "Scrub /mnt/ssd completado"
else
  echo "   (/mnt/ssd no montado, se omite el scrub)"
fi

# --- 2. BALANCE de metadatos ---
echo -e "\n--- 2. BALANCE (Metadatos musage=25) ---"
log "Balance de metadatos en /"
sudo btrfs balance start -musage=25 / | tail -3 || true

# --- 3. BALANCE de datos fragmentados ---
echo -e "\n--- 3. BALANCE (Datos dusage=5) ---"
log "Balance de datos en /"
sudo btrfs balance start -dusage=5 / | tail -3 || true

# --- 4. ESTADÍSTICAS DEL DISPOSITIVO ---
echo -e "\n--- 4. ESTADO DE SALUD (Hardware) ---"
log "Estadísticas de dispositivo /"
sudo btrfs device stats /

# --- 5. REPORTE DE COMPRESIÓN ---
echo -e "\n--- 5. COMPRESIÓN (zstd) ---"
sync
sudo compsize -x / 2>/dev/null | tail -10 || echo "compsize no disponible"

# --- 6. CHECK de integridad rápido (solo checksums, sin reparación) ---
echo -e "\n--- 6. VERIFICACIÓN RÁPIDA (checksums) ---"
sudo btrfs check --check-data-csum / 2>/dev/null | tail -5 || echo "   (requiere desmontaje para check completo)"

# --- 7. REPORTE SMART (si hay smartctl) ---
echo -e "\n--- 7. SMART DATA (NVMe) ---"
if command -v smartctl &>/dev/null; then
  # NVMe principal
  NVME_DEV=$(findmnt -n -o SOURCE / | sed 's/p[0-9]*$//;s/[0-9]*$//')
  if [ -n "$NVME_DEV" ] && [ -b "$NVME_DEV" ]; then
    echo "   Dispositivo: $NVME_DEV"
    sudo smartctl -A "$NVME_DEV" 2>/dev/null | grep -E "Temperature|Percentage Used|Media and Data Integrity|Error Information|Critical Warning|Available Spare" | head -10 || echo "   (smartctl no disponible para este dispositivo)"
  fi
  # SSD secundario
  SSD_DEV=$(findmnt -n -o SOURCE /mnt/ssd | sed 's/p[0-9]*$//;s/[0-9]*$//')
  if [ -n "$SSD_DEV" ] && [ -b "$SSD_DEV" ]; then
    echo "   Dispositivo: $SSD_DEV"
    sudo smartctl -A "$SSD_DEV" 2>/dev/null | grep -E "Temperature|Percentage Used|Media and Data Integrity|Error Information|Critical Warning|Available Spare" | head -10 || echo "   (smartctl no disponible)"
  fi
else
  echo "   smartctl no instalado (sys-apps/smartmontools)"
fi

# --- 8. USO Y ESPACIO ---
echo -e "\n--- 8. USO DE ESPACIO ---"
echo "   NVMe (/):"
df -h / | tail -1
echo "   SSD (/mnt/ssd):"
df -h /mnt/ssd | tail -1

echo -e "\n=============================================="
echo "  ✅ Mantenimiento completado"
echo "  Log: $LOGFILE"
echo "=============================================="
