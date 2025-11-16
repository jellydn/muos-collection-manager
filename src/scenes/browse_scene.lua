-- BrowseScene - Display games in a collection
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local SearchEngine = require("src.services.search_engine")
local GameLibrary = require("src.services.game_library")
local GameLauncher = require("src.services.game_launcher")
local GameGrid = require("src.ui.game_grid")
local SceneManager = require("src.scenes.scene_manager")
local Dialog = require("src.ui.dialog")

local BrowseScene = {}

-- Scene state
BrowseScene.collection = nil
BrowseScene.games = {}
BrowseScene.game_grid = nil
BrowseScene.export_dialog = nil  -- Success/error message dialog
BrowseScene.show_info_panel = false  -- Game info panel (menu button)

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
        -- Favorites - get favorite games directly
        BrowseScene.games = GameLibrary.get_favorites()
        Logger.info("Loaded", #BrowseScene.games, "favorite games")

    elseif BrowseScene.collection.id == "recent-system" then
        -- Recently played - load from muOS history
        Logger.info("Loading recently played games from muOS history")
        local CollectionManager = require("src.services.collection_manager")
        local history_entries = CollectionManager.read_muos_history()
        
        -- Match history entries to games in library
        -- IMPORTANT: Search once, not inside the loop!
        local all_games = SearchEngine.search("")
        BrowseScene.games = {}
        
        for _, entry in ipairs(history_entries) do
            -- Find game in library by file path
            for _, game in ipairs(all_games) do
                if game.file_path == entry.path then
                    table.insert(BrowseScene.games, game)
                    break
                end
            end
        end
        
        Logger.info("Loaded", #BrowseScene.games, "recently played games from muOS history")

    else
        -- Custom collection - apply ALL filters
        if #BrowseScene.collection.filters == 0 then
            -- No filters - show all games
            BrowseScene.games = SearchEngine.search("")
        else
            local FilterEngine = require("src.services.filter_engine")
            local SearchFilter = require("src.models.search_filter")
            
            -- Start with all games or name-filtered games
            local base_games = SearchEngine.search("")
            local name_query = ""
            local other_filters = {}
            
            -- Separate name filter from others
            for _, f in ipairs(BrowseScene.collection.filters) do
                if f.filter_type == "name" then
                    name_query = f.value or ""
                else
                    local filter_obj = SearchFilter.new(f)
                    if filter_obj then
                        table.insert(other_filters, filter_obj)
                    end
                end
            end
            
            -- Apply name search first
            if name_query ~= "" then
                base_games = SearchEngine.search(name_query)
            end
            
            -- Then apply other filters
            if #other_filters > 0 then
                BrowseScene.games = FilterEngine.apply_filters(
                    base_games, 
                    other_filters, 
                    BrowseScene.collection.filter_mode or "AND"
                )
            else
                BrowseScene.games = base_games
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
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_medium))

    -- Draw game count
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    love.graphics.print(#BrowseScene.games .. " games", DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin + 30)

    -- Draw game grid
    if BrowseScene.game_grid then
        BrowseScene.game_grid:draw()
    end

    -- Draw dialog overlay (for export/delete confirmations)
    if BrowseScene.export_dialog and BrowseScene.export_dialog.is_open then
        BrowseScene.export_dialog:draw()
    end

    -- Draw info panel if active (menu button pressed)
    if BrowseScene.show_info_panel and BrowseScene.game_grid then
        local selected = BrowseScene.game_grid:get_selected()
        if selected then
            BrowseScene.game_grid:draw_info_panel(selected)
        end
    end

    -- Draw help text (only if dialog not open)
    if not BrowseScene.export_dialog or not BrowseScene.export_dialog.is_open then
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin

        -- Show different help text based on whether collection can be exported
        -- Only "All Games" and "Recently Played" cannot be exported
        local non_exportable = {
            ["all-games-system"] = true,
            ["recent-system"] = true
        }

        local help_text
        if BrowseScene.collection and non_exportable[BrowseScene.collection.id] then
            help_text = "B: Back | START: Info | X: Delete | Y: Favorite"
        else
            help_text = "A: Export | B: Back | START: Info | X: Delete | Y: Favorite"
        end

        love.graphics.print(help_text, DisplayConfig.SIZES.margin, help_y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle keyboard input
function BrowseScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)
    if action then
        Logger.debug("BrowseScene action:", action)
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
    -- If info panel is open, close it on B button
    if BrowseScene.show_info_panel then
        if action == "cancel" then
            BrowseScene.show_info_panel = false
        end
        return
    end
    
    -- If export dialog is open, route input to it
    if BrowseScene.export_dialog and BrowseScene.export_dialog.is_open then
        if action == "left" then
            BrowseScene.export_dialog:move_left()
        elseif action == "right" then
            BrowseScene.export_dialog:move_right()
        elseif action == "confirm" then
            BrowseScene.export_dialog:confirm_selection()
        elseif action == "cancel" then
            BrowseScene.export_dialog:close()
            BrowseScene.export_dialog = nil
        end
        return
    end

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
        -- Export collection to muOS format
        -- Block export for dynamic system collections (All Games, Recently Played)
        local non_exportable = {
            ["all-games-system"] = true,
            ["recent-system"] = true
        }

        if BrowseScene.collection and non_exportable[BrowseScene.collection.id] then
            Logger.info("Cannot export dynamic collection:", BrowseScene.collection.name)
            -- Show info message
            BrowseScene.export_dialog = Dialog.new({
                title = "Cannot Export",
                message = string.format("'%s' cannot be exported.\n\nThis is a dynamic collection that changes automatically.", BrowseScene.collection.name),
                type = Dialog.TYPE.INFO,
                options = {"OK"},
                callback = function()
                    BrowseScene.export_dialog = nil
                end
            })
            BrowseScene.export_dialog:open()
        else
            Logger.info("Exporting collection to muOS:", BrowseScene.collection.name)
            local ok, result = GameLauncher.export_to_muos(BrowseScene.collection, BrowseScene.games)

            if ok then
                Logger.info("Collection exported successfully:", result)
                -- Show success message
                BrowseScene.export_dialog = Dialog.new({
                    title = "Export Successful!",
                    message = string.format("'%s' exported to muOS Collections.\n\nOpen muOS > Collection to launch games.", BrowseScene.collection.name),
                    type = Dialog.TYPE.INFO,
                    options = {"OK"},
                    callback = function()
                        BrowseScene.export_dialog = nil
                    end
                })
                BrowseScene.export_dialog:open()
            else
                Logger.error("Failed to export collection:", result)
                -- Show error message
                BrowseScene.export_dialog = Dialog.new({
                    title = "Export Failed",
                    message = "Failed to export collection:\n" .. tostring(result),
                    type = Dialog.TYPE.INFO,
                    options = {"OK"},
                    callback = function()
                        BrowseScene.export_dialog = nil
                    end
                })
                BrowseScene.export_dialog:open()
            end
        end

    elseif action == "cancel" then
        -- Go back to menu
        SceneManager.switch_with_fade("menu")

    elseif action == "menu" then
        -- Show game info panel with box art
        local selected = BrowseScene.game_grid and BrowseScene.game_grid:get_selected()
        if selected then
            Logger.info("START pressed - opening info panel for:", selected.title)
            BrowseScene.show_info_panel = true
        else
            -- If no game selected, go to menu
            Logger.info("START pressed - no game selected, going to menu")
            SceneManager.switch_with_fade("menu")
        end

    elseif action == "favorite" then
        -- Toggle favorite for selected game
        local selected = BrowseScene.game_grid and BrowseScene.game_grid:get_selected()
        if selected then
            GameLibrary.toggle_favorite(selected.id)
            Logger.info("Toggled favorite for:", selected.title, "->", selected.favorite)
            -- Refresh view if in favorites collection
            if BrowseScene.collection and BrowseScene.collection.id == "favorites-system" then
                BrowseScene.load_games()
            end
        end

    elseif action == "delete" then
        -- Delete selected game with confirmation
        Logger.info("DELETE action triggered")
        local selected = BrowseScene.game_grid and BrowseScene.game_grid:get_selected()
        Logger.info("Selected game:", selected and selected.title or "nil")
        if selected then
            Logger.info("Creating delete dialog...")
            BrowseScene.export_dialog = Dialog.new({
                title = "Delete Game?",
                message = string.format("Delete '%s'?\n\nThis will permanently delete the ROM file from your device. This cannot be undone!", selected.title),
                type = Dialog.TYPE.CONFIRM,
                options = {"Yes", "No"},
                callback = function(choice)
                    Logger.info("Dialog callback called with choice:", choice)
                    if choice == "yes" then
                        Logger.info("Deleting game:", selected.title, selected.file_path)
                        
                        -- Delete the ROM file
                        local delete_cmd = string.format('rm -f "%s"', selected.file_path)
                        local result = os.execute(delete_cmd)
                        
                        if result == 0 or result == true then
                            Logger.info("Successfully deleted:", selected.file_path)
                            
                            -- Remove from game library
                            GameLibrary.remove_game(selected.id)
                            
                            -- Refresh the current view
                            BrowseScene.load_games()
                            
                            -- Show success message
                            BrowseScene.export_dialog = Dialog.new({
                                title = "Game Deleted",
                                message = string.format("'%s' has been deleted.", selected.title),
                                type = Dialog.TYPE.INFO,
                                options = {"OK"},
                                callback = function()
                                    BrowseScene.export_dialog = nil
                                end
                            })
                            BrowseScene.export_dialog:open()
                        else
                            Logger.error("Failed to delete:", selected.file_path)
                            
                            -- Show error message
                            BrowseScene.export_dialog = Dialog.new({
                                title = "Delete Failed",
                                message = "Failed to delete the ROM file. It may be read-only or in use.",
                                type = Dialog.TYPE.INFO,
                                options = {"OK"},
                                callback = function()
                                    BrowseScene.export_dialog = nil
                                end
                            })
                            BrowseScene.export_dialog:open()
                        end
                    else
                        BrowseScene.export_dialog = nil
                    end
                end
            })
            Logger.info("Dialog created, opening...")
            BrowseScene.export_dialog:open()
            Logger.info("Dialog opened successfully")
        end
    end
end


return BrowseScene
