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
end

function AdapterReactorControl:enable()
  self.rc.setActive(true)
end

function AdapterReactorControl:disable()
  self.rc.setActive(false)
end

local VanillaReactorControl = class()

function VanillaReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
end

function VanillaReactorControl:enable()
  self.rs.setOutput(self.side, 15)
end

function VanillaReactorControl:disable()
  self.rs.setOutput(self.side, 0)
end

local BundledReactorControl = class()

function BundledReactorControl:init(_, cfg)
  self.rs = component.proxy(cfg.address)
  self.side = cfg.side
  self.color = cfg.color
end

function BundledReactorControl:enable()
  self.rs.setBundledOutput(self.side, self.color, 15)
end

function BundledReactorControl:disable()
  self.rs.setBundledOutput(self.side, self.color, 0)
end

return {
  Adapter = AdapterReactorControl,
  Vanilla = VanillaReactorControl,
  Bundled = BundledReactorControl,
}
