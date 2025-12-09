#! /bin/bash
echo -e "\n Iniciando Respaldo ..."
cd
DIRECTORIO1="/home/eleazar/Documentos/Tryton/TRYTON_DB"
DIRECTORIO2="/home/eleazar/DINARICASA/HOLCZER/TRYTON_DSA/TRYTON_DB"
FECHA_HORA=$(date +%F)--[$(date +%I)H_$(date +%M)M]
BACKUP=$DIRECTORIO1/respaldo_bd-$FECHA_HORA.sql
echo -e "\n Iniciando Respaldo en ..." $BACKUP
pg_dumpall -U postgres >$BACKUP
sudo cp -rfv $DIRECTORIO1/* $DIRECTORIO2/
#clear
echo -e "\n Finalizado Respaldo en" $BACKUP
