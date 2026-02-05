--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local UIElement = require('ui.element').class
local utils = require('ui.utils')

local term = palRequire('term')
local text = palRequire('text')

local Label = class(UIElement)

function Label:init(super, text)
  super.init()
  self.text = text
end

function Label:draw(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end
  self:clear(gpu)

  local x, y = self:screenPos(0, 0)
  for line in text.wrappedLines(self.text, self.rect.w, self.rect.w) do
    gpu.set(x, y, line)
    y = y + 1
  end

  if self.selected then
    utils.setNormal(gpu)
  end
end

function Label:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

return wrap(Label)
