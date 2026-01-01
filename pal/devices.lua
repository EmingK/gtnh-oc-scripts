--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')

local Reactor = class()

function Reactor:getHeat()
  return 6500
end

function Reactor:getMaxHeat()
  return 10000
end

local Redstone = class()

function Redstone:getInput(direction)
  return 15
end

function Redstone:setOutput(direction, value)
end

local Transposer = class()

function Transposer:init()
  self.sides = {}
end

function Transposer:getAllStacks(direction)
  local inventory = self.sides[direction]
  local items = inventory and inventory.items

  return {
    getAll = function() return items end
  }
end

function Transposer:transferItem(from, to, quantity, fromIndex, toIndex)
  local fromItem = self.sides[from].items[fromIndex - 1]
  self.sides[to]:setItem(toIndex - 1, fromItem)
  return 1
end

function Transposer:_connectInventory(side, inventory)
  self.sides[side] = inventory
end

local Inventory = class()

function Inventory:init(_, count)
  local items = {}
  for i = 0, count - 1 do
    items[i] = {}
  end
  self.items = items
end

function Inventory:setItem(index, item)
  self.items[index] = item
end

local GTMachine = class()

function GTMachine:init(_, capacity, stored)
  self.capacity = capacity or 100000000  -- Default 100M EU
  self.stored = stored or 50000000       -- Default 50M EU
end

function GTMachine:getEUCapacity()
  return self.capacity
end

function GTMachine:getStoredEU()
  return self.stored
end

function GTMachine:setStoredEU(amount)
  self.stored = math.max(0, math.min(amount, self.capacity))
end

return {
  Reactor = Reactor,
  Redstone = Redstone,
  Transposer = Transposer,
  Inventory = Inventory,
  GTMachine = GTMachine,
}
