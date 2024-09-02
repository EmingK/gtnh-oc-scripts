local Redstone = {}

function Redstone:getInput(side)
  local result
  self.count[side] = self.count[side] + 1
  if self.conut[side] >= self.count_set[side] then
    result = self.target_val[side]
  else
    result = self.init_val[side]
  end

  print("rs getInput(" .. self.a .. ", " .. side .. ") = " .. result)
  self.current_val[side] = result
  return result
end

function Redstone:setOutput(side, val)
  print("rs setOutput(" .. self.a .. ", " .. side .. ") = " .. val)
  self.current_val[side] = val
end



local classes = {
  redstone = Redstone,
  transposer = Transposer,
  reactor = Reactor,
}

local registry = {}

local function component_get(a)
  if registry[a] == nil then
    return nil
  end
  return a
end

local function component_proxy(a)
  return registry[a]
end

return {
  get = component_get,
  proxy = component_proxy,

  -- mock
  register = component_register,
  classes = classes,
}
