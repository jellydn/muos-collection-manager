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

-- Scan a single directory for ROMs
local function scan_directory(dir_path, system)
    local games = {}

    if not Paths.dir_exists(dir_path) then
        Logger.warn("Directory does not exist:", dir_path)
        return games
    end

    Logger.debug("Scanning directory:", dir_path)

    -- Use popen to list files (POSIX systems)
    local handle = io.popen('ls -1 "' .. dir_path .. '" 2>/dev/null')
    if not handle then
        Logger.error("Failed to open directory:", dir_path)
        return games
    end

    local count = 0
    for filename in handle:lines() do
        -- Check if it's a valid ROM file
        if Paths.is_rom_file(filename, system) then
            local file_path = dir_path .. filename

            -- Parse metadata from filename
            local metadata = parse_filename(filename, system)

            -- Create game object
            local game = Game.new({
                id = Game.generate_id(file_path),
                title = metadata.title,
                file_path = file_path,
                system = system:lower(),
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
    Logger.info("Found", count, "games in", system)

    return games
end

-- Load all games from ROM directories
function GameLibrary.load()
    Logger.info("Loading game library...")

    local start_time = love.timer.getTime()
    GameLibrary.games = {}

    -- Scan each ROM directory
    for system, extensions in pairs(Paths.rom_extensions) do
        local rom_dir = Paths.roms_root .. "/" .. system .. "/"
        local games_found = scan_directory(rom_dir, system)

        -- Add to main library
        for _, game in ipairs(games_found) do
            table.insert(GameLibrary.games, game)
        end
    end

    -- Sort by title
    table.sort(GameLibrary.games, Game.compare_by_title)

    local elapsed = (love.timer.getTime() - start_time) * 1000
    Logger.info(string.format("Loaded %d games in %.2fms", #GameLibrary.games, elapsed))

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
