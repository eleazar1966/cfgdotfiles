#!/bin/bash
# ──────────────────────────────────────────────
# MikroTik Network Connect — RB951Ui
# Muestra equipos disponibles y conecta por SSH
# ──────────────────────────────────────────────

set -euo pipefail

# ─── Configuración ─────────────────────────────
# Las IPs de la LAN del proveedor las asigna el DHCP del ONT: NO se asumen.
# Se descubren en el momento con la librería compartida.
MIKROTIK_LAN="192.168.250.1"    # Bridge del MikroTik (IP propia, no DHCP)
LAN_SUBNET="192.168.250.0/24"   # Red interna del MikroTik (la controlamos nosotros)

# Bucle de descubrimiento: cuántos barridos y cuánto esperar entre ellos.
ROUTER_RETRIES="${ROUTER_RETRIES:-3}"
ROUTER_RETRY_DELAY="${ROUTER_RETRY_DELAY:-2}"

# shellcheck source=/usr/local/lib/router-discovery.sh
if [ -r /usr/local/lib/router-discovery.sh ]; then
    . /usr/local/lib/router-discovery.sh
else
    echo "Falta /usr/local/lib/router-discovery.sh (librería de descubrimiento)" >&2
    exit 1
fi

# La subred del proveedor también es DHCP: se deduce de nuestra propia IP.
WAN_SUBNET=""
_ip_local=$(rd_ip_actual 2>/dev/null || true)
[ -n "$_ip_local" ] && WAN_SUBNET="${_ip_local%.*}.0/24"
unset _ip_local

# Credenciales: archivo 0600, nunca hardcodeadas acá.
CRED_FILE="${HOME}/.config/mikrotik/credenciales"
if [ -z "${MIKROTIK_PASS:-}" ] && [ -r "$CRED_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CRED_FILE"
fi
ADMIN_USER="${MIKROTIK_USER:-eleazar}"
ADMIN_PASS="${MIKROTIK_PASS:-}"

# ─── Colores ───────────────────────────────────
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CIAN='\033[0;36m'
NORMAL='\033[0m'

# Escribir a stderr para no contaminar capturas con $(funcion)
info()  { echo -e "${CIAN}[*]${NORMAL} $1" >&2; }
ok()    { echo -e "${VERDE}[✓]${NORMAL} $1" >&2; }
error() { echo -e "${ROJO}[✗]${NORMAL} $1" >&2; }
warn()  { echo -e "${AMARILLO}[!]${NORMAL} $1" >&2; }

# Las credenciales sólo hacen falta para hablar con la API del MikroTik.
# Sin ellas el script sigue: puede detectar el Linksys e inventariar por barrido.
if [ -z "$ADMIN_PASS" ]; then
    warn "Sin MIKROTIK_PASS (ver $CRED_FILE): se detectará el router pero no se consultará su API."
fi

# ─── Funciones ─────────────────────────────────

ROUTE_ADDED=false

# Directorio de trabajo temporal: respeta TMPDIR y no deja basura en /tmp.
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/conectar.XXXXXX")
DEVICES_JSON="$TMP_DIR/devices.json"
LEASES_TSV="$TMP_DIR/leases.tsv"
PING_TSV="$TMP_DIR/ping.tsv"

cleanup() {
    [ -n "${TMP_DIR:-}" ] && rm -rf "$TMP_DIR"
    if [ "$ROUTE_ADDED" = true ]; then
        sudo ip route del "$LAN_SUBNET" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ─── Elegir router ─────────────────────────────
# Prefiere el MikroTik (tiene API de leases); si no aparece, el Linksys.
elegir_router() {
    local n hallados mt ls
    for ((n = 1; n <= ROUTER_RETRIES; n++)); do
        info "Buscando routers en la red (intento $n/$ROUTER_RETRIES)..."
        hallados=$(rd_descubrir || true)

        mt=$(printf '%s\n' "$hallados" | awk -F'\t' '$1 == "mikrotik" {print $2; exit}')
        [ -n "$mt" ] && { printf 'mikrotik\t%s\n' "$mt"; return 0; }

        ls=$(printf '%s\n' "$hallados" | awk -F'\t' '$1 == "linksys" {print $2; exit}')
        [ -n "$ls" ] && { printf 'linksys\t%s\n' "$ls"; return 0; }

        [ "$n" -lt "$ROUTER_RETRIES" ] && sleep "$ROUTER_RETRY_DELAY"
    done
    return 1
}

# Inventario sin API: barrido de la subred + tabla ARP + DNS inverso.
inventario_por_scan() {
    local subred ip mac nombre
    subred=$(rd_subred_actual) || return 1
    rd_poblar_arp "$subred"

    : > "$LEASES_TSV"
    while read -r ip mac; do
        [ -z "$ip" ] && continue
        nombre=$(getent hosts "$ip" 2>/dev/null | awk '{print $2; exit}')
        printf '%s\t%s\t%s\n' "${nombre:-desconocido}" "$ip" "$mac" >> "$LEASES_TSV"
    done < <(ip neigh show 2>/dev/null | awk '/lladdr/ {for (i = 1; i <= NF; i++) if ($i == "lladdr") print $1, $(i + 1)}')

    sort -u "$LEASES_TSV" -o "$LEASES_TSV" 2>/dev/null || true
    [ -s "$LEASES_TSV" ]
}

# ─── Preparar ruta y firewall para conexión directa desde WAN ──

configurar_firewall_mikrotik() {
    local ip="$1"
    local reglas id actual_src actual_dst body first_id
    local comentario="SSH WAN->LAN (conectar.sh)"

    if [ -z "$WAN_SUBNET" ]; then
        warn "No se pudo determinar la subred local; se omite la regla de firewall"
        return 1
    fi

    reglas=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 5 \
        "http://$ip/rest/ip/firewall/filter" 2>/dev/null) || return 1

    # Buscar la regla por comentario (el .id en REST viene como ".id")
    id=$(printf '%s' "$reglas" | jq -r --arg c "$comentario" \
        '.[] | select(.comment == $c) | (."id" // .".id" // empty)' 2>/dev/null | head -1)

    if [ -n "$id" ]; then
        actual_src=$(printf '%s' "$reglas" | jq -r --arg c "$comentario" \
            '.[] | select(.comment == $c) | ."src-address" // ""' 2>/dev/null | head -1)
        actual_dst=$(printf '%s' "$reglas" | jq -r --arg c "$comentario" \
            '.[] | select(.comment == $c) | ."dst-address" // ""' 2>/dev/null | head -1)

        if [ "$actual_src" = "$WAN_SUBNET" ] && [ "$actual_dst" = "$LAN_SUBNET" ]; then
            ok "Regla de firewall ya correcta ($WAN_SUBNET -> $LAN_SUBNET)"
            return 0
        fi

        # Existe pero apunta a una subred vieja: actualizarla, no duplicarla.
        info "Regla desactualizada ($actual_src -> $actual_dst), corrigiendo..."
        body=$(printf '{"src-address":"%s","dst-address":"%s"}' "$WAN_SUBNET" "$LAN_SUBNET")
        if curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X PUT \
            "http://$ip/rest/ip/firewall/filter/$id" \
            -H "Content-Type: application/json" -d "$body" >/dev/null 2>&1; then
            ok "Regla actualizada a $WAN_SUBNET -> $LAN_SUBNET"
            return 0
        fi
        warn "No se pudo actualizar la regla de firewall"
        return 1
    fi

    info "Creando regla de firewall en MikroTik..."
    # En la API REST, place-before espera el .id de una regla existente
    # (p. ej. "*1"), NO un índice numérico.
    first_id=$(printf '%s' "$reglas" | jq -r '.[0] | (."id" // .".id" // empty)' 2>/dev/null)
    body=$(printf '{"chain":"forward","src-address":"%s","dst-address":"%s","protocol":"tcp","dst-port":"22","action":"accept","comment":"%s"}' \
        "$WAN_SUBNET" "$LAN_SUBNET" "$comentario")
    if [ -n "$first_id" ]; then
        body=$(printf '%s' "$body" | jq -c --arg pb "$first_id" '. + {"place-before": $pb}')
    fi
    if curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X PUT "http://$ip/rest/ip/firewall/filter" \
        -H "Content-Type: application/json" -d "$body" >/dev/null 2>&1; then
        ok "Regla de firewall agregada en MikroTik"
    else
        warn "No se pudo agregar la regla de firewall en MikroTik"
        return 1
    fi
}

agregar_ruta_lan() {
    local via="$1"
    if ! ip route show | grep -q "$LAN_SUBNET"; then
        info "Agregando ruta a LAN $LAN_SUBNET vía $via..."
        if sudo ip route add "$LAN_SUBNET" via "$via"; then
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
            "http://$ip/rest/ip/dhcp-server/lease" 2>/dev/null > "$DEVICES_JSON"; then
            if jq -e '. | length > 0' "$DEVICES_JSON" >/dev/null 2>&1; then
                return 0
            fi
        fi
        sleep 1
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
        @tsv' "$DEVICES_JSON" 2>/dev/null | sort -t$'\t' -k1 > "$LEASES_TSV"
    
    # También incluir entradas de ARP (equipos con IP fija manual)
    curl -s -u "$ADMIN_USER:$ADMIN_PASS" --connect-timeout 5 \
        "http://$mikrotik_ip/rest/ip/arp" 2>/dev/null | \
        jq -r '.[] | select(.dynamic == "false" and .address != "") | 
            [ "Fijo-\(.address)", .address, .mac_address // "?" ] | 
            @tsv' 2>/dev/null >> "$LEASES_TSV"
    
    # Quitar duplicados y ordenar
    sort -u "$LEASES_TSV" -o "$LEASES_TSV"
    
    if [ ! -s "$LEASES_TSV" ]; then
        return 1
    fi
    return 0
}

ping_equipos() {
    info "Verificando equipos disponibles en la red..."
    
    : > "$PING_TSV"
    local total=0
    local disponibles=0
    
    while IFS=$'\t' read -r hostname ip mac; do
        if [ -z "$ip" ] || [ "$ip" = "?" ]; then
            continue
        fi
        total=$((total + 1))
        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            disponibles=$((disponibles + 1))
            echo -e "$hostname\t$ip\t$mac" >> "$PING_TSV"
        fi
    done < "$LEASES_TSV"
    
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
    done < "$PING_TSV"
    
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
    done < "$PING_TSV"
    
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
    info "Conectando a $user@$ip ..."
    echo
    ssh "$user@$ip"
}

# ─── Banner ────────────────────────────────────

echo
echo -e "${AZUL}╔══════════════════════════════════════╗${NORMAL}"
echo -e "${AZUL}║    MIKROTIKS  Red Connect Tool      ║${NORMAL}"
echo -e "${AZUL}╚══════════════════════════════════════╝${NORMAL}"
echo

# ─── Encontrar router en bucle ────────────────

ROUTER_INFO=$(elegir_router) || true

if [ -z "${ROUTER_INFO:-}" ]; then
    error "No se encontró ni el MikroTik ni el Linksys en la red."
    echo
    echo -e "${AMARILLO}Posibles causas:${NORMAL}"
    echo "  - El router está apagado o en otra subred"
    echo "  - Necesitás VPN primero (L2TP/IPsec)"
    echo "  - La tabla ARP está vacía (probá un ping manual)"
    echo
    exit 1
fi

ROUTER_TIPO="${ROUTER_INFO%%$'\t'*}"
ROUTER_IP="${ROUTER_INFO#*$'\t'}"
ok "Router detectado: $ROUTER_TIPO en $ROUTER_IP"

# ─── Obtener equipos ──────────────────────────

if [ "$ROUTER_TIPO" = "mikrotik" ]; then
    info "Obteniendo equipos desde la API del MikroTik..."
    if ! obtener_equipos "$ROUTER_IP"; then
        error "No se pudieron obtener equipos del MikroTik en $ROUTER_IP"
        # Intentar mostrar leases sin procesar para depuración
        if [ -s "$DEVICES_JSON" ]; then
            warn "El MikroTik respondió pero no devolvió leases activos"
        fi
        exit 1
    fi
else
    warn "Sólo se detectó el Linksys ($ROUTER_IP): inventariando por barrido de red."
    if ! inventario_por_scan; then
        error "El barrido no devolvió ningún equipo."
        exit 1
    fi
fi

# ─── Ping a equipos ──────────────────────────

if [ "$ROUTER_TIPO" = "mikrotik" ] && [ "$ROUTER_IP" != "$MIKROTIK_LAN" ]; then
    # En WAN: configurar ruta + firewall para conexión directa
    info "Configurando acceso directo a LAN desde red proveedora..."
    configurar_firewall_mikrotik "$ROUTER_IP" || true
    agregar_ruta_lan "$ROUTER_IP" || true
    cp "$LEASES_TSV" "$PING_TSV"
    ok "Podés conectar directo a los equipos de la LAN"
else
    ping_equipos
    if [ ! -s "$PING_TSV" ]; then
        error "No hay equipos accesibles en este momento."
        exit 1
    fi
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
    
    if [ "$seleccion" -le "$(wc -l < "$PING_TSV")" ] 2>/dev/null; then
        conectar_equipo "$seleccion"
        echo
        echo -e "${VERDE}Conexión finalizada.${NORMAL}"
        echo
        # Volver a mostrar menú después de desconectar
        mostrar_menu
    else
        warn "Selección inválida. Elige entre 0 y $(wc -l < "$PING_TSV")"
    fi
done
