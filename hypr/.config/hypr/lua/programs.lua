-- Every external program the config launches, by role. Swap a tool here, not in binds/autostart.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts = config_home .. "/hypr/scripts"

return {
  terminal   = scripts .. "/kitty-cwd.sh", -- kitty in the focused window's cwd; plain kitty otherwise
  files      = "nautilus",
  menu       = "wofi --show drun",
  screenshot = "hyprshot",
  lock       = "hyprlock",
  power_menu = scripts .. "/power-menu.sh",
  bar        = "waybar",
  bar_reload = "pkill -SIGUSR2 waybar", -- reloads in place
  notify     = "swaync-client",

  -- autostart daemons
  idle = "systemd-cat -t hypridle hypridle", -- journald; Hyprland otherwise sends child stdio to /dev/null
  -- hyprpaper 0.8+ fails fast on wl_display_connect if the socket isn't ready yet when autostart
  -- fires (seen on TTY1-autologin boots), so poll the socket instead of sleeping a fixed time.
  paper       = "bash -c 'until [ -S \"$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY\" ]; do sleep 0.1; done; hyprpaper'",
  automount   = "udiskie",
  -- --service-mode only re-applies the LAST-loaded EasyEffects preset; load wave3-voice once by
  -- hand on a fresh box (easyeffects/README.md), after which this keeps it active across reboots.
  mic_effects = "easyeffects --service-mode",
}
