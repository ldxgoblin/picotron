---@class ActionMessage : Message
---@field actor Actor
local ActionMessage = prism.Message:extend("ActionMessage")

--- @param action Action
function ActionMessage:__new(action)
   self.action = action
end

return ActionMessage
