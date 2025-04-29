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

local builtins = require('reactor.builtins')
local reactorUtils = require('reactor.utils')

local function makeDefaultConfig()
  return {
    change = 'none'
  }
end

local ItemWindow = class(Window)

function ItemWindow:init(super, config)
  super.init()
  self.config = utils.copy(config) or makeDefaultConfig()

  self.tableCfg = {
    showBorders = false,
    columns = {
      n = 2,
      defaultWidth = 20,
      [1] = {
        selectable = false,
      }
    },
    rows = {
      n = 1
    }
  }
  self:makeTableContents()
end

function ItemWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('item_config'),
    Column({
        self.list,
        Separator.horizontal(),
        Row({
            Button(_T('ok')):action('clickedOk'),
            Button(_T('cancel')):action('clickedCancel'),
        }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 50, h = 8 }
end

function ItemWindow:makeTableContents()
  local tableContents = {
    {
      { display = _T('item_name') },
      { display = _T(self.config.name or 'not_configured'), action = 'editItem' }
    },
    {
      { display = _T('change_condition') },
      { display = reactorUtils.changeConditionDescription(self.config), action = 'editChangeCondition' }
    },
  }
  self.tableContents = tableContents

  if self.config.change == 'damage_less' then
    table.insert(tableContents, {
      { display = _T('threshold') },
      { display = tostring(self.config.threshold), action = 'editThreshold' }
    })
    self.tableCfg.rows.n = 3
  else
    self.tableCfg.rows.n = 2
  end
end

function ItemWindow:editItem()
  local itemList = {}
  for _, item in ipairs(builtins.items) do
    table.insert(itemList, _T(item.id))
  end
  local win = Select:new(_T('item_name'), itemList)

  self:present(
    win, 
    function(result)
      self.config.name = builtins.items[result].id
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:editChangeCondition()
  local conditions = {
    'none',
    'damage_less',
  }
  local selectMode = Select:new(_T('redstone_mode'), {
    _T('change_condition_none'),
    _T('change_condition_damage_less'),
  })

  self:present(
    selectMode, 
    function(result)
      self.config.change = conditions[result]
      if self.config.change == 'damage_less' then
        self.config.threshold = 0.1
      end
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:editThreshold()
  local win = InputWindow:new(_T('threshold'), _T('input_prompt_threshold'))
  self:present(
    win,
    function(result)
      self.config.threshold = tonumber(result)
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:clickedOk()
  self:dismiss(true, self.config)
end

function ItemWindow:clickedCancel()
  self:dismiss(false)
end

return ItemWindow