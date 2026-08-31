#!/bin/bash
# Snapshot Btrfs con rotación automática
# Mantiene solo los últimos N snapshots
set -euo pipefail

DIR1="/mnt/snaps/"
MAX_SNAPS=5           # Número máximo de snapshots a mantener
SUBVOL="/"            # Subvolumen raíz a snapshotear

nomsnap="snap_$(date +%Y-%m-%d_%H%M%S)"
ARCH="$DIR1$nomsnap"

# Crear directorio si no existe
mkdir -p "$DIR1"

# Verificar que el subvolumen existe
if ! btrfs subvolume show "$SUBVOL" &>/dev/null; then
  echo "❌ Error: $SUBVOL no es un subvolumen Btrfs"
  exit 1
fi

# Crear snapshot de solo lectura
echo "📸 Creando snapshot: $ARCH"
sudo btrfs subvolume snapshot -r "$SUBVOL" "$ARCH"
echo "   ✅ Creado: $ARCH"

# Rotación: eliminar snapshots viejos (mantener solo MAX_SNAPS)
echo "🔄 Rotando snapshots (máximo $MAX_SNAPS)..."
SNAPS=()
while IFS= read -r s; do
  SNAPS+=("$s")
done < <(ls -1d "$DIR1"/snap_* 2>/dev/null | sort)
while [ ${#SNAPS[@]} -gt $MAX_SNAPS ]; do
  old="${SNAPS[0]}"
  echo "   🗑 Eliminando snapshot viejo: $(basename "$old")"
  sudo btrfs subvolume delete "$old" 2>/dev/null || sudo rm -rf "$old"
  SNAPS=("${SNAPS[@]:1}")
done

echo "✅ Snapshot completado. Snapshots actuales:"
ls -1d "$DIR1"/snap_* 2>/dev/null | while read s; do
  echo "   📁 $(basename "$s")"
done
