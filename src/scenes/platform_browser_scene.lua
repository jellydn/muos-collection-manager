-- Platform Browser Scene
-- Displays list of gaming platforms with game counts
-- Allows navigation to browse games by platform

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local GameLibrary = require("src.services.game_library")
local SceneManager = require("src.scenes.scene_manager")

local PlatformBrowserScene = {}

-- Scene state
PlatformBrowserScene.platforms = {}
PlatformBrowserScene.selected_index = 1
PlatformBrowserScene.scroll_offset = 0

-- Visual constants
local ITEM_HEIGHT = 40
local ITEMS_PER_PAGE = 10

function PlatformBrowserScene.enter(data)
    Logger.info("Entering PlatformBrowserScene")
    
    -- Load platforms with game counts
    PlatformBrowserScene.platforms = GameLibrary.get_platforms()
    PlatformBrowserScene.selected_index = 1
    PlatformBrowserScene.scroll_offset = 0
    
    Logger.info("Loaded", #PlatformBrowserScene.platforms, "platforms with games")
end

function PlatformBrowserScene.exit()
    Logger.info("Exiting PlatformBrowserScene")
end

function PlatformBrowserScene.update(dt)
    -- No continuous updates needed
end

function PlatformBrowserScene.draw()
    local font = love.graphics.getFont()
    local screen_w = DisplayConfig.width
    local screen_h = DisplayConfig.height
    
    -- Header
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, screen_w, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Browse by Platform", 0, 20, screen_w, "center")
    
    -- Platform list
    local y_offset = 80
    local visible_start = math.floor(PlatformBrowserScene.scroll_offset / ITEM_HEIGHT) + 1
    local visible_end = math.min(visible_start + ITEMS_PER_PAGE, #PlatformBrowserScene.platforms)
    
    for i = visible_start, visible_end do
        local platform = PlatformBrowserScene.platforms[i]
        local y = y_offset + ((i - 1) * ITEM_HEIGHT) - PlatformBrowserScene.scroll_offset
        
        -- Selection highlight
        if i == PlatformBrowserScene.selected_index then
            love.graphics.setColor(0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", 20, y, screen_w - 40, ITEM_HEIGHT - 5)
        end
        
        -- Platform name and count
        love.graphics.setColor(1, 1, 1)
        local text = string.format("%s (%d games)", platform.display_name, platform.count)
        love.graphics.print(text, 30, y + 10)
    end
    
    -- Footer instructions
    love.graphics.setColor(0.5, 0.5, 0.5)
    local footer_y = screen_h - 30
    love.graphics.printf("A: Select  |  B: Back", 0, footer_y, screen_w, "center")
    
    -- Scrollbar indicator if needed
    if #PlatformBrowserScene.platforms > ITEMS_PER_PAGE then
        local scrollbar_h = (ITEMS_PER_PAGE / #PlatformBrowserScene.platforms) * (screen_h - 120)
        local scrollbar_y = 80 + (PlatformBrowserScene.scroll_offset / (#PlatformBrowserScene.platforms * ITEM_HEIGHT)) * (screen_h - 120)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("fill", screen_w - 10, scrollbar_y, 5, scrollbar_h)
    end
end

function PlatformBrowserScene.keypressed(key, scancode, isrepeat)
    local action = InputHandler.keypressed(key, scancode, isrepeat)
    if action then
        PlatformBrowserScene.handle_action(action)
    end
end

function PlatformBrowserScene.gamepadpressed(joystick, button)
    local action = InputHandler.gamepadpressed(joystick, button)
    if action then
        PlatformBrowserScene.handle_action(action)
    end
end

function PlatformBrowserScene.handle_action(action)
    -- Navigation
    if action == "up" then
        if PlatformBrowserScene.selected_index > 1 then
            PlatformBrowserScene.selected_index = PlatformBrowserScene.selected_index - 1
            
            -- Auto-scroll
            local item_y = (PlatformBrowserScene.selected_index - 1) * ITEM_HEIGHT
            
            if item_y < PlatformBrowserScene.scroll_offset then
                PlatformBrowserScene.scroll_offset = item_y
            end
            
            Logger.info("Platform selection moved UP to:", PlatformBrowserScene.selected_index, "/", #PlatformBrowserScene.platforms)
        end
        
    elseif action == "down" then
        if PlatformBrowserScene.selected_index < #PlatformBrowserScene.platforms then
            PlatformBrowserScene.selected_index = PlatformBrowserScene.selected_index + 1
            
            -- Auto-scroll
            local item_y = (PlatformBrowserScene.selected_index - 1) * ITEM_HEIGHT
            local screen_h = DisplayConfig.height
            local visible_bottom = PlatformBrowserScene.scroll_offset + (screen_h - 120)
            
            if item_y + ITEM_HEIGHT > visible_bottom then
                PlatformBrowserScene.scroll_offset = item_y - (screen_h - 120) + ITEM_HEIGHT
            end
            
            Logger.info("Platform selection moved DOWN to:", PlatformBrowserScene.selected_index, "/", #PlatformBrowserScene.platforms)
        end
        
    elseif action == "confirm" then
        -- Select platform - navigate to browse scene with filtered games
        if PlatformBrowserScene.platforms[PlatformBrowserScene.selected_index] then
            local selected_platform = PlatformBrowserScene.platforms[PlatformBrowserScene.selected_index]
            Logger.info("Opening platform:", selected_platform.display_name, "(" .. selected_platform.system .. ")")
            
            SceneManager.switch("browse", {
                collection = {
                    name = selected_platform.display_name,
                    system_filter = selected_platform.system,
                    is_platform_view = true
                }
            })
        end
        
    elseif action == "cancel" then
        -- Back to menu
        SceneManager.switch("menu")
    end
end

return PlatformBrowserScene
