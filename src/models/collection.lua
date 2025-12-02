-- Collection model for dynamic game collections
-- Constitution: II. Resource Efficiency (lightweight data structures)

local Logger = require("src.lib.logger")

local Collection = {}
Collection.__index = Collection

-- Create a new Collection
-- @param data table: Collection attributes (id, name, filters, filter_mode, created_at, is_system, icon, sort_order)
-- @return Collection|nil, error
function Collection.new(data)
    local self = setmetatable({}, Collection)

    -- Validate required fields
    if not data or type(data) ~= "table" then
        return nil, "Collection data must be a table"
    end

    if not data.name or type(data.name) ~= "string" or data.name == "" then
        return nil, "Collection name is required and must be a non-empty string"
    end

    -- Validate name length (1-50 characters)
    if #data.name < 1 or #data.name > 50 then
        return nil, "Collection name must be 1-50 characters (got " .. #data.name .. ")"
    end

    -- Set attributes with defaults
    self.id = data.id or Collection.generate_id()
    self.name = data.name
    self.filters = data.filters or {}
    self.filter_mode = data.filter_mode or "AND"
    self.created_at = data.created_at or os.time()
    self.is_system = data.is_system or false
    self.icon = data.icon or nil
    self.sort_order = data.sort_order or "title_asc"

    -- Validate filter_mode
    if self.filter_mode ~= "AND" and self.filter_mode ~= "OR" then
        return nil, "filter_mode must be 'AND' or 'OR' (got '" .. tostring(self.filter_mode) .. "')"
    end

    -- Validate sort_order
    local valid_sorts = {
        title_asc = true,
        title_desc = true,
        year_asc = true,
        year_desc = true,
        recent = true
    }
    if not valid_sorts[self.sort_order] then
        return nil, "Invalid sort_order: " .. tostring(self.sort_order)
    end

    -- Validate filters is array
    if type(self.filters) ~= "table" then
        return nil, "filters must be a table/array"
    end

    Logger.debug("Created collection:", self.name, "(ID: " .. self.id .. ")")
    return self
end

-- Generate unique ID (simple UUID v4-like)
function Collection.generate_id()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local id = string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
    return id
end

-- Serialize to table for JSON persistence
function Collection:to_table()
    return {
        id = self.id,
        name = self.name,
        filters = self.filters,
        filter_mode = self.filter_mode,
        created_at = self.created_at,
        is_system = self.is_system,
        icon = self.icon,
        sort_order = self.sort_order
    }
end

-- Check if collection can be deleted (not system collection)
function Collection:can_delete()
    return not self.is_system
end

-- Check if collection can be renamed (not system collection)
function Collection:can_rename()
    return not self.is_system
end

-- Update collection name
function Collection:set_name(new_name)
    if not self:can_rename() then
        return false, "Cannot rename system collection"
    end

    if not new_name or #new_name < 1 or #new_name > 50 then
        return false, "Name must be 1-50 characters"
    end

    self.name = new_name
    return true
end

-- Add filter to collection
function Collection:add_filter(filter)
    if type(filter) ~= "table" then
        return false, "Filter must be a table"
    end

    table.insert(self.filters, filter)
    Logger.debug("Added filter to collection", self.name)
    return true
end

-- Remove filter by index
function Collection:remove_filter(index)
    if index < 1 or index > #self.filters then
        return false, "Invalid filter index"
    end

    table.remove(self.filters, index)
    Logger.debug("Removed filter from collection", self.name)
    return true
end

-- Clear all filters
function Collection:clear_filters()
    self.filters = {}
    Logger.debug("Cleared all filters from collection", self.name)
    return true
end

-- Comparison methods for sorting
function Collection:compare_by_name(other)
    return self.name:lower() < other.name:lower()
end

function Collection:compare_by_created_at(other)
    return self.created_at < other.created_at
end

return Collection
