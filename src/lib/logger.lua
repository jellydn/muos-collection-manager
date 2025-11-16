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

-- Detect if running on muOS device (production) or development machine
local function is_muos_device()
    -- Check for muOS-specific paths
    local muos_paths = {
        "/mnt/mmc/MUOS",
        "/opt/muos",
        "/run/muos"
    }
    
    for _, path in ipairs(muos_paths) do
        local check = io.popen(string.format('test -d "%s" && echo "1"', path))
        if check then
            local result = check:read("*a")
            check:close()
            if result:match("1") then
                return true
            end
        end
    end
    
    return false
end

-- Set default log level based on environment
-- Production (muOS device): INFO level for normal operation
-- Development (Mac/PC): DEBUG level for development
Logger.current_level = is_muos_device() and Logger.LEVEL.INFO or Logger.LEVEL.DEBUG

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
    -- Convert all arguments to strings
    local str_args = {}
    for i, arg in ipairs(args) do
        str_args[i] = tostring(arg)
    end
    local message = table.concat(str_args, " ")
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
