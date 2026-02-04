--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  Reactor sub app - run

  This is the main working monitor for reactor app.
]]

local term = palRequire('term')
local event = palRequire('event')
local keyboard = palRequire('keyboard')
local computer = palRequire('computer')

local class = require('core.class')
local App = require('ui.app')
local utils = require('core.utils')

local Window = require('ui.window')
local Label = require('ui.label')
local Button = require('ui.button')
local Grid = require('ui.grid')
local Row = require('ui.row')
local Column = require('ui.column')
local Tabs = require('ui.tabs')
local Frame = require('ui.frame')
local Progress = require('ui.progress')

local appVersion = require('version')
local Chamber = require('reactor.chamber')
local config = require('reactor.config')

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

local EUStorageUI = class(Frame.class)

function EUStorageUI:init(super, storage)
  super.init(storage.name)

  self.storage = storage

  self.lblStatus = Label(""):size(nil, 1)
  self.lblPercent = Label("0%"):size(5, 1)
  self.prgEU = Progress(0):size(nil, 1)

  local inner = Column({
    Row({
      self.lblStatus,
      self.lblPercent,
    }):size(nil, 1),
    self.prgEU
  })

  self:addSubview(inner)
end

function EUStorageUI:updateStatus()
  local storage = self.storage
  local storedEU = storage.proxy.getStoredEU()
  local capacity = storage.proxy.getEUCapacity()
  local percent = math.floor((storedEU / capacity) * 100)

  -- Format EU values with appropriate units
  local function formatEU(value)
    if value >= 1000000000 then
      return string.format("%.1fG", value / 1000000000)
    elseif value >= 1000000 then
      return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
      return string.format("%.1fK", value / 1000)
    else
      return tostring(value)
    end
  end

  local statusText = string.format(_T('eu_status_format'), formatEU(storedEU), formatEU(capacity), percent)
  self.lblStatus:setText(statusText)
  self.lblPercent:setText(tostring(percent) .. "%")
  self.prgEU:setValue(storedEU / capacity)
end

local function buildUI(reactors, euStorages)
  local title = Label(string.format(_T('title_monitor_app'), appVersion)):size(nil, 1)

  local main = Grid()
  for _, reactor in ipairs(reactors) do
    local rcUI = ReactorUI:new(reactor):size(nil, 4)
    main:addSubview(rcUI)
  end

  local euStorageUIs = {}
  local euGrid = nil
  if euStorages and #euStorages > 0 then
    euGrid = Grid()
    for _, storage in ipairs(euStorages) do
      local euUI = EUStorageUI:new(storage):size(nil, 4)
      euGrid:addSubview(euUI)
      table.insert(euStorageUIs, euUI)
    end
  end

  local status = Label(_T('keyboard_tips_run')):size(nil, 1)

  local components = {title, main}
  if euGrid then
    table.insert(components, euGrid)
  end
  table.insert(components, status)

  local root = Column(components)
  return {
    root = root,
    euStorageUIs = euStorageUIs,
  }
end

local alwaysOn = {
  getInput = function() return true end,
}

local MonitorWindow = class(Window)

function MonitorWindow:onLoad()
  self.running = false
  self.timerActive = true

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

  local euStorages = config.getEUStorages()

  term.clear()
  local uiResult = buildUI(self.reactors, euStorages)
  self.ui = uiResult.root
  self.euStorageUIs = uiResult.euStorageUIs

  -- Initialize EU storage display
  self:updateEUStorageUI()

  -- Schedule periodic EU condition check
  self:scheduleEUCheck()
end

function MonitorWindow:scheduleEUCheck()
  local checkInterval = 5.0  -- Check every 5 seconds
  self.app.runloop:enqueueScheduled(
    'eu_check',
    computer.uptime() + checkInterval,
    function()
      if self.timerActive then
        self:on_timer()
        self:scheduleEUCheck()  -- Reschedule if timer is active
      end
    end
  )
end

function MonitorWindow:stopTimer()
  self.timerActive = false
end

function MonitorWindow:updateEUStorageUI()
  if self.euStorageUIs then
    for _, euUI in ipairs(self.euStorageUIs) do
      euUI:updateStatus()
    end
  end
end

function MonitorWindow:startReactors()
  self.running = true
  local canStart, mustStop = config.checkEUCondition()
  if self.globalControl:getInput() and canStart and not mustStop then
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
    self:stopTimer()
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

  local canStart, mustStop = config.checkEUCondition()

  if mustStop then
    -- Must stop due to EU condition
    self:stopReactorsInner()
  elseif self.globalControl:getInput() and canStart then
    -- Can start: global control allows and EU condition allows
    self:startReactorsInner()
  elseif not self.globalControl:getInput() then
    -- Global control requires stop
    self:stopReactorsInner()
  end
end

function MonitorWindow:on_timer()
  -- Update EU storage UI
  self:updateEUStorageUI()

  -- Periodically check EU condition
  if not self.running then
    return
  end

  local canStart, mustStop = config.checkEUCondition()

  if mustStop then
    -- Must stop due to EU condition
    self:stopReactorsInner()
  elseif self.globalControl:getInput() and canStart then
    -- Can start: global control allows and EU condition allows
    self:startReactorsInner()
  elseif not self.globalControl:getInput() then
    -- Global control requires stop
    self:stopReactorsInner()
  end
  -- Otherwise, maintain current state (neither start nor stop condition met)
end

return MonitorWindow
