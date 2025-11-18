--- @class FOV.Row : Object
--- @field depth integer
--- @field startSlope FOV.Fraction
--- @field endSlope FOV.Fraction
--- @overload fun(depth: integer, startSlope: FOV.Fraction, endSlope: FOV.Fraction): FOV.Row
local Row = prism.Object:extend("Row")

function Row:__new(depth, startSlope, endSlope)
   self.depth = depth
   self.startSlope = startSlope
   self.endSlope = endSlope
end

function Row:eachTile()
   local mincol = Row.roundTiesUp(self.startSlope * self.depth)
   local maxcol = Row.roundTiesDown(self.endSlope * self.depth)
   local col = mincol

   return function()
      if col <= maxcol then
         col = col + 1
         return self.depth, col - 1
      else
         return nil
      end
   end
end

function Row.roundTiesUp(n)
   return math.floor(n:tonumber() + 0.5)
end

function Row.roundTiesDown(n)
   return math.ceil(n:tonumber() - 0.5)
end

--- @return FOV.Row
function Row:next()
   return Row(self.depth + 1, self.startSlope, self.endSlope)
end

return Row
