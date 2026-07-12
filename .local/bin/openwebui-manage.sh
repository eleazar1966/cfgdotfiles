#!/usr/bin/env bash

CONTAINER="open-webui"
PORT=3000

# Colores para la interfaz de la consola
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m'

# 1. Función para verificar el estado de los servicios
mostrar_estado() {
  clear
  echo -e "${AZUL}=== ESTADO ACTUAL DEL SISTEMA IA ===${NC}"

  # Comprobar Ollama mediante OpenRC (no requiere sudo para ver el estado)
  if rc-service ollama status 2>/dev/null | grep -q "started"; then
    echo -e "Ollama:      ${VERDE}ACTIVO${NC}  (Servicio OpenRC en /etc/init.d/ollama)"
  else
    echo -e "Ollama:      ${ROJO}INACTIVO${NC} (Servicio OpenRC en /etc/init.d/ollama)"
  fi

  # Comprobar Open WebUI en Docker
  if [ "$(docker ps -q -f name=^/${CONTAINER}$)" ]; then
    echo -e "Open WebUI:  ${VERDE}ACTIVO${NC}  (Escuchando en http://localhost:$PORT)"
  else
    echo -e "Open WebUI:  ${ROJO}INACTIVO${NC}"
  fi
  echo -e "${AZUL}====================================${NC}\n"
}

# 2. Funciones de control de servicios
iniciar_servicios() {
  # Levantar Ollama usando OpenRC con sudo
  if ! rc-service ollama status 2>/dev/null | grep -q "started"; then
    echo -e "${AMARILLO}Iniciando servicio Ollama con sudo...${NC}"
    sudo rc-service ollama start
    sleep 1.5
  fi

  # Levantar Open WebUI en Docker
  if [ "$(docker ps -q -f name=^/${CONTAINER}$)" ]; then
    echo -e "${AZUL}Open WebUI ya se estaba ejecutando.${NC}"
  elif [ "$(docker ps -a -q -f name=^/${CONTAINER}$)" ]; then
    echo -e "${AMARILLO}Iniciando contenedor Open WebUI...${NC}"
    docker start $CONTAINER
  else
    echo -e "${ROJO}Contenedor no encontrado. Creando nuevo con red host...${NC}"
    docker run -d \
      --network=host \
      -e PORT=$PORT \
      -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
      -e RAG_FILE_MAX_SIZE=300 \
      -v open-webui:/app/backend/data \
      --name $CONTAINER \
      --restart always \
      ghcr.io/open-webui/open-webui:main
  fi
  echo -e "${VERDE}¡Todo encendido con éxito!${NC}"
}

detener_servicios() {
  echo -e "${AMARILLO}Apagando servicios...${NC}"

  # Detener contenedor Docker
  if [ "$(docker ps -q -f name=^/${CONTAINER}$)" ]; then
    docker stop $CONTAINER
    echo -e "${VERDE}[✓] Open WebUI detenido.${NC}"
  fi

  # Detener Ollama mediante OpenRC con sudo
  if rc-service ollama status 2>/dev/null | grep -q "started"; then
    echo -e "${AMARILLO}Deteniendo servicio Ollama con sudo...${NC}"
    sudo rc-service ollama stop
    echo -e "${VERDE}[✓] Servicio Ollama detenido.${NC}"
  fi

  echo -e "${ROJO}Todos los servicios se han apagado.${NC}"
}

# 3. Menú interactivo principal
while true; do
  mostrar_estado

  echo "Selecciona una opción:"
  echo "1) Encender / Activar servicios"
  echo "2) Apagar / Parar servicios"
  echo "3) Reiniciar servicios"
  echo "4) Volver a verificar estado"
  echo "5) Salir"
  echo -n "Opción [1-5]: "
  read -r opcion

  case $opcion in
    1)
      iniciar_servicios
      ;;
    2)
      detener_servicios
      ;;
    3)
      echo -e "${AMARILLO}Reiniciando entorno...${NC}"
      detener_servicios
      sleep 1
      iniciar_servicios
      ;;
    4)
      # El bucle limpia pantalla al inicio de la siguiente iteración
      ;;
    5)
      clear
      echo -e "${AZUL}Saliendo del script. ¡Buen día!${NC}"
      exit 0
      ;;
    *)
      echo -e "${ROJO}Opción inválida. Intenta de nuevo.${NC}"
      sleep 1
      ;;
  esac

  echo -e "\nPresiona [Enter] para continuar..."
  read -r
done
