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
    { id = 'gregtech:gt.rodUranium', reusable = true, },
    { id = 'gregtech:gt.rodUranium2', reusable = true, },
    { id = 'gregtech:gt.rodUranium4', reusable = true, },
    { id = 'gregtech:gt.rodThorium', reusable = true, },
    { id = 'gregtech:gt.rodThorium2', reusable = true, },
    { id = 'gregtech:gt.rodThorium4', reusable = true, },
    { id = 'gregtech:gt.rodMOX', reusable = true, },
    { id = 'gregtech:gt.rodMOX2', reusable = true, },
    { id = 'gregtech:gt.rodMOX4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah2', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah4', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium2', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityUranium4', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium2', reusable = true, },
    { id = 'gregtech:gt.rodHighDensityPlutonium4', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium2', reusable = true, },
    { id = 'gregtech:gt.rodExcitedUranium4', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium2', reusable = true, },
    { id = 'gregtech:gt.rodExcitedPlutonium4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria2', reusable = true, },
    { id = 'gregtech:gt.rodNaquadria4', reusable = true, },
    { id = 'gregtech:gt.rodTiberium', reusable = true, },
    { id = 'gregtech:gt.rodTiberium2', reusable = true, },
    { id = 'gregtech:gt.rodTiberium4', reusable = true, },
    { id = 'gregtech:gt.rodNaquadah32', reusable = true, },
    { id = 'gregtech:gt.rodGlowstone', reusable = true, },
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
    { id = 'IC2:reactorPlating', reusable = true, heatCapacity = 1000, },
    { id = 'IC2:reactorPlatingExplosive', reusable = true, heatCapacity = 500, },
    { id = 'IC2:reactorPlatingHeat', reusable = true, heatCapacity = 1700, },
  }

  local reuseableItems = {}
  for _, itemInfo in ipairs(items) do
    reuseableItems[itemInfo.id] = itemInfo.reusable
  end

  local heatCapacityMapping = {}
  for _, itemInfo in ipairs(items) do
    if itemInfo.heatCapacity then
      heatCapacityMapping[itemInfo.id] = itemInfo.heatCapacity
    end
  end

  local function isReusable(item)
    return reuseableItems[item] == true
  end

  local function getHeatCapacity(item)
    return heatCapacityMapping[item] or 0
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
  builtins.getHeatCapacity = getHeatCapacity
end

return builtins
