--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local system = require('system')
local curses = require('pal.details.curses')

local event = {}

local eventQueue = {}

function event.pull(...)
  curses.scr:refresh()
  local start = system.monotime()
  local filter, timeout

  local args = table.pack(...)
  if type(args[1]) == 'string' then
    filter = function(name) return name == args[1] end
    timeout = args[2]
  elseif type(args[1]) == 'number' or args[1] == nil then
    filter = function() return true end
    timeout = args[1]
  else
    error('invalid args')
  end
  timeout = timeout or math.huge

  while system.monotime() - start < timeout do
    -- TODO: enable external code to mock events

    -- simulate key_up. We read input from terminal, there is no way to
    -- simulate key_down.

    local key = curses.scr:getch()
    if key then
      -- TODO: key name
      local keydown = { 'key_down', nil, key, key }
      table.insert(eventQueue, keydown)
      local keyup = { 'key_up', nil, key, key }
      table.insert(eventQueue, keyup)
    end

    local first = table.remove(eventQueue, 1)
    if first and filter(first[1]) then
      return table.unpack(first)
    end

    system.sleep(0.05)
  end
  return nil
end

return event
