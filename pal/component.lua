local component = {}
local registry = {}

function component.list(filter, exact)
  local _filter
  if filter then
    _filter = function(n)
      if exact then
        return n == filter
      else
        return n:find(filter)
      end
    end
  else
    _filter = function() return true end
  end

  local ret = {}
  for a, entry in pairs(registry) do
    if _filter(entry.name) then
      ret[a] = entry.name
    end
  end

  local key = nil
  setmetatable(ret, { __call = function()
                        key = next(ret, key)
                        if key then
                          return key, ret[key]
                        end
  end})

  return ret
end

function component.get(address, componentType)
  for a, entry in pairs(registry) do
    if a:sub(1, #address) == address then
      if componentType then
        if componentType == entry.name then
          return a
        end
      else
        return a
      end
    end
  end
  return nil
end

local function makeProxy(i)
  local mt = {
    __index = function(t, k)
      return function(...) return i[k](i, ...) end
    end
  }
  return setmetatable({}, mt)
end

function component.proxy(address)
  local entry = registry[address]
  local i = entry and entry.instance
  return i and makeProxy(i)
end

function component._register(address, name, instance)
  registry[address] = {
    name = name,
    instance = instance
  }
end

return component
