-- SearchIndex model
-- Constitution: I. Performance-First (optimized in-memory indexing)

local Logger = require("src.lib.logger")

local SearchIndex = {}
SearchIndex.__index = SearchIndex

-- Create a new SearchIndex
function SearchIndex.new()
    local self = setmetatable({}, SearchIndex)
    
    -- Indexes for fast lookup
    self.title_index = {}     -- lowercase title -> games array
    self.genre_index = {}     -- genre -> games array
    self.year_index = {}      -- year -> games array
    self.players_index = {}   -- player_count -> games array
    self.all_games = {}       -- Full game list reference
    
    return self
end

-- Build indexes from game list
function SearchIndex:build(games)
    Logger.debug("Building search index for", #games, "games")
    
    local start_time = love.timer.getTime()
    
    -- Reset indexes
    self.title_index = {}
    self.genre_index = {}
    self.year_index = {}
    self.players_index = {}
    self.all_games = games
    
    -- Build title index (lowercase for case-insensitive search)
    for _, game in ipairs(games) do
        local title_lower = game.title:lower()
        
        -- Index full title
        if not self.title_index[title_lower] then
            self.title_index[title_lower] = {}
        end
        table.insert(self.title_index[title_lower], game)
        
        -- Index by genre
        for _, genre in ipairs(game.genre) do
            local genre_key = genre:lower()
            if not self.genre_index[genre_key] then
                self.genre_index[genre_key] = {}
            end
            table.insert(self.genre_index[genre_key], game)
        end
        
        -- Index by year
        if game.year then
            if not self.year_index[game.year] then
                self.year_index[game.year] = {}
            end
            table.insert(self.year_index[game.year], game)
        end
        
        -- Index by player count
        if not self.players_index[game.player_count] then
            self.players_index[game.player_count] = {}
        end
        table.insert(self.players_index[game.player_count], game)
    end
    
    local elapsed = (love.timer.getTime() - start_time) * 1000
    Logger.info(string.format("Search index built in %.2fms", elapsed))
    
    return self
end

-- Refresh index (rebuild from all_games)
function SearchIndex:refresh()
    return self:build(self.all_games)
end

-- Get memory usage estimate
function SearchIndex:get_memory_usage()
    local count = 0
    
    for _ in pairs(self.title_index) do count = count + 1 end
    for _ in pairs(self.genre_index) do count = count + 1 end
    for _ in pairs(self.year_index) do count = count + 1 end
    for _ in pairs(self.players_index) do count = count + 1 end
    
    -- Rough estimate: ~100 bytes per index entry
    local bytes = count * 100 + #self.all_games * 500
    return bytes
end

return SearchIndex
