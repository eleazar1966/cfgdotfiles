#!/bin/bash
# Aplica el tema MOC generado por matugen.
#
# matugen hace output_path=~/.moc/themes/.matugen-raw con los colordef en
# rango 0..255 (los componentes `red`/`green`/`blue` de matugen). MOC espera
# colordef en rango 0..1000, así que escalamos aquí y escribimos el tema final
# en ~/.moc/themes/matugen. Luego reiniciamos el server de MOC si está vivo
# para que tome los colores nuevos.
set -eu

RAW="$HOME/.moc/themes/.matugen-raw"
OUT="$HOME/.moc/themes/matugen"

[[ -f "$RAW" ]] || { echo "raw theme file missing: $RAW" >&2; exit 1; }

mkdir -p "$HOME/.moc/themes"
awk '/^colordef/ {
  printf "colordef %s = %d %d %d\n", $2, int($4*1000/255), int($5*1000/255), int($6*1000/255)
  next
}
{ print }' "$RAW" > "$OUT"

# Reiniciar el server de MOC si está corriendo para aplicar el tema.
if pgrep -x mocp >/dev/null 2>&1; then
  pkill -x mocp 2>/dev/null || true
  sleep 0.3
  mocp -S >/dev/null 2>&1 || true
fi
