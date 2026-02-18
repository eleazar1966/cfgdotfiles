#!/usr/bin/env python3
import os

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk

COLORS_CSS_PATH = os.path.expanduser("~/.config/waybar/colors.css")


def apply_style():
    screen = Gdk.Screen.get_default()
    provider = Gtk.CssProvider()
    colors_content = ""
    if os.path.exists(COLORS_CSS_PATH):
        with open(COLORS_CSS_PATH, "r") as f:
            colors_content = f.read()

    custom_style = f"""
    {colors_content}
    * {{
        box-shadow: none;
        text-shadow: none;
        font-family: "JetBrainsMono Nerd Font", "sans-serif";
    }}
    #main-window {{
        background-color: @background;
        border: 2px solid @outline;
        border-radius: 12px;
    }}
    #inner-box {{
        /* Asegura que el contenido respete el radio de la ventana */
        border-radius: 10px; 
        background-color: transparent;
    }}
    button {{
        background-image: none;
        background-color: @surface_container_high; 
        color: @on_surface;
        border: 1px solid @outline;
        border-radius: 6px;
        margin: 2px;
        font-weight: bold;
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
    provider.load_from_data(custom_style.encode())
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )


class PowerMenuWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Power Menu")
        self.set_name("main-window")
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        # Importante para que las esquinas redondeadas no muestren esquinas negras
        self.get_style_context().add_class("popup")
        visual = self.get_screen().get_rgba_visual()
        if visual:
            self.set_visual(visual)

        apply_style()

        # Caja interna con ID para control de bordes
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        vbox.set_name("inner-box")
        vbox.set_margin_top(6)
        vbox.set_margin_bottom(6)
        vbox.set_margin_start(6)
        vbox.set_margin_end(6)

        actions = [
            ("  Apagar", "sudo poweroff"),
            ("󰑐  Reiniciar", "sudo reboot"),
            ("󰍃  Sesión", "niri msg action quit"),
        ]

        for text, command in actions:
            btn = Gtk.Button()
            label = Gtk.Label()
            label.set_markup(f"<span size='medium'>{text}</span>")
            btn.add(label)
            btn.set_size_request(160, 38)  # Botones más pequeños
            btn.connect("clicked", self.execute_action, command)
            vbox.pack_start(btn, False, False, 0)

        # Botón Cancelar
        btn_cancel = Gtk.Button()
        l_cancel = Gtk.Label()
        l_cancel.set_markup("<span size='medium'>󰜺 Cancelar</span>")
        btn_cancel.add(l_cancel)
        btn_cancel.set_size_request(160, 38)
        btn_cancel.get_style_context().add_class("cancel-btn")
        btn_cancel.connect("clicked", lambda x: Gtk.main_quit())
        vbox.pack_start(btn_cancel, False, False, 0)

        self.connect("key-press-event", self.on_key_press)
        self.connect("button-press-event", self.on_button_press)

        self.add(vbox)
        self.show_all()

        # Grab de asiento para capturar clics fuera en Niri/Wayland
        Gdk.Display.get_default().get_default_seat().grab(
            self.get_window(), Gdk.SeatCapabilities.ALL, True, None, None, None
        )

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

    def on_button_press(self, widget, event):
        alloc = self.get_allocation()
        if (
            event.x < 0
            or event.y < 0
            or event.x > alloc.width
            or event.y > alloc.height
        ):
            Gtk.main_quit()
            return True
        return False

    def execute_action(self, button, command):
        os.system(command)
        Gtk.main_quit()


if __name__ == "__main__":
    win = PowerMenuWindow()
    Gtk.main()
