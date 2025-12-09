// Este archivo de configuración está en formato KDL: https://kdl.dev
// "/-" comenta el nodo siguiente.
// Consulta la wiki para una descripción completa de la configuración:
// https://yalter.github.io/niri/Configuration:-Introduction

// Configuración del dispositivo de entrada.
// Encuentra la lista completa de opciones en la wiki:
// https://yalter.github.io/niri/Configuration:-Input
input {
    keyboard {
        xkb {
            // Puedes establecer rules, model, layout, variant y options.
            // Para más información, consulta xkeyboard-config(7).

            // Por ejemplo:
            // layout "us,ru"
            // options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"

            // Si esta sección está vacía, niri obtendrá la configuración de xkb
            // de org.freedesktop.locale1.
            // Puedes controlarlos usando
            // localectl set-x11-keymap.
        }

        // Habilita numlock al inicio, omitir esta configuración lo deshabilita.
        numlock
    }

    // Las siguientes secciones incluyen la configuración de libinput.
    // Omitir las configuraciones las deshabilita, o las deja en sus valores predeterminados.
    // Todas las configuraciones comentadas aquí son ejemplos, no valores predeterminados.
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
        
        // scroll-method "two-finger"
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
     
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // scroll-button-lock
        // middle-emulation
    }

    // Descomenta esto para hacer que el ratón se mueva al centro de las ventanas recién enfocadas.
    // warp-mouse-to-focus

    // Enfoca ventanas y salidas automáticamente al mover el ratón hacia ellas.
    // Establecer max-scroll-amount="0%" hace que funcione solo en ventanas que ya están completamente en pantalla.
    // focus-follows-mouse max-scroll-amount="0%"
}

// Puedes configurar las salidas por su nombre, el cual puedes encontrar
// ejecutando `niri msg outputs` dentro de una instancia de niri.
// El monitor de portátil incorporado se llama usualmente "eDP-1".
// Encuentra más información en la wiki:
// https://yalter.github.io/niri/Configuration:-Outputs
// ¡Recuerda descomentar el nodo quitando "/-"!
/-output "eDP-1" {
    // Descomenta esta línea para deshabilitar esta salida.
    // off

    // Resolución y, opcionalmente, frecuencia de actualización de la salida.
    // El formato es "<ancho>x<alto>" o "<ancho>x<alto>@<frecuencia de actualización>".
    // Si se omite la frecuencia de actualización, niri elegirá la frecuencia de actualización más alta
    // para la resolución.
    // Si el modo se omite por completo o no es válido, niri elegirá uno automáticamente.
    // Ejecuta `niri msg outputs` dentro de una instancia de niri para listar todas las salidas y sus modos.
    mode "1920x1080@120.030"

    // Puedes usar escala entera o fraccionaria, por ejemplo, usa 1.5 para una escala del 150%.
    scale 2

    // Transform permite rotar la salida en sentido antihorario, los valores válidos son:
    // normal, 90, 180, 270, flipped, flipped-90, flipped-180 y flipped-270.
    transform "normal"

    // Posición de la salida en el espacio de coordenadas globales.
    // Esto afecta a las acciones direccionales del monitor como "focus-monitor-left" y al movimiento del cursor.
    // El cursor solo puede moverse entre salidas directamente adyacentes.
    // La escala y rotación de la salida deben tenerse en cuenta para el posicionamiento:
    // las salidas se dimensionan en píxeles lógicos, o escalados.
    // Por ejemplo, una salida de 3840×2160 con escala 2.0 tendrá un tamaño lógico de 1920×1080,
    // por lo que para colocar otra salida directamente adyacente a su derecha, establece su x en 1920.
    // Si la posición no está establecida o resulta en una superposición, la salida se coloca en su lugar
    // automáticamente.
    position x=1280 y=0
}

// Configuraciones que influyen en cómo se posicionan y dimensionan las ventanas.
// Encuentra más información en la wiki:
// https://yalter.github.io/niri/Configuration:-Layout
layout {
    // Establece los espacios alrededor de las ventanas en píxeles lógicos.
    gaps 16

    // Cuándo centrar una columna al cambiar el foco, las opciones son:
    // - "never", comportamiento predeterminado, enfocar una columna fuera de la pantalla se mantendrá en el borde
    //   izquierdo o derecho de la pantalla.
    // - "always", la columna enfocada siempre se centrará.
    // - "on-overflow", enfocar una columna la centrará si no cabe
    //   junto con la columna enfocada anteriormente.
    center-focused-column "never"

    // Puedes personalizar los anchos entre los que conmuta "switch-preset-column-width" (Mod+R).
    preset-column-widths {
        // Proportion establece el ancho como una fracción del ancho de la salida, teniendo en cuenta los espacios.
        // Por ejemplo, puedes encajar perfectamente cuatro ventanas de tamaño "proportion 0.25" en una salida.
        // Los anchos preestablecidos por defecto son 1/3, 1/2 y 2/3 de la salida.
        proportion 0.33333
        proportion 0.5
        proportion 0.66667

        // Fixed establece el ancho exactamente en píxeles lógicos.
        // fixed 1920
    }

    // También puedes personalizar las alturas entre las que conmuta "switch-preset-window-height" (Mod+Shift+R).
    // preset-window-heights { }

    // Puedes cambiar el ancho predeterminado de las nuevas ventanas.
    default-column-width { proportion 0.5; }
    // Si dejas los corchetes vacíos, las propias ventanas decidirán su ancho inicial.
    // default-column-width {}

    // Por defecto, el anillo de foco y el borde se renderizan como un rectángulo de fondo sólido
    // detrás de las ventanas.
    // Es decir, se mostrarán a través de ventanas semitransparentes.
    // Esto se debe a que las ventanas que usan decoraciones del lado del cliente pueden tener una forma arbitraria.
    //
    // Si no te gusta eso, deberías descomentar `prefer-no-csd` a continuación.
    // Niri dibujará el anillo de foco y el borde *alrededor* de las ventanas que acepten omitir sus
    // decoraciones del lado del cliente.
    //
    // Alternativamente, puedes anularlo con una regla de ventana llamada
    // `draw-border-with-background`.
    // Puedes cambiar el aspecto del anillo de foco.
    focus-ring {
        // Descomenta esta línea para deshabilitar el anillo de foco.
        // off

        // Cuántos píxeles lógicos se extiende el anillo desde las ventanas.
        width 4

        // Los colores se pueden establecer de varias maneras:
        // - Nombres de colores CSS: "red"
        // - Hexadecimal RGB: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
        // - Notación tipo CSS: "rgb(255, 127, 0)", rgba(), hsl() y algunas otras.
        // Color del anillo en el monitor activo.
        active-color "#7fc8ff"

        // Color del anillo en monitores inactivos.
        //
        // El anillo de foco solo se dibuja alrededor de la ventana activa, por lo que el único lugar
        // donde puedes ver su inactive-color es en otros monitores.
        inactive-color "#505050"

        // También puedes usar gradientes.
        // Toman precedencia sobre los colores sólidos.
        // Los gradientes se renderizan igual que CSS linear-gradient(angle, from, to).
        // El ángulo es el mismo que en linear-gradient, y es opcional,
        // por defecto es 180 (gradiente de arriba a abajo).
        // Puedes usar cualquier herramienta de CSS linear-gradient en la web para configurarlos.
        // También se admite cambiar el espacio de color, consulta la wiki para más información.
        //
        // active-gradient from="#80c8ff" to="#c7ff7f" angle=45

        // También puedes colorear el gradiente en relación con toda la vista
        // del espacio de trabajo, en lugar de solo en relación con la ventana en sí.
        // Para hacer eso, establece relative-to="workspace-view".
        //
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    // También puedes añadir un borde.
    // Es similar al anillo de foco, pero siempre visible.
    border {
        // Los ajustes son los mismos que para el anillo de foco.
        // Si habilitas el borde, probablemente querrás deshabilitar el anillo de foco.
        off

        width 4
        active-color "#ffc87f"
        inactive-color "#505050"

        // Color del borde alrededor de las ventanas que solicitan tu atención.
        urgent-color "#9b0000"

        // Los gradientes pueden usar diferentes espacios de color de interpolación.
        // Por ejemplo, este es un gradiente de arco iris pastel a través de in="oklch longer hue".
        //
        // active-gradient from="#e5989b" to="#ffb4a2" angle=45 relative-to="workspace-view" in="oklch longer hue"

        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    // Puedes habilitar las sombras paralelas (drop shadows) para las ventanas.
    shadow {
        // Descomenta la siguiente línea para habilitar las sombras.
        // on

        // Por defecto, la sombra se dibuja solo alrededor de su ventana, y no detrás de ella.
        // Descomenta esta configuración para hacer que la sombra se dibuje detrás de su ventana.
        //
        // Ten en cuenta que niri no tiene forma de saber sobre el radio de la esquina de la ventana CSD.
        // Tiene que asumir que las ventanas tienen esquinas cuadradas, lo que lleva a
        // artefactos de sombra dentro de las esquinas redondeadas de CSD.
        // Esta configuración soluciona
        // esos artefactos.
        //
        // Sin embargo, en su lugar, es posible que desees establecer prefer-no-csd y/o
        // geometry-corner-radius.
        // Entonces, niri sabrá el radio de la esquina y
        // dibujará la sombra correctamente, sin tener que dibujarla detrás de la
        // ventana.
        // Estos también eliminarán las sombras del lado del cliente si la ventana
        // dibuja alguna.
        //
        // draw-behind-window true

        // Puedes cambiar el aspecto de las sombras.
        // Los valores a continuación están en píxeles lógicos
        // y coinciden con las propiedades CSS box-shadow.
        // Softness controla el radio de desenfoque de la sombra.
        softness 30

        // Spread expande la sombra.
        spread 5

        // Offset mueve la sombra en relación con la ventana.
        offset x=0 y=5

        // También puedes cambiar el color y la opacidad de la sombra.
        color "#0007"
    }

    // Struts encogen el área ocupada por las ventanas, de manera similar a los paneles layer-shell.
    // Puedes pensar en ellos como una especie de espacios exteriores. Se establecen en píxeles lógicos.
    // Los struts izquierdo y derecho harán que la siguiente ventana al lado sea siempre visible.
    // Los struts superior e inferior simplemente agregarán espacios exteriores además del área ocupada por
    // los paneles layer-shell y los espacios regulares.
    struts {
        // left 64
        // right 64
        // top 64
        // bottom 64
    }
}

// Agrega líneas como esta para iniciar procesos al inicio.
// Ten en cuenta que ejecutar niri como una sesión es compatible con xdg-desktop-autostart,
// lo que puede ser más conveniente de usar.
// Consulta la sección binds a continuación para ver más ejemplos de spawn.
// Esta línea inicia waybar, una barra comúnmente utilizada para compositores Wayland.
spawn-at-startup "waybar"

// Para ejecutar un comando de shell (con variables, tuberías, etc.), usa spawn-sh-at-startup:
// spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"

hotkey-overlay {
    // Descomenta esta línea para deshabilitar la ventana emergente "Teclas Importantes" al inicio.
    // skip-at-startup
}

// Descomenta esta línea para pedir a los clientes que omitan sus decoraciones del lado del cliente si es posible.
// Si el cliente solicita específicamente CSD, la solicitud será respetada.
// Además, se informará a los clientes que están en mosaico, eliminando algunas esquinas redondeadas del lado del cliente.
// Esta opción también solucionará el dibujo del borde/anillo de foco detrás de algunas ventanas semitransparentes.
// Después de habilitar o deshabilitar esto, debes reiniciar las aplicaciones para que tenga efecto.
// prefer-no-csd

// Puedes cambiar la ruta donde se guardan las capturas de pantalla.
// Una ~ al principio se expandirá al directorio de inicio.
// La ruta se formatea con strftime(3) para darte la fecha y hora de la captura de pantalla.
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

// También puedes establecer esto en null para deshabilitar el guardado de capturas de pantalla en el disco.
// screenshot-path null

// Configuraciones de animación.
// La wiki explica cómo configurar animaciones individuales:
// https://yalter.github.io/niri/Configuration:-Animations
animations {
    // Descomentar para desactivar todas las animaciones.
    // off

    // Ralentiza todas las animaciones por este factor. Los valores por debajo de 1 las aceleran.
    // slowdown 3.0
}

// Las reglas de ventana te permiten ajustar el comportamiento de ventanas individuales.
// Encuentra más información en la wiki:
// https://yalter.github.io/niri/Configuration:-Window-Rules

// Solución para el error de configuración inicial de WezTerm
// estableciendo un default-column-width vacío.
window-rule {
    // Esta expresión regular está intencionalmente hecha lo más específica posible,
    // ya que esta es la configuración predeterminada, y no queremos falsos positivos.
    // Puedes conformarte con solo app-id="wezterm" si lo deseas.
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}

// Abre el reproductor picture-in-picture de Firefox como flotante por defecto.
window-rule {
    // Esta expresión regular de app-id funcionará para ambos:
    // - Firefox de host (app-id es "firefox")
    // - Firefox Flatpak (app-id es "org.mozilla.firefox")
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

// Ejemplo: bloquea dos gestores de contraseñas de la captura de pantalla.
// (Esta regla de ejemplo está comentada con un "/-" delante.)
/-window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#

    block-out-from "screen-capture"

    // Usa esto en su lugar si quieres que sean visibles en herramientas de captura de pantalla de terceros.
    // block-out-from "screencast"
}

// Ejemplo: habilita esquinas redondeadas para todas las ventanas.
// (Esta regla de ejemplo está comentada con un "/-" delante.)
/-window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}

binds {
    // Las teclas consisten en modificadores separados por signos +, seguidos de un nombre de tecla XKB
    // al final.
    // Para encontrar un nombre XKB para una tecla en particular, puedes usar un programa
    // como wev.
    //
    // "Mod" es un modificador especial igual a Super cuando se ejecuta en un TTY, y a Alt
    // cuando se ejecuta como una ventana winit.
    //
    // La mayoría de las acciones que puedes vincular aquí también se pueden invocar programáticamente con
    // `niri msg action do-something`.
    // Mod-Shift-/, que es usualmente lo mismo que Mod-?,
    // muestra una lista de atajos de teclado importantes.
    Mod+Shift+Slash { show-hotkey-overlay; }

    // Vinculaciones sugeridas para ejecutar programas: terminal, lanzador de aplicaciones, bloqueador de pantalla.
    Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }
    Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel";
    }
    Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock";
    }

    // Usa spawn-sh para ejecutar un comando de shell.
    // Haz esto si necesitas tuberías, múltiples comandos, etc.
    // Nota: el comando completo va como un solo argumento.
    // Se pasa textualmente a `sh -c`.
    // Por ejemplo, este es un enlace estándar para alternar el lector de pantalla (orca).
    Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca";
    }

    // Ejemplo de mapeos de teclas de volumen para PipeWire & WirePlumber.
    // La propiedad allow-when-locked=true hace que funcionen incluso cuando la sesión está bloqueada.
    // Usar spawn-sh permite pasar múltiples argumentos junto con el comando.
    // "-l 1.0" limita el volumen al 100%.
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
    }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
    }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    }
    XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    }

    // Ejemplo de mapeo de teclas multimedia usando playerctl.
    // Esto funcionará con cualquier reproductor multimedia habilitado para MPRIS.
    XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause";
    }
    XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop";
    }
    XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous";
    }
    XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next";
    }

    // Ejemplo de mapeo de teclas de brillo para brightnessctl.
