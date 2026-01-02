local curses = require('curses')

local uiUtils = require('ui.utils')

local cursesImpl = {}
local stdscr

local function uiUtilsHighlight()
  local attr = curses.color_pair(1)
  stdscr:attrset(attr)
end

local function uiUtilsNormal()
  local attr = curses.color_pair(0)
  stdscr:attrset(attr)
end

function cursesImpl.setup()
  os.setlocale("")
  stdscr = curses.initscr()
  curses.start_color()
  curses.echo(false)
  curses.cbreak(true)
  stdscr:keypad(true)
  stdscr:nodelay(true)
  cursesImpl.scr = stdscr

  -- color palette
  curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)

  uiUtils.setHighlight = uiUtilsHighlight
  uiUtils.setNormal = uiUtilsNormal
end

function cursesImpl.destroy()
  stdscr:getch()
  stdscr:keypad(false)
  curses.cbreak(false)
  curses.echo(true)
  curses.endwin()
end

function cursesImpl.echo(enabled)
  curses.echo(enabled)
end

return cursesImpl
