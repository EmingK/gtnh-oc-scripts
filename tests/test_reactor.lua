require('tests/setup')

local mock = require('tests/mock')

local sides = require('sides')
local Reactor = require('reactor')
local global_control = require('global_control')

local function test_reactor_setup()
  local r = Reactor:new({
      redstone = { comp = mock.redstone(), side = sides.east }
  })
  assert(r.running == false)
  assert(r.item_shortage == false)
  assert(r.output_full == false)
end

local function test_run_by_iterate_ret()
  local start_called = 0
  local stop_called = 0
  local iterate_called = 0
  local iterate_count = 10

  local r = Reactor:new({
      redstone = { comp = mock.redstone(), side = sides.east }
  })
  r.start = function() start_called = start_called + 1 end
  r.stop = function() stop_called = stop_called + 1 end
  r.iterate = function()
    iterate_called = iterate_called + 1
    return iterate_called >= iterate_count
  end

  r:run()
  assert(start_called == 0)
  assert(stop_called == 2)
  assert(iterate_called == 10)
end

local function test_shutdown_on_run_error()
  local start_called = 0
  local stop_called = 0
  local e = {}

  local r = Reactor:new({
      redstone = { comp = mock.redstone(), side = sides.east }
  })
  r.start = function() start_called = start_called + 1 end
  r.stop = function() stop_called = stop_called + 1 end
  r.iterate = function()
    error(e)
  end

  r:run()
  assert(start_called == 0)
  assert(stop_called == 2)
  assert(r.error == e)
end

local function test_global_shutdown()
  global_control.setup({
      energy_latch = { comp = mock.redstone(), side = sides.east },
      shutdown_switch = { comp = mock.redstone(), side = sides.west },
  })
  local rs = mock.redstone()
  local r = Reactor:new({
      redstone = { comp = rs, side = sides.east },
  })

  assert(r.running == false)
  global_control.shutdown()
  assert(r:iterate() == true)
  assert(rs.outputs[sides.east] == 0)
end

test_reactor_setup()
test_run_by_iterate_ret()
test_shutdown_on_run_error()
test_global_shutdown()
