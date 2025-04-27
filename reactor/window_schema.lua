--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local utils = require('core.utils')

local Window = require('ui.window')
local Column = require('ui.column')
local Row = require('ui.row')
local Frame = require('ui.frame')
local Button = require('ui.button')
local Table = require('ui.table')
local Separator = require('ui.separator')
local Select = require('ui.window_select')
local InputWindow = require('ui.window_input')
require('reactor.window+select_component')

local function makeDefaultConfig()
  return {
    name = 'new_config',
    size = { w = 9, h = 6 },
    count = 54,
    layout = {}
  }
end

local SchemaWindow = class(Window)

function SchemaWindow:init(super, config)
  super.init()
  self.config = utils.copy(config) or makeDefaultConfig()

  self.tblCfgOptions = {
    showBorders = false,
    columns = {
      n = 2,
      defaultWidth = 8,
      [2] = {
        width = 10,
      }
    },
    rows = {
      n = 2
    }
  }
  self.tblLayoutOptions = {
    showBorders = true,
    columns = {
        n = config.size.w,
        defaultWidth = 2,
    },
    rows = {
        n = config.size.h,
    }
  }
  self.tblLayoutContents = {}

  self:makeTableContents()
end

function SchemaWindow:onLoad()
  local left = Table(self.tblCfgContents, self.tblCfgOptions):size(16)
  self.left = left
  local right = Table(self.tblLayoutContents, self.tblLayoutOptions)
  self.right = right

  self.ui = Frame(
    _T('schema_config'),
    Column({
      Row({
        left,
        Separator.vertical(),
        right,
      }),
      Separator.horizontal(),
      Row({
        Button('OK'):action('clickedOk'),
        Button('Cancel'):action('clickedCancel'),
      }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 60, h = 17 }
end

function SchemaWindow:makeTableContents()
  self.tblCfgContents = {
    {
      { display = _T('name') },
      { display = self.config.name, action = 'editName' }
    },
    {
      { display = _T('width') },
      { display = _T(tostring(self.config.size.w)), action = 'editWidth' }
    },
    {
      { display = _T('height') },
      { display = tostring(self.config.size.h), action = 'editHeight' }
    },
  }
  self.tblCfgOptions.rows.n = #self.tblCfgContents

  local w = self.config.size.w
  local h = self.config.size.h
  local layout = self.config.layout

  for i = 1, h do
    self.tblLayoutContents[i] = {}
    for j = 1, w do
      local idx = (i - 1) * w + j
      self.tblLayoutContents[i][j] = {
        display = layout[idx]
      }
    end
  end

  self.tblLayoutOptions.columns.n = w
  self.tblLayoutOptions.rows.n = h
end

function SchemaWindow:editName()
  local win = InputWindow:new(_T('schema_name'), _T('input_prompt_schema_name'))
  self:present(
    win,
    function(result)
      self.config.name = result
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
    end
  )
end

function SchemaWindow:editWidth()
  local win = InputWindow:new(_T('schema_width'), _T('input_prompt_schema_width'))
  self:present(
    win,
    function(result)
      self.config.size.w = tonumber(result)
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right:reload()
    end
  )
end

function SchemaWindow:editHeight()
  local win = InputWindow:new(_T('schema_height'), _T('input_prompt_schema_height'))
  self:present(
    win,
    function(result)
      self.config.size.h = tonumber(result)
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right:reload()
    end
  )
end

function SchemaWindow:clickedOk()
  self:dismiss(true, self.config)
end

function SchemaWindow:clickedCancel()
  self:dismiss(false)
end

function SchemaWindow:editTableInplace(char)
  local idx = (self.right.selectedRow - 1) * self.config.size.w + self.right.selectedColumn
  self.config.layout[idx] = char
  self:makeTableContents()
  -- no changes to table config, no reload needed
  self.right:setNeedUpdate()
end

function SchemaWindow:on_key_down(device, key, keycode)
  if (key >= 0x41 and key <= 0x5a) or (key >= 0x61 and key <= 0x7a) then
    if self.selectedElement == self.right then
      -- Alphabet keys inside table
      self:editTableInplace(string.char(key):upper())
      return
    end
  end
  Window.on_key_down(self, device, key, keycode)
end

return SchemaWindow