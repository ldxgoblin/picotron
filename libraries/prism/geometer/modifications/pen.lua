--- @class PenModification : Modification
--- @field placeable Placeable
--- @field placed Placeable[]|nil
--- @field replaced SparseGrid
--- @field locations SparseGrid
local PenModification = geometer.Modification:extend "PenModification"

---@param placeable Placeable
---@param locations SparseGrid
function PenModification:__new(placeable, locations)
   self.placeable = placeable
   self.locations = locations
end

--- @param attachable SpectrumAttachable
function PenModification:execute(attachable)
   for x, y in self.locations:each() do
      self:place(attachable, x, y, self.placeable)
   end
end

return PenModification
