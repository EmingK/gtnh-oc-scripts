--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local term = palRequire('term')
local keyboard = palRequire('keyboard')

local class = require('core.class')
local Navigation = require('ui.navigation')

local Window = class()

function Window:init(_)
  self.updateQueue = {}
end

--[[
  [Must override] setup the UI for a window.

  Subclasses should override this method and set ui property of this object.
]]
function Window:onLoad()
  error('Should override Window:onLoad()')
end

--[[
  [Optional override] Do cleanup when the window get dismissed.
]]
function Window:onUnload()
end

function Window:handleEvent(name, ...)
  if self.presentedWindow then
    self.presentedWindow:handleEvent(name, ...)
    return
  end

  local handler = self['on_' .. name]
  if handler then
    handler(self, ...)
  end
end

--[[
  Present another window over this window.

  This method saves screen content and restores after the new window is dismissed.

  @param aWindow The window to be presented.
  @param resultHandler callback for the result of the presented window. The result
                       is passed via the window's `dismiss` method.
]]
function Window:present(aWindow, resultHandler)
  local gpu = term.gpu()

  local w, h = gpu.getResolution()
  local bg = gpu.allocateBuffer(w, h)
  gpu.bitblt(bg, 1, 1, w, h, 0)

  self.presentedWindow = aWindow
  self.app:present(
    aWindow,
    function(...)
      self.presentedWindow = nil
      gpu.bitblt(0, 1, 1, w, h, bg)
      gpu.freeBuffer(bg)
      self.ui:setNeedUpdate()
      if resultHandler then
        resultHandler(...)
      end
    end
  )
end

--[[
  Dismiss the current window.
]]
function Window:dismiss(...)
  if self.dismissHandler then
    self.dismissHandler(...)
  end
end

function Window:enqueueUpdate(element)
  table.insert(self.updateQueue, element)
  self.app:enqueueUpdate()
end

function Window:update(gpu)
  if self.presentedWindow then
    self.presentedWindow:update(gpu)
    return
  end

  local q = self.updateQueue
  self.updateQueue = {}

  for _, e in pairs(q) do
    e:update(gpu)
  end
end

-- MARK: - keyboard navigation

function Window:initSelection()
  local selectedElement = self.ui:initSelection(nil)
  self.selectedElement = selectedElement
  if selectedElement then
    self.selectedElement:setSelected(true)
  end
end

function Window:on_key_down(device, key, keycode)
  if keycode == keyboard.keys.enter and self.selectedElement then
    local actionParams = table.pack(self.selectedElement:getAction())
    if #actionParams >= 1 then
      local action = table.remove(actionParams, 1)
      if self[action] then
        self[action](self, table.unpack(actionParams))
        return
      end
    end
  end

  local navigation = nil
  if keycode == keyboard.keys.up then
    navigation = Navigation.up
  elseif keycode == keyboard.keys.down then
    navigation = Navigation.down
  elseif keycode == keyboard.keys.left then
    navigation = Navigation.left
  elseif keycode == keyboard.keys.right then
    navigation = Navigation.right
  end

  if navigation and self.selectedElement then
    local nextElement = self.selectedElement:handleNavigation(navigation)
    if nextElement then
      self.selectedElement:setSelected(false)
      nextElement:setSelected(true)
      self.selectedElement = nextElement
    end
  end
end

return Window