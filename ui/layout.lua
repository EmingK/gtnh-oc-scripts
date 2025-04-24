--[[
  Copyright (c) 2024 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local function directionContainerLayout(c, main, cross, mainOffset, crossOffset)
  local w = c.rect[main]

  local fixed = 0
  local nFlex = 0
  for i, child in ipairs(c.children) do
    if child.intrinsicSize[main] then
      fixed = fixed + child.intrinsicSize[main]
    else
      nFlex = nFlex + 1
    end
  end
  local unit = 0
  if nFlex > 0 then unit = (w - fixed) // nFlex end

  local x = 0
  for i, child in ipairs(c.children) do
    local childMain, childCross
    if child.intrinsicSize[main] then
      childMain = child.intrinsicSize[main]
    else
      childMain = unit
    end
    childCross = child.intrinsicSize[cross] or c.rect[cross]

    child.rect[mainOffset] = c.rect[mainOffset] + x
    child.rect[crossOffset] = c.rect[crossOffset]
    child.rect[main] = childMain
    child.rect[cross] = childCross

    if child.layout then
      child:layout()
    end

    x = x + childMain
  end
end

return directionContainerLayout
