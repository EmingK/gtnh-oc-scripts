--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

local class = require('core.class')
local Navigation = require('ui.navigation')
local uiUtils = require('ui.utils')
local wrap = require('ui.wrap_class')
local Element = require('ui.element').class

local unicode = palRequire('unicode')

local symbols = {
  tl = unicode.char(0x250c),
  tm = unicode.char(0x252c),
  tr = unicode.char(0x2510),
  ml = unicode.char(0x251c),
  mm = unicode.char(0x253c),
  mr = unicode.char(0x2524),
  bl = unicode.char(0x2514),
  bm = unicode.char(0x2534),
  br = unicode.char(0x2518),
  hl = unicode.char(0x2500),
  vl = unicode.char(0x2502),

  arrowLeft = unicode.char(0x25c0),
  arrowRight = unicode.char(0x25b6),
  arrowUp = unicode.char(0x25b2),
  arrowDown = unicode.char(0x25bc),
  barHorz = unicode.char(0x2588),
  barVert = unicode.char(0x2588),
}

--[[
  A table is a scrollable container with fixed cell size.

  Input data structure is defined as following:
  type Contents = {
    -- Row
    {
      -- Column
      {
        -- The action corresponding to this cell
        action: String?,
        -- The display content of this cell
        display: String,
        -- Cell level selection control
        selectable: Boolean = true,
      }
      ...
    },
    ...
  }

  type config = {
    showBorders: Boolean,
    rows = {
      n = Integer,
      defaultHeight: Integer? = 1,
      [index] = {
        height: Integer?,
        selectable: Boolean,
      }
    },
    columns = {
      n = Integer,
      defaultWidth: Integer? = 10
      [index] = {
        width: Integer?,
        selectable: Boolean,
      }
    }
  }
]]
local Table = class(Element)

function Table:init(super, contents, config)
  super.init()
  self.contents = contents
  self.config = config
  self.selectable = true

  self.offset = {
    x = 0,
    y = 0,
  }

  self:calculatePositions()
end

--[[
  Notify that the table has changed its data and layout.
]]
function Table:reload()
  self:calculatePositions()
  self:setNeedUpdate()
end

function Table:initSelection(navFrom)
  -- TODO: handle navFrom
  -- TODO: handle config selectable
  self.selectedRow = 1
  self.selectedColumn = 1
  return self
end

function Table:handleNavigation(nav)
  -- TODO: cell level refresh
  local nextRow, nextCol = self:findNextSelectablePos(nav)
  if nextRow and nextCol then
    self:selectCell(nextRow, nextCol)
    return self
  end
  
  local next = Element.handleNavigation(self, nav)
  if next then
    self.selectedRow = nil
    self.selectedColumn = nil
    self:setNeedUpdate()
  end
  return next
end

function Table:cellSelectableAt(row, col)
  -- cell's config is at top priority
  local row = self.contents[row]
  local cell = row and row[col]
  local cellSelectable = cell and cell.selectable

  if cellSelectable ~= nil then
    return cellSelectable
  end
  -- follow the row and column's config
  local rowCfg = self.config.rows[row]
  local rowSelectable = rowCfg and rowCfg.selectable
  if rowSelectable ~= nil then
    return rowSelectable
  end
  local colCfg = self.config.columns[col]
  local colSelectable = colCfg and colCfg.selectable
  if colSelectable ~= nil then
    return colSelectable
  end

  return self.selectable
end

--[[
  Find a coordinate of cell when navigated with `nav`.
  @returns row, column or nil
]]
function Table:findNextSelectablePos(nav)
  local fCfgMain, fCfgCross, fSelMain, fSelCross, delta
  if nav == Navigation.up then
    fCfgMain = 'rows'
    fCfgCross = 'columns'
    fSelMain = 'selectedRow'
    fSelCross = 'selectedColumn'
    delta = -1
  elseif nav == Navigation.down then
    fCfgMain = 'rows'
    fCfgCross = 'columns'
    fSelMain = 'selectedRow'
    fSelCross = 'selectedColumn'
    delta = 1
  elseif nav == Navigation.left then
    fCfgMain = 'columns'
    fCfgCross = 'rows'
    fSelMain = 'selectedColumn'
    fSelCross = 'selectedRow'
    delta = -1
  elseif nav == Navigation.right then
    fCfgMain = 'columns'
    fCfgCross = 'rows'
    fSelMain = 'selectedColumn'
    fSelCross = 'selectedRow'
    delta = 1
  else 
    error("bug: unexpected nav direction")
  end

  local nextPos = {
    selectedRow = self.selectedRow,
    selectedColumn = self.selectedColumn
  }

  local nextMain = self[fSelMain] + delta
  while nextMain >= 1 and nextMain <= self.config[fCfgMain].n do
    nextPos[fSelMain] = nextMain
    if self:cellSelectableAt(nextPos.selectedRow, nextPos.selectedColumn) then
      return nextPos.selectedRow, nextPos.selectedColumn
    end

    -- skip if the row/column disable selection
    local mAxisCfg = self.config[fCfgMain][nextMain]
    if (mAxisCfg and mAxisCfg.selectable) ~= false then
      -- search a cell inside cross direction
      for deltaCross = 1, -1, -2 do
        nextPos[fSelCross] = self[fSelCross]
        local nextCross = self[fSelCross] + deltaCross
        while nextCross >= 1 and nextCross <= self.config[fCfgCross].n do
          nextPos[fSelCross] = nextCross
          if self:cellSelectableAt(nextPos.selectedRow, nextPos.selectedColumn) then
            return nextPos.selectedRow, nextPos.selectedColumn
          end
        end
      end
    end
    nextMain = nextMain + delta
  end
  return nil
end

function Table:selectCell(row, col)
  self.selectedRow = row
  self.selectedColumn = col

  local yStart = self.rowPositions[self.selectedRow]
  local xStart = self.colPositions[self.selectedColumn]
  local yEnd = self.rowPositions[self.selectedRow + 1] - 1
  local xEnd = self.colPositions[self.selectedColumn + 1] - 1

  -- adjust offset based on cell position
  if self.offset.x > xStart then 
    self.offset.x = xStart
  elseif self.offset.x + self.viewportW <= xEnd then
    local nextOffsetX = xEnd - self.viewportW + 1
    self.offset.x = math.min(xStart, nextOffsetX)
  end
  if self.offset.y > yStart then
    self.offset.y = yStart
  elseif self.offset.y + self.viewportH <= yEnd then
    local nextOffsetY = yEnd - self.viewportH + 1
    self.offset.y = math.min(yStart, nextOffsetY)
  end
  self:setNeedUpdate()
end

function Table:selectedContent()
  if self.selectedRow and self.selectedColumn then
    local row = self.contents[self.selectedRow]
    return row and row[self.selectedColumn]
  end
  return nil
end

function Table:getAction()
  local selected = self:selectedContent()
  if selected then
    return selected.action, selected.value
  end
  return nil
end

function Table:draw(gpu)
  self:clear(gpu)
  -- The whole painting area, include scroll bars.
  local w = self.rect.w
  local h = self.rect.h
  -- The content viewport area, is painting area removing scroll bars.
  local viewportW = w
  local viewportH = h

  local totalRows = self.config.rows.n
  local totalCols = self.config.columns.n

  -- The inner scrollable content size
  local contentW = self.colPositions[#self.colPositions]
  local contentH = self.rowPositions[#self.rowPositions]

  local showBorders = self.config.showBorders

  local shouldShowHorizontalScroll = false
  local shouldShowVerticalScroll = false
  if contentW > w then
    shouldShowHorizontalScroll = true
    viewportH = viewportH - 1
    if contentH >= h then
      shouldShowVerticalScroll = true
      viewportW = viewportW - 1
    end
  elseif contentH > h then
    shouldShowVerticalScroll = true
    viewportW = viewportW - 1
    if contentW >= w then
      shouldShowHorizontalScroll = true
      viewportH = viewportH - 1
    end
  end
  self.viewportW = viewportW
  self.viewportH = viewportH

  -- paint contents
  -- decide which cell to start draw
  local rowPaintStartIndex = 1
  local columnPaintStartIndex = 1

  while self.colPositions[columnPaintStartIndex + 1] <= self.offset.x do
    columnPaintStartIndex = columnPaintStartIndex + 1
  end

  while self.rowPositions[rowPaintStartIndex + 1] <= self.offset.y do
    rowPaintStartIndex = rowPaintStartIndex + 1
  end

  local rowPaintIndex = rowPaintStartIndex

  -- paint every row
  local currentPaintOffsetY = self.offset.y
  while currentPaintOffsetY < self.offset.y + viewportH and rowPaintIndex <= totalRows do
    local columnPaintIndex = columnPaintStartIndex
    local availableHeight = math.min(self.rowPositions[rowPaintIndex + 1], self.offset.y + viewportH) - currentPaintOffsetY

    -- paint every column
    local currentPaintOffsetX = self.offset.x
    while currentPaintOffsetX < self.offset.x + viewportW and columnPaintIndex <= totalCols do
      local availableWidth = math.min(self.colPositions[columnPaintIndex + 1], self.offset.x + viewportW) - currentPaintOffsetX
      local cellAvailableHeight = availableHeight
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)

      -- borders
      if showBorders then
        -- topleft
        local borderTopleft = symbols.mm
        if columnPaintIndex == 1 then
          if rowPaintIndex == 1 then
            borderTopleft = symbols.tl
          else
            borderTopleft = symbols.ml
          end
        elseif rowPaintIndex == 1 then
          borderTopleft = symbols.tm
        end
        gpu.set(sx, sy, borderTopleft)
        sx = sx + 1
        -- top
        gpu.set(sx, sy, symbols.hl:rep(availableWidth - 1))
        sy = sy + 1

        cellAvailableHeight = cellAvailableHeight - 1
        -- left
        if cellAvailableHeight > 0 then
          gpu.set(sx - 1, sy, symbols.vl:rep(cellAvailableHeight), true)
        end
      end

      if cellAvailableHeight > 0 then
        local row = self.contents[rowPaintIndex]
        local cell = row and row[columnPaintIndex]
        local displayText = cell and cell.display or ' '
        if unicode.wlen(displayText) > availableWidth then
          displayText = unicode.wtrunc(displayText, availableWidth)
        end
        local shouldHighlight = self.selectedRow == rowPaintIndex and self.selectedColumn == columnPaintIndex
        if shouldHighlight then
          uiUtils.setHighlight(gpu)
        end
        gpu.set(sx, sy, displayText)
        if shouldHighlight then
          uiUtils.setNormal(gpu)
        end
      end

      columnPaintIndex = columnPaintIndex + 1
      currentPaintOffsetX = self.colPositions[columnPaintIndex]
    end
    -- try draw the rightmost border
    if showBorders and currentPaintOffsetX < self.offset.x + viewportW then
      -- topright
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      if rowPaintIndex == 1 then
        gpu.set(sx, sy, symbols.tr)
      else
        gpu.set(sx, sy, symbols.mr)
      end

      if availableHeight > 1 then
        gpu.set(sx, sy + 1, symbols.vl:rep(availableHeight - 1), true)
      end
    end

    rowPaintIndex = rowPaintIndex + 1
    currentPaintOffsetY = self.rowPositions[rowPaintIndex]
  end
  -- try draw the bottommost border
  if showBorders and currentPaintOffsetY < self.offset.y + viewportH then
    local columnPaintIndex = columnPaintStartIndex
    local currentPaintOffsetX = self.offset.x
    while currentPaintOffsetX < self.offset.x + viewportW and columnPaintIndex <= totalCols do
      local availableWidth = math.min(viewportW, self.colPositions[columnPaintIndex + 1]) - currentPaintOffsetX
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      -- bottom left
      if columnPaintIndex == 1 then
        gpu.set(sx, sy, symbols.bl)
      else
        gpu.set(sx, sy, symbols.bm)
      end
      -- bottom
      gpu.set(sx + 1, sy, symbols.hl:rep(availableWidth - 1))

      columnPaintIndex = columnPaintIndex + 1
      currentPaintOffsetX = self.colPositions[columnPaintIndex]
    end
    -- bottom right
    if currentPaintOffsetX < self.offset.x + viewportW then
      local sx, sy = self:screenPos(currentPaintOffsetX - self.offset.x, currentPaintOffsetY - self.offset.y)
      gpu.set(sx, sy, symbols.br)
    end
  end

  -- paint scroll bars
  if shouldShowHorizontalScroll then
    local sx, sy = self:screenPos(0, self.rect.h - 1)
    gpu.set(sx, sy, symbols.arrowLeft)

    local scrollLength = self.rect.w - 2
    if shouldShowVerticalScroll then
      scrollLength = self.rect.w - 3
    end
    local barLength = math.max(math.floor(viewportW / contentW * scrollLength), 1)
    local barOffset = math.floor(self.offset.x / contentW * scrollLength)
    gpu.set(sx + 1, sy, symbols.hl:rep(scrollLength))
    gpu.set(sx + 1 + barOffset, sy, symbols.barHorz:rep(barLength))
    gpu.set(sx + scrollLength + 1, sy, symbols.arrowRight)
  end
  if shouldShowVerticalScroll then
    local sx, sy = self:screenPos(self.rect.w - 1, 0)
    gpu.set(sx, sy, symbols.arrowUp)

    local scrollLength = self.rect.h - 2
    if shouldShowHorizontalScroll then
      scrollLength = self.rect.h - 3
    end
    local barLength = math.max(math.floor(viewportH / contentH * scrollLength), 1)
    local barOffset = math.floor(self.offset.y / contentH * scrollLength)
    gpu.set(sx, sy + 1, symbols.vl:rep(scrollLength), true)
    gpu.set(sx, sy + 1 + barOffset, symbols.barVert:rep(barLength), true)
    gpu.set(sx, sy + scrollLength + 1, symbols.arrowDown)
  end
end

function Table:calculatePositions()
  local totalRows = self.config.rows.n
  local totalCols = self.config.columns.n

  local showBorders = self.config.showBorders

  local pos = 0
  local colPositions = {}
  for i = 1, totalCols do
    table.insert(colPositions, pos)
    local colConfig = self.config.columns[i]
    pos = pos + (colConfig and colConfig.width or self.config.columns.defaultWidth or 10)
    if showBorders then
      pos = pos + 1
    end
  end
  table.insert(colPositions, pos)

  pos = 0
  local rowPositions = {}
  for i = 1, totalRows do
    table.insert(rowPositions, pos)
    local rowConfig = self.config.rows[i]
    pos = pos + (rowConfig and rowConfig.height or self.config.rows.defaultHeight or 1)
    if showBorders then
      pos = pos + 1
    end
  end
  table.insert(rowPositions, pos)

  self.colPositions = colPositions
  self.rowPositions = rowPositions
end

return wrap(Table)
