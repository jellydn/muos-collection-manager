-- BrowseScene - Display games in a collection
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local SearchEngine = require("src.services.search_engine")
local GameGrid = require("src.ui.game_grid")
local SceneManager = require("src.scenes.scene_manager")

local BrowseScene = {}

-- Scene state
BrowseScene.collection = nil
BrowseScene.games = {}
BrowseScene.game_grid = nil

-- Enter scene
-- @param data table: {collection = Collection}
function BrowseScene.enter(data)
    Logger.info("Entering BrowseScene")

    if not data or not data.collection then
        Logger.error("BrowseScene requires collection data")
        SceneManager.switch_with_fade("menu")
        return
    end

    BrowseScene.collection = data.collection

    -- Initialize game grid
    local margin = DisplayConfig.SIZES.margin
    local grid_y = margin + 60  -- Account for title
    local grid_height = DisplayConfig.height - grid_y - 60  -- Account for help text
    BrowseScene.game_grid = GameGrid.new(margin, grid_y, DisplayConfig.width - margin * 2, grid_height)

    -- Load games matching collection filters
    BrowseScene.load_games()

    Logger.info("BrowseScene initialized:", BrowseScene.collection.name, "with", #BrowseScene.games, "games")
end

-- Exit scene
function BrowseScene.exit()
    Logger.info("Exiting BrowseScene")
    BrowseScene.collection = nil
    BrowseScene.games = {}
    BrowseScene.game_grid = nil
end

-- Load games matching collection filters
function BrowseScene.load_games()
    if not BrowseScene.collection then
        BrowseScene.games = {}
        return
    end

    -- Special handling for system collections
    if BrowseScene.collection.id == "all-games-system" then
        -- All games - no filters
        BrowseScene.games = SearchEngine.search("")

    elseif BrowseScene.collection.id == "favorites-system" then
        -- Favorites - filter by favorite flag
        -- TODO: Implement favorite filtering in SearchEngine
        BrowseScene.games = SearchEngine.search("")

    elseif BrowseScene.collection.id == "recent-system" then
        -- Recently played - sort by last_played
        -- TODO: Implement recent sorting in SearchEngine
        BrowseScene.games = SearchEngine.search("")

    else
        -- Custom collection - apply filters
        if #BrowseScene.collection.filters == 0 then
            -- No filters - show all games
            BrowseScene.games = SearchEngine.search("")
        else
            -- Apply first filter (name search for now)
            -- TODO: Implement multi-filter support in SearchEngine
            local first_filter = BrowseScene.collection.filters[1]
            if first_filter and first_filter.filter_type == "name" then
                BrowseScene.games = SearchEngine.search(first_filter.value or "")
            else
                BrowseScene.games = SearchEngine.search("")
            end
        end
    end

    -- Update grid
    if BrowseScene.game_grid then
        BrowseScene.game_grid:set_items(BrowseScene.games)
    end

    Logger.debug("Loaded", #BrowseScene.games, "games for collection:", BrowseScene.collection.name)
end

-- Update scene
function BrowseScene.update(dt)
    if BrowseScene.game_grid then
        BrowseScene.game_grid:update(dt)
    end
end

-- Draw scene
function BrowseScene.draw()
    -- Draw collection name as title
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_large))
    local title = BrowseScene.collection and BrowseScene.collection.name or "Browse"
    love.graphics.print(title, DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_normal))

    -- Draw game count
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    love.graphics.print(#BrowseScene.games .. " games", DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin + 30)

    -- Draw game grid
    if BrowseScene.game_grid then
        BrowseScene.game_grid:draw()
    end

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    love.graphics.print("A: Launch | B: Back to Menu", DisplayConfig.SIZES.margin, help_y)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle keyboard input
function BrowseScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)
    if action then
        BrowseScene.handle_action(action)
    end
end

-- Handle gamepad input
function BrowseScene.gamepadpressed(joystick, button)
    local action = InputHandler.gamepadpressed(joystick, button)
    if action then
        BrowseScene.handle_action(action)
    end
end

-- Handle logical action
function BrowseScene.handle_action(action)
    if action == "up" then
        if BrowseScene.game_grid then
            BrowseScene.game_grid:move_up()
        end

    elseif action == "down" then
        if BrowseScene.game_grid then
            BrowseScene.game_grid:move_down()
        end

    elseif action == "left" then
        if BrowseScene.game_grid then
            BrowseScene.game_grid:move_left()
        end

    elseif action == "right" then
        if BrowseScene.game_grid then
            BrowseScene.game_grid:move_right()
        end

    elseif action == "confirm" then
        -- Launch selected game
        local selected = BrowseScene.game_grid and BrowseScene.game_grid:get_selected()
        if selected then
            Logger.info("Launch game:", selected.title)
            -- TODO: Implement game launching
        end

    elseif action == "cancel" then
        -- Go back to menu
        SceneManager.switch_with_fade("menu")

    elseif action == "menu" then
        -- Go to menu
        SceneManager.switch_with_fade("menu")
    end
end

return BrowseScene
