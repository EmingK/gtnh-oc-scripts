--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]
require('core.pal')
local pal = require('pal')

local function entry(module, ...)
  local fn = loadfile(module)
  fn(...)
end

-- setup mocked components
local component = palRequire('component')
local devices = require('pal.devices')

local rc1 = devices.Reactor:new()
local rsg = devices.Redstone:new()
local rs1 = devices.Redstone:new()
local tp1 = devices.Transposer:new()

local Inventory = devices.Inventory

local itemIn = Inventory:new(27)
local itemOut = Inventory:new(27)
local itemReactor = Inventory:new(54)

tp1:_connectInventory(1, itemIn)
tp1:_connectInventory(2, itemOut)
tp1:_connectInventory(3, itemReactor)

itemIn:setItem(0, { name = 'item.rod' })
itemIn:setItem(1, { name = 'item.coolant' })

component._register('addr_reactor', 'reactor_chamber', rc1)
component._register('addr_redstoneg', 'redstone', rsg)
component._register('addr_redstone1', 'redstone', rs1)
component._register('addr_transposer1', 'transposer', tp1)

pal.start(entry, ...)
