local config = require("config")
local global_control = require("global_control")
local Reactor = require("reactor")
local ui = require("ui")

local thread = require("thread")
local event = require("event")

local reactors = {}
local threads = {}

local function reactors_setup()
  for i, cfg in ipairs(config.reactors) do
    reactors[i] = Reactor:new(cfg)
  end
end

local function reactors_start()
  for i, reactor in ipairs(reactors) do
    threads[i] = thread.create(reactor.run, reactor)
  end
end

local function reactors_running()
  local all_finish = true
  for i, t in ipairs(threads) do
    if t:status() ~= "dead" then
      all_finish = false
      break
    end
  end

  return not all_finish
end

local function ui_loop()
  ui.setup(reactors)
  ui.loop(reactors_running)
end

local function start()
  global_control.setup(config.global_controls)
  reactors_setup()
  reactors_start()
  ui_loop()
end

start()
