local unicode = palRequire('unicode')

local text = {}

function text.wrap(value, width, maxWidth)
  local line, nl = value:match("([^\r\n]*)(\r?\n?)") -- read until newline
  if unicode.wlen(line) > width then -- do we even need to wrap?
    local partial = unicode.wtrunc(line, width)
    local wrapped = partial:match("(.*[^a-zA-Z0-9._()'`=])")
    if wrapped or unicode.wlen(line) > maxWidth then
      partial = wrapped or partial
      return partial, unicode.sub(value, unicode.len(partial) + 1), true
    else
      return "", value, true -- write in new line.
    end
  end
  local start = unicode.len(line) + unicode.len(nl) + 1
  return line, start <= unicode.len(value) and unicode.sub(value, start) or nil, unicode.len(nl) > 0
end

function text.wrappedLines(value, width, maxWidth)
  local line, nl
  return function()
    if value then
      line, value, nl = text.wrap(value, width, maxWidth)
      return line
    end
  end
end

return text