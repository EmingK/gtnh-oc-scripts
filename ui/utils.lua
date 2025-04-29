--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local utils = {}

function utils.setHighlight(gpu)
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x0)
end

function utils.setNormal(gpu)
  gpu.setBackground(0x0)
  gpu.setForeground(0xffffff)
end

return utils
