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
local SelectWindow = require('ui.window_select')
local RedstoneWindow = require('reactor.window_redstone')
local InstanceWindow = require('reactor.window_instance')
local SchemaWindow = require('reactor.window_schema')

local function makeDefaultConfig()
  return {
    lang = i18n.langList.default,
    schemas = {},
    instances = {},
  }
end

local function getCopyName(name, listOfNameOwner)
  local names = {}
  for _, entry in pairs(listOfNameOwner) do
    names[entry.name] = true
  end

  local namePrefix = string.format("%s %s", name, _T('name_copy'))
  local suffix = 1
  local newName = namePrefix
  while names[newName] do
    newName = string.format("%s%d", namePrefix, suffix)
  end
  return newName
end

local SetupWindow = class(Window)

function SetupWindow:onLoad()
  self.config = config.get() or makeDefaultConfig()

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

function SetupWindow:calcSchemasTabContent()
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

  local tableCfg = {
    showBorders = false,
    rows = {
      n = #tableContents
    },
    columns = {
      n = 3,
      defaultWidth = 8,
      [1] = {
        width = 30
      }
    }
  }
  return tableContents, tableCfg
end

function SetupWindow:buildSchemasTab()
  local tableContents, tableCfg = self:calcSchemasTabContent()
  return Table(tableContents, tableCfg)
end

function SetupWindow:refreshSchemas()
  local tableContents, tableCfg = self:calcSchemasTabContent()
  self.schemasTabTable.contents = tableContents
  self.schemasTabTable.config = tableCfg
  self.schemasTabTable:reload()
end

function SetupWindow:calcReactorsTabContent()
  local tableContents = {}

  for i, instance in ipairs(self.config.instances or {}) do
    table.insert(tableContents, {
      { display = instance.name or 'Unnamed' },
      { display = _T('edit'), action = 'editInstance', value = i },
      { display = _T('copy'), action = 'copyInstance', value = i },
    })
  end

  local tableCfg = {
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

  return tableContents, tableCfg
end

function SetupWindow:buildReactorsTab()
  local tableContents, tableCfg = self:calcReactorsTabContent()
  return Table(tableContents, tableCfg)
end

function SetupWindow:refreshInstances()
  local tableContents, tableCfg = self:calcReactorsTabContent()
  self.reactorsTabTable.contents = tableContents
  self.reactorsTabTable.config = tableCfg
  self.reactorsTabTable:reload()
end

function SetupWindow:buildSaveTab()
  return Row()
end

function SetupWindow:buildUI()
  local title = Label(string.format(_T('title_config_app'), appVersion)):size(nil, 1)
  self.generalTabTable = self:buildGeneralTab()
  self.schemasTabTable = self:buildSchemasTab()
  self.reactorsTabTable = self:buildReactorsTab()
  local save = self:buildSaveTab()

  local main = Tabs({
      { _T('tab_general'), self.generalTabTable },
      { _T('tab_schemas'), self.schemasTabTable },
      { _T('tab_reactors'), self.reactorsTabTable },
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

function SetupWindow:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.x then
    self:dismiss()
  else
    Window.on_key_down(self, device, key, keycode)
  end
end

function SetupWindow:editI18n()
  local languages = {}
  for name, _ in pairs(i18n.langList) do
    if name ~= 'default' then
      table.insert(languages, name)
    end
  end

  local win = SelectWindow:new(_T('language'), languages)
  self:present(
    win,
    function(idx)
      local langCode = i18n.langList[languages[idx]]
      self.config.lang = langCode
      self:reloadLanguage(langCode)
    end
  )
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

  local win = SchemaWindow:new(schema, info.builtin)
  self:present(
    win,
    function(editOk, newSchema)
      if editOk and not info.builtin then
        self.config.schemas[info.i] = newSchema
        self.schemasTabTable:reload()
      end
    end
  )
end

function SetupWindow:copySchema(info)
  local schema
  if info.builtin then
    schema = builtins.schemas[info.i]
  else
    schema = self.config.schemas[info.i]
  end

  if not schema then
    return
  end

  schema = utils.copy(schema)
  schema.name = getCopyName(schema.name, self.config.schemas)
  schema.displayName = nil
  table.insert(self.config.schemas, schema)
  self:refreshSchemas()
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
  local instance = self.config.instances[index]
  instance = utils.copy(instance)
  instance.name = getCopyName(instance.name, self.config.instances)
  table.insert(self.config.instances, instance)
  self:refreshInstances()
end

function SetupWindow:reloadLanguage(code)
end

return SetupWindow
