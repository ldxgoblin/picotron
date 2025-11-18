--- A succeeder node in the behavior tree.
--- @class BehaviorTree.Succeeder : BehaviorTree.Node
--- @overload fun(node: BehaviorTree.Node): BehaviorTree.Succeeder
local BTSucceeder = prism.BehaviorTree.Node:extend("BehaviorTree.Succeeder")

--- Creates a new BTSucceeder.
--- @param node BehaviorTree.Node
function BTSucceeder:__new(node)
   self.node = node
end

--- Runs the succeeder node.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function BTSucceeder:run(level, actor, controller)
   local ret = self.node:run(level, actor, controller)
   if ret == false then return true end
   return ret
end

return BTSucceeder
