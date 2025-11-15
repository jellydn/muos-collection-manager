-- SearchFilter model for dynamic collection filtering
-- Constitution: II. Resource Efficiency (lightweight filter structures)

local Logger = require("src.lib.logger")

local SearchFilter = {}
SearchFilter.__index = SearchFilter

-- Valid filter configurations per data-model.md
SearchFilter.VALID_TYPES = {
    name = true,
    genre = true,
    year = true,
    players = true,
    favorite = true
}

SearchFilter.VALID_OPERATORS = {
    contains = true,
    equals = true,
    range = true,
    gte = true,
    lte = true
}

-- Valid operator-type combinations
SearchFilter.TYPE_OPERATORS = {
    name = { contains = true },
    genre = { equals = true },
    year = { equals = true, range = true, gte = true, lte = true },
    players = { equals = true, gte = true, lte = true },
    favorite = { equals = true }
}

-- Create a new SearchFilter
-- @param data table: Filter attributes (filter_type, operator, value)
-- @return SearchFilter|nil, error
function SearchFilter.new(data)
    local self = setmetatable({}, SearchFilter)

    -- Validate required fields
    if not data or type(data) ~= "table" then
        return nil, "SearchFilter data must be a table"
    end

    if not data.filter_type or type(data.filter_type) ~= "string" then
        return nil, "filter_type is required and must be a string"
    end

    if not data.operator or type(data.operator) ~= "string" then
        return nil, "operator is required and must be a string"
    end

    if data.value == nil then
        return nil, "value is required"
    end

    -- Validate filter_type
    if not SearchFilter.VALID_TYPES[data.filter_type] then
        return nil, "Invalid filter_type: " .. data.filter_type
    end

    -- Validate operator
    if not SearchFilter.VALID_OPERATORS[data.operator] then
        return nil, "Invalid operator: " .. data.operator
    end

    -- Validate operator is valid for this filter_type
    local valid_ops = SearchFilter.TYPE_OPERATORS[data.filter_type]
    if not valid_ops or not valid_ops[data.operator] then
        return nil, string.format(
            "Operator '%s' is not valid for filter_type '%s'",
            data.operator,
            data.filter_type
        )
    end

    -- Set attributes
    self.filter_type = data.filter_type
    self.operator = data.operator
    self.value = data.value

    -- Validate value type based on operator and filter_type
    local ok, err = self:validate_value()
    if not ok then
        return nil, err
    end

    Logger.debug("Created SearchFilter:", self.filter_type, self.operator, self.value)
    return self
end

-- Validate value type and format
function SearchFilter:validate_value()
    if self.operator == "contains" then
        -- String type
        if type(self.value) ~= "string" then
            return false, "Value for 'contains' operator must be a string"
        end

    elseif self.operator == "equals" then
        -- Type depends on filter_type
        if self.filter_type == "name" or self.filter_type == "genre" then
            if type(self.value) ~= "string" then
                return false, "Value for " .. self.filter_type .. " equals must be a string"
            end
        elseif self.filter_type == "year" or self.filter_type == "players" then
            if type(self.value) ~= "number" then
                return false, "Value for " .. self.filter_type .. " equals must be a number"
            end
        elseif self.filter_type == "favorite" then
            if type(self.value) ~= "boolean" then
                return false, "Value for favorite equals must be a boolean"
            end
        end

    elseif self.operator == "range" then
        -- Table with two numbers [min, max]
        if type(self.value) ~= "table" then
            return false, "Value for 'range' operator must be a table"
        end
        if #self.value ~= 2 then
            return false, "Value for 'range' operator must be array of 2 numbers [min, max]"
        end
        if type(self.value[1]) ~= "number" or type(self.value[2]) ~= "number" then
            return false, "Range values must be numbers"
        end
        if self.value[1] > self.value[2] then
            return false, "Range min must be <= max"
        end

    elseif self.operator == "gte" or self.operator == "lte" then
        -- Number
        if type(self.value) ~= "number" then
            return false, "Value for " .. self.operator .. " operator must be a number"
        end
    end

    return true
end

-- Serialize to table for JSON persistence
function SearchFilter:to_table()
    return {
        filter_type = self.filter_type,
        operator = self.operator,
        value = self.value
    }
end

-- Check if a game matches this filter
-- @param game Game: Game object to test
-- @return boolean
function SearchFilter:matches(game)
    if self.filter_type == "name" then
        if self.operator == "contains" then
            local title_lower = game.title:lower()
            local value_lower = self.value:lower()
            return title_lower:find(value_lower, 1, true) ~= nil
        end

    elseif self.filter_type == "genre" then
        if self.operator == "equals" then
            for _, genre in ipairs(game.genre or {}) do
                if genre:lower() == self.value:lower() then
                    return true
                end
            end
            return false
        end

    elseif self.filter_type == "year" then
        if not game.year then
            return false
        end

        if self.operator == "equals" then
            return game.year == self.value
        elseif self.operator == "range" then
            return game.year >= self.value[1] and game.year <= self.value[2]
        elseif self.operator == "gte" then
            return game.year >= self.value
        elseif self.operator == "lte" then
            return game.year <= self.value
        end

    elseif self.filter_type == "players" then
        if self.operator == "equals" then
            return game.player_count == self.value
        elseif self.operator == "gte" then
            return game.player_count >= self.value
        elseif self.operator == "lte" then
            return game.player_count <= self.value
        end

    elseif self.filter_type == "favorite" then
        if self.operator == "equals" then
            return game.favorite == self.value
        end
    end

    return false
end

-- Get human-readable description
function SearchFilter:to_string()
    local desc = self.filter_type .. " "

    if self.operator == "contains" then
        desc = desc .. "contains '" .. self.value .. "'"
    elseif self.operator == "equals" then
        desc = desc .. "= " .. tostring(self.value)
    elseif self.operator == "range" then
        desc = desc .. "between " .. self.value[1] .. "-" .. self.value[2]
    elseif self.operator == "gte" then
        desc = desc .. ">= " .. self.value
    elseif self.operator == "lte" then
        desc = desc .. "<= " .. self.value
    end

    return desc
end

return SearchFilter
