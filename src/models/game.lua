-- Game model
-- Constitution: II. Resource Efficiency (compact data structure)

local Game = {}
Game.__index = Game

-- Create a new Game instance
function Game.new(data)
    local self = setmetatable({}, Game)
    
    -- Required fields
    self.id = data.id or ""
    self.title = data.title or ""
    self.file_path = data.file_path or ""
    self.system = data.system or "unknown"
    
    -- Optional fields with defaults
    self.genre = data.genre or {"Unknown"}
    self.year = data.year  -- Can be nil
    self.player_count = data.player_count or 1
    self.favorite = data.favorite or false
    self.play_count = data.play_count or 0
    self.last_played = data.last_played  -- Can be nil
    
    return self
end

-- Validate game data
function Game:validate()
    local errors = {}
    
    if not self.title or self.title == "" then
        table.insert(errors, "Title cannot be empty")
    end
    
    if not self.file_path or self.file_path == "" then
        table.insert(errors, "File path cannot be empty")
    end
    
    if self.year and (self.year < 1970 or self.year > 2100) then
        table.insert(errors, "Year must be between 1970 and 2100")
    end
    
    if self.player_count < 1 or self.player_count > 8 then
        table.insert(errors, "Player count must be between 1 and 8")
    end
    
    return #errors == 0, errors
end

-- Convert to JSON-serializable table
function Game:to_table()
    return {
        id = self.id,
        title = self.title,
        file_path = self.file_path,
        system = self.system,
        genre = self.genre,
        year = self.year,
        player_count = self.player_count,
        favorite = self.favorite,
        play_count = self.play_count,
        last_played = self.last_played
    }
end

-- Create from JSON table
function Game.from_table(data)
    return Game.new(data)
end

-- Generate unique ID from file path
function Game.generate_id(file_path)
    -- Simple hash: use file path as-is (unique per file)
    -- In production, could use MD5 or SHA1
    return file_path:gsub("[^%w]", "_")
end

-- Compare for sorting
function Game.compare_by_title(a, b)
    return a.title:lower() < b.title:lower()
end

function Game.compare_by_year(a, b)
    if a.year == nil and b.year == nil then return false end
    if a.year == nil then return false end
    if b.year == nil then return true end
    return a.year < b.year
end

function Game.compare_by_recent(a, b)
    if a.last_played == nil and b.last_played == nil then return false end
    if a.last_played == nil then return false end
    if b.last_played == nil then return true end
    return a.last_played > b.last_played
end

return Game
