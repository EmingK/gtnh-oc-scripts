--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local curses = require('pal.details.curses')

local pal = {}

local function palModulesInit()
  curses.setup()
end

local function palModulesOnExit()
  curses.destroy()
end

--[[
  Initialize simulated environment.

  OC use non blocking key handling. User input is handled by `term.read`.
  We disable input echo and line mode for the while program, and then handle
  blocking input from `term` module.
]]
function pal.start(f, ...)
  palModulesInit()
  f(...)
  palModulesOnExit()
end

return pal
