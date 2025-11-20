nbre = nbre or {}

local Entity = require("nbre/core/entity")

local Actor = Entity:extend("Actor")

function Actor:__new()
  self.super.__new(self)
end

function Actor:give(component)
  self.super.give(self, component)
  if self.level and self.level.__addComponent then
    self.level:__addComponent(self, component)
  end
  return self
end

function Actor:remove(component)
  self.super.remove(self, component)
  if self.level and self.level.__removeComponent then
    self.level:__removeComponent(self, component)
  end
  return self
end

function Actor:initialize()
  return {}
end

nbre.Actor = Actor
return Actor
