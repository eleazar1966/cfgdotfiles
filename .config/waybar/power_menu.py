#!/usr/bin/env python3
import os

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk

# Ruta del archivo de colores generado por Matugen
COLORS_CSS_PATH = os.path.expanduser("~/.config/waybar/colors.css")


def apply_style():
    """Carga los colores de Matugen y aplica el estilo CSS con alta prioridad."""
    screen = Gdk.Screen.get_default()
    provider = Gtk.CssProvider()

    colors_content = ""
    if os.path.exists(COLORS_CSS_PATH):
        with open(COLORS_CSS_PATH, "r") as f:
            colors_content = f.read()

    # CSS Estricto: Centrado, texto grande y colores de Matugen
    custom_style = f"""
    {colors_content}

    * {{
        box-shadow: none;
        text-shadow: none;
        font-family: "JetBrainsMono Nerd Font", "sans-serif";
    }}

    window {{
        background-color: @background;
        border: 2px solid @outline;
        border-radius: 16px;
    }}
    
    button {{
        background-image: none;
        background-color: @surface_container_high; 
        color: @on_surface;
        border: 1px solid @outline;
        border-radius: 12px;
        margin: 6px;
    }}

    button:hover {{
        background-color: @primary;
        color: @on_primary;
        border-color: @primary;
    }}

    .cancel-btn {{
        background-color: @error_container;
        color: @on_error_container;
        border: 1px solid @error;
    }}

    .cancel-btn:hover {{
        background-color: @error;
        color: @on_error;
    }}
    """

    try:
        provider.load_from_data(custom_style.encode())
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        )
    except Exception as e:
        print(f"Error cargando CSS: {e}")


class PowerMenuWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Power Menu")
        self.set_border_width(20)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        apply_style()
        self.connect("key-press-event", self.on_key_press)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        # Acciones con texto e iconos más grandes y centrados
        # Icono: xx-large, Texto: x-large
        actions = [
            (
                "<span size='xx-large'></span>\n<span size='x-large' weight='bold'>Apagar</span>",
                "sudo poweroff",
            ),
            (
                "<span size='xx-large'>󰑐</span>\n<span size='x-large' weight='bold'>Reiniciar</span>",
                "sudo reboot",
            ),
            (
                "<span size='xx-large'>󰍃</span>\n<span size='x-large' weight='bold'>Sesión</span>",
                "niri msg action quit",
            ),
        ]

        for label_markup, command in actions:
            btn = Gtk.Button()
            label = Gtk.Label()
            label.set_markup(label_markup)
            label.set_justify(Gtk.Justification.CENTER)
            label.set_xalign(0.5)
            btn.add(label)

            btn.set_size_request(280, 100)
            btn.connect("clicked", self.execute_action, command)
            vbox.pack_start(btn, False, False, 0)

        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        vbox.pack_start(separator, False, False, 8)

        # Botón Cancelar
        btn_cancel = Gtk.Button()
        label_cancel = Gtk.Label()
        label_cancel.set_markup("<span size='x-large' weight='bold'>󰜺 Cancelar</span>")
        label_cancel.set_xalign(0.5)
        btn_cancel.add(label_cancel)

        btn_cancel.set_size_request(280, 70)
        btn_cancel.get_style_context().add_class("cancel-btn")
        btn_cancel.connect("clicked", lambda x: Gtk.main_quit())
        vbox.pack_start(btn_cancel, False, False, 0)

        self.add(vbox)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

    def execute_action(self, button, command):
        os.system(command)
        Gtk.main_quit()


if __name__ == "__main__":
    win = PowerMenuWindow()
    Gtk.main()
