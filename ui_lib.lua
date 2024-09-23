local term = require('term')
local unicode = require('unicode')

local class = require('class')
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

local UIElement = class()

function UIElement:init()
  self.rect = { x = 0, y = 0, w = 0, h = 0 }
  self.intrinsic_size = {}
end

function UIElement:draw()
  error("Override me")
end

function UIElement:clear()
  term.gpu().fill(self.rect.x, self.rect.y, self.rect.w, self.rect.h, ' ')
end

function UIElement:update()
end

function UIElement:move_cursor(x, y)
  term.setCursor(self.rect.x + x, self.rect.y + y)
end

local function direction_container_layout(c, main, cross, main_offset, cross_offset)
  local w = c.rect[main]

  local fixed = 0
  local n_flex = 0
  for i, child in ipairs(c.children) do
    if child.intrinsic_size[main] then
      fixed = fixed + child.intrinsic_size[main]
    else
      n_flex = n_flex + 1
    end
  end
  local unit = 0
  if n_flex > 0 then unit = (w - fixed) // n_flex end

  local x = 0
  for i, child in ipairs(c.children) do
    local child_main, child_cross
    if child.intrinsic_size[main] then
      child_main = child.intrinsic_size[main]
    else
      child_main = unit
    end
    child_cross = child.intrinsic_size[cross] or c.rect[cross]

    child.rect[main_offset] = c.rect[main_offset] + x
    child.rect[cross_offset] = c.rect[cross_offset]
    child.rect[main] = child_main
    child.rect[cross] = child_cross

    if child.children then
      child:layout()
    end

    x = x + child_main
  end
end

local Container = class(UIElement)

function Container:init()
  self.children = {}
end

function Container:add_subview(v)
  table.insert(self.children, v)
  v.parent = self
end

function Container:draw()
  for i, child in ipairs(self.children) do
    child:draw()
  end
end

function Container:update()
  for i, child in ipairs(self.children) do
    child:update()
  end
end

function Container:layout(w, h)
  error("Override me")
end

local Row = class(Container)

function Row:layout()
  direction_container_layout(self, 'w', 'h', 'x', 'y')
end

local Column = class(Container)

function Column:layout()
  direction_container_layout(self, 'h', 'w', 'y', 'x')
end

local Label = class(UIElement)

function Label:init(text)
  self.text = text
end

function Label:draw()
  self:clear()
  self:move_cursor(0, 0)
  term.write(self.text)
end

function Label:set_text(t)
  if self.text ~= t then
    self.text = t
    self:draw()
  end
end

local Button = class(UIElement)

function Button:init(text)
  self.text = text
  self.active = false
end

function Button:draw()
  local gpu = term.gpu()
  local bg = gpu.getBackground()
  local fg = gpu.getForeground()
  if self.active then
    gpu.setBackground(fg)
    gpu.setForeground(bg)
  end

  self:clear()
  self:move_cursor(0, 0)
  term.write(self.text)

  gpu.setBackground(bg)
  gpu.setForeground(fg)
end

function Button:set_active(a)
  if self.active ~= a then
    self.active = a
    self:draw()
  end
end

function Button:set_text(t)
  if self.text ~= t then
    self.text = t
    self:draw()
  end
end

local Grid = class(Container)

function Grid:layout()
  if #self.children == 0 then return end
  local child1 = self.children[1]

  local w = self.rect.w
  local h = self.rect.h
  local cw = child1.intrinsic_size.w
  local ch = child1.intrinsic_size.h

  local nr = 1
  local nc = 1

  if cw == nil and ch == nil then
    error("Grid element must have at least 1 intrinsic size")
  end

  if cw == nil then
    while math.ceil(#self.children / nc) * ch > h do nc = nc + 1 end
    cw = w // nc
  end

  if ch == nil then
    while math.ceil(#self.children / nr) * cw > w do nr = nr + 1 end
    ch = h // nr
  end

  nc = w // cw
  nr = math.ceil(#self.children / nc)

  for i, child in ipairs(self.children) do
    local x = (i - 1) % nc
    local y = (i - 1) // nc

    child.rect.x = self.rect.x + x * cw
    child.rect.y = self.rect.y + y * ch
    child.rect.w = cw
    child.rect.h = ch

    if child.children then
      child:layout()
    end
  end
end

local Frame = class(Container)

function Frame:init(title)
  self.title = title
end

function Frame:draw()
  local w = self.rect.w
  local top_count = (w - 2 - #self.title)
  local top = borders.tl .. self.title .. borders.t:rep(top_count) .. borders.tr

  self:move_cursor(0, 0)
  term.write(top)

  local h = self.rect.h
  for y = 1, h - 2, 1 do
    self:move_cursor(0, y)
    term.write(borders.l)
    self:move_cursor(w - 1, y)
    term.write(borders.r)
  end

  self:move_cursor(0, h - 1)
  term.write(borders.bl .. borders.b:rep(w - 2) .. borders.br)

  local child = self.children[1]
  if child then
    child:draw()
  end
end

function Frame:layout()
  local child = self.children[1]
  if not child then return end
  child.rect.x = self.rect.x + 1
  child.rect.y = self.rect.y + 1
  child.rect.w = self.rect.w - 2
  child.rect.h = self.rect.h - 2

  if child.children then
    child:layout()
  end
end

local Progress = class(UIElement)

function Progress:init(value)
  self.value = value
end

local progress_sym = {
  filled = unicode.char(0x2588),
  blank = unicode.char(0x2591)
}

function Progress:draw()
  self:move_cursor(0, 0)
  local w = self.rect.w
  local left = math.floor(w * self.value + 0.5)
  local right = w - left

  local str = progress_sym.filled:rep(left) .. progress_sym.blank:rep(right)
  term.write(str)
end

function Progress:set_value(v)
  if self.value ~= v then
    self.value = v
    self:draw()
  end
end

local function layout(root, rect)
  root.rect = rect
  root:layout()
end

return {
  UIElement = UIElement,
  Container = Container,
  Row = Row,
  Column = Column,
  Label = Label,
  Button = Button,
  Frame = Frame,
  Grid = Grid,
  Progress = Progress,
  layout = layout,
}
