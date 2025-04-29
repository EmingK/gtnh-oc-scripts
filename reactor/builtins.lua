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
    'gregtech:gt.reactorUraniumSimple',
    'gregtech:gt.reactorUraniumDual',
    'gregtech:gt.reactorUraniumQuad',
    'gregtech:gt.Thoriumcell',
    'gregtech:gt.Double_Thoriumcell',
    'gregtech:gt.Quad_Thoriumcell',
    'gregtech:gt.reactorMOXSimple',
    'gregtech:gt.reactorMOXDual',
    'gregtech:gt.reactorMOXQuad',
    'gregtech:gt.Naquadahcell',
    'gregtech:gt.Double_Naquadahcell',
    'gregtech:gt.Quad_Naquadahcell',
    'gregtech:gt.60k_Helium_Coolantcell',
    'gregtech:gt.180k_Helium_Coolantcell',
    'gregtech:gt.360k_Helium_Coolantcell',
    'gregtech:gt.60k_NaK_Coolantcell',
    'gregtech:gt.180k_NaK_Coolantcell',
    'gregtech:gt.360k_NaK_Coolantcell',
    'IC2:reactorVentCore',
  }

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
  builtins.check = checks
end

return builtins
