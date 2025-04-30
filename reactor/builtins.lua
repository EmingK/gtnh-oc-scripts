--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local builtins = {}

function builtins.setup()
  local schemas = {
    {
      name = 'builtin.vacuum',
      displayName = _T('schema_name_vacuum'),
      size = {
        w = 9,
        h = 6,
      },
      count = 54,
      layout = {
        'B', 'A', 'A', 'A', 'B', 'A', 'A', 'B', 'A',
        'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A',
        'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A', 'A',
        'A', 'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B',
        'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A',
        'A', 'B', 'A', 'A', 'B', 'A', 'A', 'A', 'B'
      }
    },
    {
      name = 'builtin.single',
      displayName = _T('schema_name_single'),
      size = {
        w = 9,
        h = 6,
      },
      count = 54,
      layout = {
        'A'
      }
    }
  }

  local items = {
    { id = 'gregtech:gt.reactorUraniumSimple', reusable = true, },
    { id = 'gregtech:gt.reactorUraniumDual', reusable = true, },
    { id = 'gregtech:gt.reactorUraniumQuad', reusable = true, },
    { id = 'gregtech:gt.Thoriumcell', reusable = true, },
    { id = 'gregtech:gt.Double_Thoriumcell', reusable = true, },
    { id = 'gregtech:gt.Quad_Thoriumcell', reusable = true, },
    { id = 'gregtech:gt.reactorMOXSimple', reusable = true, },
    { id = 'gregtech:gt.reactorMOXDual', reusable = true, },
    { id = 'gregtech:gt.reactorMOXQuad', reusable = true, },
    { id = 'gregtech:gt.Naquadahcell', reusable = true, },
    { id = 'gregtech:gt.Double_Naquadahcell', reusable = true, },
    { id = 'gregtech:gt.Quad_Naquadahcell', reusable = true, },
    { id = 'GoodGenerator:rodCompressedUranium', reusable = true, },
    { id = 'GoodGenerator:rodCompressedUranium2', reusable = true, },
    { id = 'GoodGenerator:rodCompressedUranium4', reusable = true, },
    { id = 'GoodGenerator:rodCompressedPlutonium', reusable = true, },
    { id = 'GoodGenerator:rodCompressedPlutonium2', reusable = true, },
    { id = 'GoodGenerator:rodCompressedPlutonium4', reusable = true, },
    { id = 'GoodGenerator:rodLiquidUranium', reusable = true, },
    { id = 'GoodGenerator:rodLiquidUranium2', reusable = true, },
    { id = 'GoodGenerator:rodLiquidUranium4', reusable = true, },
    { id = 'GoodGenerator:rodLiquidPlutonium', reusable = true, },
    { id = 'GoodGenerator:rodLiquidPlutonium2', reusable = true, },
    { id = 'GoodGenerator:rodLiquidPlutonium4', reusable = true, },
    { id = 'gregtech:gt.MNqCell', reusable = true, },
    { id = 'gregtech:gt.Double_MNqCell', reusable = true, },
    { id = 'gregtech:gt.Quad_MNqCell', reusable = true, },
    { id = 'gregtech:gt.Tiberiumcell', reusable = true, },
    { id = 'gregtech:gt.Double_Tiberiumcell', reusable = true, },
    { id = 'gregtech:gt.Quad_Tiberiumcell', reusable = true, },
    { id = 'gregtech:gt.Core_Reactor_Cell', reusable = true, },
    { id = 'gregtech:gt.glowstoneCell', reusable = true, },
    { id = 'gregtech:gt.60k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.60k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.540k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.1080k_Space_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.neutroniumHeatCapacitor', reusable = false, },
    { id = 'IC2:reactorVentCore', reusable = true, },
  }

  local reuseableItems = {}
  for _, itemInfo in ipairs(items) do
    reuseableItems[itemInfo.id] = itemInfo.reusable
  end

  local function isReusable(item)
    return reuseableItems[item] == true
  end

  local checks = {
    noCheck = function() return false end,
    damageLess = function(threshold)
      return function(item)
        if item.damage == nil then
          return false
        end

        local t = item.maxDamage * threshold
        return (item.maxDamage - item.damage) <= t
      end
    end
  }

  builtins.schemas = schemas
  builtins.items = items
  builtins.isReusable = isReusable
  builtins.check = checks
end

return builtins
