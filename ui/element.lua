--[[
  Copyright (c) 2024-2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local Navigation = require('ui.navigation')
local wrap = require('ui.wrap_class')

local UIElement = class()

--[[
  UIElement constructor.

  Subclasses must call constructor of super class.
]]
function UIElement:init()
  self.rect = { x = 0, y = 0, w = 0, h = 0 }
  self.intrinsicSize = {}
  self.needUpdate = true
end

-- MARK: - Property modifiers

--[[
  Specify a fixed size of this view.

  If a length property is nil, it will be stretched in its container.
]]
function UIElement:size(w, h)
  self.intrinsicSize.w = w
  self.intrinsicSize.h = h
  return self
end

function UIElement:makeSelectable(selectable)
  self.selectable = selectable
  return self
end

function UIElement:setSelected(state)
  if state ~= self.selected then
    self.selected = state
    self:setNeedUpdate()
  end
end

function UIElement:action(a)
  self._action = a
  return self
end

-- MARK: - Painting

--[[
  Paint its content to the screen. Subclasses must override this method.

  @param gpu the GPU object provided by the OpenOS API.
]]
function UIElement:draw(gpu)
  error("UIElement:draw() method should be overriden")
end

--[[
  Clear its painting area.

  Subclasses generally do not override this method.
]]
function UIElement:clear(gpu)
  gpu.fill(self.rect.x, self.rect.y, self.rect.w, self.rect.h, ' ')
end

--[[
  Update the element's visual contents.

  The default implementation redraws the component completely. Subclasses may 
  override this method to do partial updates.
]]
function UIElement:update(gpu)
  if self.window and self.needUpdate then
    self.needUpdate = false
    self:draw(gpu)
  end
end

--[[
  Mark this component to be updated.

  Updates are batched to reduce duplicated painting.
]]
function UIElement:setNeedUpdate()
  self.needUpdate = true
  if self.window then
    self.window:enqueueUpdate(self)
  end
end

--[[
  Notify the element is moved to a window.

  Updates are bound to the element's window. Only the foreground window handles
  updates. Background windows will be updated when they are brought to foreground.
]]
function UIElement:moveToWindow(win)
  self.window = win
end

--[[
  Helper method to get the screen coordinate of relative coordinates from this 
  element. Useful when implementing the `draw()` method.
]]
function UIElement:screenPos(x, y)
  return self.rect.x + x, self.rect.y + y
end

-- MARK: - Arrow key navigation support

--[[
  Decide the element to be selected when a cursor enters selection into this
  element.
]]
function UIElement:initSelection(navFrom)
  if self.selectable then
    return self
  end
  return nil
end

--[[
  Handles arrow key navigation.

  When this component is selected and arrow key is pressed, this method is called
  with the navigation direction.

  @returns the next element should be selected. If this element cannot decide the
           element to be selected, nil is returned.
]]
function UIElement:handleNavigation(nav)
  if self.parent then
    return self.parent:handleNavigation(nav)
  end
  return nil
end

-- MARK: - Touch screen support

--[[
  Find the component under screen coordinate (x, y).

  This is used to implement touch interactions.
]]
function UIElement:elementAtPoint(x, y)
  if x >= self.rect.x and y >= self.rect.y and x < self.rect.x + self.rect.w and y < self.rect.y + self.rect.h then
    return self
  else
    return nil
  end
end

function UIElement:getAction()
  return self._action
end

-- MARK: - Reserved / unused

function UIElement:keyShortcut(key, action)
  self.keyShortcut = key
  self.keyAction = action
  return self
end

function UIElement:onClick(action)
  self.clickAction = action
  return self
end

return wrap(UIElement)
