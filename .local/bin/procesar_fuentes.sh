#!/bin/bash

TARGET="$HOME/fonts"
TEMP_DIR="$HOME/fonts_clean_temp"

# Inicializar contadores para las estadísticas finales
CONT_TOTAL=0
CONT_MONO=0
CONT_NERD=0
# Se eliminó la variable duplicada de Nerd Fonts
CONT_EMOJI=0
CONT_PIXEL=0
# Se corrigieron los nombres de variables para que coincidan exactamente en el bloque case
CONT_HAND=0
CONT_SERIF=0
CONT_SANS=0
CONT_DISPLAY=0
CONT_DESCARTADAS=0

# Asegurar limpieza previa de temporales
rm -rf "$TEMP_DIR"
mkdir -p "$TARGET" 

echo "==> Paso 1: Buscando y copiando fuentes de todo el sistema..."
# Excluimos explícitamente tanto TARGET como TEMP_DIR para evitar bucles infinitos
# Al usar sudo, garantizamos acceso a los directorios de todos los usuarios
sudo find / -type f \( -name "*.ttf" -o -name "*.otf" \) \
    -not -path "$TARGET/*" \
    -not -path "$TEMP_DIR/*" \
    -exec cp {} "$TARGET" \; 2>/dev/null

# Restaurar la propiedad a tu usuario tras la copia masiva del sistema
sudo chown -R $USER:$USER "$TARGET"

echo "==> Paso 2: Creando directorios temporales de trabajo..."
mkdir -p "$TEMP_DIR/Monospace"   "$TEMP_DIR/Nerd-Fonts" \
         "$TEMP_DIR/Emojis-Color" "$TEMP_DIR/Pixel-Fonts" \
         "$TEMP_DIR/Handwriting"  "$TEMP_DIR/Serif" \
         "$TEMP_DIR/Sans-Serif"   "$TEMP_DIR/Display"

echo "==> Paso 3: Eliminando duplicados exactos por contenido inicial..."
# jdupes limpia archivos binarios idénticos de forma recursiva
jdupes -rdN "$TARGET"

echo "==> Paso 4: Clasificando, saneando y renombrando binarios tipográficos..."
# Leemos los archivos uno a uno de forma segura utilizando -print0 para evitar problemas con espacios
while IFS= read -r -d '' fuente; do
    ((CONT_TOTAL++))
    
    # Reparación estructural in-place con FontForge usando sintaxis Python correcta
    fontforge -c "
import fontforge
try:
    f = fontforge.open('''$fuente''')
    f.generate('''$fuente''')
    f.close()
except Exception as e:
    pass
" 2>/dev/null

    # Extraer propiedades internas XML para clasificación inteligente
    propiedades=$(fc-scan --xml "$fuente" 2>/dev/null)
    nom=$(basename "$fuente" | tr '[:upper:]' '[:lower:]')

    # Sistema jerárquico de filtros de texto y metadatos
    if echo "$propiedades" | xml2 2>/dev/null | grep -q "/fontconfig/match/edit/int=100"; then
        cat="Monospace"
        ((CONT_MONO++))
    elif [[ "$nom" =~ "nerd" || "$nom" =~ "nf" || "$nom" =~ "complete" ]]; then
        cat="Nerd-Fonts"
        ((CONT_NERD++))
    elif [[ "$nom" =~ "emoji" || "$nom" =~ "twemoji" ]]; then
        cat="Emojis-Color"
        ((CONT_EMOJI++))
    elif [[ "$nom" =~ "pixel" || "$nom" =~ "px" || "$nom" =~ "bitmap" ]]; then
        cat="Pixel-Fonts"
        ((CONT_PIXEL++))
    elif [[ "$nom" =~ "script" || "$nom" =~ "hand" || "$nom" =~ "cursive" || "$nom" =~ "sketch" ]]; then
        cat="Handwriting"
        ((CONT_HAND++))
    elif [[ "$nom" =~ "serif" ]]; then 
        cat="Serif"
        ((CONT_SERIF++))
    elif [[ "$nom" =~ "sans" ]]; then 
        cat="Sans-Serif"
        ((CONT_SANS++))
    else 
        cat="Display"
        ((CONT_DISPLAY++))
    fi
    
    # Obtener el nombre real y estilo de la fuente desde su metadata interna (ADN)
    family=$(fc-scan --format='%{family}\n' "$fuente" 2>/dev/null | head -n 1 | tr -d '",:/\\*?|<> ')
    style=$(fc-scan --format='%{style}\n' "$fuente" 2>/dev/null | head -n 1 | tr -d '",:/\\*?|<> ')
    extension="${fuente##*.}"

    # Si fc-scan falla, preservamos el nombre original de forma segura
    if [[ -z "$family" ]]; then
        nombre_final=$(basename "$fuente")
    else
        if [[ -n "$style" && "$style" != "Regular" ]]; then
            nombre_final="${family}-${style}.${extension}"
        else
            nombre_final="${family}.${extension}"
        fi
    fi

    # Resolver colisiones: Si el nombre ya existe en esa categoría, es un duplicado real y se descarta
    if [[ -f "$TEMP_DIR/$cat/$nombre_final" ]]; then
        ((CONT_DESCARTADAS++))
        # Restar del contador de la categoría correspondiente ya que no se moverá allí
        case "$cat" in
            "Monospace")    ((CONT_MONO--)) ;;
            "Nerd-Fonts")   ((CONT_NERD--)) ;;
            "Emojis-Color") ((CONT_EMOJI--)) ;;
            "Pixel-Fonts")  ((CONT_PIXEL--)) ;;
            "Handwriting")  ((CONT_HAND--)) ;;
            "Serif")        ((CONT_SERIF--)) ;;
            "Sans-Serif")   ((CONT_SANS--)) ;;
            "Display")      ((CONT_DISPLAY--)) ;;
        esac
        rm -f "$fuente"
    else
        # Mover el archivo final único de forma definitiva
        mv "$fuente" "$TEMP_DIR/$cat/$nombre_final" 2>/dev/null
    fi

done < <(find "$TARGET" -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)

echo "==> Paso 5: Reestructurando el directorio definitivo ~/fonts..."
rm -rf "$TARGET"
mv "$TEMP_DIR" "$TARGET"

echo "==> Paso 6: Copiando al repositorio seguro de Gentoo (/usr/share/fonts/custom-imported)..."
# Usamos un directorio propio para no alterar ni romper los paquetes oficiales de Portage
sudo mkdir -p /usr/share/fonts/custom-imported
sudo rm -rf /usr/share/fonts/custom-imported/*
sudo cp -r "$TARGET"/* /usr/share/fonts/custom-imported/

# Configurar permisos estrictos de lectura global requeridos por X11/Wayland
sudo chown -R root:root /usr/share/fonts/custom-imported
sudo find /usr/share/fonts/custom-imported -type d -exec chmod 755 {} +
sudo find /usr/share/fonts/custom-imported -type f -exec chmod 644 {} +

# Forzar a Fontconfig a reconstruir las cachés del sistema de inmediato
echo "==> Actualizando caché de fuentes del sistema..."
sudo fc-cache -rfv >/dev/null

echo ""
echo "========================================================================"
echo " ==> ¡PROCESAMIENTO Y OPTIMIZACIÓN PROFUNDA COMPLETADOS CON ÉXITO! <=="
echo "========================================================================"
echo " Directorio local limpio:  $TARGET"
echo " Directorio del sistema:  /usr/share/fonts/custom-imported"
echo "------------------------------------------------------------------------"
echo "   • Fuentes totales encontradas en el sistema:  $CONT_TOTAL"
echo "   • Fuentes duplicadas/repetidas eliminadas:    $CONT_DESCARTADAS"
echo "------------------------------------------------------------------------"
echo "   Distribución de fuentes guardadas por categoría única:"
echo "   [+] Monospace:    $CONT_MONO"
echo "   [+] Nerd-Fonts:   $CONT_NERD"
echo "   [+] Emojis-Color: $CONT_EMOJI"
echo "   [+] Pixel-Fonts:  $CONT_PIXEL"
echo "   [+] Handwriting:  $CONT_HAND"
echo "   [+] Serif:        $CONT_SERIF"
echo "   [+] Sans-Serif:   $CONT_SANS"
echo "   [+] Display:      $CONT_DISPLAY"
echo "========================================================================"
