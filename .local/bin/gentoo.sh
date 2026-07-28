#!/bin/bash
# gentoo.sh — Asistente de instalación guiada de Gentoo
# Basado en el Handbook AMD64 oficial (actualizado 2025)
# Ejecutar desde cualquier LiveCD o sistema Gentoo existente.
#
# Uso:  sudo ./gentoo.sh [--resume]
#   --resume  reanuda desde el último paso completado

set -euo pipefail

# ── Colores ────────────────────────────────────────────────────────────────
RST="\e[0m"; B="\e[1m"; D="\e[2m"
G="\e[32m"; Y="\e[33m"; C="\e[36m"; R="\e[31m"; M="\e[35m"

info()  { echo -e " ${C}→${RST} $*"; }
ok()    { echo -e " ${G}✓${RST} $*"; }
warn()  { echo -e " ${Y}⚠${RST} $*"; }
err()   { echo -e " ${R}✗${RST} $*"; }
title() { echo -e "\n${B}══ $1 ══${RST}\n"; }
step()  { echo -e "\n${M}◆${RST} ${B}Paso $1:${RST} $2\n"; }

# ── Estado ─────────────────────────────────────────────────────────────────
STATE_FILE="/tmp/gentoo-install-state"
CHROOT="/mnt/gentoo"
STEP=0

load_state() {
  if [ -f "$STATE_FILE" ]; then
    STEP=$(cat "$STATE_FILE")
    info "Reanudando desde paso $STEP"
  fi
}

save_state() { echo "$1" > "$STATE_FILE"; }
clear_state() { rm -f "$STATE_FILE"; }

pause() {
  echo
  read -rp "  Presiona Enter para continuar (o Ctrl+C para salir)... "
  echo
}

confirm_destructive() {
  local msg="$1"
  echo
  echo -e " ${R}⚠ ATENCIÓN:${RST} $msg"
  read -rp "  Escribe 'yes' para confirmar: " reply
  [ "$reply" = "yes" ] || { err "Cancelado."; exit 1; }
  echo
}

# Resuelve nombres de partición según el tipo de disco
resolve_parts() {
  local disk="$1"
  local name="${disk#/dev/}"
  PART1="${disk}1"; PART2="${disk}2"; PART3="${disk}3"
  if echo "$name" | grep -q 'nvme\|mmc\|nbd'; then
    PART1="${disk}p1"; PART2="${disk}p2"; PART3="${disk}p3"
  fi
}

# ── Paso 0: Información del hardware destino ─────────────────────────────
step_hardware_info() {
  step 0 "Información del hardware DESTINO"

  echo -e " ${D}Necesito saber las características de la máquina donde se usará${RST}"
  echo -e " ${D}Gentoo para optimizar los flags de compilación.${RST}"
  echo
  echo -e " ${Y}Opción A:${RST} Pegar la salida de 'cat /proc/cpuinfo' de la máquina destino"
  echo -e " ${Y}Opción B:${RST} Ingresar manualmente CPU y número de hilos"
  echo
  read -rp "  ¿Opción (A/B)? " cpu_opt
  echo

  TARGET_ARCH=""
  TARGET_THREADS=""

  if [ "$cpu_opt" = "A" ] || [ "$cpu_opt" = "a" ]; then
    echo -e " ${D}Pega el contenido de /proc/cpuinfo de la máquina destino.${RST}"
    echo -e " ${D}Termina con Ctrl+D (o una línea con solo 'EOF'):${RST}"
    echo

    CPUINFO=$(mktemp)
    cat > "$CPUINFO"

    local cpu_flags model_name cpu_cores
    cpu_flags=$(head -1 "$CPUINFO" 2>/dev/null | grep -m1 'flags' || true)
    model_name=$(grep -m1 'model name' "$CPUINFO" 2>/dev/null | sed 's/.*: //' || echo "desconocido")
    cpu_cores=$(grep -c '^processor' "$CPUINFO" 2>/dev/null || echo "1")

    TARGET_THREADS=$cpu_cores

    echo
    echo -e "  ${B}CPU detectado:${RST} $model_name"
    echo -e "  ${B}Hilos:${RST}        $cpu_cores"
    echo

    if echo "$cpu_flags" | grep -q 'znver5'; then
      TARGET_ARCH="znver5"
    elif echo "$cpu_flags" | grep -q 'znver4'; then
      TARGET_ARCH="znver4"
    elif echo "$cpu_flags" | grep -q 'znver3' || echo "$model_name" | grep -qi 'ryzen [5-9]\|ryzen 7\|ryzen 9\|threadripper\|epyc.*7\|epyc.*9'; then
      TARGET_ARCH="znver3"
    elif echo "$cpu_flags" | grep -q 'znver2' || echo "$model_name" | grep -qi 'ryzen [3-4]\|ryzen 5 2\|ryzen 7 2'; then
      TARGET_ARCH="znver2"
    elif echo "$cpu_flags" | grep -q 'znver1'; then
      TARGET_ARCH="znver1"
    elif echo "$cpu_flags" | grep -q 'avx512' && echo "$cpu_flags" | grep -q 'clflushopt'; then
      TARGET_ARCH="skylake-avx512"
    elif echo "$cpu_flags" | grep -q 'avx2' && echo "$cpu_flags" | grep -q 'clwb'; then
      TARGET_ARCH="skylake"
    elif echo "$cpu_flags" | grep -q 'avx2'; then
      TARGET_ARCH="haswell"
    elif echo "$cpu_flags" | grep -q 'avx'; then
      TARGET_ARCH="sandybridge"
    else
      TARGET_ARCH="x86-64-v2"
    fi

    echo -e "  ${B}march sugerido:${RST} -march=$TARGET_ARCH"
    rm -f "$CPUINFO"
  else
    echo -e " ${D}Ingresa manualmente los datos del CPU destino:${RST}"
    echo
    read -rp "  Arquitectura / march target (ej: znver3, skylake, haswell, x86-64-v2): " TARGET_ARCH
    read -rp "  Número de hilos (cores × threads): " TARGET_THREADS
    echo
  fi

  # RAM
  read -rp "  RAM de la máquina destino en GB (ej: 8, 16, 32): " TARGET_RAM

  local load_avg=$(( TARGET_THREADS + 2 ))
  if [ "$TARGET_RAM" -lt 4 ]; then
    TARGET_JOBS=1
  elif [ "$TARGET_RAM" -lt 8 ]; then
    TARGET_JOBS=$(( TARGET_THREADS / 2 ))
  else
    TARGET_JOBS=$TARGET_THREADS
  fi
  [ "$TARGET_JOBS" -lt 1 ] && TARGET_JOBS=1
  TARGET_MAKEOPTS="-j$TARGET_JOBS -l$load_avg"

  echo
  echo -e "  ${B}MAKEOPTS:${RST} $TARGET_MAKEOPTS"
  echo -e "  ${B}CFLAGS:${RST}  -march=$TARGET_ARCH -O2 -pipe"
  echo

  # Modo kernel (genkernel obsoleto — reemplazado por auto-compile o binario)
  echo -e " ${D}¿Cómo quieres manejar el kernel?${RST}"
  echo
  echo "  1) Compilación automática (detecta hardware del LiveCD con localmodconfig"
  echo "     y compila un kernel optimizado — RECOMENDADO)"
  echo "  2) Kernel binario (gentoo-kernel-bin — emerge y listo, no compila)"
  echo "  3) Manual (yo configuro el kernel dentro del chroot)"
  echo
  read -rp "  Opción (1-3): " kernel_opt
  KERNEL_MODE="auto"
  [ "$kernel_opt" = "2" ] && KERNEL_MODE="binary"
  [ "$kernel_opt" = "3" ] && KERNEL_MODE="manual"
  echo

  # GPU
  echo -e " ${D}¿Qué GPU tiene la máquina destino? (para VIDEO_CARDS)${RST}"
  echo
  echo "  1) AMD/ATI (amdgpu radeonsi)"
  echo "  2) Intel"
  echo "  3) NVIDIA (nouveau — open source)"
  echo "  4) NVIDIA (proprietary — nvidia)"
  echo "  5) Virtual machine (virtio)"
  echo "  6) Otra / No sé"
  echo
  read -rp "  Opción (1-6): " gpu_opt
  case "$gpu_opt" in
    1) TARGET_VIDEO_CARDS="amdgpu radeonsi" ;;
    2) TARGET_VIDEO_CARDS="intel" ;;
    3) TARGET_VIDEO_CARDS="nouveau" ;;
    4) TARGET_VIDEO_CARDS="nvidia" ;;
    5) TARGET_VIDEO_CARDS="virtio" ;;
    *) TARGET_VIDEO_CARDS="" ;;
  esac
  echo

  read -rp "  Hostname para la nueva instalación [gentoo-box]: " TARGET_HOSTNAME
  TARGET_HOSTNAME="${TARGET_HOSTNAME:-gentoo-box}"
  echo

  read -rp "  Usuario del sistema (opcional, dejar vacío para saltar): " TARGET_USERNAME
  echo

  ok "Información de hardware recopilada"
  save_state 1
  pause
}

# ── Paso 1: Seleccionar disco destino ─────────────────────────────────────
step_select_disk() {
  step 1 "Seleccionar disco destino"

  # Detectar disco del sistema activo — maneja LiveCD (overlay/squashfs)
  local system_disk
  system_disk=$(findmnt -n -o SOURCE / 2>/dev/null || true)

  # Si estamos en LiveCD, findmnt devuelve overlay o tmpfs — no hay disco que excluir
  if echo "$system_disk" | grep -qE '^(overlay|tmpfs|squashfs|/dev/loop)'; then
    system_disk=""
    echo -e "  ${D}Entorno LiveCD detectado — no se excluirá ningún disco.${RST}"
  else
    # Extraer disco base (eliminar número de partición)
    system_disk=$(echo "$system_disk" | sed 's/p[0-9]*$//; s/[0-9]*$//')
    echo -e "  Disco del sistema actual: ${D}$system_disk (excluido)${RST}"
  fi
  echo

  echo -e "  ${B}Discos disponibles:${RST}"
  echo

  local disks=()
  while read -r line; do
    local name size model
    name=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    model=$(echo "$line" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' | sed 's/ *$//')
    [ -z "$model" ] && model="(sin modelo)"

    # Excluir disco del sistema, zram, y loop
    if [ -n "$system_disk" ] && { [ "/dev/$name" = "$system_disk" ] || [ "/dev/${name%[0-9]}" = "$system_disk" ] || [ "/dev/${name%p[0-9]}" = "$system_disk" ]; }; then
      continue
    fi
    echo "$name" | grep -qE '^loop|^zram|^sr' && continue

    disks+=("$name|$size|$model")
  done < <(lsblk -d -o NAME,SIZE,MODEL -n 2>/dev/null || true)

  if [ ${#disks[@]} -eq 0 ]; then
    warn "No se detectaron discos disponibles."
    echo
    read -rp "  Ingresa el dispositivo manualmente (ej: /dev/sda): " TARGET_DISK
  else
    for i in "${!disks[@]}"; do
      IFS='|' read -r dname dsize dmodel <<< "${disks[$i]}"
      echo "  $((i+1))) /dev/$dname  —  $dsize  —  $dmodel"
    done
    echo
    read -rp "  Selecciona disco (1-${#disks[@]}): " disk_idx
    IFS='|' read -r dname dsize dmodel <<< "${disks[$((disk_idx-1))]}"
    TARGET_DISK="/dev/$dname"
  fi

  # Detectar tipo de disco: 0=SSD/NVMe, 1=HDD
  local base_name="${TARGET_DISK#/dev/}"
  if [ -f "/sys/block/$base_name/queue/rotational" ]; then
    TARGET_DISK_ROTATIONAL=$(cat "/sys/block/$base_name/queue/rotational")
  else
    TARGET_DISK_ROTATIONAL=1  # asume HDD si no se puede detectar
  fi

  if [ "$TARGET_DISK_ROTATIONAL" -eq 0 ]; then
    echo -e "  ${D}Tipo:${RST} ${B}SSD / NVMe${RST} — se usará tmpfs para compilaciones (menos escritura)"
  else
    echo -e "  ${D}Tipo:${RST} ${Y}HDD${RST} — tmpfs no configurado (no hay beneficio en desgaste)"
  fi
  echo
  echo -e "  ${B}Disco seleccionado:${RST} $TARGET_DISK"
  echo
  confirm_destructive "Esto BORRARÁ TODOS LOS DATOS en $TARGET_DISK"

  save_state 2
  pause
}

# ── Paso 2: Particionar (GPT + UEFI) ──────────────────────────────────────
step_partition() {
  step 2 "Particionar disco (GPT + UEFI)"

  SWAP_SIZE=""  # global: usada por pasos posteriores

  echo -e " ${D}Esquema de particiones:${RST}"
  echo
  echo "    1) EFI System Partition  —  vfat  —  /efi"
  echo "    2) swap                   —  opcional según RAM"
  echo "    3) root                   —  ext4/btrfs/xfs  —  resto"
  echo
  echo -e "  ${Y}¿Personalizar tamaños?${RST}"
  read -rp "  Tamaño EFI en GB [1]: " efi_size
  efi_size="${efi_size:-1}"

  # Swap: automático según RAM, pero permitir override
  if [ "$TARGET_RAM" -le 8 ]; then
    echo
    echo -e "  ${D}RAM ≤ 8GB → swap recomendado. Tamaño en GB [4]:${RST}"
    read -rp "  (0 = sin swap): " swap_size
    swap_size="${swap_size:-4}"
  else
    echo
    echo -e "  ${D}RAM > 8GB → swap no necesario (a menos que uses hibernación).${RST}"
    read -rp "  Tamaño swap en GB [0] (ej: 4, 8, 0=sin swap): " swap_size
    swap_size="${swap_size:-0}"
  fi
  SWAP_SIZE=$swap_size

  # Filesystem para root (Handbook: XFS recomendado)
  echo
  echo "  Sistema de archivos para /:"
  echo "    1) ext4  (simple, compatible)"
  echo "    2) btrfs (snapshots, compresión, subvolúmenes)"
  echo "    3) xfs   (recomendado — rápido, reflink, CoW)"
  echo
  read -rp "  Opción (1/2/3): " fs_opt
  case "$fs_opt" in
    2) ROOT_FS="btrfs" ;;
    3) ROOT_FS="xfs" ;;
    *) ROOT_FS="ext4" ;;
  esac

  echo
  echo -e " ${R}⚠ Ejecutando particionado en ${B}$TARGET_DISK${RST}${R}...${RST}"
  echo

  resolve_parts "$TARGET_DISK"

  # Crear tabla GPT
  echo -e "  ${D}Creando tabla GPT...${RST}"
  parted -s "$TARGET_DISK" mklabel gpt

  # EFI System Partition (siempre)
  echo -e "  ${D}Creando EFI System Partition (${efi_size}GB)...${RST}"
  parted -s "$TARGET_DISK" mkpart primary fat32 1MiB "${efi_size}GiB"
  parted -s "$TARGET_DISK" set 1 esp on

  if [ "$SWAP_SIZE" -gt 0 ]; then
    # Swap
    echo -e "  ${D}Creando partición swap (${SWAP_SIZE}GB)...${RST}"
    parted -s "$TARGET_DISK" mkpart primary "${efi_size}GiB" "$((efi_size + SWAP_SIZE))GiB"
    # Root (resto del disco)
    echo -e "  ${D}Creando partición root (resto del disco)...${RST}"
    parted -s "$TARGET_DISK" mkpart primary "$((efi_size + SWAP_SIZE))GiB" 100%
  else
    # Sin swap: root es la segunda partición
    echo -e "  ${D}Sin swap — creando root como partición 2 (todo el resto)...${RST}"
    parted -s "$TARGET_DISK" mkpart primary "${efi_size}GiB" 100%
  fi

  ok "Particionado completado"
  echo
  if [ "$SWAP_SIZE" -gt 0 ]; then
    echo -e "  ${Y}⚠ Recuerda:${RST} Las particiones swap y root se formatearán"
  else
    echo -e "  ${Y}⚠ Recuerda:${RST} Sin swap configurado."
  fi
  echo -e "  con los sistemas de archivos correctos en el siguiente paso."
  save_state 3
  pause
}

# ── Paso 3: Formatear particiones ─────────────────────────────────────────
step_format() {
  step 3 "Formatear particiones"

  resolve_parts "$TARGET_DISK"

  # root es PART2 si no hay swap, PART3 si hay swap
  local root_part
  if [ "$SWAP_SIZE" -gt 0 ]; then
    root_part="$PART3"
  else
    root_part="$PART2"
  fi

  echo -e "  ${D}Formateando EFI (vfat)...${RST}"
  mkfs.vfat -F 32 "$PART1"

  if [ "$SWAP_SIZE" -gt 0 ]; then
    echo -e "  ${D}Formateando swap...${RST}"
    mkswap "$PART2"
  else
    echo -e "  ${Y}Sin swap — omitido.${RST}"
  fi

  echo -e "  ${D}Formateando root (${B}$ROOT_FS${RST}${D}) en ${B}$root_part${RST}${D}...${RST}"
  case "$ROOT_FS" in
    btrfs) mkfs.btrfs -f "$root_part" ;;
    xfs)   mkfs.xfs -f "$root_part" ;;
    *)     mkfs.ext4 -F "$root_part" ;;
  esac

  ok "Particiones formateadas"
  save_state 4
  pause
}

# ── Paso 4: Montar ────────────────────────────────────────────────────────
step_mount() {
  step 4 "Montar particiones"

  resolve_parts "$TARGET_DISK"

  # root es PART2 si no hay swap, PART3 si hay swap
  local root_part
  if [ "$SWAP_SIZE" -gt 0 ]; then
    root_part="$PART3"
  else
    root_part="$PART2"
  fi

  mkdir -p "$CHROOT"

  echo -e "  ${D}Montando root ($root_part) en $CHROOT...${RST}"
  mount "$root_part" "$CHROOT"

  # NOTA: La ESP se monta en /efi, no en /boot (Handbook v2025+)
  # GRUB pone los kernels en /boot, la ESP va en /efi
  echo -e "  ${D}Creando y montando /efi (ESP)...${RST}"
  mkdir -p "$CHROOT/efi"
  mount "$PART1" "$CHROOT/efi"

  if [ "$SWAP_SIZE" -gt 0 ]; then
    echo -e "  ${D}Activando swap...${RST}"
    swapon "$PART2" 2>/dev/null || true
  else
    echo -e "  ${Y}Sin swap — omitido.${RST}"
  fi

  ok "Particiones montadas"
  echo
  echo -e "  ${D}Puntos de montaje:${RST}"
  echo "    $CHROOT/     → root ($ROOT_FS)"
  echo "    $CHROOT/efi  → ESP (vfat)"
  if [ "$SWAP_SIZE" -gt 0 ]; then
    echo "    swap         → activado"
  else
    echo "    swap         → no configurado"
  fi
  save_state 5
  pause
}

# ── Paso 5: make.conf ─────────────────────────────────────────────────────
step_make_conf() {
  step 5 "Configurar make.conf con optimizaciones para hardware destino"

  mkdir -p "$CHROOT/etc/portage"

  cat > "$CHROOT/etc/portage/make.conf" <<- MAKECONF
# gentoo.sh — Generado para hardware destino
# CPU: -march=$TARGET_ARCH
# MAKEOPTS optimizado para ${TARGET_THREADS} hilos

CHOST="x86_64-pc-linux-gnu"
CFLAGS="-march=$TARGET_ARCH -O2 -pipe"
CXXFLAGS="\${CFLAGS}"

# Optimizaciones para Rust
RUSTFLAGS="\${RUSTFLAGS} -C target-cpu=native"

# Compilación paralela
MAKEOPTS="$TARGET_MAKEOPTS"

# Acelerar Portage — compilación en tmpfs (RAM)
PORTAGE_TMPFS="/tmp"
FEATURES="\${FEATURES} parallel-fetch parallel-install"
EMERGE_DEFAULT_OPTS="--jobs=1 --load-average=$((TARGET_THREADS + 2)) --keep-going"

# ccache — acelera recompilaciones (emerge dev-util/ccache)
FEATURES="\${FEATURES} ccache"
CCACHE_SIZE="10G"

# Descarga
GENTOO_MIRRORS="https://distfiles.gentoo.org"

# Soporte de idioma
L10N="es"
LINGUAS="es"
MAKECONF

  if [ -n "$TARGET_VIDEO_CARDS" ]; then
    echo "VIDEO_CARDS=\"$TARGET_VIDEO_CARDS\"" >> "$CHROOT/etc/portage/make.conf"
  fi

  # Crear package.use para VIDEO_CARDS (Handbook: usar -* para limpiar defaults)
  if [ -n "$TARGET_VIDEO_CARDS" ]; then
    mkdir -p "$CHROOT/etc/portage/package.use"
    cat > "$CHROOT/etc/portage/package.use/00video-cards" <<- VCONF
# Video cards config — gentoo.sh
*/* VIDEO_CARDS: -* $TARGET_VIDEO_CARDS
VCONF
  fi

  ok "make.conf configurado en $CHROOT/etc/portage/make.conf"
  echo
  echo -e "  ${D}Contenido:${RST}"
  cat "$CHROOT/etc/portage/make.conf"
  echo
  save_state 6
  pause
}

# ── Paso 6: Descargar y extraer stage3 ────────────────────────────────────
step_stage3() {
  step 6 "Descargar y extraer Stage3"

  # ── Sincronizar hora (Handbook: necesario para HTTPS) ──
  echo -e " ${D}¿Sincronizar hora del sistema antes de descargar?${RST}"
  echo "  (necesaria para conexiones HTTPS y verificación GPG)"
  echo
  echo "  1) Sincronizar automáticamente con chronyd (NTP)"
  echo "  2) Ingresar hora manualmente"
  echo "  3) Saltar — la hora ya es correcta"
  echo
  read -rp "  Opción (1-3): " time_opt
  case "$time_opt" in
    1)
      if command -v chronyd &>/dev/null; then
        chronyd -q || warn "chronyd falló — instala net-misc/chrony o usa opción manual"
      else
        warn "chronyd no está disponible. Instala net-misc/chrony en el LiveCD."
      fi
      ;;
    2)
      read -rp "  Fecha/hora (formato MMDDhhmmYYYY, ej: 012612002026): " manual_time
      date "$manual_time" 2>/dev/null || warn "Formato incorrecto"
      ;;
  esac
  echo

  local stage3_url stage3_file

  echo -e "  ${D}Selecciona el perfil Stage3:${RST}"
  echo
  echo "  1) stage3-amd64-desktop-openrc  (perfil desktop, recomendado)"
  echo "  2) stage3-amd64-openrc          (mínimo, sin GUI)"
  echo "  3) stage3-amd64-nomultilib-openrc (64-bit puro)"
  echo "  4) stage3-amd64-desktop-systemd  (desktop + systemd)"
  echo "  5) Ingresar URL manualmente"
  echo
  read -rp "  Opción (1-5): " s3_opt
  echo

  STAGE3_FLAVOR="stage3-amd64-desktop-openrc"
  case "$s3_opt" in
    2) STAGE3_FLAVOR="stage3-amd64-openrc" ;;
    3) STAGE3_FLAVOR="stage3-amd64-nomultilib-openrc" ;;
    4) STAGE3_FLAVOR="stage3-amd64-desktop-systemd" ;;
    5)
      read -rp "  URL del stage3: " stage3_url
      STAGE3_FLAVOR="custom"
      ;;
  esac

  if [ "$STAGE3_FLAVOR" != "custom" ]; then
    echo -e "  ${D}Obteniendo URL de la última versión de $STAGE3_FLAVOR...${RST}"
    stage3_url=$(curl -sf "https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-$STAGE3_FLAVOR.txt" 2>/dev/null \
      | grep -v '^#' | grep 'tar.xz$' | head -1 | awk '{print $1}' || true)

    if [ -n "$stage3_url" ]; then
      stage3_url="https://distfiles.gentoo.org/releases/amd64/autobuilds/$stage3_url"
    else
      warn "No se pudo determinar la URL automáticamente."
      echo
      echo -e "  ${D}Podés descargarlo manualmente desde:${RST}"
      echo "    https://www.gentoo.org/downloads/"
      echo
      read -rp "  Ingresa la URL del stage3: " stage3_url
    fi
  fi

  stage3_file="/tmp/$(basename "$stage3_url")"
  local digest_file="/tmp/$(basename "$stage3_url").DIGESTS"
  local asc_file="/tmp/$(basename "$stage3_url").asc"

  echo
  echo -e "  ${D}Descargando stage3...${RST}"
  echo -e "  ${D}URL:${RST} $stage3_url"
  echo
  curl -L --progress-bar -o "$stage3_file" "$stage3_url"

  # ── Verificación (Handbook: GPG + SHA256) ──────────────
  echo
  echo -e " ${D}¿Verificar integridad del stage3? (recomendado)${RST}"
  echo "  1) Verificar con GPG + SHA256"
  echo "  2) Saltar verificación"
  echo
  read -rp "  Opción (1/2): " verify_opt
  echo

  if [ "$verify_opt" = "1" ]; then
    echo -e "  ${D}Descargando archivos de verificación...${RST}"
    curl -sfL -o "$digest_file" "${stage3_url}.DIGESTS" || true
    curl -sfL -o "$asc_file" "${stage3_url}.asc" || true

    # GPG verification
    if command -v gpg &>/dev/null && [ -f "$asc_file" ] && [ -s "$asc_file" ]; then
      echo -e "  ${D}Verificando firma GPG...${RST}"
      # Importar clave de Release Engineering si no está
      gpg --list-keys 2>/dev/null | grep -q "releng@gentoo.org" || \
        gpg --keyserver hkps://keys.gentoo.org --recv-keys 13EBBDBEDE7A12775DFDB1BABB572E0E2D182910 2>/dev/null || \
        gpg --auto-key-locate=clear,nodefault,wkd --locate-key releng@gentoo.org 2>/dev/null || true

      if gpg --verify "$asc_file" "$stage3_file" 2>/dev/null; then
        ok "Firma GPG válida"
      else
        warn "Firma GPG no pudo verificarse (puede continuar igual)"
      fi
    else
      warn "GPG no disponible o sin archivo .asc — saltando verificación de firma"
    fi

    # SHA256 verification
    if [ -f "$digest_file" ] && [ -s "$digest_file" ]; then
      echo -e "  ${D}Verificando SHA256...${RST}"
      local expected_hash
      expected_hash=$(grep -A1 'SHA256' "$digest_file" | grep -v 'SHA256\|^--$' | head -1 | awk '{print $1}' || true)
      if [ -n "$expected_hash" ]; then
        local actual_hash
        actual_hash=$(sha256sum "$stage3_file" | awk '{print $1}')
        if [ "$expected_hash" = "$actual_hash" ]; then
          ok "SHA256 coincide"
        else
          err "SHA256 NO coincide — el archivo puede estar corrupto"
          echo "  Esperado: $expected_hash"
          echo "  Obtenido: $actual_hash"
          read -rp "  ¿Continuar de todas formas? (s/N): " cont
          [ "$cont" != "s" ] && exit 1
        fi
      else
        warn "No se pudo extraer hash SHA256 del archivo .DIGESTS"
      fi
    fi
    rm -f "$digest_file" "$asc_file"
  else
    echo -e "  ${Y}Verificación saltada por el usuario.${RST}"
  fi

  # ── Extracción ─────────────────────────────────────────
  echo
  echo -e "  ${D}Extrayendo en $CHROOT...${RST}"
  echo "  (esto puede tomar varios minutos)"
  echo
  tar xpf "$stage3_file" -C "$CHROOT" --xattrs-include='*.*' --numeric-owner

  ok "Stage3 extraído correctamente"
  rm -f "$stage3_file"
  save_state 7
  pause
}

# ── Paso 7: Configurar repositorios (pre-chroot) ──────────────────────────
step_portage() {
  step 7 "Configurar repositorios Portage y red (pre-chroot)"

  # ── Configurar repositorio (emerge-webrsync se ejecuta DENTRO del chroot) ──
  mkdir -p "$CHROOT/etc/portage/repos.conf"
  cat > "$CHROOT/etc/portage/repos.conf/gentoo.conf" <<- REPO
[gentoo]
location = /var/db/repos/gentoo
sync-type = rsync
sync-uri = rsync://rsync.gentoo.org/gentoo-portage
auto-sync = yes
sync-rsync-verify-metamanifest = yes
sync-rsync-verify-max-age = 3
sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
sync-openpgp-keyserver = hkps://keys.gentoo.org
sync-webrsync-verify-signature = yes
REPO

  # ── DNS ────────────────────────────────────────────────
  echo -e "  ${D}Copiando configuración de red (resolv.conf)...${RST}"
  cp --dereference /etc/resolv.conf "$CHROOT/etc/" 2>/dev/null || true

  # ── /etc/hosts ─────────────────────────────────────────
  echo -e "  ${D}Creando /etc/hosts...${RST}"
  cat > "$CHROOT/etc/hosts" <<- HOSTS
127.0.0.1     $TARGET_HOSTNAME $TARGET_HOSTNAME localhost
::1           $TARGET_HOSTNAME $TARGET_HOSTNAME localhost
HOSTS

  # ── fstab (con UUIDs) ─────────────────────────────────
  resolve_parts "$TARGET_DISK"

  # root es PART2 si no hay swap, PART3 si hay swap
  local root_part
  if [ "$SWAP_SIZE" -gt 0 ]; then
    root_part="$PART3"
  else
    root_part="$PART2"
  fi

  local root_uuid boot_uuid swap_uuid
  root_uuid=$(blkid -s UUID -o value "$root_part" 2>/dev/null || echo "")
  boot_uuid=$(blkid -s UUID -o value "$PART1" 2>/dev/null || echo "")

  cat > "$CHROOT/etc/fstab" <<- FSTAB
# /etc/fstab — Generado por gentoo.sh
# <file system>    <mount point>  <type>  <options>               <dump> <pass>

# ESP (Handbook: montar en /efi, no /boot)
UUID=$boot_uuid  /efi           vfat    umask=0077,tz=UTC        0      2
UUID=$root_uuid  /              $ROOT_FS defaults,noatime       0      1
FSTAB

  if [ "$SWAP_SIZE" -gt 0 ]; then
    swap_uuid=$(blkid -s UUID -o value "$PART2" 2>/dev/null || echo "")
    cat >> "$CHROOT/etc/fstab" <<- FSTAB
UUID=$swap_uuid  none           swap    sw                      0      0
FSTAB
  fi

  # tmpfs para /tmp en SSD (reduce escritura en disco)
  if [ "$TARGET_DISK_ROTATIONAL" -eq 0 ]; then
    cat >> "$CHROOT/etc/fstab" <<- FSTAB
tmpfs            /tmp           tmpfs   nosuid,nodev,noexec,size=4G   0      0
FSTAB
    echo -e "  ${D}/tmp como tmpfs (4G en RAM) — SSD optimizado.${RST}"
  fi

  # ── hostname ───────────────────────────────────────────
  echo "$TARGET_HOSTNAME" > "$CHROOT/etc/hostname"

  ok "Portage, red y fstab configurados"
  save_state 8
  pause
}

# ── Paso 8: Montar sistemas de archivos para chroot ──────────────────────
step_prepare_chroot() {
  step 8 "Montar sistemas de archivos para el chroot"

  echo -e "  ${D}Montando /proc, /sys, /dev y /run...${RST}"

  mount --types proc /proc "$CHROOT/proc"
  mount --rbind /sys "$CHROOT/sys"
  mount --make-rslave "$CHROOT/sys"
  mount --rbind /dev "$CHROOT/dev"
  mount --make-rslave "$CHROOT/dev"
  mount --bind /run "$CHROOT/run" 2>/dev/null || true
  mount --make-slave "$CHROOT/run" 2>/dev/null || true

  # Asegurar /dev/shm (importante en LiveCD no-Gentoo)
  if [ -L "$CHROOT/dev/shm" ]; then
    rm -f "$CHROOT/dev/shm"
    mkdir "$CHROOT/dev/shm"
    mount --types tmpfs --options nosuid,nodev,noexec shm "$CHROOT/dev/shm"
    chmod 1777 "$CHROOT/dev/shm"
  fi

  ok "Sistemas de archivos montados para chroot"
  save_state 9
  pause
}

# ── Paso 9: Generar script post-chroot ────────────────────────────────────
step_generate_chroot_script() {
  step 9 "Generar script de configuración interna (kernel, bootloader, etc.)"

  local script="$CHROOT/root/install-in-chroot.sh"

  cat > "$script" <<- INCHROOT
#!/bin/bash
# Script de configuración interna — ejecutado DENTRO del chroot
# Generado por gentoo.sh — basado en Handbook AMD64
set -euo pipefail

source /etc/profile
export PS1="(chroot) \\[\\e[1m\\]\\w\\[\\e[0m\\] # "

echo
echo "================================================"
echo "  DENTRO DEL CHROOT — Configuración interna"
echo "================================================"
echo

# ═══════════════════════════════════════════════════════
# 1. SINCRONIZAR REPOSITORIO PORTAGE
# ═══════════════════════════════════════════════════════
echo ">>> Sincronizando repositorio Portage (emerge-webrsync)..."
emerge-webrsync
echo

# ═══════════════════════════════════════════════════════
# 2. SELECCIONAR PERFIL
# ═══════════════════════════════════════════════════════
echo ">>> Perfiles disponibles:"
eselect profile list
echo
echo "  RECOMENDADO (OpenRC):"
echo "    eselect profile set default/linux/amd64/23.0/desktop/plasma"
echo "    eselect profile set default/linux/amd64/23.0/desktop/gnome"
echo "    eselect profile set default/linux/amd64/23.0/desktop"
echo "    eselect profile set default/linux/amd64/23.0"
echo "  (usa 'openrc' en el nombre del perfil; evita perfiles con 'systemd')"
echo "  EJECUTA MANUALMENTE: eselect profile set <NÚMERO>"
echo "  Luego vuelve a ejecutar este script con:"
echo "    source /etc/profile && ./root/install-in-chroot.sh --skip-profile"
echo

  # Si el usuario dice "ya seleccioné perfil, salta ese paso"
  if [ "\${1:-}" = "--skip-profile" ]; then
    echo ">>> Perfil ya seleccionado — continuando..."
  else
    echo ">>> DETENIDO — selecciona el perfil primero con eselect profile set"
    echo ">>> Luego ejecuta: source /etc/profile && ./root/install-in-chroot.sh --skip-profile"
    exit 0
  fi
INCHROOT

  cat >> "$script" <<- 'INCHROOT'

# ═══════════════════════════════════════════════════════
# 3. ACTUALIZAR @world (opcional, puede saltarse en instalación rápida)
# ═════════════════════════════════════════════════════════
echo ">>> Actualizando @world (opcional — puede tomar mucho tiempo)..."
echo "    Para saltar: emerge --sync && continuar con el siguiente paso"
echo "    Para ejecutar: emerge -uDvN @world"
echo

# ═══════════════════════════════════════════════════════
# 4. CONFIGURAR ZONA HORARIA (Handbook: Timezone)
# ═══════════════════════════════════════════════════════
echo ">>> Configurando zona horaria..."
echo "    Zonas disponibles en /usr/share/zoneinfo/"
echo "    Ejecutar: ln -sf ../usr/share/zoneinfo/America/Mexico_City /etc/localtime"
echo "    (o la zona que corresponda)"
echo

# ═══════════════════════════════════════════════════════
# 5. CONFIGURAR LOCALE (Handbook: Configure locales)
# ═══════════════════════════════════════════════════════
echo ">>> Configurando locales..."
echo "    Edit:  nano /etc/locale.gen"
echo "    Luego: locale-gen"
echo "    Luego: eselect locale set <NÚMERO>"
echo "    Luego: env-update && source /etc/profile"
echo

# ═══════════════════════════════════════════════════════
# 6. INSTALAR KERNEL
# ═══════════════════════════════════════════════════════
INCHROOT

  cat >> "$script" <<- 'INCHROOT'
echo ">>> Instalando kernel..."
echo
INCHROOT

  if [ "$KERNEL_MODE" = "auto" ]; then
    cat >> "$script" <<- 'INCHROOT'
emerge -v sys-kernel/gentoo-sources
echo
# Seleccionar las fuentes recién instaladas
eselect kernel set 1
echo "  Fuentes seleccionadas: $(eselect kernel list | grep '*' | awk '{print $2}')"
echo
cd /usr/src/linux || { echo "ERROR: /usr/src/linux no existe"; exit 1; }
# Copiar configuración del kernel del LiveCD (compatible con hardware actual)
if [ -f /proc/config.gz ]; then
  echo ">>> Copiando configuración del kernel del LiveCD..."
  zcat /proc/config.gz > .config
  echo "  Usando config del LiveCD como base"
else
  echo ">>> Generando configuración por defecto..."
  make defconfig
fi
# Actualizar defaults para nuevas opciones (no interactivo)
make olddefconfig
# Recortar a solo los módulos del hardware detectado en el LiveCD
echo ">>> Recortando módulos al hardware detectado (localmodconfig)..."
make localmodconfig 2>/dev/null || true
echo
echo ">>> Compilando kernel (esto puede tomar varios minutos)..."
make -j$(nproc)
echo
echo ">>> Instalando módulos..."
make modules_install
echo
echo ">>> Instalando kernel y System.map..."
make install
echo
# Generar initramfs con dracut
echo ">>> Instalando dracut para initramfs..."
emerge -v sys-kernel/dracut
KERNEL_VER=$(make -s kernelrelease 2>/dev/null || ls /lib/modules/ | sort -V | tail -1)
echo "  Versión del kernel: $KERNEL_VER"
dracut --force --host-only "/boot/initramfs-$KERNEL_VER.img" "$KERNEL_VER"
echo
ok "Kernel compilado e instalado correctamente"
INCHROOT

  elif [ "$KERNEL_MODE" = "binary" ]; then
    cat >> "$script" <<- 'INCHROOT'
echo ">>> Instalando kernel binario (gentoo-kernel-bin)..."
emerge -v sys-kernel/gentoo-kernel-bin
echo
ok "Kernel binario instalado correctamente"
echo "  NOTA: El initramfs se genera automáticamente con kernel-install"
echo
INCHROOT

  else
    cat >> "$script" <<- 'INCHROOT'
echo ">>> Kernel manual — sigue estos pasos:"
echo
echo "  1) emerge -v sys-kernel/gentoo-sources"
echo "  2) eselect kernel set 1"
echo "  3) cd /usr/src/linux"
echo "  4) zcat /proc/config.gz > .config  (opcional, copia config del LiveCD)"
echo "  5) make menuconfig                (configura a tu gusto)"
echo "  6) make -j\$(nproc) && make modules_install && make install"
echo "  7) emerge -v sys-kernel/dracut"
echo "  8) dracut --force --host-only /boot/initramfs-<versión>.img <versión>"
echo
echo "  EJECUTA MANUALMENTE, luego vuelve a este script"
echo "  con: ./root/install-in-chroot.sh --skip-kernel"
INCHROOT
  fi

  cat >> "$script" <<- 'INCHROOT'

# ═══════════════════════════════════════════════════════
# 7. FIRMWARE (Handbook: Suggested)
# ═══════════════════════════════════════════════════════
echo ">>> Instalando linux-firmware..."
emerge -v sys-kernel/linux-firmware
echo

# ═══════════════════════════════════════════════════════
# 8. INSTALAR BOOTLOADER (GRUB)
# ═══════════════════════════════════════════════════════
echo ">>> Instalando GRUB..."
echo

# Montar ESP si no está montada (Handbook: mount /dev/sda1 /efi)
if ! mountpoint -q /efi; then
  echo "  Montando EFI System Partition..."
  # Buscar partición EFI por tipo
  EFI_PART=\$(blkid | grep 'PARTUUID="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"' | head -1 | cut -d: -f1)
  if [ -n "\$EFI_PART" ]; then
    mkdir -p /efi
    mount "\$EFI_PART" /efi
  else
    echo "  Usando /dev/sda1 como ESP (asumiendo primer partición)"
    mkdir -p /efi
    mount /dev/sda1 /efi 2>/dev/null || echo "  (ajusta la ruta manualmente si falla)"
  fi
fi

echo "    emerge -v sys-boot/grub"
echo "    grub-install --target=x86_64-efi --efi-directory=/efi"
echo "    grub-mkconfig -o /boot/grub/grub.cfg"
echo
INCHROOT

  if [ "$KERNEL_MODE" != "manual" ]; then
    cat >> "$script" <<- 'INCHROOT'
echo ">>> INSTALANDO GRUB AUTOMÁTICAMENTE..."
echo
emerge -v sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
echo "  GRUB instalado correctamente."
echo
INCHROOT
  else
    cat >> "$script" <<- 'INCHROOT'
echo ">>> GRUB requiere instalación manual (kernel manual):"
echo "    emerge -v sys-boot/grub"
echo "    grub-install --target=x86_64-efi --efi-directory=/efi"
echo "    grub-mkconfig -o /boot/grub/grub.cfg"
echo
INCHROOT
  fi

  cat >> "$script" <<- 'INCHROOT'

# ═══════════════════════════════════════════════════════
# 9. CONTRASEÑA ROOT
# ═══════════════════════════════════════════════════════
echo ">>> ESTABLECER CONTRASEÑA ROOT (OBLIGATORIO):"
passwd
echo

# ═══════════════════════════════════════════════════════
# 10. CONFIGURAR RED
# ═══════════════════════════════════════════════════════
echo ">>> Configuración de red:"
echo "  Opción 1 — dhcpcd (simple, ethernet):"
echo "    emerge -v net-misc/dhcpcd"
echo "    rc-update add dhcpcd default"
echo "    rc-service dhcpcd start"
echo
echo "  Opción 2 — NetworkManager (WiFi, escritorio):"
echo "    emerge -v net-misc/networkmanager"
echo "    rc-update add NetworkManager default"
echo
echo "  Opción 3 — netifrc (manual, OpenRC)"
echo "    emerge -v net-misc/netifrc"
echo "    nano /etc/conf.d/net"
echo "    ln -s net.lo /etc/init.d/net.eth0"
echo "    rc-update add net.eth0 default"
echo

# ═══════════════════════════════════════════════════════
# 11. SISTEMA DE ARCHIVOS /boot (separado de ESP)
# ═══════════════════════════════════════════════════════
echo ">>> NOTA: Con ESP en /efi, los kernels se instalan en /boot"
echo "  (que está en la partición root). Asegúrate de tener"
echo "  suficiente espacio en /boot (200-500MB recomendado)."
echo

# ═══════════════════════════════════════════════════════
# 12. TOOLS ADICIONALES (Handbook: Installing tools)
# ═══════════════════════════════════════════════════════
echo ">>> Herramientas del sistema (opcional):"
echo "  ccache:         emerge -v dev-util/ccache"
echo "  System logger:  emerge -v app-admin/sysklogd && rc-update add sysklogd default"
echo "  Cron:           emerge -v sys-process/cronie && rc-update add cronie default"
echo "  File indexing:  emerge -v sys-apps/mlocate"
echo
INCHROOT

# ═══════════════════════════════════════════════════════
# 13. CREAR USUARIO (según Handbook)
# ═══════════════════════════════════════════════════════
cat >> "$script" <<- INCHROOT
if [ -n "$TARGET_USERNAME" ]; then
  echo ">>> Creando usuario '$TARGET_USERNAME'..."
  useradd -m -G users,wheel,audio,video,portage $TARGET_USERNAME
  echo "  Usuario creado. Establecé su contraseña:"
  passwd $TARGET_USERNAME
  echo
else
  echo ">>> Sin usuario definido — podés crear uno después con:"
  echo "    useradd -m -G users,wheel,audio,video,portage <usuario>"
  echo "    passwd <usuario>"
  echo
fi
INCHROOT

cat >> "$script" <<- 'INCHROOT'

echo "================================================"
echo "  CONFIGURACIÓN DENTRO DEL CHROOT COMPLETADA"
echo "================================================"
echo
echo "  Resumen de pasos manuales:"
echo "    1. eselect profile set <N>"
echo "    2. source /etc/profile && ./root/install-in-chroot.sh --skip-profile"
echo "       (dentro: contraseña root, timezone, locale, kernel, firmware, GRUB, red, usuario)"
echo "    3. exit                # salir del chroot"
echo "    4. umount -R /mnt/gentoo"
echo "    5. reboot"
echo
INCHROOT

  chmod +x "$script"
  ok "Script generado: $CHROOT/root/install-in-chroot.sh"
  save_state 10
  pause
}

# ── Paso 10: Entrar al chroot ─────────────────────────────────────────────
step_enter_chroot() {
  step 10 "Entrar al chroot"

  echo
  echo -e "  ${B}Instalación lista para continuar DENTRO del chroot.${RST}"
  echo
  echo -e "  ${D}Comandos:${RST}"
  echo
  echo -e "    ${C}chroot /mnt/gentoo /bin/bash${RST}"
  echo -e "    ${C}source /etc/profile${RST}"
  echo -e "    ${C}export PS1=\"(chroot) \${PS1}\"${RST}"
  echo -e "    ${C}./root/install-in-chroot.sh${RST}"
  echo
  echo -e "  ${Y}O todo en uno:${RST}"
  echo
  echo -e "    ${C}chroot /mnt/gentoo /bin/bash -c \"source /etc/profile && export PS1='(chroot) \\\\[\\\\e[1m\\\\]\\\\w\\\\[\\\\e[0m\\\\] # ' && ./root/install-in-chroot.sh\"${RST}"
  echo

  if [ -x "$CHROOT/bin/bash" ]; then
    echo "  1) Entrar al chroot ahora (al salir, continúa el script)"
    echo "  2) No entrar ahora — dejar montado para después"
    echo "  3) Desmontar todo y finalizar"
    echo
    read -rp "  Opción (1-3): " chroot_opt
    echo

    case "$chroot_opt" in
      1)
        info "Entrando al chroot. Ejecuta 'exit' para volver."
        echo
        chroot "$CHROOT" /bin/bash
        echo
        info "De vuelta del chroot."
        step_cleanup
        ;;
      2)
        info "Dejando /mnt/gentoo montado."
        info "Para entrar después: sudo chroot /mnt/gentoo /bin/bash"
        info "Para desmontar:     sudo umount -R /mnt/gentoo"
        echo
        clear_state
        echo -e "  ${G}✓${RST} Instalación completada (pendiente de chroot manual)."
        echo
        exit 0
        ;;
      3)
        step_cleanup
        ;;
    esac
  else
    warn "/mnt/gentoo/bin/bash no existe — ¿el stage3 se extrajo correctamente?"
    step_cleanup
  fi

  save_state 99
}

# ── Limpieza ───────────────────────────────────────────────────────────────
step_cleanup() {
  step "Limpieza" "Desmontar sistemas de archivos"

  echo -e "  ${D}Desmontando sistemas de archivos...${RST}"
  umount -R "$CHROOT" 2>/dev/null || true
  ok "Sistemas desmontados"
  clear_state
  echo
  echo -e "  ${G}✓${RST} Instalación completada. Podés reiniciar."
  echo
}

# ── Menú de pasos ─────────────────────────────────────────────────────────
show_menu() {
  local steps=(
    "Información del hardware destino"
    "Seleccionar disco destino"
    "Particionar disco (GPT + UEFI)"
    "Formatear particiones"
    "Montar particiones"
    "Configurar make.conf"
    "Descargar y extraer Stage3"
    "Configurar Portage y red (pre-chroot)"
    "Montar sistemas de archivos"
    "Generar script post-chroot"
    "Entrar al chroot"
  )

  echo
  echo -e "${B}══════════════════════════════════════════════${RST}"
  echo -e "${B}  Gentoo Installation Assistant${RST}"
  echo -e "${B}  Basado en el Handbook AMD64${RST}"
  echo -e "${B}══════════════════════════════════════════════${RST}"
  echo
  echo -e "  ${D}Paso siguiente: #$((STEP+1)) — ${steps[$STEP]}${RST}"
  echo
  echo "  1) Continuar con el siguiente paso"
  echo "  2) Ir a un paso específico"
  echo "  3) Salir"
  echo
  read -rp "  Opción: " menu_opt
  echo

  case "$menu_opt" in
    2)
      echo -e "  ${D}Pasos disponibles:${RST}"
      for i in "${!steps[@]}"; do
        local marker=" "
        [ "$i" -lt "$STEP" ] && marker="${G}✓${RST}"
        [ "$i" -eq "$STEP" ] && marker="${M}▶${RST}"
        echo "  $marker $((i+1))) ${steps[$i]}"
      done
      echo
      read -rp "  Ir al paso: " go_step
      STEP=$((go_step - 1))
      [ "$STEP" -lt 0 ] && STEP=0
      [ "$STEP" -gt 10 ] && STEP=10
      save_state "$STEP"
      ;;
    3)
      echo "  Saliendo."
      exit 0
      ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
  if [ "$(id -u)" -ne 0 ]; then
    err "Este script debe ejecutarse como root (sudo)."
    exit 1
  fi

  # Verificar comandos esenciales
  for cmd in parted mkfs.vfat mkswap mount blkid tar curl; do
    if ! command -v "$cmd" &>/dev/null; then
      err "Comando requerido no encontrado: $cmd"
      exit 1
    fi
  done

  if [ "${1:-}" = "--resume" ]; then
    load_state
  else
    clear_state
    STEP=0
  fi

  while [ "$STEP" -le 10 ]; do
    case "$STEP" in
      0)  step_hardware_info ;;
      1)  step_select_disk ;;
      2)  step_partition ;;
      3)  step_format ;;
      4)  step_mount ;;
      5)  step_make_conf ;;
      6)  step_stage3 ;;
      7)  step_portage ;;
      8)  step_prepare_chroot ;;
      9)  step_generate_chroot_script ;;
      10) step_enter_chroot ;;
    esac
  done
}

main "$@"
