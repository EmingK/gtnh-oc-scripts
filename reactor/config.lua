--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local utils = require('core.utils')
local builtins = require('reactor.builtins')
local reactorControl = require('reactor.reactor_control')

local component = palRequire('component')
local filesystem = palRequire('filesystem')

local kDefaultConfigPath = 'reactor.conf'

local configFileName = nil
local config = nil
local schemasByKey = {}

local function configLoad(path)
  configFileName = path or kDefaultConfigPath
  config = utils.loadSerializedObject(configFileName)
  return config
end

local function configSave()
  if config then
    utils.saveSerializedObject(configFileName, config)
  end
end

local function instantiateControl(cfg, rc)
  if cfg.mode == 'adapter' then
    return reactorControl.Adapter:new(rc)
  elseif cfg.mode == 'vanilla' then
    return reactorControl.Vanilla:new(cfg)
  elseif cfg.mode == 'bundled' then
    return reactorControl.Bundled:new(cfg)
  else
    error(string.format(_T('unsupported_control'), cfg.mode or '<nil>'))
  end
end

local function instantiateItem(description)
  local item = {}
  item.name = description.name
  local checkFn
  if description.change == 'none' then
    checkFn = builtins.check.noCheck
  elseif description.change == 'damage_less' then
    checkFn = builtins.check.damageLess(description.threshold)
  else
    error(string.format(_T('unsupported_item_check'), description.change or '<nil>'))
  end
  item.check = checkFn

  return item
end

local function configInstantiate(cfg)
  if not builtins.schemas then
    error('Builtins was not setup, this is a bug.')
  end

  local ret = {}

  ret.name = cfg.name
  ret.enabled = cfg.enabled
  ret.minHeat = cfg.heat_min
  ret.maxHeat = cfg.heat_max
  ret.interval = 0.5 + 0.05 * #config.instances

  -- components
  ret.reactor = component.proxy(cfg.components.reactor)

  local tp = {}
  local tpcfg = cfg.components.transposer
  local tproxy = component.proxy(tpcfg.address)
  setmetatable(tp, { __index = tproxy })
  tp.itemIn = tpcfg.item_in
  tp.itemOut = tpcfg.item_out
  tp.itemReactor = tpcfg.item_reactor
  ret.transposer = tp

  local ctrl = instantiateControl(cfg.components.redstone, ret.reactor)
  ret.control = ctrl

  -- profiles
  local profiles = {}
  for k, v in pairs(cfg.profiles) do
    local schema = schemasByKey[v.schema]
    if not schema then
      error(string.format(_T('invalid_schema'), v.schema or '<nil>'))
    end

    local profile = {}
    profile.count = schema.count
    local layout = {}
    for i, id in ipairs(schema.layout) do
      layout[i] = instantiateItem(v.item[id])
    end
    profile.layout = layout

    profiles[k] = profile
  end
  ret.profiles = profiles

  return ret
end

local function configPrepare()
  for _, schema in ipairs(builtins.schemas) do
    schemasByKey[schema.name] = schema
  end

  if not config then 
    return
  end

  for _, schema in ipairs(config.schemas or {}) do
    schemasByKey[schema.name] = schema
  end
end

local function configBackup()
  local cwd = os.getenv('PWD')
  local configPath = filesystem.canonical(string.format('%s/%s', cwd, configFileName))
  local backupFilename = configPath .. '.bak'
  if filesystem.exists(configPath) then
    filesystem.copy(configPath, backupFilename)
    return backupFilename
  end
  return nil
end

return {
  load = configLoad,
  save = configSave,
  backup = configBackup,
  get = function() return config end,
  set = function(newConfig) config = newConfig end,
  instantiate = configInstantiate,
  instantiateControl = instantiateControl,
  prepare = configPrepare,
}
