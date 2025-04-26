--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local keyboard = palRequire('keyboard')
local unicode = palRequire('unicode')

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
  local maxWidth = 0
  for _, option in ipairs(self.options) do
    maxWidth = math.max(maxWidth, unicode.wlen(option))
  end

  local tableContents = self:makeTableContents()
  local tableCfg = {
    showBorders = false,
    columns = {
      n = 1,
      defaultWidth = maxWidth
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

  self.preferredSize = { w = maxWidth + 2, h = #self.options + 2 }
end

function Select:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.enter then
    self:dismiss(self.main.selectedRow)
  else
    Window.on_key_down(self, device, key, keycode)
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