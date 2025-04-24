--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local utils = require('core.utils')

local confFilename = 'reactor_schema.conf'
local SchemaManager = {}

local schemas = {}

function SchemaManager.setup()
  local loaded = utils.loadSerializedObject(confFilename)
  if type(loaded) == 'table' then
    schemas = loaded
  elseif loaded == nil then
    schemas = {}
  else
    error(_T('schema_corrupt'))
  end
end

return SchemaManager
