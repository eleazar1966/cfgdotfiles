#!/usr/bin/env python3
import os

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk

# Ruta absoluta al XML
XML_PATH = os.path.expanduser("~/.config/waybar/power_menu.xml")


class PowerMenuWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Power Menu")
        self.set_border_width(15)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)

        # Cerrar con Escape
        self.connect("key-press-event", self.on_key_press)

        builder = Gtk.Builder()
        builder.add_from_file(XML_PATH)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        # Mapeo de acciones (IDs del XML)
        actions = {
            "shutdown": "sudo poweroff",
            "reboot": "sudo reboot",
            "logout": "niri msg action quit",
        }

        # Añadir botones del XML
        for item_id, command in actions.items():
            menu_item = builder.get_object(item_id)
            if menu_item:
                btn = Gtk.Button(label=menu_item.get_label())
                btn.set_size_request(160, 45)
                btn.connect("clicked", self.execute_action, command)
                vbox.pack_start(btn, False, False, 0)

        # Añadir separador y botón Cancelar
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        vbox.pack_start(separator, False, False, 5)

        btn_cancel = Gtk.Button(label="Cancelar")
        btn_cancel.set_size_request(160, 45)
        btn_cancel.get_style_context().add_class(
            "suggested-action"
        )  # Opcional: resalta el botón
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
