#!/usr/bin/env python
import pyinotify
import os
import sys

# --- CONFIGURACIÓN ---
# Asegúrate de que esta ruta es correcta para tu LED de Scroll Lock
DEVICE_PATH = "/sys/class/leds/input3::scrolllock/brightness"
PID_FILE = "/tmp/scrolllock_toggle.pid"
# --- FIN CONFIGURACIÓN ---


# Clase que maneja los eventos de inotify
class LEDEventHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, event):
        """
        Se ejecuta cuando el kernel intenta escribir en el archivo (ej. al pulsar una tecla)
        y lo cierra.
        """
        try:
            # Forzar el LED a 1 (ENCENDIDO)
            with open(DEVICE_PATH, "w") as f:
                f.write("1")
            # Opcional: Esto ayuda a apagar el parpadeo inicial cuando se inicia el script
            # print(f"Evento detectado: LED forzado a 1 en {DEVICE_PATH}")
        except Exception as e:
            # print(f"Error al escribir en el LED: {e}")
            pass


def start_monitor():
    """Inicia el demonio de monitoreo."""
    try:
        # Asegúrate de que el archivo PID no exista antes de escribir el nuevo
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)

        # Guarda el PID del proceso de Python
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))

        # Configura el observador
        wm = pyinotify.WatchManager()
        # Monitorea eventos de escritura y cierre de escritura
        mask = pyinotify.IN_CLOSE_WRITE

        # Inicia el monitoreo del archivo
        handler = LEDEventHandler()
        notifier = pyinotify.Notifier(wm, handler)

        # Añade la ruta del dispositivo para monitorear
        wm.add_watch(DEVICE_PATH, mask, rec=False)

        # Forzar el encendido inicial del LED
        with open(DEVICE_PATH, "w") as f:
            f.write("1")

        print(f"Scroll Lock Forzado ENCENDIDO. Monitoreando: {DEVICE_PATH}")

        # Inicia el bucle principal de inotify
        notifier.loop()

    except pyinotify.NotifierError as err:
        print(f"Error de Notifier: {err}", file=sys.stderr)
    except FileNotFoundError:
        print(
            f"Error: Ruta del dispositivo no encontrada ({DEVICE_PATH}).",
            file=sys.stderr,
        )
    except Exception as e:
        print(f"Ha ocurrido un error inesperado: {e}", file=sys.stderr)

    finally:
        # Limpieza (si el script se detiene)
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)


if __name__ == "__main__":
    start_monitor()
