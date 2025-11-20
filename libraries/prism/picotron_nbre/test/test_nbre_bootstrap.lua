local assert = require("assert")
local log = require("log")

local fixture = {}

function fixture.before_all()
  log.set_level(log.levels.DEBUG)
  log.set_target(log.targets.CONSOLE)
  log.init()
end

function fixture.test_nbre_bootstrap_basic()
  local nbre = require("nbre/init")

  assert.is_not_nil(nbre, "nbre should not be nil")
  assert.is_type(nbre, "table", "nbre should be a table")

  assert.is_not_nil(nbre.logger, "nbre.logger should be present")
  assert.is_type(nbre.logger.debug, "function", "nbre.logger.debug should exist")

  assert.is_not_nil(nbre.registries, "nbre.registries should be initialized")
  assert.is_type(nbre.registries, "table", "nbre.registries should be a table")

  assert.is_type(nbre.registerRegistry, "function", "nbre.registerRegistry should be a function")
  assert.is_type(nbre.register, "function", "nbre.register should be a function")
  assert.is_type(nbre.resolveFactory, "function", "nbre.resolveFactory should be a function")
end

return fixture
