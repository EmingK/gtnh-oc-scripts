--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  OO support for Lua.

  This module generates the class and its new and init method
  stubs, to support OO programming style.

  Example:

  ```lua
  local Base = class()
  local Derived = class(Base)

  function Derived:init(super, a)
    super.init()
    self.a = a
  end

  local d = Derived:new(1)
  ```
]]

--[[
  Find the concrete class which implements the specific method.
]]
local function findImplClass(class, method)
  local currentClass = class
  while currentClass do
    if rawget(currentClass, method) then
      return currentClass
    end
    currentClass = getmetatable(currentClass)
  end
  return nil
end

-- Forward declaration for recursive calls of functions below.
local invokeSuper

--[[
  Create a `super` object for an instance method. The `super` object
  guarantees method invocation on this object invoke the implementation
  from its superclass.
]]
local function createSuper(object, class)
  local base = getmetatable(class) or {}
  local superMt = {
    __index = function(_, method)
      if type(base[method]) == 'function' then
        return function(...)
          invokeSuper(object, base, method, ...)
        end
      end
      return nil
    end
  }
  return setmetatable({}, superMt)
end

--[[
  Invoke the superclass implementation of a method.
]]
invokeSuper = function(object, superClass, method, ...)
  local base = findImplClass(superClass, method)
  if base then
    local super = createSuper(object, base)
    base[method](object, super, ...)
  end
end

-- A root class to prevent subclasses invoke `super.init()` unexpectedly.
local ObjectClass = {
  init = function() end
}

--[[
  Create a class object.

  The class have a generated `new` method, used to create an
  instance. If the class implements an `init` method, the `new`
  method will intoke that with a super object.
]]
local function makeClass(base)
  local class = {}
  class.__index = class
  setmetatable(class, base or ObjectClass)

  -- We may want a super object for every instant method. However
  -- this brings more overhead, since OpenOS has limited "hardware"
  -- resource, we only support a super object for the `init` method.
  -- For other methods, using `Base.method(self, ...)` is needed.
  function class:new(...)
    local object = setmetatable({}, class)
    local implClass = findImplClass(class, 'init')

    if implClass then
      local initMethod = rawget(implClass, 'init')
      initMethod(object, createSuper(object, implClass), ...)
    end
    return object
  end

  return class
end

return makeClass
