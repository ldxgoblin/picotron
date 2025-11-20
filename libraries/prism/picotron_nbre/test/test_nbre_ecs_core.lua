local assert = require("assert")
local log = require("log")

local fixture = {}

function fixture.before_all()
  log.set_level(log.levels.DEBUG)
  log.set_target(log.targets.CONSOLE)
  log.init()
end

function fixture.test_object_extend_and_instance()
  local Object = require("nbre/core/object")
  local Foo = Object:extend("Foo")
  local inst = Foo()

  assert.is_true(inst:isInstance(), "Instance flag should be true")
  assert.are_equal("Foo", Foo.className, "Class name should be set on prototype")
  assert.is_true(Foo:is(inst), "Prototype should recognize its instances")
  assert.is_true(inst:instanceOf(Foo), "Instance should recognize its direct prototype")
end

function fixture.test_component_requirements_and_clone()
  local Object = require("nbre/core/object")
  local Component = require("nbre/core/component")
  local Entity = require("nbre/core/entity")

  local Position = Component:extend("Position")
  function Position:__new(x, y)
    self.x, self.y = x, y
  end
  function Position:getRequirements() end

  local NeedsPos = Component:extend("NeedsPos")
  NeedsPos.requirements = { Position }

  local e = Entity()
  local pos = Position(1, 2)

  -- Check requirements API directly
  local okReq, missing = NeedsPos():checkRequirements(e)
  assert.is_false(okReq, "Requirements should not be met")
  assert.are_equal(Position, missing, "Missing component prototype should be Position")

  -- Adding satisfying component first makes give() succeed
  e:give(pos)
  assert.is_true(e:has(Position), "Entity should report having Position component")

  local ok2 = pcall(function()
    e:give(NeedsPos())
  end)
  assert.is_true(ok2, "Giving NeedsPos after Position should not error")

  -- Clone preserves fields
  local p2 = pos:clone()
  assert.are_equal(pos.x, p2.x, "Cloned component should copy x")
  assert.are_equal(pos.y, p2.y, "Cloned component should copy y")
end

function fixture.test_entity_give_has_get_expect_remove()
  local Entity = require("nbre/core/entity")
  local Component = require("nbre/core/component")

  local Simple = Component:extend("Simple")
  function Simple:getRequirements() end

  local e = Entity()
  local c = Simple()

  e:give(c)
  assert.is_true(e:has(Simple), "Entity should report having Simple component")

  local got = e:get(Simple)
  assert.are_equal(c, got, "get() should return the same instance")
  assert.are_equal(e, got.owner, "Component owner should be set to entity")

  local expect = e:expect(Simple)
  assert.are_equal(c, expect, "expect() should return the component instance")

  e:remove(Simple)
  assert.is_false(e:has(Simple), "Component should be removed after remove()")
end

function fixture.test_entity_relations_basic()
  local Object = require("nbre/core/object")
  local Entity = require("nbre/core/entity")

  local Relation = Object:extend("Relation")
  function Relation:getBase() return Relation end
  function Relation:generateSymmetric() return nil end
  function Relation:generateInverse() return nil end

  local a = Entity()
  local b = Entity()
  local rel = Relation()

  a:addRelation(rel, b)

  assert.is_true(a:hasRelation(Relation, b), "Entity a should have relation to b")
  assert.is_false(b:hasRelation(Relation), "Entity b should not have any relations without symmetry")
end

function fixture.test_system_manager_requirements_and_soft_order()
  local System = require("nbre/core/system")
  local SystemManager = require("nbre/core/system_manager")

  local A = System:extend("A")
  A.requirements = {}
  A.softRequirements = {}

  local B = System:extend("B")
  B.requirements = { A }
  B.softRequirements = {}

  local level = {}

  -- Hard requirement: adding B before A should error
  local sm1 = SystemManager(level)
  local ok1, _ = pcall(function() sm1:addSystem(B()) end)
  assert.is_false(ok1, "Adding system with unmet hard requirements should error")

  -- Adding A then B should succeed
  local sm2 = SystemManager(level)
  sm2:addSystem(A())
  local ok2, _ = pcall(function() sm2:addSystem(B()) end)
  assert.is_true(ok2, "Adding required system first should succeed")

  -- Soft requirement: existing system requires new system to come earlier
  local C = System:extend("C")
  C.requirements = {}
  C.softRequirements = {}

  local D = System:extend("D")
  D.requirements = {}
  D.softRequirements = { C } -- D expects C to be added before it

  local sm3 = SystemManager(level)
  sm3:addSystem(D())
  local ok3, _ = pcall(function() sm3:addSystem(C()) end)
  assert.is_false(ok3, "Violating soft requirement order should error")
end

return fixture
