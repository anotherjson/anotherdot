-- Small functional helpers shared by every module.
local M = {}

function M.range(from, to)
  local out = {}
  for i = from, to do out[#out + 1] = i end
  return out
end

function M.map(list, fn)
  local out = {}
  for i, v in ipairs(list) do out[i] = fn(v, i) end
  return out
end

function M.flat_map(list, fn)
  local out = {}
  for _, v in ipairs(list) do
    for _, w in ipairs(fn(v)) do out[#out + 1] = w end
  end
  return out
end

-- Concatenate lists: concat({a, b}, {c}) → {a, b, c}.
function M.concat(...)
  return M.flat_map({ ... }, function(list) return list end)
end

function M.each(list, fn)
  for i, v in ipairs(list) do fn(v, i) end
end

-- Dispatcher that runs a shell command; the bind-side counterpart of hl.exec_cmd.
function M.exec(cmd)
  return hl.dsp.exec_cmd(cmd)
end

-- Register binds given as { keys, dispatcher, opts? }. `prefix` ("SUPER") is prepended to every
-- chord; nil binds the bare key (media keys).
function M.bind_all(prefix, binds)
  local chord = prefix and function(k) return prefix .. " + " .. k end or function(k) return k end
  M.each(binds, function(b) hl.bind(chord(b[1]), b[2], b[3]) end)
end

-- Run each command once when Hyprland starts (the exec-once equivalent).
function M.start_all(cmds)
  hl.on("hyprland.start", function()
    M.each(cmds, function(cmd) hl.exec_cmd(cmd) end)
  end)
end

return M
