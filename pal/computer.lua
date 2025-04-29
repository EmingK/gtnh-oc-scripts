--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local system = require('system')

local Computer = {}

function Computer.uptime()
  return system.monotime()
end

return Computer
