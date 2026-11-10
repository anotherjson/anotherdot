-- Every bind lives here, including the ones aimed at extras daemons (they no-op when the daemon
-- is off), so the desktop stays fully drivable in core-only mode.
local p, u = require("lua.programs"), require("lua.util")
local exec = u.exec

local function focus_binds()
  return u.map({ { "H", "left" }, { "J", "down" }, { "K", "up" }, { "L", "right" } }, function(pair)
    return { pair[1], hl.dsp.focus({ direction = pair[2] }) }
  end)
end

-- Super+N switches to workspace N, Super+Shift+N moves the window there; 10 lives on key 0.
local function workspace_binds()
  return u.flat_map(u.range(1, 10), function(i)
    local key = tostring(i % 10)
    return {
      { key,               hl.dsp.focus({ workspace = i }) },
      { "SHIFT + " .. key, hl.dsp.window.move({ workspace = i }) },
    }
  end)
end

u.bind_all("SUPER", u.concat({
  { "T",                   exec(p.terminal) },
  { "Q",                   hl.dsp.window.close() },
  { "SHIFT + Q",           exec(p.lock) },
  { "SHIFT + CONTROL + M", hl.dsp.exit() },
  { "F",                   exec(p.files) },
  { "space",               exec(p.menu) },
  { "apostrophe",          hl.dsp.window.float({ action = "toggle" }) },
  { "P",                   hl.dsp.window.pseudo() },       -- dwindle
  { "O",                   hl.dsp.layout("togglesplit") }, -- dwindle; Super+S is the scratchpad
  { "W",                   exec(p.screenshot .. " -m window") },
  { "M",                   exec(p.screenshot .. " -m output") },
  { "R",                   exec(p.screenshot .. " -m region") },
  { "B",                   exec(p.bar_reload) },
  { "SHIFT + E",           exec(p.power_menu) },
  { "N",                   exec(p.notify .. " -t -sw") },
  { "SHIFT + N",           exec(p.notify .. " -d -sw") },
  { "CTRL + N",            exec(p.notify .. " -C") },
  { "S",                   hl.dsp.workspace.toggle_special("magic") },
  { "SHIFT + S",           hl.dsp.window.move({ workspace = "special:magic" }) },
  { "mouse_down",          hl.dsp.focus({ workspace = "e+1" }) },
  { "mouse_up",            hl.dsp.focus({ workspace = "e-1" }) },
  { "mouse:272",           hl.dsp.window.drag(),   { mouse = true } },
  { "mouse:273",           hl.dsp.window.resize(), { mouse = true } },
}, focus_binds(), workspace_binds()))

-- Media keys work on the lock screen; the volume/brightness ones repeat while held.
local held, locked = { locked = true, repeating = true }, { locked = true }
u.bind_all(nil, {
  { "XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held },
  { "XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held },
  { "XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     held },
  { "XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   held },
  { "XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  held }, -- laptop keys;
  { "XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  held }, -- absent on a desktop
  { "XF86AudioNext",         exec("playerctl next"),                                 locked },
  { "XF86AudioPause",        exec("playerctl play-pause"),                           locked },
  { "XF86AudioPlay",         exec("playerctl play-pause"),                           locked },
  { "XF86AudioPrev",         exec("playerctl previous"),                             locked },
})
