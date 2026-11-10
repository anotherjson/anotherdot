-- Solarized Osaka palette, mirrored 1:1 from solarized_osaka.conf (hyprlock and the hyprtoolkit
-- apps read the hyprlang copy). Bare hex; rgb()/rgba() build Hyprland colour strings.
local hex = {
  base000 = "9EACAD", base001 = "ADB8B8", base002 = "EEE8D5", base003 = "FDF6E3", base004 = "FFFFFF",
  base00x = "657B83", base01x = "586E75", base02x = "073642", base03x = "002B36", base04x = "00141A",

  green100   = "D6FFAC", green300   = "BAFB00", green500   = "859900", green700   = "596600", green900   = "2C3300",
  cyan100    = "B9FFFA", cyan300    = "29EEDF", cyan500    = "2AA198", cyan700    = "1A6265", cyan900    = "103B3D",
  blue100    = "AADCFF", blue300    = "49AEF5", blue500    = "268BD2", blue700    = "1B6497", blue900    = "103956",
  violet100  = "CCCFFF", violet300  = "9CA0ED", violet500  = "6C71C4", violet700  = "494FB6", violet900  = "25285B",
  magenta100 = "FF77B9", magenta300 = "F255A1", magenta500 = "D33682", magenta700 = "B02669", magenta900 = "541232",
  red100     = "FF9D9B", red300     = "F6524F", red500     = "DC322F", red700     = "B7211F", red900     = "57100F",
  orange100  = "FF9468", orange300  = "F8520E", orange500  = "CB4B16", orange700  = "A13C11", orange900  = "5C220A",
  yellow100  = "FFE999", yellow300  = "FFC100", yellow500  = "B58900", yellow700  = "664D00", yellow900  = "332700",
}

local M = { hex = hex }

local function lookup(name)
  return assert(hex[name], "theme: unknown colour " .. tostring(name))
end

function M.rgb(name)
  return ("rgb(%s)"):format(lookup(name))
end

-- alpha: two hex digits, e.g. rgba("base04x", "ee")
function M.rgba(name, alpha)
  return ("rgba(%s%s)"):format(lookup(name), alpha)
end

return M
