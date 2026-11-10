local t, u = require("lua.theme"), require("lua.util")

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 5,
    border_size = 2,
    col = {
      active_border   = { colors = { t.rgb("base001"), t.rgb("base01x") }, angle = 90 },
      inactive_border = t.rgb("base02x"),
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.8,
    shadow = { enabled = true, range = 4, render_power = 3, color = "rgba(1a1a1aee)" },
    blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  master = { new_status = "master" },
  misc = { force_default_wallpaper = -1, disable_hyprland_logo = false },
})

local function bezier(name, p1, p2)
  hl.curve(name, { type = "bezier", points = { p1, p2 } })
end
bezier("easeOutQuint",   { 0.23, 1 },    { 0.32, 1 })
bezier("easeInOutCubic", { 0.65, 0.05 }, { 0.36, 1 })
bezier("linear",         { 0, 0 },       { 1, 1 })
bezier("almostLinear",   { 0.5, 0.5 },   { 0.75, 1 })
bezier("quick",          { 0.15, 0 },    { 0.1, 1 })

-- { leaf, speed, curve, style? }
u.each({
  { "global",        10,   "default" },
  { "border",        5.39, "easeOutQuint" },
  { "windows",       4.79, "easeOutQuint" },
  { "windowsIn",     4.1,  "easeOutQuint", "popin 87%" },
  { "windowsOut",    1.49, "linear",       "popin 87%" },
  { "fadeIn",        1.73, "almostLinear" },
  { "fadeOut",       1.46, "almostLinear" },
  { "fade",          3.03, "quick" },
  { "layers",        3.81, "easeOutQuint" },
  { "layersIn",      4,    "easeOutQuint", "fade" },
  { "layersOut",     1.5,  "linear",       "fade" },
  { "fadeLayersIn",  1.79, "almostLinear" },
  { "fadeLayersOut", 1.39, "almostLinear" },
  { "workspaces",    1.94, "almostLinear", "fade" },
  { "workspacesIn",  1.21, "almostLinear", "fade" },
  { "workspacesOut", 1.94, "almostLinear", "fade" },
}, function(a)
  hl.animation({ leaf = a[1], enabled = true, speed = a[2], bezier = a[3], style = a[4] })
end)
