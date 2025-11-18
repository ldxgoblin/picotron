--- @class RectModification : Modification
--- @field placeable Placeable
--- @field placed Placeable[]|nil
--- @field replaced SparseGrid
--- @field topLeft Vector2
--- @field bottomRight Vector2
local RectModification = geometer.Modification:extend "RectModification"

---@param placeable Placeable
---@param topLeft Vector2
---@param bottomRight Vector2
function RectModification:__new(placeable, topLeft, bottomRight, fillMode)
   self.placeable = placeable
   self.topLeft = topLeft
   self.bottomRight = bottomRight
   self.fillMode = fillMode
end

--- @param attachable SpectrumAttachable
function RectModification:execute(attachable)
   local i, j = self.topLeft.x, self.topLeft.y
   local k, l = self.bottomRight.x, self.bottomRight.y

   if self.fillMode then
      -- Fill the rectangle
      for x = i, k do
         for y = j, l do
            self:place(attachable, x, y, self.placeable)
         end
      end
   else
      -- Draw only the outline of the rectangle
      for x = i, k do
         self:placeBoundaryCell(attachable, x, j) -- Top edge
         self:placeBoundaryCell(attachable, x, l) -- Bottom edge
      end
      for y = j + 1, l - 1 do
         self:placeBoundaryCell(attachable, i, y) -- Left edge
         self:placeBoundaryCell(attachable, k, y) -- Right edge
      end
   end
end

--- Helper function to place a cell on the boundary
---@param attachable SpectrumAttachable
---@param x number
---@param y number
function RectModification:placeBoundaryCell(attachable, x, y)
   self:place(attachable, x, y, self.placeable)
end

return RectModification
