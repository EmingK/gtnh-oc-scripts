local function class(super)
  local c = {}
  c.__index = c
  setmetatable(c, super)

  function c:new(...)
    local o
    if super then
      o = super:new(...)
    else
      o = {}
    end
    setmetatable(o, self)
    o:init(...)
    return o
  end

  return c
end

return class
