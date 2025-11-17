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
