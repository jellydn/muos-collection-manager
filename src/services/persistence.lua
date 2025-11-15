-- Persistence service for saving/loading collections to JSON
-- Constitution: III. Device Constraints (atomic writes for flash storage)

local Logger = require("src.lib.logger")
local json = require("src.lib.json")

local Persistence = {}

-- Save data to file with atomic write pattern (temp file + rename)
-- @param file_path string: Target file path
-- @param data table: Data to serialize to JSON
-- @param version string: Schema version (default "1.0")
-- @return boolean, error
function Persistence.save(file_path, data, version)
    version = version or "1.0"

    -- Validate inputs
    if not file_path or type(file_path) ~= "string" then
        return false, "Invalid file path"
    end

    if not data or type(data) ~= "table" then
        return false, "Data must be a table"
    end

    -- Wrap data with version
    local wrapped_data = {
        version = version,
        collections = data
    }

    -- Serialize to JSON
    local ok, json_string = pcall(json.encode, wrapped_data)
    if not ok then
        Logger.error("Failed to encode JSON:", json_string)
        return false, "JSON encoding failed: " .. tostring(json_string)
    end

    -- Create directory if it doesn't exist
    local dir = file_path:match("(.*/)")
    if dir then
        -- Create directory recursively
        os.execute("mkdir -p '" .. dir .. "'")
    end

    -- Atomic write pattern: write to temp file, then rename
    local temp_path = file_path .. ".tmp"

    -- Write to temp file
    local file, err = io.open(temp_path, "w")
    if not file then
        Logger.error("Failed to open temp file for writing:", err)
        return false, "Cannot write to temp file: " .. tostring(err)
    end

    local write_ok, write_err = file:write(json_string)
    file:close()

    if not write_ok then
        Logger.error("Failed to write to temp file:", write_err)
        -- Clean up temp file
        os.remove(temp_path)
        return false, "Write failed: " .. tostring(write_err)
    end

    -- Atomic rename (replaces existing file)
    local rename_ok = os.rename(temp_path, file_path)
    if not rename_ok then
        Logger.error("Failed to rename temp file to target:", file_path)
        os.remove(temp_path)
        return false, "Atomic rename failed"
    end

    Logger.info("Saved data to", file_path, "(version " .. version .. ")")
    return true
end

-- Load data from file with error handling and schema migration
-- @param file_path string: Source file path
-- @return table|nil, error
function Persistence.load(file_path)
    -- Validate input
    if not file_path or type(file_path) ~= "string" then
        return nil, "Invalid file path"
    end

    -- Check if file exists
    local file, err = io.open(file_path, "r")
    if not file then
        -- File doesn't exist (first run) - not an error
        Logger.debug("File not found (first run?):", file_path)
        return nil, nil  -- Return nil without error
    end

    -- Read file contents
    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        Logger.warn("Empty file:", file_path)
        return nil, "File is empty"
    end

    -- Parse JSON
    local ok, data = pcall(json.decode, content)
    if not ok then
        Logger.error("Failed to parse JSON:", data)
        -- Create backup of corrupted file
        local backup_path = file_path .. ".backup"
        os.rename(file_path, backup_path)
        Logger.info("Created backup of corrupted file:", backup_path)
        return nil, "JSON parsing failed (backup created)"
    end

    -- Handle schema versioning
    if not data.version then
        -- Legacy format without version field - migrate to 1.0
        Logger.warn("Loading legacy format (no version field), migrating to 1.0")
        data = Persistence.migrate_to_v1_0(data)
    elseif data.version == "1.0" then
        -- Current version - no migration needed
        Logger.debug("Loaded schema version 1.0")
    else
        -- Unknown future version - cannot parse safely
        Logger.error("Unsupported schema version:", data.version)
        local backup_path = file_path .. ".backup"
        os.rename(file_path, backup_path)
        Logger.info("Created backup of incompatible file:", backup_path)
        return nil, "Unsupported schema version: " .. tostring(data.version)
    end

    Logger.info("Loaded data from", file_path)
    return data.collections, nil
end

-- Migrate legacy format (no version) to version 1.0
-- @param data table: Legacy data format
-- @return table: Migrated data with version 1.0 structure
function Persistence.migrate_to_v1_0(data)
    -- Assume legacy format has collections array at root
    -- Add version wrapper
    return {
        version = "1.0",
        collections = data.collections or data or {}
    }
end

-- Check if file exists
-- @param file_path string: File path to check
-- @return boolean
function Persistence.file_exists(file_path)
    local file = io.open(file_path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

return Persistence
