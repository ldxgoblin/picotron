local log = require("log")

-- Global API table for the engine port
nbre = nbre or {}

-- Attach logging from the template log module
nbre.logger = log

-- Load registry support (populates functions on the global nbre table)
require("nbre/registry")

return nbre
