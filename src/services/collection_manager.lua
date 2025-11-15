-- CollectionManager service for CRUD operations on collections
-- Constitution: I. Performance-First (in-memory cache)

local Logger = require("src.lib.logger")
local Collection = require("src.models.collection")
local Persistence = require("src.services.persistence")
local Paths = require("src.config.paths")

local CollectionManager = {}

-- State
CollectionManager.collections = {}  -- Array of Collection objects
CollectionManager.collections_by_id = {}  -- Map of id → Collection for fast lookup
CollectionManager.collections_file = nil  -- Will be set during init

-- Initialize CollectionManager (loads from disk)
-- @param collections_file string: Path to collections.json (optional, defaults to muOS path)
-- @return boolean, error
function CollectionManager.init(collections_file)
    CollectionManager.collections_file = collections_file or (Paths.config_dir .. "collections.json")

    Logger.info("Initializing CollectionManager with file:", CollectionManager.collections_file)

    -- Load collections from disk
    local data, err = Persistence.load(CollectionManager.collections_file)

    if err then
        Logger.error("Failed to load collections:", err)
        -- Initialize with default collections
        CollectionManager.create_default_collections()
        return true  -- Not a fatal error
    end

    if not data then
        -- First run - create default collections
        Logger.info("No collections file found, creating defaults")
        CollectionManager.create_default_collections()
        return true
    end

    -- Parse collections from data
    CollectionManager.collections = {}
    CollectionManager.collections_by_id = {}

    for _, collection_data in ipairs(data) do
        local collection, parse_err = Collection.new(collection_data)
        if collection then
            table.insert(CollectionManager.collections, collection)
            CollectionManager.collections_by_id[collection.id] = collection
        else
            Logger.warn("Failed to parse collection:", parse_err)
        end
    end

    Logger.info("Loaded", #CollectionManager.collections, "collections")
    return true
end

-- Create default system collections
function CollectionManager.create_default_collections()
    Logger.info("Creating default system collections")

    -- All Games
    local all_games = Collection.new({
        id = "all-games-system",
        name = "All Games",
        filters = {},
        filter_mode = "AND",
        is_system = true,
        icon = "games",
        sort_order = "title_asc"
    })

    -- Favorites
    local favorites = Collection.new({
        id = "favorites-system",
        name = "Favorites",
        filters = {
            {filter_type = "favorite", operator = "equals", value = true}
        },
        filter_mode = "AND",
        is_system = true,
        icon = "star",
        sort_order = "title_asc"
    })

    -- Recently Played
    local recent = Collection.new({
        id = "recent-system",
        name = "Recently Played",
        filters = {},  -- Special handling in search engine
        filter_mode = "AND",
        is_system = true,
        icon = "clock",
        sort_order = "recent"
    })

    CollectionManager.collections = {all_games, favorites, recent}
    CollectionManager.collections_by_id = {
        [all_games.id] = all_games,
        [favorites.id] = favorites,
        [recent.id] = recent
    }

    -- Save to disk
    CollectionManager.save()
end

-- Save all collections to disk
-- @return boolean, error
function CollectionManager.save()
    -- Serialize collections to array of tables
    local data = {}
    for _, collection in ipairs(CollectionManager.collections) do
        table.insert(data, collection:to_table())
    end

    local ok, err = Persistence.save(CollectionManager.collections_file, data, "1.0")
    if not ok then
        Logger.error("Failed to save collections:", err)
        return false, err
    end

    return true
end

-- Create a new collection
-- @param name string: Collection name
-- @param filters table: Array of SearchFilter objects
-- @param filter_mode string: "AND" or "OR" (default "AND")
-- @return Collection|nil, error
function CollectionManager.create(name, filters, filter_mode)
    -- Check for duplicate names
    for _, collection in ipairs(CollectionManager.collections) do
        if collection.name:lower() == name:lower() then
            return nil, "Collection with name '" .. name .. "' already exists"
        end
    end

    -- Create collection
    local collection, err = Collection.new({
        name = name,
        filters = filters or {},
        filter_mode = filter_mode or "AND",
        is_system = false
    })

    if not collection then
        return nil, err
    end

    -- Add to in-memory store
    table.insert(CollectionManager.collections, collection)
    CollectionManager.collections_by_id[collection.id] = collection

    -- Save to disk
    local save_ok, save_err = CollectionManager.save()
    if not save_ok then
        -- Rollback in-memory changes
        table.remove(CollectionManager.collections)
        CollectionManager.collections_by_id[collection.id] = nil
        return nil, "Failed to save: " .. tostring(save_err)
    end

    Logger.info("Created collection:", collection.name)
    return collection
end

-- Delete a collection by ID
-- @param id string: Collection ID
-- @return boolean, error
function CollectionManager.delete(id)
    local collection = CollectionManager.collections_by_id[id]

    if not collection then
        return false, "Collection not found"
    end

    if not collection:can_delete() then
        return false, "Cannot delete system collection"
    end

    -- Remove from in-memory store
    for i, c in ipairs(CollectionManager.collections) do
        if c.id == id then
            table.remove(CollectionManager.collections, i)
            break
        end
    end
    CollectionManager.collections_by_id[id] = nil

    -- Save to disk
    local ok, err = CollectionManager.save()
    if not ok then
        Logger.error("Failed to save after delete:", err)
        return false, err
    end

    Logger.info("Deleted collection:", collection.name)
    return true
end

-- Get collection by ID
-- @param id string: Collection ID
-- @return Collection|nil
function CollectionManager.get(id)
    return CollectionManager.collections_by_id[id]
end

-- Get all collections
-- @return Collection[]
function CollectionManager.get_all()
    return CollectionManager.collections
end

-- Get collections sorted (system first, then by name)
-- @return Collection[]
function CollectionManager.get_sorted()
    local sorted = {}

    -- Copy collections
    for _, collection in ipairs(CollectionManager.collections) do
        table.insert(sorted, collection)
    end

    -- Sort: system collections first, then alphabetically by name
    table.sort(sorted, function(a, b)
        if a.is_system and not b.is_system then
            return true
        elseif not a.is_system and b.is_system then
            return false
        else
            return a:compare_by_name(b)
        end
    end)

    return sorted
end

-- Update collection (rename or modify filters)
-- @param id string: Collection ID
-- @param updates table: Fields to update (name, filters, filter_mode)
-- @return boolean, error
function CollectionManager.update(id, updates)
    local collection = CollectionManager.collections_by_id[id]

    if not collection then
        return false, "Collection not found"
    end

    -- Update name if provided
    if updates.name then
        local ok, err = collection:set_name(updates.name)
        if not ok then
            return false, err
        end
    end

    -- Update filters if provided
    if updates.filters then
        collection.filters = updates.filters
    end

    -- Update filter_mode if provided
    if updates.filter_mode then
        if updates.filter_mode ~= "AND" and updates.filter_mode ~= "OR" then
            return false, "Invalid filter_mode"
        end
        collection.filter_mode = updates.filter_mode
    end

    -- Save to disk
    local ok, err = CollectionManager.save()
    if not ok then
        return false, err
    end

    Logger.info("Updated collection:", collection.name)
    return true
end

return CollectionManager
