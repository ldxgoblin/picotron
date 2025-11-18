--- A sparse grid class that stores data using hashed coordinates. Similar to a SparseMap
--- except here there is only one entry per grid coordinate. This is suitable for stuff like Cells.
--- @class SparseGrid<V> : Object, { data : table<V> }
--- @overload fun(): SparseGrid
local SparseGrid = prism.Object:extend("SparseGrid")

--- The constructor for the 'SparseGrid' class.
--- Initializes the sparse grid with an empty data table.
function SparseGrid:__new()
   self.data = {}
   return self
end

--- Sets the value at the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param value any The value to set.
function SparseGrid:set(x, y, value)
   local key = prism.Vector2._hash(x, y)
   self.data[key] = value
end

--- Gets the value at the specified coordinates.
--- @generic V
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return any value The value at the specified coordinates, or nil if not set.
function SparseGrid:get(x, y)
   local key = prism.Vector2._hash(x, y)
   return self.data[key]
end

--- Clears all values in the sparse grid.
function SparseGrid:clear()
   for k in pairs(self.data) do
      self.data[k] = nil
   end
end

--- Iterator function for the SparseGrid.
--- Iterates over all entries in the sparse grid, returning the coordinates and value for each entry.
--- @generic V
--- @return fun(): integer, integer, V iter An iterator function that returns the x-coordinate, y-coordinate, and value for each entry.
function SparseGrid:each()
   local nextIndex, nextValue = next(self.data)
   return function()
      local currentIndex, currentValue = nextIndex, nextValue
      if currentIndex then
         nextIndex, nextValue = next(self.data, currentIndex)
         local x, y = prism.Vector2._unhash(currentIndex)

         -- This gives a false positive due to the closure.
         --- @diagnostic disable-next-line
         return x, y, currentValue
      end
   end
end

return SparseGrid
