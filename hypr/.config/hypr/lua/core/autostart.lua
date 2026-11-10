-- Daemons the desktop is unsafe or unusable without. Nice-to-haves live in extras/autostart.lua.
local p, u = require("lua.programs"), require("lua.util")

u.start_all({
  p.idle,
})
