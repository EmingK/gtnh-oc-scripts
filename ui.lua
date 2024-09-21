local term = require('term')
local computer = require('computer')
local unicode = require('unicode')

local version = require('version')

local borders = {
  tl = unicode.char(0x2552),
  t = unicode.char(0x2550),
  tr = unicode.char(0x2555),
  l = unicode.char(0x2502),
  r = unicode.char(0x2502),
  bl = unicode.char(0x2514),
  b = unicode.char(0x2500),
  br = unicode.char(0x2518),
}

local UIElement = {}
UIElement.__index = UIElement

function UIElement:new(x, y, w, h)
  local o = {
    rect = {
      x = x,
      y = y,
      w = w,
      h = h,
    }
  }

  setmetatable(o, self)
  return o
end

function UIElement:move_cursor(rel_x, rel_y)
  term.setCursor(self.rect.x + rel_x, self.rect.y + rel_y)
end

local Panel = {}
Panel.__index = Panel
setmetatable(Panel, UIElement)

function Panel:new(x, y, w, h, index, reactor)
  local o = UIElement:new(x, y, w, h)
  o.index = index
  o.reactor = reactor

  setmetatable(o, self)
  return o
end

function Panel:draw()
  -- top border
  self:move_cursor(0, 0)
  local title = "Reactor #" .. tostring(self.index)
  local row_1 = borders.tl .. title .. borders.t:rep(self.rect.w - 2 - #title) .. borders.tr
  term.write(row_1)

  -- state
  self:move_cursor(0, 1)
  local reactor_state
  
  if self.reactor.error then
    reactor_state = "[!] ERR:" .. tostring(self.reactor.error)
  elseif self.reactor.item_shortage then
    reactor_state = "[!] Item shortage!"
  elseif self.reactor.output_full then
    reactor_state = "[!] Output is full!"
  elseif self.reactor.running then
    reactor_state = "[*] RUNNING"
  else
    reactor_state = "[-] PAUSED"
  end
  term.write(borders.l .. reactor_state)

  -- temperature
  local temp = self.reactor:temperature()
  self:move_cursor(self.rect.w - 10, 1)
  term.write("Temp:" .. tostring(math.floor(temp * 100 + 0.5)) .. "%")
  self:move_cursor(self.rect.w - 1, 1)
  term.write(borders.r)

  -- temp bar
  self:move_cursor(0, 2)
  local bar_len = self.rect.w - 2
  local left_len = math.floor(temp * bar_len + 0.5)
  local right_len = bar_len - left_len
  term.write(borders.l .. ("#"):rep(left_len) .. ("."):rep(right_len) .. borders.r)

  -- bottom
  self:move_cursor(0, 3)
  term.write(borders.bl .. borders.b:rep(self.rect.w - 2) .. borders.br)
end

local Button = {}
Button.__index = Button
setmetatable(Button, UIElement)

function Button:new(x, y, w, h, shortcut, text)
  local o = UIElement:new(x, y, w, h)
  o.focus = false
  o.shortcut = shortcut
  o.text = text

  setmetatable(o, self)
  return o
end

function Button:draw()
  self:move_cursor(0, 0)
  local focus_text
  if self.focus then
    focus_text = "*"
  else
    focus_text = " "
  end

  local text = focus_text .. "[" .. self.shortcut .. "]" .. self.text
  term.write(text)
end

local TitleBar = {}
TitleBar.__index = TitleBar
setmetatable(TitleBar, UIElement)

function TitleBar:new(x, y, w, h)
  local o = UIElement:new(x, y, w, h)
  setmetatable(o, self)
  return o
end

function TitleBar:draw()
  self:move_cursor(0, 0)
  term.write("Reactor monitor v" .. version)
end

local TITLE_HEIGHT = 1
local PANEL_HEIGHT = 4
local BUTTON_WIDTH = 10

-- start, pause, quit
local BUTTON_COUNT = 3

local screen_w
local screen_h
local elements = {}

local ui = {}

function ui.setup(reactors)
  term.clear()
  screen_w, screen_h = term.getViewport()

  local ui_element_idx = 1
  function add_ui_element(e)
    elements[ui_element_idx] = e
    ui_element_idx = ui_element_idx + 1
  end

  local title = TitleBar:new(1, 1, screen_w, TITLE_HEIGHT)
  add_ui_element(title)

  local button_cols = math.ceil(screen_w / BUTTON_WIDTH)
  local button_rows = math.ceil(BUTTON_COUNT / button_cols)
  local available_rows = screen_h - TITLE_HEIGHT - button_rows

  local panel_cols = 1
  while math.ceil((PANEL_HEIGHT * #reactors) / panel_cols) > available_rows do
    panel_cols = panel_cols + 1
  end

  local panel_width = screen_w // panel_cols
  for i, reactor in ipairs(reactors) do
    local offset_x = (i - 1) % panel_cols
    local offset_y = (i - 1) // panel_cols

    local panel = Panel:new(1 + offset_x * panel_width, TITLE_HEIGHT + 1 + offset_y * PANEL_HEIGHT, panel_width, panel_height, i, reactor)
    add_ui_element(panel)
  end

  local button_index = 0
  function add_button(shortcut, text)
    local offset_x = button_index % button_cols
    local offset_y = button_index // button_cols

    local button = Button:new(1 + offset_x * BUTTON_WIDTH, screen_h - button_rows + offset_y, BUTTON_WIDTH, 1, shortcut, text)
    add_ui_element(button)
    button_index = button_index + 1
  end

  add_button("S", "Start")
  add_button("P", "Pause")
  add_button("X", "Exit")
end

function ui.update(cmd)
  for i, e in ipairs(elements) do
    if e.shortcut then
      if e.shortcut == cmd then
        e.focus = true
      else
        e.focus = false
      end
    end
    e:draw()
  end
  term.setCursor(1, screen_h)
  term.write("Mem: " .. tostring(computer.totalMemory()) .. ", " .. tostring(computer.freeMemory()) .. " free")
end

return ui
