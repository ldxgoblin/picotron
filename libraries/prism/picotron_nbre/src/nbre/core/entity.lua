nbre = nbre or {}

local Object = require("nbre/core/object")
local Component = require("nbre/core/component")

local Entity = Object:extend("Entity")

function Entity:__new()
  self.relations = {}
  self.components = {}
  self.componentCache = {}
end

function Entity:give(component)
  assert(Component:is(component), "Component must be Component!")
  assert(component:isInstance(), "Expected an instance of a Component!")

  local requirementsMet, missingComponent = component:checkRequirements(self)
  if not requirementsMet then
    local err = "%s was missing requirement %s for %s"
    error(err:format(self.className, missingComponent.className, component.className))
  end

  local base = component:getBase()
  if self:has(base) then
    self:remove(base)
  end

  local proto = getmetatable(component)
  while proto and proto ~= Component do
    self.componentCache[proto] = component
    proto = getmetatable(proto)
  end

  component.owner = self
  table.insert(self.components, component)
  return self
end

function Entity:remove(component)
  if component:isInstance() then component = getmetatable(component) end

  if not self:has(component) then
    if nbre.logger and nbre.logger.warn then
      nbre.logger.warn("Tried to remove %s from %s but they didn't have it.", component.className, self:getName())
    end
    return self
  end

  local instance = self:get(component)
  instance.owner = nil
  for i = 1, #self.components do
    if instance == self.components[i] then table.remove(self.components, i) end
  end

  for prototype, cachedInstance in pairs(self.componentCache) do
    if instance == cachedInstance then self.componentCache[prototype] = nil end
  end

  return self
end

function Entity:ensure(component)
  assert(component:isInstance(), "Expected an instance of a Component!")
  if not self:has(getmetatable(component)) then self:give(component) end
  return self
end

function Entity:has(...)
  for _, prototype in ipairs({ ... }) do
    Object.assertType(prototype, Component)
    if not self.componentCache[prototype] then return false end
  end
  return true
end

function Entity:get(prototype, ...)
  if prototype == nil then return nil end
  return self.componentCache[prototype], self:get(...)
end

function Entity:getName()
  if nbre.components and nbre.components.Name then
    local name = self:get(nbre.components.Name)
    return name and name.name or self.className
  end
  return self.className
end

function Entity:expect(prototype)
  Object.assertType(prototype, Component)
  return self.componentCache[prototype]
    or error("Expected component " .. prototype.className .. " but it was not present!")
end

-- Relation methods are ported directly for future Relation support.
function Entity:addRelation(relation, target, final)
  assert(Entity:is(target), "Target must be an Entity!")

  local relType = relation:getBase()
  self.relations = self.relations or {}

  if not self.relations[relType] then self.relations[relType] = {} end

  if relation.exclusive then
    for other in pairs(self.relations[relType]) do
      self:removeRelation(relType, other)
    end
  end

  self.relations[relType][target] = relation

  local symmetricRelation = relation:generateSymmetric()
  if symmetricRelation and not final then
    target:addRelation(symmetricRelation, self, true)
  end

  local inverseRelation = relation:generateInverse()
  if inverseRelation and not final then
    target:addRelation(inverseRelation, self, true)
  end

  return self
end

function Entity:removeRelation(relationType, target)
  self.relations = self.relations or {}
  if not self.relations[relationType] then return self end

  local relation
  if self.relations[relationType][target] then
    relation = self.relations[relationType][target]
    self.relations[relationType][target] = nil
  else
    return self
  end

  local symmetric = relation:generateSymmetric()
  if symmetric then target:removeRelation(symmetric:getBase(), self) end

  local inverse = relation:generateInverse()
  if inverse then target:removeRelation(inverse:getBase(), self) end

  return self
end

function Entity:removeAllRelations(relationType)
  if not self.relations[relationType] then return self end
  for entity in pairs(self.relations[relationType]) do
    self:removeRelation(relationType, entity)
  end
  return self
end

function Entity:hasRelation(relationType, target)
  self.relations = self.relations or {}
  if not self.relations[relationType] then return false end
  return (target and self.relations[relationType][target] ~= nil)
    or next(self.relations[relationType]) ~= nil
end

function Entity:getRelations(relationType)
  return self.relations[relationType] or {}
end

function Entity:getRelation(relationType)
  local entity = next(self.relations[relationType] or {})
  return entity
end

nbre.Entity = Entity
return Entity
