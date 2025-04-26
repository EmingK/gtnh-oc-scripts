--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  Reactor sub app - setup

  This is an app used to setup the reactor app, including:
    - app language
    - reactor schemas
    - reactor instances
]]

local term = palRequire('term')
local keyboard = palRequire('keyboard')

local class = require('core.class')
local App = require('core.app')
local utils = require('core.utils')
local i18n = require('core.i18n')

local Window = require('ui.window')
local Label = require('ui.label')
local Button = require('ui.button')
local Grid = require('ui.grid')
local Row = require('ui.row')
local Column = require('ui.column')
local Tabs = require('ui.tabs')
local Table = require('ui.table')

local appVersion = require('reactor.version')
local config = require('reactor.config')
local RedstoneWindow = require('reactor.window_redstone')

local function buildGeneralTab()
  local tableContents = {
    {
      { display = _T('language') },
      { display = i18n.current }
    },
    {
      { display = _T('global_control') },
      { display = 'None' }
    },
    {
      { display = _T('sync_shutdown') },
      { display = 'On' }
    }
  }

  local tablecfg = {
    showBorders = false,
    rows = {
      n = #tableContents
    },
    columns = {
      n = 2,
      defaultWidth = 10,
      [1] = {
        width = 16
      }
    }
  }

  return Table(tableContents, tablecfg)
end

local function buildSchemasTab()
  local tableContents = {}
  table.insert(tableContents, {
    { display = _T('builtin_schemas') },
  })
  table.insert(tableContents, {
    { display = '强冷堆' },
    {},
    { display = '复制'}
  })
  table.insert(tableContents, {
    { display = '我的配置' }
  })
  table.insert(tableContents, {
    { display = '增殖堆' },
    { display = '编辑' },
    { display = '复制'}
  })

  local tablecfg = {
    showBorders = false,
    rows = {
      n = #tableContents
    },
    columns = {
      n = 3,
      defaultWidth = 8,
      [1] = {
        width = 16
      }
    }
  }

  return Table(tableContents, tablecfg)
end

local function buildReactorsTab()
  return Row()
end

local function buildSaveTab()
  return Row()
end

local function buildUI()
  local title = Label(string.format(_T('title_config_app'), appVersion)):size(nil, 1)
  local general = buildGeneralTab()
  local schemas = buildSchemasTab()
  local reactors = buildReactorsTab()
  local save = buildSaveTab()

  local main = Tabs({
      { _T('tab_general'), general },
      { _T('tab_schemas'), schemas },
      { _T('tab_reactors'), reactors },
      { _T('tab_save'), save },
  })

  local status = Label("111"):size(nil, 1)

  local root = Column({
      title,
      main,
      status
  })
  return {
    root = root,
    tabs = main,
  }
end

local SetupWindow = class(Window)

function SetupWindow:onLoad()
  self.config = config.get()

  term.clear()
  local w, h, x, y = term.getViewport()

  local ui = buildUI()
  local root = ui.root
  self.tabs = ui.tabs

  root.rect = { x = x + 1, y = y + 1, w = w, h = h }
  root:layout()

  self.ui = root
end

function SetupWindow:on_key_up(device, key, keycode)
  if keycode == keyboard.keys.x then
    self:dismiss()
  elseif keycode == keyboard.keys.enter then
    local rs = self.config.instances[1].components.redstone
    local win = RedstoneWindow:new(rs)
    self:present(win)
  else
    Window.on_key_up(self, device, key, keycode)
  end
end

return SetupWindow
