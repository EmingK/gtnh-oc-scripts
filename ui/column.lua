--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local directionContainerLayout = require('ui.layout')
local Navigation = require('ui.navigation')
local wrap = require('ui.wrap_class')
local Container = require('ui.container').class

local Column = class(Container)

function Column:layout()
  directionContainerLayout(self, 'h', 'w', 'y', 'x')
  -- print('-- column layout')
  -- for i, c in ipairs(self.children) do
  --   print(string.format('children %d: x=%d, y=%d, w=%d, h=%d', i, c.rect.x, c.rect.y, c.rect.w, c.rect.h))
  -- end
end

function Column:initSelection(navFrom)
  if navFrom == Navigation.up then
    -- reverse order
    for i = #self.children, 1, -1 do
      local selected = self.children[i]:initSelection(navFrom)
      if selected then
        return selected
      end
    end
    return nil
  end

  return Container.initSelection(self, navFrom)
end

function Column:handleNavigation(nav)
  if nav == Navigation.up then
    return self:trySelectPrevChild(nav)
  elseif nav == Navigation.down then
    return self:trySelectNextChild(nav)
  end
  return Container.handleNavigation(self, nav)
end

return wrap(Column)
