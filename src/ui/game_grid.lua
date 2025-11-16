-- GameGrid component with virtual scrolling
-- Constitution: I. Performance-First (viewport culling for 60 FPS)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")

local GameGrid = {}
GameGrid.__index = GameGrid

-- Global image cache (shared across all GameGrid instances)
-- Cache structure: { [path] = image_object | error_string }
--   - image_object (userdata): Successfully loaded image
--   - error_string (string): Error message from failed load attempt
GameGrid.image_cache = {}
GameGrid.placeholder_image = nil  -- Fallback icon when box art not found
GameGrid.catalogue_available = nil  -- nil = not checked, true = exists, false = missing

-- Cache statistics
GameGrid.cache_stats = {
    hits = 0,          -- Successful cache retrievals
    misses = 0,        -- Cache misses requiring disk load
    success_loads = 0, -- Successful image loads from disk
    failed_loads = 0   -- Failed image loads from disk
}

-- Clear image cache (useful for debugging box art issues)
-- The cache automatically re-checks file existence for cached failures,
-- but you can manually clear it to force a complete refresh
function GameGrid.clear_image_cache()
    local count = 0
    for _ in pairs(GameGrid.image_cache) do count = count + 1 end
    Logger.info("Box art cache cleared (" .. count .. " entries)")
    Logger.info("Cache stats - Hits: " .. GameGrid.cache_stats.hits ..
                ", Misses: " .. GameGrid.cache_stats.misses ..
                ", Success: " .. GameGrid.cache_stats.success_loads ..
                ", Failed: " .. GameGrid.cache_stats.failed_loads)
    GameGrid.image_cache = {}
    GameGrid.cache_stats = { hits = 0, misses = 0, success_loads = 0, failed_loads = 0 }
end

-- Get cache statistics
function GameGrid.get_cache_stats()
    local success_count = 0
    local failure_count = 0
    for _, cached in pairs(GameGrid.image_cache) do
        if type(cached) == "userdata" then
            success_count = success_count + 1
        else
            failure_count = failure_count + 1
        end
    end
    return {
        total_entries = success_count + failure_count,
        cached_images = success_count,
        cached_failures = failure_count,
        hits = GameGrid.cache_stats.hits,
        misses = GameGrid.cache_stats.misses,
        success_loads = GameGrid.cache_stats.success_loads,
        failed_loads = GameGrid.cache_stats.failed_loads
    }
end

-- Create a new GameGrid
function GameGrid.new(x, y, width, height)
    local self = setmetatable({}, GameGrid)

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- List configuration (vertical list, not grid)
    self.item_height = 60  -- Increased to fit box art thumbnail (was 50)
    self.padding = DisplayConfig.SIZES.padding
    self.cols = 1  -- List view - single column
    
    -- Box art configuration
    self.box_art_size = 48  -- 48x48 thumbnail
    self.box_art_padding = 8  -- Space between art and text

    -- Virtual scrolling state
    self.scroll_offset = 0
    self.scroll_speed = 120  -- pixels per second
    self.items = {}
    self.selected_index = 1

    -- Performance optimization: Create canvas for offscreen rendering
    -- Only render visible items, cache the rest
    self.canvas = nil  -- Created on demand
    self.canvas_needs_update = true

    -- Font cache for text rendering
    self.font_cache = {}

    return self
end-- Set items to display
function GameGrid:set_items(items)
    self.items = items or {}
    self.selected_index = 1
    self.scroll_offset = 0
    self.canvas_needs_update = true  -- Invalidate cache
    Logger.debug("GameGrid items set:", #self.items)
end

-- Update grid
function GameGrid:update(dt)
    -- Smooth scrolling (animated)
    -- Target scroll position based on selected item
    if #self.items > 0 then
        local target_row = math.floor((self.selected_index - 1) / self.cols)
        local target_y = target_row * self.item_height

        -- Keep selected item in viewport
        local viewport_height = self.height
        local min_scroll = target_y - viewport_height + self.item_height + self.padding
        local max_scroll = target_y - self.padding

        if self.scroll_offset < min_scroll then
            self.scroll_offset = min_scroll
        elseif self.scroll_offset > max_scroll then
            self.scroll_offset = max_scroll
        end

        -- Clamp to valid range
        local max_offset = math.max(0, math.ceil(#self.items / self.cols) * self.item_height - viewport_height)
        self.scroll_offset = math.max(0, math.min(max_offset, self.scroll_offset))
    end
end

-- Draw list with virtual scrolling
function GameGrid:draw()
    -- Enable scissor (clip outside viewport)
    love.graphics.setScissor(self.x, self.y, self.width, self.height)

    if #self.items == 0 then
        -- Draw "no items" message
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        local msg = "No games found"
        local msg_width = love.graphics.getFont():getWidth(msg)
        local msg_x = self.x + (self.width - msg_width) / 2
        local msg_y = self.y + self.height / 2
        love.graphics.print(msg, msg_x, msg_y)
        love.graphics.setScissor()
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Calculate visible range (viewport culling)
    local visible_start = math.max(1, math.floor(self.scroll_offset / self.item_height))
    local visible_end = math.min(#self.items, math.ceil((self.scroll_offset + self.height) / self.item_height) + 1)

    -- Draw each visible list item
    for i = visible_start, visible_end do
        local game = self.items[i]
        if game then
            local item_y = self.y + (i - 1) * self.item_height - self.scroll_offset
            local is_selected = (i == self.selected_index)

            -- Draw background bar
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.primary)
            else
                love.graphics.setColor(DisplayConfig.COLORS.surface)
            end
            love.graphics.rectangle("fill", self.x, item_y, self.width, self.item_height)

            -- Draw text content
            self:draw_list_item(game, item_y, is_selected)
        end
    end

    -- Disable scissor
    love.graphics.setScissor()

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end-- Draw a single list item
function GameGrid:draw_list_item(game, item_y, is_selected)
    local padding = 12
    local text_y = item_y + (self.item_height - DisplayConfig.SIZES.font_size_medium) / 2

    -- Set text color
    if is_selected then
        love.graphics.setColor(1, 1, 1)  -- White for selected
    else
        love.graphics.setColor(DisplayConfig.COLORS.text)
    end

    -- Favorite star icon (left of title)
    local title_x = self.x + padding
    if game.favorite then
        -- Draw filled star (★)
        love.graphics.setColor(1.0, 0.8, 0.0)  -- Gold color
        love.graphics.print("★", title_x, text_y)
        title_x = title_x + 20  -- Add space after star
        
        -- Restore text color
        if is_selected then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(DisplayConfig.COLORS.text)
        end
    end

    -- Game title
    local title = game.title or "Unknown"
    local max_title_width = self.width - 250 - (game.favorite and 20 or 0)  -- Account for star
    local font = love.graphics.getFont()

    -- Truncate title if too long
    if font:getWidth(title) > max_title_width then
        while font:getWidth(title .. "...") > max_title_width and #title > 0 do
            title = title:sub(1, -2)
        end
        title = title .. "..."
    end

    love.graphics.print(title, title_x, text_y)

    -- System badge (right side)
    local system_text = (game.system or "unknown"):upper()
    local system_x = self.x + self.width - 180

    -- Dim color for system
    if is_selected then
        love.graphics.setColor(0.9, 0.9, 0.9)
    else
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    end
    love.graphics.print("[" .. system_text .. "]", system_x, text_y)

    -- Year (far right)
    if game.year then
        local year_text = tostring(game.year)
        local year_x = self.x + self.width - 80
        love.graphics.print(year_text, year_x, text_y)
    end
end-- Navigate list (up/down only for single column)
function GameGrid:move_up()
    if self.selected_index > 1 then
        self.selected_index = self.selected_index - 1
        Logger.info("GameGrid selection moved UP to:", self.selected_index, "/", #self.items)
    else
        Logger.info("GameGrid at top, can't move up")
    end
end

function GameGrid:move_down()
    if self.selected_index < #self.items then
        self.selected_index = self.selected_index + 1
        Logger.info("GameGrid selection moved DOWN to:", self.selected_index, "/", #self.items)
    else
        Logger.info("GameGrid at bottom, can't move down")
    end
end

function GameGrid:move_left()
    -- Not used in list view
end

function GameGrid:move_right()
    -- Not used in list view
end

-- Get selected game
function GameGrid:get_selected()
    if #self.items > 0 and self.selected_index <= #self.items then
        return self.items[self.selected_index]
    end
    return nil
end

-- Load box art image for a game
--
-- Box art search strategy:
--   1. Extract ROM filename without extension from game.file_path
--   2. Map game.system to muOS catalogue folder name (e.g., "gbc" -> "Nintendo Game Boy Color")
--   3. Try multiple system folder variations (with/without spaces around dashes)
--   4. For each system folder, try filename variations:
--      - Exact ROM filename: "Game (USA) (Rev 1).png"
--      - Stripped filename: "Game.png" (removes region/revision tags)
--   5. Load image using fallback methods:
--      - Direct: love.graphics.newImage(path) - fast but may fail with restricted filesystem
--      - FileData: io.open() → FileData → ImageData → Image - slower but works around restrictions
--   6. Cache all results (success or failure) to avoid repeated filesystem checks
--   7. Cached failures are automatically re-checked if files are added later
--
-- Search paths example for "Dr. Mario (Japan, USA) (En).zip" on FC system:
--   /mnt/mmc/MUOS/info/catalogue/Nintendo NES - Famicom/box/Dr. Mario (Japan, USA) (En).png
--   /mnt/mmc/MUOS/info/catalogue/Nintendo NES - Famicom/box/Dr. Mario.png
--   /mnt/mmc/MUOS/info/catalogue/Nintendo NES-Famicom/box/Dr. Mario (Japan, USA) (En).png
--   /mnt/mmc/MUOS/info/catalogue/Nintendo NES-Famicom/box/Dr. Mario.png
--
-- Cache performance:
--   - Successful loads are cached in memory (instant retrieval on next access)
--   - Failed loads are cached to avoid repeated filesystem checks
--   - Cache auto-retries if files are added after initial failure
--   - Use GameGrid.get_cache_stats() to view cache performance metrics
--
-- Debugging box art issues:
--   - Check logs for "Box art search" messages showing all paths tried
--   - Look for "✓✓✓ CACHE HIT" for successful cache retrievals
--   - Verify catalogue exists: ls /mnt/mmc/MUOS/info/catalogue/
--   - Check system folder name matches: ls /mnt/mmc/MUOS/info/catalogue/<SYSTEM>/box/
--   - Clear cache with GameGrid.clear_image_cache() to retry failed loads
--
-- @param game Game: The game object
-- @return Image|nil: Love2D image object or nil if not found
function GameGrid:load_box_art(game)
    local Paths = require("src.config.paths")

    if not game or not game.system or not game.title then
        return nil
    end

    -- Check if catalogue directory exists (only once)
    if GameGrid.catalogue_available == nil then
        local catalogue_base = "/mnt/mmc/MUOS/info/catalogue"
        GameGrid.catalogue_available = Paths.dir_exists(catalogue_base)

        if not GameGrid.catalogue_available then
            Logger.info("muOS catalogue not found - box art disabled")
            Logger.info("To enable: Install box art to", catalogue_base)
        else
            Logger.info("muOS catalogue found - box art enabled")
        end
    end

    -- Skip if catalogue not available
    if not GameGrid.catalogue_available then
        return nil
    end

    -- Map short system codes to muOS catalogue folder names
    -- These MUST match the catalogue= values in MUOS/info/assign/<system>/global.ini
    local muos_system_map = {
        -- Nintendo
        nes = "Nintendo NES - Famicom",
        fc = "Nintendo NES - Famicom",
        snes = "Nintendo SNES - SFC",
        sfc = "Nintendo SNES - SFC",
        gb = "Nintendo Game Boy",
        gbc = "Nintendo Game Boy Color",
        gba = "Nintendo Game Boy Advance",
        n64 = "Nintendo N64",
        nds = "Nintendo DS",
        -- Sony
        ps1 = "Sony PlayStation",
        ps = "Sony PlayStation",
        psp = "Sony PlayStation Portable",
        -- Sega
        genesis = "Sega Mega Drive-Genesis",
        md = "Sega Mega Drive-Genesis",
        mastersystem = "Sega Master System",
        ms = "Sega Master System",
        gamegear = "Sega Game Gear",
        gg = "Sega Game Gear",
        dreamcast = "Sega Dreamcast",
        dc = "Sega Dreamcast",
        -- Arcade
        arcade = "Arcade",
        fbneo = "Arcade",
        mame = "Arcade",
    }

    -- Build box art path: /mnt/mmc/MUOS/info/catalogue/<SYSTEM>/box/<ROMNAME>.png
    -- Extract ROM filename without extension (exact match is critical per muOS docs)
    local rom_basename = game.file_path:match("([^/]+)%.[^%.]+$")
    if not rom_basename then
        rom_basename = game.title  -- Fallback to title
    end

    -- Try multiple system folder name variations (muOS naming is inconsistent)
    -- Example: NES uses "Nintendo NES - Famicom" but SNES uses "Nintendo SNES-SFC"
    local mapped_system = muos_system_map[game.system:lower()] or game.system
    local system_variations = {
        mapped_system,  -- Primary mapping: "Nintendo NES - Famicom"
        (mapped_system:gsub("%s*-%s*", "-")),  -- No spaces: "Nintendo NES-Famicom"
        (mapped_system:gsub("%-", " - "):gsub("%s+", " ")),  -- Spaces normalized: ensure single space around dash
    }

    -- Remove duplicates from system variations
    local seen = {}
    local unique_systems = {}
    for _, sys in ipairs(system_variations) do
        if not seen[sys] then
            seen[sys] = true
            table.insert(unique_systems, sys)
        end
    end

    -- Try each system folder variation
    Logger.debug("Box art search - ROM basename:", rom_basename)
    Logger.debug("Box art search - System:", table.concat(unique_systems, ", "))

    for sys_idx, catalogue_system in ipairs(unique_systems) do
        local catalogue_dir = string.format("/mnt/mmc/MUOS/info/catalogue/%s/box", catalogue_system)

        -- Try file name variations:
        -- 1. Exact ROM filename (per muOS docs, this MUST match)
        -- 2. Stripped version (fallback for manually renamed files)
        local file_variations = {
            rom_basename,  -- Exact match: "Contra Force (USA).png"
            (rom_basename:gsub("%s*%([^%)]*%)%s*", ""):gsub("%s*%[[^%]]*%]%s*", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"))  -- Strip tags: "Contra Force.png"
        }

        for file_idx, filename in ipairs(file_variations) do
            if filename and filename ~= "" then
                local box_art_path = string.format("%s/%s.png", catalogue_dir, filename)

                -- Check cache first
                if GameGrid.image_cache[box_art_path] ~= nil then
                    -- Cache hit - check if it's an image or an error record
                    local cached = GameGrid.image_cache[box_art_path]
                    if type(cached) == "userdata" then
                        -- It's a cached image object - instant return!
                        GameGrid.cache_stats.hits = GameGrid.cache_stats.hits + 1
                        Logger.debug(string.format("Cache hit: %s", box_art_path))
                        return cached
                    else
                        -- It's a cached failure - but check if file exists now (might have been added)
                        local file_exists = Paths.file_exists(box_art_path)
                        Logger.debug(string.format("Cached failure, re-checking: %s", file_exists and "exists now" or "still missing"))

                        if file_exists then
                            -- File exists now! Clear cache and retry
                            GameGrid.image_cache[box_art_path] = nil
                            Logger.debug("Cache cleared, retrying...")
                            -- Fall through to loading logic below
                        else
                            -- Still doesn't exist, skip to next variation
                            goto continue_to_next_file
                        end
                    end
                end

                -- Not in cache OR cache was cleared due to file now existing
                if GameGrid.image_cache[box_art_path] == nil then
                    -- Cache miss - need to load from disk
                    GameGrid.cache_stats.misses = GameGrid.cache_stats.misses + 1

                    -- Not in cache - check if file exists first
                    local file_exists = Paths.file_exists(box_art_path)

                    if file_exists then
                        -- File exists, try to load it
                        Logger.debug(string.format("Attempting to load: %s", box_art_path))

                        -- Try direct path first (works if LÖVE has filesystem access)
                        local success, image_or_error = pcall(love.graphics.newImage, box_art_path)

                        if not success then
                            -- Direct path failed, try loading via FileData (workaround for restricted filesystem)
                            Logger.debug("Trying FileData fallback method...")

                            local file = io.open(box_art_path, "rb")
                            if file then
                                local data = file:read("*all")
                                file:close()

                                -- Create FileData from the raw bytes
                                local filedata_success, filedata = pcall(love.filesystem.newFileData, data, "temp.png")
                                if filedata_success and filedata then
                                    -- Create ImageData from FileData
                                    local imagedata_success, imagedata = pcall(love.image.newImageData, filedata)
                                    if imagedata_success and imagedata then
                                        -- Create Image from ImageData
                                        success, image_or_error = pcall(love.graphics.newImage, imagedata)
                                    end
                                end
                            end
                        end

                        if success and image_or_error then
                            -- Cache and return the image
                            GameGrid.cache_stats.success_loads = GameGrid.cache_stats.success_loads + 1
                            GameGrid.image_cache[box_art_path] = image_or_error
                            Logger.info(string.format("Box art search - ✓ SUCCESS: %s", box_art_path))
                            return image_or_error
                        else
                            -- Failed to load despite file existing - cache the error message
                            GameGrid.cache_stats.failed_loads = GameGrid.cache_stats.failed_loads + 1
                            local error_msg = tostring(image_or_error)
                            GameGrid.image_cache[box_art_path] = error_msg
                            Logger.debug(string.format("Load failed: %s", error_msg))
                        end
                    else
                        -- File doesn't exist - cache as false
                        GameGrid.cache_stats.failed_loads = GameGrid.cache_stats.failed_loads + 1
                        GameGrid.image_cache[box_art_path] = "File does not exist"
                    end
                end

                ::continue_to_next_file::
            end
        end
    end

    Logger.debug("Box art not found")
    return nil
end

-- Draw game info panel with box art (called when user presses menu button)
function GameGrid:draw_info_panel(game)
    if not game then
        Logger.warn("draw_info_panel: no game provided")
        return
    end

    Logger.info("Drawing info panel for:", game.title)

    -- Panel configuration
    local panel_width = math.min(500, DisplayConfig.width - 40)
    local panel_height = math.min(600, DisplayConfig.height - 40)
    local panel_x = (DisplayConfig.width - panel_width) / 2
    local panel_y = (DisplayConfig.height - panel_height) / 2
    local padding = 20

    -- Draw dark overlay background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, DisplayConfig.width, DisplayConfig.height)

    -- Draw panel background
    love.graphics.setColor(DisplayConfig.COLORS.surface)
    love.graphics.rectangle("fill", panel_x, panel_y, panel_width, panel_height)

    -- Draw panel border
    love.graphics.setColor(DisplayConfig.COLORS.primary)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panel_x, panel_y, panel_width, panel_height)
    love.graphics.setLineWidth(1)

    local content_x = panel_x + padding
    local content_y = panel_y + padding
    local content_width = panel_width - padding * 2

    -- Try to load box art
    local box_art = self:load_box_art(game)
    local art_height = 0

    if box_art then
        -- Draw box art centered at top
        local max_art_width = content_width
        local max_art_height = 300
        local img_width = box_art:getWidth()
        local img_height = box_art:getHeight()
        local scale = math.min(max_art_width / img_width, max_art_height / img_height)
        local display_width = img_width * scale
        local display_height = img_height * scale

        local art_x = content_x + (content_width - display_width) / 2

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(box_art, art_x, content_y, 0, scale, scale)

        art_height = display_height + padding
    else
        -- Draw placeholder message
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        local no_art_msg = "[No box art]"
        local msg_width = love.graphics.getFont():getWidth(no_art_msg)
        love.graphics.print(no_art_msg, content_x + (content_width - msg_width) / 2, content_y)
        art_height = 40
    end

    -- Draw game info below box art
    local info_y = content_y + art_height
    love.graphics.setColor(DisplayConfig.COLORS.text)

    -- Title
    local title = game.title or "Unknown"
    love.graphics.print(title, content_x, info_y)
    info_y = info_y + 30

    -- System
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    love.graphics.print("System: " .. (game.system or "unknown"):upper(), content_x, info_y)
    info_y = info_y + 25

    -- Year
    if game.year then
        love.graphics.print("Year: " .. game.year, content_x, info_y)
        info_y = info_y + 25
    end

    -- Player count
    if game.player_count and game.player_count > 1 then
        love.graphics.print("Players: " .. game.player_count, content_x, info_y)
        info_y = info_y + 25
    end

    -- Genre
    if game.genre and #game.genre > 0 then
        love.graphics.print("Genre: " .. table.concat(game.genre, ", "), content_x, info_y)
        info_y = info_y + 25
    end

    -- Play stats
    if game.play_count and game.play_count > 0 then
        love.graphics.print("Played: " .. game.play_count .. " times", content_x, info_y)
        info_y = info_y + 25
    end

    -- Favorite status
    if game.favorite then
        love.graphics.setColor(1.0, 0.8, 0.0)
        love.graphics.print("★ Favorite", content_x, info_y)
        info_y = info_y + 25
    end

    -- Help text at bottom
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_text = "Press B to close"
    local help_y = panel_y + panel_height - padding - 20
    love.graphics.print(help_text, content_x, help_y)

    -- Reset
    love.graphics.setColor(1, 1, 1, 1)
end

return GameGrid
