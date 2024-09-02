local sides = require('sides')
local schema = require('schema')
local components = require('component_helper')

local vacuum_u4_NaK360 = schema.build({
    layout = schema.layouts.vacuum,
    items = {
      A = {
        item = schema.items.u4,
        check = schema.checkers.none,
      },
      B = {
        item = schema.items.nak360,
        check = schema.checkers.damage_less_than(0.1)
      },
    }
})

return {
  -- Global controlling.
  global_controls = {
    -- Input signal from energy storage.
    -- If the signal is set to off, reactor will pause until set to on.
    energy_latch = components.with_side('abfababa-c173-4a1e-8d8a-fec0f72a87e1', sides.south),
    -- Input signal for manual shutdown.
    -- If the signal is set, the control program will quit.
    shutdown_switch = components.with_side('abfababa-c173-4a1e-8d8a-fec0f72a87e1', sides.east),
  },
  reactors = {
    -- reactor #1
    {
      reactor = components.address('a640c2a1-58ef-45d4-9714-4d52d40cc010'),
      transposer = components.address('a739cf26-1467-4365-9ee7-68302e928429'),
      redstone = components.with_side('c8ac883b-6013-4620-bc8b-937b9835adda', sides.north),

      item_from = sides.west,
      item_to = sides.up,
      item_reactor = sides.north,

      schema = vacuum_u4_NaK360,

      min_heat = 0,
      max_heat = 0.1,
    },
    -- reactor #2
    -- add more...
  }
}
