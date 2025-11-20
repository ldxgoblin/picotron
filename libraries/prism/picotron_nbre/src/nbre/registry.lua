nbre = nbre or {}
local api = nbre

api.registries = api.registries or {}

--- Registers a registry, a global list of game objects.
--- @param name string The name of the registry, e.g. "components".
--- @param type table The type of the object, e.g. a Component prototype.
--- @param factory? boolean Whether objects in the registry are registered with a factory. Defaults to false.
--- @param moduleName? string The table to assign the registry to. Defaults to the global NBRE table.
function api.registerRegistry(name, type, factory, moduleName)
  moduleName = moduleName or "nbre"

  for _, registry in ipairs(api.registries) do
    if registry.name == name then
      error("A registry with name " .. name .. " is already registered!")
    end
  end

  local moduleTable = _G[moduleName] or api
  if moduleTable[name] then
    error("namespace for registry " .. name .. "already contains " .. name .. "!")
  end
  moduleTable[name] = {}

  local registry = {
    name = name,
    class = type,
    manualRegistration = factory or false,
    module = moduleName,
  }

  table.insert(api.registries, registry)

  if factory then
    local className = type.className
    local registryList = moduleTable[name]
    local registryStr = moduleName .. "." .. name

    _G[moduleName]["register" .. className] = function(objectName, creator)
      assert(
        registryList[objectName] == nil,
        className .. " " .. objectName .. " is already registered!"
      )

      local classStr = registryStr .. "." .. objectName
      registryList[objectName] = function(...)
        local o = creator(...)
        if type(o) == "table" then o.__factory = classStr end
        return o
      end
    end
  end
end

--- Registers an object into its registry. Errors if the object has no registry.
--- @param object table The object to register.
--- @param _skipDefinitions any Ignored; kept for API compatibility only.
function api.register(object, _skipDefinitions)
  if type(object) == "string" then
    error(
      "Tried to register a string (" .. object .. ") as an object. Did you mean to register a factory?"
    )
  end

  assert(
    api.Object and api.Object.is and api.Object:is(object),
    "Tried to register a non-Object (" .. tostring(object) .. ") object!"
  )

  local registry
  for _, r in ipairs(api.registries) do
    if r.class:is(object) then
      registry = r
    end
  end

  local objectName = object.className
  assert(registry, "Tried to register a " .. objectName .. " but it has no registry!")
  assert(
    not registry.manualRegistration,
    "Tried to register an object (" .. objectName .. ") into a factory registry!"
  )

  local moduleTable = _G[registry.module] or api
  local registryList = moduleTable[registry.name]
  assert(
    registryList[objectName] == nil,
    string.format("Tried to register duplicate %s (%s)", registry.class.className, objectName)
  )

  registryList[objectName] = object

  if api.logger and api.logger.debug then
    api.logger.debug("Registered ", objectName, " into ", registry.module, ".", registry.name)
  end
end

--- Resolves a factory from a dotted path stored on created instances.
--- @param path string
--- @return any
function api.resolveFactory(path)
  local node = _G
  for seg in string.gmatch(path, "[^%.]+") do
    node = node[seg]
  end
  return node
end

return api
