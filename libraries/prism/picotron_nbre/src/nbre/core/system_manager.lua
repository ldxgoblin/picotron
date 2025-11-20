nbre = nbre or {}

local Object = require("nbre/core/object")
local System = require("nbre/core/system")

local SystemManager = Object:extend("SystemManager")

function SystemManager:__new(owner)
  self.systems = {}
  self.owner = owner
end

function SystemManager:addSystem(system)
  assert(not self:getSystem(system), "Level already has system " .. system.className .. "!")

  for _, requirement in ipairs(system.requirements) do
    local err = "System %s requires system %s but it is not present"
    assert(self:getSystem(requirement), err:format(system.className, requirement.className))
  end

  for _, existingSystem in pairs(self.systems) do
    for _, softRequirement in ipairs(existingSystem.softRequirements) do
      if softRequirement:is(system) then
        local err = "System %s is out of order. It must be added before %s"
        error(err:format(system.className, existingSystem.className))
      end
    end
  end

  system.owner = self.owner
  table.insert(self.systems, system)
end

function SystemManager:getSystem(prototype)
  for _, system in ipairs(self.systems) do
    if prototype:is(system) then return system end
  end
end

function SystemManager:initialize(level)
  for _, system in ipairs(self.systems) do
    system:initialize(level)
  end
end

function SystemManager:postInitialize(level)
  for _, system in ipairs(self.systems) do
    system:postInitialize(level)
  end
end

function SystemManager:onTick(level)
  for _, system in ipairs(self.systems) do
    system:onTick(level)
  end
end

function SystemManager:onTurn(level, actor)
  for _, system in ipairs(self.systems) do
    system:onTurn(level, actor)
  end
end

function SystemManager:onTurnEnd(level, actor)
  for _, system in ipairs(self.systems) do
    system:onTurnEnd(level, actor)
  end
end

function SystemManager:onActorAdded(level, actor)
  for _, system in ipairs(self.systems) do
    system:onActorAdded(level, actor)
  end
end

function SystemManager:onActorRemoved(level, actor)
  for _, system in ipairs(self.systems) do
    system:onActorRemoved(level, actor)
  end
end

function SystemManager:beforeMove(level, actor, from, to)
  for _, system in ipairs(self.systems) do
    system:beforeMove(level, actor, from, to)
  end
end

function SystemManager:onMove(level, actor, from, to)
  for _, system in ipairs(self.systems) do
    system:onMove(level, actor, from, to)
  end
end

function SystemManager:beforeAction(level, actor, action)
  for _, system in ipairs(self.systems) do
    system:beforeAction(level, actor, action)
  end
end

function SystemManager:afterAction(level, actor, action)
  for _, system in ipairs(self.systems) do
    system:afterAction(level, actor, action)
  end
end

function SystemManager:afterOpacityChanged(level, x, y)
  for _, system in ipairs(self.systems) do
    system:afterOpacityChanged(level, x, y)
  end
end

function SystemManager:onYield(level, event)
  for _, system in ipairs(self.systems) do
    system:onYield(level, event)
  end
end

function SystemManager:trigger(eventString, ...)
  for _, system in ipairs(self.systems) do
    if system[eventString] then system[eventString](system, ...) end
  end
end

nbre.SystemManager = SystemManager
return SystemManager
