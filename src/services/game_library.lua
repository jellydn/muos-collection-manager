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
local function scan_directory_recursive(dir_path, games, depth)
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
    local find_cmd = string.format(
        'find "%s" -type f -not -path "*/\\.*" 2>&1',
        dir_path
    )

    Logger.info("Executing find command...")
    local handle = io.popen(find_cmd)
    if not handle then
        Logger.error("Failed to execute find command for:", dir_path)
        return games
    end

    Logger.info("Reading file list...")
    local count = 0
    local total_files = 0
    for file_path in handle:lines() do
        total_files = total_files + 1

        -- Progress indicator every 100 files
        if total_files % 100 == 0 then
            Logger.info(string.format("Scanned %d files, found %d ROMs...", total_files, count))
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

    handle:close()

    Logger.info(string.format("Scan complete: %d total files, %d valid ROMs found", total_files, count))

    return games
end

-- Load all games from ROM directories (recursive scan)
function GameLibrary.load()
    Logger.info("Loading game library...")

    local start_time = love.timer.getTime()
    GameLibrary.games = {}

    -- Check if ROM root exists
    Logger.info("Checking ROM root directory:", Paths.roms_root)
    local dir_exists = Paths.dir_exists(Paths.roms_root)
    Logger.info("Directory exists check result:", dir_exists)

    -- Recursively scan the entire ROMS root directory
    if dir_exists then
        Logger.info("Starting recursive scan of:", Paths.roms_root)
        GameLibrary.games = scan_directory_recursive(Paths.roms_root, {}, 0)
        Logger.info("Recursive scan returned", #GameLibrary.games, "games")
    else
        Logger.error("ROM root directory does not exist:", Paths.roms_root)
        -- Try to list what's in /mnt/mmc to help debug
        Logger.info("Attempting to list /mnt/mmc contents...")
        local handle = io.popen("ls -la /mnt/mmc 2>&1")
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

return GameLibrary
