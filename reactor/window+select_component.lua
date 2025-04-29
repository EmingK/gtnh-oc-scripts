--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local component = palRequire('component')

local Window = require('ui.window')
local Select = require('ui.window_select')

function Window:selectComponent(name, callback)
  local devices = component.list(name)
  local choices = {}
  for k, _ in pairs(devices) do
    table.insert(choices, k)
  end

  if #choices == 0 then
    -- TODO: alert
    return
  end

  local selectAddress = Select:new(_T('component_address'), choices)

  self:present(
    selectAddress, 
    function(result)
      callback(choices[result])
    end
  )
end