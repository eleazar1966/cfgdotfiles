#!/bin/bash
# Wrapper para wttr.in — reintenta si la red no está, pero no se duerme si ya funciona
# LOCATION puede overridearse con: LOCATION="Bogota" weather-wttr.sh

MAX_RETRIES=15
RETRY_DELAY=1
CURL_TIMEOUT=3
LOCATION="${LOCATION:-Caracas}"

for ((i = 1; i <= MAX_RETRIES; i++)); do
  result=$(curl -s --max-time "$CURL_TIMEOUT" "https://wttr.in/${LOCATION}?format=3" 2>/dev/null)
  if [[ -n "$result" ]]; then
    echo "$result" | jq -R --unbuffered -c '{text: .}'
    exit 0
  fi
  sleep "$RETRY_DELAY"
done

# Último intento aunque falle — waybar muestra estado de desconexión
result=$(curl -s --max-time "$CURL_TIMEOUT" "https://wttr.in/${LOCATION}?format=3" 2>/dev/null)
if [[ -n "$result" ]]; then
  echo "$result" | jq -R --unbuffered -c '{text: .}'
else
  echo '{"text": "🌤 sin conexión"}'
fi
