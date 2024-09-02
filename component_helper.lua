local component = require('component')

local function make_address(addr)
  local c = component.get(addr)
  if c == nil then
   error('component not found: ' .. addr)
   return nil
  end
  return component.proxy(c)
end

local function make_side(addr, side)
  local c = make_address(addr)
  return {
    comp = c,
    side = side,
  }
end

local Redstone = {}

function Redstone:on()
  self.comp.setOutput(self.side, 15)
end

function Redstone:off()
  self.comp.setOutput(self.side, 0)
end

function Redstone:get()
  return self.comp.getInput(self.side) ~= 0
end

function Redstone:new(o)
  setmetatable(o, self)
  self.__index = self
  return o
end

return {
  address = make_address,
  with_side = make_side,
  Redstone = Redstone,
}
