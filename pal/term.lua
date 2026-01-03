--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local system = require('system')
local curses = require('pal.details.curses')

local gpu = require('pal.gpu')

return {
  isAvailable = function() return true end,

  getViewport = function()
    local h, w = curses.scr:getmaxyx()
    return w, h, 0, 0, 0, 0
  end,

  gpu = function() return gpu end,

  getCursor = function()
    l, c = curses.scr:getyx()
    return c + 1, l + 1
  end,

  setCursor = function(col, row)
    curses.scr:move(row - 1, col - 1)
  end,

  getCursorBlink = function() return false end,

  setCursorBlink = function() end,

  clear = function()
    curses.scr:erase()
  end,

  clearLine = function()
    curses.scr:clrtoeol()
  end,

  read = function()
    -- Temporarily switch to blocking mode with echo for input
    curses.scr:nodelay(false)
    curses.echo(true)
    local result = curses.scr:getstr()
    curses.echo(false)
    curses.scr:nodelay(true)  -- Restore non-blocking mode
    return result
  end,

  -- TODO: support no line wrap
  write = function(s)
    curses.scr:addstr(s)
  end,
}
