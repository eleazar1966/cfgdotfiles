#!/bin/bash
# ──────────────────────────────────────────────
# MikroTik Network Connect — RB951Ui
# Muestra equipos disponibles y conecta por SSH
# ──────────────────────────────────────────────

set -euo pipefail

# ─── Configuración ─────────────────────────────
# Las IPs se detectan dinámicamente, estos son fallbacks
MIKROTIK_LAN="192.168.250.1"
MIKROTIK_WAN="192.168.200.28"  # Fallback por si el scan no encuentra nada

# Credenciales: SOLO variables de entorno (nunca hardcodear)
# Configurá MIKROTIK_USER y MIKROTIK_PASS en ~/.bashrc o ~/.profile
ADMIN_USER="${MIKROTIK_USER:-eleazar}"
ADMIN_PASS="${MIKROTIK_PASS:-}"
[ -z "$ADMIN_PASS" ] && { echo -e "${ROJO}[✗]${NORMAL} MIKROTIK_PASS no configurada. Ponla en ~/.bashrc: export MIKROTIK_PASS='tu-clave'" >&2; exit 1; }

# ─── Colores ───────────────────────────────────
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CIAN='\033[0;36m'
NORMAL='\033[0m'

# Escribir a stderr para no contaminar capturas con $(funcion)
info()  { echo -e "${CIAN}[*]${NORMAL} $1" >&2; }
ok()    { echo -e "${VERDE}[✓]${NORMAL} $1" >&2; }
error() { echo -e "${ROJO}[✗]${NORMAL} $1" >&2; }
warn()  { echo -e "${AMARILLO}[!]${NORMAL} $1" >&2; }

# ─── Funciones ─────────────────────────────────

ROUTE_ADDED=false

cleanup() {
    rm -f /tmp/mikrotik_devices.json /tmp/mikrotik_leases.txt /tmp/mikrotik_ping.txt
    if [ "$ROUTE_ADDED" = true ]; then
        sudo ip route del 192.168.250.0/24 2>/dev/null || true
    fi
}
trap cleanup EXIT

detectar_red() {
    local mi_ip
    mi_ip=$(ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '^127\.' | head -1)
    
    if echo "$mi_ip" | grep -q '^192\.168\.250\.'; then
        echo "lan"
    elif echo "$mi_ip" | grep -q '^192\.168\.200\.'; then
        echo "wan"
    else
        echo "otra"
    fi
}

# ─── Preparar ruta y firewall para conexión directa desde WAN ──

configurar_firewall_mikrotik() {
    local ip="$1"
    # Verificar si la regla ya existe
    if ! curl -s -u "$ADMIN_USER:$ADMIN_PASS" "http://$ip/rest/ip/firewall/filter" 2>/dev/null | \
         jq -e '.[] | select(.comment == "SSH WAN->LAN (conectar.sh)")' >/dev/null 2>&1; then
        info "Configurando regla de firewall en MikroTik..."
        curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X PUT "http://$ip/rest/ip/firewall/filter" \
            -H "Content-Type: application/json" \
            -d '{
                "chain":"forward",
                "src-address":"192.168.200.0/24",
                "dst-address":"192.168.250.0/24",
                "protocol":"tcp",
                "dst-port":"22",
                "action":"accept",
                "comment":"SSH WAN->LAN (conectar.sh)",
                "place-before":"0"
            }' >/dev/null 2>&1 && ok "Regla de firewall agregada en MikroTik"
    fi
}

agregar_ruta_lan() {
    local via="$1"
    if ! ip route show | grep -q '192.168.250.0/24'; then
        info "Agregando ruta a LAN 192.168.250.0/24 vía $via..."
        if sudo ip route add 192.168.250.0/24 via "$via"; then
            ROUTE_ADDED=true
            ok "Ruta agregada (se limpia al salir)"
        else
            warn "No se pudo agregar ruta (¿sudo configurado?)"
            return 1
        fi
    fi
    return 0
}

consultar_mikrotik() {
    local ip="$1"
    local intentos=2
    
    for i in $(seq 1 $intentos); do
        if curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 5 \
            "http://$ip/rest/ip/dhcp-server/lease" 2>/dev/null > /tmp/mikrotik_devices.json; then
            if jq -e '. | length > 0' /tmp/mikrotik_devices.json >/dev/null 2>&1; then
                return 0
            fi
        fi
        sleep 1
    done
    return 1
}

# ─── Encontrar MikroTik por hostname ─────────---
# Escanea la red buscando puerto 8291 (Winbox) y verifica identity por REST API
encontrar_mikrotik() {
    local red="$1"  # "lan", "wan", "otra"
    local mi_ip
    local subnet
    local candidatos
    local ip

    # Si estamos en LAN, probar primero la IP fija del bridge
    if [ "$red" = "lan" ]; then
        if curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 3 \
            "http://$MIKROTIK_LAN/rest/system/identity" 2>/dev/null | jq -re '.name' 2>/dev/null | grep -qi '.' >/dev/null; then
            echo "$MIKROTIK_LAN"
            return 0
        fi
    fi

    mi_ip=$(ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '^127\.' | head -1)
    subnet=$(echo "$mi_ip" | cut -d. -f1-3)

    info "Buscando MikroTik en $subnet.0/24 (puerto 8291)..."
    
    # Escanear puerto 8291 (Winbox) — exclusivo de MikroTik
    # nmap output: "Nmap scan report for <ip>", extraemos la IP
    candidatos=$(nmap -p 8291 --open -T4 "$subnet.0/24" 2>/dev/null | grep 'Nmap scan report for' | grep -oP '\d+\.\d+\.\d+\.\d+' || true)

    for ip in $candidatos; do
        [ "$ip" = "$mi_ip" ] && continue  # saltearnos nosotros mismos
        local identity
        identity=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 3 \
            "http://$ip/rest/system/identity" 2>/dev/null | jq -r '.name // "desconocido"' 2>/dev/null)
        if [ -n "$identity" ] && [ "$identity" != "desconocido" ]; then
            ok "MikroTik encontrado: $identity en $ip"
            echo "$ip"
            return 0
        fi
    done

    # Fallback: probar las IPs conocidas por si están fijas
    for try_ip in "$MIKROTIK_WAN" "$MIKROTIK_LAN"; do
        [ -z "$try_ip" ] && continue
        if curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 3 \
            "http://$try_ip/rest/system/identity" 2>/dev/null | jq -re '.name' 2>/dev/null | grep -qi '.' >/dev/null; then
            echo "$try_ip"
            return 0
        fi
    done

    return 1
}

obtener_equipos() {
    local mikrotik_ip="$1"
    
    consultar_mikrotik "$mikrotik_ip" || return 1
    
    # Extraer equipos del JSON
    jq -r '.[] | select(.status == "bound" or .status == "waiting") | 
        [ (.comment // .["host-name"] // "desconocido"), 
          (.active_address // .address // "?"), 
          (.active_mac_address // .mac_address // "?") ] | 
        @tsv' /tmp/mikrotik_devices.json 2>/dev/null | sort -t$'\t' -k1 > /tmp/mikrotik_leases.txt
    
    # También incluir entradas de ARP (equipos con IP fija manual)
    curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 5 \
        "http://$mikrotik_ip/rest/ip/arp" 2>/dev/null | \
        jq -r '.[] | select(.dynamic == "false" and .address != "") | 
            [ "Fijo-\(.address)", .address, .mac_address // "?" ] | 
            @tsv' 2>/dev/null >> /tmp/mikrotik_leases.txt
    
    # Quitar duplicados y ordenar
    sort -u /tmp/mikrotik_leases.txt -o /tmp/mikrotik_leases.txt
    
    if [ ! -s /tmp/mikrotik_leases.txt ]; then
        return 1
    fi
    return 0
}

ping_equipos() {
    info "Verificando equipos disponibles en la red..."
    
    > /tmp/mikrotik_ping.txt
    local total=0
    local disponibles=0
    
    while IFS=$'\t' read -r hostname ip mac; do
        if [ -z "$ip" ] || [ "$ip" = "?" ]; then
            continue
        fi
        total=$((total + 1))
        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            disponibles=$((disponibles + 1))
            echo -e "$hostname\t$ip\t$mac" >> /tmp/mikrotik_ping.txt
        fi
    done < /tmp/mikrotik_leases.txt
    
    echo
    ok "Equipos encontrados: $disponibles de $total"
    echo
}

mostrar_menu() {
    local opciones=()
    local i=0
    
    while IFS=$'\t' read -r hostname ip mac; do
        i=$((i + 1))
        opciones+=("$i" "$hostname ($ip)")
        # Guardar para referencia (printf -v es seguro, no interpreta el contenido)
        printf -v "host_%d" "$i" "%s" "$hostname"
        printf -v "ip_%d" "$i" "%s" "$ip"
        printf -v "mac_%d" "$i" "%s" "$mac"
    done < /tmp/mikrotik_ping.txt
    
    if [ $i -eq 0 ]; then
        error "No hay equipos disponibles en este momento."
        return 1
    fi
    
    echo -e "${AZUL}╔══════════════════════════════════════╗${NORMAL}"
    echo -e "${AZUL}║     EQUIPOS DISPONIBLES EN LA RED    ║${NORMAL}"
    echo -e "${AZUL}╚══════════════════════════════════════╝${NORMAL}"
    echo
    
    local j=1
    while IFS=$'\t' read -r hostname ip mac; do
        local nombre_limpio="${hostname//_/ }"
        printf "  ${VERDE}%2d)${NORMAL} %-30s ${CIAN}%s${NORMAL}\n" "$j" "$nombre_limpio" "$ip"
        j=$((j + 1))
    done < /tmp/mikrotik_ping.txt
    
    echo
    echo -e "  ${AMARILLO} 0)${NORMAL} Salir"
    echo
}

conectar_equipo() {
    local num="$1"
    
    local hostname="host_${num}"
    local ip="ip_${num}"
    local user=""
    
    hostname="${!hostname}"
    ip="${!ip}"
    
    echo
    echo -e "${AZUL}═══════════════════════════════════════${NORMAL}"
    echo -e "  Conectando a: ${VERDE}$hostname${NORMAL}"
    echo -e "  IP:           ${CIAN}$ip${NORMAL}"
    echo -e "${AZUL}═══════════════════════════════════════${NORMAL}"
    echo
    
    # Pedir usuario SSH
    read -r -p "$(echo -e "${AMARILLO}?${NORMAL} Usuario SSH para $hostname [$(whoami)]: ")" user
    if [ -z "$user" ]; then
        user=$(whoami)
    fi
    
    echo
    if [ "$MIKROTIK_IP" = "$MIKROTIK_LAN" ]; then
        info "Conectando directamente a $ip ..."
        echo
        ssh "$user@$ip"
    else
        info "Conectando directamente a $user@$ip ..."
        echo
        ssh "$user@$ip"
    fi
}

# ─── Banner ────────────────────────────────────

echo
echo -e "${AZUL}╔══════════════════════════════════════╗${NORMAL}"
echo -e "${AZUL}║    MIKROTIKS  Red Connect Tool      ║${NORMAL}"
echo -e "${AZUL}╚══════════════════════════════════════╝${NORMAL}"
echo

# ─── Encontrar MikroTik dinámicamente ─────────

RED=$(detectar_red)
MIKROTIK_IP=$(encontrar_mikrotik "$RED") || true

if [ -z "$MIKROTIK_IP" ]; then
    error "No se pudo encontrar el MikroTik en la red."
    echo
    echo -e "${AMARILLO}Posibles causas:${NORMAL}"
    echo "  - El MikroTik está apagado o en otra red"
    echo "  - Necesitás VPN primero (L2TP/IPsec)"
    echo "  - Las credenciales son incorrectas"
    echo
    exit 1
fi

# ─── Obtener equipos ──────────────────────────

info "Obteniendo equipos desde MikroTik..."
if ! obtener_equipos "$MIKROTIK_IP"; then
    error "No se pudieron obtener equipos del MikroTik en $MIKROTIK_IP"
    # Intentar mostrar leases sin procesar para depuración
    if [ -s /tmp/mikrotik_devices.json ]; then
        warn "El MikroTik respondió pero no devolvió leases activos"
    fi
    exit 1
fi

# ─── Ping a equipos (solo en LAN) ────────────

if [ "$MIKROTIK_IP" = "$MIKROTIK_LAN" ]; then
    ping_equipos
    if [ ! -s /tmp/mikrotik_ping.txt ]; then
        error "No hay equipos accesibles en este momento."
        exit 1
    fi
else
    # En WAN: configurar ruta + firewall para conexión directa
    info "Configurando acceso directo a LAN desde red proveedora..."
    configurar_firewall_mikrotik "$MIKROTIK_IP"
    agregar_ruta_lan "$MIKROTIK_IP" || true
    cp /tmp/mikrotik_leases.txt /tmp/mikrotik_ping.txt
    ok "Podés conectar directo a los equipos de la LAN"
fi

mostrar_menu

while true; do
    echo
    read -r -p "$(echo -e "${VERDE}Selecciona un número [0 para salir]: ${NORMAL}")" seleccion
    
    if [ "$seleccion" = "0" ] || [ -z "$seleccion" ]; then
        echo
        info "Saliendo..."
        exit 0
    fi
    
    # Validar que sea un número válido
    if ! [[ "$seleccion" =~ ^[0-9]+$ ]]; then
        warn "Ingresa un número válido"
        continue
    fi
    
    if [ "$seleccion" -le "$(wc -l < /tmp/mikrotik_ping.txt)" ] 2>/dev/null; then
        conectar_equipo "$seleccion"
        echo
        echo -e "${VERDE}Conexión finalizada.${NORMAL}"
        echo
        # Volver a mostrar menú después de desconectar
        mostrar_menu
    else
        warn "Selección inválida. Elige entre 0 y $(wc -l < /tmp/mikrotik_ping.txt)"
    fi
done
