--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local Element = require('ui.element').class

local unicode = palRequire('unicode')

local HSeparator = class(Element)

function HSeparator:init(super)
  super.init()
  self.intrinsicSize.h = 1
end

function HSeparator:draw(gpu)
  local sx, sy = self:screenPos(0, 0)
  gpu.fill(sx, sy, self.rect.w, 1, unicode.char(0x2500))
end

local VSeparator = class(Element)

function VSeparator:init(super)
  super.init()
  self.intrinsicSize.w = 1
end

function VSeparator:draw(gpu)
  local sx, sy = self:screenPos(0, 0)
  gpu.fill(sx, sy, 1, self.rect.h, unicode.char(0x2502))
end

return {
  horizontal = wrap(HSeparator),
  vertical = wrap(VSeparator),
}