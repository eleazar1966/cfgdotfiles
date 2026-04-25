#!/bin/bash
# Mantenimiento preventivo Btrfs - Gentoo
# Ubicación: ~/.local/bin/btrfs-salud.sh

echo "--- 1. SCRUB (Integridad) ---"
sudo btrfs scrub start -B /

echo -e "\n--- 2. BALANCE (Metadatos musage=25) ---"
sudo btrfs balance start -musage=25 /

echo -e "\n--- 3. BALANCE (Datos dusage=5) ---"
sudo btrfs balance start -dusage=5 /

echo -e "\n--- 4. ESTADO DE SALUD (Hardware) ---"
sudo btrfs device stats /

echo -e "\n--- 5. REPORTE DE COMPRESIÓN (zstd) ---"
# Sincronizamos y limpiamos caché para lectura real
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sudo compsize -x /

echo -e "\n--- 6. OPTIMIZACIÓN DE FUENTES (Solo texto/código) ---"
# Aplicar solo a fuentes del Kernel para no saturar el SSD
sudo find /usr/src/linux -type f ! -name "*.xz" -exec btrfs filesystem defragment -czstd {} +

echo -e "\n--- 7. TOP 5 ARCHIVOS MÁS FRAGMENTADOS ---"
sudo find / -xdev -type f -exec filefrag {} + 2>/dev/null |
  sed 's/^\(.*\): \([0-9]\+\) extent.*/\2 \1/' |
  sort -n -r | head -n 5
