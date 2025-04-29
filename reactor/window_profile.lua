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
local builtins = require('reactor.builtins')

local function makeDefaultConfig()
  return {
    item = {}
  }
end

local ProfileWindow = class(Window)

function ProfileWindow:init(super, config, schemas)
  super.init()
  self.config = utils.copy(config) or makeDefaultConfig()
  
  local schemasByKey = {}
  for _, schema in ipairs(builtins.schemas) do
    schemasByKey[schema.name] = schema
  end
  for _, schema in ipairs(schemas or {}) do
    schemasByKey[schema.name] = schema
  end
  self.schemasByKey = schemasByKey

  self.schema = config.schema and schemasByKey[config.schema]

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
        n = 1,
        defaultWidth = 2,
        [1] = {
          selectable = false,
        }
    },
    rows = {
        n = 1,
    }
  }
  self.tblLayoutContents = {}

  self:makeTableContents()
end

function ProfileWindow:onLoad()
  local left = Table(self.tblCfgContents, self.tblCfgOptions):size(24)
  self.left = left
  local right = Table(self.tblLayoutContents, self.tblLayoutOptions)
  self.right = right

  self.ui = Frame(
    _T('profile_config'),
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

function ProfileWindow:makeTableContents()
  local schema = self.schema
  local schemaDisplayName = schema and (schema.displayName or schema.name) or _T('not_configured')

  local tblCfgContents = {
    {
      { display = _T('schema') },
      { display = schemaDisplayName, action = 'editSchema' }
    },
  }

  self.tblCfgContents = tblCfgContents
  
  if not schema then
    self.tblCfgOptions.rows.n = #tblCfgContents
    -- tricks to 'hide' layout
    self.tblLayoutOptions.showBorders = false
    self.tblLayoutOptions.rows.n = 1
    self.tblLayoutOptions.columns.n = 1
    self.tblLayoutContents = {}
    return
  end

  local uniqueLayoutVariables = {}

  for _, var in ipairs(schema.layout or {}) do
    uniqueLayoutVariables[var] = true
  end

  for var, _ in pairs(uniqueLayoutVariables) do
    local item = self.config.item[var]
    local itemDisplay = item and (item.name and _T(item.name)) or _T('not_configured')
    table.insert(tblCfgContents, {
      { display = var },
      { display = itemDisplay, action = 'editItem', value = var }
    })
  end

  self.tblCfgOptions.rows.n = #tblCfgContents

  -- layout table contents

  local w = schema.size.w
  local h = schema.size.h
  local layout = schema.layout

  for i = 1, h do
    self.tblLayoutContents[i] = {}
    for j = 1, w do
      local idx = (i - 1) * w + j
      self.tblLayoutContents[i][j] = {
        display = layout[idx]
      }
    end
  end

  self.tblLayoutOptions.showBorders = true
  self.tblLayoutOptions.columns.n = w
  self.tblLayoutOptions.rows.n = h
end

function ProfileWindow:editSchema()
  local schemaList = { _T('not_configured') }
  local backed = { 1 } -- placeholder

  for name, schema in pairs(self.schemasByKey) do 
    table.insert(schemaList, schema.displayName or schema.name)
    table.insert(backed, name)
  end

  local win = Select:new(_T('select_schema'), schemaList)
  self:present(
    win,
    function(result)
      local schemaName = nil
      if result ~= 1 then
        schemaName = backed[result]
      end
      if self.config.schema ~= schemaName then
        self.config.item = {}
      end
      self.config.schema = schemaName
      self.schema = schemaName and self.schemasByKey[schemaName]

      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right.contents = self.tblLayoutContents
      self.right:reload()
    end
  )
end

function ProfileWindow:editItem(varName)
end

function ProfileWindow:clickedOk()
  self:dismiss(true, self.config)
end

function ProfileWindow:clickedCancel()
  self:dismiss(false)
end

return ProfileWindow