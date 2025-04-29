--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  PAL - Platform Abstraction Layer

  This layer simulates OpenComputers APIs on PC. This makes developing
  OC programs easy without restarting computer in game over and over
  again.
]]

local isOpenOS = false
if _G._OSVERSION then
  if type(_OSVERSION) == 'string' then
    if string.sub(_OSVERSION, 1, 6) == 'OpenOS' then
      isOpenOS = true
    end
  end
end

--[[
  Global function palRequire

  Use simulated implementation if the platform is not OpenOS.
  All OpenOS modules should be imported using this.
]]

palRequire = require

if not isOpenOS then
  palRequire = function(moduleName)
    return require('pal.' .. moduleName)
  end
  os.sleep = function() end
end

debugLog = function() end
