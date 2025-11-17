-- muOS Tracker Service
-- Reads playtime and launch data from muOS tracking system
-- Constitution: II. Resource Efficiency (lazy loading, cached reads)

local Logger = require("src.lib.logger")
local JSON = require("src.lib.json")

local MuOSTracker = {}

-- Paths for muOS tracking data
MuOSTracker.PLAYTIME_PATH = "/mnt/mmc/MUOS/info/track/playtime_data.json"

-- Cache for playtime data
MuOSTracker.cache = nil
MuOSTracker.cache_timestamp = 0
MuOSTracker.cache_ttl = 60 -- Cache for 60 seconds

-- Load and parse playtime data
-- @return table: Playtime data indexed by ROM path, or empty table on failure
function MuOSTracker.load_playtime_data()
    -- Check cache first
    local now = os.time()
    if MuOSTracker.cache and (now - MuOSTracker.cache_timestamp) < MuOSTracker.cache_ttl then
        Logger.debug("Using cached playtime data")
        return MuOSTracker.cache
    end

    -- Try to load from file
    local file = io.open(MuOSTracker.PLAYTIME_PATH, "r")
    if not file then
        Logger.debug("muOS playtime data not found:", MuOSTracker.PLAYTIME_PATH)
        MuOSTracker.cache = {}
        MuOSTracker.cache_timestamp = now
        return {}
    end

    local content = file:read("*all")
    file:close()

    -- Parse JSON
    local success, data = pcall(JSON.decode, content)
    if not success or not data then
        Logger.warn("Failed to parse playtime data:", data)
        MuOSTracker.cache = {}
        MuOSTracker.cache_timestamp = now
        return {}
    end

    -- Count entries (data is a table with path keys, not an array)
    local count = 0
    for _ in pairs(data) do count = count + 1 end
    Logger.info("Loaded playtime data for", count, "games")
    MuOSTracker.cache = data
    MuOSTracker.cache_timestamp = now
    return data
end

-- Get playtime info for a specific ROM
-- @param rom_path string: Full path to ROM file
-- @return table|nil: Playtime data or nil if not found
function MuOSTracker.get_playtime(rom_path)
    local data = MuOSTracker.load_playtime_data()
    return data[rom_path]
end

-- Enrich game object with muOS tracking data
-- @param game table: Game object with file_path field
-- @return table: Enhanced game object with playtime data
function MuOSTracker.enrich_game(game)
    if not game or not game.file_path then
        Logger.debug("enrich_game: game or file_path is nil")
        return game
    end

    Logger.info("enrich_game called for:", game.title, "path:", game.file_path)
    local playtime = MuOSTracker.get_playtime(game.file_path)
    Logger.info("Playtime data retrieved:", playtime and "found" or "not found")
    if playtime then
        -- Add muOS-specific tracking data
        game.muos_launches = playtime.launches or 0
        game.muos_total_time = playtime.total_time or 0 -- in seconds
        game.muos_avg_time = playtime.avg_time or 0 -- average session in seconds
        game.muos_last_played = playtime.start_time or nil -- Unix timestamp
        game.muos_last_core = playtime.last_core or nil
        game.muos_last_device = playtime.last_device or nil

        Logger.info(string.format("Enriched %s: %d launches, %d total seconds",
            game.title, game.muos_launches, game.muos_total_time))
    else
        Logger.info("No playtime data found for:", game.title)
    end

    return game
end

-- Clear cache (useful for forcing refresh)
function MuOSTracker.clear_cache()
    Logger.info("muOS tracker cache cleared")
    MuOSTracker.cache = nil
    MuOSTracker.cache_timestamp = 0
end

-- Format playtime in human-readable format
-- @param seconds number: Total seconds played
-- @return string: Formatted time (e.g., "2h 15m", "45m", "30s")
function MuOSTracker.format_playtime(seconds)
    if not seconds or seconds < 1 then
        return "0s"
    end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        if minutes > 0 then
            return string.format("%dh %dm", hours, minutes)
        else
            return string.format("%dh", hours)
        end
    elseif minutes > 0 then
        return string.format("%dm", minutes)
    else
        return string.format("%ds", secs)
    end
end

-- Format last played timestamp
-- @param timestamp number: Unix timestamp
-- @return string: Relative time (e.g., "2 days ago", "1 hour ago")
function MuOSTracker.format_last_played(timestamp)
    if not timestamp then
        return "Never"
    end

    local now = os.time()
    local diff = now - timestamp

    if diff < 60 then
        return "Just now"
    elseif diff < 3600 then
        local minutes = math.floor(diff / 60)
        return string.format("%d minute%s ago", minutes, minutes > 1 and "s" or "")
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return string.format("%d hour%s ago", hours, hours > 1 and "s" or "")
    elseif diff < 604800 then
        local days = math.floor(diff / 86400)
        return string.format("%d day%s ago", days, days > 1 and "s" or "")
    elseif diff < 2592000 then
        local weeks = math.floor(diff / 604800)
        return string.format("%d week%s ago", weeks, weeks > 1 and "s" or "")
    else
        local months = math.floor(diff / 2592000)
        return string.format("%d month%s ago", months, months > 1 and "s" or "")
    end
end

return MuOSTracker
