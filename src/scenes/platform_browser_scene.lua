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
PlatformBrowserScene.item_height = 50  -- Match MenuScene item height

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
    -- Keep selected item in view (smooth scrolling like MenuScene)
    local viewport_height = DisplayConfig.height - 150  -- Account for header and footer
    local target_y = (PlatformBrowserScene.selected_index - 1) * PlatformBrowserScene.item_height
    
    local min_scroll = target_y - viewport_height + PlatformBrowserScene.item_height
    local max_scroll = target_y
    
    if PlatformBrowserScene.scroll_offset < min_scroll then
        PlatformBrowserScene.scroll_offset = min_scroll
    elseif PlatformBrowserScene.scroll_offset > max_scroll then
        PlatformBrowserScene.scroll_offset = max_scroll
    end
    
    -- Clamp scroll
    local max_offset = math.max(0, #PlatformBrowserScene.platforms * PlatformBrowserScene.item_height - viewport_height)
    PlatformBrowserScene.scroll_offset = math.max(0, math.min(max_offset, PlatformBrowserScene.scroll_offset))
end

function PlatformBrowserScene.draw()
    local screen_w = DisplayConfig.width
    local screen_h = DisplayConfig.height
    
    -- Draw title (matching MenuScene style)
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_large))
    love.graphics.print("Browse by Platform", DisplayConfig.SIZES.margin, DisplayConfig.SIZES.margin)
    love.graphics.setFont(love.graphics.newFont(DisplayConfig.SIZES.font_size_medium))
    
    -- Platform list with virtual rendering (viewport culling for performance)
    local start_y = DisplayConfig.SIZES.margin + 40
    local margin = DisplayConfig.SIZES.margin
    local width = screen_w - margin * 2
    
    love.graphics.setScissor(margin, start_y, width, screen_h - start_y - 60)
    
    -- Calculate visible range based on scroll position
    local visible_start = math.max(1, math.floor(PlatformBrowserScene.scroll_offset / PlatformBrowserScene.item_height))
    local visible_end = math.min(#PlatformBrowserScene.platforms, 
                                 math.ceil((PlatformBrowserScene.scroll_offset + screen_h - 140) / PlatformBrowserScene.item_height) + 1)
    
    -- Only render visible items (virtual list for performance with 100+ platforms)
    for i = visible_start, visible_end do
        local platform = PlatformBrowserScene.platforms[i]
        local y = start_y + (i - 1) * PlatformBrowserScene.item_height - PlatformBrowserScene.scroll_offset
        local is_selected = (i == PlatformBrowserScene.selected_index)
        
        -- Draw background
        if is_selected then
            love.graphics.setColor(DisplayConfig.COLORS.primary)
        else
            love.graphics.setColor(DisplayConfig.COLORS.surface)
        end
        love.graphics.rectangle("fill", margin, y, width, PlatformBrowserScene.item_height - 4, 4, 4)
        
        -- Draw border
        love.graphics.setColor(DisplayConfig.COLORS.secondary)
        love.graphics.rectangle("line", margin, y, width, PlatformBrowserScene.item_height - 4, 4, 4)
        
        -- Platform name and count
        if is_selected then
            love.graphics.setColor(DisplayConfig.COLORS.background)
        else
            love.graphics.setColor(DisplayConfig.COLORS.text)
        end
        
        local text = string.format("%s (%d games)", platform.display_name, platform.count)
        love.graphics.print(text, margin + 10, y + 12)
    end
    
    love.graphics.setScissor()
    
    -- Draw help text (matching MenuScene footer)
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help_y = screen_h - DisplayConfig.SIZES.font_size_small - DisplayConfig.SIZES.margin
    love.graphics.print("A: Browse | B: Back", DisplayConfig.SIZES.margin, help_y)
    love.graphics.setColor(1, 1, 1, 1)
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
            Logger.info("Platform selection moved UP to:", PlatformBrowserScene.selected_index, "/", #PlatformBrowserScene.platforms)
        end
        
    elseif action == "down" then
        if PlatformBrowserScene.selected_index < #PlatformBrowserScene.platforms then
            PlatformBrowserScene.selected_index = PlatformBrowserScene.selected_index + 1
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
