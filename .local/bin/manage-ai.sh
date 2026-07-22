#!/bin/bash

# ~/.local/bin/manage_llm.sh
# Gestion de servicios LLM en Gentoo OpenRC

SERVICES=("ollama" "open-webui")

check_status() {
  echo "--- Estatus actual ---"
  for svc in "${SERVICES[@]}"; do
    if sudo rc-service "$svc" status >/dev/null 2>&1; then
      echo "[RUNNING] $svc"
    else
      echo "[STOPPED] $svc"
    fi
  done
  echo "----------------------"
}

run_action() {
  local action=$1
  for svc in "${SERVICES[@]}"; do
    echo "Ejecutando $action sobre $svc..."
    sudo rc-service "$svc" "$action"
  done
}

while true; do
  clear
  check_status
  echo "Seleccione una accion:"
  options=("Iniciar servicios" "Detener servicios y salir" "Salir")
  select opt in "${options[@]}"; do
    case $opt in
      "Iniciar servicios")
        run_action "start"
        break
        ;;
      "Detener servicios y salir")
        run_action "stop"
        exit 0
        ;;
      "Salir")
        exit 0
        ;;
      *) echo "Opcion invalida" ;;
    esac
  done
done
