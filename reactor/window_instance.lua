--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local utils = require('core.utils')
local reactorUtils = require('reactor.utils')

local Window = require('ui.window')
local Column = require('ui.column')
local Row = require('ui.row')
local Frame = require('ui.frame')
local Button = require('ui.button')
local Table = require('ui.table')
local Separator = require('ui.separator')
local Select = require('ui.window_select')
local InputWindow = require('ui.window_input')
local RedstoneWindow = require('reactor.window_redstone')
local TransposerWindow = require('reactor.window_transposer')
local ProfileWindow = require('reactor.window_profile')
require('reactor.window+select_component')

local InstanceWindow = class(Window)

function InstanceWindow:init(super, config, schemas)
  super.init()
  self.config = utils.copy(config)
  self.schemas = schemas

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

function InstanceWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('instance_config'),
    Column({
      self.list,
      Separator.horizontal(),
      Row({
        Button(_T('ok')):action('clickedOk'),
        Button(_T('cancel')):action('clickedCancel'),
      }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 50, h = 14 }
end

function InstanceWindow:makeTableContents()
  self.tableContents = {
    {
      { display = _T('name') },
      { display = self.config.name, action = 'editName' }
    },
    -- {
    --   { display = _T('enabled') },
    --   { display = _T(tostring(self.config.enabled)), action = 'editEnabled' }
    -- },
    {
      { display = _T('max_heat_temp') },
      { display = tostring(self.config.heat_max), action = 'editMaxHeat' }
    },
    {
      { display = _T('min_heat_temp') },
      { display = tostring(self.config.heat_min), action = 'editMinHeat' }
    },
    {
      { display = _T('reactor_address') },
      { display = self.config.components.reactor, action = 'editReactorAddress' }
    },
    {
      { display = _T('transposer') },
      { display = reactorUtils.transposerDescription(self.config.components.transposer), action = 'editTransposer' }
    },
    {
      { display = _T('redstone_control') },
      { display = reactorUtils.redstoneDescription(self.config.components.redstone), action = 'editRedstone' }
    },
    {
      { display = _T('profile_working') },
      { display = reactorUtils.profileDescription(self.config.profiles.working), action = 'editProfile', value = 'working' }
    },
    {
      { display = _T('profile_heatup') },
      { display = reactorUtils.profileDescription(self.config.profiles.heatup), action = 'editProfile', value = 'heatup' }
    },
    {
      { display = _T('profile_cooldown') },
      { display = reactorUtils.profileDescription(self.config.profiles.cooldown), action = 'editProfile', value = 'cooldown' }
    },
  }
  self.tableCfg.rows.n = #self.tableContents
end

function InstanceWindow:makeRefreshingCallback(fn)
  return function(...)
    fn(...)
    self:makeTableContents()
    self.list.contents = self.tableContents
    self.list:reload()
  end
end

function InstanceWindow:editName()
  local win = InputWindow:new(_T('instance_name'), _T('input_prompt_instance_name'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.name = result
      end
    )
  )
end

function InstanceWindow:editEnabled()
  local selectEnabled = Select:new(_T('enabled'), {
    _T('enabled'),
    _T('disabled'),
  })

  self:present(
    selectEnabled, 
    self:makeRefreshingCallback(
      function(result)
        self.config.enabled = result == 1
      end
    )
  )
end

function InstanceWindow:editMaxHeat()
  local win = InputWindow:new(_T('max_heat_temp'), _T('input_prompt_max_heat'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.heat_max = tonumber(result)
      end
    )
  )
end

function InstanceWindow:editMinHeat()
  local win = InputWindow:new(_T('min_heat_temp'), _T('input_prompt_min_heat'))
  self:present(
    win,
    self:makeRefreshingCallback(
      function(result)
        self.config.heat_min = tonumber(result)
      end
    )
  )
end

function InstanceWindow:editReactorAddress()
  self:selectComponent(
    'reactor',
    self:makeRefreshingCallback(
      function(address)
        self.config.components.reactor = address
      end
    )
  )
end

function InstanceWindow:editTransposer()
  local tp = self.config.components.transposer
  local win = TransposerWindow:new(tp)
  self:present(
    win,
    self:makeRefreshingCallback(
      function(editOk, newConfig)
        if editOk then
          self.config.components.transposer = newConfig
        end
      end
    )
  )
end

function InstanceWindow:editRedstone()
  local rs = self.config.components.redstone
  local win = RedstoneWindow:new(rs)
  self:present(
    win,
    self:makeRefreshingCallback(
      function(editOk, newConfig)
        if editOk then
          self.config.components.redstone = newConfig
        end
      end
    )
  )
end

function InstanceWindow:editProfile(name)
  local profile = self.config.profiles[name]
  local win = ProfileWindow:new(profile, self.schemas)
  self:present(
    win,
    self:makeRefreshingCallback(
      function(editOk, newConfig)
        if editOk then
          self.config.profiles[name] = newConfig
        end
      end
    )
  )
end

function InstanceWindow:clickedOk()
  self:dismiss(true, self.config)
end

function InstanceWindow:clickedCancel()
  self:dismiss(false)
end

return InstanceWindow