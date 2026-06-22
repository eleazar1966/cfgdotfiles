#!/bin/bash
# ==============================================================================
# SCRIPT DE OPTIMIZACIÓN DE MÚSICA - VERSIÓN ULTRA (HÍBRIDA + BEETS + MUSICBRAINZ)
# Categorías personalizadas + Integración con API MusicBrainz (Protección Anti-Ban).
# ==============================================================================

CARPETA_MUSICA="$HOME/Música"
LISTA_PLAYLIST="$CARPETA_MUSICA/lista_limpia.m3u"
ULTIMA_CONSULTA=0

# --- AJUSTES DE ENTORNO Y RECURSOS DEL SISTEMA ---
export NO_AT_SPI=1
export GST_DEBUG=0
ulimit -n 8192

echo "🎵 Iniciando optimización HÍBRIDA y CONVERSIÓN TOTAL en: $CARPETA_MUSICA"
echo "----------------------------------------------------------------"

# Paso 1: Verificar herramientas esenciales
for cmd in detox rdfind exiftool ffmpeg beet python3; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Error: El comando '$cmd' no está instalado."
        exit 1
    fi
done

if ! python3 -c "import musicbrainzngs" &> /dev/null; then
    echo "❌ Error: El paquete dev-python/musicbrainzngs no está instalado en el sistema."
    exit 1
fi

mkdir -p "$CARPETA_MUSICA"

# Paso 2: PURGADO DE IMÁGENES, TEXTOS Y SCRIPTS VIEJOS
echo "🗑️  Paso 1/6: Eliminando imágenes, reportes y scripts obsoletos..."
find "$CARPETA_MUSICA" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.txt" -o -name "convert*.sh" \) -delete

# Paso 3: CONVERSIÓN RECURSIVA DE M4A A MP3
echo "🔄 Paso 2/6: Buscando y convirtiendo todos los archivos .m4a a .mp3..."
find "$CARPETA_MUSICA" -type f -name "*.m4a" | while read -r archivo_m4a; do
    [ -f "$archivo_m4a" ] || continue
    dir_m4a=$(dirname "$archivo_m4a")
    base_m4a=$(basename "$archivo_m4a" .m4a)
    destino_mp3="$dir_m4a/${base_m4a}.mp3"
    
    echo "   ↳ Convertiendo: $base_m4a.m4a -> .mp3"
    ffmpeg -y -i "$archivo_m4a" -b:a 320k "$destino_mp3" &>/dev/null
    
    if [ -f "$destino_mp3" ]; then
        rm -f "$archivo_m4a"
    fi
done

# Paso 4: Saneamiento de nombres y clasificación inteligente de GÉNEROS
echo "✨ Paso 3/6: Normalizando nombres de archivos y ordenando carpetas de género..."

LISTA_TEMPORAL=$(mktemp)
find "$CARPETA_MUSICA" -type f -name "*.mp3" > "$LISTA_TEMPORAL"

TOTAL_ARCHIVOS=$(wc -l < "$LISTA_TEMPORAL")
CONTADOR=0

while read -r archivo; do
    [ -f "$archivo" ] || continue

    ((CONTADOR++))
    dir=$(dirname "$archivo")
    base=$(basename "$archivo")
    
    # Barra de progreso en tiempo real[cite: 2]
    if [ "$TOTAL_ARCHIVOS" -gt 0 ]; then
        PORCENTAJE=$((CONTADOR * 100 / TOTAL_ARCHIVOS))
        BARRA_LLENA=$((PORCENTAJE / 4))
        BARRA=$(printf "%${BARRA_LLENA}s" | tr ' ' '█')
        BARRA_VACIA=$((25 - BARRA_LLENA))
        ESPACIOS=$(printf "%${BARRA_VACIA}s" | tr ' ' '-')
        printf "\r⚡ [%s%s] %d%% (%d/%d) | %-35.35s" "$BARRA" "$ESPACIOS" "$PORCENTAJE" "$CONTADOR" "$TOTAL_ARCHIVOS" "$base"
    fi

    # Extracción de metadatos locales base[cite: 2]
    metadata=$(exiftool -f -p '$Artist|||$Title|||$Genre' "$archivo" 2>/dev/null)
    IFS='|||' read -r tag_artist_raw tag_title_raw tag_genre_fallback <<< "$metadata"
    
    [ "$tag_artist_raw" = "-" ] && tag_artist_raw=""
    [ "$tag_title_raw" = "-" ] && tag_title_raw=""
    [ "$tag_genre_fallback" = "-" ] && tag_genre_fallback=""
    
    # Sanitización primaria del nombre del archivo[cite: 2]
    nuevo_nombre="${base,,}"
    nuevo_nombre=$(echo "$nuevo_nombre" | tr -s ' ' '_')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed 's/0/o/g; s/3/e/g; s/1/i/g')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/-[a-z0-9_-]{11}\.mp3$/\.mp3/; s/_[a-z0-9_-]{11}\.mp3$/\.mp3/; s/\.[a-z0-9_-]{11}\.mp3$/\.mp3/; s/_audio-[a-z0-9_-]{11}\.mp3$/\.mp3/; s/^[0-9]+[[:space:]_.-]+//')

    nombre_sin_ext="${nuevo_nombre%.mp3}"
    nombre_limpio=$(echo "$nombre_sin_ext" | sed -E 's/[^a-z0-9_-]/_/g')
    
    # Deduplicación de términos en el nombre[cite: 2]
    palabras_unicas=""
    IFS='_' read -r -a tokens <<< "$nombre_limpio"
    for token in "${tokens[@]}"; do
        if [[ -z "$token" ]]; then continue; fi
        if [[ " $palabras_unicas " != *" $token "* ]]; then
            palabras_unicas="$palabras_unicas $token"
        fi
    done
    nombre_limpio=$(echo $palabras_unicas | tr ' ' '_')
    nuevo_nombre="${nombre_limpio}.mp3"
    nuevo_nombre=$(echo "$nuevo_nombre" | tr -s '_-' '_')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/^[[:space:]_.-]+//; s/_\.mp3$/\.mp3/')

    # Asegurar valores mínimos de búsqueda[cite: 2]
    if [ ${#nombre_limpio} -le 2 ] || [ "$nuevo_nombre" = "mp3.mp3" ]; then
        tag_artist=$(echo "$tag_artist_raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]/_/g')
        tag_title=$(echo "$tag_title_raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]/_/g')
        if [ -n "$tag_artist" ] && [ -n "$tag_title" ]; then
            nuevo_nombre="${tag_artist}_${tag_title}.mp3"
        else
            hash_id=$(echo "$base" | md5sum | cut -c1-5)
            nuevo_nombre="pista_desconocida_${hash_id}.mp3"
        fi
        nuevo_nombre=$(echo "$nuevo_nombre" | tr -s '_')
    fi

    # Rate Limiter para la API de MusicBrainz[cite: 2]
    AHORA=$(date +%s)
    DIFERENCIA=$((AHORA - ULTIMA_CONSULTA))
    if [ "$DIFERENCIA" -lt 1 ]; then
        sleep 1
    fi
    ULTIMA_CONSULTA=$(date +%s)

    # NUEVO FLUJO: CONSULTA PREVIA A MUSICBRAINZ Y EXTRACCIÓN MULTI-VARIABLE
    mb_data=$(python3 -c "
import musicbrainzngs
import sys
import time

musicbrainzngs.set_rate_limit(limit_or_interval=1.0, new_requests=1)
musicbrainzngs.set_useragent('ScriptOptimizadoMusica', '2.0', 'anzola@gmail.com')

artist = \"\"\"$tag_artist_raw\"\"\".strip()
title = \"\"\"$tag_title_raw\"\"\".strip()
filename_query = \"\"\"$nombre_limpio\"\"\".replace('_', ' ').strip()

mb_artist, mb_title, mb_genre = '', '', ''

try:
    if artist and title and len(artist) > 2 and len(title) > 2:
        resultado = musicbrainzngs.search_recordings(artist=artist, recording=title, limit=1)
    else:
        resultado = musicbrainzngs.search_recordings(recording=filename_query, limit=1)
    
    if resultado and resultado.get('recording-list'):
        first_match = resultado['recording-list'][0]
        mb_title = first_match.get('title', '')
        
        if 'artist-credit' in first_match and first_match['artist-credit']:
            credit = first_match['artist-credit'][0]
            if isinstance(credit, dict) and 'artist' in credit:
                mb_artist = credit['artist'].get('name', '')
        
        rec_id = first_match['id']
        time.sleep(1.0)
        datos = musicbrainzngs.get_recording_by_id(rec_id, includes=['tags'])
        tags = datos.get('recording', {}).get('tag-list', [])
        
        if tags:
            mejor_tag = max(tags, key=lambda x: int(x['count']))
            mb_genre = mejor_tag['name']
except Exception:
    pass

print(f'{mb_artist}|||{mb_title}|||{mb_genre}')
" 2>/dev/null)

    # Desempaquetar los datos devueltos por MusicBrainz
    IFS='|||' read -r mb_artist mb_title mb_genre <<< "$mb_data"

    # Si MusicBrainz aportó datos correctos, actualizamos las variables locales antes de clasificar
    [ -n "$mb_artist" ] && tag_artist_raw="$mb_artist"
    [ -n "$mb_title" ] && tag_title_raw="$mb_title"
    
    if [ -n "$mb_genre" ]; then
        genero_raw=$(echo "$mb_genre" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]_.-]+//;s/[[:space:]_.-]+$//')
    else
        # FALLBACK LOCAL: Si MusicBrainz no tenía género, recurrir al tag original del archivo[cite: 2]
        genero_raw=$(echo "$tag_genre_fallback" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]_.-]+//;s/[[:space:]_.-]+$//')
    fi

    # NUEVO ENFOQUE: Construcción robusta de match_str con metadatos oficiales corregidos
    match_str="${nuevo_nombre} ${tag_artist_raw} ${tag_title_raw} ${genero_raw}"
    match_str=$(echo "$match_str" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    
    # Clasificación basada en expresiones de categorías críticas[cite: 2]
    if [[ "$match_str" =~ (cardenales|gaita|alitasia|maracaibo|astolfo|barrio_obrero|ali_primera|simon_diaz|gualberto|carota|nema|taja|un_solo_pueblo|aguinaldo|curarigueno|pajarillo|bandola|llano|llanera|eneas) ]]; then
        genero_carpeta="Tradicional_Y_Gaitas"
    elif [[ "$match_str" =~ (afro_criollo|house|remix|bpm|dj|caplay|starter|break_aca|mix_2024) ]]; then
        genero_carpeta="Afro_Criollo_Y_House_Mix"
    elif [[ "$match_str" =~ (adolescent|carruyo|mosaico|celia|puerto_rican|lavoe|arroyo|billo|antaños|pastor_lopez|cumbia|vallenato|barros|aniceto|binomio|salsa|merengue) ]]; then
        genero_carpeta="Tropical_Salsa_Merengue"
    elif [[ "$match_str" =~ (illapu|savia_andina|arak_pacha|querevalu|warthon|ortuño|chabuca|cavero|aviles|quena|charango|zampoña) ]]; then
        genero_carpeta="Andina_Y_Folklore_Latino"
    elif [[ "$match_str" =~ (canon|pachelbel|beethoven|mozart|chopin|debussy|badinerie|piazzolla|bossa|jazz|saxofon|sanso|mangore) ]]; then
        genero_carpeta="Clasica_Instrumental_Jazz"
    else
        # FALLBACK DE CATEGORÍA GENERADO POR NOMBRE DE GÉNERO OFICIAL[cite: 2]
        if [[ -n "$genero_raw" && "$genero_raw" != "unknown" && "$genero_raw" != "none" ]]; then
            genero_carpeta=$(echo "$genero_raw" | sed -E 's/[^a-z0-9_-]/_/g' | tr -s '_')
            genero_carpeta=$(echo "$genero_carpeta" | sed -e 's/\b\(.\)/\u\1/g') 
        else
            genero_carpeta="Otros_Y_Pop"
        fi
    fi

    SUBCARPETA_DESTINO="$CARPETA_MUSICA/$genero_carpeta"
    mkdir -p "$SUBCARPETA_DESTINO"
    destino_final="$SUBCARPETA_DESTINO/$nuevo_nombre"

    # Resolución de colisiones físicas en disco[cite: 2]
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

    # ESCRITURA ESTÉTICA FINAL CON METADATOS ENRIQUECIDOS
    if [ -f "$destino_final" ]; then
        if [ -n "$tag_title_raw" ]; then
            titulo_estetico="$tag_title_raw"
        else
            titulo_estetico=$(basename "$destino_final" .mp3 | tr '_' ' ' | sed -e 's/\b\(.\)/\u\1/g')
        fi
        
        exiftool -overwrite_original -all= \
            -Artist="$tag_artist_raw" \
            -Title="$titulo_estetico" \
            -Genre="$genero_carpeta" \
            -Encoding="LAME3.100" "$destino_final" &>/dev/null
    fi
done < "$LISTA_TEMPORAL"
echo "" 
rm -f "$LISTA_TEMPORAL"

# Paso 5: IMPORTACIÓN INTELIGENTE EN EL SITIO CON BEETS[cite: 2]
echo "🤖 Paso 4/6: Invocando a Beets para el enriquecimiento y corrección ID3 masiva..."
beet import -q "$CARPETA_MUSICA"

# Paso 6: Limpieza profunda de duplicados y directorios vacíos[cite: 2]
echo "🧹 Paso 5/6: Ejecutando detox y barriendo duplicados exactos (rdfind)..."
detox -r "$CARPETA_MUSICA" &>/dev/null
rdfind -deleteduplicates true "$CARPETA_MUSICA" &>/dev/null
