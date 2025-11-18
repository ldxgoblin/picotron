--- A display name for an entity.
--- @class Name : Component
--- @field name string
--- @overload fun(name: string): Name
local Name = prism.Component:extend "Name"

--- @param name string
function Name:__new(name)
   self.name = name
end

--- Retrieves the string name of an entity, defaulting to their class name ("Actor" or "Cell").
--- @param entity Entity The entity whose name to retrieve.
--- @return string -- The name.
function Name.get(entity)
   local name = entity:get(prism.components.Name)
   return name and name.name or entity.className
end

--- Retrieves the name of an entity in lower case.
--- @param entity Entity The entity whose name to retrieve.
--- @return string -- The name.
function Name.lower(entity)
   return string.lower(Name.get(entity))
end

--- Retrieves the name of an entity in upper case.
--- @param entity Entity The entity whose name to retrieve.
--- @return string -- The name.
function Name.upper(entity)
   return string.upper(Name.get(entity))
end

return Name
