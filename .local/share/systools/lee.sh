#!/bin/bash

# 1. Define la ruta del directorio
# Sustituye "/ruta/a/tus/imagenes" por la ruta real de tus imágenes
DIRECTORIO_IMAGENES="$HOME/.config/wallpaper"

# 2. Crea una lista de todos los archivos de imagen en el directorio
# Utiliza find para encontrar archivos con extensiones .jpg, .png, .gif, etc.
# Y los guarda en un array
mapfile -t ARCHIVOS_IMAGENES < <(find "$DIRECTORIO_IMAGENES" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \))

# 3. Verifica si hay archivos de imagen
if [ ${#ARCHIVOS_IMAGENES[@]} -eq 0 ]; then
  echo "No se encontraron archivos de imagen en '$DIRECTORIO_IMAGENES'."
  exit 1
fi

# 4. Inicializa el contador
INDICE=0
TOTAL_ARCHIVOS=${#ARCHIVOS_IMAGENES[@]}

# 5. Bucle para listar los archivos de forma cíclica
while true; do
  # 6. Muestra el archivo actual (con la ruta completa)
  echo "Archivo actual: ${ARCHIVOS_IMAGENES[$INDICE]}"
  matugen image ${ARCHIVOS_IMAGENES[$INDICE]}
  ~/.config/waybar/scripts/launch.sh
  sleep 300

  # 7. Espera la entrada del usuario para continuar
  #read -p "Presiona Enter para continuar con el siguiente archivo, o escribe 'exit' para salir..."

  # 8. Comprueba si el usuario quiere salir
  if [[ "${REPLY,,}" == "exit" ]]; then
    echo "Saliendo del script."
    break
  fi

  # 9. Incrementa el índice
  INDICE=$((INDICE + 1))

  # 10. Si se llega al final, vuelve al principio (el primer archivo)
  if [ $INDICE -eq $TOTAL_ARCHIVOS ]; then
    INDICE=0
  fi
done
