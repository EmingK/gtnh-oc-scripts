function redstone()
  local r = {
    inputs = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
    outputs = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
  }
  r.getInput = function(side) return r.inputs[side] end
  r.setOutput = function(side, val) r.outputs[side] = val end
  return r
end

function reactor()
  return {}
end

function transposer()
  return {}
end

return {
  redstone = redstone,
  reactor = reactor,
  transposer = transposer,
}
