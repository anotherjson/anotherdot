-- Entry point. Loads the config tiers, then the machine-local monitor file.
-- Everything else lives under lua/ (layout and troubleshooting: guides/host-config.md).
--
-- Broken desktop? From a TTY:  HYPR_TIERS=core start-hyprland   (skips lua/extras/)
local u = require("lua.util")

local default_tiers = "core,extras"
local requested = u.split(os.getenv("HYPR_TIERS"), ",")
local tiers = #requested > 0 and requested or u.split(default_tiers, ",") -- empty/unset → default

u.each(tiers, function(tier)
  require("./lua/" .. tier .. "/*") -- wildcards need the path form; "lua.core.*" does not resolve
end)

-- Monitors are machine-local and untracked: ~/.config/hypr/monitors.lua, seeded from
-- hosts/hypr/monitors.lua.template by `just host-init`. Loaded by absolute path because a
-- relative require resolves from this file's real (stow) location, not from ~/.config/hypr.
-- No file → Hyprland's defaults (preferred / auto / auto). A broken file is still reported.
local monitors_path = u.config_home() .. "/hypr/monitors"
local monitors = io.open(monitors_path .. ".lua", "r")
if monitors then
  monitors:close()
  require(monitors_path)
end
