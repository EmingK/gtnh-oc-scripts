--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local serialization = palRequire('serialization')
local computer = palRequire('computer')
local colors = palRequire('colors')

local function debugLog(...)
  local up = computer.uptime()
  local ts = string.format('[%f]', up)
  local args = table.pack(...)
  table.insert(args, '\r')
  print(ts, table.unpack(args))
end

local function loadSerializedObject(filename)
  local f = io.open(filename)
  if not f then return nil end
  local s = f:read('a')
  f:close()

  return serialization.unserialize(s)
end

local function saveSerializedObject(filename, value)
  local s = serialization.serialize(value)
  local f = io.open(filename, 'w')
  f:write(s)
  f:close()
end

local function bind(f, ...)
  local boundArgs = table.pack(...)
  return function(...)
    local args = table.pack(...)
    for i = 1, #args do
      table.insert(boundArgs, args[i])
    end
    f(table.unpack(boundArgs))
  end
end

local function copy(obj)
  if type(obj) ~= 'table' then
    return obj
  end
  local copied = {}
  for k, v in pairs(obj) do
    copied[k] = copy(v)
  end
  return copied
end

local sideNames = {
  'up', 'north', 'south', 'west', 'east', [0] = 'down'
}

local function sideDescription(side)
  return sideNames[side]
end

local function colorDescription(color)
  return colors[color]
end

return {
  loadSerializedObject = loadSerializedObject,
  saveSerializedObject = saveSerializedObject,
  sideDescription = sideDescription,
  colorDescription = colorDescription,
  bind = bind,
  copy = copy,
  debug = debugLog,
}
