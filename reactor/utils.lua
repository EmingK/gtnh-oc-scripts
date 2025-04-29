--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local utils = require('core.utils')
local builtins = require('reactor.builtins')

local function redstoneDescription(cfg)
  if not cfg then 
    return _T('redstone_mode_none')
  end

  local desc = _T('redstone_mode_'..cfg.mode)
  if cfg.mode == 'vanilla' or cfg.mode == 'bundled' then
    desc = desc .. ',' .. _T(utils.sideDescription(cfg.side))
  end
  return desc
end

local function transposerDescription(cfg)
  if not cfg then
    return _T('not_configured')
  end

  return cfg.address
end

local function profileDescription(cfg)
  if not cfg then
    return _T('not_configured')
  end
  
  local schemaName = cfg.schema
  for _, schema in pairs(builtins.schemas) do
    if schema.name == schemaName then
      schemaName = schema.displayName
      break
    end
  end
  return schemaName
end

local function changeConditionDescription(cfg)
  if cfg then
    if cfg.change == 'none' then
      return _T('change_condition_none')
    elseif cfg.change == 'damage_less' then
      return _T('change_condition_damage_less')
    end
  end
  return _T('not_configured')
end

return {
  redstoneDescription = redstoneDescription,
  transposerDescription = transposerDescription,
  profileDescription = profileDescription,
  changeConditionDescription = changeConditionDescription,
}