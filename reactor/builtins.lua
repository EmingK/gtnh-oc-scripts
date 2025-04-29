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
    { id = 'gregtech:gt.glowstoneCell', reusable = true, },
    { id = 'gregtech:gt.60k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_Helium_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.60k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.180k_NaK_Coolantcell', reusable = false, },
    { id = 'gregtech:gt.360k_NaK_Coolantcell', reusable = false, },
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
