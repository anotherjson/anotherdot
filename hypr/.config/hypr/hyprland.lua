-- Entry point. Loads the config tiers, then the machine-local monitor file.
-- Everything else lives under lua/ (layout and troubleshooting: guides/host-config.md).
--
-- Broken desktop? From a TTY:  HYPR_TIERS=core start-hyprland   (skips lua/extras/)
local tiers = os.getenv("HYPR_TIERS") or "core,extras"

for tier in tiers:gmatch("[^,]+") do
  require("./lua/" .. tier .. "/*") -- wildcards need the path form; "lua.core.*" does not resolve
end

-- Monitors are machine-local and untracked: ~/.config/hypr/monitors.lua, seeded from
-- hosts/hypr/monitors.lua.template by `just host-init`. Loaded by absolute path because a
-- relative require resolves from this file's real (stow) location, not from ~/.config/hypr.
-- No file → Hyprland's defaults (preferred / auto / auto). A broken file is still reported.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local monitors = io.open(config_home .. "/hypr/monitors.lua", "r")
if monitors then
  monitors:close()
  require(config_home .. "/hypr/monitors")
end
