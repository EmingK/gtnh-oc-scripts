--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local inner = require('pal.details.curses')
local curses = require('curses')

local gpu = {}

function gpu.getResolution()
  local h, w = inner.scr:getmaxyx()
  return w, h
end

function gpu.fill(x, y, w, h, c)
  local cc = c or ' '
  for dy = 0, h - 1 do
    inner.scr:mvaddstr(y + dy - 1, x - 1, c:rep(w))
  end
end

-- Not used in PC env.
function gpu.getBackground()
  error('unexpected call to gpu method. We do not emulate gpu.getBackground().')
end

function gpu.setBackground(c)
  error('unexpected call to gpu method. We do not emulate gpu.setBackground().')
end

function gpu.getForeground()
  error('unexpected call to gpu method. We do not emulate gpu.getForeground().')
end

function gpu.setForeground(c)
  error('unexpected call to gpu method. We do not emulate gpu.setForeground().')
end

function gpu.set(x, y, s, vertical)
  if not vertical then
    inner.scr:mvaddstr(y - 1, x - 1, s)
    return
  end

  -- vertical
  local sy = y - 1
  for _, cp in utf8.codes(s) do
    inner.scr:mvaddstr(sy, x - 1, utf8.char(cp))
    sy = sy + 1
  end
end

function gpu.allocateBuffer(w, h)
  return curses.newpad(h, w)
end

function gpu.freeBuffer(buf)
  buf:close()
end

function gpu.bitblt(dst, col, row, width, height, src, fromCol, fromRow)
  if dst == 0 then
    dst = inner.scr
  end
  if src == 0 then
    src = inner.scr
  end
  fromCol = fromCol or 1
  fromRow = fromRow or 1

  src:copywin(dst, fromRow - 1, fromCol - 1, row - 1, col - 1, row + height - 1, col + width - 1, true)
end

local emptyGpu = setmetatable({}, {
    __call = function(self, name, ...)
      print(string.format('gpu.%s', name), ...)
    end
})

gpu.empty = emptyGpu

return gpu
