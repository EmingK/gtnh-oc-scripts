--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local path = require('path')
local fs = require('path.fs')

return {
  exists = fs.exists,
  copy = fs.copy,
  canonical = path,
}