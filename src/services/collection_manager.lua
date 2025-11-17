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

-- Helper to count map size
function CollectionManager.count_map_size(map)
    local count = 0
    for _ in pairs(map) do
        count = count + 1
    end
    return count
end

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
            Logger.debug("Registered collection in map:", collection.name, "id:", collection.id)
        else
            Logger.warn("Failed to parse collection:", parse_err)
        end
    end

    Logger.info("Loaded", #CollectionManager.collections, "collections")
    Logger.debug("collections_by_id map size:", CollectionManager.count_map_size(CollectionManager.collections_by_id))

    -- Skip loading muOS collections - we manage our own collections
    -- CollectionManager.load_muos_collections()
    Logger.debug("Skipping muOS collection loading (not needed)")

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

    -- Favorites (user-managed, but system collection)
    local favorites = Collection.new({
        id = "favorites-system",
        name = "Favorites",
        filters = {},  -- Special handling in browse scene
        filter_mode = "AND",
        is_system = true,
        icon = "star",
        sort_order = "title_asc"
    })

    -- Recently Played
    local recent = Collection.new({
        id = "recent-system",
        name = "Recently Played",
        filters = {},  -- Special handling in browse scene
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
    Logger.debug("CollectionManager.delete called with id:", id)

    local keys = {}
    for k, _ in pairs(CollectionManager.collections_by_id or {}) do
        table.insert(keys, k)
    end
    Logger.debug("collections_by_id has", #keys, "keys")

    local collection = CollectionManager.collections_by_id[id]

    if not collection then
        Logger.debug("Collection lookup failed for id:", id)
        Logger.debug("Total collections in memory:", #CollectionManager.collections)
        for i, c in ipairs(CollectionManager.collections) do
            Logger.debug("  Collection", i, ":", c.name, "id:", c.id)
        end
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

-- Delete collection by ID (with safety check for system collections)
-- Returns: success (bool), error message (string or nil)
function CollectionManager.delete(collection_id)
    local collection = CollectionManager.collections_by_id[collection_id]
    
    if not collection then
        return false, "Collection not found"
    end
    
    -- Prevent deletion of system collections
    if collection.is_system then
        return false, "Cannot delete system collection: " .. collection.name
    end
    
    -- Remove from arrays
    for i, col in ipairs(CollectionManager.collections) do
        if col.id == collection_id then
            table.remove(CollectionManager.collections, i)
            break
        end
    end
    
    CollectionManager.collections_by_id[collection_id] = nil
    
    -- Save to disk
    local ok, err = CollectionManager.save()
    if not ok then
        return false, err
    end
    
    Logger.info("Deleted collection:", collection.name)
    return true
end

-- Check if collection is system collection (immutable)
function CollectionManager.is_system_collection(collection_id)
    local collection = CollectionManager.collections_by_id[collection_id]
    return collection and collection.is_system or false
end

-- Read muOS history to get recently played games
-- Returns array of game ROM paths sorted by most recent first
-- @return table: Array of {path, system, title, timestamp}
function CollectionManager.read_muos_history()
    Logger.info("read_muos_history: Starting...")
    local history_dir = "/mnt/mmc/MUOS/info/history"
    local history_entries = {}

    Logger.info("read_muos_history: Checking if directory exists...")
    -- Check if history directory exists
    local check_dir = io.popen(string.format('test -d "%s" && echo "exists"', history_dir))
    local exists = check_dir:read("*a"):match("exists")
    check_dir:close()
    Logger.info("read_muos_history: Directory exists:", exists and "yes" or "no")

    if not exists then
        Logger.warn("muOS history directory not found:", history_dir)
        return {}
    end

    Logger.info("read_muos_history: Listing .cfg files...")
    -- List all .cfg files in history directory, sorted by modification time (newest first)
    local ls_cmd = string.format('ls -1t "%s"/*.cfg 2>/dev/null', history_dir)
    local handle = io.popen(ls_cmd)
    if not handle then
        Logger.error("Failed to read history directory")
        return {}
    end
    Logger.info("read_muos_history: ls command completed, reading files...")

    local file_count = 0
    for cfg_file in handle:lines() do
        file_count = file_count + 1
        if file_count % 10 == 0 then
            Logger.info("read_muos_history: Processing file", file_count, "...")
        end

        -- Read the .cfg file (3 lines: path, system, title)
        local cfg = io.open(cfg_file, "r")
        if cfg then
            local rom_path = cfg:read("*line")
            local system = cfg:read("*line")
            local title = cfg:read("*line")
            cfg:close()
            
            if rom_path and system and title then
                -- Convert /mnt/union/ROMS to /mnt/mmc/ROMS to match Game Library
                local local_path = rom_path:gsub("^/mnt/union/ROMS", "/mnt/mmc/ROMS")
                
                -- Get file modification time as timestamp
                local stat_cmd = string.format('stat -c %%Y "%s" 2>/dev/null', cfg_file)
                local stat_handle = io.popen(stat_cmd)
                local timestamp = tonumber(stat_handle:read("*a")) or 0
                stat_handle:close()
                
                table.insert(history_entries, {
                    path = local_path,
                    system = system,
                    title = title,
                    timestamp = timestamp
                })
            end
        end
        
        -- Limit to 50 most recent games for performance
        if file_count >= 50 then
            break
        end
    end
    handle:close()
    
    Logger.info("Read", #history_entries, "entries from muOS history")
    return history_entries
end

-- Load existing collections from muOS collection directory
-- Imports user-created collections from /mnt/mmc/MUOS/info/collection/
function CollectionManager.load_muos_collections()
    local muos_collect_dir = "/mnt/mmc/MUOS/info/collection"

    Logger.debug("load_muos_collections() called")
    Logger.info("Loading muOS collections from:", muos_collect_dir)

    -- Check if directory exists
    Logger.debug("Checking if directory exists...")

    local check_dir = io.popen(string.format('test -d "%s" && echo "exists"', muos_collect_dir))
    local exists = check_dir:read("*a"):match("exists")
    check_dir:close()

    Logger.debug("Directory exists:", tostring(exists ~= nil))

    if not exists then
        Logger.debug("No muOS collections directory, returning")
        return  -- No muOS collections to load
    end

    -- List all directories in collection folder
    local ls_cmd = string.format('ls -1d "%s"/*/ 2>/dev/null', muos_collect_dir)
    Logger.debug("About to list directories with:", ls_cmd)

    local handle = io.popen(ls_cmd)
    Logger.debug("io.popen() returned, handle:", tostring(handle))

    if not handle then
        Logger.debug("handle is nil, returning")
        return
    end

    local loaded_count = 0
    Logger.debug("Starting to read collection directories...")

    local collection_num = 0
    for collection_path in handle:lines() do
        collection_num = collection_num + 1
        Logger.debug("Processing collection #" .. collection_num .. ":", collection_path)

        -- Extract collection name from path (remove trailing slash)
        local collection_name = collection_path:match("([^/]+)/$")
        if not collection_name then
            collection_name = collection_path:match("([^/]+)$")
        end

        Logger.debug("  Extracted name:", tostring(collection_name))

        if collection_name then
            -- Skip muOS system collections (managed by muOS itself)
            local skip_collections = {
                ["Favorites"] = true,
                ["History"] = true,
                ["Explore"] = true
            }

            if skip_collections[collection_name] then
                Logger.debug("  Skipping system collection:", collection_name)
                goto continue
            end

            -- Generate ID from name
            local collection_id = "muos-" .. collection_name:lower():gsub("[^%w]", "-")
            Logger.debug("  Generated ID:", collection_id)

            -- Skip if already exists in our collections
            if not CollectionManager.collections_by_id[collection_id] then
                Logger.debug("  Skipping game count (performance optimization)")

                -- Skip game count to avoid hanging on large collections or problematic files
                -- The count will be calculated when the collection is actually browsed
                local game_count = 0

                Logger.debug("  Game count set to:", game_count, "(will be calculated on browse)")

                -- Create a static collection (muOS collections are just folders, not filters)
                Logger.debug("  Creating collection object...")

                local collection = Collection.new({
                    id = collection_id,
                    name = collection_name,
                    filters = {},
                    filter_mode = "AND",
                    is_system = false,
                    is_muos_import = true,  -- Mark as imported from muOS
                    icon = "folder",
                    sort_order = "title_asc",
                    game_ids = {}  -- Will be populated when browsing
                })

                Logger.debug("  Collection created:", tostring(collection ~= nil))

                if collection then
                    table.insert(CollectionManager.collections, collection)
                    CollectionManager.collections_by_id[collection.id] = collection
                    loaded_count = loaded_count + 1
                    Logger.info(string.format("Loaded muOS collection: %s (%d games)", collection_name, game_count))
                    Logger.debug("  Added to collections list")
                end
            else
                Logger.debug("  Collection already exists, skipping")
            end
        else
            Logger.debug("  Failed to extract collection name")
        end

        ::continue::
        Logger.debug("  Finished processing collection #" .. collection_num)
    end

    Logger.debug("Finished reading collection directories, closing handle...")

    handle:close()

    Logger.debug("Handle closed, loaded_count:", loaded_count)

    if loaded_count > 0 then
        Logger.info("Loaded", loaded_count, "collections from muOS")
    end

    Logger.debug("load_muos_collections() completed")
end

return CollectionManager
