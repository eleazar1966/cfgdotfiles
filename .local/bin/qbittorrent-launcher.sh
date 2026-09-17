#!/bin/bash
# qBittorrent launcher: garantiza que Jackett y FlareSolverr esten vivos
# antes de abrir la app. Arrancar servicios OpenRC requiere root (lock de
# /run/openrc), por eso sudo -n (sin contrasena, ya configurado).
sudo -n rc-service jackett start >/dev/null 2>&1
sudo -n rc-service flaresolverr start >/dev/null 2>&1
exec /usr/bin/qbittorrent "$@"