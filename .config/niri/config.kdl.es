[cite_start]// Este archivo de configuración está en formato KDL: https://kdl.dev [cite: 1]
[cite_start]// "/-" comenta el nodo siguiente. [cite: 2]
// Consulta la wiki para una descripción completa de la configuración:
[cite_start]// https://yalter.github.io/niri/Configuration:-Introduction [cite: 2]

// Configuración del dispositivo de entrada.
// Encuentra la lista completa de opciones en la wiki:
[cite_start]// https://yalter.github.io/niri/Configuration:-Input [cite: 3]
input {
    keyboard {
        xkb {
            // Puedes establecer rules, model, layout, variant y options.
            [cite_start]// Para más información, consulta xkeyboard-config(7). [cite: 4]

            // Por ejemplo:
            // layout "us,ru"
            // options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"

            // Si esta sección está vacía, niri obtendrá la configuración de xkb
            // de org.freedesktop.locale1.
            // Puedes controlarlos usando
            [cite_start]// localectl set-x11-keymap. [cite: 5, 6]
        }

        [cite_start]// Habilita numlock al inicio, omitir esta configuración lo deshabilita. [cite: 7]
        numlock
    }

    // Las siguientes secciones incluyen la configuración de libinput.
    [cite_start]// Omitir las configuraciones las deshabilita, o las deja en sus valores predeterminados. [cite: 8]
    [cite_start]// Todas las configuraciones comentadas aquí son ejemplos, no valores predeterminados. [cite: 9]
    touchpad {
        // off
        tap
        // dwt
        // dwtp
        // drag false
        // drag-lock
        natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        
        [cite_start]// scroll-method "two-finger" [cite: 10]
        // disabled-on-external-mouse
    }

    mouse {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "no-scroll"
    }

    trackpoint {
        // off
        // natural-scroll
     
        [cite_start]// accel-speed 0.2 [cite: 11]
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // scroll-button-lock
        // middle-emulation
    }

    [cite_start]// Descomenta esto para hacer que el ratón se mueva al centro de las ventanas recién enfocadas. [cite: 12]
    // warp-mouse-to-focus

    [cite_start]// Enfoca ventanas y salidas automáticamente al mover el ratón hacia ellas. [cite: 13]
    [cite_start]// Establecer max-scroll-amount="0%" hace que funcione solo en ventanas que ya están completamente en pantalla. [cite: 14]
    // focus-follows-mouse max-scroll-amount="0%"
}

// Puedes configurar las salidas por su nombre, el cual puedes encontrar
[cite_start]// ejecutando `niri msg outputs` dentro de una instancia de niri. [cite: 15]
[cite_start]// El monitor de portátil incorporado se llama usualmente "eDP-1". [cite: 15]
// Encuentra más información en la wiki:
// https://yalter.github.io/niri/Configuration:-Outputs
[cite_start]// ¡Recuerda descomentar el nodo quitando "/-"! [cite: 16]
/-output "eDP-1" {
    [cite_start]// Descomenta esta línea para deshabilitar esta salida. [cite: 17]
    // off

    // Resolución y, opcionalmente, frecuencia de actualización de la salida.
    [cite_start]// El formato es "<ancho>x<alto>" o "<ancho>x<alto>@<frecuencia de actualización>". [cite: 18]
    // Si se omite la frecuencia de actualización, niri elegirá la frecuencia de actualización más alta
    [cite_start]// para la resolución. [cite: 19]
    [cite_start]// Si el modo se omite por completo o no es válido, niri elegirá uno automáticamente. [cite: 20]
    [cite_start]// Ejecuta `niri msg outputs` dentro de una instancia de niri para listar todas las salidas y sus modos. [cite: 21]
    mode "1920x1080@120.030"

    [cite_start]// Puedes usar escala entera o fraccionaria, por ejemplo, usa 1.5 para una escala del 150%. [cite: 22]
    scale 2

    // Transform permite rotar la salida en sentido antihorario, los valores válidos son:
    [cite_start]// normal, 90, 180, 270, flipped, flipped-90, flipped-180 y flipped-270. [cite: 23]
    transform "normal"

    // Posición de la salida en el espacio de coordenadas globales.
    [cite_start]// Esto afecta a las acciones direccionales del monitor como "focus-monitor-left" y al movimiento del cursor. [cite: 24]
    [cite_start]// El cursor solo puede moverse entre salidas directamente adyacentes. [cite: 25]
    // La escala y rotación de la salida deben tenerse en cuenta para el posicionamiento:
    [cite_start]// las salidas se dimensionan en píxeles lógicos, o escalados. [cite: 26]
    // Por ejemplo, una salida de 3840×2160 con escala 2.0 tendrá un tamaño lógico de 1920×1080,
    [cite_start]// por lo que para colocar otra salida directamente adyacente a su derecha, establece su x en 1920. [cite: 27]
    // Si la posición no está establecida o resulta en una superposición, la salida se coloca en su lugar
    [cite_start]// automáticamente. [cite: 28]
    position x=1280 y=0
}

// Configuraciones que influyen en cómo se posicionan y dimensionan las ventanas.
// Encuentra más información en la wiki:
[cite_start]// https://yalter.github.io/niri/Configuration:-Layout [cite: 29]
layout {
    [cite_start]// Establece los espacios alrededor de las ventanas en píxeles lógicos. [cite: 30]
    gaps 16

    // Cuándo centrar una columna al cambiar el foco, las opciones son:
    // - "never", comportamiento predeterminado, enfocar una columna fuera de la pantalla se mantendrá en el borde
    [cite_start]//   izquierdo o derecho de la pantalla. [cite: 31]
    [cite_start]// - "always", la columna enfocada siempre se centrará. [cite: 32]
    // - "on-overflow", enfocar una columna la centrará si no cabe
    [cite_start]//   junto con la columna enfocada anteriormente. [cite: 33]
    center-focused-column "never"

    [cite_start]// Puedes personalizar los anchos entre los que conmuta "switch-preset-column-width" (Mod+R). [cite: 34]
    preset-column-widths {
        [cite_start]// Proportion establece el ancho como una fracción del ancho de la salida, teniendo en cuenta los espacios. [cite: 35]
        [cite_start]// Por ejemplo, puedes encajar perfectamente cuatro ventanas de tamaño "proportion 0.25" en una salida. [cite: 36]
        [cite_start]// Los anchos preestablecidos por defecto son 1/3, 1/2 y 2/3 de la salida. [cite: 37]
        proportion 0.33333
        proportion 0.5
        proportion 0.66667

        [cite_start]// Fixed establece el ancho exactamente en píxeles lógicos. [cite: 38]
        // fixed 1920
    }

    [cite_start]// También puedes personalizar las alturas entre las que conmuta "switch-preset-window-height" (Mod+Shift+R). [cite: 39]
    // preset-window-heights { }

    [cite_start]// Puedes cambiar el ancho predeterminado de las nuevas ventanas. [cite: 40]
    default-column-width { proportion 0.5; }
    [cite_start]// Si dejas los corchetes vacíos, las propias ventanas decidirán su ancho inicial. [cite: 41]
    // default-column-width {}

    // Por defecto, el anillo de foco y el borde se renderizan como un rectángulo de fondo sólido
    [cite_start]// detrás de las ventanas. [cite: 42]
    [cite_start]// Es decir, se mostrarán a través de ventanas semitransparentes. [cite: 42]
    [cite_start]// Esto se debe a que las ventanas que usan decoraciones del lado del cliente pueden tener una forma arbitraria. [cite: 43]
    //
    [cite_start]// Si no te gusta eso, deberías descomentar `prefer-no-csd` a continuación. [cite: 44]
    // Niri dibujará el anillo de foco y el borde *alrededor* de las ventanas que acepten omitir sus
    [cite_start]// decoraciones del lado del cliente. [cite: 45]
    //
    // Alternativamente, puedes anularlo con una regla de ventana llamada
    [cite_start]// `draw-border-with-background`. [cite: 46]
    // Puedes cambiar el aspecto del anillo de foco.
    focus-ring {
        [cite_start]// Descomenta esta línea para deshabilitar el anillo de foco. [cite: 47]
        // off

        [cite_start]// Cuántos píxeles lógicos se extiende el anillo desde las ventanas. [cite: 48]
        width 4

        // Los colores se pueden establecer de varias maneras:
        // - Nombres de colores CSS: "red"
        // - Hexadecimal RGB: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
        [cite_start]// - Notación tipo CSS: "rgb(255, 127, 0)", rgba(), hsl() y algunas otras. [cite: 49]
        // Color del anillo en el monitor activo.
        active-color "#7fc8ff"

        [cite_start]// Color del anillo en monitores inactivos. [cite: 50]
        //
        // El anillo de foco solo se dibuja alrededor de la ventana activa, por lo que el único lugar
        [cite_start]// donde puedes ver su inactive-color es en otros monitores. [cite: 51]
        inactive-color "#505050"

        [cite_start]// También puedes usar gradientes. [cite: 52]
        [cite_start]// Toman precedencia sobre los colores sólidos. [cite: 52]
        [cite_start]// Los gradientes se renderizan igual que CSS linear-gradient(angle, from, to). [cite: 53]
        // El ángulo es el mismo que en linear-gradient, y es opcional,
        [cite_start]// por defecto es 180 (gradiente de arriba a abajo). [cite: 54]
        [cite_start]// Puedes usar cualquier herramienta de CSS linear-gradient en la web para configurarlos. [cite: 55]
        [cite_start]// También se admite cambiar el espacio de color, consulta la wiki para más información. [cite: 56]
        //
        // active-gradient from="#80c8ff" to="#c7ff7f" angle=45

        // También puedes colorear el gradiente en relación con toda la vista
        [cite_start]// del espacio de trabajo, en lugar de solo en relación con la ventana en sí. [cite: 57]
        // Para hacer eso, establece relative-to="workspace-view".
        //
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    [cite_start]// También puedes añadir un borde. [cite: 58]
    [cite_start]// Es similar al anillo de foco, pero siempre visible. [cite: 58]
    border {
        [cite_start]// Los ajustes son los mismos que para el anillo de foco. [cite: 59]
        [cite_start]// Si habilitas el borde, probablemente querrás deshabilitar el anillo de foco. [cite: 60]
        off

        width 4
        active-color "#ffc87f"
        inactive-color "#505050"

        [cite_start]// Color del borde alrededor de las ventanas que solicitan tu atención. [cite: 61]
        urgent-color "#9b0000"

        [cite_start]// Los gradientes pueden usar diferentes espacios de color de interpolación. [cite: 62]
        [cite_start]// Por ejemplo, este es un gradiente de arco iris pastel a través de in="oklch longer hue". [cite: 63]
        //
        // active-gradient from="#e5989b" to="#ffb4a2" angle=45 relative-to="workspace-view" in="oklch longer hue"

        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    [cite_start]// Puedes habilitar las sombras paralelas (drop shadows) para las ventanas. [cite: 64]
    shadow {
        [cite_start]// Descomenta la siguiente línea para habilitar las sombras. [cite: 65]
        // on

        [cite_start]// Por defecto, la sombra se dibuja solo alrededor de su ventana, y no detrás de ella. [cite: 66]
        [cite_start]// Descomenta esta configuración para hacer que la sombra se dibuje detrás de su ventana. [cite: 67]
        //
        [cite_start]// Ten en cuenta que niri no tiene forma de saber sobre el radio de la esquina de la ventana CSD. [cite: 68]
        [cite_start]// Tiene que asumir que las ventanas tienen esquinas cuadradas, lo que lleva a [cite: 68]
        [cite_start]// artefactos de sombra dentro de las esquinas redondeadas de CSD. [cite: 69]
        [cite_start]// Esta configuración soluciona [cite: 69]
        [cite_start]// esos artefactos. [cite: 70]
        //
        // Sin embargo, en su lugar, es posible que desees establecer prefer-no-csd y/o
        [cite_start]// geometry-corner-radius. [cite: 71]
        // Entonces, niri sabrá el radio de la esquina y
        // dibujará la sombra correctamente, sin tener que dibujarla detrás de la
        [cite_start]// ventana. [cite: 72]
        // Estos también eliminarán las sombras del lado del cliente si la ventana
        [cite_start]// dibuja alguna. [cite: 73]
        //
        // draw-behind-window true

        [cite_start]// Puedes cambiar el aspecto de las sombras. [cite: 74]
        [cite_start]// Los valores a continuación están en píxeles lógicos [cite: 74]
        [cite_start]// y coinciden con las propiedades CSS box-shadow. [cite: 75]
        // Softness controla el radio de desenfoque de la sombra.
        softness 30

        [cite_start]// Spread expande la sombra. [cite: 76]
        spread 5

        [cite_start]// Offset mueve la sombra en relación con la ventana. [cite: 77]
        offset x=0 y=5

        [cite_start]// También puedes cambiar el color y la opacidad de la sombra. [cite: 78]
        color "#0007"
    }

    [cite_start]// Struts encogen el área ocupada por las ventanas, de manera similar a los paneles layer-shell. [cite: 79]
    // Puedes pensar en ellos como una especie de espacios exteriores. [cite_start]Se establecen en píxeles lógicos. [cite: 80]
    [cite_start]// Los struts izquierdo y derecho harán que la siguiente ventana al lado sea siempre visible. [cite: 81]
    // Los struts superior e inferior simplemente agregarán espacios exteriores además del área ocupada por
    [cite_start]// los paneles layer-shell y los espacios regulares. [cite: 82]
    struts {
        // left 64
        // right 64
        // top 64
        // bottom 64
    }
}

[cite_start]// Agrega líneas como esta para iniciar procesos al inicio. [cite: 83]
// Ten en cuenta que ejecutar niri como una sesión es compatible con xdg-desktop-autostart,
[cite_start]// lo que puede ser más conveniente de usar. [cite: 84]
[cite_start]// Consulta la sección binds a continuación para ver más ejemplos de spawn. [cite: 85]
[cite_start]// Esta línea inicia waybar, una barra comúnmente utilizada para compositores Wayland. [cite: 86]
spawn-at-startup "waybar"

// Para ejecutar un comando de shell (con variables, tuberías, etc.), usa spawn-sh-at-startup:
// spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"

hotkey-overlay {
    [cite_start]// Descomenta esta línea para deshabilitar la ventana emergente "Teclas Importantes" al inicio. [cite: 87]
    // skip-at-startup
}

[cite_start]// Descomenta esta línea para pedir a los clientes que omitan sus decoraciones del lado del cliente si es posible. [cite: 88]
[cite_start]// Si el cliente solicita específicamente CSD, la solicitud será respetada. [cite: 89]
[cite_start]// Además, se informará a los clientes que están en mosaico, eliminando algunas esquinas redondeadas del lado del cliente. [cite: 90]
[cite_start]// Esta opción también solucionará el dibujo del borde/anillo de foco detrás de algunas ventanas semitransparentes. [cite: 91]
[cite_start]// Después de habilitar o deshabilitar esto, debes reiniciar las aplicaciones para que tenga efecto. [cite: 92]
// prefer-no-csd

[cite_start]// Puedes cambiar la ruta donde se guardan las capturas de pantalla. [cite: 93]
[cite_start]// Una ~ al principio se expandirá al directorio de inicio. [cite: 94]
[cite_start]// La ruta se formatea con strftime(3) para darte la fecha y hora de la captura de pantalla. [cite: 95]
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

[cite_start]// También puedes establecer esto en null para deshabilitar el guardado de capturas de pantalla en el disco. [cite: 96]
// screenshot-path null

// Configuraciones de animación.
// La wiki explica cómo configurar animaciones individuales:
// https://yalter.github.io/niri/Configuration:-Animations
animations {
    [cite_start]// Descomentar para desactivar todas las animaciones. [cite: 97]
    // off

    // Ralentiza todas las animaciones por este factor. [cite_start]Los valores por debajo de 1 las aceleran. [cite: 98]
    // slowdown 3.0
}

[cite_start]// Las reglas de ventana te permiten ajustar el comportamiento de ventanas individuales. [cite: 99]
// Encuentra más información en la wiki:
// https://yalter.github.io/niri/Configuration:-Window-Rules

// Solución para el error de configuración inicial de WezTerm
[cite_start]// estableciendo un default-column-width vacío. [cite: 100]
window-rule {
    // Esta expresión regular está intencionalmente hecha lo más específica posible,
    [cite_start]// ya que esta es la configuración predeterminada, y no queremos falsos positivos. [cite: 101]
    [cite_start]// Puedes conformarte con solo app-id="wezterm" si lo deseas. [cite: 102]
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}

[cite_start]// Abre el reproductor picture-in-picture de Firefox como flotante por defecto. [cite: 103]
window-rule {
    // Esta expresión regular de app-id funcionará para ambos:
    // - Firefox de host (app-id es "firefox")
    // - Firefox Flatpak (app-id es "org.mozilla.firefox")
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

[cite_start]// Ejemplo: bloquea dos gestores de contraseñas de la captura de pantalla. [cite: 104]
// (Esta regla de ejemplo está comentada con un "/-" delante.)
/-window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#

    block-out-from "screen-capture"

    [cite_start]// Usa esto en su lugar si quieres que sean visibles en herramientas de captura de pantalla de terceros. [cite: 105]
    // block-out-from "screencast"
}

[cite_start]// Ejemplo: habilita esquinas redondeadas para todas las ventanas. [cite: 106]
// (Esta regla de ejemplo está comentada con un "/-" delante.)
/-window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}

binds {
    // Las teclas consisten en modificadores separados por signos +, seguidos de un nombre de tecla XKB
    [cite_start]// al final. [cite: 107]
    // Para encontrar un nombre XKB para una tecla en particular, puedes usar un programa
    [cite_start]// como wev. [cite: 108]
    //
    // "Mod" es un modificador especial igual a Super cuando se ejecuta en un TTY, y a Alt
    [cite_start]// cuando se ejecuta como una ventana winit. [cite: 109]
    //
    // La mayoría de las acciones que puedes vincular aquí también se pueden invocar programáticamente con
    [cite_start]// `niri msg action do-something`. [cite: 110]
    // Mod-Shift-/, que es usualmente lo mismo que Mod-?,
    [cite_start]// muestra una lista de atajos de teclado importantes. [cite: 111]
    Mod+Shift+Slash { show-hotkey-overlay; }

    // Vinculaciones sugeridas para ejecutar programas: terminal, lanzador de aplicaciones, bloqueador de pantalla.
    [cite_start]Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; [cite: 112] }
    [cite_start]Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; [cite: 113]
    }
    [cite_start]Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; [cite: 114]
    }

    [cite_start]// Usa spawn-sh para ejecutar un comando de shell. [cite: 115]
    [cite_start]// Haz esto si necesitas tuberías, múltiples comandos, etc. [cite: 115]
    [cite_start]// Nota: el comando completo va como un solo argumento. [cite: 116]
    [cite_start]// Se pasa textualmente a `sh -c`. [cite: 116]
    [cite_start]// Por ejemplo, este es un enlace estándar para alternar el lector de pantalla (orca). [cite: 117]
    [cite_start]Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; [cite: 118]
    }

    [cite_start]// Ejemplo de mapeos de teclas de volumen para PipeWire & WirePlumber. [cite: 119]
    [cite_start]// La propiedad allow-when-locked=true hace que funcionen incluso cuando la sesión está bloqueada. [cite: 120]
    [cite_start]// Usar spawn-sh permite pasar múltiples argumentos junto con el comando. [cite: 121]
    [cite_start]// "-l 1.0" limita el volumen al 100%. [cite: 121]
    [cite_start]XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; [cite: 122]
    }
    [cite_start]XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; [cite: 123]
    }
    [cite_start]XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; [cite: 124]
    }
    [cite_start]XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; [cite: 125]
    }

    // Ejemplo de mapeo de teclas multimedia usando playerctl.
    [cite_start]// Esto funcionará con cualquier reproductor multimedia habilitado para MPRIS. [cite: 126]
    [cite_start]XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; [cite: 127]
    }
    [cite_start]XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; [cite: 128]
    }
    [cite_start]XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; [cite: 129]
    }
    [cite_start]XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; [cite: 130]
    }

    [cite_start]// Ejemplo de mapeo de teclas de brillo para brightnessctl. [cite: 131]
    // También puedes usar spawn regular con múltiples argumentos (para evitar pasar por "sh"),
    [cite_start]// pero necesitas poner manualmente cada argumento entre comillas "" separadas. [cite: 132]
    XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    [cite_start]XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; [cite: 133]
    }

    [cite_start]// Abrir/cerrar la Vista General (Overview): una vista ampliada de los espacios de trabajo y las ventanas. [cite: 134]
    // También puedes mover el ratón a la esquina superior izquierda,
    [cite_start]// o hacer un deslizamiento de cuatro dedos hacia arriba en un panel táctil. [cite: 135]
    Mod+O repeat=false { toggle-overview; }

    Mod+Q repeat=false { close-window; }

    [cite_start]Mod+Left  { focus-column-left; [cite: 136]
    }
    Mod+Down  { focus-window-down; }
    [cite_start]Mod+Up    { focus-window-up; [cite: 137]
    }
    Mod+Right { focus-column-right; }
    [cite_start]Mod+H     { focus-column-left; [cite: 138]
    }
    [cite_start]Mod+J     { focus-window-down; [cite: 139]
    }
    [cite_start]Mod+K     { focus-window-up; [cite: 140]
    }
    Mod+L     { focus-column-right; }

    [cite_start]Mod+Ctrl+Left  { move-column-left; [cite: 141]
    }
    Mod+Ctrl+Down  { move-window-down; }
    [cite_start]Mod+Ctrl+Up    { move-window-up; [cite: 142]
    }
    Mod+Ctrl+Right { move-column-right; }
    [cite_start]Mod+Ctrl+H     { move-column-left; [cite: 143]
    }
    [cite_start]Mod+Ctrl+J     { move-window-down; [cite: 144]
    }
    [cite_start]Mod+Ctrl+K     { move-window-up; [cite: 145]
    }
    [cite_start]Mod+Ctrl+L     { move-column-right; [cite: 146]
    }

    // Comandos alternativos que se mueven a través de espacios de trabajo al alcanzar
    [cite_start]// la primera o última ventana en una columna. [cite: 147]
    // Mod+J     { focus-window-or-workspace-down; }
    [cite_start]// Mod+K     { focus-window-or-workspace-up; [cite: 148]
    }
    [cite_start]// Mod+Ctrl+J     { move-window-down-or-to-workspace-down; [cite: 149]
    }
    // Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

    [cite_start]Mod+Home { focus-column-first; [cite: 150]
    }
    Mod+End  { focus-column-last; }
    [cite_start]Mod+Ctrl+Home { move-column-to-first; [cite: 151]
    }
    Mod+Ctrl+End  { move-column-to-last; }

    [cite_start]Mod+Shift+Left  { focus-monitor-left; [cite: 152]
    }
    Mod+Shift+Down  { focus-monitor-down; }
    [cite_start]Mod+Shift+Up    { focus-monitor-up; [cite: 153]
    }
    Mod+Shift+Right { focus-monitor-right; }
    [cite_start]Mod+Shift+H     { focus-monitor-left; [cite: 154]
    }
    [cite_start]Mod+Shift+J     { focus-monitor-down; [cite: 155]
    }
    [cite_start]Mod+Shift+K     { focus-monitor-up; [cite: 156]
    }
    Mod+Shift+L     { focus-monitor-right; }

    [cite_start]Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; [cite: 157]
    }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    [cite_start]Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; [cite: 158]
    }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
    [cite_start]Mod+Shift+Ctrl+H     { move-column-to-monitor-left; [cite: 159]
    }
    [cite_start]Mod+Shift+Ctrl+J     { move-column-to-monitor-down; [cite: 160]
    }
    [cite_start]Mod+Shift+Ctrl+K     { move-column-to-monitor-up; [cite: 161]
    }
    [cite_start]Mod+Shift+Ctrl+L     { move-column-to-monitor-right; [cite: 162]
    }

    // Alternativamente, hay comandos para mover solo una ventana:
    [cite_start]// Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; [cite: 163]
    }
    // ...

    // Y también puedes mover un espacio de trabajo completo a otro monitor:
    [cite_start]// Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; [cite: 164]
    }
    // ...

    [cite_start]Mod+Page_Down      { focus-workspace-down; [cite: 165]
    }
    [cite_start]Mod+Page_Up        { focus-workspace-up; [cite: 166]
    }
    [cite_start]Mod+U              { focus-workspace-down; [cite: 167]
    }
    [cite_start]Mod+I              { focus-workspace-up; [cite: 168]
    }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    [cite_start]Mod+Ctrl+Page_Up   { move-column-to-workspace-up; [cite: 169]
    }
    [cite_start]Mod+Ctrl+U         { move-column-to-workspace-down; [cite: 170]
    }
    [cite_start]Mod+Ctrl+I         { move-column-to-workspace-up; [cite: 171]
    }

    // Alternativamente, hay comandos para mover solo una ventana:
    [cite_start]// Mod+Ctrl+Page_Down { move-window-to-workspace-down; [cite: 172]
    }
    // ...

    [cite_start]Mod+Shift+Page_Down { move-workspace-down; [cite: 173]
    }
    Mod+Shift+Page_Up   { move-workspace-up; }
    [cite_start]Mod+Shift+U         { move-workspace-down; [cite: 174]
    }
    [cite_start]Mod+Shift+I         { move-workspace-up; [cite: 175]
    }

    [cite_start]// Puedes vincular los clics de la rueda del ratón usando la siguiente sintaxis. [cite: 176]
    [cite_start]// Estas vinculaciones cambiarán de dirección según la configuración natural-scroll. [cite: 177]
    //
    // Para evitar desplazarse por los espacios de trabajo muy rápido, puedes usar
    [cite_start]// la propiedad cooldown-ms. [cite: 178]
    [cite_start]// La vinculación se limitará a esta velocidad. [cite: 178]
    [cite_start]// Puedes establecer un cooldown en cualquier vinculación, pero es más útil para la rueda. [cite: 179]
    Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
    [cite_start]Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; [cite: 180]
    }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    [cite_start]Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; [cite: 181]
    }

    [cite_start]Mod+WheelScrollRight      { focus-column-right; [cite: 182]
    }
    Mod+WheelScrollLeft       { focus-column-left; }
    [cite_start]Mod+Ctrl+WheelScrollRight { move-column-right; [cite: 183]
    }
    Mod+Ctrl+WheelScrollLeft  { move-column-left; }

    // Usualmente, desplazarse hacia arriba y abajo con Shift en las aplicaciones resulta en
    [cite_start]// desplazamiento horizontal; [cite: 184]
    [cite_start]// estas vinculaciones replican eso. [cite: 184]
    [cite_start]Mod+Shift+WheelScrollDown      { focus-column-right; [cite: 185]
    }
    [cite_start]Mod+Shift+WheelScrollUp        { focus-column-left; [cite: 186]
    }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
    [cite_start]Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; [cite: 187]
    }

    [cite_start]// De manera similar, puedes vincular los "clics" de desplazamiento del panel táctil. [cite: 188]
    // El desplazamiento del panel táctil es continuo, por lo que para estas vinculaciones se divide en
    [cite_start]// intervalos discretos. [cite: 189]
    // Estas vinculaciones también se ven afectadas por el natural-scroll del panel táctil, por lo que estos
    // ejemplos de vinculaciones están "invertidos", ya que tenemos natural-scroll habilitado para
    [cite_start]// los paneles táctiles por defecto. [cite: 190]
    // Mod+TouchpadScrollDown { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+"; }
    [cite_start]// Mod+TouchpadScrollUp   { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-"; [cite: 191]
    }

    [cite_start]// Puedes referirte a los espacios de trabajo por índice. [cite: 192]
    // Sin embargo, ten en cuenta que
    // niri es un sistema dinámico de espacios de trabajo, por lo que estos comandos son una especie de
    [cite_start]// "mejor esfuerzo". [cite: 193]
    // Intentar referirse a un índice de espacio de trabajo mayor que
    // el recuento actual de espacios de trabajo se referirá en su lugar al espacio de trabajo más inferior
    [cite_start]// (vacío). [cite: 194]
    //
    // Por ejemplo, con 2 espacios de trabajo + 1 vacío, los índices 3, 4, 5 y así sucesivamente
    [cite_start]// se referirán todos al tercer espacio de trabajo. [cite: 195]
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    [cite_start]Mod+3 { focus-workspace 3; [cite: 196]
    }
    Mod+4 { focus-workspace 4; }
    [cite_start]Mod+5 { focus-workspace 5; [cite: 197]
    }
    Mod+6 { focus-workspace 6; }
    [cite_start]Mod+7 { focus-workspace 7; [cite: 198]
    }
    Mod+8 { focus-workspace 8; }
    [cite_start]Mod+9 { focus-workspace 9; [cite: 199]
    }
    Mod+Ctrl+1 { move-column-to-workspace 1; }
    [cite_start]Mod+Ctrl+2 { move-column-to-workspace 2; [cite: 200]
    }
    Mod+Ctrl+3 { move-column-to-workspace 3; }
    [cite_start]Mod+Ctrl+4 { move-column-to-workspace 4; [cite: 201]
    }
    Mod+Ctrl+5 { move-column-to-workspace 5; }
    [cite_start]Mod+Ctrl+6 { move-column-to-workspace 6; [cite: 202]
    }
    Mod+Ctrl+7 { move-column-to-workspace 7; }
    [cite_start]Mod+Ctrl+8 { move-column-to-workspace 8; [cite: 203]
    }
    Mod+Ctrl+9 { move-column-to-workspace 9; }

    // Alternativamente, hay comandos para mover solo una ventana:
    [cite_start]// Mod+Ctrl+1 { move-window-to-workspace 1; [cite: 204]
    }

    // Cambia el foco entre el espacio de trabajo actual y el anterior.
    [cite_start]// Mod+Tab { focus-workspace-previous; [cite: 205]
    }

    [cite_start]// Las siguientes vinculaciones mueven la ventana enfocada dentro y fuera de una columna. [cite: 206]
    [cite_start]// Si la ventana está sola, la consumirá en la columna cercana al lado. [cite: 207]
    // Si la ventana ya está en una columna, la expulsará.
    [cite_start]Mod+BracketLeft  { consume-or-expel-window-left; [cite: 208]
    }
    Mod+BracketRight { consume-or-expel-window-right; }

    [cite_start]// Consume una ventana de la derecha a la parte inferior de la columna enfocada. [cite: 209]
    Mod+Comma  { consume-window-into-column; }
    [cite_start]// Expulsa la ventana inferior de la columna enfocada a la derecha. [cite: 210]
    Mod+Period { expel-window-from-column; }

    [cite_start]Mod+R { switch-preset-column-width; [cite: 211]
    }
    // También es posible alternar entre los presets en orden inverso.
    [cite_start]// Mod+R { switch-preset-column-width-back; [cite: 212]
    }
    Mod+Shift+R { switch-preset-window-height; }
    [cite_start]Mod+Ctrl+R { reset-window-height; [cite: 213]
    }
    Mod+F { maximize-column; }
    [cite_start]Mod+Shift+F { fullscreen-window; [cite: 214]
    }

    [cite_start]// Expande la columna enfocada para ocupar el espacio no utilizado por otras columnas completamente visibles. [cite: 215]
    [cite_start]// Hace que la columna "llene el resto del espacio". [cite: 215]
    Mod+Ctrl+F { expand-column-to-available-width; }

    [cite_start]Mod+C { center-column; [cite: 216]
    }

    // Centra todas las columnas completamente visibles en la pantalla.
    [cite_start]Mod+Ctrl+C { center-visible-columns; [cite: 217]
    }

    // Ajustes de ancho más finos.
    // Este comando también puede:
    // * establecer el ancho en píxeles: "1000"
    // * ajustar el ancho en píxeles: "-5" o "+5"
    // * establecer el ancho como un porcentaje del ancho de la pantalla: "25%"
    // * ajustar el ancho como un porcentaje del ancho de la pantalla: "-10%" o "+10%"
    [cite_start]// Los tamaños en píxeles usan píxeles lógicos o escalados. [cite: 218]
    [cite_start]// Es decir, en una salida con escala 2.0, [cite: 218]
    [cite_start]// set-column-width "100" hará que la columna ocupe 200 píxeles físicos de pantalla. [cite: 219]
    Mod+Minus { set-column-width "-10%"; }
    [cite_start]Mod+Equal { set-column-width "+10%"; [cite: 220]
    }

    // Ajustes de altura más finos cuando está en una columna con otras ventanas.
    [cite_start]Mod+Shift+Minus { set-window-height "-10%"; [cite: 221]
    }
    Mod+Shift+Equal { set-window-height "+10%"; }

    [cite_start]// Mueve la ventana enfocada entre el diseño flotante y el de mosaico. [cite: 222]
    Mod+V       { toggle-window-floating; }
    [cite_start]Mod+Shift+V { switch-focus-between-floating-and-tiling; [cite: 223]
    }

    [cite_start]// Alterna el modo de visualización de columna con pestañas. [cite: 224]
    // Las ventanas en esta columna aparecerán como pestañas verticales,
    [cite_start]// en lugar de apiladas una encima de la otra. [cite: 225]
    Mod+W { toggle-column-tabbed-display; }

    [cite_start]// Acciones para cambiar diseños (layouts). [cite: 226]
    // Nota: si descomentas esto, asegúrate de NO tener
    [cite_start]// un atajo de teclado de cambio de diseño coincidente configurado en las opciones xkb anteriores. [cite: 227]
    // Tener ambos a la vez en el mismo atajo de teclado romperá el cambio,
    [cite_start]// ya que cambiará dos veces al presionar el atajo (una por xkb, otra por niri). [cite: 228]
    // Mod+Space       { switch-layout "next"; }
    [cite_start]// Mod+Shift+Space { switch-layout "prev"; [cite: 229]
    }

    Print { screenshot; }
    [cite_start]Ctrl+Print { screenshot-screen; [cite: 230]
    }
    Alt+Print { screenshot-window; }

    // Aplicaciones como clientes de escritorio remoto y conmutadores KVM de software pueden
    // solicitar que niri deje de procesar los atajos de teclado definidos aquí
    [cite_start]// para que puedan, por ejemplo, reenviar las pulsaciones de teclas tal cual a una máquina remota. [cite: 231]
    // Es una buena idea vincular una "vía de escape" para alternar el inhibidor,
    [cite_start]// para que una aplicación con errores no pueda mantener tu sesión como rehén. [cite: 232]
    //
    // La propiedad allow-inhibiting=false se puede aplicar a otras vinculaciones también,
    [cite_start]// lo que garantiza que niri siempre las procese, incluso cuando un inhibidor está activo. [cite: 233]
    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    [cite_start]// La acción quit mostrará un cuadro de diálogo de confirmación para evitar salidas accidentales. [cite: 234]
    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    [cite_start]// Apaga los monitores. [cite: 235]
    // Para volver a encenderlos, realiza cualquier entrada como
    [cite_start]// mover el ratón o presionar cualquier otra tecla. [cite: 236]
    Mod+Shift+P { power-off-monitors; }
}
