--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local keyboard = palRequire('keyboard')

local class = require('core.class')

local Window = require('ui.window')
local Frame = require('ui.frame')
local Column = require('ui.column')
local Row = require('ui.row')
local Button = require('ui.button')
local Label = require('ui.label')

local Alert = class(Window)

Alert.Ok = 0
Alert.Cancel = 1

function Alert:init(super, title, message, buttons)
  super.init()
  self.title = title or _T('alert_title')
  self.message = message or _T('alert_message')
  self.buttons = buttons or 0
end

function Alert:onLoad()
  local buttons = Row()

  if self.buttons & Alert.Ok == Alert.Ok then
    buttons:addSubview(Button(_T('alert_ok')))
  end
  if self.buttons & Alert.Cancel == Alert.Cancel then
    buttons:addSubview(Button(_T('alert_cancel')))
  end

  self.ui = Frame(self.title, Column({
    Label(self.message),
    buttons
  }))

  -- TODO: auto size
  self.ui.rect = { x = 10, y = 10, w = 50, h = 7 }
  self.ui:layout()
end

function Alert:on_key_up(device, key, keycode)
  if keycode == keyboard.keys.enter then
    -- TODO: ret value
    self:dismiss(Alert.Ok)
  end
end

return Alert