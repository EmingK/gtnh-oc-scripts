--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local system = require('system')

return {

  -- unicode.char(value: number, ...): string
  -- UTF-8 aware version of string.char. The values may be in the full UTF-8 range, not just ASCII.
  char = utf8.char,

  -- unicode.charWidth(value: string, ...): number
  -- Returns the width of the first character given. For example, for シ it'll return 2, where a would return 1.
  charWidth = system.utf8cwidth,

  -- unicode.isWide(value: string, ...): boolean
  -- Returns if the width of the first character given is greater than 1. For example, for シ it'll return true, where a would return false.
  isWide = function(s) return system.utf8cwidth(s) > 1 end,

  -- unicode.len(value: string): number
  -- UTF-8 aware version of string.len. For example, for Ümläüt it'll return 6, where string.len would return 9.
  len = utf8.len,

  -- unicode.lower(value: string): string
  -- UTF-8 aware version of string.lower.

  -- unicode.reverse(value: string): string
  -- UTF-8 aware version of string.reverse. For example, for Ümläüt it'll return tüälmÜ, where string.reverse would return tälm.

  -- unicode.sub(value: string, i:number[, j:number]): string
  -- UTF-8 aware version of string.sub.

  -- unicode.upper(value: string): string
  -- UTF-8 aware version of string.upper.

  -- unicode.wlen(value: string): number
  -- Returns the width of the entire string.
  wlen = system.utf8swidth,

  -- unicode.wtrunc(value: string, count: number): string
  -- Truncates the given string up to but not including count width. If there are not enough characters to match the wanted width, the function errors.
  wtrunc = function(value, count)
    local res = ""
    local available = count
    for _, cp in utf8.codes(value) do
      local c = utf8.char(cp)
      local len = system.utf8cwidth(c)
      if len > available then
        break
      end
      res = res .. c
      available = available - len
    end
    return res
  end,
}
