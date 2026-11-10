-- Nice-to-haves: bar, wallpaper, automount, mic effects, GTK theme. Skipped by HYPR_TIERS=core.
local p, u = require("lua.programs"), require("lua.util")

u.start_all({
  p.bar,
  p.paper,
  p.automount,
  p.mic_effects,
  "gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'",
  "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'",
})
