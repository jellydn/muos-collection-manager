-- Error Handler and Recovery Utilities
-- Constitution: II. Resource Efficiency (graceful degradation)

local Logger = require("src.lib.logger")
local Paths = require("src.config.paths")
local json = require("src.lib.json")

local ErrorHandler = {}

-- Error recovery strategies
ErrorHandler.STRATEGIES = {
    FALLBACK = "fallback",      -- Use default/empty data
    RETRY = "retry",            -- Retry operation
    SKIP = "skip",              -- Skip corrupted item
    BACKUP = "backup"           -- Restore from backup
}

-- Safe file read with error handling
function ErrorHandler.safe_read_json(file_path, strategy)
    strategy = strategy or ErrorHandler.STRATEGIES.FALLBACK
    
    if not Paths.file_exists(file_path) then
        Logger.warn("File not found:", file_path)
        return nil, "File not found"
    end
    
    local file = io.open(file_path, "r")
    if not file then
        Logger.error("Cannot open file:", file_path)
        return nil, "Cannot open file"
    end
    
    local content = file:read("*a")
    file:close()
    
    -- Parse JSON
    local success, data = pcall(json.decode, content)
    
    if not success then
        Logger.error("JSON parse error in:", file_path, "=>", data)
        
        if strategy == ErrorHandler.STRATEGIES.BACKUP then
            -- Try to restore from backup
            local backup_path = file_path .. ".backup"
            if Paths.file_exists(backup_path) then
                Logger.info("Restoring from backup:", backup_path)
                return ErrorHandler.safe_read_json(backup_path, ErrorHandler.STRATEGIES.FALLBACK)
            end
        end
        
        return nil, "JSON parse error: " .. tostring(data)
    end
    
    return data, nil
end

-- Safe JSON write with atomic operation and backup
function ErrorHandler.safe_write_json(file_path, data)
    -- Ensure directory exists
    local dir = file_path:match("(.*)/")
    if dir and not Paths.dir_exists(dir) then
        os.execute("mkdir -p \"" .. dir .. "\"")
    end
    
    -- Encode JSON
    local success, json_str = pcall(json.encode, data)
    if not success then
        Logger.error("JSON encode error:", json_str)
        return false, "JSON encode error"
    end
    
    -- Atomic write: write to temp file first, then rename
    local temp_path = file_path .. ".tmp"
    local file = io.open(temp_path, "w")
    if not file then
        Logger.error("Cannot open temp file for writing:", temp_path)
        return false, "Cannot write to temp file"
    end
    
    file:write(json_str)
    file:close()
    
    -- Create backup of existing file
    if Paths.file_exists(file_path) then
        os.execute(string.format("cp \"%s\" \"%s.backup\"", file_path, file_path))
    end
    
    -- Atomic rename
    local rename_ok = os.rename(temp_path, file_path)
    if not rename_ok then
        Logger.error("Cannot rename temp file to:", file_path)
        return false, "Cannot finalize write"
    end
    
    Logger.info("File saved successfully:", file_path)
    return true, nil
end

-- Handle corrupted collection file with recovery
function ErrorHandler.recover_collection_file(file_path)
    Logger.warn("Attempting to recover corrupted collection file:", file_path)
    
    local backup_path = file_path .. ".backup"
    if Paths.file_exists(backup_path) then
        Logger.info("Restoring from backup...")
        os.execute(string.format("cp \"%s\" \"%s\"", backup_path, file_path))
        return true, "Restored from backup"
    end
    
    -- If no backup, create empty collection file
    Logger.warn("No backup found. Creating empty collection file.")
    local empty_data = json.encode({})
    local file = io.open(file_path, "w")
    if file then
        file:write(empty_data)
        file:close()
        return true, "Created empty collection"
    end
    
    return false, "Recovery failed - cannot create collection file"
end

-- Handle missing ROM directory with logging
function ErrorHandler.handle_missing_rom_dir(dir_path)
    Logger.error("ROM directory not found:", dir_path)
    Logger.info("Expected ROM structure:")
    Logger.info("  /mnt/mmc/ROMS/NES/game1.nes")
    Logger.info("  /mnt/mmc/ROMS/SNES/game2.smc")
    Logger.info("  /mnt/mmc/ROMS/Genesis/game3.bin")
    
    return {
        missing_dir = dir_path,
        recovery_action = "SKIP",
        message = "ROM directory not found - continuing with other directories"
    }
end

-- Validate schema version and handle migration
function ErrorHandler.validate_schema(data, expected_version)
    if not data then return nil, "No data" end
    
    local version = data.version or "unknown"
    
    if version == expected_version then
        return true, nil
    end
    
    Logger.warn(string.format("Schema mismatch: expected %s, got %s",
        expected_version, version))
    
    -- Future: implement migration logic here
    -- For now, accept as-is (forward compatible)
    return true, "Schema version mismatch (continuing)"
end

-- Wrap function call with error handling
function ErrorHandler.safe_call(func, ...)
    local success, result = pcall(func, ...)
    
    if not success then
        Logger.error("Error in safe_call:", result)
        Logger.error("Stack trace:", debug.traceback())
        return nil, result
    end
    
    return result, nil
end

return ErrorHandler
