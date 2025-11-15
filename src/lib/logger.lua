-- Simple logger utility for debugging and performance tracking
-- Constitution: I. Performance-First (profiling support)

local Logger = {}

-- Log levels
Logger.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Current log level (set to INFO in production, DEBUG for development)
Logger.current_level = Logger.LEVEL.INFO

-- Format timestamp
local function format_time()
    return os.date("%H:%M:%S")
end

-- Core logging function
local function log(level, level_name, ...)
    if level < Logger.current_level then
        return
    end
    
    local args = {...}
    local message = table.concat(args, " ")
    print(string.format("[%s] %s: %s", format_time(), level_name, message))
end

-- Public API
function Logger.debug(...)
    log(Logger.LEVEL.DEBUG, "DEBUG", ...)
end

function Logger.info(...)
    log(Logger.LEVEL.INFO, "INFO", ...)
end

function Logger.warn(...)
    log(Logger.LEVEL.WARN, "WARN", ...)
end

function Logger.error(...)
    log(Logger.LEVEL.ERROR, "ERROR", ...)
end

-- Performance profiling helper
function Logger.profile(name, func)
    local start_time = love.timer.getTime()
    local result = {func()}
    local elapsed = (love.timer.getTime() - start_time) * 1000  -- Convert to ms
    
    Logger.debug(string.format("PROFILE [%s]: %.2fms", name, elapsed))
    
    return table.unpack(result)
end

-- Set log level
function Logger.set_level(level)
    Logger.current_level = level
end

return Logger
