--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')

local wrap = require('ui.wrap_class')
local Row = require('ui.row')
local Column = require('ui.column').class
local Label = require('ui.label')

local unicode = palRequire('unicode')
local term = palRequire('term')

local symbols = {
  normal = unicode.char(0x2500),
  highlight = unicode.char(0x2580),
}

local Tabs = class(Column)

function Tabs:init(super, tabs)
  super.init({})
  self.tabs = tabs
  self.selectedTabIndex = 1

  local tabRow = Row():size(nil, 2)
  self.tabRow = tabRow
  for i, item in ipairs(tabs) do
    local label = Label(item[1]):size(nil, 1):makeSelectable(true)
    tabRow:addSubview(label)
  end
  
  local origInitSelection = tabRow.initSelection
  local origHandleNavigation = tabRow.handleNavigation
  local outerSelf = self

  -- override the tabRow instance methods
  function tabRow:initSelection(nav)
    -- always select the current tab index
    self.selectionIndex = outerSelf.selectedTabIndex
    return self.children[self.selectionIndex]
  end

  function tabRow:handleNavigation(nav)
    local result = origHandleNavigation(self, nav)
    if self.selectionIndex then
      outerSelf:selectTab(self.selectionIndex)
    end
    return result
  end

  self:addSubview(tabRow)
  self:addSubview(tabs[1][2])
end

function Tabs:selectTab(index)
  if index == self.selectedTabIndex then
    return
  end
  self.selectedTabIndex = index
  local oldChild = self.children[2]
  local newChild = self.tabs[index][2]

  self.children[2] = newChild
  oldChild:moveToWindow(nil)
  newChild.parent = self
  newChild:moveToWindow(self.window)
  
  self:layout()
  self:setNeedUpdate()
end

function Tabs:draw(gpu)
  self:clear(gpu)
  Column.draw(self, gpu)
  self:drawTabLine(gpu)
end

function Tabs:drawTabLine(gpu)
  local selectedLabel = self.tabRow.children[self.selectedTabIndex]
  if not selectedLabel then
    return
  end

  local rowRect = self.tabRow.rect
  local rect = selectedLabel.rect
  gpu.set(rowRect.x, rowRect.y + 1, symbols.normal:rep(rowRect.w))
  gpu.set(rect.x, rect.y + 1, symbols.highlight:rep(rect.w))
end

return wrap(Tabs)
