--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')

local Window = require('ui.window')
local Frame = require('ui.frame')
local Column = require('ui.column')
local Label = require('ui.label')
local Input = require('ui.input')

local InputWindow = class(Window)

function InputWindow:init(super, title, message, text)
  super.init()
  self.title = title or _T('input_title')
  self.message = message or _T('input_message')
  self.text = text or ''
end

function InputWindow:onLoad()
  self.input = Input(self.text)
  self.ui = Frame(self.title, Column({
    Label(self.message),
    self.input,
  }))

  self.preferredSize = { w = 60, h = 4 }
end

function InputWindow:update(gpu)
  Window.update(self, gpu)
  local result = self.input:editText(gpu)
  self:dismiss(result)
end

return InputWindow