---@class DebugMessage : Message
---@field message string A human readable message for why we stopped here.
local ActionMessage = prism.Message:extend "DebugMessage"

--- @param message string
function ActionMessage:__new(message)
   self.message = message
end

return ActionMessage
