--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--- @class Logger
--- Logging module for debug purposes.
local logger = {}

--- @alias LogLevel "trace" | "debug" | "info" | "warn" | "error"

--- Whether to use terminal colors or not.
logger.useColor = true
--- A file to log to.
logger.outFile = nil
--- Toggle this on to only log to file.
logger.onlyFile = false
--- The log level to log up to.
--- @type LogLevel
logger.level = "info"
--- Toggle this off to disable all logging.
logger.enabled = true
--- Toggle this on to overwrite the log file every time.
logger.resetFile = false

--- Set options at once with a table.
--- @param options { enabled: boolean, level: LogLevel, outFile: string, onlyFile: boolean, resetFile: boolean, useColor: boolean }
function logger.setOptions(options)
   logger.useColor = options.useColor or logger.useColor
   logger.outFile = options.outFile or logger.outFile
   logger.onlyFile = options.onlyFile or logger.onlyFile
   logger.level = options.level or logger.level
   logger.enabled = options.enabled or logger.enabled
   logger.resetFile = options.resetFile or logger.resetFile
end

function logger.init()
   if logger.outFile then
      local fp = io.open(logger.outFile, "w")
      fp:close()
   end
end

local init = false

local modes = {
   { name = "trace", color = "\27[34m" },
   { name = "debug", color = "\27[36m" },
   { name = "info", color = "\27[32m" },
   { name = "warn", color = "\27[33m" },
   { name = "error", color = "\27[31m" },
}

local levels = {}
for i, v in ipairs(modes) do
   levels[v.name] = i
end

local round = function(x, increment)
   increment = increment or 1
   x = x / increment
   return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
end

local _tostring = tostring

local tostring = function(...)
   local t = {}
   for i = 1, select("#", ...) do
      local x = select(i, ...)
      if type(x) == "number" then x = round(x, 0.01) end
      t[#t + 1] = _tostring(x)
   end
   return table.concat(t, " ")
end

--- @private
function logger.getLevel()
   return levels[logger.level]
end

local function log(i, ...)
   if not logger.enabled then return end

   -- Return early if we're below the logger level
   if i < levels[logger.level] then return end

   if not init then logger.init() end

   local message = tostring(...)

   local x = modes[i]
   local nameupper = x.name:upper()

   local info = debug.getinfo(3, "Sl")

   local lineinfo = info.short_src .. ":" .. info.currentline

   -- Output to console
   if not logger.onlyFile then
      print(
         string.format(
            "%s[%-6s%s]%s %s: %s",
            logger.useColor and x.color or "",
            nameupper,
            os.date("%H:%M:%S"),
            logger.useColor and "\27[0m" or "",
            lineinfo,
            message
         )
      )
   end

   -- Output to logger file
   if logger.outFile then
      local fp = io.open(logger.outFile, "a")
      local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, message)
      fp:write(str)
      fp:close()
   end
end

--- Log a message at the TRACE level.
function logger.trace(...)
   log(1, ...)
end

--- Log a message at the DEBUG level.
function logger.debug(...)
   log(2, ...)
end

--- Log a message at the INFO level.
function logger.info(...)
   log(3, ...)
end

--- Log a message at the WARN level.
function logger.warn(...)
   log(4, ...)
end

--- Log a message at the ERROR level.
function logger.error(...)
   log(5, ...)
end

return logger
