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
local euStorages = nil
local euLogicStart = 'or'
local euLogicStop = 'or'

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
    for i, id in pairs(schema.layout) do
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

  -- Prepare EU storages
  euStorages = {}
  euLogicStart = config.eu_logic_start or 'or'
  euLogicStop = config.eu_logic_stop or 'or'

  for _, storage in ipairs(config.eu_storages or {}) do
    if storage.address and storage.address ~= '' then
      local euProxy = component.proxy(storage.address)
      table.insert(euStorages, {
        name = storage.name,
        proxy = euProxy,
        eu_low = storage.eu_low or 0,
        eu_high = storage.eu_high or 0,
      })
    end
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

local function checkEUCondition()
  if not euStorages or #euStorages == 0 then
    return true, false  -- No EU control: allow start, never force stop
  end

  local startConditions = {}
  local stopConditions = {}

  for _, storage in ipairs(euStorages) do
    local storedEU = storage.proxy.getStoredEU()
    local capacity = storage.proxy.getEUCapacity()

    -- Calculate actual thresholds from percentages
    local lowThreshold = capacity * storage.eu_low
    local highThreshold = capacity * storage.eu_high

    -- Start condition: EU < low threshold
    local shouldStart = storedEU < lowThreshold
    table.insert(startConditions, shouldStart)

    -- Stop condition: EU > high threshold
    local shouldStop = storedEU > highThreshold
    table.insert(stopConditions, shouldStop)
  end

  -- Apply start logic
  local canStart = false
  if euLogicStart == 'and' then
    -- All storages must satisfy start condition
    canStart = true
    for _, result in ipairs(startConditions) do
      if not result then
        canStart = false
        break
      end
    end
  else  -- 'or'
    -- At least one storage satisfies start condition
    for _, result in ipairs(startConditions) do
      if result then
        canStart = true
        break
      end
    end
  end

  -- Apply stop logic
  local mustStop = false
  if euLogicStop == 'and' then
    -- All storages must satisfy stop condition
    mustStop = true
    for _, result in ipairs(stopConditions) do
      if not result then
        mustStop = false
        break
      end
    end
  else  -- 'or'
    -- At least one storage satisfies stop condition
    for _, result in ipairs(stopConditions) do
      if result then
        mustStop = true
        break
      end
    end
  end

  return canStart, mustStop
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
  checkEUCondition = checkEUCondition,
  getEUStorages = function() return euStorages end,
}
