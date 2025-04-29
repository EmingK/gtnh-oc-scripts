--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local meta = {
  __call = function(class, ...)
    return class.class:new(...)
  end
}

local function wrapUiClass(class)
  local o = {
    class = class
  }
  setmetatable(o, meta)
  return o
end

return wrapUiClass
