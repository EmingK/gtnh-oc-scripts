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
  return {}
end

local TransposerWindow = class(Window)

function TransposerWindow:init(super, config)
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

function TransposerWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('transposer_config'),
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

function TransposerWindow:makeTableContents()
  local tableContents = {
    {
      { display = _T('component_address') },
      { display = self.config.address or _T('not_configured'), action = 'editAddress' }
    },
    {
      { display = _T('item_input_side') },
      { display = _T(utils.sideDescription(self.config.item_in or 0)), action = 'editDirection', value = 'item_in' }
    },
    {
      { display = _T('item_output_side') },
      { display = _T(utils.sideDescription(self.config.item_out or 0)), action = 'editDirection', value = 'item_out' }
    },
    {
      { display = _T('item_reactor_side') },
      { display = _T(utils.sideDescription(self.config.item_reactor or 0)), action = 'editDirection', value = 'item_reactor' }
    }
  }
  self.tableContents = tableContents
  self.tableCfg.rows.n = #tableContents
end

function TransposerWindow:editAddress()
  self:selectComponent(
    'transposer',
    function(result)
      self.config.address = result
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function TransposerWindow:editDirection(field)
  local selectSide = Select:new(_T('item_direction'), {
    _T('down'),
    _T('up'),
    _T('north'),
    _T('south'),
    _T('west'),
    _T('east')
  })

  self:present(
    selectSide, 
    function(result)
      self.config[field] = result - 1
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function TransposerWindow:clickedOk()
  self:dismiss(true, self.config)
end

function TransposerWindow:clickedCancel()
  self:dismiss(false)
end

return TransposerWindow