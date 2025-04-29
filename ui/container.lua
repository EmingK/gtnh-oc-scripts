--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local wrap = require('ui.wrap_class')
local UIElement = require('ui.element').class

local Container = class(UIElement)

function Container:init(super, children)
  super.init()
  self.selectionIndex = nil
  self.children = {}
  if children then
    for _, child in ipairs(children) do
      self:addSubview(child)
    end
  end
end

function Container:addSubview(v)
  table.insert(self.children, v)
  v.parent = self
  v:moveToWindow(self.window)
end

function Container:moveToWindow(win)
  self.window = win
  for _, child in ipairs(self.children) do
    child:moveToWindow(win)
  end
end

function Container:draw(gpu)
  for _, child in ipairs(self.children) do
    child:draw(gpu)
    child.needUpdate = false
  end
end

function Container:initSelection(navFrom)
  for i, child in ipairs(self.children) do
    local selected = child:initSelection(navFrom)
    if selected then
      self.selectionIndex = i
      return selected
    end
  end
  return nil
end

function Container:trySelectPrevChild(nav)
  local nextSelectionIndex = self.selectionIndex - 1
  while nextSelectionIndex > 0 do
    local nextSelectedElement = self.children[nextSelectionIndex]:initSelection(nav)
    if nextSelectedElement then
      self.selectionIndex = nextSelectionIndex
      return nextSelectedElement
    end
    nextSelectionIndex = nextSelectionIndex - 1
  end
  return Container.handleNavigation(self, nav)
end

function Container:trySelectNextChild(nav)
  local nextSelectionIndex = self.selectionIndex + 1
  while nextSelectionIndex <= #self.children do
    local nextSelectedElement = self.children[nextSelectionIndex]:initSelection(nav)
    if nextSelectedElement then
      self.selectionIndex = nextSelectionIndex
      return nextSelectedElement
    end
    nextSelectionIndex = nextSelectionIndex + 1
  end
  return Container.handleNavigation(self, nav)
end

function Container:handleNavigation(nav)
  if self.parent then
    local next = self.parent:handleNavigation(nav)
    if next then
      -- navigated outside of this container
      self.selectionIndex = nil
      return next
    end
  end
  return nil
end

function Container:elementAtPoint(x, y)
  for _, child in ipairs(self.children) do
    if child:elementAtPoint(x, y) then
      return child
    end
  end
  return UIElement.elementAtPoint(self, x, y)
end

function Container:layout(w, h)
  error("Override me")
end

return wrap(Container)
