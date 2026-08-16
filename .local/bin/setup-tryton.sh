#!/usr/bin/env bash
# =============================================================================
# setup-tryton.sh — Instalación limpia de Tryton siguiendo la documentación
# oficial (https://docs.tryton.org/projects/server/en/latest/) y la
# wiki de Gentoo (https://wiki.gentoo.org/wiki/Tryton).
#
# Incluye para comenzar una empresa desde cero, expandible:
#   - Países y sus ciudades/subdivisiones (módulo country)
#   - Monedas (currency) + cambio de divisas
#   - Terceros/clientes/proveedores (party)
#   - Empresa / multiempresa (company)
#   - Productos / catálogo / unidades (product)
#   - Inventario (stock, stock_forecast)
#   - Compras (purchase, purchase_request)
#   - Ventas (sale, sale_payment, sale_price_list)
#   - Caja y bancos (bank, account_statement, account_payment)
#   - Contabilidad universal (account + account_invoice + account_product)
#   - Impuestos por país (account_tax_rule_country)
#
# DOS MODOS DE INSTALACIÓN:
#   native  → instalación nativa Gentoo (emerge), serie más reciente del
#             overlay (sin fijar versiones: Portage resuelve la última).
#             Sigue wiki Gentoo: overlay → emerge → config → BD → admin.
#   podman  → contenedorizado con Podman (imagen oficial tryton/tryton),
#             útil para versiones de PRUEBA y para PRODUCCIÓN final.
#
# La instalación es lo más automática posible: la creación del usuario
# "admin" de Tryton usa el mecanismo oficial TRYTONPASSFILE + --email
# (verificado en el código fuente de trytond-admin 8.0), sin entrada manual.
#
# Uso:
#   sudo ./setup-tryton.sh --mode native   [opciones]
#   sudo ./setup-tryton.sh --mode podman   [opciones]
#
# Opciones:
#   --mode native|podman    modo de instalación (obligatorio)
#   --db <nombre>           nombre de la base de datos (default: tryton)
#   --admin-email <correo>  email del usuario admin (default: admin@localhost)
#   --admin-pass <clave>    contraseña admin (default: genera aleatoria)
#   --language <código>     idioma de la BD (default: es)
#   --listen <host:puerto>  interfaz web (default: 0.0.0.0:8000)
#   --skip-modules          no activar módulos de negocio tras la instalación
#   --dry-run               muestra los pasos sin ejecutarlos
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuración por defecto (sobreescribible por flags)
# ----------------------------------------------------------------------------
MODE=""
DB_NAME="tryton"
ADMIN_EMAIL="admin@localhost"
ADMIN_PASS=""
LANGUAGE="es"
LISTEN="0.0.0.0:8000"
ACTIVATE_MODULES=1
DRY_RUN=0

CONF_DIR="/etc/trytond"
CONF_FILE="${CONF_DIR}/trytond.conf"
CONFD_FILE="/etc/conf.d/trytond"
DATA_DIR="/var/lib/trytond"
LOG_DIR="/var/log/trytond"
SAO_ROOT="/usr/share/sao"

# Módulos de negocio base (sin versión: Portage resuelve la última serie).
# Expandible: basta añadir atoms aquí o con --update-modules-list después.
NATIVE_PKGS_CORE="app-office/trytond app-office/tryton app-office/sao"
NATIVE_PKGS_MODULES="
    app-tryton/country
    app-tryton/currency
    app-tryton/party
    app-tryton/company
    app-tryton/product
    app-tryton/account
    app-tryton/account_invoice
    app-tryton/account_product
    app-tryton/account_payment
    app-tryton/account_statement
    app-tryton/account_rule
    app-tryton/account_tax_rule_country
    app-tryton/account_stock_continental
    app-tryton/bank
    app-tryton/stock
    app-tryton/stock_forecast
    app-tryton/purchase
    app-tryton/purchase_request
    app-tryton/sale
    app-tryton/sale_payment
    app-tryton/sale_price_list
"

# Módulos Tryton (nombres internos) a ACTIVAR en la base de datos, con sus
# dependencias activadas automáticamente (--activate-dependencies).
TRYTOND_MODULES="
    country
    currency
    party
    company
    product
    account
    account_invoice
    account_product
    account_payment
    account_statement
    account_rule
    account_tax_rule_country
    account_stock_continental
    bank
    stock
    stock_forecast
    purchase
    purchase_request
    sale
    sale_payment
    sale_price_list
"

# Imagen oficial de Tryton (Docker Hub). "latest" es la serie más reciente;
# existen tags como 8.0-office (con LibreOffice para reportes).
PODMAN_IMAGE="tryton/tryton:latest"
PODMAN_NAME="tryton"
PODMAN_VOL_DATA="tryton-data"
PODMAN_VOL_PG="tryton-postgres"
PODMAN_PORT="8000:8000"

# ----------------------------------------------------------------------------
# Colores / utilidades
# ----------------------------------------------------------------------------
AZUL="\033[1;34m"; VERDE="\033[1;32m"; AMARILLO="\033[1;33m"; ROJO="\033[1;31m"
RESET="\033[0m"

info()  { echo -e "${AZUL}[INFO]${RESET} $*"; }
ok()    { echo -e "${VERDE}[OK]${RESET} $*"; }
warn()  { echo -e "${AMARILLO}[AVISO]${RESET} $*"; }
err()   { echo -e "${ROJO}[ERROR]${RESET} $*" >&2; }
die()   { err "$*"; exit 1; }

run() { # ejecuta un comando como root (el script se invoca con sudo)
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${AMARILLO}[DRY]${RESET} $*"
        return 0
    fi
    "$@"
}

run_psql() { # comando SQL como usuario postgres
    run sudo -u postgres psql -tAc "$1"
}

gen_pass() {
    head -c 16 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Ejecutá con sudo: sudo $0 --mode native|podman"
    fi
}

# ----------------------------------------------------------------------------
# Parsing de argumentos
# ----------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --mode)        MODE="$2"; shift 2 ;;
        --db)          DB_NAME="$2"; shift 2 ;;
        --admin-email) ADMIN_EMAIL="$2"; shift 2 ;;
        --admin-pass)  ADMIN_PASS="$2"; shift 2 ;;
        --language)    LANGUAGE="$2"; shift 2 ;;
        --listen)      LISTEN="$2"; shift 2 ;;
        --skip-modules) ACTIVATE_MODULES=0; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        -h|--help)     sed -n '2,60p' "$0"; exit 0 ;;
        *) die "Opción desconocida: $1 (mirá --help)" ;;
    esac
done

[ -z "$MODE" ] && die "--mode native|podman es obligatorio (mirá --help)"
[ "$MODE" != "native" ] && [ "$MODE" != "podman" ] && die "Modo inválido: $MODE"

[ -z "$ADMIN_PASS" ] && ADMIN_PASS="$(gen_pass)"

require_root
ok "Modo: ${MODE} | BD: ${DB_NAME} | idioma: ${LANGUAGE} | listen: ${LISTEN}"

# ============================================================================
# MODO NATIVO — instalación Gentoo (emerge)
# ============================================================================
instalar_native() {
    info "Activando overlay tryton (wiki Gentoo: eselect-repository)"
    if [ "$DRY_RUN" -eq 1 ]; then
        run emerge --ask n eselect-repository
    else
        if ! emerge -pv app-eselect/eselect-repository >/dev/null 2>&1 \
                && ! command -v eselect-repository >/dev/null; then
            emerge --ask app-eselect/eselect-repository
        fi
        if ! eselect repository list 2>/dev/null | grep -q "tryton"; then
            eselect repository enable tryton
        fi
        eselect repository list | grep -q "tryton" \
            || die "No se pudo activar el overlay tryton"
    fi
    ok "Overlay tryton listo"

    info "Emergiendo servidor, clientes y módulos (última serie del overlay)"
    run emerge --ask --autounmask=y --autounmask-write \
        ${NATIVE_PKGS_CORE} ${NATIVE_PKGS_MODULES}
    if [ "$DRY_RUN" -eq 0 ]; then
        dispatch-conf >/dev/null 2>&1 || true
        emerge --ask ${NATIVE_PKGS_CORE} ${NATIVE_PKGS_MODULES}
    fi
    ok "Paquetes instalados"

    info "Configurando PostgreSQL"
    if [ "$DRY_RUN" -eq 0 ]; then
        if ! rc-service postgresql status >/dev/null 2>&1; then
            rc-service postgresql start
            rc-update add postgresql default
        fi
        # Crea el usuario de BD 'trytond' (comportamiento oficial del ebuild:
        # emerge --config =app-office/trytond-*)
        if ! run_psql "SELECT 1 FROM pg_user WHERE usename='trytond'" \
                | grep -q 1; then
            sudo -u postgres createuser --createdb trytond
            ok "Usuario de BD 'trytond' creado"
        else
            ok "Usuario de BD 'trytond' ya existe"
        fi
    fi

    info "Escribiendo configuración en ${CONF_FILE}"
    run mkdir -p "${CONF_DIR}" "${DATA_DIR}" "${LOG_DIR}"
    if [ "$DRY_RUN" -eq 0 ]; then
        cat > "${CONF_FILE}" <<EOF
[database]
uri = postgresql://trytond@localhost:5432/
path = ${DATA_DIR}
language = ${LANGUAGE}

[web]
listen = ${LISTEN}
root = ${SAO_ROOT}

[session]
super_pwd = tryton
EOF
        chown -R trytond:trytond "${DATA_DIR}" "${LOG_DIR}"
    fi

    info "Configurando /etc/conf.d/trytond (init.d de Gentoo)"
    if [ "$DRY_RUN" -eq 0 ]; then
        cat > "${CONFD_FILE}" <<EOF
# Configuración del servicio trytond (OpenRC)
CONFIG="${CONF_FILE}"
DATABASES="${DB_NAME}"
EOF
        # trytond-cron y trytond-worker usan el mismo conf.d
        cp "${CONFD_FILE}" /etc/conf.d/trytond-cron
        cp "${CONFD_FILE}" /etc/conf.d/trytond-worker
    fi

    info "Inicializando la base de datos Tryton (trytond-admin --all)"
    # Automatización oficial: TRYTONPASSFILE + --email evitan la interacción.
    if [ "$DRY_RUN" -eq 0 ]; then
        local passfile
        passfile="$(mktemp)"
        echo "$ADMIN_PASS" > "$passfile"
        TRYTONPASSFILE="$passfile" trytond-admin \
            -c "${CONF_FILE}" -d "${DB_NAME}" --all \
            --email "${ADMIN_EMAIL}"
        rm -f "$passfile"

        info "Actualizando lista de módulos (trytond-admin --update-modules-list)"
        trytond-admin -c "${CONF_FILE}" -d "${DB_NAME}" --update-modules-list

        if [ "${ACTIVATE_MODULES}" -eq 1 ]; then
            info "Activando módulos de negocio (trytond-admin -u ... --activate-dependencies)"
            trytond-admin -c "${CONF_FILE}" -d "${DB_NAME}" \
                -u ${TRYTOND_MODULES} --activate-dependencies
        fi
    fi

    info "Arrancando servicios (trytond, cron y worker)"
    if [ "$DRY_RUN" -eq 0 ]; then
        for s in trytond trytond-cron trytond-worker; do
            rc-service "$s" start || true
            rc-update add "$s" default || true
        done
    fi

    ok "Instalación nativa completada."
}

# ============================================================================
# MODO PODMAN — instalación contenedorizada (pruebas y producción)
# ============================================================================
instalar_podman() {
    if [ "$DRY_RUN" -eq 0 ] && ! command -v podman >/dev/null; then
        die "Podman no está instalado. Emergilo: emerge --ask app-containers/podman"
    fi

    info "Descargando imagen oficial ${PODMAN_IMAGE}"
    run podman pull "${PODMAN_IMAGE}"

    info "Creando volúmenes persistentes"
    run podman volume create "${PODMAN_VOL_DATA}"
    run podman volume create "${PODMAN_VOL_PG}"

    info "Eliminando contenedor previo si existe"
    if podman container exists "${PODMAN_NAME}" 2>/dev/null; then
        run podman rm -f "${PODMAN_NAME}"
    fi

    info "Lanzando contenedor Tryton (puerto ${PODMAN_PORT})"
    # La imagen oficial tryton/tryton arranca trytond + PostgreSQL embebidos.
    # Los volúmenes preservan datos y filestore entre reinicios.
    # --restart=unless-stopped: necesario para que el servicio OpenRC
    # podman-restart lo arranque al boot.
    run podman run -d --name "${PODMAN_NAME}" \
        --restart=unless-stopped \
        -p "${PODMAN_PORT}" \
        -v "${PODMAN_VOL_DATA}:/var/lib/trytond" \
        -v "${PODMAN_VOL_PG}:/var/lib/postgresql" \
        "${PODMAN_IMAGE}"

    info "Esperando a que el contenedor esté listo"
    if [ "$DRY_RUN" -eq 0 ]; then
        for ((i = 1; i <= 30; i++)); do
            if podman exec "${PODMAN_NAME}" true 2>/dev/null; then
                break
            fi
            sleep 2
        done

        info "Inicializando BD y usuario admin dentro del contenedor"
        local passfile
        passfile="$(mktemp)"
        echo "$ADMIN_PASS" > "$passfile"
        podman exec -e TRYTONPASSFILE=/tmp/.trytonpass \
            "${PODMAN_NAME}" sh -c \
            "echo '$ADMIN_PASS' > /tmp/.trytonpass && \
             trytond-admin -d ${DB_NAME} --all --email ${ADMIN_EMAIL}"
        rm -f "$passfile"

        podman exec "${PODMAN_NAME}" \
            trytond-admin -d "${DB_NAME}" --update-modules-list

        if [ "${ACTIVATE_MODULES}" -eq 1 ]; then
            info "Activando módulos de negocio en el contenedor"
            podman exec "${PODMAN_NAME}" \
                trytond-admin -d "${DB_NAME}" \
                -u ${TRYTOND_MODULES} --activate-dependencies
        fi

        info "Activando inicio automático del contenedor (OpenRC)"
        # El servicio OpenRC podman-restart (provisto por el ebuild de podman)
        # arranca al boot todos los contenedores con restart-policy=always o
        # unless-stopped. El contenedor se creó con --restart=unless-stopped
        # para quedar cubierto por él.
        rc-update add podman-restart default
        rc-service podman-restart start || true
    fi

    ok "Instalación Podman completada."
}

# ============================================================================
# Ejecución principal
# ============================================================================
case "$MODE" in
    native) instalar_native ;;
    podman) instalar_podman ;;
esac

# ----------------------------------------------------------------------------
# Resumen final
# ----------------------------------------------------------------------------
echo
echo -e "${VERDE}====================================================================${RESET}"
echo -e "${VERDE}  TRYTON INSTALADO — próximo paso: conectar el cliente${RESET}"
echo -e "${VERDE}====================================================================${RESET}"
if [ "$MODE" = "native" ]; then
    echo "  Cliente web SAO:  http://localhost:8000  (root=${SAO_ROOT})"
    echo "  Cliente GTK:      tryton"
else
    echo "  Cliente web:      http://localhost:8000"
fi
echo "  Base de datos:    ${DB_NAME}"
echo "  Usuario admin:    ${ADMIN_EMAIL}"
echo "  Clave admin:      ${ADMIN_PASS}"
echo "  Idioma:           ${LANGUAGE}"
echo
echo "  Siguientes pasos recomendados (desde la interfaz):"
echo "   1. Administración → Compañías → crear la empresa (datos + moneda)."
echo "   2. Contabilidad → Crear plan de cuentas (universal) y tipos de cuenta."
echo "   3. Cargar países/ciudades desde 'Datos de ejemplo' (módulo country)."
echo "   4. Configurar bancos (bank) y caja (account_statement)."
echo "   5. Cargar productos, tarifas y terceros."
echo
echo "  Para expandir módulos más adelante:"
echo "     emerge --ask app-tryton/<modulo>   # y luego:"
echo "     trytond-admin -c ${CONF_FILE} -d ${DB_NAME} --update-modules-list"
echo "     trytond-admin -c ${CONF_FILE} -d ${DB_NAME} -u <modulo> --activate-dependencies"
echo -e "${VERDE}====================================================================${RESET}"
