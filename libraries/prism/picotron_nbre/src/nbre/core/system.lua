nbre = nbre or {}

local Object = require("nbre/core/object")

local System = Object:extend("System")
System.requirements = {}
System.softRequirements = {}

function System:getRequirements() end
function System:getSoftRequirements() end

function System:initialize(level) end
function System:postInitialize(level) end

function System:beforeAction(level, actor, action) end
function System:afterAction(level, actor, action) end

function System:beforeMove(level, actor, from, to) end
function System:onMove(level, actor, from, to) end

function System:onActorAdded(level, actor) end
function System:onActorRemoved(level, actor) end

function System:afterOpacityChanged(level, x, y) end

function System:onTick(level) end

function System:onTurn(level, actor) end
function System:onTurnEnd(level, actor) end

function System:onYield(level, event) end

nbre.System = System
return System
