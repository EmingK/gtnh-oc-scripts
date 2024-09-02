local function no_check()
  --return function(item)
    return false
  --end
end

local function damage_less_than(threshold)
  return function(item)
    if item.damage == nil then
      return false
    end

    local t = item.maxDamage * threshold
    return (item.maxDamage - item.damage) <= t
  end
end

local layouts = {
  vacuum = {
    width = 9,
    height = 6,
    layout = {
      'B', 'A', 'A', 'A', 'B', 'A', 'A', 'B', 'A',
      'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A',
      'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A', 'A',
      'A', 'A', 'A', 'B', 'A', 'A', 'A', 'A', 'B',
      'A', 'B', 'A', 'A', 'A', 'A', 'B', 'A', 'A',
      'A', 'B', 'A', 'A', 'B', 'A', 'A', 'A', 'B'
    }
  }
}

local items = {
  u1 = "gregtech:gt.reactorUraniumSimple",
  u2 = "gregtech:gt.reactorUraniumDual",
  u4 = "gregtech:gt.reactorUraniumQuad",
  th1 = "gregtech:gt.Thoriumcell",
  th2 = "gregtech:gt.Double_Thoriumcell",
  th4 = "gregtech:gt.Quad_Thoriumcell",
  mox1 = "gregtech:gt.reactorMOXSimple",
  mox2 = "gregtech:gt.reactorMOXDual",
  mox4 = "gregtech:gt.reactorMOXQuad",
  nq1 = "gregtech:gt.Naquadahcell",
  nq2 = "gregtech:gt.Double_Naquadahcell",
  nq4 = "gregtech:gt.Quad_Naquadahcell",
  he60 = "gregtech:gt.60k_Helium_Coolantcell",
  he180 = "gregtech:gt.180k_Helium_Coolantcell",
  he360 = "gregtech:gt.360k_Helium_Coolantcell",
  nak60 = "gregtech:gt.60k_NaK_Coolantcell",
  nak180 = "gregtech:gt.180k_NaK_Coolantcell",
  nak360 = "gregtech:gt.360k_NaK_Coolantcell",
}

local function build(cfg)
  local result = {}
  for i, name in ipairs(cfg.layout.layout) do
    result[i] = cfg.items[name]
  end
  return result
end

return {
  build = build,
  layouts = layouts,
  items = items,
  checkers = {
    none = no_check,
    damage_less_than = damage_less_than
  },
}
