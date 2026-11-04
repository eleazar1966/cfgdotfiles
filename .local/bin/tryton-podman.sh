#!/bin/bash
# ---------------------------------------------------------------------------
# Tryton 8.2 - Lanzador Podman (entorno de prueba en contenedores)
#
# Si el servidor en contenedores ya está sirviendo, abre directamente el
# cliente GTK nativo. Si no, inicia los contenedores (PostgreSQL primero),
# espera los puertos y recién entonces abre el cliente.
#
# Contenedores:
#   tryton-pg  -> PostgreSQL 18 en el puerto host 5433
#   tryton82   -> trytond 8.2 (gunicorn) en el puerto host 8001
#
# Entorno:
#   TRYTON_NO_CLIENT=1   asegura los contenedores pero NO abre la GUI
# ---------------------------------------------------------------------------
set -uo pipefail

HOST="localhost"
PORT="8001"
DB="tryton"
USER="admin"
PG_CONTAINER="tryton-pg"
APP_CONTAINER="tryton82"
PG_PORT="5433"
ICON="$HOME/.local/share/icons/tryton-podman.png"
LOG="${XDG_RUNTIME_DIR:-/tmp}/tryton-podman.log"

notify() {
    notify-send -i "$ICON" "Tryton Podman (8.2)" "$1" 2>/dev/null || true
}

port_open() {
    (exec 3<>"/dev/tcp/$HOST/$1") 2>/dev/null
}

wait_port() {
    local port="$1" i
    for ((i = 0; i < 45; i++)); do
        port_open "$port" && return 0
        sleep 1
    done
    return 1
}

container_state() {
    podman container inspect -f '{{.State.Status}}' "$1" 2>/dev/null
}

# --- 1. Asegura que el servidor esté sirviendo -----------------------------
if port_open "$PORT"; then
    : # ya está arriba: solo abrir el cliente
else
    if [ "$(container_state "$PG_CONTAINER")" != "running" ]; then
        if ! podman start "$PG_CONTAINER" >>"$LOG" 2>&1; then
            notify "No pude iniciar $PG_CONTAINER. Ver $LOG."
            exit 1
        fi
    fi
    if ! wait_port "$PG_PORT"; then
        notify "$PG_CONTAINER no abrió el puerto $PG_PORT. Ver $LOG."
        exit 1
    fi

    if [ "$(container_state "$APP_CONTAINER")" != "running" ]; then
        if ! podman start "$APP_CONTAINER" >>"$LOG" 2>&1; then
            notify "No pude iniciar $APP_CONTAINER. Ver $LOG."
            exit 1
        fi
    fi
    if ! wait_port "$PORT"; then
        notify "$APP_CONTAINER no abrió el puerto $PORT. Ver $LOG."
        exit 1
    fi
fi

# --- 2. Abre el cliente GTK nativo -----------------------------------------
[ "${TRYTON_NO_CLIENT:-0}" = "1" ] && exit 0
exec tryton -u "$USER" "tryton://$HOST:$PORT/$DB"
