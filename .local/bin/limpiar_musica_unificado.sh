#!/bin/bash
# ==============================================================================
# SCRIPT DE OPTIMIZACIÓN DE MÚSICA - VERSIÓN ULTRA EN RENDIMIENTO (REFINADA)
# Nombres limpios, etiquetas en minúsculas, sin duplicados ni caracteres extraños
# ==============================================================================

CARPETA_MUSICA="$HOME/Música"

# --- AJUSTES DE ENTORNO Y RECURSOS CRÍTICOS ---
export NO_AT_SPI=1
export GST_DEBUG=0
export PYTHONWARNINGS="ignore::UserWarning"

# Utilizar el techo absoluto de archivos abiertos permitido por el kernel
HARD_FD=$(ulimit -Hn 2>/dev/null || echo 4096)
[[ "$HARD_FD" =~ ^[0-9]+$ ]] && ulimit -n "$HARD_FD" 2>/dev/null || true

echo "🎵 Iniciando optimización ESTRICTA y CONVERSIÓN TOTAL en: $CARPETA_MUSICA"
echo "----------------------------------------------------------------"

# Paso 1: Verificar herramientas esenciales
for cmd in rdfind exiftool ffmpeg beet python3; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Error: El comando '$cmd' no está instalado."
    exit 1
  fi
done

if ! python3 -c "import musicbrainzngs" &>/dev/null; then
  echo "❌ Error: El paquete dev-python/musicbrainzngs no está instalado."
  exit 1
fi

mkdir -p "$CARPETA_MUSICA"

# Paso 2: PURGADO DE ARCHIVOS BASURA O INNECESARIOS
echo "🗑️  Paso 1/6: Eliminando imágenes, reportes y scripts obsoletos..."
find "$CARPETA_MUSICA" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.txt" -o -name "*.log" -o -name "convert*.sh" \) -delete

# Paso 3: CONVERSIÓN RECURSIVA DE M4A A MP3
echo "🔄 Paso 2/6: Buscando y convirtiendo todos los archivos .m4a a .mp3..."
find "$CARPETA_MUSICA" -type f -name "*.m4a" | while read -r archivo_m4a; do
  [ -f "$archivo_m4a" ] || continue
  dir_m4a=$(dirname "$archivo_m4a")
  base_m4a=$(basename "$archivo_m4a" .m4a)
  destino_mp3="$dir_m4a/${base_m4a}.mp3"

  ffmpeg -nostdin -y -i "$archivo_m4a" -b:a 320k "$destino_mp3" &>/dev/null
  if [ -f "$destino_mp3" ]; then
    rm -f "$archivo_m4a"
  fi
done

# Paso 4: Saneamiento de nombres y clasificación inteligente de GÉNEROS
echo "✨ Paso 3/6: Normalizando nombres de archivos y ordenando carpetas..."

LISTA_TEMPORAL=$(mktemp)
find "$CARPETA_MUSICA" -type f -name "*.mp3" >"$LISTA_TEMPORAL"

TOTAL_ARCHIVOS=$(wc -l <"$LISTA_TEMPORAL")
CONTADOR=0

# ── Worker persistente de MusicBrainz ────────────────────────────────────────
# Antes se lanzaba un `python3 -c` POR ARCHIVO: cada uno arrancaba el intérprete
# y re-importaba musicbrainzngs/requests (~0.3-0.5s de arranque). Con un único
# proceso Python leyendo consultas por FIFO el ahorro es significativo en
# bibliotecas grandes. El rate-limit de ~1 consulta/seg se mantiene en el worker.
MB_WORKER=$(mktemp)
MB_QUEUE=$(mktemp -u)
MB_RESULT=$(mktemp -u)
cat > "$MB_WORKER" <<'PYEOF'
import sys, time
import musicbrainzngs

musicbrainzngs.set_useragent('ScriptOptimizadoMusica', '2.0', 'anzola@gmail.com')
last = 0.0

for raw in sys.stdin:
    raw = raw.rstrip('\n')
    if not raw:
        continue
    parts = raw.split('|||', 2) + ['', '', '']
    artist = parts[0].strip()
    title = parts[1].strip()
    query = parts[2].replace('_', ' ').strip()

    mb_artist, mb_title, mb_genre = '', '', ''

    # Respetar el límite de ~1 consulta/seg de MusicBrainz (evita baneos)
    delta = time.time() - last
    if delta < 1.0:
        time.sleep(1.0 - delta)
    last = time.time()

    try:
        if artist and title and len(artist) > 2 and len(title) > 2:
            resultado = musicbrainzngs.search_recordings(artist=artist, recording=title, limit=1)
        else:
            resultado = musicbrainzngs.search_recordings(recording=query, limit=1)

        if resultado and resultado.get('recording-list'):
            first_match = resultado['recording-list'][0]
            mb_title = first_match.get('title', '')
            credit = first_match.get('artist-credit') or []
            if credit and isinstance(credit[0], dict) and 'artist' in credit[0]:
                mb_artist = credit[0]['artist'].get('name', '')
            tags = first_match.get('tag-list', [])
            if tags:
                mb_genre = max(tags, key=lambda x: int(x['count'])).get('name', '')
    except Exception:
        pass

    print(f'{mb_artist}|||{mb_title}|||{mb_genre}', flush=True)
PYEOF

mkfifo "$MB_QUEUE" "$MB_RESULT"
python3 "$MB_WORKER" <"$MB_QUEUE" >"$MB_RESULT" &
MB_PID=$!
# fd 7 = peticiones al worker; fd 8 = respuestas del worker
exec 7>"$MB_QUEUE"
exec 8<"$MB_RESULT"

while read -r archivo; do
  [ -f "$archivo" ] || continue

  ((CONTADOR++))
  base=$(basename "$archivo")

  # Barra de progreso en tiempo real
  if [ "$TOTAL_ARCHIVOS" -gt 0 ]; then
    PORCENTAJE=$((CONTADOR * 100 / TOTAL_ARCHIVOS))
    BARRA_LLENA=$((PORCENTAJE / 4))
    BARRA=$(printf "%${BARRA_LLENA}s" | tr ' ' '█')
    BARRA_VACIA=$((25 - BARRA_LLENA))
    ESPACIOS=$(printf "%${BARRA_VACIA}s" | tr ' ' '-')
    printf "\r⚡ [%s%s] %d%% (%d/%d) | %-35.35s" "$BARRA" "$ESPACIOS" "$PORCENTAJE" "$CONTADOR" "$TOTAL_ARCHIVOS" "$base"
  fi

  # Extracción de metadatos locales base
  metadata=$(exiftool -f -p '$Artist|||$Title|||$Genre' "$archivo" 2>/dev/null)
  IFS='|||' read -r tag_artist_raw tag_title_raw tag_genre_fallback <<<"$metadata"

  [ "$tag_artist_raw" = "-" ] && tag_artist_raw=""
  [ "$tag_title_raw" = "-" ] && tag_title_raw=""
  [ "$tag_genre_fallback" = "-" ] && tag_genre_fallback=""

  # Sanitización estricta del nombre base (Fuerza minúsculas y elimina caracteres especiales/emojis)
  nuevo_nombre="${base,,}"
  nuevo_nombre="${nuevo_nombre// /_}"
  nuevo_nombre="${nuevo_nombre//-/_}"

  # Remover hashes de YouTube (11 caracteres alfanuméricos al final) y números de track iniciales
  nuevo_nombre=$(echo "$nuevo_nombre" | sed -E \
    -e 's/[_\.][a-z0-9_-]{11}\.mp3$/\.mp3/' \
    -e 's/_audio-[a-z0-9_-]{11}\.mp3$/\.mp3/' \
    -e 's/^[0-9]+[[:space:]_.-]+//')

  nombre_sin_ext="${nuevo_nombre%.mp3}"
  # Eliminar CUALQUIER cosa que no sea letras, números o guiones bajos (Limpia Emojis y símbolos raros)
  nombre_limpio=$(echo "$nombre_sin_ext" | sed -E 's/[^a-z0-9_-]/_/g')

  # Deduplicación eficiente de términos repetidos en el nombre en memoria
  palabras_unicas=""
  IFS='_' read -r -a tokens <<<"$nombre_limpio"
  for token in "${tokens[@]}"; do
    if [[ -z "$token" ]]; then continue; fi
    if [[ " $palabras_unicas " != *" $token "* ]]; then
      palabras_unicas+="$token "
    fi
  done

  nombre_limpio=$(echo "$palabras_unicas" | sed -E 's/[[:space:]]+/_/g; s/_+$//')
  nuevo_nombre="${nombre_limpio}.mp3"

  # Consulta a MusicBrainz vía worker persistente (rate-limit ~1/s dentro del worker)
  if [ -n "$MB_PID" ] && kill -0 "$MB_PID" 2>/dev/null; then
    printf '%s|||%s|||%s\n' "$tag_artist_raw" "$tag_title_raw" "$nombre_limpio" >&7
    IFS='|||' read -r mb_artist mb_title mb_genre <&8
  else
    mb_artist=""
    mb_title=""
    mb_genre=""
  fi

  # Priorizar datos de MusicBrainz, si no, mantener los locales
  [ -n "$mb_artist" ] && tag_artist_raw="$mb_artist"
  [ -n "$mb_title" ] && tag_title_raw="$mb_title"
  [ -n "$mb_genre" ] && tag_genre_fallback="$mb_genre"

  # Procesar etiquetas finales estrictamente en minúsculas y limpias
  tag_artist=$(echo "$tag_artist_raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | sed -E 's/[[:space:]]+/_/g')
  tag_title=$(echo "$tag_title_raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | sed -E 's/[[:space:]]+/_/g')
  genero_raw=$(echo "$tag_genre_fallback" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | sed -E 's/[[:space:]]+/_/g')

  # Re-verificar nombre si quedó vacío tras la limpieza drástica
  if [ ${#nombre_limpio} -le 2 ] || [ "$nuevo_nombre" = ".mp3" ]; then
    if [ -n "$tag_artist" ] && [ -n "$tag_title" ]; then
      nuevo_nombre="${tag_artist}__${tag_title}.mp3"
    else
      hash_id=$(echo "$base" | md5sum | cut -c1-5)
      nuevo_nombre="pista_desconocida_${hash_id}.mp3"
    fi
  fi
  nuevo_nombre=$(echo "$nuevo_nombre" | tr -s '_')

  # Clasificación Consolidada Macro en minúsculas (Menos carpetas, más limpias)
  match_str="${nuevo_nombre}_${tag_artist}_${tag_title}_${genero_raw}"

  if [[ "$match_str" =~ (cardenales|gaita|alitasia|maracaibo|astolfo|barrio_obrero|ali_primera|simon_diaz|gualberto|carota|un_solo_pueblo|aguinaldo|llanera|llano) ]]; then
    genero_carpeta="tradicional_y_gaitas"
  elif [[ "$match_str" =~ (afro_criollo|house|remix|bpm|dj|mix|electro|dance) ]]; then
    genero_carpeta="afro_criollo_y_house_mix"
  elif [[ "$match_str" =~ (adolescent|salsa|merengue|bachata|cumbia|vallenato|billo|pastor_lopez|celia|lavoe) ]]; then
    genero_carpeta="tropical_salsa_merengue"
  elif [[ "$match_str" =~ (andina|folklore|latino|quena|charango|zampoña|illapu) ]]; then
    genero_carpeta="andina_y_folklore"
  elif [[ "$match_str" =~ (beethoven|mozart|chopin|bach|clasica|jazz|sax|instrumental|bossa) ]]; then
    genero_carpeta="clasica_instrumental_jazz"
  else
    if [[ -n "$genero_raw" && "$genero_raw" != "unknown" && "$genero_raw" != "none" ]]; then
      # Si el género es muy largo, mandarlo a una carpeta general para evitar directorios raros
      if [ ${#genero_raw} -gt 15 ]; then
        genero_carpeta="otros_y_pop"
      else
        genero_carpeta="$genero_raw"
      fi
    else
      genero_carpeta="otros_y_pop"
    fi
  fi

  SUBCARPETA_DESTINO="$CARPETA_MUSICA/$genero_carpeta"
  mkdir -p "$SUBCARPETA_DESTINO"
  destino_final="$SUBCARPETA_DESTINO/$nuevo_nombre"

  # Reubicación inteligente y resolución de colisiones por tamaño (Mantiene el de mejor calidad)
  if [ ! -f "$destino_final" ] && [ "$archivo" != "$destino_final" ]; then
    mv "$archivo" "$destino_final"
  elif [ -f "$destino_final" ] && [ "$archivo" != "$destino_final" ]; then
    peso_actual=$(stat -c "%s" "$archivo")
    peso_destino=$(stat -c "%s" "$destino_final")
    if [ "$peso_actual" -le "$peso_destino" ]; then
      rm -f "$archivo"
      continue
    else
      mv -f "$archivo" "$destino_final"
    fi
  fi

  # Escritura limpia de metadatos ID3 en absoluto minúsculas
  if [ -f "$destino_final" ]; then
    tag_artist_id3=$(echo "$tag_artist" | tr '_' ' ')
    tag_title_id3=$(echo "$tag_title" | tr '_' ' ')

    # Si las etiquetas quedaron vacías, usar el nombre del archivo limpio como título
    [ -z "$tag_title_id3" ] && tag_title_id3=$(basename "$destino_final" .mp3 | tr '_' ' ')
    [ -z "$tag_artist_id3" ] && tag_artist_id3="desconocido"

    exiftool -overwrite_original -all= \
      -Artist="$tag_artist_id3" \
      -Title="$tag_title_id3" \
      -Genre="$genero_carpeta" \
      -Encoding="lame3.100" "$destino_final" &>/dev/null
  fi
done <"$LISTA_TEMPORAL"
echo ""

# Cerrar worker persistente y limpiar temporales
exec 7>&- 2>/dev/null || true
exec 8<&- 2>/dev/null || true
[ -n "$MB_PID" ] && wait "$MB_PID" 2>/dev/null || true
rm -f "$MB_WORKER" "$MB_QUEUE" "$MB_RESULT" "$LISTA_TEMPORAL"

# Paso 5: PURGA DE SUBDIRECTORIOS VACÍOS
echo "🧹 Paso 4/6: Eliminando árboles de directorios vacíos..."
find "$CARPETA_MUSICA" -type d -empty -delete

# Paso 6: IMPORTACIÓN SILENCIOSA CON BEETS
echo "🤖 Paso 5/6: Ejecutando importación en bloque con Beets..."
find "$CARPETA_MUSICA" -mindepth 1 -maxdepth 1 -type d | while read -r subcarpeta; do
  # -q (quiet) e -s (sketch/as-is) para evitar peticiones interactivas que congelen el script
  beet import -q -s "$subcarpeta" &>/dev/null
done

# Paso 7: DETECCIÓN PROFUNDA DE DUPLICADOS EXACTOS (CONTENIDO)
echo "🧹 Paso 6/6: Barriendo duplicados reales mediante hash (rdfind)..."
rdfind -deleteduplicates true "$CARPETA_MUSICA" &>/dev/null

# Limpieza final de estructura vacía residual
find "$CARPETA_MUSICA" -type d -empty -delete
echo "✨ ¡Optimización completada! Archivos y etiquetas totalmente limpios en minúsculas."
