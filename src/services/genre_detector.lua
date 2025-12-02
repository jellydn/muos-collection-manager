-- Genre Detection Service
-- Detects game genres based on title keywords and platform patterns

local Logger = require("src.lib.logger")

local GenreDetector = {}

-- Genre keyword patterns (case-insensitive matching)
local GENRE_PATTERNS = {
    -- Action genres
    {genre = "Action", keywords = {"action", "vs", "fighter", "fight", "combat", "brawl", "battle", "mortal kombat", "street fighter"}},
    {genre = "Platformer", keywords = {"mario", "sonic", "platformer", "jump", "crash bandicoot", "donkey kong", "rayman", "castlevania"}},
    {genre = "Beat 'em Up", keywords = {"beat em up", "brawler", "double dragon", "streets of rage", "final fight", "golden axe"}},
    {genre = "Shooter", keywords = {"shooter", "shoot", "contra", "r-type", "gradius", "1942", "galaga", "gunstar"}},

    -- RPG genres
    {genre = "RPG", keywords = {"rpg", "final fantasy", "dragon quest", "chrono", "pokemon", "earthbound", "phantasy star"}},
    {genre = "Action RPG", keywords = {"zelda", "secret of mana", "ys", "terranigma", "soul blazer"}},

    -- Racing/Sports
    {genre = "Racing", keywords = {"racing", "race", "gran turismo", "need for speed", "mario kart", "f-zero", "ridge racer", "wipeout"}},
    {genre = "Sports", keywords = {"sports", "soccer", "football", "baseball", "basketball", "tennis", "golf", "hockey", "nba", "fifa", "madden"}},

    -- Strategy
    {genre = "Strategy", keywords = {"strategy", "tactics", "advance wars", "fire emblem", "civilization", "age of empires"}},
    {genre = "Puzzle", keywords = {"puzzle", "tetris", "dr mario", "puyo", "columns", "bejeweled", "lumines"}},

    -- Adventure
    {genre = "Adventure", keywords = {"adventure", "quest", "monkey island", "kings quest", "myst", "ace attorney"}},
    {genre = "Visual Novel", keywords = {"visual novel", "dating sim", "phoenix wright"}},

    -- Simulation
    {genre = "Simulation", keywords = {"sim", "tycoon", "manager", "harvest moon", "animal crossing", "the sims"}},

    -- Rhythm
    {genre = "Rhythm", keywords = {"rhythm", "music", "guitar hero", "ddr", "dance dance", "beatmania", "taiko"}},

    -- Horror
    {genre = "Horror", keywords = {"horror", "resident evil", "silent hill", "fatal frame", "clock tower"}},

    -- Arcade
    {genre = "Arcade", keywords = {"pac-man", "pacman", "donkey kong", "galaga", "dig dug", "frogger", "centipede"}},
}

-- Platform-specific genre hints
local PLATFORM_GENRE_HINTS = {
    -- Arcade systems tend to have more arcade-style games
    arcade = {
        default_genres = {"Arcade", "Action"},
        boost_patterns = {
            {genre = "Fighting", keywords = {"vs", "fighter", "fight"}},
            {genre = "Shooter", keywords = {"shoot", "gun"}},
        }
    },

    -- Nintendo platforms known for platformers
    nes = {
        boost_patterns = {
            {genre = "Platformer", keywords = {"bros", "adventure", "quest"}},
        }
    },
    snes = {
        boost_patterns = {
            {genre = "Platformer", keywords = {"bros", "world", "land"}},
            {genre = "RPG", keywords = {"quest", "fantasy", "story"}},
        }
    },

    -- PlayStation known for RPGs, racing, and 3D action
    ps1 = {
        boost_patterns = {
            {genre = "RPG", keywords = {"fantasy", "legend", "quest"}},
            {genre = "Racing", keywords = {"gt", "rally", "race"}},
        }
    },

    -- Sega platforms
    genesis = {
        boost_patterns = {
            {genre = "Action", keywords = {"sonic", "streets", "golden"}},
        }
    },
}

-- Detect genres from game title
-- Returns array of genre strings (can be multiple)
function GenreDetector.detect(title, system)
    if not title or title == "" then
        return {"Unknown"}
    end

    local detected_genres = {}
    local title_lower = title:lower()

    -- Try to match against genre patterns
    for _, pattern in ipairs(GENRE_PATTERNS) do
        for _, keyword in ipairs(pattern.keywords) do
            if title_lower:find(keyword, 1, true) then  -- Plain text search
                table.insert(detected_genres, pattern.genre)
                break  -- One match per pattern is enough
            end
        end
    end

    -- Apply platform-specific hints
    if system and PLATFORM_GENRE_HINTS[system] then
        local hints = PLATFORM_GENRE_HINTS[system]

        -- Check boost patterns (stronger signal for certain genres on certain platforms)
        if hints.boost_patterns then
            for _, pattern in ipairs(hints.boost_patterns) do
                for _, keyword in ipairs(pattern.keywords) do
                    if title_lower:find(keyword, 1, true) then
                        -- Add if not already present
                        local already_added = false
                        for _, genre in ipairs(detected_genres) do
                            if genre == pattern.genre then
                                already_added = true
                                break
                            end
                        end
                        if not already_added then
                            table.insert(detected_genres, pattern.genre)
                        end
                        break
                    end
                end
            end
        end

        -- Use default genres if nothing detected
        if #detected_genres == 0 and hints.default_genres then
            for _, genre in ipairs(hints.default_genres) do
                table.insert(detected_genres, genre)
            end
        end
    end

    -- Remove duplicates
    local unique_genres = {}
    local seen = {}
    for _, genre in ipairs(detected_genres) do
        if not seen[genre] then
            table.insert(unique_genres, genre)
            seen[genre] = true
        end
    end

    -- Return Unknown if nothing detected
    if #unique_genres == 0 then
        return {"Unknown"}
    end

    return unique_genres
end

-- Get all unique genres from the patterns
function GenreDetector.get_all_genres()
    local all_genres = {}
    local seen = {}

    for _, pattern in ipairs(GENRE_PATTERNS) do
        if not seen[pattern.genre] then
            table.insert(all_genres, pattern.genre)
            seen[pattern.genre] = true
        end
    end

    -- Add Unknown
    table.insert(all_genres, "Unknown")

    -- Sort alphabetically
    table.sort(all_genres)

    return all_genres
end

return GenreDetector
