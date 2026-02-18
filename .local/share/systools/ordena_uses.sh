#!/bin/bash

# Uso: ./procesar_palabras.sh archivo_entrada.txt
INPUT_FILE=$1
OUTPUT_FILE="resultado.txt"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: El archivo '$INPUT_FILE' no existe."
    exit 1
fi

# 1. Extraer palabras, limpiar ruidos (\ y espacios) y ordenar único
all_words=$(tr -s ' \\' '\n' < "$INPUT_FILE" | grep -v '^$' | sort -u)

# 2. Separar normales de las que empiezan con "-"
normales=$(echo "$all_words" | grep -v '^-')
con_guion=$(echo "$all_words" | grep '^-')

# 3. Unir ambos grupos (normales primero, guiones después)
# Luego procesar con awk para el formato de 70 caracteres
echo "$normales $con_guion" | awk -v width=63 '
{
    for (i=1; i<=NF; i++) {
        # Si añadir la palabra excede el ancho, cerramos línea
        if (length(line) + length($i) + 1 > width) {
            print "     " line " \\"
            line = $i
        } else {
            line = (line == "" ? $i : line " " $i)
        }
    }
}
END {
    # Imprimir la última línea acumulada
    print "     " line
}' | sed '1 s/     /     "/; $ s/$/"/' > "$OUTPUT_FILE"

echo "Proceso completado. Resultado en: $OUTPUT_FILE"
