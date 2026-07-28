#!/bin/bash
set -euo pipefail
FECHA_HORA=$(date +%F--[%I_H_%M_M])
BACKUP="$HOME/Documentos/Tryton/TRYTON_DB/respaldo_bd-$FECHA_HORA.sql.gz"
DESTINO="$HOME/DINARICASA/HOLCZER/TRYTON_DSA/TRYTON_DB"

echo -e "\n Iniciando Respaldo en $BACKUP"

# Crear directorios si no existen
mkdir -p "$(dirname "$BACKUP")"
mkdir -p "$DESTINO"

pg_dumpall -U postgres | gzip >"$BACKUP"
echo "   ✓ Backup creado: $(du -h "$BACKUP" | cut -f1)"

sudo cp -rf "$HOME/Documentos/Tryton/TRYTON_DB/"* "$DESTINO/"
echo "   ✓ Copiado a $DESTINO"
echo -e "\n Finalizado Respaldo en $BACKUP"
