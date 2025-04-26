--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local UIElement = require('ui.element').class
local utils = require('ui.utils')

local term = palRequire('term')

local Input = class(UIElement)

function Input:init(super, text)
  super.init()
  self.text = text
end

function Input:draw(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end
  self:clear(gpu)
  -- TODO: support line wrapping
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, self.text)

  if self.selected then
    utils.setNormal(gpu)
  end
end

function Input:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

function Input:editText(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end

  local x, y = self:screenPos(0, 0)
  term.setCursor(x, y)
  term.setCursorBlink(true)
  local res = term.read():gsub('\n', '')
  term.setCursorBlink(false)
  if self.selected then
    utils.setNormal(gpu)
  end

  return res
end

return wrap(Input)
