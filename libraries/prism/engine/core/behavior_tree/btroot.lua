--- The root node of a behavior tree.
--- @class BehaviorTree.Root : BehaviorTree.Node
--- @overload fun(children: BehaviorTree.Node[]): BehaviorTree.Root
local BTRoot = prism.BehaviorTree.Node:extend("BehaviorTree.Root")

--- Creates a new BTRoot.
--- @param children BehaviorTree.Node[]
function BTRoot:__new(children)
   self.children = self.children or children
end

--- Runs the behavior tree starting from this root node.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return Action
function BTRoot:run(level, actor, controller)
   for i = 1, #self.children do
      local child = self.children[i]
      local result = child:run(level, actor, controller)
      if result and type(result) ~= "boolean" and prism.Action:is(result) then
         --- @type Action
         return result
      end
   end

   error "Root node must return an action"
end

return BTRoot
