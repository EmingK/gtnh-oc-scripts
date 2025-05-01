--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  Reactor chamber - Controller of a single reactor instance
]]

local class = require('core.class')
local utils = require('core.utils')
local builtins = require('reactor.builtins')

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

--[[
  Method ReactorChamber:check

  Do temprature and item check, change redstone if needed. If items does not
  satisfy its current profile, schedule an idle task to apply profile, i.e.
  change fuel rods and coolant cells. Also switch to other preset profiles
  if heap temprature beyond limit.

  This need to be run in high priority, and will be a timed schedule to its
  attached runloop.
]]
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

--[[
  Method ReactorChamber:checkProfile

  A quick check on whether reactor contents match current active profile.

  Returns early if profile not match.
]]
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

--[[
  Method ReactorChamber:applyProfile

  Try to update all items inside the reactor, to match the description of
  current working profile. This include:
]]
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
