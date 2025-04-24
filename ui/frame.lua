--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local Container = require('ui.container').class

local unicode = palRequire('unicode')

local borders = {
  tl = unicode.char(0x2552),
  t = unicode.char(0x2550),
  tr = unicode.char(0x2555),
  l = unicode.char(0x2502),
  r = unicode.char(0x2502),
  bl = unicode.char(0x2514),
  b = unicode.char(0x2500),
  br = unicode.char(0x2518),
}


local Frame = class(Container)

function Frame:init(super, title)
  super.init()
  self.title = title
end

function Frame:draw(gpu)
  local w = self.rect.w
  local topCount = (w - 2 - unicode.wlen(self.title))
  local top = borders.tl .. self.title .. borders.t:rep(topCount) .. borders.tr

  local sx, sy = self:screenPos(0, 0)
  gpu.set(sx, sy, top)

  local h = self.rect.h
  for y = 1, h - 2, 1 do
    sx, sy = self:screenPos(0, y)
    gpu.set(sx, sy, borders.l)
    sx, sy = self:screenPos(w - 1, y)
    gpu.set(sx, sy, borders.r)
  end

  sx, sy = self:screenPos(0, h - 1)
  gpu.set(sx, sy, borders.bl .. borders.b:rep(w - 2) .. borders.br)

  local child = self.children[1]
  if child then
    child:draw(gpu)
  end
end

function Frame:layout()
  local child = self.children[1]
  if not child then return end
  child.rect.x = self.rect.x + 1
  child.rect.y = self.rect.y + 1
  child.rect.w = self.rect.w - 2
  child.rect.h = self.rect.h - 2

  if child.children then
    child:layout()
  end
end

return wrap(Frame)
