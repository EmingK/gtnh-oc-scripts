--[[
Copyright (c) 2013-2015 Florian "Sangar" Nücke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local shell = {}

-- Copied from OC repo
function shell.parse(...)
  local params = table.pack(...)
  local args = {}
  local options = {}
  local doneWithOptions = false
  for i = 1, params.n do
    local param = params[i]
    if not doneWithOptions and type(param) == "string" then
      if param == "--" then
        doneWithOptions = true -- stop processing options at `--`
      elseif param:sub(1, 2) == "--" then
        local key, value = param:match("%-%-(.-)=(.*)")
        if not key then
          key, value = param:sub(3), true
        end
        options[key] = value
      elseif param:sub(1, 1) == "-" and param ~= "-" then
        for j = 2, utf8.len(param) do
          options[utf8.sub(param, j, j)] = true
        end
      else
        table.insert(args, param)
      end
    else
      table.insert(args, param)
    end
  end
  return args, options
end

return shell
