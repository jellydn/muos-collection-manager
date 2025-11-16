-- SearchEngine service
-- Constitution: I. Performance-First (debounced case-insensitive search)

local Logger = require("src.lib.logger")
local Profiler = require("src.lib.profiler")
local SearchIndex = require("src.models.search_index")

local SearchEngine = {}

-- State
SearchEngine.index = nil
SearchEngine.debounce_timer = 0
SearchEngine.debounce_delay = 0.15  -- 150ms per research.md
SearchEngine.pending_query = ""
SearchEngine.last_query = ""
SearchEngine.last_results = {}

-- Initialize with game library
function SearchEngine.init(games)
    Logger.info("Initializing search engine with", #games, "games")

    SearchEngine.index = SearchIndex.new()
    SearchEngine.index:build(games)

    local memory = SearchEngine.index:get_memory_usage()
    Logger.info(string.format("Search index memory: %.2f MB", memory / 1024 / 1024))
end

-- Perform case-insensitive partial match search
function SearchEngine.search(query)
    Profiler.start_timer("search_query")
    
    if not SearchEngine.index then
        Logger.error("SearchEngine not initialized")
        return {}
    end

    if not query or query == "" then
        Profiler.end_timer("search_query", 100)
        return SearchEngine.index.all_games
    end

    local start_time = love.timer.getTime()
    local query_lower = query:lower()
    local results = {}
    local seen = {}  -- Prevent duplicates

    -- Search through all games (linear scan with early filtering)
    for _, game in ipairs(SearchEngine.index.all_games) do
        local title_lower = game.title:lower()

        -- Partial match using string.find (plain text, not pattern)
        if title_lower:find(query_lower, 1, true) then
            if not seen[game.id] then
                table.insert(results, game)
                seen[game.id] = true
            end
        end
    end

    local elapsed = (love.timer.getTime() - start_time) * 1000
    Logger.debug(string.format("Search '%s': %d results in %.2fms", query, #results, elapsed))

    -- Performance warning if search is slow
    if elapsed > 100 and #SearchEngine.index.all_games >= 1000 then
        Logger.warn(string.format("Search took %.2fms (>100ms threshold)", elapsed))
    end

    Profiler.end_timer("search_query", 100)  -- T074: Verify <100ms for 1K games
    return results
end

-- Query with debouncing (call this from UI update loop)
function SearchEngine.query(query, dt)
    local current_query = query or ""

    -- Reset timer if query changed
    if current_query ~= SearchEngine.last_query then
        SearchEngine.debounce_timer = 0
        SearchEngine.pending_query = current_query
        Logger.debug(string.format("Search query changed: '%s' -> '%s' (resetting debounce)",
            SearchEngine.last_query, current_query))
        SearchEngine.last_query = current_query  -- Update last_query immediately
    end

    -- Increment timer
    SearchEngine.debounce_timer = SearchEngine.debounce_timer + (dt or 0)

    -- Execute search after debounce delay
    if SearchEngine.debounce_timer >= SearchEngine.debounce_delay then
        Logger.debug(string.format("Executing search for: '%s'", SearchEngine.pending_query))
        SearchEngine.last_results = SearchEngine.search(SearchEngine.pending_query)
        -- Only log if query is not empty (avoid spam for "show all" queries)
        if SearchEngine.pending_query ~= "" then
            Logger.info(string.format("Search results: %d games for query '%s'",
                #SearchEngine.last_results, SearchEngine.pending_query))
        end
        -- Reset timer to prevent repeated execution until query changes
        SearchEngine.debounce_timer = SearchEngine.debounce_delay
        return SearchEngine.last_results
    end

    -- Return last results while debouncing
    Logger.debug(string.format("Debouncing... (%.3fs / %.3fs)",
        SearchEngine.debounce_timer, SearchEngine.debounce_delay))
    return SearchEngine.last_results
end

-- Get last search results (without triggering new search)
function SearchEngine.get_last_results()
    return SearchEngine.last_results
end

-- Check if currently debouncing
function SearchEngine.is_debouncing()
    return SearchEngine.debounce_timer < SearchEngine.debounce_delay
end

-- Reset debounce state
function SearchEngine.reset_debounce()
    SearchEngine.debounce_timer = 0
    SearchEngine.pending_query = ""
    SearchEngine.last_query = ""
end

-- Refresh index (when library changes)
function SearchEngine.refresh(games)
    Logger.info("Refreshing search index")
    SearchEngine.index:build(games)
end

return SearchEngine
