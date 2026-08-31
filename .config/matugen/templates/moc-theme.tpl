#
# MOC theme generated from Material You colors (matugen).
#
# MOC's colordef only accepts the standard 8 terminal color names plus grey,
# and values in the 0..1000 range. We remap those 9 slots to the Material You
# roles pulled from matugen, so the theme follows the system palette.
#
# Slot mapping (MOC name -> Material You role):
#   black   -> surface            (main dark background)
#   grey    -> surface_dim        (secondary background / frame)
#   white   -> on_surface         (primary text)
#   cyan    -> primary            (accents, selection, title, bars)
#   blue    -> secondary
#   magenta -> tertiary
#   red     -> error
#   green   -> secondary_container (message background)
#   yellow  -> on_primary         (selection foreground)
#

colordef black   = {{colors.surface.default.red}} {{colors.surface.default.green}} {{colors.surface.default.blue}}
colordef grey    = {{colors.surface_dim.default.red}} {{colors.surface_dim.default.green}} {{colors.surface_dim.default.blue}}
colordef white   = {{colors.on_surface.default.red}} {{colors.on_surface.default.green}} {{colors.on_surface.default.blue}}
colordef cyan    = {{colors.primary.default.red}} {{colors.primary.default.green}} {{colors.primary.default.blue}}
colordef blue    = {{colors.secondary.default.red}} {{colors.secondary.default.green}} {{colors.secondary.default.blue}}
colordef magenta = {{colors.tertiary.default.red}} {{colors.tertiary.default.green}} {{colors.tertiary.default.blue}}
colordef red     = {{colors.error.default.red}} {{colors.error.default.green}} {{colors.error.default.blue}}
colordef green   = {{colors.secondary_container.default.red}} {{colors.secondary_container.default.green}} {{colors.secondary_container.default.blue}}
colordef yellow  = {{colors.on_primary.default.red}} {{colors.on_primary.default.green}} {{colors.on_primary.default.blue}}

background		= white	black
frame			= grey	black
window_title		= cyan	black	bold
directory		= white	black
selected_directory	= black	cyan	bold
playlist		= white	black
selected_playlist	= black	cyan	bold
file			= white	black
selected_file		= black	cyan
marked_file		= cyan	black	bold
marked_selected_file	= black	cyan	bold
info			= white	black
selected_info		= black	cyan	bold
marked_info		= cyan	black	bold
marked_selected_info	= black	cyan	bold
status			= white	black	bold
title			= cyan	black	bold
state			= cyan	black	bold
current_time		= white	black	bold
time_left		= white	black
total_time		= white	black
time_total_frames	= white	black
sound_parameters	= white	black
legend			= white	black
disabled		= white	black
enabled			= black	cyan	bold
empty_mixer_bar		= white	grey
filled_mixer_bar	= black	cyan
empty_time_bar		= white	grey
filled_time_bar		= black	cyan
entry			= white	black
entry_title		= cyan	black	bold
error			= red	black	bold
message			= black	green	bold
plist_time		= white	black
