local global_control = require('global_control')
local component_helper = require('component_helper')

local STATE_HEATING = "[^] Heating"
local STATE_COOLING = "[v] Cooling"
local STATE_STOPPED = "[-] Stopped"
local STATE_RUNNING = "[>] Running"

local Reactor = {}

-- Constructor of the `Reactor` class.
--
-- Build runtime instance of a runnable reactor.
function Reactor:new(config)
  o = {
    cfg = config,
    running = false,
    output_full = false,
    item_shortage = false,
  }
  component_helper.Redstone:new(o.cfg.redstone)

  setmetatable(o, self)
  self.__index = self
  return o
end

-- Activate the reactor.
--
-- Unsafe method: used for internal implementation only.
function Reactor:start()
  self.cfg.redstone:on()
  self.running = true
end

-- Deactivate the reactor.
--
-- Unsafe method: used for internal implementation only.
function Reactor:stop()
  -- if self.running then
    self.cfg.redstone:off()
    os.sleep(1)
  -- end
  self.running = false
end

-- Get the reactor temperature in percentage.
function Reactor:temperature()
  local heat = self.cfg.reactor.getHeat()
  local max_heat = self.cfg.reactor.getMaxHeat()
  return heat / max_heat;
end

-- Run the reactor monitor blocking.
--
-- For multiple reactor instances, you may use threads.
function Reactor:run()
  self:stop()
  while true do
    ok, result = pcall(self.iterate, self)
    if not ok then
      self.error = result
      break
    end
    if result then
      break
    end
  end
  self:stop()
end

function Reactor:iterate()
  -- handle interrupt
  if global_control.should_shutdown() then
    return true
  end
  if global_control.should_pause() then
    self:stop()
    return false
  end
  -- check temperature
  self:check_temperature()
  -- check change items
  self:change_items_if_needed()
  -- pause if error occurs
  if self.output_full or self.item_shortage then
    self:stop()
    return false
  end
  self:start()
  os.sleep(0.5)
  return false
end

-- Operate on reactor to make temperature between defined ranges.
function Reactor:check_temperature()
  local heat = self:temperature()

  if heat > self.cfg.max_heat then
    self:cool_down()
  end
  if heat < self.cfg.min_heat then
    self:warm_up()
  end
end

-- Check reactor items and change items if needed.
--
-- If item change happens, the reactor will stop first and wait.
-- Error flags will be set if the item can not be changed.
function Reactor:change_items_if_needed()
  local reactor_items = self.cfg.transposer.getAllStacks(self.cfg.item_reactor).getAll()
  local schema = self.cfg.schema

  for i = 1, #schema, 1 do
    local item_cfg = schema[i]
    local reactor_item = reactor_items[i - 1]

    local need_insert = false
    local need_replace = false

    if reactor_item == nil or reactor_item["name"] == nil then
      need_insert = true
    elseif reactor_item.name ~= item_cfg.item then
      need_replace = true
    elseif item_cfg.check(reactor_item) then
      need_replace = true
    end

    if (need_insert or need_replace) and self.running then
      self:stop()
    end

    local remove_ok = true
    if need_replace then
      need_insert = true
      remove_ok = self:remove_item(i)
      self.output_full = not remove_ok
    end

    local insert_ok
    if remove_ok and need_insert then
      insert_ok = self:insert_item(i, item_cfg.item)
      self.item_shortage = not insert_ok
    end
  end
end

-- Move an item from the reactor to the output box.
function Reactor:remove_item(index)
  local count = self.cfg.transposer.transferItem(self.cfg.item_reactor, self.cfg.item_to, 1, index)
  return count > 0
end

-- Move an item from input box to the reactor.
function Reactor:insert_item(index, item_name)
  local count = 0
  local slot = 1
  for item in self.cfg.transposer.getAllStacks(self.cfg.item_from) do
    if item.name == item_name then
      local move_count = self.cfg.transposer.transferItem(self.cfg.item_from, self.cfg.item_reactor, 1, slot, index)
      count = count + move_count

      if count > 0 then
        break
      end
    end
    slot = slot + 1
  end

  return count > 0
end

-- Remove all items and insert cool down item, and wait for temperature below the threshold.
function Reactor:cool_down()
  error("Not implemented")
end

-- Remove all items and insert warm up item, and wait for temperature above the threshold.
function Reactor:warm_up()
  error("Not implemented")
end

return Reactor
