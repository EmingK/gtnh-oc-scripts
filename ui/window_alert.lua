--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

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
    buttons:addSubview(Button(_T('ok')):action('clickedOk'))
  end
  if self.buttons & Alert.Cancel == Alert.Cancel then
    buttons:addSubview(Button(_T('cancel')):action('clickedCancel'))
  end

  self.ui = Frame(self.title, Column({
    Label(self.message),
    buttons
  }))

  self.preferredSize = { w = 50, h = 7 }
end

function Alert:clickedOk()
  self:dismiss(Alert.Ok)
end

function Alert:clickedCancel()
  self:dismiss(Alert.Cancel)
end

return Alert