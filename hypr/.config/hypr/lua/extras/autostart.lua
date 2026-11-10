-- Nice-to-haves: bar, wallpaper, automount, mic effects, GTK theme/font/cursor. Skipped by HYPR_TIERS=core.
local p, u = require("lua.programs"), require("lua.util")

u.start_all({
  p.bar,
  p.paper,
  p.automount,
  p.mic_effects,
  "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'",
  "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
  "gsettings set org.gnome.desktop.interface font-name 'FiraCode Nerd Font Mono 12'",
  "gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 12'",
  "gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'",
  "gsettings set org.gnome.desktop.interface cursor-size 24",
})
