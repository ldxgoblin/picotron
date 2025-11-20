local Object = require("nbre/core/object")

local Component = Object:extend("Component")
Component.requirements = {}

function Component:getRequirements() end

function Component:checkRequirements(entity)
  for _, component in ipairs(self.requirements) do
    if not entity:has(component) then return false, component end
  end
  return true
end

function Component:getBase()
  local proto = self:isInstance() and getmetatable(self) or self
  while proto and proto ~= Component do
    proto = getmetatable(proto)
  end
  return proto
end

function Component:clone()
  local copy = {}
  for k, v in pairs(self) do
    if not self._serializationBlacklist or not self._serializationBlacklist[k] then
      copy[k] = v
    end
  end
  return getmetatable(self):adopt(copy)
end

nbre.Component = Component
return Component
