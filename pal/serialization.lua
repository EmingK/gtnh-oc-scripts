--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local function serialize(value)
  local vtype = type(value)

  if vtype == 'string' then
    return string.format("%q", value)
  elseif vtype == 'table' then
    local res = '{'
    for k, v in pairs(value) do
      res = res .. string.format("[%q]=%s,", k, serialize(v))
    end
    return res .. '}'
  else
    return tostring(value)
  end
end

local function unserialize(value)
  return load('return '..value)()
end

return {
  serialize = serialize,
  unserialize = unserialize,
}
