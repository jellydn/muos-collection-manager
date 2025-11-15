-- muOS Collection Manager - Main Entry Point
-- Constitution: All 5 Principles (Performance, Resource, Input, Scene, Assets)

local Logger = require("src.lib.logger")
local Paths = require("src.config.paths")
local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local SceneManager = require("src.scenes.scene_manager")
local GameLibrary = require("src.services.game_library")
local SearchEngine = require("src.services.search_engine")

-- Global state
local app = {
    version = "0.1.0",
    fps_counter = {
        frames = 0,
        elapsed = 0,
        current_fps = 0
    }
}

-- Love2D: Initialization
function love.load()
    Logger.info("muOS Collection Manager v" .. app.version)
    Logger.info("Love2D version:", love.getVersion())
    
    -- Initialize configurations
    DisplayConfig.init()
    Logger.info(string.format("Display: %dx%d (%s)", DisplayConfig.width, DisplayConfig.height, DisplayConfig.aspect_ratio))
    
    -- Initialize paths (create directories if needed)
    Paths.init()
    Logger.info("Config directory:", Paths.config_dir)
    
    -- Initialize input handler
    InputHandler.init()
    Logger.info("Input handler initialized")
    
    -- Load game library
    Logger.info("Loading game library...")
    local start_time = love.timer.getTime()
    GameLibrary.load()
    local load_time = (love.timer.getTime() - start_time) * 1000
    Logger.info(string.format("Library loaded: %d games in %.2fms", #GameLibrary.games, load_time))
    
    -- Initialize search engine
    Logger.info("Initializing search engine...")
    SearchEngine.init(GameLibrary.games)
    
    -- Register scenes
    SceneManager.register("search", require("src.scenes.search_scene"))
    
    -- Start with search scene
    SceneManager.switch("search")
    
    Logger.info("Application initialized successfully")
end

-- Love2D: Update loop (60 FPS target)
function love.update(dt)
    -- Update FPS counter
    app.fps_counter.frames = app.fps_counter.frames + 1
    app.fps_counter.elapsed = app.fps_counter.elapsed + dt
    
    if app.fps_counter.elapsed >= 1.0 then
        app.fps_counter.current_fps = app.fps_counter.frames
        app.fps_counter.frames = 0
        app.fps_counter.elapsed = 0
        
        -- Log FPS warning if below 60
        if app.fps_counter.current_fps < 60 then
            Logger.warn(string.format("FPS drop: %d (target: 60)", app.fps_counter.current_fps))
        end
    end
    
    -- Update input handler (for repeat)
    InputHandler.update(dt)
    
    -- Update scene manager
    SceneManager.update(dt)
end

-- Love2D: Draw loop
function love.draw()
    -- Clear with background color
    love.graphics.clear(DisplayConfig.COLORS.background)
    
    -- Draw current scene
    SceneManager.draw()
    
    -- Draw FPS counter (debug)
    if Logger.current_level == Logger.LEVEL.DEBUG then
        love.graphics.setColor(DisplayConfig.COLORS.text)
        love.graphics.print(string.format("FPS: %d", app.fps_counter.current_fps), 10, 10)
        love.graphics.print(string.format("Games: %d", #GameLibrary.games), 10, 30)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Love2D: Keyboard input
function love.keypressed(key, scancode, isrepeat)
    -- Global shortcuts
    if key == "escape" then
        love.event.quit()
        return
    end
    
    -- Toggle debug mode
    if key == "f1" then
        if Logger.current_level == Logger.LEVEL.DEBUG then
            Logger.set_level(Logger.LEVEL.INFO)
            Logger.info("Debug mode OFF")
        else
            Logger.set_level(Logger.LEVEL.DEBUG)
            Logger.debug("Debug mode ON")
        end
        return
    end
    
    -- Forward to input handler
    InputHandler.keypressed(key, scancode, isrepeat)
    
    -- Forward to scene manager
    SceneManager.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    InputHandler.keyreleased(key, scancode)
    SceneManager.keyreleased(key, scancode)
end

-- Love2D: Gamepad input
function love.gamepadpressed(joystick, button)
    InputHandler.gamepadpressed(joystick, button)
    SceneManager.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    InputHandler.gamepadreleased(joystick, button)
    SceneManager.gamepadreleased(joystick, button)
end

-- Love2D: Quit handler
function love.quit()
    Logger.info("Application shutting down")
    return false  -- Allow quit
end
