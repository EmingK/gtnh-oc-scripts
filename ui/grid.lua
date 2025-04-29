--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local Container = require('ui.container').class

local Grid = class(Container)

function Grid:layout()
  if #self.children == 0 then return end
  local child1 = self.children[1]

  local w = self.rect.w
  local h = self.rect.h
  local cw = child1.intrinsicSize.w
  local ch = child1.intrinsicSize.h

  local nr = 1
  local nc = 1

  if cw == nil and ch == nil then
    error("Grid element must have at least 1 intrinsic size")
  end

  if cw == nil then
    while math.ceil(#self.children / nc) * ch > h do nc = nc + 1 end
    cw = w // nc
  end

  if ch == nil then
    while math.ceil(#self.children / nr) * cw > w do nr = nr + 1 end
    ch = h // nr
  end

  nc = w // cw
  nr = math.ceil(#self.children / nc)

  for i, child in ipairs(self.children) do
    local x = (i - 1) % nc
    local y = (i - 1) // nc

    child.rect.x = self.rect.x + x * cw
    child.rect.y = self.rect.y + y * ch
    child.rect.w = cw
    child.rect.h = ch

    if child.children then
      child:layout()
    end
  end
end

return wrap(Grid)
