#!/bin/bash
set -e
FECHA_HORA=$(date +%F--[%I_H_%M_M])
BACKUP="$HOME/Documentos/Tryton/TRYTON_DB/respaldo_bd-$FECHA_HORA.sql.gz"
echo -e "\n Iniciando Respaldo en $BACKUP"
pg_dumpall -U postgres | gzip > "$BACKUP"
sudo cp -rf "$HOME/Documentos/Tryton/TRYTON_DB/"* "$HOME/DINARICASA/HOLCZER/TRYTON_DSA/TRYTON_DB/"
echo -e "\n Finalizado Respaldo en $BACKUP"
