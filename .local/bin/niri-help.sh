#!/usr/bin/env bash
# =============================================================================
# NIRI - MANUAL INTERACTIVO DE EXPERTO (PRODUCCIÓN - IDIOMA INTEGRADO)
# =============================================================================

set -e

# Crear un archivo temporal directamente en la RAM (Memoria Compartida)
TEMP_MANUAL=$(mktemp --tmpdir=/dev/shm niri_manual.XXXXXX)

# Asegurar la purga del archivo temporal al cerrar el script
trap 'rm -f "$TEMP_MANUAL"' EXIT

# Inyectar el manual en el búfer de memoria gráfica
cat <<'EOF' >"$TEMP_MANUAL"
=============================================================================
         ARQUITECTURA DE NIRI - MANUAL DE EJECUCIÓN PARA EXPERTOS
=============================================================================
Paradigma Central: Cinta horizontal infinita. Las ventanas se apilan en 
columnas verticales y las columnas se desplazan linealmente hacia los lados.

1. NAVEGACIÓN, ENFOQUE E IDIOMA (Control del entorno y teclado)
-----------------------------------------------------------------------------
  • Mod + H / Izquierda   : Enfoca la columna de la izquierda.
  • Mod + L / Derecha     : Enfoca la columna de la derecha.
  • Mod + J / Abajo       : Baja el foco dentro de la columna actual.
  • Mod + K / Arriba      : Sube el foco dentro de la columna actual.
  • Mod + Home / End      : Salta instantáneamente al inicio o fin de la cinta.
  • Mod + O               : Alterna la Vista General para mapear todo el diseño.
  • Alt + Shift           : Alterna la distribución del teclado (Inglés <-> Español).

2. REORGANIZACIÓN DINÁMICA (Mover contenedores y ventanas)
-----------------------------------------------------------------------------
  • Mod + Shift + H / L   : Desplaza la columna completa a izquierda o derecha.
  • Mod + Shift + J / K   : Cambia el orden vertical de la ventana en su columna.
  • Mod + Shift + Home/End: Envía la columna al extremo inicial o final absoluto.

3. OPERACIONES DE COLUMNAS (Mutación de contenedores)
-----------------------------------------------------------------------------
  • Mod + [ (Corchete Izq): Integra la ventana dentro de la columna vecina.
  • Mod + ] (Corchete Der): Expulsa la ventana fuera de la columna actual.
  • Mod + , (Coma)         : Integra o expulsa de forma inteligente a la izquierda.
  • Mod + . (Punto)        : Integra o expulsa de forma inteligente a la derecha.
  • Mod + W               : Alterna la columna entre diseño vertical y pestañas.

4. DIMENSIONAMIENTO Y ESCALADO GEOMÉTRICO
-----------------------------------------------------------------------------
  • Mod + R               : Alterna entre los anchos predefinidos (33%, 50%, 66%).
  • Mod + F               : Maximiza la columna actual (conservando los márgenes).
  • Mod + Shift + F       : Modo Pantalla Completa absoluto de la ventana activa.
  • Mod + C               : Centra la columna activa en el monitor.
  • Mod + Minus / Equal   : Ajusta el ancho de la columna (-10% / +10%).
  • Mod + Shift + - / =   : Ajusta la altura de la ventana (-10% / +10%).
  • Mod + V               : Alterna la ventana entre modo Flotante y Mosaico.

5. GESTIÓN DE ESPACIOS DE TRABAJO (Entornos Virtuales Dinámicos)
-----------------------------------------------------------------------------
  • Mod + Page_Down / U   : Avanza al siguiente Espacio de Trabajo.
  • Mod + Page_Up / I     : Retrocede al Espacio de Trabajo anterior.
  • Mod + Ctrl + PgDown    : Mueve la columna actual al Espacio de Trabajo inferior.
  • Mod + Ctrl + PgUp      : Mueve la columna actual al Espacio de Trabajo superior.
  • Mod + [1 a 9]          : Salto directo al Espacio de Trabajo numérico.
  • Mod + Shift + [1 a 9]    : Envía la columna al Espacio de Trabajo numérico indicado.

6. SUBSISTEMA MULTIMEDIA, CAPTURAS Y SCRIPTS PROPIOS
-----------------------------------------------------------------------------
  • Teclas de Vol (Fn)    : Ajuste global de audio con alertas visuales de Mako.
  • Mod + N               : Alterna Silencio/Activo del Micrófono con aviso en Mako.
  • Print                 : Captura de pantalla nativa de Niri.
  • Ctrl + Print          : Captura exclusiva de la pantalla completa actual.
  • Alt + Print           : Captura exclusiva de la ventana que tiene el foco.
  • Mod + G               : Ejecuta tu script personalizado 'graba_video.sh'.

7. LANZADORES Y HERRAMIENTAS DE ENTORNO
-----------------------------------------------------------------------------
  • Mod + Return          : Despliega la terminal principal (Kitty).
  • Mod + D               : Despliega el menú de aplicaciones (Fuzzel).
  • Mod + E               : Abre el gestor de archivos gráfico (Thunar).
  • Mod + T               : Abre Telegram bajo el entorno estable de XWayland.
  • Mod + Shift + Slash   : Muestra el panel nativo de atajos de Niri.

8. SISTEMA, INHIBICIÓN Y SEGURIDAD CRÍTICA
-----------------------------------------------------------------------------
  • Mod + Escape          : Activa/Desactiva el bloqueo de atajos para VM o KVM.
  • Mod + Q               : Cierra la ventana que se encuentra bajo el foco actual.
  • Mod + Shift + P       : Apaga los monitores (DPMS) de forma segura.
  • Mod + Shift + E       : Envía una señal de salida limpia para cerrar Niri.
  • Ctrl + Alt + Delete   : Cierre alternativo de emergencia de la sesión gráfica.

=============================================================================
             [ Presiona 'q' para salir del manual interactivo ]
=============================================================================
EOF

# Less lee de forma limpia el archivo persistente en memoria RAM
less -R "$TEMP_MANUAL"
