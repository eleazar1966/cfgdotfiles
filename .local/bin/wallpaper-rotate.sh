#!/bin/sh
# Rota el wallpaper aleatoriamente cada 5 minutos usando el IPC de DMS.
# Funciona incluso si el auto-ciclo interno de DMS pierde su config al reiniciar
# (el daemon borra las claves wallpaperCycling* de session.json al arrancar).
# Politicas:
#   - flock: evita procesos duplicados al recargar niri / re-login.
#   - Pausa si hay una ventana a pantalla completa (igual que el scheduler de DMS).
#   - Salta en silencio si DMS no esta corriendo (vuelve a intentar en el proximo tick).

LOCK_FILE="/run/user/$(id -u)/wallpaper-rotate.lock"
WALLPAPER_DIR="$HOME/.config/wallpaper"
STATE_FILE="$HOME/.local/state/wallpaper-rotate-last"
INTERVAL=300

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

while :; do
    sleep "$INTERVAL"

    # DMS vivo? si no, reintentar en el proximo ciclo.
    dms ipc call wallpaper get >/dev/null 2>&1 || continue

    # Pausar si hay fullscreen activo (juego, video): no rotar encima.
    if niri msg focused-window 2>/dev/null | grep -q 'is-fullscreen: true'; then
        continue
    fi

    current="$(dms ipc call wallpaper get 2>/dev/null | tail -n1)"
    [ -z "$current" ] && current="$(cat "$STATE_FILE" 2>/dev/null)"
    [ -z "$current" ] && current="/nonexistent"

    pick="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        2>/dev/null | grep -v -F -x "$current" | shuf -n 1)"

    [ -z "$pick" ] && continue

    if dms ipc call wallpaper set "$pick" >/dev/null 2>&1; then
        printf '%s\n' "$pick" > "$STATE_FILE"
    fi
done