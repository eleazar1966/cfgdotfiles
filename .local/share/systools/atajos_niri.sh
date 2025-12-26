#!/bin/bash
# Buscar todos los atajos de teclado niri/config.kdl

grep -E "^\s*(Mod|Super|Alt|Shift|Ctrl|Print|XF86)" \
  $HOME/.config/niri/config.kdl |
  fuzzel --dmenu --prompt " Buscar :> " --match-mode=exact no-sort no-icons -l 30 -w 110
