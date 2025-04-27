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

local RedstoneWindow = class(Window)

function RedstoneWindow:init(super, config)
  super.init()
  self.config = utils.copy(config)

  self.tableCfg = {
    showBorders = false,
    columns = {
      n = 2,
      defaultWidth = 20
    },
    rows = {
      n = 1
    }
  }
  self:makeTableContents()
end

function RedstoneWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('redstone_config'),
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

function RedstoneWindow:makeTableContents()
  local tableContents = {}
  self.tableContents = tableContents
  -- mode
  if not self.config then
    table.insert(tableContents, {
      { display = _T('redstone_mode') },
      { display = _T('redstone_mode_none'), action = 'editRedstoneMode' }
    })
    self.tableCfg.rows.n = 1
    return
  end

  table.insert(tableContents, {
    { display = _T('redstone_mode') },
    { display = _T('redstone_mode_' .. self.config.mode), action = 'editRedstoneMode' }
  })
  table.insert(tableContents, {
    { display = _T('component_address') },
    { display = self.config.address or _T('not_configured'), action = 'editRedstoneAddress' }
  })
  table.insert(tableContents, {
    { display = _T('redstone_direction') },
    { display = _T(utils.sideDescription(self.config.side)) or _T('not_configured'), action = 'editRedstoneSide' }
  })
  if self.config.mode == 'bundled' then
    table.insert(tableContents, {
      { display = _T('redstone_color') },
      { display = _T(utils.colorDescription(self.config.color)) or _T('not_configured'), action = 'editRedstoneColor' }
    })
    self.tableCfg.rows.n = 4
  else
    self.tableCfg.rows.n = 3
  end
end

function RedstoneWindow:editRedstoneMode()
  local modes = {
    'none',
    'vanilla',
    'bundled'
  }
  local selectMode = Select:new(_T('redstone_mode'), {
    _T('redstone_mode_none'),
    _T('redstone_mode_vanilla'),
    _T('redstone_mode_bundled'),
  })

  self:present(
    selectMode, 
    function(result)
      if result == 1 then
        self.config = nil
      else
        if not self.config then
          self.config = {}
        end
        self.config.mode = modes[result]
      end
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function RedstoneWindow:editRedstoneAddress()
  self:selectComponent(
    'redstone',
    function(result)
      self.config.address = result
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function RedstoneWindow:editRedstoneSide()
  local selectSide = Select:new(_T('redstone_direction'), {
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
      self.config.side = result - 1
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function RedstoneWindow:editRedstoneColor()
  local selectColor = Select:new(_T('redstone_direction'), {
    _T('white'),
    _T('orange'),
    _T('magenta'),
    _T('lightblue'),
    _T('yellow'),
    _T('lime'),
    _T('pink'),
    _T('gray'),
    _T('silver'),
    _T('cyan'),
    _T('purple'),
    _T('blue'),
    _T('brown'),
    _T('green'),
    _T('red'),
    _T('black'),
  })

  self:present(
    selectColor, 
    function(result)
      self.config.color = result - 1
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function RedstoneWindow:clickedOk()
  self:dismiss(true, self.config)
end

function RedstoneWindow:clickedCancel()
  self:dismiss(false)
end

return RedstoneWindow