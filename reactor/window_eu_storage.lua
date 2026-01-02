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
local InputWindow = require('ui.window_input')
require('reactor.window+select_component')

local EUStorageWindow = class(Window)

function EUStorageWindow:init(super, config)
  super.init()
  self.config = utils.copy(config or {
    name = _T('eu_storage'),
    address = '',
    eu_low = 0.2,
    eu_high = 0.8,
  })

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

function EUStorageWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('eu_storage_config'),
    Column({
      self.list,
      Separator.horizontal(),
      Row({
        Button(_T('ok')):action('clickedOk'),
        Button(_T('cancel')):action('clickedCancel'),
      }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 50, h = 10 }
end

function EUStorageWindow:makeTableContents()
  self.tableContents = {
    {
      { display = _T('eu_storage_name') },
      { display = self.config.name, action = 'editName' }
    },
    {
      { display = _T('eu_address') },
      { display = self.config.address or _T('not_configured'), action = 'editAddress' }
    },
    {
      { display = _T('eu_low_threshold') },
      { display = tostring(self.config.eu_low or 0), action = 'editLowThreshold' }
    },
    {
      { display = _T('eu_high_threshold') },
      { display = tostring(self.config.eu_high or 0), action = 'editHighThreshold' }
    },
  }
  self.tableCfg.rows.n = #self.tableContents
end

function EUStorageWindow:makeRefreshingCallback(fn)
  return function(...)
    fn(...)
    self:makeTableContents()
    self.list.contents = self.tableContents
    self.list:reload()
  end
end

function EUStorageWindow:editName()
  local win = InputWindow:new(_T('eu_storage_name'), _T('input_prompt_eu_name'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.name = result
      end
    )
  )
end

function EUStorageWindow:editAddress()
  self:selectComponent(
    'gt_machine',
    self:makeRefreshingCallback(
      function(address)
        self.config.address = address
      end
    )
  )
end

function EUStorageWindow:editLowThreshold()
  local win = InputWindow:new(_T('eu_low_threshold'), _T('input_prompt_eu_low'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.eu_low = tonumber(result) or 0
      end
    )
  )
end

function EUStorageWindow:editHighThreshold()
  local win = InputWindow:new(_T('eu_high_threshold'), _T('input_prompt_eu_high'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.eu_high = tonumber(result) or 0
      end
    )
  )
end

function EUStorageWindow:clickedOk()
  self:dismiss(true, self.config)
end

function EUStorageWindow:clickedCancel()
  self:dismiss(false)
end

return EUStorageWindow
