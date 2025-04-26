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
end

function SchemaWindow:editWidth()
end

function SchemaWindow:editHeight()
end

function SchemaWindow:clickedOk()
  self:dismiss(true, self.config)
end

function SchemaWindow:clickedCancel()
  self:dismiss(false)
end

return SchemaWindow