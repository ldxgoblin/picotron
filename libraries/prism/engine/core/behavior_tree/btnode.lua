--- The base class for all nodes in the behavior tree.
--- @class BehaviorTree.Node : Object, IBehavior
--- @overload fun(run: fun(self: BehaviorTree.Node, level: Level, actor: Actor, controller: Controller): boolean|Action): BehaviorTree.Node
local BTNode = prism.Object:extend("BehaviorTree.Node")

--- You can also construct an anonymous node like:
--- prism.BehaviorTree.Node(function(level, actor) return true end)
--- For this reason simple nodes like succeeders, inverters, failers etc.
--- should just be created using these anonymous nodes.
--- @param run fun(self: BehaviorTree.Node, level: Level, actor: Actor, controller: Controller): boolean|Action
function BTNode:__new(run)
   self.run = run or self.run
end

--- Override this method in your own nodes, or supply an anonymous function
--- to the constructor to create an 'anonymous node'. While we pass in self here
--- it's generally not a good idea to store state on the nodes itself, but it can be
--- fine for caching a path for instance.
--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function BTNode:run(level, actor, controller)
   error "BehaviorTree.Node is an abstract class! Extend it or provide a run method!"
end

return BTNode
