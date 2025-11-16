-- MenuScene - List all collections
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local CollectionManager = require("src.services.collection_manager")
local SceneManager = require("src.scenes.scene_manager")
local Dialog = require("src.ui.dialog")
local SearchEngine = require("src.services.search_engine")
local GameLibrary = require("src.services.game_library")
local FilterEngine = require("src.services.filter_engine")
local SearchFilter = require("src.models.search_filter")

local MenuScene = {}

-- Scene state
MenuScene.collections = {}
MenuScene.selected_index = 1
MenuScene.scroll_offset = 0
MenuScene.item_height = 50
MenuScene.delete_dialog = nil

-- Get game count for a collection
function MenuScene.get_collection_game_count(collection)
    if collection.id == "all-games-system" then
        return #SearchEngine.search("")
    elseif collection.id == "favorites-system" then
        return #GameLibrary.get_favorites()
    elseif collection.id == "recent-system" then
        local CollectionManager = require("src.services.collection_manager")
        local history_entries = CollectionManager.read_muos_history()
        return #history_entries
    else
        -- Custom collection - apply filters
        if #collection.filters == 0 then
            return #SearchEngine.search("")
        else
            local base_games = SearchEngine.search("")
            local name_query = ""
            local other_filters = {}

            for _, f in ipairs(collection.filters) do
                if f.filter_type == "name" then
                    name_query = f.value or ""
                else
                    local filter_obj = SearchFilter.new(f)
                    if filter_obj then
                        table.insert(other_filters, filter_obj)
                    end
                end
            end

            if name_query ~= "" then
                base_games = SearchEngine.search(name_query)
            end

            if #other_filters > 0 then
                local filtered = FilterEngine.apply_filters(base_games, other_filters, collection.filter_mode or "AND")
                return #filtered
            else
                return #base_games
            end
        end
    end
end

-- Enter scene
function MenuScene.enter(data)
    Logger.info("Entering MenuScene")

    -- Load collections (sorted: system first, then alphabetically)
    MenuScene.collections = CollectionManager.get_sorted()
    MenuScene.selected_index = 1
    MenuScene.scroll_offset = 0

    Logger.info("MenuScene loaded", #MenuScene.collections, "collections")
end

-- Exit scene
function MenuScene.exit()
    Logger.info("Exiting MenuScene")
    MenuScene.collections = {}
end

-- Update scene
function MenuScene.update(dt)
    -- Keep selected item in view
    local viewport_height = DisplayConfig.height - 150  -- Account for title and help text
    local target_y = (MenuScene.selected_index - 1) * MenuScene.item_height

    local min_scroll = target_y - viewport_height + MenuScene.item_height
    local max_scroll = target_y

    if MenuScene.scroll_offset < min_scroll then
        MenuScene.scroll_offset = min_scroll
    elseif MenuScene.scroll_offset > max_scroll then
        MenuScene.scroll_offset = max_scroll
    end

    -- Clamp scroll
    local max_offset = math.max(0, #MenuScene.collections * MenuScene.item_height - viewport_height)
    MenuScene.scroll_offset = math.max(0, math.min(max_offset, MenuScene.scroll_offset))
end

-- Draw scene
function MenuScene.draw()
    -- Draw title
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_large))
    love.graphics.print("Collections", DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_medium))

    -- Draw collection list
    local start_y = DisplayConfig.SIZES.margin + 40
    local margin = DisplayConfig.SIZES.margin
    local width = DisplayConfig.width - margin * 2

    love.graphics.setScissor(margin, start_y, width, DisplayConfig.height - start_y - 60)

    for i, collection in ipairs(MenuScene.collections) do
        local y = start_y + (i - 1) * MenuScene.item_height - MenuScene.scroll_offset
        local is_selected = (i == MenuScene.selected_index)

        -- Draw background
        if is_selected then
            love.graphics.setColor(DisplayConfig.COLORS.primary)
        else
            love.graphics.setColor(DisplayConfig.COLORS.surface)
        end
        love.graphics.rectangle("fill", margin, y, width, MenuScene.item_height - 4, 4, 4)

        -- Draw border
        love.graphics.setColor(DisplayConfig.COLORS.secondary)
        love.graphics.rectangle("line", margin, y, width, MenuScene.item_height - 4, 4, 4)

        -- Draw collection name
        if is_selected then
            love.graphics.setColor(DisplayConfig.COLORS.background)
        else
            love.graphics.setColor(DisplayConfig.COLORS.text)
        end

        local name = collection.name
        if collection.is_system then
            name = "[S] " .. name  -- [S] for system collections
        end

        love.graphics.print(name, margin + 10, y + 15)

        -- Draw game count
        local game_count = MenuScene.get_collection_game_count(collection)
        local count_text = game_count .. " game" .. (game_count ~= 1 and "s" or "")
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        love.graphics.print(count_text, margin + 10, y + 30)
    end

    love.graphics.setScissor()

    -- Draw confirmation dialog if active
    if MenuScene.delete_dialog and MenuScene.delete_dialog.is_open then
        MenuScene.delete_dialog:draw()
    end

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    love.graphics.print("A: Browse | B: Exit | X: Delete | START: New Search", DisplayConfig.SIZES.margin, help_y)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle keyboard input
function MenuScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)
    if action then
        MenuScene.handle_action(action)
    end
end

-- Handle gamepad input
function MenuScene.gamepadpressed(joystick, button)
    local action = InputHandler.gamepadpressed(joystick, button)
    if action then
        MenuScene.handle_action(action)
    end
end

-- Handle logical action
function MenuScene.handle_action(action)
    -- If dialog is open, route input to it
    if MenuScene.delete_dialog and MenuScene.delete_dialog.is_open then
        if action == "left" then
            MenuScene.delete_dialog:move_left()
        elseif action == "right" then
            MenuScene.delete_dialog:move_right()
        elseif action == "confirm" then
            MenuScene.delete_dialog:select()
        elseif action == "cancel" then
            MenuScene.delete_dialog:close()
            MenuScene.delete_dialog = nil
        end
        return
    end

    -- Normal menu navigation
    if action == "up" then
        if MenuScene.selected_index > 1 then
            MenuScene.selected_index = MenuScene.selected_index - 1
        end

    elseif action == "down" then
        if MenuScene.selected_index < #MenuScene.collections then
            MenuScene.selected_index = MenuScene.selected_index + 1
        end

    elseif action == "confirm" then
        -- Browse selected collection
        local collection = MenuScene.collections[MenuScene.selected_index]
        if collection then
            Logger.info("Opening collection:", collection.name)
            SceneManager.switch_with_fade("browse", {collection = collection})
        end

    elseif action == "cancel" then
        -- ESC/B exits the app (we're on main menu)
        love.event.quit()

    elseif action == "delete" then
        -- Delete collection (X button)
        Logger.debug("Delete action triggered, dialog state:", MenuScene.delete_dialog and "exists" or "nil",
                     MenuScene.delete_dialog and MenuScene.delete_dialog.is_open or "n/a")
        MenuScene.delete_selected_collection()

    elseif action == "menu" or action == "filter" then
        -- M or TAB = New search
        SceneManager.switch_with_fade("search")
    end
end

-- Delete selected collection
function MenuScene.delete_selected_collection()
    Logger.debug("delete_selected_collection called, selected_index:", MenuScene.selected_index)
    local collection = MenuScene.collections[MenuScene.selected_index]

    if not collection then
        Logger.warn("No collection at index:", MenuScene.selected_index)
        return
    end

    Logger.debug("Attempting to delete collection:", collection.name, "id:", collection.id, "can_delete:", collection:can_delete())

    if not collection:can_delete() then
        Logger.warn("Cannot delete system collection:", collection.name)
        return
    end

    -- Capture collection details for the callback
    local collection_id = collection.id
    local collection_name = collection.name
    local deletion_index = MenuScene.selected_index

    -- Show confirmation dialog
    Logger.debug("Creating delete dialog for:", collection_name, "at index:", deletion_index)
    MenuScene.delete_dialog = Dialog.new({
        title = "Delete Collection",
        message = "Delete '" .. collection_name .. "'?\nThis cannot be undone.",
        type = Dialog.TYPE.CONFIRM,
        options = {"Yes", "No"},
        callback = function(choice)
            Logger.debug("Delete dialog callback - choice:", choice, "for collection:", collection_name)
            if choice == "yes" then
                local ok, err = CollectionManager.delete(collection_id)

                if not ok then
                    Logger.error("Failed to delete collection:", err)
                else
                    Logger.info("Deleted collection:", collection_name)

                    -- Reload collections
                    MenuScene.collections = CollectionManager.get_sorted()
                    Logger.debug("Reloaded collections, new count:", #MenuScene.collections)

                    -- Smart selection adjustment:
                    -- If we deleted the last item, move selection up
                    -- Otherwise keep selection at same index (which now shows next collection)
                    if deletion_index > #MenuScene.collections then
                        MenuScene.selected_index = math.max(1, #MenuScene.collections)
                        Logger.debug("Adjusted selected_index to:", MenuScene.selected_index)
                    else
                        -- Keep current index, but ensure it's valid
                        MenuScene.selected_index = math.min(deletion_index, #MenuScene.collections)
                        Logger.debug("Kept selected_index at:", MenuScene.selected_index)
                    end
                end
            end
            -- Clear dialog reference after processing
            Logger.debug("Clearing delete_dialog reference")
            MenuScene.delete_dialog = nil
        end
    })
    Logger.debug("Opening delete dialog")
    MenuScene.delete_dialog:open()
end

return MenuScene
