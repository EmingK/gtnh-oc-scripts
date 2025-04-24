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

local class = require('core.class')
local App = require('core.app')
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

local appVersion = require('reactor.version')
local Chamber = require('reactor.chamber')
local config = require('reactor.config')

local ReactorUI = class(Frame.class)

function ReactorUI:init(super, reactor)
  super.init(reactor.i.name)

  self.reactor = reactor
  reactor.delegate = self

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

  local status = Label("[S] Start\t[P] Stop\t[X] Exit"):size(nil, 1)

  local root = Column({
      title,
      main,
      status
  })
  return {
    root = root,
  }
end

local MonitorWindow = class(Window)

function MonitorWindow:onLoad()
  local rawConfig = config.get()

  local reactors = {}
  for i, cfg in ipairs(rawConfig.instances) do
    local instance = config.instantiate(cfg)
    local rc = Chamber:new(instance)
    rc:attachTo(self.app.runloop)
    reactors[i] = rc
  end
  self.reactors = reactors

  term.clear()

  local w, h, x, y = term.getViewport()
  local root = buildUI(reactors).root

  root.rect = { x = x + 1, y = y + 1, w = w, h = h }
  root:layout()

  self.ui = root
end

function MonitorWindow:startReactors()
  for _, reactor in ipairs(self.reactors) do
    reactor:start()
  end
end

function MonitorWindow:stopReactors()
  for _, reactor in ipairs(self.reactors) do
    reactor:stop()
  end
end

-- Event handlers

function MonitorWindow:on_key_up(device, key, keycode)
  if keycode == keyboard.keys.x then
    self:stopReactors()
    self:dismiss()
  elseif keycode == keyboard.keys.s then
    self:startReactors()
  elseif keycode == keyboard.keys.p then
    self:stopReactors()
  end
end

function MonitorWindow:on_redstone_changed(device, side, oldValue, newValue, color)
end

return MonitorWindow
