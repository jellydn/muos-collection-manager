-- Shell utility for safe command execution
-- Provides shell argument escaping to prevent command injection vulnerabilities

local Shell = {}

-- Lua 5.1 compatibility: unpack is global, not table.unpack
local unpack = unpack or table.unpack

-- Escape a shell argument to prevent command injection
-- Wraps the argument in single quotes and escapes any single quotes within
-- @param arg string: Argument to escape
-- @return string: Escaped argument safe for use in shell commands
function Shell.escape(arg)
    if type(arg) ~= "string" then
        arg = tostring(arg)
    end
    
    -- Replace single quotes with '\'' (end quote, escaped quote, start quote)
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

-- Safely execute a shell command with escaped arguments
-- @param cmd string: Command template with %s placeholders
-- @param ... string: Arguments to escape and insert
-- @return boolean|number: Command exit status
function Shell.execute(cmd, ...)
    local args = {...}
    local escaped_args = {}
    
    for i, arg in ipairs(args) do
        escaped_args[i] = Shell.escape(arg)
    end
    
    local safe_cmd = string.format(cmd, unpack(escaped_args))
    return os.execute(safe_cmd)
end

-- Safely execute a command with wildcard support
-- For commands that need wildcards (like rm -f %s/*.cfg), use this variant
-- The path is escaped, but wildcards are appended outside quotes
-- @param base_cmd string: Base command (e.g., "rm -f")
-- @param path string: Path to escape
-- @param wildcard string: Wildcard pattern to append (e.g., "/*.cfg")
-- @param redirect string: Optional redirect (e.g., "2>/dev/null")
-- @return boolean|number: Command exit status
function Shell.execute_with_wildcard(base_cmd, path, wildcard, redirect)
    local escaped_path = Shell.escape(path)
    -- Remove trailing quote and add wildcard, then re-add quote
    local safe_path = escaped_path:sub(1, -2) .. wildcard .. "'"
    local cmd = base_cmd .. " " .. safe_path
    if redirect then
        cmd = cmd .. " " .. redirect
    end
    return os.execute(cmd)
end

-- Safely open a shell command pipe with escaped arguments
-- @param cmd string: Command template with %s placeholders
-- @param ... string: Arguments to escape and insert
-- @return file*|nil: File handle or nil on error
function Shell.popen(cmd, ...)
    local args = {...}
    local escaped_args = {}
    
    for i, arg in ipairs(args) do
        escaped_args[i] = Shell.escape(arg)
    end
    
    local safe_cmd = string.format(cmd, unpack(escaped_args))
    return io.popen(safe_cmd)
end

-- Safely open a pipe with wildcard support
-- For commands that need wildcards (like ls -1d %s/*/), use this variant
-- @param base_cmd string: Base command (e.g., "ls -1d")
-- @param path string: Path to escape
-- @param wildcard string: Wildcard pattern to append (e.g., "/*/")
-- @param redirect string: Optional redirect (e.g., "2>/dev/null")
-- @return file*|nil: File handle or nil on error
function Shell.popen_with_wildcard(base_cmd, path, wildcard, redirect)
    local escaped_path = Shell.escape(path)
    -- Remove trailing quote and add wildcard, then re-add quote
    local safe_path = escaped_path:sub(1, -2) .. wildcard .. "'"
    local cmd = base_cmd .. " " .. safe_path
    if redirect then
        cmd = cmd .. " " .. redirect
    end
    return io.popen(cmd)
end

return Shell
