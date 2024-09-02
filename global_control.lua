local component_helper = require('component_helper')

local energy_latch
local shutdown_switch
local program_pause
local program_shutdown

local function setup(cfg)
  program_pause = true
  program_shutdown = false
  energy_latch = component_helper.Redstone:new(cfg.energy_latch)
  shutdown_switch = component_helper.Redstone:new(cfg.shutdown_switch)
end

local function shutdown()
  program_shutdown = true
end

local function set_pause(v)
  program_pause = v
end

local function should_shutdown()
  local switch_shutdown = shutdown_switch:get()
  return program_shutdown or switch_shutdown
end

local function should_pause()
  local switch_pause = not energy_latch:get()
  return program_pause or switch_pause
end


local global_control = {
  setup = setup,

  shutdown = shutdown,

  set_pause = set_pause,

  -- Shutdown the system.
  -- Existing reactors will stop and quit the program.
  should_shutdown = should_shutdown,

  -- Temporarily pause running of all reactors.
  should_pause = should_pause,
}

return global_control
