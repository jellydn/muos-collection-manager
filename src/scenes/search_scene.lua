-- Search Scene
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local SearchEngine = require("src.services.search_engine")
local GameLibrary = require("src.services.game_library")
local GameLauncher = require("src.services.game_launcher")
local FilterEngine = require("src.services.filter_engine")
local SearchFilter = require("src.models.search_filter")
local FilterPanel = require("src.ui.filter_panel")
local SearchBar = require("src.ui.search_bar")
local OnScreenKeyboard = require("src.ui.keyboard")
local GameGrid = require("src.ui.game_grid")
local SceneManager = require("src.scenes.scene_manager")

local SearchScene = {}

-- Search configuration
SearchScene.MIN_SEARCH_LENGTH = 3  -- Minimum characters before triggering search

-- Scene state
SearchScene.search_bar = nil
SearchScene.keyboard = nil
SearchScene.game_grid = nil
SearchScene.search_results = {}
SearchScene.keyboard_mode = false
SearchScene.loading_indicator_visible = false
SearchScene.search_start_time = 0
SearchScene.active_filters = {}
SearchScene.filter_mode = "AND"
SearchScene.filter_panel = nil
SearchScene.show_info_panel = false

-- Enter scene
function SearchScene.enter(data)
    Logger.info("Entering SearchScene")

    -- Initialize UI components
    local margin = DisplayConfig.SIZES.margin
    local width = DisplayConfig.width - margin * 2

    -- Search bar at top
    SearchScene.search_bar = SearchBar.new(margin, margin, width)
    SearchScene.search_bar:set_focus(true)

    -- On-screen keyboard below search bar
    local keyboard_y = margin + SearchScene.search_bar.height + margin
    local keyboard_height = 200
    SearchScene.keyboard = OnScreenKeyboard.new(margin, keyboard_y, width, keyboard_height)
    SearchScene.keyboard:hide()  -- Start hidden - show game list first
    SearchScene.keyboard_mode = false

    -- Game grid below search bar (full height when keyboard hidden)
    local grid_y = margin + SearchScene.search_bar.height + margin
    local grid_height = DisplayConfig.height - grid_y - margin
    SearchScene.game_grid = GameGrid.new(margin, grid_y, width, grid_height)

    -- Load initial results (all games)
    SearchScene.search_results = SearchEngine.get_last_results()
    Logger.debug(string.format("Last search results: %d games", #SearchScene.search_results))

    if #SearchScene.search_results == 0 then
        Logger.debug("No cached results, loading all games...")
        SearchScene.search_results = SearchEngine.search("")  -- Get all games
        Logger.debug(string.format("Loaded %d games from search", #SearchScene.search_results))
    end

    SearchScene.game_grid:set_items(SearchScene.search_results)
    Logger.debug(string.format("Game grid set with %d items", #SearchScene.search_results))

    -- Initialize FilterPanel (overlay)
    local panel_w = math.floor(DisplayConfig.width * 0.9)
    local panel_h = math.floor(DisplayConfig.height * 0.9)
    local panel_x = math.floor((DisplayConfig.width - panel_w) / 2)
    local panel_y = math.floor((DisplayConfig.height - panel_h) / 2)
    SearchScene.filter_panel = FilterPanel.new(panel_x, panel_y, panel_w, panel_h, GameLibrary.get_all())

    Logger.info(string.format("SearchScene initialized with %d games", #SearchScene.search_results))
end

-- Exit scene
function SearchScene.exit()
    Logger.info("Exiting SearchScene")
    SearchScene.search_bar = nil
    SearchScene.keyboard = nil
    SearchScene.game_grid = nil
end

-- Update scene
function SearchScene.update(dt)
    -- Update UI components
    if SearchScene.search_bar then
        SearchScene.search_bar:update(dt)
    end

    if SearchScene.keyboard and SearchScene.keyboard:is_visible() then
        SearchScene.keyboard:update(dt)
    end

    if SearchScene.game_grid then
        SearchScene.game_grid:update(dt)
    end

    -- Execute debounced name search first
    local query = SearchScene.search_bar:get_query()
    Logger.debug(string.format("Update: query='%s', dt=%.4f", query or "", dt or 0))

    -- Only search if query is empty (show all) or has minimum length
    local name_results
    if query == "" then
        -- No query - show all games
        name_results = SearchEngine.query("", dt)
        Logger.debug(string.format("Query empty, showing all %d results", #name_results))
    elseif #query >= SearchScene.MIN_SEARCH_LENGTH then
        -- Query long enough - perform search
        name_results = SearchEngine.query(query, dt)
        Logger.debug(string.format("Query returned %d results", #name_results))
    else
        -- Query too short - keep showing all games (don't search yet)
        name_results = SearchEngine.get_last_results()
        if #name_results == 0 then
            name_results = SearchEngine.query("", dt)
        end
        Logger.debug(string.format("Query too short (%d chars, min %d), keeping %d results",
            #query, SearchScene.MIN_SEARCH_LENGTH, #name_results))
    end

    -- Apply additional filters (excluding the name query)
    local filter_objs = {}
    for _, f in ipairs(SearchScene.active_filters or {}) do
        local obj, err = SearchFilter.new({ filter_type = f.filter_type, operator = f.operator, value = f.value })
        if obj then table.insert(filter_objs, obj) end
    end
    if #filter_objs > 0 then
        SearchScene.search_results = FilterEngine.apply_filters(name_results, filter_objs, SearchScene.filter_mode)
        Logger.debug(string.format("After filters: %d results", #SearchScene.search_results))
    else
        SearchScene.search_results = name_results
    end

    -- Show loading indicator if search is taking >100ms
    if SearchEngine.is_debouncing() then
        local elapsed = love.timer.getTime() - SearchScene.search_start_time
        SearchScene.loading_indicator_visible = (elapsed > 0.1)
    else
        SearchScene.loading_indicator_visible = false
        SearchScene.search_start_time = love.timer.getTime()
    end

    -- Update grid items only if results changed
    if SearchScene.game_grid then
        -- Only update if the number of results changed
        local current_count = #(SearchScene.game_grid.items or {})
        if current_count ~= #SearchScene.search_results then
            SearchScene.game_grid:set_items(SearchScene.search_results)
        end
    end
end

-- Draw scene
function SearchScene.draw()
    -- Draw search bar
    if SearchScene.search_bar then
        SearchScene.search_bar:draw()
    end

    -- Draw on-screen keyboard OR game grid (not both)
    if SearchScene.keyboard and SearchScene.keyboard:is_visible() then
        SearchScene.keyboard:draw()
        
        -- Show game count when keyboard is visible
        love.graphics.setColor(DisplayConfig.COLORS.text)
        local count_text = string.format("%d games found", #SearchScene.search_results)
        local keyboard_bottom = SearchScene.keyboard.y + SearchScene.keyboard.height
        love.graphics.print(count_text, DisplayConfig.SIZES.margin, keyboard_bottom + DisplayConfig.SIZES.margin)
        
    elseif SearchScene.game_grid then
        SearchScene.game_grid:draw()
        
        -- Draw loading indicator (only when grid is visible)
        if SearchScene.loading_indicator_visible then
            love.graphics.setColor(DisplayConfig.COLORS.warning)
            love.graphics.print("Searching...", DisplayConfig.width - 120, DisplayConfig.SIZES.margin)
        end
    end

    -- Draw filter panel overlay if visible
    if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
        SearchScene.filter_panel:draw()
    end

    -- Draw game info panel if active
    if SearchScene.show_info_panel then
        local selected = SearchScene.game_grid and SearchScene.game_grid:get_selected()
        if selected and SearchScene.game_grid then
            SearchScene.game_grid:draw_info_panel(selected)
        end
    end

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin

    if SearchScene.keyboard_mode then
        local help_text = "SELECT: Hide Keyboard | A: Type | START: Menu"
        love.graphics.print(help_text, DisplayConfig.SIZES.margin, help_y)

        -- Draw keyboard mode indicator
        love.graphics.setColor(DisplayConfig.COLORS.primary)
        love.graphics.print("[KEYBOARD MODE]", DisplayConfig.width - 150, help_y)
    else
        local help_text = "A: Info | B: Back | Y: Favorite | SELECT: Keyboard | START: Save Collection"
        love.graphics.print(help_text, DisplayConfig.SIZES.margin, help_y)
    end
end

-- Handle keyboard input
function SearchScene.keypressed(key, scancode, isrepeat)
    Logger.debug("SearchScene.keypressed:", key, "keyboard_mode:", SearchScene.keyboard_mode)
    local action = InputHandler.keypressed(key, scancode, isrepeat)
    Logger.debug("  -> action:", action or "nil")

    -- Process action first (navigation, etc.)
    if action then
        SearchScene.handle_action(action)
        return
    end

    -- Only handle text input if no action was triggered AND not in keyboard mode
    -- Allow alphanumeric and space for search input
    if not SearchScene.keyboard_mode then
        if key:match("^[a-zA-Z0-9%s]$") then
            SearchScene.search_bar:add_char(key)
        elseif key == "backspace" then
            SearchScene.search_bar:backspace()
        end
    end
end

-- Handle gamepad input
function SearchScene.gamepadpressed(joystick, button)
    local action = InputHandler.gamepadpressed(joystick, button)
    if action then
        SearchScene.handle_action(action)
    end
end

-- Handle logical action
function SearchScene.handle_action(action)
    -- If info panel is open, close it on B button
    if SearchScene.show_info_panel then
        if action == "cancel" then
            SearchScene.show_info_panel = false
        end
        return
    end

    if action == "menu" then
        -- Open menu or save collection (START button)
        if SearchScene.keyboard_mode then
            -- If keyboard is open, switch to menu
            SceneManager.switch_with_fade("menu")
        else
            -- If browsing games, save current search as collection
            local query = SearchScene.search_bar:get_query()
            local filters = {}
            -- Include name query as a filter if present
            if query and query ~= "" and #query >= SearchScene.MIN_SEARCH_LENGTH then
                table.insert(filters, { filter_type = "name", operator = "contains", value = query })
                Logger.info("Adding name filter:", query)
            end
            -- Include active panel filters
            for _, f in ipairs(SearchScene.active_filters or {}) do
                table.insert(filters, { filter_type = f.filter_type, operator = f.operator, value = f.value })
                Logger.info("Adding filter:", f.filter_type, f.operator, f.value)
            end
            Logger.info("Switching to create_collection with", #filters, "filters")
            SceneManager.switch_with_fade("create_collection", { filters = filters, filter_mode = SearchScene.filter_mode })
        end

    elseif action == "filter" then
        -- Toggle keyboard with SELECT button
        SearchScene.keyboard:toggle()
        SearchScene.keyboard_mode = SearchScene.keyboard:is_visible()

        if SearchScene.keyboard_mode then
            SearchScene.search_bar:set_focus(true)
        else
            SearchScene.search_bar:set_focus(false)
        end

    elseif action == "cancel" then
        -- Back navigation: Keyboard -> Search -> Menu
        if SearchScene.keyboard_mode then
            -- Close keyboard
            SearchScene.keyboard:hide()
            SearchScene.keyboard_mode = false
            SearchScene.search_bar:set_focus(false)
        elseif SearchScene.search_bar:get_query() ~= "" then
            -- Clear search if there's text
            SearchScene.search_bar:clear()
        else
            -- Go back to menu if search is empty
            SceneManager.switch_with_fade("menu")
        end

    elseif action == "confirm" then
        -- Select key on keyboard or show game info
        if SearchScene.keyboard_mode then
            local key = SearchScene.keyboard:get_selected_key()
            if key == "DEL" then
                SearchScene.search_bar:backspace()
            elseif key == "CAPS" then
                -- Toggle shift mode
                SearchScene.keyboard:toggle_shift()
            else
                SearchScene.search_bar:add_char(key)
            end
        else
            -- Show game info panel (A button)
            local selected = SearchScene.game_grid and SearchScene.game_grid:get_selected()
            if selected then
                Logger.info("A pressed - opening info panel for:", selected.title)
                SearchScene.show_info_panel = true
            end
        end

    elseif action == "shoulder_l" then
        -- Open/close filter panel
        if SearchScene.filter_panel then
            if SearchScene.filter_panel:is_visible() then
                SearchScene.filter_panel:hide()
            else
                SearchScene.filter_panel:show(SearchScene.active_filters, SearchScene.filter_mode)
            end
        end

    elseif action == "shoulder_r" then
        -- Toggle AND/OR mode (if panel visible, forward to it)
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        else
            SearchScene.filter_mode = (SearchScene.filter_mode == "AND") and "OR" or "AND"
        end

    elseif action == "up" then
        Logger.info("UP pressed - keyboard_mode:", SearchScene.keyboard_mode, "grid exists:", SearchScene.game_grid ~= nil)
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_up()
        else
            if SearchScene.game_grid then
                Logger.info("  -> Calling game_grid:move_up()")
                SearchScene.game_grid:move_up()
            else
                Logger.error("  -> game_grid is nil!")
            end
        end

    elseif action == "down" then
        Logger.info("DOWN pressed - keyboard_mode:", SearchScene.keyboard_mode, "grid exists:", SearchScene.game_grid ~= nil)
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_down()
        else
            if SearchScene.game_grid then
                Logger.info("  -> Calling game_grid:move_down()")
                SearchScene.game_grid:move_down()
            else
                Logger.error("  -> game_grid is nil!")
            end
        end

    elseif action == "left" then
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_left()
        else
            SearchScene.game_grid:move_left()
        end

    elseif action == "right" then
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_right()
        else
            SearchScene.game_grid:move_right()
        end

    elseif action == "favorite" then
        -- Toggle favorite for selected game (Y button)
        if not SearchScene.keyboard_mode and not (SearchScene.filter_panel and SearchScene.filter_panel:is_visible()) then
            local selected = SearchScene.game_grid:get_selected()
            if selected then
                GameLibrary.toggle_favorite(selected.id)
                Logger.info("Toggled favorite for:", selected.title, "->", selected.favorite)
            end
        end
    end

    -- Sync filters from panel when it is visible (live update)
    if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
        SearchScene.active_filters = SearchScene.filter_panel:get_filters()
        SearchScene.filter_mode = SearchScene.filter_panel:get_mode()
    end
end

return SearchScene
