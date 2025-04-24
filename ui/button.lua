--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local uiUtils = require('ui.utils')
local UIElement = require('ui.element').class

local term = palRequire('term')

local Button = class(UIElement)

function Button:init(super, text)
  super.init()
  self.selectable = true
  self.text = text
  self.active = false
end

function Button:draw(gpu)
  if self.selected then
    uiUtils.setHighlight(gpu)
  end

  self:clear(gpu)
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, self.text)

  if self.selected then
    uiUtils.setNormal(gpu)
  end
end

function Button:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

return wrap(Button)
