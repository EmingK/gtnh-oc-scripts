--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  Runloop - task scheduler with time management

  This module create a loop to run tasks. Typically, a TUI application
  need this to handle key or other events and respond to them infinitely.

  Runloop accepts two kinds of task:
    - Timed task, need to be scheduled at specific timing point.
    - Idle task, is handled when no timed task is running.

  Runloop schedules timed task as accurate as possible. At other time,
  idle tasks are executed in FIFO order.
]]

local class = require('core.class')

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
