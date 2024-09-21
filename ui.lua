local term = require('term')
local event = require('event')
local computer = require('computer')

local version = require('version')
local ui_lib = require('ui_lib')
local global_control = require('global_control')
local class = require('class')

local Button = ui_lib.Button
local Row = ui_lib.Row
local Column = ui_lib.Column
local Label = ui_lib.Label
local Progress = ui_lib.Progress
local Grid = ui_lib.Grid

function reactor_status_string(r)
  if r.err then
    return r.err
  elseif r.item_shortage then
    return "[!] Item shortage!"
  elseif r.output_full then
    return "[!] Output full!"
  elseif r.running then
    return "[+] RUNNING"
  else
    return "[-] PAUSED"
  end
end

local ReactorStatus = class(ui_lib.Frame)

function ReactorStatus:init(name, reactor)
  self.reactor = reactor

  local inner = Column:new()
  local row_0 = Row:new()
  local label_state_1 = Label:new("")
  label_state_1.intrinsic_size = { h = 1 }
  row_0:add_subview(label_state_1)
  self.lbl_status = label_state_1
  row_0.intrinsic_size = { h = 1 }
  local label_temp = Label:new("0%")
  label_temp.intrinsic_size = { w = 4, h = 1 }
  row_0:add_subview(label_temp)
  self.lbl_temp = label_temp
  inner:add_subview(row_0)

  local progress_bar = Progress:new(0)
  progress_bar.intrinsic_size = { h = 1 }
  self.prg_temp = progress_bar
  inner:add_subview(progress_bar)

  self:add_subview(inner)
end

function ReactorStatus:update()
  local reactor = self.reactor
  local temp = reactor:temperature()

  self.lbl_status:set_text(reactor_status_string(reactor))
  self.lbl_temp:set_text(tostring(math.floor(temp * 100 + 0.5)) .. "%")
  self.prg_temp:set_value(temp)
end

local Group = class()

function Group:init()
  self.elements = {}
end

function Group:add(e)
  table.insert(self.elements, e)
end

function Group:activate(e)
  for i, element in ipairs(self.elements) do
    if element == e then
      element:set_active(true)
    else
      element:set_active(false)
    end
  end
end

local key_registry = {}
local function key_register(name, action)
  key_registry[name] = action
end

local function key_handle(k)
  cmd = string.char(k):upper()
  local action = key_registry[cmd]
  if action then action() end
end

local ui = {}
local root
local CONTROL_BUTTON_W = 10

function ui.setup(reactors)
  local w, h, x, y = term.getViewport()

  root = Column:new()

  local title_bar = Label:new("Reactor Monitor - v" .. version)
  title_bar.intrinsic_size = { h = 1 }
  root:add_subview(title_bar)

  local reactor_status = Grid:new()
  for i, reactor in ipairs(reactors) do
    local state_frame = ReactorStatus:new("Reactor #" .. tostring(i), reactor)
    state_frame.intrinsic_size = { h = 4 }
    reactor_status:add_subview(state_frame)
  end
  root:add_subview(reactor_status)

  local control_height = math.ceil(3 * CONTROL_BUTTON_W / w)
  local controls = Grid:new()
  controls.intrinsic_size = { h = control_height }
  local control_group = Group:new()
  local button_start = Button:new("[S] Start")
  button_start.intrinsic_size = { w = CONTROL_BUTTON_W }
  controls:add_subview(button_start)
  control_group:add(button_start)
  local button_pause = Button:new("[P] Pause")
  button_pause.intrinsic_size = { w = CONTROL_BUTTON_W }
  controls:add_subview(button_pause)
  control_group:add(button_pause)
  local button_exit = Button:new("[X] Exit")
  button_exit.intrinsic_size = { w = CONTROL_BUTTON_W }
  controls:add_subview(button_exit)
  control_group:add(button_exit)
  root:add_subview(controls)

  key_register("S", function()
                 global_control.set_pause(false)
                 control_group:activate(button_start)
  end)
  key_register("P", function()
                 global_control.set_pause(true)
                 control_group:activate(button_pause)
  end)
  key_register("X", function()
                 global_control.shutdown()
                 control_group:activate(button_exit)
  end)

  local status_bar = Label:new("")
  status_bar.intrinsic_size = { h = 1 }

  function status_bar:update()
    local mem = computer.totalMemory()
    local used = mem - computer.freeMemory()
    self:set_text("Mem: " .. tostring(used) .. "/" .. tostring(mem))
  end
  root:add_subview(status_bar)

  ui_lib.layout(root, { x = x + 1, y = y + 1, w = w, h = h })
  ui.root = root

  term.clear()
  root:draw()
end

function ui.update() root:update() end

function ui.loop(run_condition)
  while run_condition() do
    local a, dev, ch = event.pull(0.5, "key_down")

    if ch then
      key_handle(ch)
    end

    root:update()
  end
end

return ui
