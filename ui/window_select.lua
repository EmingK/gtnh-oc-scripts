--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local keyboard = palRequire('keyboard')

local class = require('core.class')

local Window = require('ui.window')
local Frame = require('ui.frame')
local Table = require('ui.table')

local Select = class(Window)

function Select:init(super, title, options)
  super.init()
  self.title = title or _T('alert_title')
  self.options = options
end

function Select:onLoad()
  local tableContents = self:makeTableContents()
  local tableCfg = {
    showBorders = false,
    columns = {
      n = 1,
      defaultWidth = 20
    },
    rows = {
      n = #self.options
    }
  }

  local main = Table(tableContents, tableCfg)
  self.main = main

  self.ui = Frame(
    self.title,
    main
  )

  -- TODO: auto size
  self.ui.rect = { x = 10, y = 10, w = 50, h = 7 }
  self.ui:layout()
end

function Select:on_key_up(device, key, keycode)
  if keycode == keyboard.keys.enter then
    -- TODO: ret value
    self:dismiss(self.main.selectedRow)
  else
    Window.on_key_up(self, device, key, keycode)
  end
end

function Select:makeTableContents()
  local tableContents = {}
  for _, option in ipairs(self.options) do
    table.insert(tableContents, {
      { display = option }
    })
  end
  return tableContents
end

return Select