local _argv = table.pack(require('shell').parse(...))
  -- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)


require("core.pal")
local shell = palRequire('shell')
local event = palRequire('event')
local term = palRequire('term')

local i18n = require("core.i18n")
local utils = require("core.utils")
local config = require("reactor.config")
local builtins = require("reactor.builtins")
local App = require("ui.app")
local WindowSetup = require("reactor.window_setup")
local WindowRun = require("reactor.window_run")

local function appEntry(window)
  return function(...) App:new(...):start(window:new()) end
end

local function usage()
  print(_T('usage'))
end

local subCommands = {
  setup = appEntry(WindowSetup),
  run = appEntry(WindowRun),
  help = usage,
}

local function main(args, options)
  if options.debug then
    debugLog = utils.debug
  end

  local cfg = config.load(options.config)
  local lang = cfg and cfg.lang

  i18n.setup('res/reactor/i18n', lang)

  local mode = args[1] or 'run'
  if mode and not subCommands[mode] then
    print(string.format(_T('invalid_command'), mode))
    usage()
    return
  end

  local cfgReadyForRun =
    cfg and
    cfg.lang and
    type(cfg.instances) == 'table' and
    #cfg.instances > 0

  if mode ~= 'setup' and not cfgReadyForRun then
    mode = 'setup'
    print(_T('no_valid_config'))
    event.pull('key_up')
  end

  builtins.setup()
  config.prepare()
  subCommands[mode](options)
  if not options.debug then
    term.clear()
  end
end

main(table.unpack(_argv))

end)
__bundle_register("reactor.window_run", function(require, _LOADED, __bundle_register, __bundle_modules)




local term = palRequire('term')
local event = palRequire('event')
local keyboard = palRequire('keyboard')

local class = require("core.class")
local App = require("ui.app")
local utils = require("core.utils")

local Window = require("ui.window")
local Label = require("ui.label")
local Button = require("ui.button")
local Grid = require("ui.grid")
local Row = require("ui.row")
local Column = require("ui.column")
local Tabs = require("ui.tabs")
local Frame = require("ui.frame")
local Progress = require("ui.progress")

local appVersion = require("version")
local Chamber = require("reactor.chamber")
local config = require("reactor.config")

local ReactorUI = class(Frame.class)

function ReactorUI:init(super, reactor)
  super.init(reactor.i.name)

  self.reactor = reactor

  self.lblStatus = Label(""):size(nil, 1)
  self.lblTemp = Label("0%"):size(4, 1)
  self.prgTemp = Progress(0):size(nil, 1)

  local inner = Column({
    Row({
      self.lblStatus,
      self.lblTemp,
    }):size(nil, 1),
    self.prgTemp
  })

  self:addSubview(inner)
  reactor:setDelegate(self)
end

function ReactorUI:onReactorUpdate()
  local reactor = self.reactor
  local temp = reactor:temperature()

  self.lblStatus:setText(reactor:statusDescription())
  self.lblTemp:setText(tostring(math.floor(temp * 100)) .. "%")
  self.prgTemp:setValue(temp)
end

local function buildUI(reactors)
  local title = Label(string.format(_T('title_monitor_app'), appVersion)):size(nil, 1)

  local main = Grid()
  for _, reactor in ipairs(reactors) do
    local rcUI = ReactorUI:new(reactor):size(nil, 4)
    main:addSubview(rcUI)
  end

  local status = Label(_T('keyboard_tips_run')):size(nil, 1)

  local root = Column({
      title,
      main,
      status
  })
  return {
    root = root,
  }
end

local alwaysOn = {
  getInput = function() return true end,
}

local MonitorWindow = class(Window)

function MonitorWindow:onLoad()
  self.running = false

  local rawConfig = config.get()
  local globalControl = alwaysOn
  if rawConfig.global_control then 
    globalControl = config.instantiateControl(rawConfig.global_control)
  end
  self.globalControl = globalControl

  local reactors = {}
  for i, cfg in ipairs(rawConfig.instances) do
    local instance = config.instantiate(cfg)
    local rc = Chamber:new(instance)
    rc:attachTo(self.app.runloop)
    reactors[i] = rc
  end
  self.reactors = reactors

  term.clear()
  self.ui = buildUI(self.reactors).root
end

function MonitorWindow:startReactors()
  self.running = true
  if self.globalControl:getInput() then
    self:startReactorsInner()
  end
end

function MonitorWindow:startReactorsInner()
  for _, reactor in ipairs(self.reactors) do
    reactor:start()
  end
end

function MonitorWindow:stopReactors()
  self.running = false
  self:stopReactorsInner()
end

function MonitorWindow:stopReactorsInner()
  for _, reactor in ipairs(self.reactors) do
    reactor:stop()
  end
end

-- Event handlers

function MonitorWindow:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.q then
    self:stopReactors()
    self:dismiss()
  elseif keycode == keyboard.keys.r then
    self:startReactors()
  elseif keycode == keyboard.keys.s then
    self:stopReactors()
  end
end

function MonitorWindow:on_redstone_changed(device, side, oldValue, newValue, color)
  debugLog('redstone changed, global control is', self.globalControl:getInput())
  if not self.running then
    return
  end
  if self.globalControl:getInput() then
    self:startReactorsInner()
  else
    self:stopReactorsInner()
  end
end

return MonitorWindow

end)
__bundle_register("reactor.config", function(require, _LOADED, __bundle_register, __bundle_modules)


local utils = require("core.utils")
local builtins = require("reactor.builtins")
local reactorControl = require("reactor.reactor_control")

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

end)
__bundle_register("reactor.reactor_control", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")

local component = palRequire('component')

local AdapterReactorControl = class()

function AdapterReactorControl:init(_, rcproxy)
  self.rc = rcproxy
  self.rc.setActive(false)
  self.enabled = false
end

function AdapterReactorControl:enable()
  if not self.enabled then
    self.rc.setActive(true)
    self.enabled = true
  end
end

function AdapterReactorControl:disable()
  if self.enabled then
    self.rc.setActive(false)
    self.enabled = false
  end
end

local VanillaReactorControl = class()

function VanillaReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
  self.rs.setOutput(self.side, 0)
  self.enabled = false
end

function VanillaReactorControl:getInput()
  return self.rs.getInput(self.side) ~= 0
end

function VanillaReactorControl:enable()
  if not self.enabled then
    self.rs.setOutput(self.side, 15)
    self.enabled = true
  end
end

function VanillaReactorControl:disable()
  if self.enabled then
    self.rs.setOutput(self.side, 0)
    self.enabled = false
  end
end

local BundledReactorControl = class()

function BundledReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
  self.color = cfg.color
  self.rs.setBundledOutput(self.side, self.color, 0)
  self.enabled = false
end

function BundledReactorControl:getInput()
  return self.rs.getBundledInput(self.side, self.color) ~= 0
end

function BundledReactorControl:enable()
  if not self.enabled then
    self.rs.setBundledOutput(self.side, self.color, 15)
    self.enabled = true
  end
end

function BundledReactorControl:disable()
  if self.enabled then
    self.rs.setBundledOutput(self.side, self.color, 0)
    self.enabled = false
  end
end

return {
  Adapter = AdapterReactorControl,
  Vanilla = VanillaReactorControl,
  Bundled = BundledReactorControl,
}

end)
__bundle_register("core.class", function(require, _LOADED, __bundle_register, __bundle_modules)





local function findImplClass(class, method)
  local currentClass = class
  while currentClass do
    if rawget(currentClass, method) then
      return currentClass
    end
    currentClass = getmetatable(currentClass)
  end
  return nil
end

-- Forward declaration for recursive calls of functions below.
local invokeSuper


local function createSuper(object, class)
  local base = getmetatable(class) or {}
  local superMt = {
    __index = function(_, method)
      if type(base[method]) == 'function' then
        return function(...)
          invokeSuper(object, base, method, ...)
        end
      end
      return nil
    end
  }
  return setmetatable({}, superMt)
end


invokeSuper = function(object, superClass, method, ...)
  local base = findImplClass(superClass, method)
  if base then
    local super = createSuper(object, base)
    base[method](object, super, ...)
  end
end

-- A root class to prevent subclasses invoke `super.init()` unexpectedly.
local ObjectClass = {
  init = function() end
}


local function makeClass(base)
  local class = {}
  class.__index = class
  setmetatable(class, base or ObjectClass)

  -- We may want a super object for every instant method. However
  -- this brings more overhead, since OpenOS has limited "hardware"
  -- resource, we only support a super object for the `init` method.
  -- For other methods, using `Base.method(self, ...)` is needed.
  function class:new(...)
    local object = setmetatable({}, class)
    local implClass = findImplClass(class, 'init')

    if implClass then
      local initMethod = rawget(implClass, 'init')
      initMethod(object, createSuper(object, implClass), ...)
    end
    return object
  end

  return class
end

return makeClass

end)
__bundle_register("reactor.builtins", function(require, _LOADED, __bundle_register, __bundle_modules)


local builtins = {}

function builtins.setup()
  local schemas = {
    {
      name = 'builtin.vacuum',
      displayName = _T('schema_name_vacuum'),
      size = {
        w = 9,
        h = 6,
      },
      count = 54,
      layout = {
        'B', 'A', 'A', 'A', 'B', 'A', 'A', 'B', 'A',
        'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A',
        'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A', 'A',
        'A', 'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B',
        'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A',
        'A', 'B', 'A', 'A', 'B', 'A', 'A', 'A', 'B'
      }
    },
    {
      name = 'builtin.single',
      displayName = _T('schema_name_single'),
      size = {
        w = 9,
        h = 6,
      },
      count = 54,
      layout = {
        'A'
      }
    }
  }

  local items = {
    { id = 'gregtech:gt.rodUranium', reusable = true, },
    { id = 'gregtech:gt.rodUranium2', reusable = true, },
    { id = 'gregtech:gt.rodUranium4', reusable = true, },
    { id = 'gregtech:gt.rodThorium', reusable = true, },
    { id = 'gregtech:gt.rodThorium2', reusable = true, },
    { id = 'gregtech:gt.rodThorium4', reusable = true, },
    { id = 'gregtech:gt.rodMOX', reusable = true, },
    { id = 'gregtech:gt.rodMOX2', reusable = true, },
    { id = 'gregtech:gt.rodMOX4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah2', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah4', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium2', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium4', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium2', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium4', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium2', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium4', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium2', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria2', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria4', reusable = true, },
    { id = 'gregtech:gt.rodTiberium', reusable = true, },
    { id = 'gregtech:gt.rodTiberium2', reusable = true, },
    { id = 'gregtech:gt.rodTiberium4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah32', reusable = true, },
    { id = 'gregtech:gt.rodGlowstone', reusable = true, },
    { id = 'gregtech:gt.60k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.60k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.540k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.1080k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.neutroniumHeatCapacitor', reusable = false, },
    { id = 'IC2:reactorVentCore', reusable = true, },
  }

  local reuseableItems = {}
  for _, itemInfo in ipairs(items) do
    reuseableItems[itemInfo.id] = itemInfo.reusable
  end

  local function isReusable(item)
    return reuseableItems[item] == true
  end

  local checks = {
    noCheck = function() return false end,
    damageLess = function(threshold)
      return function(item)
        if item.damage == nil then
          return false
        end

        local t = item.maxDamage * threshold
        return (item.maxDamage - item.damage) <= t
      end
    end
  }

  builtins.schemas = schemas
  builtins.items = items
  builtins.isReusable = isReusable
  builtins.check = checks
end

return builtins

end)
__bundle_register("core.utils", function(require, _LOADED, __bundle_register, __bundle_modules)


local serialization = palRequire('serialization')
local computer = palRequire('computer')
local colors = palRequire('colors')

local function debugLog(...)
  local up = computer.uptime()
  local ts = string.format('[%f]', up)
  local args = table.pack(...)
  table.insert(args, '\r')
  print(ts, table.unpack(args))
end

local function loadSerializedObject(filename)
  local f = io.open(filename)
  if not f then return nil end
  local s = f:read('a')
  f:close()

  return serialization.unserialize(s)
end

local function saveSerializedObject(filename, value)
  local s = serialization.serialize(value)
  local f = io.open(filename, 'w')
  f:write(s)
  f:close()
end

local function bind(f, ...)
  local boundArgs = table.pack(...)
  return function(...)
    local args = table.pack(...)
    for i = 1, #args do
      table.insert(boundArgs, args[i])
    end
    f(table.unpack(boundArgs))
  end
end

local function copy(obj)
  if type(obj) ~= 'table' then
    return obj
  end
  local copied = {}
  for k, v in pairs(obj) do
    copied[k] = copy(v)
  end
  return copied
end

local sideNames = {
  'up', 'north', 'south', 'west', 'east', [0] = 'down'
}

local function sideDescription(side)
  return sideNames[side]
end

local function colorDescription(color)
  return colors[color]
end

return {
  loadSerializedObject = loadSerializedObject,
  saveSerializedObject = saveSerializedObject,
  sideDescription = sideDescription,
  colorDescription = colorDescription,
  bind = bind,
  copy = copy,
  debug = debugLog,
}

end)
__bundle_register("reactor.chamber", function(require, _LOADED, __bundle_register, __bundle_modules)




local class = require("core.class")
local utils = require("core.utils")
local builtins = require("reactor.builtins")

local computer = palRequire('computer')

local ReactorChamber = class()

function ReactorChamber:init(_, instance)
  self.i = instance
  self.rlName = 'Reactor:'..instance.name
  self.running = false
  self.state = _T('reactor_state_stopped')
  self.profileName = 'N/A'

  self.heat = 0
  self.maxHeat = 10000

  self:checkTemperature()
end

function ReactorChamber:attachTo(runloop)
  self.rl = runloop
end

function ReactorChamber:setDelegate(delegate)
  self.delegate = delegate
  self.delegate:onReactorUpdate(self)
end

function ReactorChamber:start()
  if self.running then return end
  self.running = true
  self.error = nil
  self.maxHeat = self.i.reactor.getMaxHeat()
  self.rl:enqueueScheduled(self.rlName, 0, utils.bind(self.check, self))
end

function ReactorChamber:stop()
  self.running = false
end

-- For UI presentation.
-- Getting heat from reactor component is indirect method, it will consume
-- 1 game tick, we cache them for UI.
function ReactorChamber:temperature()
  local heat = self.heat
  local maxHeat = self.maxHeat
  return heat / maxHeat, heat, maxHeat
end

function ReactorChamber:statusDescription()
  debugLog('rc: state is' .. self.state)
  return self.state
end


function ReactorChamber:check()
  debugLog('rc check', self.rlName)

  self.error = nil

  local startTime = computer.uptime()

  if not self.running then
    self.i.control:disable()
    self.state = _T('reactor_state_stopped')
    if self.delegate then
      self.delegate:onReactorUpdate(self)
    end
    return
  end

  -- check temp
  self:checkTemperature()
  if self.delegate then
    self.delegate:onReactorUpdate(self)
  end

  if self.error then
    debugLog('rc: checkTemp error', self.error)
    self.running = false
    self.i.control:disable()
    return
  end

  -- check profile
  if self:checkProfile() then
    -- apply profile if needed
    self.i.control:disable()
    if self.error then
      debugLog('rc: checkprofile error', self.error)
      self.state = _T('reactor_state_error'):format(self.error)
      self.running = false
    else
      debugLog('rc: wait for applyProfile')
      self.rl:enqueueScheduled(self.rlName, computer.uptime() + 1.0, utils.bind(self.applyProfile, self))
    end
    return
  end

  self.i.control:enable()
  self.state = _T('reactor_state_running'):format(self.profileName)
  
  -- schedule next check
  local nextCheck = startTime + self.i.interval
  self.rl:enqueueScheduled(self.rlName, nextCheck, utils.bind(self.check, self))
end

function ReactorChamber:checkTemperature()
  local function switchProfile(name)
    local profile = self.i.profiles[name]
    if not profile then
      self.error = string.format(_T('no_profile'), name)
      return
    end
    if self.activeProfile ~= profile then
      self.activeProfile = profile
      self.profileName = _T('profile_name_'..name)
      debugLog('rc: switched to profile '..name)
    end
  end

  local heat = self.i.reactor.getHeat()
  self.heat = heat
  if heat > self.i.maxHeat then
    switchProfile('cooldown')
  elseif heat < self.i.minHeat then
    switchProfile('heatup')
  else
    switchProfile('working')
  end
end


function ReactorChamber:checkProfile()
  local tp = self.i.transposer
  local reactorItems = tp.getAllStacks(tp.itemReactor).getAll()
  local layout = self.activeProfile.layout

  for i = 1, self.activeProfile.count do
    local profileItem = layout[i]
    local reactorItem = reactorItems[i - 1]

    if not reactorItem then
      self.error = _T('profile_count_mismatch')
      return true
    end
    if not reactorItem.name and profileItem then
      -- need insert
      return true
    elseif reactorItem.name and not profileItem then
      -- need remove
      return true
    elseif reactorItem.name and profileItem then
      -- need compare
      if reactorItem.name ~= profileItem.name or profileItem.check(reactorItem) then
        return true
      end
    end
  end
  return false
end


function ReactorChamber:applyProfile()
  if not self.error then
    self.state = _T('reactor_state_applying')
  end
  self.error = nil

  if not self.running then
    self.state = _T('reactor_state_stopped')
    if self.delegate then
      self.delegate:onReactorUpdate(self)
    end
    return
  end

  local tp = self.i.transposer
  local function removeFromReactor(index, name)
    local dst = tp.itemOut
    if builtins.isReusable(name) then
      dst = tp.itemIn
    end
    debugLog(string.format('remove reactor item #%d', index))
    local count = tp.transferItem(tp.itemReactor, dst, 1, index)
    coroutine.yield()
    if count == 0 then
      self.error = _T('output_full')
      return false
    end
    debugLog(string.format('remove reactor item #%d success', index))
    return true
  end

  local function insertIntoReactor(index, name)
    debugLog(string.format('insert %s to reactor slot #%d', name, index))
    local items = tp.getAllStacks(tp.itemIn).getAll()
    coroutine.yield()
    for i = 1, #items do
      local item = items[i - 1]
      if item.name == name then
        local count = tp.transferItem(tp.itemIn, tp.itemReactor, 1, i, index)
        coroutine.yield()
        if count > 0 then
          debugLog(string.format('insert %s to reactor slot #%d success', name, index))
          return true
        end
      end
    end
    debugLog(string.format('insert %s to reactor slot #%d fail', name, index))
    self.error = string.format(_T('item_shortage'), name)
    return false
  end

  local function doProfile()
    local reactorItems = tp.getAllStacks(tp.itemReactor).getAll()
    coroutine.yield()
    local layout = self.activeProfile.layout

    for i = 1, self.activeProfile.count do
      if not self.running then
        self.state = _T('reactor_state_stopped')
        if self.delegate then
          self.delegate:onReactorUpdate(self)
        end
        return
      end
      debugLog(string.format('rc: apply for slot #%d', i))
      local profileItem = layout[i]
      local reactorItem = reactorItems[i - 1]

      if not reactorItem then
        debugLog('reactorItem not exist!')
        self.error = _T('profile_count_mismatch')
        -- profile misconfigured, no need to retry
        self.state = _T('reactor_state_error'):format(self.error)
        if self.delegate then
          self.delegate:onReactorUpdate(self)
        end
        return
      end

      if not reactorItem.name and profileItem then
        -- need insert
        insertIntoReactor(i, profileItem.name)
      elseif reactorItem.name and not profileItem then
        -- need remove
        removeFromReactor(i, reactorItem.name)
      elseif reactorItem.name and profileItem then
        -- need compare
        if reactorItem.name ~= profileItem.name or profileItem.check(reactorItem) then
          local _ = removeFromReactor(i, reactorItem.name) and insertIntoReactor(i, profileItem.name)
        end
      end

      if self.error then
        -- retry after 1s
        debugLog('apply error:', self.error)
        self.state = _T('reactor_state_error'):format(self.error)
        self.rl:enqueueScheduled(self.rlName, computer.uptime() + 1.0, utils.bind(self.applyProfile, self))
        return
      end

      if self.delegate then
        self.delegate:onReactorUpdate(self)
      end
    end

    self.rl:enqueueScheduled(self.rlName, 0, utils.bind(self.check, self))
  end

  self.rl:enqueueIdleYieldable(self.rlName, doProfile)
end

return ReactorChamber

end)
__bundle_register("version", function(require, _LOADED, __bundle_register, __bundle_modules)
return '0.3.0'
end)
__bundle_register("ui.progress", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local UIElement = require("ui.element").class
local wrap = require("ui.wrap_class")

local unicode = palRequire('unicode')
local term = palRequire('term')

local Progress = class(UIElement)

function Progress:init(super, value)
  super.init()
  self.value = value
end

local progressSym = {
  filled = unicode.char(0x2588),
  blank = unicode.char(0x2591)
}

function Progress:draw(gpu)
  local w = self.rect.w
  local left = math.floor(w * self.value)
  local right = w - left

  local str = progressSym.filled:rep(left) .. progressSym.blank:rep(right)
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, str)
end

function Progress:setValue(v)
  if self.value ~= v then
    self.value = v
    self:setNeedUpdate()
  end
end

return wrap(Progress)

end)
__bundle_register("ui.wrap_class", function(require, _LOADED, __bundle_register, __bundle_modules)


local meta = {
  __call = function(class, ...)
    return class.class:new(...)
  end
}

local function wrapUiClass(class)
  local o = {
    class = class
  }
  setmetatable(o, meta)
  return o
end

return wrapUiClass

end)
__bundle_register("ui.element", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local Navigation = require("ui.navigation")
local wrap = require("ui.wrap_class")

local UIElement = class()


function UIElement:init()
  self.rect = { x = 0, y = 0, w = 0, h = 0 }
  self.intrinsicSize = {}
  self.needUpdate = true
end

-- MARK: - Property modifiers


function UIElement:size(w, h)
  self.intrinsicSize.w = w
  self.intrinsicSize.h = h
  return self
end

function UIElement:makeSelectable(selectable)
  self.selectable = selectable
  return self
end

function UIElement:setSelected(state)
  if state ~= self.selected then
    self.selected = state
    self:setNeedUpdate()
  end
end

function UIElement:action(a)
  self._action = a
  return self
end

-- MARK: - Painting


function UIElement:draw(gpu)
  error("UIElement:draw() method should be overriden")
end


function UIElement:clear(gpu)
  gpu.fill(self.rect.x, self.rect.y, self.rect.w, self.rect.h, ' ')
end


function UIElement:update(gpu)
  if self.window and self.needUpdate then
    self.needUpdate = false
    self:draw(gpu)
  end
end


function UIElement:setNeedUpdate()
  self.needUpdate = true
  if self.window then
    self.window:enqueueUpdate(self)
  end
end


function UIElement:moveToWindow(win)
  self.window = win
end


function UIElement:screenPos(x, y)
  return self.rect.x + x, self.rect.y + y
end

-- MARK: - Arrow key navigation support


function UIElement:initSelection(navFrom)
  if self.selectable then
    return self
  end
  return nil
end


function UIElement:handleNavigation(nav)
  if self.parent then
    return self.parent:handleNavigation(nav)
  end
  return nil
end

-- MARK: - Touch screen support


function UIElement:elementAtPoint(x, y)
  if x >= self.rect.x and y >= self.rect.y and x < self.rect.x + self.rect.w and y < self.rect.y + self.rect.h then
    return self
  else
    return nil
  end
end

function UIElement:getAction()
  return self._action
end

-- MARK: - Reserved / unused

function UIElement:keyShortcut(key, action)
  self.keyShortcut = key
  self.keyAction = action
  return self
end

function UIElement:onClick(action)
  self.clickAction = action
  return self
end

return wrap(UIElement)

end)
__bundle_register("ui.navigation", function(require, _LOADED, __bundle_register, __bundle_modules)



local Navigation = {
  up = 1,
  down = 2,
  left = 3,
  right = 4,
}

return Navigation
end)
__bundle_register("ui.frame", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local Container = require("ui.container").class

local unicode = palRequire('unicode')

local borders = {
  tl = unicode.char(0x2552),
  t = unicode.char(0x2550),
  tr = unicode.char(0x2555),
  l = unicode.char(0x2502),
  r = unicode.char(0x2502),
  bl = unicode.char(0x2514),
  b = unicode.char(0x2500),
  br = unicode.char(0x2518),
}


local Frame = class(Container)

function Frame:init(super, title, content)
  super.init()
  self.title = title
  if content then
    self:addSubview(content)
  end
end

function Frame:draw(gpu)
  local w = self.rect.w
  local topCount = (w - 2 - unicode.wlen(self.title))
  local top = borders.tl .. self.title .. borders.t:rep(topCount) .. borders.tr

  local sx, sy = self:screenPos(0, 0)
  gpu.set(sx, sy, top)

  local h = self.rect.h
  for y = 1, h - 2, 1 do
    sx, sy = self:screenPos(0, y)
    gpu.set(sx, sy, borders.l)
    sx, sy = self:screenPos(w - 1, y)
    gpu.set(sx, sy, borders.r)
  end

  sx, sy = self:screenPos(0, h - 1)
  gpu.set(sx, sy, borders.bl .. borders.b:rep(w - 2) .. borders.br)

  local child = self.children[1]
  if child then
    child:draw(gpu)
  end
end

function Frame:layout()
  local child = self.children[1]
  if not child then return end
  child.rect.x = self.rect.x + 1
  child.rect.y = self.rect.y + 1
  child.rect.w = self.rect.w - 2
  child.rect.h = self.rect.h - 2

  if child.children then
    child:layout()
  end
end

return wrap(Frame)

end)
__bundle_register("ui.container", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local UIElement = require("ui.element").class

local Container = class(UIElement)

function Container:init(super, children)
  super.init()
  self.selectionIndex = nil
  self.children = {}
  if children then
    for _, child in ipairs(children) do
      self:addSubview(child)
    end
  end
end

function Container:addSubview(v)
  table.insert(self.children, v)
  v.parent = self
  v:moveToWindow(self.window)
end

function Container:moveToWindow(win)
  self.window = win
  for _, child in ipairs(self.children) do
    child:moveToWindow(win)
  end
end

function Container:draw(gpu)
  for _, child in ipairs(self.children) do
    child:draw(gpu)
    child.needUpdate = false
  end
end

function Container:initSelection(navFrom)
  for i, child in ipairs(self.children) do
    local selected = child:initSelection(navFrom)
    if selected then
      self.selectionIndex = i
      return selected
    end
  end
  return nil
end

function Container:trySelectPrevChild(nav)
  local nextSelectionIndex = self.selectionIndex - 1
  while nextSelectionIndex > 0 do
    local nextSelectedElement = self.children[nextSelectionIndex]:initSelection(nav)
    if nextSelectedElement then
      self.selectionIndex = nextSelectionIndex
      return nextSelectedElement
    end
    nextSelectionIndex = nextSelectionIndex - 1
  end
  return Container.handleNavigation(self, nav)
end

function Container:trySelectNextChild(nav)
  local nextSelectionIndex = self.selectionIndex + 1
  while nextSelectionIndex <= #self.children do
    local nextSelectedElement = self.children[nextSelectionIndex]:initSelection(nav)
    if nextSelectedElement then
      self.selectionIndex = nextSelectionIndex
      return nextSelectedElement
    end
    nextSelectionIndex = nextSelectionIndex + 1
  end
  return Container.handleNavigation(self, nav)
end

function Container:handleNavigation(nav)
  if self.parent then
    local next = self.parent:handleNavigation(nav)
    if next then
      -- navigated outside of this container
      self.selectionIndex = nil
      return next
    end
  end
  return nil
end

function Container:elementAtPoint(x, y)
  for _, child in ipairs(self.children) do
    if child:elementAtPoint(x, y) then
      return child
    end
  end
  return UIElement.elementAtPoint(self, x, y)
end

function Container:layout(w, h)
  error("Override me")
end

return wrap(Container)

end)
__bundle_register("ui.tabs", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")

local wrap = require("ui.wrap_class")
local Row = require("ui.row")
local Column = require("ui.column").class
local Label = require("ui.label")

local unicode = palRequire('unicode')
local term = palRequire('term')

local symbols = {
  normal = unicode.char(0x2500),
  highlight = unicode.char(0x2580),
}

local Tabs = class(Column)

function Tabs:init(super, tabs)
  super.init({})
  self.tabs = tabs
  self.selectedTabIndex = 1

  local tabRow = Row():size(nil, 2)
  self.tabRow = tabRow
  for i, item in ipairs(tabs) do
    local label = Label(item[1]):size(nil, 1):makeSelectable(true)
    tabRow:addSubview(label)
  end
  
  local origInitSelection = tabRow.initSelection
  local origHandleNavigation = tabRow.handleNavigation
  local outerSelf = self

  -- override the tabRow instance methods
  function tabRow:initSelection(nav)
    -- always select the current tab index
    self.selectionIndex = outerSelf.selectedTabIndex
    return self.children[self.selectionIndex]
  end

  function tabRow:handleNavigation(nav)
    local result = origHandleNavigation(self, nav)
    if self.selectionIndex then
      outerSelf:selectTab(self.selectionIndex)
    end
    return result
  end

  self:addSubview(tabRow)
  self:addSubview(tabs[1][2])
end

function Tabs:selectTab(index)
  if index == self.selectedTabIndex then
    return
  end
  self.selectedTabIndex = index
  local oldChild = self.children[2]
  local newChild = self.tabs[index][2]

  self.children[2] = newChild
  oldChild:moveToWindow(nil)
  newChild.parent = self
  newChild:moveToWindow(self.window)
  
  self:layout()
  self:setNeedUpdate()
end

function Tabs:draw(gpu)
  self:clear(gpu)
  Column.draw(self, gpu)
  self:drawTabLine(gpu)
end

function Tabs:drawTabLine(gpu)
  local selectedLabel = self.tabRow.children[self.selectedTabIndex]
  if not selectedLabel then
    return
  end

  local rowRect = self.tabRow.rect
  local rect = selectedLabel.rect
  gpu.set(rowRect.x, rowRect.y + 1, symbols.normal:rep(rowRect.w))
  gpu.set(rect.x, rect.y + 1, symbols.highlight:rep(rect.w))
end

return wrap(Tabs)

end)
__bundle_register("ui.label", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local UIElement = require("ui.element").class
local utils = require("ui.utils")

local term = palRequire('term')

local Label = class(UIElement)

function Label:init(super, text)
  super.init()
  self.text = text
end

function Label:draw(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end
  self:clear(gpu)
  -- TODO: support line wrapping
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, self.text)

  if self.selected then
    utils.setNormal(gpu)
  end
end

function Label:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

return wrap(Label)

end)
__bundle_register("ui.utils", function(require, _LOADED, __bundle_register, __bundle_modules)


local utils = {}

function utils.setHighlight(gpu)
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x0)
end

function utils.setNormal(gpu)
  gpu.setBackground(0x0)
  gpu.setForeground(0xffffff)
end

return utils

end)
__bundle_register("ui.column", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local directionContainerLayout = require("ui.layout")
local Navigation = require("ui.navigation")
local wrap = require("ui.wrap_class")
local Container = require("ui.container").class

local Column = class(Container)

function Column:layout()
  directionContainerLayout(self, 'h', 'w', 'y', 'x')
  -- print('-- column layout')
  -- for i, c in ipairs(self.children) do
  --   print(string.format('children %d: x=%d, y=%d, w=%d, h=%d', i, c.rect.x, c.rect.y, c.rect.w, c.rect.h))
  -- end
end

function Column:initSelection(navFrom)
  if navFrom == Navigation.up then
    -- reverse order
    for i = #self.children, 1, -1 do
      local selected = self.children[i]:initSelection(navFrom)
      if selected then
        return selected
      end
    end
    return nil
  end

  return Container.initSelection(self, navFrom)
end

function Column:handleNavigation(nav)
  if nav == Navigation.up then
    return self:trySelectPrevChild(nav)
  elseif nav == Navigation.down then
    return self:trySelectNextChild(nav)
  end
  return Container.handleNavigation(self, nav)
end

return wrap(Column)

end)
__bundle_register("ui.layout", function(require, _LOADED, __bundle_register, __bundle_modules)


local function directionContainerLayout(c, main, cross, mainOffset, crossOffset)
  local w = c.rect[main]

  local fixed = 0
  local nFlex = 0
  for i, child in ipairs(c.children) do
    if child.intrinsicSize[main] then
      fixed = fixed + child.intrinsicSize[main]
    else
      nFlex = nFlex + 1
    end
  end
  local unit = 0
  if nFlex > 0 then unit = (w - fixed) // nFlex end

  local x = 0
  for i, child in ipairs(c.children) do
    local childMain, childCross
    if child.intrinsicSize[main] then
      childMain = child.intrinsicSize[main]
    else
      childMain = unit
    end
    childCross = child.intrinsicSize[cross] or c.rect[cross]

    child.rect[mainOffset] = c.rect[mainOffset] + x
    child.rect[crossOffset] = c.rect[crossOffset]
    child.rect[main] = childMain
    child.rect[cross] = childCross

    if child.layout then
      child:layout()
    end

    x = x + childMain
  end
end

return directionContainerLayout

end)
__bundle_register("ui.row", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local directionContainerLayout = require("ui.layout")
local Navigation = require("ui.navigation")
local wrap = require("ui.wrap_class")
local Container = require("ui.container").class

local Row = class(Container)

function Row:layout()
  directionContainerLayout(self, 'w', 'h', 'x', 'y')
  -- print('-- row layout')
  -- for i, c in ipairs(self.children) do
  --   print(string.format('children %d: x=%d, y=%d, w=%d, h=%d', i, c.rect.x, c.rect.y, c.rect.w, c.rect.h))
  -- end
end

function Row:initSelection(navFrom)
  if navFrom == Navigation.left then
    -- reverse order
    for i = #self.children, 1, -1 do
      local selected = self.children[i]:initSelection(navFrom)
      if selected then
        self.selectionIndex = i
        return selected
      end
    end
    return nil
  end

  return Container.initSelection(self, navFrom)
end

function Row:handleNavigation(nav)
  if nav == Navigation.left then
    return self:trySelectPrevChild(nav)
  elseif nav == Navigation.right then
    return self:trySelectNextChild(nav)
  end
  return Container.handleNavigation(self, nav)
end

return wrap(Row)

end)
__bundle_register("ui.grid", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local Container = require("ui.container").class

local Grid = class(Container)

function Grid:layout()
  if #self.children == 0 then return end
  local child1 = self.children[1]

  local w = self.rect.w
  local h = self.rect.h
  local cw = child1.intrinsicSize.w
  local ch = child1.intrinsicSize.h

  local nr = 1
  local nc = 1

  if cw == nil and ch == nil then
    error("Grid element must have at least 1 intrinsic size")
  end

  if cw == nil then
    while math.ceil(#self.children / nc) * ch > h do nc = nc + 1 end
    cw = w // nc
  end

  if ch == nil then
    while math.ceil(#self.children / nr) * cw > w do nr = nr + 1 end
    ch = h // nr
  end

  nc = w // cw
  nr = math.ceil(#self.children / nc)

  for i, child in ipairs(self.children) do
    local x = (i - 1) % nc
    local y = (i - 1) // nc

    child.rect.x = self.rect.x + x * cw
    child.rect.y = self.rect.y + y * ch
    child.rect.w = cw
    child.rect.h = ch

    if child.children then
      child:layout()
    end
  end
end

return wrap(Grid)

end)
__bundle_register("ui.button", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local uiUtils = require("ui.utils")
local UIElement = require("ui.element").class

local term = palRequire('term')

local Button = class(UIElement)

function Button:init(super, text)
  super.init()
  self.selectable = true
  self.text = text
  self.active = false
end

function Button:draw(gpu)
  if self.selected then
    uiUtils.setHighlight(gpu)
  end

  self:clear(gpu)
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, self.text)

  if self.selected then
    uiUtils.setNormal(gpu)
  end
end

function Button:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

return wrap(Button)

end)
__bundle_register("ui.window", function(require, _LOADED, __bundle_register, __bundle_modules)


local term = palRequire('term')
local keyboard = palRequire('keyboard')

local class = require("core.class")
local Navigation = require("ui.navigation")

local Window = class()

function Window:init(_)
  self.updateQueue = {}
end


function Window:onLoad()
  error('Should override Window:onLoad()')
end


function Window:onUnload()
end

function Window:handleEvent(name, ...)
  if self.presentedWindow then
    self.presentedWindow:handleEvent(name, ...)
    return
  end

  local handler = self['on_' .. name]
  if handler then
    handler(self, ...)
  end
end


function Window:present(aWindow, resultHandler)
  local gpu = term.gpu()

  local w, h = gpu.getResolution()
  local bg = gpu.allocateBuffer(w, h)
  gpu.bitblt(bg, 1, 1, w, h, 0)

  self.presentedWindow = aWindow
  self.app:present(
    aWindow,
    function(...)
      self.presentedWindow = nil
      gpu.bitblt(0, 1, 1, w, h, bg)
      gpu.freeBuffer(bg)
      self.ui:setNeedUpdate()
      if resultHandler then
        resultHandler(...)
      end
    end
  )
end


function Window:dismiss(...)
  if self.dismissHandler then
    self.dismissHandler(...)
  end
end

function Window:enqueueUpdate(element)
  table.insert(self.updateQueue, element)
  self.app:enqueueUpdate()
end

function Window:update(gpu)
  if self.presentedWindow then
    self.presentedWindow:update(gpu)
    return
  end

  local q = self.updateQueue
  self.updateQueue = {}

  for _, e in pairs(q) do
    e:update(gpu)
  end
end

-- MARK: - keyboard navigation

function Window:initSelection()
  local selectedElement = self.ui:initSelection(nil)
  self.selectedElement = selectedElement
  if selectedElement then
    self.selectedElement:setSelected(true)
  end
end

function Window:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.enter and self.selectedElement then
    local actionParams = table.pack(self.selectedElement:getAction())
    if #actionParams >= 1 then
      local action = table.remove(actionParams, 1)
      if self[action] then
        self[action](self, table.unpack(actionParams))
        return
      end
    end
  end

  local navigation = nil
  if keycode == keyboard.keys.up then
    navigation = Navigation.up
  elseif keycode == keyboard.keys.down then
    navigation = Navigation.down
  elseif keycode == keyboard.keys.left then
    navigation = Navigation.left
  elseif keycode == keyboard.keys.right then
    navigation = Navigation.right
  end

  if navigation and self.selectedElement then
    local nextElement = self.selectedElement:handleNavigation(navigation)
    if nextElement then
      self.selectedElement:setSelected(false)
      nextElement:setSelected(true)
      self.selectedElement = nextElement
    end
  end
end

return Window
end)
__bundle_register("ui.app", function(require, _LOADED, __bundle_register, __bundle_modules)




local class = require("core.class")
local utils = require("core.utils")
local Runloop = require("core.runloop")

local term = palRequire('term')

local App = class()

-- MARK: - App methods

function App:init(_, options)
  self.runloop = Runloop:new()
  self.options = options or {}
  self.hasUpdates = false
  App.shared = self
end

function App:start(window)
  self.window = window
  self:app_setup()
  self.runloop:addEventHandler(self)
  if not self.options.debug and self.window then
    self:present(window, utils.bind(self.stop, self))
  else --for debug
    window.app = self
    window.dismissHandler = utils.bind(self.stop, self)
    window:onLoad()
  end
  self.runloop:run()
end

function App:stop(reload)
  if reload then
    self:present(self.window, utils.bind(self.stop, self))
    return
  end
  self.runloop:stop()
end

function App:present(window, handler)
  window.app = self
  self.runloop:enqueueIdle(
    'App_UI',
    function()
      window.dismissHandler = handler
      window:onLoad()
      -- layout
      local w, h, x, y = term.getViewport()
      if window.preferredSize then
        local newW = math.min(w, window.preferredSize.w)
        local newH = math.min(h, window.preferredSize.h)
        local newX = (x + 1) + (w - newW) // 2
        local newY = (y + 1) + (h - newH) // 2
        window.ui.rect = {x = newX, y = newY, w = newW, h = newH }
      else
        window.ui.rect = { x = x + 1, y = y + 1, w = w, h = h }
      end
      window.ui:layout()
      window.ui:moveToWindow(window)
      window:initSelection()
      window.ui:setNeedUpdate()
    end
  )
end

function App:handleEvent(name, ...)
  if not name then return end

  debugLog(name, ...)
  self.window:handleEvent(name, ...)
end

function App:enqueueUpdate()
  if self.hasUpdates then
    return
  end
  self.hasUpdates = true

  self.runloop:enqueueIdle(
    'App_UI',
    function()
      self.hasUpdates = false
      if self.window then
        self.window:update(term.gpu())
      end
    end
  )
end

-- MARK: - Subclass overrides

function App:app_setup()
end

-- MARK: - Exports

return App

end)
__bundle_register("core.runloop", function(require, _LOADED, __bundle_register, __bundle_modules)




local class = require("core.class")

local computer = palRequire('computer')
local event = palRequire('event')

-- Maximum loop execution time between system yields, in seconds.
--
-- A system yield will be inserted if runloop exceeds this time when
-- running.
--
-- GT:NH sets it to 5.0 seconds, we slightly tune this down for safety.
local kSystemYield = 3.0

local kTaskQueueEmpty = 0
local kTaskExecuted = 1
local kTaskNeedWait = 2

local Runloop = class()

function Runloop:init(super)
  -- scheduled task queue
  self.tq = {}
  -- idle task queue
  self.iq = {}
  -- event handlers
  self.eventHandlers = {}

  self.running = false
end

function Runloop:run()
  local deadline = kSystemYield
  local startTime = computer.uptime()

  self.running = true

  while self.running or #self.tq > 0 or #self.iq > 0 do
    local result, timeout = self:runOneTask()

    if result == kTaskExecuted then
      local endTime = computer.uptime()
      if endTime - startTime >= kSystemYield then
        os.sleep(0)
        startTime = computer.uptime()
      end
    else
      local e = table.pack(event.pull(timeout))
      startTime = computer.uptime()
      self:handleEvent(table.unpack(e))
    end
  end
end

function Runloop:stop()
  self.running = false
end

function Runloop:addEventHandler(handler)
  table.insert(self.eventHandlers, handler)
end

function Runloop:enqueueScheduled(name, target, fn)
  local idx = #self.tq

  while idx > 0 do
    if self.tq[idx].target <= target then
      break
    end
    idx = idx - 1
  end

  local task = {
    name = name,
    run = fn,
    target = target
  }
  table.insert(self.tq, idx + 1, task)
end

function Runloop:enqueueIdle(name, fn)
  local task = {
    name = name,
    run = fn,
  }
  table.insert(self.iq, task)
end

function Runloop:enqueueIdleYieldable(name, fn)
  local co = coroutine.create(fn)
  local function wrapped()
    if coroutine.resume(co) then
      self:enqueueIdle(name, wrapped)
    end
  end
  self:enqueueIdle(name, wrapped)
end

function Runloop:runOneTask()
  Runloop.current = self
  local task
  local nextScheduleTime = nil

  if #self.tq > 0 then
    if computer.uptime() >= self.tq[1].target then
      task = table.remove(self.tq, 1)
      task.run()
      return kTaskExecuted
    else
      nextScheduleTime = self.tq[1].target - computer.uptime()
    end
  end

  if #self.iq > 0 then
    task = table.remove(self.iq, 1)
    task.run()
    return kTaskExecuted
  end
  return kTaskQueueEmpty, nextScheduleTime
end

function Runloop:handleEvent(name, ...)
  for _, handler in pairs(self.eventHandlers) do
    handler:handleEvent(name, ...)
  end
end

return Runloop

end)
__bundle_register("reactor.window_setup", function(require, _LOADED, __bundle_register, __bundle_modules)




local term = palRequire('term')
local keyboard = palRequire('keyboard')

local class = require("core.class")
local App = require("ui.app")
local utils = require("core.utils")
local i18n = require("core.i18n")

local Window = require("ui.window")
local Label = require("ui.label")
local Button = require("ui.button")
local Grid = require("ui.grid")
local Row = require("ui.row")
local Column = require("ui.column")
local Tabs = require("ui.tabs")
local Table = require("ui.table")

local appVersion = require("version")
local config = require("reactor.config")
local builtins = require("reactor.builtins")
local Alert = require("ui.window_alert")
local SelectWindow = require("ui.window_select")
local RedstoneWindow = require("reactor.window_redstone")
local InstanceWindow = require("reactor.window_instance")
local SchemaWindow = require("reactor.window_schema")
local reactorUtils = require("reactor.utils")

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
  local cfg = config.get()
  if not cfg then
    cfg = makeDefaultConfig()
    config.set(cfg)
  end
  self.config = cfg

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
  return Table({
    {
      { display = _T('save_and_exit'), action = 'saveAndExit' }
    },
    {
      { display = _T('discard_and_exit'), action = 'discardAndExit' }
    }
  }, {
    showBorders = false,
    rows = {
      n = 2,
    },
    columns = {
      n = 1,
      defaultWidth = 30
    }
  })
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
    self:discardAndExit()
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
        self.generalTabTable.contents[2][2].display = reactorUtils.redstoneDescription(self.config.global_control)
        self.generalTabTable:setNeedUpdate()
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
        self:refreshSchemas()
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
  local win = InstanceWindow:new(instance, self.config.schemas)
  self:present(
    win,
    function(editOk, newInstance)
      if editOk then
        self.config.instances[index] = newInstance
        self:refreshInstances()
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

function SetupWindow:saveAndExit()
  local backupName = config.backup()
  config.set(self.config)
  config.save()

  if backupName then
    local alert = Alert:new(
      _T('backup_saved'), 
      string.format(_T('prompt_backup'), backupName)
    )
    self:present(
      alert,
      function(result)
        self:dismiss()
      end
    )
  else
    self:dismiss()
  end
end

function SetupWindow:discardAndExit()
  local alert = Alert:new(
    _T('confirm_exit'), 
    string.format(_T('prompt_confirm_exit')),
    Alert.Ok | Alert.Cancel
  )
  self:present(
    alert,
    function(result)
      if result == Alert.Ok then
        self:dismiss()
      end
    end
  )
end

function SetupWindow:reloadLanguage(code)
  i18n.reload(code)
  builtins.setup()
  self:dismiss(true)
end

return SetupWindow

end)
__bundle_register("reactor.utils", function(require, _LOADED, __bundle_register, __bundle_modules)


local utils = require("core.utils")
local builtins = require("reactor.builtins")

local function redstoneDescription(cfg)
  if not cfg then 
    return _T('redstone_mode_none')
  end

  local desc = _T('redstone_mode_'..cfg.mode)
  if cfg.mode == 'vanilla' or cfg.mode == 'bundled' then
    desc = desc .. ',' .. _T(utils.sideDescription(cfg.side))
  end
  return desc
end

local function transposerDescription(cfg)
  if not cfg then
    return _T('not_configured')
  end

  return cfg.address
end

local function profileDescription(cfg)
  if not cfg then
    return _T('not_configured')
  end
  
  local schemaName = cfg.schema
  for _, schema in pairs(builtins.schemas) do
    if schema.name == schemaName then
      schemaName = schema.displayName
      break
    end
  end
  return schemaName
end

local function changeConditionDescription(cfg)
  if cfg then
    if cfg.change == 'none' then
      return _T('change_condition_none')
    elseif cfg.change == 'damage_less' then
      return _T('change_condition_damage_less')
    end
  end
  return _T('not_configured')
end

return {
  redstoneDescription = redstoneDescription,
  transposerDescription = transposerDescription,
  profileDescription = profileDescription,
  changeConditionDescription = changeConditionDescription,
}
end)
__bundle_register("reactor.window_schema", function(require, _LOADED, __bundle_register, __bundle_modules)


local keyboard = palRequire('keyboard')

local class = require("core.class")
local utils = require("core.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
local InputWindow = require("ui.window_input")
require("reactor.window+select_component")

local function makeDefaultConfig()
  return {
    name = 'new_config',
    size = { w = 9, h = 6 },
    count = 54,
    layout = {}
  }
end

local SchemaWindow = class(Window)

function SchemaWindow:init(super, config, isBuiltin)
  super.init()
  self.config = utils.copy(config) or makeDefaultConfig()
  self.isBuiltin = isBuiltin

  self.tblCfgOptions = {
    showBorders = false,
    columns = {
      n = 2,
      defaultWidth = 16,
      [1] = {
        width = 8,
        selectable = false,
      },
    },
    rows = {
      n = 2
    }
  }
  self.tblLayoutOptions = {
    showBorders = true,
    columns = {
        n = config.size.w,
        defaultWidth = 2,
    },
    rows = {
        n = config.size.h,
    }
  }
  self.tblLayoutContents = {}

  self:makeTableContents()
end

function SchemaWindow:onLoad()
  local left = Table(self.tblCfgContents, self.tblCfgOptions):size(24)
  self.left = left
  local right = Table(self.tblLayoutContents, self.tblLayoutOptions)
  self.right = right
  if self.isBuiltin then
    left:makeSelectable(false)
    right:makeSelectable(false)
  end

  self.ui = Frame(
    _T('schema_config'),
    Column({
      Row({
        left,
        Separator.vertical(),
        right,
      }),
      Separator.horizontal(),
      Row({
        Button(_T('ok')):action('clickedOk'),
        Button(_T('cancel')):action('clickedCancel'),
      }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 60, h = 17 }
end

function SchemaWindow:makeTableContents()
  self.tblCfgContents = {
    {
      { display = _T('name') },
      { display = self.config.name, action = 'editName' }
    },
    {
      { display = _T('width') },
      { display = _T(tostring(self.config.size.w)), action = 'editWidth' }
    },
    {
      { display = _T('height') },
      { display = tostring(self.config.size.h), action = 'editHeight' }
    },
  }
  self.tblCfgOptions.rows.n = #self.tblCfgContents

  local w = self.config.size.w
  local h = self.config.size.h
  local layout = self.config.layout

  for i = 1, h do
    self.tblLayoutContents[i] = {}
    for j = 1, w do
      local idx = (i - 1) * w + j
      self.tblLayoutContents[i][j] = {
        display = layout[idx]
      }
    end
  end

  self.tblLayoutOptions.columns.n = w
  self.tblLayoutOptions.rows.n = h
end

function SchemaWindow:editName()
  local win = InputWindow:new(_T('schema_name'), _T('input_prompt_schema_name'))
  self:present(
    win,
    function(result)
      self.config.name = result
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
    end
  )
end

function SchemaWindow:editWidth()
  local win = InputWindow:new(_T('schema_width'), _T('input_prompt_schema_width'))
  self:present(
    win,
    function(result)
      self.config.size.w = tonumber(result)
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right:reload()
    end
  )
end

function SchemaWindow:editHeight()
  local win = InputWindow:new(_T('schema_height'), _T('input_prompt_schema_height'))
  self:present(
    win,
    function(result)
      self.config.size.h = tonumber(result)
      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right:reload()
    end
  )
end

function SchemaWindow:clickedOk()
  self:dismiss(true, self.config)
end

function SchemaWindow:clickedCancel()
  self:dismiss(false)
end

function SchemaWindow:editTableInplace(char)
  local idx = (self.right.selectedRow - 1) * self.config.size.w + self.right.selectedColumn
  self.config.layout[idx] = char
  self:makeTableContents()
  -- no changes to table config, no reload needed
  self.right:setNeedUpdate()
end

function SchemaWindow:on_key_down(device, key, keycode)
  if self.selectedElement == self.right then
    if (key >= 0x41 and key <= 0x5a) or (key >= 0x61 and key <= 0x7a) then
      -- Alphabet keys inside table
      self:editTableInplace(string.char(key):upper())
      return
    elseif keycode == keyboard.keys.back then
      self:editTableInplace(nil)
      return
    end
  end
  Window.on_key_down(self, device, key, keycode)
end

return SchemaWindow
end)
__bundle_register("reactor.window+select_component", function(require, _LOADED, __bundle_register, __bundle_modules)


local component = palRequire('component')

local Window = require("ui.window")
local Select = require("ui.window_select")

function Window:selectComponent(name, callback)
  local devices = component.list(name)
  local choices = {}
  for k, _ in pairs(devices) do
    table.insert(choices, k)
  end

  if #choices == 0 then
    -- TODO: alert
    return
  end

  local selectAddress = Select:new(_T('component_address'), choices)

  self:present(
    selectAddress, 
    function(result)
      callback(choices[result])
    end
  )
end
end)
__bundle_register("ui.window_select", function(require, _LOADED, __bundle_register, __bundle_modules)


local keyboard = palRequire('keyboard')
local unicode = palRequire('unicode')

local class = require("core.class")

local Window = require("ui.window")
local Frame = require("ui.frame")
local Table = require("ui.table")

local Select = class(Window)

function Select:init(super, title, options)
  super.init()
  self.title = title or _T('select_title')
  self.options = options
end

function Select:onLoad()
  local maxWidth = unicode.wlen(self.title)
  for _, option in ipairs(self.options) do
    maxWidth = math.max(maxWidth, unicode.wlen(option))
  end

  local tableContents = self:makeTableContents()
  local tableCfg = {
    showBorders = false,
    columns = {
      n = 1,
      defaultWidth = maxWidth
    },
    rows = {
      n = #self.options
    }
  }

  local main = Table(tableContents, tableCfg)
  self.main = main

  self.ui = Frame(
    self.title,
    main
  )

  self.preferredSize = { w = maxWidth + 3, h = #self.options + 2 }
end

function Select:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.enter then
    self:dismiss(self.main.selectedRow)
  else
    Window.on_key_down(self, device, key, keycode)
  end
end

function Select:makeTableContents()
  local tableContents = {}
  for _, option in ipairs(self.options) do
    table.insert(tableContents, {
      { display = option }
    })
  end
  return tableContents
end

return Select
end)
__bundle_register("ui.table", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local Navigation = require("ui.navigation")
local uiUtils = require("ui.utils")
local wrap = require("ui.wrap_class")
local Element = require("ui.element").class

local unicode = palRequire('unicode')

local symbols = {
  tl = unicode.char(0x250c),
  tm = unicode.char(0x252c),
  tr = unicode.char(0x2510),
  ml = unicode.char(0x251c),
  mm = unicode.char(0x253c),
  mr = unicode.char(0x2524),
  bl = unicode.char(0x2514),
  bm = unicode.char(0x2534),
  br = unicode.char(0x2518),
  hl = unicode.char(0x2500),
  vl = unicode.char(0x2502),

  arrowLeft = unicode.char(0x25c0),
  arrowRight = unicode.char(0x25b6),
  arrowUp = unicode.char(0x25b2),
  arrowDown = unicode.char(0x25bc),
  barHorz = unicode.char(0x2588),
  barVert = unicode.char(0x2588),
}


local Table = class(Element)

function Table:init(super, contents, config)
  super.init()
  self.contents = contents
  self.config = config
  self.selectable = true

  self.offset = {
    x = 0,
    y = 0,
  }

  self:calculatePositions()
end


function Table:reload()
  self:calculatePositions()
  self:setNeedUpdate()
end

function Table:initSelection(navFrom)
  -- TODO: handle navFrom
  for i = 1, self.config.rows.n do
    for j = 1, self.config.columns.n do
      if self:cellSelectableAt(i, j) then
        self.selectedRow = i
        self.selectedColumn = j
        return self
      end
    end
  end
  return nil
end

function Table:handleNavigation(nav)
  -- TODO: cell level refresh
  local nextRow, nextCol = self:findNextSelectablePos(nav)
  if nextRow and nextCol then
    self:selectCell(nextRow, nextCol)
    return self
  end
  
  local next = Element.handleNavigation(self, nav)
  if next then
    self.selectedRow = nil
    self.selectedColumn = nil
    self:setNeedUpdate()
  end
  return next
end

function Table:cellSelectableAt(row, col)
  -- cell's config is at top priority
  local row = self.contents[row]
  local cell = row and row[col]
  local cellSelectable = cell and cell.selectable

  if cellSelectable ~= nil then
    return cellSelectable
  end
  -- follow the row and column's config
  local rowCfg = self.config.rows[row]
  local rowSelectable = rowCfg and rowCfg.selectable
  if rowSelectable ~= nil then
    return rowSelectable
  end
  local colCfg = self.config.columns[col]
  local colSelectable = colCfg and colCfg.selectable
  if colSelectable ~= nil then
    return colSelectable
  end

  return self.selectable
end


function Table:findNextSelectablePos(nav)
  local fCfgMain, fCfgCross, fSelMain, fSelCross, delta
  if nav == Navigation.up then
    fCfgMain = 'rows'
    fCfgCross = 'columns'
    fSelMain = 'selectedRow'
    fSelCross = 'selectedColumn'
    delta = -1
  elseif nav == Navigation.down then
    fCfgMain = 'rows'
    fCfgCross = 'columns'
    fSelMain = 'selectedRow'
    fSelCross = 'selectedColumn'
    delta = 1
  elseif nav == Navigation.left then
    fCfgMain = 'columns'
    fCfgCross = 'rows'
    fSelMain = 'selectedColumn'
    fSelCross = 'selectedRow'
    delta = -1
  elseif nav == Navigation.right then
    fCfgMain = 'columns'
    fCfgCross = 'rows'
    fSelMain = 'selectedColumn'
    fSelCross = 'selectedRow'
    delta = 1
  else 
    error("bug: unexpected nav direction")
  end

  local nextPos = {
    selectedRow = self.selectedRow,
    selectedColumn = self.selectedColumn
  }

  local nextMain = self[fSelMain] + delta
  while nextMain >= 1 and nextMain <= self.config[fCfgMain].n do
    nextPos[fSelMain] = nextMain
    if self:cellSelectableAt(nextPos.selectedRow, nextPos.selectedColumn) then
      return nextPos.selectedRow, nextPos.selectedColumn
    end

    -- skip if the row/column disable selection
    local mAxisCfg = self.config[fCfgMain][nextMain]
    if (mAxisCfg and mAxisCfg.selectable) ~= false then
      -- search a cell inside cross direction
      for deltaCross = 1, -1, -2 do
        nextPos[fSelCross] = self[fSelCross]
        local nextCross = self[fSelCross] + deltaCross
        while nextCross >= 1 and nextCross <= self.config[fCfgCross].n do
          nextPos[fSelCross] = nextCross
          if self:cellSelectableAt(nextPos.selectedRow, nextPos.selectedColumn) then
            return nextPos.selectedRow, nextPos.selectedColumn
          end
          nextCross = nextCross + deltaCross
        end
      end
    end
    nextMain = nextMain + delta
  end
  return nil
end

function Table:selectCell(row, col)
  self.selectedRow = row
  self.selectedColumn = col

  local yStart = self.rowPositions[self.selectedRow]
  local xStart = self.colPositions[self.selectedColumn]
  local yEnd = self.rowPositions[self.selectedRow + 1] - 1
  local xEnd = self.colPositions[self.selectedColumn + 1] - 1

  -- adjust offset based on cell position
  if self.offset.x > xStart then 
    self.offset.x = xStart
  elseif self.offset.x + self.viewportW <= xEnd then
    local nextOffsetX = xEnd - self.viewportW + 1
    self.offset.x = math.min(xStart, nextOffsetX)
  end
  if self.offset.y > yStart then
    self.offset.y = yStart
  elseif self.offset.y + self.viewportH <= yEnd then
    local nextOffsetY = yEnd - self.viewportH + 1
    self.offset.y = math.min(yStart, nextOffsetY)
  end
  self:setNeedUpdate()
end

function Table:selectedContent()
  if self.selectedRow and self.selectedColumn then
    local row = self.contents[self.selectedRow]
    return row and row[self.selectedColumn]
  end
  return nil
end

function Table:getAction()
  local selected = self:selectedContent()
  if selected then
    return selected.action, selected.value
  end
  return nil
end

function Table:draw(gpu)
  self:clear(gpu)
  -- The whole painting area, include scroll bars.
  local w = self.rect.w
  local h = self.rect.h
  -- The content viewport area, is painting area removing scroll bars.
  local viewportW = w
  local viewportH = h

  local totalRows = self.config.rows.n
  local totalCols = self.config.columns.n

  -- The inner scrollable content size
  local contentW = self.colPositions[#self.colPositions]
  local contentH = self.rowPositions[#self.rowPositions]

  local showBorders = self.config.showBorders

  local shouldShowHorizontalScroll = false
  local shouldShowVerticalScroll = false
  if contentW > w then
    shouldShowHorizontalScroll = true
    viewportH = viewportH - 1
    if contentH >= h then
      shouldShowVerticalScroll = true
      viewportW = viewportW - 1
    end
  elseif contentH > h then
    shouldShowVerticalScroll = true
    viewportW = viewportW - 1
    if contentW >= w then
      shouldShowHorizontalScroll = true
      viewportH = viewportH - 1
    end
  end
  self.viewportW = viewportW
  self.viewportH = viewportH

  -- paint contents
  -- decide which cell to start draw
  local rowPaintStartIndex = 1
  local columnPaintStartIndex = 1

  while self.colPositions[columnPaintStartIndex + 1] <= self.offset.x do
    columnPaintStartIndex = columnPaintStartIndex + 1
  end

  while self.rowPositions[rowPaintStartIndex + 1] <= self.offset.y do
    rowPaintStartIndex = rowPaintStartIndex + 1
  end

  local rowPaintIndex = rowPaintStartIndex

  -- paint every row
  local currentPaintOffsetY = self.offset.y
  while currentPaintOffsetY < self.offset.y + viewportH and rowPaintIndex <= totalRows do
    local columnPaintIndex = columnPaintStartIndex
    local availableHeight = math.min(self.rowPositions[rowPaintIndex + 1], self.offset.y + viewportH) - currentPaintOffsetY

    -- paint every column
    local currentPaintOffsetX = self.offset.x
    while currentPaintOffsetX < self.offset.x + viewportW and columnPaintIndex <= totalCols do
      local availableWidth = math.min(self.colPositions[columnPaintIndex + 1], self.offset.x + viewportW) - currentPaintOffsetX
      local cellAvailableHeight = availableHeight
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)

      -- borders
      if showBorders then
        -- topleft
        local borderTopleft = symbols.mm
        if columnPaintIndex == 1 then
          if rowPaintIndex == 1 then
            borderTopleft = symbols.tl
          else
            borderTopleft = symbols.ml
          end
        elseif rowPaintIndex == 1 then
          borderTopleft = symbols.tm
        end
        gpu.set(sx, sy, borderTopleft)
        sx = sx + 1
        -- top
        gpu.set(sx, sy, symbols.hl:rep(availableWidth - 1))
        sy = sy + 1

        cellAvailableHeight = cellAvailableHeight - 1
        -- left
        if cellAvailableHeight > 0 then
          gpu.set(sx - 1, sy, symbols.vl:rep(cellAvailableHeight), true)
        end
      end

      if cellAvailableHeight > 0 then
        local row = self.contents[rowPaintIndex]
        local cell = row and row[columnPaintIndex]
        local displayText = cell and cell.display or ' '
        if unicode.wlen(displayText) > availableWidth then
          displayText = unicode.wtrunc(displayText, availableWidth)
        end
        local shouldHighlight = self.selectedRow == rowPaintIndex and self.selectedColumn == columnPaintIndex
        if shouldHighlight then
          uiUtils.setHighlight(gpu)
        end
        gpu.set(sx, sy, displayText)
        if shouldHighlight then
          uiUtils.setNormal(gpu)
        end
      end

      columnPaintIndex = columnPaintIndex + 1
      currentPaintOffsetX = self.colPositions[columnPaintIndex]
    end
    -- try draw the rightmost border
    if showBorders and currentPaintOffsetX < self.offset.x + viewportW then
      -- topright
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      if rowPaintIndex == 1 then
        gpu.set(sx, sy, symbols.tr)
      else
        gpu.set(sx, sy, symbols.mr)
      end

      if availableHeight > 1 then
        gpu.set(sx, sy + 1, symbols.vl:rep(availableHeight - 1), true)
      end
    end

    rowPaintIndex = rowPaintIndex + 1
    currentPaintOffsetY = self.rowPositions[rowPaintIndex]
  end
  -- try draw the bottommost border
  if showBorders and currentPaintOffsetY < self.offset.y + viewportH then
    local columnPaintIndex = columnPaintStartIndex
    local currentPaintOffsetX = self.offset.x
    while currentPaintOffsetX < self.offset.x + viewportW and columnPaintIndex <= totalCols do
      local availableWidth = math.min(viewportW, self.colPositions[columnPaintIndex + 1]) - currentPaintOffsetX
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      -- bottom left
      if columnPaintIndex == 1 then
        gpu.set(sx, sy, symbols.bl)
      else
        gpu.set(sx, sy, symbols.bm)
      end
      -- bottom
      gpu.set(sx + 1, sy, symbols.hl:rep(availableWidth - 1))

      columnPaintIndex = columnPaintIndex + 1
      currentPaintOffsetX = self.colPositions[columnPaintIndex]
    end
    -- bottom right
    if currentPaintOffsetX < self.offset.x + viewportW then
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      gpu.set(sx, sy, symbols.br)
    end
  end

  -- paint scroll bars
  if shouldShowHorizontalScroll then
    local sx, sy = self:screenPos(0, self.rect.h - 1)
    gpu.set(sx, sy, symbols.arrowLeft)

    local scrollLength = self.rect.w - 2
    if shouldShowVerticalScroll then
      scrollLength = self.rect.w - 3
    end
    local barLength = math.max(math.floor(viewportW / contentW * scrollLength), 1)
    local barOffset = math.floor(self.offset.x / contentW * scrollLength)
    gpu.set(sx + 1, sy, symbols.hl:rep(scrollLength))
    gpu.set(sx + 1 + barOffset, sy, symbols.barHorz:rep(barLength))
    gpu.set(sx + scrollLength + 1, sy, symbols.arrowRight)
  end
  if shouldShowVerticalScroll then
    local sx, sy = self:screenPos(self.rect.w - 1, 0)
    gpu.set(sx, sy, symbols.arrowUp)

    local scrollLength = self.rect.h - 2
    if shouldShowHorizontalScroll then
      scrollLength = self.rect.h - 3
    end
    local barLength = math.max(math.floor(viewportH / contentH * scrollLength), 1)
    local barOffset = math.floor(self.offset.y / contentH * scrollLength)
    gpu.set(sx, sy + 1, symbols.vl:rep(scrollLength), true)
    gpu.set(sx, sy + 1 + barOffset, symbols.barVert:rep(barLength), true)
    gpu.set(sx, sy + scrollLength + 1, symbols.arrowDown)
  end
end

function Table:calculatePositions()
  local totalRows = self.config.rows.n
  local totalCols = self.config.columns.n

  local showBorders = self.config.showBorders

  local pos = 0
  local colPositions = {}
  for i = 1, totalCols do
    table.insert(colPositions, pos)
    local colConfig = self.config.columns[i]
    pos = pos + (colConfig and colConfig.width or self.config.columns.defaultWidth or 10)
    if showBorders then
      pos = pos + 1
    end
  end
  table.insert(colPositions, pos)

  pos = 0
  local rowPositions = {}
  for i = 1, totalRows do
    table.insert(rowPositions, pos)
    local rowConfig = self.config.rows[i]
    pos = pos + (rowConfig and rowConfig.height or self.config.rows.defaultHeight or 1)
    if showBorders then
      pos = pos + 1
    end
  end
  table.insert(rowPositions, pos)

  self.colPositions = colPositions
  self.rowPositions = rowPositions
end

return wrap(Table)

end)
__bundle_register("ui.window_input", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")

local Window = require("ui.window")
local Frame = require("ui.frame")
local Column = require("ui.column")
local Label = require("ui.label")
local Input = require("ui.input")

local InputWindow = class(Window)

function InputWindow:init(super, title, message, text)
  super.init()
  self.title = title or _T('input_title')
  self.message = message or _T('input_message')
  self.text = text or ''
end

function InputWindow:onLoad()
  self.input = Input(self.text)
  self.ui = Frame(self.title, Column({
    Label(self.message),
    self.input,
  }))

  self.preferredSize = { w = 60, h = 4 }
end

function InputWindow:update(gpu)
  Window.update(self, gpu)
  local result = self.input:editText(gpu)
  self:dismiss(result)
end

return InputWindow
end)
__bundle_register("ui.input", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local UIElement = require("ui.element").class
local utils = require("ui.utils")

local term = palRequire('term')

local Input = class(UIElement)

function Input:init(super, text)
  super.init()
  self.text = text
end

function Input:draw(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end
  self:clear(gpu)
  -- TODO: support line wrapping
  local x, y = self:screenPos(0, 0)
  gpu.set(x, y, self.text)

  if self.selected then
    utils.setNormal(gpu)
  end
end

function Input:setText(t)
  if self.text ~= t then
    self.text = t
    self:setNeedUpdate()
  end
end

function Input:editText(gpu)
  if self.selected then
    utils.setHighlight(gpu)
  end

  local x, y = self:screenPos(0, 0)
  term.setCursor(x, y)
  term.setCursorBlink(true)
  local res = term.read():gsub('\n', '')
  term.setCursorBlink(false)
  if self.selected then
    utils.setNormal(gpu)
  end

  return res
end

return wrap(Input)

end)
__bundle_register("ui.separator", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local wrap = require("ui.wrap_class")
local Element = require("ui.element").class

local unicode = palRequire('unicode')

local HSeparator = class(Element)

function HSeparator:init(super)
  super.init()
  self.intrinsicSize.h = 1
end

function HSeparator:draw(gpu)
  local sx, sy = self:screenPos(0, 0)
  gpu.fill(sx, sy, self.rect.w, 1, unicode.char(0x2500))
end

local VSeparator = class(Element)

function VSeparator:init(super)
  super.init()
  self.intrinsicSize.w = 1
end

function VSeparator:draw(gpu)
  local sx, sy = self:screenPos(0, 0)
  gpu.fill(sx, sy, 1, self.rect.h, unicode.char(0x2502))
end

return {
  horizontal = wrap(HSeparator),
  vertical = wrap(VSeparator),
}
end)
__bundle_register("reactor.window_instance", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local utils = require("core.utils")
local reactorUtils = require("reactor.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
local InputWindow = require("ui.window_input")
local RedstoneWindow = require("reactor.window_redstone")
local TransposerWindow = require("reactor.window_transposer")
local ProfileWindow = require("reactor.window_profile")
require("reactor.window+select_component")

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
      { display = _T('min_heat_temp') },
      { display = tostring(self.config.heat_min), action = 'editMinHeat' }
    },
    {
      { display = _T('max_heat_temp') },
      { display = tostring(self.config.heat_max), action = 'editMaxHeat' }
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
end)
__bundle_register("reactor.window_profile", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local utils = require("core.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
local ItemWindow = require("reactor.window_item")
local builtins = require("reactor.builtins")

local function makeDefaultConfig()
  return {
    item = {}
  }
end

local ProfileWindow = class(Window)

function ProfileWindow:init(super, config, schemas)
  super.init()
  self.config = utils.copy(config) or makeDefaultConfig()
  
  local schemasByKey = {}
  for _, schema in ipairs(builtins.schemas) do
    schemasByKey[schema.name] = schema
  end
  for _, schema in ipairs(schemas or {}) do
    schemasByKey[schema.name] = schema
  end
  self.schemasByKey = schemasByKey

  self.schema = self.config.schema and schemasByKey[self.config.schema]

  self.tblCfgOptions = {
    showBorders = false,
    columns = {
      n = 2,
      defaultWidth = 8,
      [1] = {
        selectable = false,
      },
      [2] = {
        width = 10,
      }
    },
    rows = {
      n = 2
    }
  }
  self.tblLayoutOptions = {
    showBorders = true,
    columns = {
        n = 1,
        defaultWidth = 2,
    },
    rows = {
        n = 1,
    }
  }
  self.tblLayoutContents = {}

  self:makeTableContents()
end

function ProfileWindow:onLoad()
  local left = Table(self.tblCfgContents, self.tblCfgOptions):size(24)
  self.left = left
  local right = Table(self.tblLayoutContents, self.tblLayoutOptions):makeSelectable(false)
  self.right = right

  self.ui = Frame(
    _T('profile_config'),
    Column({
      Row({
        left,
        Separator.vertical(),
        right,
      }),
      Separator.horizontal(),
      Row({
        Button(_T('ok')):action('clickedOk'),
        Button(_T('cancel')):action('clickedCancel'),
      }):size(nil, 1)
    })
  )

  self.preferredSize = { w = 60, h = 17 }
end

function ProfileWindow:makeTableContents()
  local schema = self.schema
  local schemaDisplayName = schema and (schema.displayName or schema.name) or _T('not_configured')

  local tblCfgContents = {
    {
      { display = _T('schema') },
      { display = schemaDisplayName, action = 'editSchema' }
    },
  }

  self.tblCfgContents = tblCfgContents
  
  if not schema then
    self.tblCfgOptions.rows.n = #tblCfgContents
    -- tricks to 'hide' layout
    self.tblLayoutOptions.showBorders = false
    self.tblLayoutOptions.rows.n = 1
    self.tblLayoutOptions.columns.n = 1
    self.tblLayoutContents = {}
    return
  end

  local uniqueLayoutVariables = {}

  for _, var in pairs(schema.layout or {}) do
    uniqueLayoutVariables[var] = true
  end
  local sortedLayoutVariables = {}
  for var, _ in pairs(uniqueLayoutVariables) do
    table.insert(sortedLayoutVariables, var)
  end
  table.sort(sortedLayoutVariables)

  for _, var in pairs(sortedLayoutVariables) do
    local item = self.config.item[var]
    local itemDisplay = item and (item.name and _T(item.name)) or _T('not_configured')
    table.insert(tblCfgContents, {
      { display = var },
      { display = itemDisplay, action = 'editItem', value = var }
    })
  end

  self.tblCfgOptions.rows.n = #tblCfgContents

  -- layout table contents

  local w = schema.size.w
  local h = schema.size.h
  local layout = schema.layout

  for i = 1, h do
    self.tblLayoutContents[i] = {}
    for j = 1, w do
      local idx = (i - 1) * w + j
      self.tblLayoutContents[i][j] = {
        display = layout[idx]
      }
    end
  end

  self.tblLayoutOptions.showBorders = true
  self.tblLayoutOptions.columns.n = w
  self.tblLayoutOptions.rows.n = h
end

function ProfileWindow:editSchema()
  local schemaList = { _T('not_configured') }
  local backed = { 1 } -- placeholder

  for name, schema in pairs(self.schemasByKey) do 
    table.insert(schemaList, schema.displayName or schema.name)
    table.insert(backed, name)
  end

  local win = Select:new(_T('select_schema'), schemaList)
  self:present(
    win,
    function(result)
      local schemaName = nil
      if result ~= 1 then
        schemaName = backed[result]
      end
      if self.config.schema ~= schemaName then
        self.config.item = {}
      end
      self.config.schema = schemaName
      self.schema = schemaName and self.schemasByKey[schemaName]

      self:makeTableContents()
      self.left.contents = self.tblCfgContents
      self.left:reload()
      self.right.contents = self.tblLayoutContents
      self.right:reload()
    end
  )
end

function ProfileWindow:editItem(varName)
  local win = ItemWindow:new(self.config.item[varName])
  self:present(
    win,
    function(editOk, newItem)
      if editOk then
        self.config.item[varName] = newItem
        self:makeTableContents()
        self.left.contents = self.tblCfgContents
        self.left:reload()
      end
    end
  )
end

function ProfileWindow:clickedOk()
  self:dismiss(true, self.config)
end

function ProfileWindow:clickedCancel()
  self:dismiss(false)
end

return ProfileWindow
end)
__bundle_register("reactor.window_item", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local utils = require("core.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
local InputWindow = require("ui.window_input")

local builtins = require("reactor.builtins")
local reactorUtils = require("reactor.utils")

local function makeDefaultConfig()
  return {
    change = 'none'
  }
end

local ItemWindow = class(Window)

function ItemWindow:init(super, config)
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

function ItemWindow:onLoad()
  local list = Table(self.tableContents, self.tableCfg)
  self.list = list

  self.ui = Frame(
    _T('item_config'),
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

function ItemWindow:makeTableContents()
  local tableContents = {
    {
      { display = _T('item_name') },
      { display = _T(self.config.name or 'not_configured'), action = 'editItem' }
    },
    {
      { display = _T('change_condition') },
      { display = reactorUtils.changeConditionDescription(self.config), action = 'editChangeCondition' }
    },
  }
  self.tableContents = tableContents

  if self.config.change == 'damage_less' then
    table.insert(tableContents, {
      { display = _T('threshold') },
      { display = tostring(self.config.threshold), action = 'editThreshold' }
    })
    self.tableCfg.rows.n = 3
  else
    self.tableCfg.rows.n = 2
  end
end

function ItemWindow:editItem()
  local itemList = {}
  for _, item in ipairs(builtins.items) do
    table.insert(itemList, _T(item.id))
  end
  local win = Select:new(_T('item_name'), itemList)

  self:present(
    win, 
    function(result)
      self.config.name = builtins.items[result].id
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:editChangeCondition()
  local conditions = {
    'none',
    'damage_less',
  }
  local selectMode = Select:new(_T('redstone_mode'), {
    _T('change_condition_none'),
    _T('change_condition_damage_less'),
  })

  self:present(
    selectMode, 
    function(result)
      self.config.change = conditions[result]
      if self.config.change == 'damage_less' then
        self.config.threshold = 0.1
      end
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:editThreshold()
  local win = InputWindow:new(_T('threshold'), _T('input_prompt_threshold'))
  self:present(
    win,
    function(result)
      self.config.threshold = tonumber(result)
      self:makeTableContents()
      self.list.contents = self.tableContents
      self.list:reload()
    end
  )
end

function ItemWindow:clickedOk()
  self:dismiss(true, self.config)
end

function ItemWindow:clickedCancel()
  self:dismiss(false)
end

return ItemWindow
end)
__bundle_register("reactor.window_transposer", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local utils = require("core.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
require("reactor.window+select_component")

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
end)
__bundle_register("reactor.window_redstone", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")
local utils = require("core.utils")

local Window = require("ui.window")
local Column = require("ui.column")
local Row = require("ui.row")
local Frame = require("ui.frame")
local Button = require("ui.button")
local Table = require("ui.table")
local Separator = require("ui.separator")
local Select = require("ui.window_select")
require("reactor.window+select_component")

local RedstoneWindow = class(Window)

function RedstoneWindow:init(super, config)
  super.init()
  self.config = utils.copy(config)

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
end)
__bundle_register("ui.window_alert", function(require, _LOADED, __bundle_register, __bundle_modules)


local class = require("core.class")

local Window = require("ui.window")
local Frame = require("ui.frame")
local Column = require("ui.column")
local Row = require("ui.row")
local Button = require("ui.button")
local Label = require("ui.label")

local Alert = class(Window)

Alert.Ok = 0
Alert.Cancel = 1

function Alert:init(super, title, message, buttons)
  super.init()
  self.title = title or _T('alert_title')
  self.message = message or _T('alert_message')
  self.buttons = buttons or 0
end

function Alert:onLoad()
  local buttons = Row()

  if self.buttons & Alert.Ok == Alert.Ok then
    buttons:addSubview(Button(_T('ok')):action('clickedOk'))
  end
  if self.buttons & Alert.Cancel == Alert.Cancel then
    buttons:addSubview(Button(_T('cancel')):action('clickedCancel'))
  end

  self.ui = Frame(self.title, Column({
    Label(self.message),
    buttons
  }))

  self.preferredSize = { w = 50, h = 7 }
end

function Alert:clickedOk()
  self:dismiss(Alert.Ok)
end

function Alert:clickedCancel()
  self:dismiss(Alert.Cancel)
end

return Alert
end)
__bundle_register("core.i18n", function(require, _LOADED, __bundle_register, __bundle_modules)



local i18n = {}
local langTable = {}


function _T(k)
  return langTable[k] or k
end

local baseModule

function i18n.reload(lang)
  local langCode = lang or i18n.langList.default

  for name, code in pairs(i18n.langList) do
    if name ~= 'default' and code == langCode then
      langCode = code
      i18n.current = name
      break
    end
  end

  langTable = require(baseModule..'/lang_'..langCode)
end


function i18n.setup(base, lang)
  baseModule = base
  i18n.langList = require(base)
  i18n.reload(lang)
end

return i18n

end)
__bundle_register("core.pal", function(require, _LOADED, __bundle_register, __bundle_modules)




local isOpenOS = false
if _G._OSVERSION then
  if type(_OSVERSION) == 'string' then
    if string.sub(_OSVERSION, 1, 6) == 'OpenOS' then
      isOpenOS = true
    end
  end
end



palRequire = require

if not isOpenOS then
  palRequire = function(moduleName)
    return require('pal.' .. moduleName)
  end
  os.sleep = function() end
end

debugLog = function() end

end)
return __bundle_require("__root")