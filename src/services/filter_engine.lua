-- FilterEngine service for multi-criteria game filtering
-- Constitution: I. Performance-First (optimized filtering with early exit)

local Logger = require("src.lib.logger")
local SearchFilter = require("src.models.search_filter")

local FilterEngine = {}

-- Apply multiple filters to a game list
-- @param games Game[]: Array of game objects
-- @param filters SearchFilter[]: Array of filter objects
-- @param mode string: "AND" or "OR" (default "AND")
-- @return Game[]: Filtered results
function FilterEngine.apply_filters(games, filters, mode)
    mode = mode or "AND"

    if not filters or #filters == 0 then
        return games
    end

    if mode ~= "AND" and mode ~= "OR" then
        Logger.error("Invalid filter mode:", mode)
        return games
    end

    local start_time = love.timer.getTime()
    local results = {}

    if mode == "AND" then
        -- AND logic: Game must match ALL filters
        for _, game in ipairs(games) do
            local matches_all = true

            for _, filter in ipairs(filters) do
                if not filter:matches(game) then
                    matches_all = false
                    break  -- Early exit on first non-match
                end
            end

            if matches_all then
                table.insert(results, game)
            end
        end

    else
        -- OR logic: Game must match AT LEAST ONE filter
        for _, game in ipairs(games) do
            local matches_any = false

            for _, filter in ipairs(filters) do
                if filter:matches(game) then
                    matches_any = true
                    break  -- Early exit on first match
                end
            end

            if matches_any then
                table.insert(results, game)
            end
        end
    end

    local elapsed = (love.timer.getTime() - start_time) * 1000
    Logger.debug(string.format(
        "FilterEngine: %d filters (%s mode) on %d games → %d results in %.2fms",
        #filters,
        mode,
        #games,
        #results,
        elapsed
    ))

    return results
end

-- Apply filters by type (genre, year, players, favorite)
-- @param games Game[]: Array of game objects
-- @param filter_type string: "genre", "year", "players", "favorite"
-- @param operator string: "equals", "range", "gte", "lte"
-- @param value any: Filter value
-- @return Game[]: Filtered results
function FilterEngine.filter_by_type(games, filter_type, operator, value)
    local filter, err = SearchFilter.new({
        filter_type = filter_type,
        operator = operator,
        value = value
    })

    if not filter then
        Logger.error("Failed to create filter:", err)
        return games
    end

    return FilterEngine.apply_filters(games, {filter}, "AND")
end

-- Filter by genre (equals operator)
-- @param games Game[]: Array of game objects
-- @param genre string: Genre name
-- @return Game[]: Games matching genre
function FilterEngine.filter_by_genre(games, genre)
    return FilterEngine.filter_by_type(games, "genre", "equals", genre)
end

-- Filter by year (equals, range, gte, lte)
-- @param games Game[]: Array of game objects
-- @param operator string: "equals", "range", "gte", "lte"
-- @param value number|table: Year value or range [min, max]
-- @return Game[]: Games matching year criteria
function FilterEngine.filter_by_year(games, operator, value)
    return FilterEngine.filter_by_type(games, "year", operator, value)
end

-- Filter by player count (equals, gte, lte)
-- @param games Game[]: Array of game objects
-- @param operator string: "equals", "gte", "lte"
-- @param value number: Player count
-- @return Game[]: Games matching player count criteria
function FilterEngine.filter_by_players(games, operator, value)
    return FilterEngine.filter_by_type(games, "players", operator, value)
end

-- Filter by favorite flag (equals operator)
-- @param games Game[]: Array of game objects
-- @param is_favorite boolean: Favorite status
-- @return Game[]: Favorite or non-favorite games
function FilterEngine.filter_by_favorite(games, is_favorite)
    return FilterEngine.filter_by_type(games, "favorite", "equals", is_favorite)
end

-- Get unique genres from game list
-- @param games Game[]: Array of game objects
-- @return string[]: Sorted unique genres
function FilterEngine.get_genres(games)
    local genres_set = {}

    for _, game in ipairs(games) do
        for _, genre in ipairs(game.genre or {}) do
            genres_set[genre] = true
        end
    end

    local genres = {}
    for genre, _ in pairs(genres_set) do
        table.insert(genres, genre)
    end

    table.sort(genres)
    return genres
end

-- Get year range from game list
-- @param games Game[]: Array of game objects
-- @return number, number: min_year, max_year (or nil if no years)
function FilterEngine.get_year_range(games)
    local min_year = nil
    local max_year = nil

    for _, game in ipairs(games) do
        if game.year then
            if not min_year or game.year < min_year then
                min_year = game.year
            end
            if not max_year or game.year > max_year then
                max_year = game.year
            end
        end
    end

    return min_year, max_year
end

-- Get max player count from game list
-- @param games Game[]: Array of game objects
-- @return number: Maximum player count (default 1)
function FilterEngine.get_max_players(games)
    local max_players = 1

    for _, game in ipairs(games) do
        if game.player_count and game.player_count > max_players then
            max_players = game.player_count
        end
    end

    return max_players
end

return FilterEngine
