#!/bin/bash
# Define la variable con la ruta del directorio a explorar.
# Cambia `ruta/a/tu/directorio` por la ruta real.
DIRECTORIO="$HOME/.config/wallpaper"
# Verifica si el directorio existe al inicio. Si no, muestra un error y sale.
if [ ! -d "$DIRECTORIO" ]; then
  echo "Error: El directorio '$DIRECTORIO' no existe."
  exit 1
fi
# Inicia un bucle infinito. Puedes detenerlo en cualquier momento
# presionando Ctrl + C.
while true; do
  # Declara un arreglo para almacenar los archivos de imagen encontrados.
  declare -a IMAGENES=()

  # Itera sobre los archivos del directorio y subdirectorios, buscando archivos de imagen.
  while IFS= read -r archivo; do
    extension="${archivo##*.}"
    case "${extension,,}" in
    jpg | jpeg | png | gif | bmp | webp)
      IMAGENES+=("$archivo")
      ;;
    esac
  done < <(find "$DIRECTORIO" -type f)

  # Verifica si se encontraron imágenes.
  if [ ${#IMAGENES[@]} -eq 0 ]; then
    echo "No se encontraron archivos de imagen en el directorio especificado. Esperando 5 segundos para volver a intentar."
    # Pausa de 5 segundos antes de volver a verificar.
    sleep 5
    continue
  fi

  # Mezcla el arreglo de imágenes de forma aleatoria usando `shuf`.
  # Luego, itera sobre cada imagen aleatoria y muestra su ruta completa.
  printf "%s\n" "${IMAGENES[@]}" | shuf | while IFS= read -r imagen_aleatoria; do
    matugen image "$imagen_aleatoria" &
    >/dev/null
    # echo "$imagen_aleatoria"
    # Opcional: añade una pausa entre cada archivo.
    sleep 600
    #sleep 6
  done

  # Pausa antes de repetir el proceso.
  # Esto evita que el script consuma demasiados recursos del sistema.
  # echo "--- Repitiendo el proceso en 5 segundos... ---"
  #sleep 5
  ~/.local/share/systools/launch-waybar.sh &
done
