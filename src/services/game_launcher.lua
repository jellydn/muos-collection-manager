-- Game Launcher Service
-- Exports collections to muOS-compatible format for native launcher integration

local Logger = require("src.lib.logger")
local Paths = require("src.config.paths")

local GameLauncher = {}

-- Export collection to muOS format
-- muOS collections are stored as folders with .cfg files per game
-- Location: /mnt/mmc/MUOS/info/collection/<CollectionName>/
-- Each .cfg file contains: ROM_PATH\nSYSTEM\nDISPLAY_NAME
function GameLauncher.export_to_muos(collection, games)
    if not collection then
        Logger.error("Cannot export: collection is nil")
        return false, "No collection specified"
    end

    if not games or #games == 0 then
        Logger.warn("Exporting empty collection:", collection.name)
    end

    -- All collections export to /mnt/mmc/MUOS/info/collection/<Name>/
    local muos_collect_base = "/mnt/mmc/MUOS/info/collection"

    -- Sanitize collection name for folder name (remove special chars)
    local safe_name = collection.name:gsub("[^%w%s%-]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if safe_name == "" then
        safe_name = "Untitled"
    end

    local collection_dir = string.format("%s/%s", muos_collect_base, safe_name)

    Logger.info("Exporting collection to muOS:", collection.name)
    Logger.info("Target directory:", collection_dir)
    Logger.info("Games to export:", #games)
    
    -- Create collection directory (and parent if needed)
    os.execute(string.format('mkdir -p "%s"', collection_dir))
    
    -- Clear existing .cfg files in collection directory
    os.execute(string.format('rm -f "%s"/*.cfg 2>/dev/null', collection_dir))
    
    -- Write each game as a separate .cfg file
    local exported_count = 0
    for _, game in ipairs(games) do
        if game.file_path and game.title then
            -- Generate unique hash for filename (simple hash from title + path)
            local hash_input = game.title .. game.file_path
            local hash = string.format("%08X", tonumber(string.sub(hash_input:gsub("[^%w]", ""), 1, 8), 36) or 0)
            
            -- Sanitize game title for filename
            local safe_title = game.title:gsub("[^%w%s%-]", ""):gsub("%s+", " ")
            local cfg_filename = string.format("%s/%s-%s.cfg", collection_dir, safe_title, hash)
            
            -- muOS uses /mnt/union/ROMS instead of /mnt/mmc/ROMS
            local muos_path = game.file_path:gsub("^/mnt/mmc/ROMS", "/mnt/union/ROMS")
            
            -- Write .cfg file with 3 lines: path, system, display name
            local file, err = io.open(cfg_filename, "w")
            if file then
                file:write(muos_path .. "\n")
                file:write((game.system or "UNKNOWN"):upper() .. "\n")
                file:write(game.title .. "\n")
                file:close()
                exported_count = exported_count + 1
            else
                Logger.error("Failed to create .cfg file:", cfg_filename, err)
            end
        end
    end
    
    Logger.info("Exported", exported_count, "games to muOS collection:", safe_name)
    return true, collection_dir
end

-- Update game stats (favorite toggle, etc)
function GameLauncher.update_play_stats(game)
    if not game then return end
    
    game.last_played = os.time()
    game.play_count = (game.play_count or 0) + 1
    
    Logger.info("Updated play stats for:", game.title, "- count:", game.play_count)
end

-- Format last played time for display
function GameLauncher.format_last_played(timestamp)
    if not timestamp or timestamp == 0 then
        return "Never"
    end
    
    local date = os.date("*t", timestamp)
    return string.format("%04d-%02d-%02d %02d:%02d", 
        date.year, date.month, date.day, date.hour, date.min)
end

return GameLauncher
