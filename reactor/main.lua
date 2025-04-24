--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

require('core.pal')
local shell = palRequire('shell')
local event = palRequire('event')

local i18n = require('core.i18n')
local utils = require('core.utils')
local config = require('reactor.config')
local builtins = require('reactor.builtins')
local App = require('core.app')
local WindowSetup = require('reactor.window_setup')
local WindowRun = require('reactor.window_run')

local function appEntry(window)
  return function(...) App:new(...):start(window:new()) end
end

local function usage()
  print(_T('usage'))
end

local subCommands = {
  setup = appEntry(WindowSetup),
  run = appEntry(WindowRun),
  help = usage,
}

local function main(args, options)
  if options.debug then
    debugLog = utils.debug
  end

  local cfg = config.load(options.config)
  local lang = cfg and cfg.lang

  i18n.setup('res/reactor/i18n', lang)

  local mode = args[1] or 'run'
  if mode and not subCommands[mode] then
    print(string.format(_T('invalid_command'), mode))
    usage()
    return
  end

  local cfgReadyForRun =
    cfg and
    cfg.lang and
    type(cfg.instances) == 'table' and
    #cfg.instances > 0

  if mode ~= 'setup' and not cfgReadyForRun then
    mode = 'setup'
    print(_T('no_valid_config'))
    event.pull('key_up')
  end

  builtins.setup()
  config.prepare()
  subCommands[mode](options)
end

main(shell.parse(...))
