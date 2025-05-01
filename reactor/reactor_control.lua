--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')

local component = palRequire('component')

local AdapterReactorControl = class()

function AdapterReactorControl:init(_, rcproxy)
  self.rc = rcproxy
  self.rc.setActive(false)
  self.enabled = false
end

function AdapterReactorControl:enable()
  if not self.enabled then
    self.rc.setActive(true)
    self.enabled = true
  end
end

function AdapterReactorControl:disable()
  if self.enabled then
    self.rc.setActive(false)
    self.enabled = false
  end
end

local VanillaReactorControl = class()

function VanillaReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
  self.rs.setOutput(self.side, 0)
  self.enabled = false
end

function VanillaReactorControl:getInput()
  return self.rs.getInput(self.side) ~= 0
end

function VanillaReactorControl:enable()
  if not self.enabled then
    self.rs.setOutput(self.side, 15)
    self.enabled = true
  end
end

function VanillaReactorControl:disable()
  if self.enabled then
    self.rs.setOutput(self.side, 0)
    self.enabled = false
  end
end

local BundledReactorControl = class()

function BundledReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
  self.color = cfg.color
  self.rs.setBundledOutput(self.side, self.color, 0)
  self.enabled = false
end

function BundledReactorControl:getInput()
  return self.rs.getBundledInput(self.side, self.color) ~= 0
end

function BundledReactorControl:enable()
  if not self.enabled then
    self.rs.setBundledOutput(self.side, self.color, 15)
    self.enabled = true
  end
end

function BundledReactorControl:disable()
  if self.enabled then
    self.rs.setBundledOutput(self.side, self.color, 0)
    self.enabled = false
  end
end

return {
  Adapter = AdapterReactorControl,
  Vanilla = VanillaReactorControl,
  Bundled = BundledReactorControl,
}
