--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local UIElement = require('ui.element').class
local wrap = require('ui.wrap_class')

local unicode = palRequire('unicode')
local term = palRequire('term')

local Progress = class(UIElement)

function Progress:init(super, value)
  super.init()
  self.value = value
end

local progressSym = {
  filled = unicode.char(0x2588),
  blank = unicode.char(0x2591)
}

function Progress:draw(gpu)
  local w = self.rect.w
  local left = math.floor(w * self.value)
  local right = w - left

  local str = progressSym.filled:rep(left) .. progressSym.blank:rep(right)
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, str)
end

function Progress:setValue(v)
  if self.value ~= v then
    self.value = v
    self:setNeedUpdate()
  end
end

return wrap(Progress)
