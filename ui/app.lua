--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  App is an abstraction over tui application.

  The App class manages its own run loop, sub classes should
  implement the UI and event handling.
]]

local class = require('core.class')
local utils = require('core.utils')
local Runloop = require('core.runloop')

local term = palRequire('term')

local App = class()

-- MARK: - App methods

function App:init(_, options)
  self.runloop = Runloop:new()
  self.options = options or {}
  self.hasUpdates = false
  App.shared = self
end

function App:start(window)
  self.window = window
  self:app_setup()
  self.runloop:addEventHandler(self)
  if not self.options.debug and self.window then
    self:present(window, utils.bind(self.stop, self))
  else --for debug
    window.app = self
    window.dismissHandler = utils.bind(self.stop, self)
    window:onLoad()
  end
  self.runloop:run()
end

function App:stop(reload)
  if reload then
    self:present(self.window, utils.bind(self.stop, self))
    return
  end
  self.runloop:stop()
end

function App:present(window, handler)
  window.app = self
  self.runloop:enqueueIdle(
    'App_UI',
    function()
      window.dismissHandler = handler
      window:onLoad()
      -- layout
      local w, h, x, y = term.getViewport()
      if window.preferredSize then
        local newW = math.min(w, window.preferredSize.w)
        local newH = math.min(h, window.preferredSize.h)
        local newX = (x + 1) + (w - newW) // 2
        local newY = (y + 1) + (h - newH) // 2
        window.ui.rect = {x = newX, y = newY, w = newW, h = newH }
      else
        window.ui.rect = { x = x + 1, y = y + 1, w = w, h = h }
      end
      window.ui:layout()
      window.ui:moveToWindow(window)
      window:initSelection()
      window.ui:setNeedUpdate()
    end
  )
end

function App:handleEvent(name, ...)
  if not name then return end

  debugLog(name, ...)
  self.window:handleEvent(name, ...)
end

function App:enqueueUpdate()
  if self.hasUpdates then
    return
  end
  self.hasUpdates = true

  self.runloop:enqueueIdle(
    'App_UI',
    function()
      self.hasUpdates = false
      if self.window then
        self.window:update(term.gpu())
      end
    end
  )
end

-- MARK: - Subclass overrides

function App:app_setup()
end

-- MARK: - Exports

return App
