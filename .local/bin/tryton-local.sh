#!/bin/bash
# ---------------------------------------------------------------------------
# Tryton 8.2 - Lanzador local (servidor nativo OpenRC)
#
# Si el servicio trytond local ya está sirviendo, abre directamente el
# cliente GTK nativo. Si no, inicia el servicio, espera el puerto y recién
# entonces abre el cliente.
#
# Entorno:
#   TRYTON_NO_CLIENT=1   asegura el servidor pero NO abre la GUI
#                        (usado para pruebas no interactivas)
# ---------------------------------------------------------------------------
set -uo pipefail

HOST="localhost"
PORT="8000"
DB="tryton"
USER="admin"
SERVICE="trytond"
ICON="$HOME/.local/share/icons/tryton-local.png"
LOG="${XDG_RUNTIME_DIR:-/tmp}/tryton-local.log"

notify() {
    notify-send -i "$ICON" "Tryton Local (8.2)" "$1" 2>/dev/null || true
}

port_open() {
    (exec 3<>"/dev/tcp/$HOST/$1") 2>/dev/null
}

wait_port() {
    local i
    for ((i = 0; i < 45; i++)); do
        port_open "$1" && return 0
        sleep 1
    done
    return 1
}

# --- 1. Asegura que el servidor esté sirviendo -----------------------------
if port_open "$PORT"; then
    : # ya está arriba: solo abrir el cliente
elif rc-service "$SERVICE" status >/dev/null 2>&1; then
    if ! wait_port "$PORT"; then
        notify "El servicio $SERVICE está activo pero el puerto $PORT no responde. Ver $LOG."
        exit 1
    fi
else
    # shellcheck disable=SC2024  # $LOG es escribible por el usuario; el redirect como usuario es intencional
    if ! sudo rc-service "$SERVICE" start >>"$LOG" 2>&1; then
        notify "No pude iniciar $SERVICE. Ver $LOG."
        exit 1
    fi
    if ! wait_port "$PORT"; then
        notify "$SERVICE arrancó pero el puerto $PORT todavía no responde. Ver $LOG."
        exit 1
    fi
fi

# --- 2. Abre el cliente GTK nativo -----------------------------------------
[ "${TRYTON_NO_CLIENT:-0}" = "1" ] && exit 0
exec tryton -u "$USER" "tryton://$HOST:$PORT/$DB"
