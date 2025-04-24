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
    [_T('item_name_u1')] = "gregtech:gt.reactorUraniumSimple",
    [_T('item_name_u2')] = "gregtech:gt.reactorUraniumDual",
    [_T('item_name_u4')] = "gregtech:gt.reactorUraniumQuad",
    [_T('item_name_th1')] = "gregtech:gt.Thoriumcell",
    [_T('item_name_th2')] = "gregtech:gt.Double_Thoriumcell",
    [_T('item_name_th4')] = "gregtech:gt.Quad_Thoriumcell",
    [_T('item_name_mox1')] = "gregtech:gt.reactorMOXSimple",
    [_T('item_name_mox2')] = "gregtech:gt.reactorMOXDual",
    [_T('item_name_mox4')] = "gregtech:gt.reactorMOXQuad",
    [_T('item_name_nq1')] = "gregtech:gt.Naquadahcell",
    [_T('item_name_nq2')] = "gregtech:gt.Double_Naquadahcell",
    [_T('item_name_nq4')] = "gregtech:gt.Quad_Naquadahcell",
    [_T('item_name_he60')] = "gregtech:gt.60k_Helium_Coolantcell",
    [_T('item_name_he180')] = "gregtech:gt.180k_Helium_Coolantcell",
    [_T('item_name_he360')] = "gregtech:gt.360k_Helium_Coolantcell",
    [_T('item_name_nak60')] = "gregtech:gt.60k_NaK_Coolantcell",
    [_T('item_name_nak180')] = "gregtech:gt.180k_NaK_Coolantcell",
    [_T('item_name_nak360')] = "gregtech:gt.360k_NaK_Coolantcell",
    [_T('item_name_reactorVent')] = "IC2:reactorVentCore"
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
