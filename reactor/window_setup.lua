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
local App = require('ui.app')
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
local Alert = require('ui.window_alert')
local SelectWindow = require('ui.window_select')
local RedstoneWindow = require('reactor.window_redstone')
local InstanceWindow = require('reactor.window_instance')
local SchemaWindow = require('reactor.window_schema')
local reactorUtils = require('reactor.utils')

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
    suffix = suffix + 1
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
      { display = reactorUtils.redstoneDescription(self.config.global_control), action = 'editGlobalControl' }
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
      defaultWidth = 20,
      [1] = {
        selectable = false,
        width = 16
      }
    }
  }

  return Table(tableContents, tablecfg)
end

function SetupWindow:calcSchemasTabContent()
  local tableContents = {}
  local nextSectionRowIndex = 2
  table.insert(tableContents, {
    { display = _T('builtin_schemas') },
  })

  local builtinSchemas = builtins.schemas
  for i, schema in ipairs(builtinSchemas) do
    table.insert(tableContents, {
      { display = schema.displayName or schema.name or 'Unnamed' },
      { display = _T('view'), selectable = true, action = 'editSchema', value = { builtin = true, i = i } },
      { display = _T('copy'), selectable = true, action = 'copySchema', value = { builtin = true, i = i } },
    })
    nextSectionRowIndex = nextSectionRowIndex + 1
  end

  table.insert(tableContents, {
    { display = _T('user_schemas') }
  })

  for i, schema in ipairs(self.config.schemas or {}) do
    table.insert(tableContents, {
      { display = schema.displayName or schema.name or 'Unnamed' },
      { display = _T('edit'), selectable = true, action = 'editSchema', value = { builtin = false, i = i } },
      { display = _T('copy'), selectable = true, action = 'copySchema', value = { builtin = false, i = i } },
      { display = _T('delete'), selectable = true, action = 'deleteSchema', value = i },
    })
  end

  table.insert(tableContents, {
    { display = _T('create_new'), selectable = true, action = 'newSchema' }
  })

  local tableCfg = {
    showBorders = false,
    rows = {
      n = #tableContents,
    },
    columns = {
      n = 4,
      defaultWidth = 8,
      [1] = {
        width = 30,
      }
    }
  }
  return tableContents, tableCfg
end

function SetupWindow:buildSchemasTab()
  local tableContents, tableCfg = self:calcSchemasTabContent()
  return Table(tableContents, tableCfg):makeSelectable(false)
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
      { display = _T('edit'), selectable = true, action = 'editInstance', value = i },
      { display = _T('copy'), selectable = true, action = 'copyInstance', value = i },
      { display = _T('delete'), selectable = true, action = 'deleteInstance', value = i },
    })
  end

  table.insert(tableContents, {
    { display = _T('create_new'), selectable = true, action = 'newInstance' }
  })

  local tableCfg = {
    showBorders = false,
    rows = {
      n = #tableContents
    },
    columns = {
      n = 4,
      defaultWidth = 8,
      [1] = {
        width = 30
      }
    }
  }

  return tableContents, tableCfg
end

function SetupWindow:buildReactorsTab()
  local tableContents, tableCfg = self:calcReactorsTabContent()
  return Table(tableContents, tableCfg):makeSelectable(false)
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

  local status = Label(_T('keyboard_tips_setup')):size(nil, 1)

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
  if keycode == keyboard.keys.q then
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

function SetupWindow:newSchema()
  table.insert(self.config.schemas, {
    name = string.format('%s%d', _T('schema'), #self.config.schemas + 1),
    size = {
      w = 9,
      h = 6,
    },
    count = 54,
    layout = {},
  })
  self:refreshSchemas()
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

function SetupWindow:deleteSchema(index)
  local schema = self.config.schemas[index]
  local alert = Alert:new(
    _T('confirm_delete'), 
    string.format(_T('prompt_confirm_delete'), schema.name),
    Alert.Ok | Alert.Cancel
  )
  self:present(
    alert,
    function(result)
      if result == Alert.Ok then
        table.remove(self.config.schemas, index)
        self:refreshSchemas()
      end
    end
  )
end

function SetupWindow:newInstance()
  table.insert(self.config.instances, {
    name = string.format('%s #%d', _T('reactor'), #self.config.instances + 1),
    enabled = true,
    heat_max = 0,
    heat_min = 0,
    components = {},
    profiles = {},
  })
  self:refreshInstances()
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

function SetupWindow:deleteInstance(index)
  local instance = self.config.instances[index]
  local alert = Alert:new(
    _T('confirm_delete'), 
    string.format(_T('prompt_confirm_delete'), instance.name),
    Alert.Ok | Alert.Cancel
  )
  self:present(
    alert,
    function(result)
      if result == Alert.Ok then
        table.remove(self.config.instances, index)
        self:refreshInstances()
      end
    end
  )
end

function SetupWindow:reloadLanguage(code)
end

return SetupWindow
