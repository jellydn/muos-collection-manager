-- Simple logger utility for debugging and performance tracking
-- Constitution: I. Performance-First (profiling support)

local Shell = require("src.lib.shell")
local Logger = {}

-- Log levels
Logger.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Log file configuration
Logger.LOG_FILE = "game_vault.log"
Logger.MAX_LINES = 1000
Logger.line_count = 0

-- Detect if running on muOS device (production) or development machine
local function is_muos_device()
    -- Check for muOS-specific paths
    local muos_paths = {
        "/mnt/mmc/MUOS",
        "/opt/muos",
        "/run/muos"
    }
    
    for _, path in ipairs(muos_paths) do
        local check = Shell.popen('test -d %s && echo "1"', path)
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

-- Count lines in log file
local function count_log_lines()
    local file = io.open(Logger.LOG_FILE, "r")
    if not file then
        return 0
    end

    local count = 0
    for _ in file:lines() do
        count = count + 1
    end
    file:close()
    return count
end

-- Clean log file if it exceeds max lines
local function clean_log_if_needed()
    -- Only check every 10 writes to avoid overhead
    if Logger.line_count % 10 == 0 then
        local actual_count = count_log_lines()
        if actual_count > Logger.MAX_LINES then
            -- Truncate the log file
            local file = io.open(Logger.LOG_FILE, "w")
            if file then
                file:write(string.format("--- Log cleaned at %s (exceeded %d lines) ---\n",
                    os.date("%Y-%m-%d %H:%M:%S"), Logger.MAX_LINES))
                file:close()
                Logger.line_count = 1
            end
        else
            Logger.line_count = actual_count
        end
    end
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
    local log_line = string.format("[%s] %s: %s", format_time(), level_name, message)

    -- Print to console
    print(log_line)

    -- Write to file
    clean_log_if_needed()
    local file = io.open(Logger.LOG_FILE, "a")
    if file then
        file:write(log_line .. "\n")
        file:close()
        Logger.line_count = Logger.line_count + 1
    end
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

-- Initialize logger
local function init()
    Logger.line_count = count_log_lines()
end

-- Initialize on load
init()

return Logger
