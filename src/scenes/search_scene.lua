-- Search Scene
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local SearchEngine = require("src.services.search_engine")
local GameLibrary = require("src.services.game_library")
local FilterEngine = require("src.services.filter_engine")
local SearchFilter = require("src.models.search_filter")
local FilterPanel = require("src.ui.filter_panel")
local SearchBar = require("src.ui.search_bar")
local OnScreenKeyboard = require("src.ui.keyboard")
local GameGrid = require("src.ui.game_grid")

local SearchScene = {}

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
    SearchScene.keyboard:show()  -- Show by default
    SearchScene.keyboard_mode = true

    -- Game grid below keyboard (or below search bar if keyboard hidden)
    local grid_y = keyboard_y + keyboard_height + margin
    local grid_height = DisplayConfig.height - grid_y - margin
    SearchScene.game_grid = GameGrid.new(margin, grid_y, width, grid_height)

    -- Load initial results (all games)
    SearchScene.search_results = SearchEngine.get_last_results()
    if #SearchScene.search_results == 0 then
        SearchScene.search_results = SearchEngine.search("")  -- Get all games
    end
    SearchScene.game_grid:set_items(SearchScene.search_results)

    -- Initialize FilterPanel (overlay)
    local panel_w = math.floor(DisplayConfig.width * 0.9)
    local panel_h = math.floor(DisplayConfig.height * 0.9)
    local panel_x = math.floor((DisplayConfig.width - panel_w) / 2)
    local panel_y = math.floor((DisplayConfig.height - panel_h) / 2)
    SearchScene.filter_panel = FilterPanel.new(panel_x, panel_y, panel_w, panel_h, GameLibrary.get_all())

    Logger.info("SearchScene initialized with", #SearchScene.search_results, "games")
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
    local name_results = SearchEngine.query(query)

    -- Apply additional filters (excluding the name query)
    local filter_objs = {}
    for _, f in ipairs(SearchScene.active_filters or {}) do
        local obj, err = SearchFilter.new({ filter_type = f.filter_type, operator = f.operator, value = f.value })
        if obj then table.insert(filter_objs, obj) end
    end
    if #filter_objs > 0 then
        SearchScene.search_results = FilterEngine.apply_filters(name_results, filter_objs, SearchScene.filter_mode)
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

    -- Update grid items if results changed
    if SearchScene.game_grid then
        SearchScene.game_grid:set_items(SearchScene.search_results)
    end
end

-- Draw scene
function SearchScene.draw()
    -- Draw search bar
    if SearchScene.search_bar then
        SearchScene.search_bar:draw()
    end

    -- Draw on-screen keyboard
    if SearchScene.keyboard and SearchScene.keyboard:is_visible() then
        SearchScene.keyboard:draw()
    end

    -- Draw game grid
    if SearchScene.game_grid then
        SearchScene.game_grid:draw()
    end

    -- Draw loading indicator
    if SearchScene.loading_indicator_visible then
        love.graphics.setColor(DisplayConfig.COLORS.warning)
        love.graphics.print("Searching...", DisplayConfig.width - 120, DisplayConfig.SIZES.margin)
    end

    -- Draw filter panel overlay if visible
    if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
        SearchScene.filter_panel:draw()
    end

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    if SearchScene.keyboard_mode then
        love.graphics.print("SELECT: Hide Keyboard | START: Collections Menu", DisplayConfig.SIZES.margin, help_y)
    else
        love.graphics.print("SELECT: Show Keyboard | START: Save Collection", DisplayConfig.SIZES.margin, help_y)
    end
end

-- Handle keyboard input
function SearchScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)

    if not action then
        -- Handle text input (when not on keyboard)
        if not SearchScene.keyboard_mode and key:len() == 1 then
            SearchScene.search_bar:add_char(key)
        elseif key == "backspace" and not SearchScene.keyboard_mode then
            SearchScene.search_bar:backspace()
        end
        return
    end

    SearchScene.handle_action(action)
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
            if query and query ~= "" then
                table.insert(filters, { filter_type = "name", operator = "contains", value = query })
            end
            -- Include active panel filters
            for _, f in ipairs(SearchScene.active_filters or {}) do
                table.insert(filters, { filter_type = f.filter_type, operator = f.operator, value = f.value })
            end
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
        -- Close keyboard or clear search
        if SearchScene.keyboard_mode then
            SearchScene.keyboard:hide()
            SearchScene.keyboard_mode = false
            SearchScene.search_bar:set_focus(false)
        else
            SearchScene.search_bar:clear()
        end

    elseif action == "confirm" then
        -- Select key on keyboard or select game
        if SearchScene.keyboard_mode then
            local key = SearchScene.keyboard:get_selected_key()
            if key == "⌫" then
                SearchScene.search_bar:backspace()
            else
                SearchScene.search_bar:add_char(key)
            end
        else
            -- TODO: Launch selected game
            local selected = SearchScene.game_grid:get_selected()
            if selected then
                Logger.info("Selected game:", selected.title)
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
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_up()
        else
            SearchScene.game_grid:move_up()
        end

    elseif action == "down" then
        if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
            SearchScene.filter_panel:handle_action(action)
        elseif SearchScene.keyboard_mode then
            SearchScene.keyboard:move_down()
        else
            SearchScene.game_grid:move_down()
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
    end

    -- Sync filters from panel when it is visible (live update)
    if SearchScene.filter_panel and SearchScene.filter_panel:is_visible() then
        SearchScene.active_filters = SearchScene.filter_panel:get_filters()
        SearchScene.filter_mode = SearchScene.filter_panel:get_mode()
    end
end

return SearchScene
