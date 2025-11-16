-- Settings Scene for Game Vault
-- Constitution: IV. Scene Independence (independent, testable state)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local GameLibrary = require("src.services.game_library")

local SettingsScene = {}
SettingsScene.__index = SettingsScene

-- Create new settings scene
function SettingsScene.new()
    local self = setmetatable({}, SettingsScene)
    
    -- Scene state
    self.selected_index = 1
    self.menu_items = {
        { label = "Rescan Library", action = "rescan" },
        { label = "Clear Favorites", action = "clear_favorites" },
        { label = "About", action = "about" },
        { label = "Back to Menu", action = "back" }
    }
    
    return self
end

-- Initialize scene
function SettingsScene:load()
    Logger.info("Settings scene loaded")
end

-- Update scene (dt = delta time in seconds)
function SettingsScene:update(dt)
    -- Handle navigation
    if InputHandler.is_pressed("up") then
        self.selected_index = math.max(1, self.selected_index - 1)
    elseif InputHandler.is_pressed("down") then
        self.selected_index = math.min(#self.menu_items, self.selected_index + 1)
    end
    
    -- Handle selection
    if InputHandler.is_pressed("confirm") then
        self:handle_selection()
    end
    
    -- Back button
    if InputHandler.is_pressed("cancel") then
        self.parent:switch("menu")
        return
    end
end

-- Handle menu selection
function SettingsScene:handle_selection()
    local item = self.menu_items[self.selected_index]
    
    if item.action == "rescan" then
        Logger.info("Rescanning library...")
        GameLibrary.refresh()
        Logger.info("Rescan complete!")
    elseif item.action == "clear_favorites" then
        for _, game in ipairs(GameLibrary.games) do
            game.favorite = false
        end
        Logger.info("Favorites cleared")
    elseif item.action == "about" then
        Logger.info("Game Vault v0.1.0")
    elseif item.action == "back" then
        self.parent:switch("menu")
    end
end

-- Draw scene
function SettingsScene:draw()
    -- Background
    love.graphics.clear(DisplayConfig.COLORS.background)
    
    -- Title
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Settings", 20, 20)
    
    -- Menu items
    local item_y = 70
    local item_height = 40
    
    for i, item in ipairs(self.menu_items) do
        -- Highlight selected item
        if i == self.selected_index then
            love.graphics.setColor(DisplayConfig.COLORS.accent)
            love.graphics.rectangle("fill", 10, item_y - 5, DisplayConfig.width - 20, item_height)
            love.graphics.setColor(DisplayConfig.COLORS.bg_primary)
        else
            love.graphics.setColor(DisplayConfig.COLORS.text)
        end
        
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(item.label, 30, item_y)
        
        item_y = item_y + item_height
    end
    
    -- Footer with controls
    love.graphics.setColor(DisplayConfig.COLORS.text_secondary)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("A: Select  B: Back", 20, DisplayConfig.height - 40)
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
end

-- Input handlers (forwarded from SceneManager)
function SettingsScene:keypressed(key, scancode, isrepeat)
    -- Handled in update
end

function SettingsScene:keyreleased(key, scancode)
    -- Optional: handle specific key releases
end

function SettingsScene:gamepadpressed(joystick, button)
    -- Handled in update
end

function SettingsScene:gamepadreleased(joystick, button)
    -- Optional: handle specific button releases
end

return SettingsScene
