-- MenuScene - List all collections
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local CollectionManager = require("src.services.collection_manager")
local SceneManager = require("src.scenes.scene_manager")

local MenuScene = {}

-- Scene state
MenuScene.collections = {}
MenuScene.selected_index = 1
MenuScene.scroll_offset = 0
MenuScene.item_height = 50

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
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_normal))

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
            name = "★ " .. name  -- Star for system collections
        end

        love.graphics.print(name, margin + 10, y + 15)

        -- Draw filter count
        local filter_count = #collection.filters
        local filter_text = filter_count .. " filter" .. (filter_count ~= 1 and "s" or "")
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        love.graphics.print(filter_text, margin + 10, y + 30)
    end

    love.graphics.setScissor()

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    love.graphics.print("A: Browse | B: Back | X: Delete | Y: New Search", DisplayConfig.SIZES.margin, help_y)
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
        -- Go to search scene
        SceneManager.switch_with_fade("search")

    elseif action == "filter" then
        -- Delete collection (X button)
        MenuScene.delete_selected_collection()

    elseif action == "menu" then
        -- New search (Y button)
        SceneManager.switch_with_fade("search")
    end
end

-- Delete selected collection
function MenuScene.delete_selected_collection()
    local collection = MenuScene.collections[MenuScene.selected_index]

    if not collection then
        return
    end

    if not collection:can_delete() then
        Logger.warn("Cannot delete system collection:", collection.name)
        return
    end

    -- Confirm deletion (TODO: add confirmation dialog)
    local ok, err = CollectionManager.delete(collection.id)

    if not ok then
        Logger.error("Failed to delete collection:", err)
        return
    end

    Logger.info("Deleted collection:", collection.name)

    -- Reload collections
    MenuScene.collections = CollectionManager.get_sorted()

    -- Adjust selection
    if MenuScene.selected_index > #MenuScene.collections then
        MenuScene.selected_index = math.max(1, #MenuScene.collections)
    end
end

return MenuScene
