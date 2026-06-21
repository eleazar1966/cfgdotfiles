#!/bin/bash
# ==============================================================================
# SCRIPT DE OPTIMIZACIÓN DE MÚSICA EN GENTOO - VERSIÓN FINAL CON DIRECTORIO ESTÁNDAR
# Ruta actualizada a ~/Música, conversión M4A, purgado de imágenes y géneros.
# ==============================================================================

# NUEVA RUTA CONFIGURADA:
CARPETA_MUSICA="$HOME/Música"
LISTA_PLAYLIST="$CARPETA_MUSICA/lista_limpia.m3u"

echo "🎵 Iniciando optimización RECURSIVA y CONVERSIÓN TOTAL en: $CARPETA_MUSICA"
echo "----------------------------------------------------------------"

# Paso 1: Verificar herramientas esenciales
for cmd in detox rdfind exiftool ffmpeg; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Error: El comando '$cmd' no está instalado."
        exit 1
    fi
done

# Asegurarse de que el nuevo directorio existe antes de trabajar
mkdir -p "$CARPETA_MUSICA"

# Paso 2: PURGADO DE IMÁGENES, TEXTOS Y SCRIPTS VIEJOS
echo "🗑️  Paso 1/5: Eliminando imágenes, reportes y scripts obsoletos..."
find "$CARPETA_MUSICA" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.txt" -o -name "convert*.sh" \) -delete

# Paso 3: CONVERSIÓN RECURSIVA DE M4A A MP3
echo "🔄 Paso 2/5: Buscando y convirtiendo todos los archivos .m4a a .mp3..."
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
echo "✨ Paso 3/5: Normalizando nombres de archivos y ordenando carpetas de género..."
find "$CARPETA_MUSICA" -type f -name "*.mp3" | while read -r archivo; do
    [ -f "$archivo" ] || continue

    dir=$(dirname "$archivo")
    base=$(basename "$archivo")
    
    # Mapeo de género inteligente basado en palabras clave internas
    genero_raw=$(exiftool -p '$Genre' "$archivo" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    
    if [[ -z "$genero_raw" || "$genero_raw" == "unknown" || "$genero_raw" == "none" ]]; then
        genero_carpeta="clasificar_manualmente"
    elif [[ "$genero_raw" == *"cumbia"* ]]; then
        genero_carpeta="cumbia"
    elif [[ "$genero_raw" == *"salsa"* ]]; then
        genero_carpeta="salsa"
    elif [[ "$genero_raw" == *"guaracha"* || "$genero_raw" == *"dembow"* ]]; then
        genero_carpeta="urbano_latino"
    elif [[ "$genero_raw" == *"hip-hop"* || "$genero_raw" == *"rap"* || "$genero_raw" == *"hiphop"* ]]; then
        genero_carpeta="rap_hiphop"
    elif [[ "$genero_raw" == *"house"* || "$genero_raw" == *"electronic"* || "$genero_raw" == *"dance"* || "$genero_raw" == *"techno"* || "$genero_raw" == *"funk"* || "$genero_raw" == *"soul"* ]]; then
        genero_carpeta="electronica_dance"
    elif [[ "$genero_raw" == *"pop"* ]]; then
        genero_carpeta="pop"
    elif [[ "$genero_raw" == *"corrido"* || "$genero_raw" == *"norteno"* || "$genero_raw" == *"quebradita"* ]]; then
        genero_carpeta="regional_mexicano"
    else
        genero_carpeta=$(echo "$genero_raw" | tr -s ' ' '_' | sed -E 's/[^a-z0-9_-]/_/g')
    fi

    SUBCARPETA_DESTINO="$CARPETA_MUSICA/$genero_carpeta"
    mkdir -p "$SUBCARPETA_DESTINO"

    # Sanitizar el nombre del archivo
    nuevo_nombre="${base,,}"
    nuevo_nombre=$(echo "$nuevo_nombre" | tr -s ' ' '_')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/-[a-z0-9_-]{11}\.mp3$/\.mp3/')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/_[a-z0-9_-]{11}\.mp3$/\.mp3/')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/\.[a-z0-9_-]{11}\.mp3$/\.mp3/')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/_audio-[a-z0-9_-]{11}\.mp3$/\.mp3/')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/^[0-9]+[[:space:]_.-]+//')

    nombre_sin_ext="${nuevo_nombre%.mp3}"
    nombre_limpio=$(echo "$nombre_sin_ext" | sed -E 's/[^a-z0-9_-]/_/g')
    
    nuevo_nombre="${nombre_limpio}.mp3"
    nuevo_nombre=$(echo "$nuevo_nombre" | tr -s '_-' '_')
    
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/^[[:space:]_.-]+//')
    nuevo_nombre=$(echo "$nuevo_nombre" | sed -E 's/_\.mp3$/\.mp3/')

    if [ ${#nombre_limpio} -le 2 ] || [ "$nuevo_nombre" = "mp3.mp3" ]; then
        tag_artist=$(exiftool -p '$Artist' "$archivo" 2>/dev/null | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]/_/g')
        tag_title=$(exiftool -p '$Title' "$archivo" 2>/dev/null | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]/_/g')
        
        if [ -n "$tag_artist" ] && [ -n "$tag_title" ]; then
            nuevo_nombre="${tag_artist}_${tag_title}.mp3"
        else
            hash_id=$(echo "$base" | md5sum | cut -c1-5)
            nuevo_nombre="pista_desconocida_${hash_id}.mp3"
        fi
        nuevo_nombre=$(echo "$nuevo_nombre" | tr -s '_')
    fi

    destino_final="$SUBCARPETA_DESTINO/$nuevo_nombre"

    # Mover y resolver colisiones por tamaño de audio
    if [ ! -f "$destino_final" ] && [ "$archivo" != "$destino_final" ]; then
        mv "$archivo" "$destino_final"
    elif [ -f "$destino_final" ] && [ "$archivo" != "$destino_final" ]; then
        peso_actual=$(stat -c "%s" "$archivo")
        peso_destino=$(stat -c "%s" "$destino_final")
        
        if [ "$peso_actual" -le "$peso_destino" ]; then
            rm -f "$archivo"
        else
            mv -f "$archivo" "$destino_final"
        fi
    fi
done

# Paso 5: Limpieza profunda de duplicados y directorios vacíos
echo "🧹 Paso 4/5: Ejecutando detox y barriendo duplicados exactos (rdfind)..."
detox -r "$CARPETA_MUSICA" &>/dev/null
rdfind -deleteduplicates true "$CARPETA_MUSICA" &>/dev/null

# Eliminar carpetas vacías residuales
find "$CARPETA_MUSICA" -type d -empty -delete 2>/dev/null

echo "📋 Paso 5/5: Generando lista de reproducción unificada (.m3u)..."
find "$CARPETA_MUSICA" -type f -name "*.mp3" | sort > "$LISTA_PLAYLIST"

echo "----------------------------------------------------------------"
echo "🎉 ¡PROCESO COMPLETADO CON ÉXITO!"
echo "✨ Todos los cambios apuntan ahora a la carpeta estándar: $CARPETA_MUSICA"
echo "👉 Playlist actualizada en: $LISTA_PLAYLIST"
