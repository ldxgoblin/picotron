nbre = nbre or {}

local Object = {}
Object.className = "Object"
Object._isInstance = false
Object._serializationBlacklist = {
  className = true,
  _isInstance = true,
}

function Object:extend(className)
  assert(className, "You must supply a class name when extending Objects!")
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.__call = self.__call or Object.__call
  o._isInstance = false
  o.className = className
  o.super = self
  return o
end

function Object:__call(...)
  local o = {}
  Object.adopt(self, o)
  o:__new(...)
  return o
end

function Object:adopt(o)
  o._isInstance = true
  setmetatable(o, self)
  self.__index = self
  self.__call = self.__call or Object.__call
  return o
end

function Object:isInstance()
  return self._isInstance
end

function Object:__new(...) end

function Object:is(o)
  if not o then return false end
  if self == o then return true end
  local parent = getmetatable(o)
  while parent do
    if parent == self then return true end
    parent = getmetatable(parent)
  end
  return false
end

local errorString = "%s expected. Got: %s"
function Object.assertType(o, prototype)
  if not prototype:is(o) then error(errorString:format(prototype.className, tostring(o))) end
end

function Object:instanceOf(o)
  if getmetatable(self) == o then return true end
  return false
end

nbre.Object = Object
return Object
