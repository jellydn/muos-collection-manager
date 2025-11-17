-- Game Library Service
-- Constitution: I. Performance-First (efficient ROM scanning)

local Logger = require("src.lib.logger")
local Paths = require("src.config.paths")
local Game = require("src.models.game")

local GameLibrary = {}

-- Library state
GameLibrary.games = {}
GameLibrary.is_loaded = false

-- Parse game metadata from filename
-- Examples:
--   "Super Mario Bros (USA) (1985).nes" -> title="Super Mario Bros", year=1985
--   "Sonic (1991) [2P].bin" -> title="Sonic", year=1991, player_count=2
local function parse_filename(filename, system)
    local metadata = {
        title = filename,
        year = nil,
        player_count = 1,
        genre = {"Unknown"}
    }

    -- Remove file extension
    local name_without_ext = filename:match("(.+)%..+$") or filename

    -- Extract year (4 digits in parentheses)
    local year = name_without_ext:match("%((%d%d%d%d)%)")
    if year then
        metadata.year = tonumber(year)
        -- Remove year from title
        name_without_ext = name_without_ext:gsub("%s*%(" .. year .. "%)%s*", " ")
    end

    -- Extract player count [NP] format
    local players = name_without_ext:match("%[(%d)P%]")
    if players then
        metadata.player_count = tonumber(players)
        -- Remove player count from title
        name_without_ext = name_without_ext:gsub("%s*%[%d+P%]%s*", " ")
    end

    -- Remove common tags: (USA), (Japan), (Europe), (Rev X), etc.
    name_without_ext = name_without_ext:gsub("%s*%([^%)]*%)%s*", " ")
    name_without_ext = name_without_ext:gsub("%s*%[[^%]]*%]%s*", " ")

    -- Trim whitespace
    metadata.title = name_without_ext:match("^%s*(.-)%s*$")

    return metadata
end

-- Recursively scan directory and subdirectories for ROM files
local function scan_directory_recursive(dir_path, games, depth, progress_callback)
    games = games or {}
    depth = depth or 0

    -- Safety limit: prevent infinite recursion
    if depth > 10 then
        Logger.warn("Maximum recursion depth reached:", dir_path)
        return games
    end

    if not Paths.dir_exists(dir_path) then
        Logger.warn("Directory does not exist:", dir_path)
        return games
    end

    Logger.info("Scanning directory:", dir_path)

    -- Ensure path ends with /
    if not dir_path:match("/$") then
        dir_path = dir_path .. "/"
    end

    -- Use find command for recursive scanning (much faster than manual recursion)
    -- -type f: files only, -not -path: exclude hidden directories
    Logger.info("Scanning directory:", dir_path)
    Logger.debug("About to execute find command...")

    local start_time = love.timer.getTime()
    local Shell = require("src.lib.shell")
    local handle = Shell.popen('find %s -type f -not -path "*/\\.*" 2>&1', dir_path)

    Logger.debug("io.popen() returned, handle:", tostring(handle))

    if not handle then
        Logger.error("Failed to execute find command for:", dir_path)
        Logger.error("ERROR: io.popen() returned nil!")
        return games
    end

    Logger.info("Reading file list from find output...")
    Logger.debug("Starting to read lines from find output...")
    local count = 0
    local total_files = 0
    local max_scan_time = 60 -- Maximum 60 seconds for scanning
    local last_log_time = start_time

    for file_path in handle:lines() do
        total_files = total_files + 1

        -- Log first file found
        if total_files == 1 then
            Logger.debug("First file found:", file_path)
        end

        -- Check timeout every 100 files
        if total_files % 100 == 0 then
            local elapsed = love.timer.getTime() - start_time
            if elapsed > max_scan_time then
                Logger.warn(string.format("Scan timeout after %.1fs, scanned %d files, found %d ROMs",
                    elapsed, total_files, count))
                break
            end
        end

        -- Progress callback every 50 files (more frequent for UI updates)
        if progress_callback and total_files % 50 == 0 then
            local elapsed = love.timer.getTime() - start_time
            progress_callback(count, total_files, string.format("Found %d ROMs (%.1fs)...", count, elapsed))
        end

        -- Progress indicator every 100 files (for logs)
        local current_time = love.timer.getTime()
        if current_time - last_log_time >= 2.0 then  -- Log every 2 seconds
            local elapsed = current_time - start_time
            Logger.info(string.format("Scanning: %d files, %d ROMs, %.1fs elapsed", total_files, count, elapsed))
            last_log_time = current_time
        end

        local filename = file_path:match("([^/]+)$")

        -- Check if it's a valid ROM file
        if filename and Paths.is_rom_file(filename) then
            -- Detect system from file path (includes parent directory for archives)
            local system = Paths.detect_system_from_path(file_path)

            -- Parse metadata from filename
            local metadata = parse_filename(filename, system)

            -- Log first 5 games found, then only every 10th
            if count < 5 or count % 10 == 0 then
                Logger.info(string.format("Found ROM #%d: %s [%s]",
                    count + 1,
                    metadata.title,
                    system:upper()))
            end

            -- Create game object
            local game = Game.new({
                id = Game.generate_id(file_path),
                title = metadata.title,
                file_path = file_path,
                system = system,
                genre = metadata.genre,
                year = metadata.year,
                player_count = metadata.player_count,
                favorite = false,
                play_count = 0,
                last_played = nil
            })

            -- Validate and add to list
            local valid, errors = game:validate()
            if valid then
                table.insert(games, game)
                count = count + 1
            else
                Logger.warn("Invalid game data for", filename, ":", table.concat(errors, ", "))
            end
        end
    end

    Logger.debug("Finished reading lines, total_files:", total_files, "count:", count)

    handle:close()

    Logger.debug("Handle closed")

    Logger.info(string.format("Scan complete: %d total files, %d valid ROMs found", total_files, count))

    return games
end

-- Load all games from ROM directories (recursive scan)
-- Optional progress_callback(current, total, message) for UI updates
function GameLibrary.load(progress_callback)
    Logger.info("=== GameLibrary.load() START ===")
    Logger.debug("GameLibrary.load() called")

    local start_time = love.timer.getTime()
    GameLibrary.games = {}

    -- Check if ROM root exists
    Logger.info("Checking ROM root directory:", Paths.roms_root)
    Logger.debug("ROM root:", Paths.roms_root)

    local dir_exists = Paths.dir_exists(Paths.roms_root)
    Logger.info("Directory exists check result:", dir_exists)
    Logger.debug("Directory exists:", dir_exists)

    -- Recursively scan the entire ROMS root directory
    if dir_exists then
        Logger.info("Starting recursive scan of:", Paths.roms_root)
        Logger.debug("About to call scan_directory_recursive...")

        GameLibrary.games = scan_directory_recursive(Paths.roms_root, {}, 0, progress_callback)

        Logger.debug("scan_directory_recursive returned")
        Logger.info("Recursive scan returned", #GameLibrary.games, "games")
    else
        Logger.error("ROM root directory does not exist:", Paths.roms_root)
        -- Try to list what's in /mnt/mmc to help debug
        Logger.info("Attempting to list /mnt/mmc contents...")
        local Shell = require("src.lib.shell")
        local handle = Shell.popen("ls -la %s 2>&1", "/mnt/mmc")
        if handle then
            for line in handle:lines() do
                Logger.info("  " .. line)
            end
            handle:close()
        end
    end

    -- Sort by title
    table.sort(GameLibrary.games, Game.compare_by_title)

    local elapsed = (love.timer.getTime() - start_time) * 1000
    Logger.info(string.format("Loaded %d games in %.2fms", #GameLibrary.games, elapsed))

    -- Log system breakdown
    local system_counts = {}
    for _, game in ipairs(GameLibrary.games) do
        system_counts[game.system] = (system_counts[game.system] or 0) + 1
    end

    for system, count in pairs(system_counts) do
        Logger.info(string.format("  %s: %d games", system:upper(), count))
    end

    -- Load favorites from disk
    GameLibrary.load_favorites()
    
    -- Load muOS history to populate last_played timestamps
    GameLibrary.load_muos_history()

    GameLibrary.is_loaded = true
    return GameLibrary.games
end

-- Get all games
function GameLibrary.get_all()
    return GameLibrary.games
end

-- Get game by ID
function GameLibrary.get_by_id(id)
    for _, game in ipairs(GameLibrary.games) do
        if game.id == id then
            return game
        end
    end
    return nil
end

-- Get games by system
function GameLibrary.get_by_system(system)
    local results = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.system == system:lower() then
            table.insert(results, game)
        end
    end
    return results
end

-- Get favorite games
function GameLibrary.get_favorites()
    local results = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.favorite then
            table.insert(results, game)
        end
    end
    return results
end

-- Load muOS history and update game last_played timestamps
-- Reads from /mnt/mmc/MUOS/info/history/ and matches to games in library
function GameLibrary.load_muos_history()
    local Shell = require("src.lib.shell")
    local history_dir = "/mnt/mmc/MUOS/info/history"
    
    -- Check if history directory exists
    if not Paths.dir_exists(history_dir) then
        Logger.debug("muOS history directory not found:", history_dir)
        return 0
    end
    
    Logger.info("Loading muOS history from:", history_dir)
    
    -- Build file list using simple shell loop (handles UTF-8, no external tools)
    local file_list = {}
    local cmd = string.format('cd %s 2>/dev/null && for f in *.cfg; do [ -f "$f" ] && echo "$f"; done 2>/dev/null', Shell.escape(history_dir))
    local dir_handle = io.popen(cmd)
    
    if dir_handle then
        for filename in dir_handle:lines() do
            if filename and filename ~= "" and filename ~= "*.cfg" then
                -- Build full path
                local full_path = history_dir .. "/" .. filename
                table.insert(file_list, full_path)
                Logger.info("Found history file:", filename)
            end
        end
        dir_handle:close()
    else
        Logger.warn("Failed to list history directory")
        return 0
    end
    
    if #file_list == 0 then
        Logger.debug("No .cfg files found in history directory")
        return 0
    end
    
    Logger.info("Found", #file_list, "history files")
    
    local matched_count = 0
    local file_count = 0
    local unmatched_files = {}  -- Track files that don't match
    
    -- Create a lookup map for fast game matching by file_path
    local games_by_path = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.file_path then
            -- Normalize path for matching (handle both /mnt/mmc/ROMS and /mnt/union/ROMS)
            local normalized = game.file_path:gsub("^/mnt/union/ROMS", "/mnt/mmc/ROMS")
            games_by_path[normalized] = game
            -- Also store original path
            games_by_path[game.file_path] = game
        end
    end
    
    -- Read each history file
    for _, history_file in ipairs(file_list) do
        file_count = file_count + 1
        
        -- Read the .cfg file (3-line format: path, system, display_name)
        -- Example:
        --   /mnt/union/ROMS/GB/Battletoads-Double Dragon (USA).zip
        --   GB
        --   Battletoads-Double Dragon (USA)
        local cfg_file, err = io.open(history_file, "r")
        local rom_path, system, display_name
        
        if cfg_file then
            rom_path = cfg_file:read("*l")  -- Line 1: ROM path (e.g., /mnt/union/ROMS/GB/game.zip)
            system = cfg_file:read("*l")     -- Line 2: System (e.g., GB)
            display_name = cfg_file:read("*l") -- Line 3: Display name (e.g., Battletoads-Double Dragon (USA))
            cfg_file:close()
        else
            -- Fallback: UTF-8 filenames may fail with io.open, try using shell cat command
            Logger.warn(string.format("Failed to open history file with io.open: %s (error: %s)", history_file, err or "unknown"))
            Logger.info("Attempting fallback with shell cat command...")
            
            local cat_handle = Shell.popen('cat %s 2>/dev/null', history_file)
            if cat_handle then
                rom_path = cat_handle:read("*l")
                system = cat_handle:read("*l")
                display_name = cat_handle:read("*l")
                cat_handle:close()
                
                if rom_path then
                    Logger.info("Successfully read file with cat fallback")
                else
                    Logger.warn("Cat fallback also failed to read file")
                end
            else
                Logger.warn("Cat command also failed, skipping file")
            end
        end
        
        if rom_path and rom_path ~= "" then
                -- Normalize path (muOS uses /mnt/union/ROMS, we scan /mnt/mmc/ROMS)
                local normalized_path = rom_path:gsub("^/mnt/union/ROMS", "/mnt/mmc/ROMS")
                
                Logger.info(string.format("Processing history file %d/%d: %s -> %s", 
                    file_count, #file_list, display_name or "Unknown", rom_path))
                
                -- Try to find matching game by exact path match
                local game = games_by_path[normalized_path] or games_by_path[rom_path]
                
                if game then
                    Logger.info(string.format("  -> Matched by exact path: %s", game.title))
                else
                    -- If no exact match, try matching by filename (in case paths differ slightly)
                    local history_filename = rom_path:match("([^/]+)$")
                    if history_filename then
                        Logger.info(string.format("  -> No exact path match, trying filename: %s", history_filename))
                        
                        -- First try exact filename match
                        for _, g in ipairs(GameLibrary.games) do
                            local game_filename = g.file_path:match("([^/]+)$")
                            if game_filename == history_filename then
                                game = g
                                Logger.info(string.format("  -> Matched by filename: %s -> %s", history_filename, game.title))
                                break
                            end
                        end
                        
                        -- If still no match, try normalized comparison (handle URL encoding, special chars)
                        if not game then
                            -- Normalize for comparison: lowercase, replace common URL encodings
                            local function normalize_for_match(s)
                                return s:lower()
                                    :gsub("%%20", " ")  -- URL-encoded space
                                    :gsub("%%27", "'")  -- URL-encoded apostrophe
                                    :gsub("%%28", "(")  -- URL-encoded (
                                    :gsub("%%29", ")")  -- URL-encoded )
                                    :gsub("%%2C", ",")  -- URL-encoded comma
                                    :gsub("%%26", "&")  -- URL-encoded ampersand
                            end
                            
                            local normalized_history = normalize_for_match(history_filename)
                            Logger.info(string.format("  -> Trying normalized match: %s", normalized_history))
                            
                            for _, g in ipairs(GameLibrary.games) do
                                local game_filename = g.file_path:match("([^/]+)$")
                                if game_filename and normalize_for_match(game_filename) == normalized_history then
                                    game = g
                                    Logger.info(string.format("  -> Matched by normalized filename: %s -> %s", history_filename, game.title))
                                    break
                                end
                            end
                        end
                    end
                    
                    if not game then
                        table.insert(unmatched_files, {
                            display_name = display_name or "Unknown",
                            rom_path = rom_path,
                            history_file = history_file
                        })
                        Logger.warn(string.format("  -> No match found for history entry: %s (path: %s)", 
                            display_name or "Unknown", rom_path))
                    end
                end
                
                if game then
                    -- Get file modification time as last_played timestamp
                    local file_stat = Shell.popen('stat -c %%Y %s 2>/dev/null', history_file)
                    if file_stat then
                        local mtime_str = file_stat:read("*a")
                        file_stat:close()
                        local mtime = tonumber(mtime_str:match("%d+"))
                        
                        if mtime then
                            -- Update last_played if this is more recent
                            if not game.last_played or mtime > game.last_played then
                                game.last_played = mtime
                                game.play_count = (game.play_count or 0) + 1
                                matched_count = matched_count + 1
                                Logger.info(string.format("Matched history: %s -> %s (played: %s)", 
                                    display_name or "Unknown", game.title, os.date("%Y-%m-%d %H:%M", mtime)))
                            else
                                Logger.info(string.format("History file older than existing last_played: %s -> %s (existing: %s, history: %s)", 
                                    display_name or "Unknown", game.title, 
                                    os.date("%Y-%m-%d %H:%M", game.last_played),
                                    os.date("%Y-%m-%d %H:%M", mtime)))
                            end
                        else
                            -- Fallback: use current time if stat fails
                            game.last_played = os.time()
                            game.play_count = (game.play_count or 0) + 1
                            matched_count = matched_count + 1
                        end
                    else
                        -- Fallback: use current time if stat command fails
                        game.last_played = os.time()
                        game.play_count = (game.play_count or 0) + 1
                        matched_count = matched_count + 1
                    end
                else
                    Logger.info("History file not matched to library:", rom_path)
                end
            else
                Logger.warn(string.format("Empty or invalid ROM path in history file: %s", history_file))
            end
    end
    
    Logger.info(string.format("Loaded muOS history: %d files, %d matched to library", file_count, matched_count))
    
    -- Log unmatched files for debugging
    if #unmatched_files > 0 then
        Logger.error(string.format("=== UNMATCHED HISTORY FILES (%d) ===", #unmatched_files))
        for _, unmatched in ipairs(unmatched_files) do
            Logger.error(string.format("  - %s (path: %s)", unmatched.display_name, unmatched.rom_path))
        end
        Logger.error("=== END UNMATCHED FILES ===")
    else
        Logger.info("All history files matched successfully")
    end
    
    return matched_count
end

-- Get recently played games
function GameLibrary.get_recent(limit)
    limit = limit or 20

    local results = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.last_played then
            table.insert(results, game)
        end
    end

    -- Sort by last played (most recent first)
    table.sort(results, Game.compare_by_recent)

    -- Return top N
    local limited = {}
    for i = 1, math.min(limit, #results) do
        table.insert(limited, results[i])
    end

    return limited
end

-- Refresh library (re-scan)
function GameLibrary.refresh()
    Logger.info("Refreshing game library...")
    GameLibrary.is_loaded = false
    return GameLibrary.load()
end

-- Toggle favorite status for a game
-- Returns: success (bool), updated game (Game or nil)
function GameLibrary.toggle_favorite(game_id)
    for _, game in ipairs(GameLibrary.games) do
        if game.id == game_id then
            game.favorite = not game.favorite
            Logger.info("Game favorite toggled:", game.title, "=>", game.favorite)

            -- Save favorites to persistence
            GameLibrary.save_favorites()

            return true, game
        end
    end
    Logger.warn("Game not found:", game_id)
    return false, nil
end

-- Remove a game from the library (after deletion)
function GameLibrary.remove_game(game_id)
    local removed = false
    for i, game in ipairs(GameLibrary.games) do
        if game.id == game_id then
            table.remove(GameLibrary.games, i)
            removed = true
            Logger.info("Removed game from library:", game.title)
            break
        end
    end
    return removed
end

-- Get all favorite games
function GameLibrary.get_favorites()
    local favorites = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.favorite then
            table.insert(favorites, game)
        end
    end
    return favorites
end

-- Save favorites to disk
function GameLibrary.save_favorites()
    local Persistence = require("src.services.persistence")
    local favorites_file = Paths.config_dir .. "favorites.json"

    -- Create list of favorite game IDs
    local favorite_ids = {}
    for _, game in ipairs(GameLibrary.games) do
        if game.favorite then
            table.insert(favorite_ids, game.id)
        end
    end

    -- Save to disk
    local success, err = Persistence.save(favorites_file, favorite_ids)
    if success then
        Logger.info("Saved", #favorite_ids, "favorites to disk")
    else
        Logger.error("Failed to save favorites:", err)
    end

    return success
end

-- Load favorites from disk
function GameLibrary.load_favorites()
    local Persistence = require("src.services.persistence")
    local favorites_file = Paths.config_dir .. "favorites.json"

    -- Load favorite IDs from disk
    local favorite_ids, err = Persistence.load(favorites_file)
    if err then
        Logger.info("No favorites file found (first run)")
        return true
    end

    if not favorite_ids then
        return true
    end

    -- Create lookup table for O(1) checking
    local favorite_lookup = {}
    for _, id in ipairs(favorite_ids) do
        favorite_lookup[id] = true
    end

    -- Apply favorite status to games
    local count = 0
    for _, game in ipairs(GameLibrary.games) do
        if favorite_lookup[game.id] then
            game.favorite = true
            count = count + 1
        end
    end

    Logger.info("Loaded", count, "favorites from disk")
    return true
end

return GameLibrary
