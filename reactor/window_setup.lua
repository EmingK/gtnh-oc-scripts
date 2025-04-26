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
local builtins = require('reactor.builtins')
local RedstoneWindow = require('reactor.window_redstone')
local InstanceWindow = require('reactor.window_instance')
local SchemaWindow = require('reactor.window_schema')

local SetupWindow = class(Window)

function SetupWindow:onLoad()
  self.config = config.get()

  term.clear()
  local ui = self:buildUI()
  local root = ui.root
  self.tabs = ui.tabs

  self.ui = root
end


function SetupWindow:buildGeneralTab()
  local tableContents = {
    {
      { display = _T('language') },
      { display = i18n.current, action = 'editI18n' }
    },
    {
      { display = _T('global_control') },
      { display = 'None', action = 'editGlobalControl' }
    },
    -- {
    --   { display = _T('sync_shutdown') },
    --   { display = 'On' }
    -- }
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

function SetupWindow:buildSchemasTab()
  local tableContents = {}
  table.insert(tableContents, {
    { display = _T('builtin_schemas') },
  })

  local builtinSchemas = builtins.schemas
  for i, schema in ipairs(builtinSchemas) do
    table.insert(tableContents, {
      { display = schema.displayName or schema.name or 'Unnamed' },
      { display = _T('view'), action = 'editSchema', value = { builtin = true, i = i } },
      { display = _T('copy'), action = 'copySchema', value = { builtin = true, i = i } },
    })
  end

  table.insert(tableContents, {
    { display = _T('user_schemas') }
  })

  for i, schema in ipairs(self.config.schemas or {}) do
    table.insert(tableContents, {
      { display = schema.displayName or schema.name or 'Unnamed' },
      { display = _T('edit'), action = 'editSchema', value = { builtin = false, i = i } },
      { display = _T('copy'), action = 'copySchema', value = { builtin = false, i = i } },
    })
  end

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

function SetupWindow:buildReactorsTab()
  local tableContents = {}

  for i, instance in ipairs(self.config.instances or {}) do
    table.insert(tableContents, {
      { display = instance.name or 'Unnamed' },
      { display = _T('edit'), action = 'editInstance', value = i },
      { display = _T('copy'), action = 'copyInstance', value = i },
    })
  end

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

function SetupWindow:buildSaveTab()
  return Row()
end

function SetupWindow:buildUI()
  local title = Label(string.format(_T('title_config_app'), appVersion)):size(nil, 1)
  local general = self:buildGeneralTab()
  local schemas = self:buildSchemasTab()
  local reactors = self:buildReactorsTab()
  local save = self:buildSaveTab()

  local main = Tabs({
      { _T('tab_general'), general },
      { _T('tab_schemas'), schemas },
      { _T('tab_reactors'), reactors },
      { _T('tab_save'), save },
  })

  local status = Label("[←↑→↓]功能选择  [Enter]确认  [N]新建配置"):size(nil, 1)

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

function SetupWindow:on_key_up(device, key, keycode)
  if keycode == keyboard.keys.x then
    self:dismiss()
  -- elseif keycode == keyboard.keys.enter then
  --   local rs = self.config.instances[1].components.redstone
  --   local win = RedstoneWindow:new(rs)
  --   self:present(win)
  else
    Window.on_key_up(self, device, key, keycode)
  end
end

function SetupWindow:editI18n()
end

function SetupWindow:editGlobalControl()
  local rs = self.config.global_control
  local win = RedstoneWindow:new(rs)
  self:present(
    win,
    function(editOk, newConfig)
      if editOk then
        self.config.global_control = newConfig
      end
    end
  )
end

function SetupWindow:editSchema(info)
  local schema
  if info.builtin then
    schema = builtins.schemas[info.i]
  else
    schema = self.config.schemas[info.i]
  end

  if not schema then
    return
  end

  local win = SchemaWindow:new(schema)
  self:present(
    win,
    function(editOk, newSchema)
      if editOk then
        --self.config.global_control = newConfig
      end
    end
  )
end

function SetupWindow:copySchema(info)
end

function SetupWindow:editInstance(index)
  local instance = self.config.instances[index]
  local win = InstanceWindow:new(instance)
  self:present(
    win,
    function(editOk, newInstance)
      if editOk then
        self.config.instances[index] = newInstance
      end
    end
  )
end

function SetupWindow:copyInstance(index)
end

return SetupWindow
