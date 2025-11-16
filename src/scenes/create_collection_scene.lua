-- CreateCollectionScene - Name input and save collection
-- Constitution: IV. Scene Independence (isolated state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local CollectionManager = require("src.services.collection_manager")
local SearchBar = require("src.ui.search_bar")
local OnScreenKeyboard = require("src.ui.keyboard")
local SceneManager = require("src.scenes.scene_manager")

local CreateCollectionScene = {}

-- Scene state
CreateCollectionScene.name_input = nil
CreateCollectionScene.keyboard = nil
CreateCollectionScene.filters = nil  -- Filters to save with collection
CreateCollectionScene.error_message = nil
CreateCollectionScene.keyboard_mode = true

-- Enter scene
-- @param data table: {filters = SearchFilter[]} - filters to save
function CreateCollectionScene.enter(data)
    Logger.info("Entering CreateCollectionScene")
    Logger.info("  -> data received:", data and "yes" or "no")
    if data then
        Logger.info("  -> data.filters:", data.filters and #data.filters or "nil")
    end

    CreateCollectionScene.filters = (data and data.filters) or {}
    CreateCollectionScene.error_message = nil

    Logger.info("CreateCollectionScene initialized with", #CreateCollectionScene.filters, "filters")

    -- Initialize UI components
    local margin = DisplayConfig.SIZES.margin
    local width = DisplayConfig.width - margin * 2

    -- Name input at top
    CreateCollectionScene.name_input = SearchBar.new(margin, margin + 40, width)
    CreateCollectionScene.name_input:set_focus(true)
    CreateCollectionScene.name_input.placeholder = "Enter collection name..."

    -- On-screen keyboard below input
    local keyboard_y = margin + 40 + CreateCollectionScene.name_input.height + margin
    local keyboard_height = 200
    CreateCollectionScene.keyboard = OnScreenKeyboard.new(margin, keyboard_y, width, keyboard_height)
    CreateCollectionScene.keyboard:show()
    CreateCollectionScene.keyboard_mode = true

    Logger.info("CreateCollectionScene initialized with", #CreateCollectionScene.filters, "filters")
end

-- Exit scene
function CreateCollectionScene.exit()
    Logger.info("Exiting CreateCollectionScene")
    CreateCollectionScene.name_input = nil
    CreateCollectionScene.keyboard = nil
    CreateCollectionScene.filters = nil
    CreateCollectionScene.error_message = nil
end

-- Update scene
function CreateCollectionScene.update(dt)
    if CreateCollectionScene.name_input then
        CreateCollectionScene.name_input:update(dt)
    end

    if CreateCollectionScene.keyboard and CreateCollectionScene.keyboard:is_visible() then
        CreateCollectionScene.keyboard:update(dt)
    end
end

-- Draw scene
function CreateCollectionScene.draw()
    -- Draw title
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_large))
    love.graphics.print("Create Collection", DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_medium))

    -- Draw name input
    if CreateCollectionScene.name_input then
        CreateCollectionScene.name_input:draw()
    end

    -- Draw keyboard
    if CreateCollectionScene.keyboard and CreateCollectionScene.keyboard:is_visible() then
        CreateCollectionScene.keyboard:draw()
    end

    -- Draw error message if present
    if CreateCollectionScene.error_message then
        love.graphics.setColor(DisplayConfig.COLORS.warning)
        local error_y = DisplayConfig.height - 100
        love.graphics.print(CreateCollectionScene.error_message, DisplayConfig.SIZES.margin, error_y)
    end

    -- Draw help text
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = DisplayConfig.height - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    if CreateCollectionScene.keyboard_mode then
        love.graphics.print("A: Type | B: Cancel | SELECT: Hide Keyboard | START: Save", DisplayConfig.SIZES.margin, help_y)
    else
        love.graphics.print("A/START: Save | B: Cancel | SELECT: Show Keyboard", DisplayConfig.SIZES.margin, help_y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle keyboard input
function CreateCollectionScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)

    if not action then
        -- Handle text input
        if not CreateCollectionScene.keyboard_mode and key:len() == 1 then
            CreateCollectionScene.name_input:add_char(key)
        elseif key == "backspace" and not CreateCollectionScene.keyboard_mode then
            CreateCollectionScene.name_input:backspace()
        end
        return
    end

    CreateCollectionScene.handle_action(action)
end

-- Handle gamepad input
function CreateCollectionScene.gamepadpressed(joystick, button)
    local action = InputHandler.gamepadpressed(joystick, button)
    if action then
        CreateCollectionScene.handle_action(action)
    end
end

-- Handle logical action
function CreateCollectionScene.handle_action(action)
    if action == "filter" then
        -- Toggle keyboard
        CreateCollectionScene.keyboard:toggle()
        CreateCollectionScene.keyboard_mode = CreateCollectionScene.keyboard:is_visible()

    elseif action == "cancel" then
        -- Go back to SearchScene
        SceneManager.switch_with_fade("search")

    elseif action == "confirm" then
        if CreateCollectionScene.keyboard_mode then
            -- Select key on keyboard
            local key = CreateCollectionScene.keyboard:get_selected_key()
            if key == "DEL" then
                CreateCollectionScene.name_input:backspace()
            elseif key == "CAPS" then
                -- Toggle shift mode
                CreateCollectionScene.keyboard:toggle_shift()
            else
                CreateCollectionScene.name_input:add_char(key)
            end
        else
            -- Save collection
            CreateCollectionScene.save_collection()
        end

    elseif action == "menu" then
        -- Also save on menu button (A button)
        CreateCollectionScene.save_collection()

    elseif action == "up" then
        if CreateCollectionScene.keyboard_mode then
            CreateCollectionScene.keyboard:move_up()
        end

    elseif action == "down" then
        if CreateCollectionScene.keyboard_mode then
            CreateCollectionScene.keyboard:move_down()
        end

    elseif action == "left" then
        if CreateCollectionScene.keyboard_mode then
            CreateCollectionScene.keyboard:move_left()
        end

    elseif action == "right" then
        if CreateCollectionScene.keyboard_mode then
            CreateCollectionScene.keyboard:move_right()
        end
    end
end

-- Save collection
function CreateCollectionScene.save_collection()
    local name = CreateCollectionScene.name_input:get_query()

    if name == "" then
        CreateCollectionScene.error_message = "Please enter a collection name"
        Logger.warn("Cannot save collection: empty name")
        return
    end

    -- Create collection
    local collection, err = CollectionManager.create(name, CreateCollectionScene.filters, "AND")

    if not collection then
        CreateCollectionScene.error_message = "Error: " .. tostring(err)
        Logger.error("Failed to create collection:", err)
        return
    end

    Logger.info("Collection created:", collection.name)

    -- Go back to search scene
    SceneManager.switch_with_fade("search")
end

return CreateCollectionScene
