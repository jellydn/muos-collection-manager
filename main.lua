-- Game Vault - Main Entry Point
-- Constitution: All 5 Principles (Performance, Resource, Input, Scene, Assets)

-- Early module loading (before Logger is available, use print)
print("[EARLY] Starting main.lua - Loading Logger...")
local Logger = require("src.lib.logger")

-- Now use Logger for all subsequent loading
Logger.info("Loading Paths...")
local Paths = require("src.config.paths")

Logger.info("Loading DisplayConfig...")
local DisplayConfig = require("src.config.display_config")

Logger.info("Loading InputHandler...")
local InputHandler = require("src.ui.input_handler")

Logger.info("Loading SceneManager...")
local SceneManager = require("src.scenes.scene_manager")

Logger.info("Loading GameLibrary...")
local GameLibrary = require("src.services.game_library")

Logger.info("Loading SearchEngine...")
local SearchEngine = require("src.services.search_engine")

Logger.info("Loading CollectionManager...")
local CollectionManager = require("src.services.collection_manager")

Logger.info("Loading Profiler...")
local Profiler = require("src.lib.profiler")

Logger.info("All modules loaded successfully")

-- Global state
local app = {
	version = "0.1.0",
	is_loading = true,
	loading_step = 0,
	fps_counter = {
		frames = 0,
		elapsed = 0,
		current_fps = 0,
	},
	memory_usage = {
		last_check = 0,
		current_mb = 0,
		peak_mb = 0,
	},
}

-- Loading scene reference (loaded early)
local LoadingScene = nil

-- Love2D: Initialization
function love.load()
	-- Logger is already loaded at module level
	Logger.debug("love.load() started")

	-- Initialize basic systems first
	Logger.info("Game Vault v" .. app.version)
	Logger.info("Love2D version:", love.getVersion())

	-- Initialize display config
	DisplayConfig.init()
	Logger.info(
		string.format("Display: %dx%d (%s)", DisplayConfig.width, DisplayConfig.height, DisplayConfig.aspect_ratio)
	)

	-- Load and show loading scene immediately
	LoadingScene = require("src.scenes.loading_scene")
	LoadingScene.init()
	LoadingScene.set_progress(0, 6, "Initializing", "Setting up...")

	-- Force an immediate draw to show the loading screen
	love.graphics.clear(DisplayConfig.COLORS.background)
	LoadingScene.draw()
	love.graphics.present()

	Logger.info("Loading scene displayed")
end

-- Deferred initialization function (called from update loop)
local function complete_initialization()
	local success, err = pcall(function()
		-- Step 1: Initialize paths
		LoadingScene.set_progress(1, 6, "Initializing", "Setting up directories...")
		Paths.init()
		Logger.info("Config directory:", Paths.config_dir)

		-- Step 2: Initialize input handler
		LoadingScene.set_progress(2, 6, "Initializing", "Configuring controls...")
		InputHandler.init()
		Logger.info("Input handler initialized")

		-- Step 3: Load game library (this is the slow part)
		LoadingScene.set_progress(3, 6, "Loading Games", "Scanning ROM directory...")
		Logger.info("Loading game library...")
		local start_time = love.timer.getTime()

		-- Progress callback for ROM scanning
		local progress_callback = function(roms_found, files_scanned, message)
			LoadingScene.set_progress(3, 6, "Loading Games",
				string.format("Found %d ROMs (%d files scanned)", roms_found, files_scanned))
			-- Force screen update to show progress
			love.graphics.clear(DisplayConfig.COLORS.background)
			LoadingScene.draw()
			love.graphics.present()
		end

		GameLibrary.load(progress_callback)
		local load_time = (love.timer.getTime() - start_time) * 1000
		Logger.info(string.format("Library loaded: %d games in %.2fms", #GameLibrary.games, load_time))

		-- Step 4: Initialize search engine
		LoadingScene.set_progress(4, 6, "Indexing", "Building search index...")
		Logger.info("Initializing search engine...")
		SearchEngine.init(GameLibrary.games)

		-- Step 5: Initialize collection manager
		LoadingScene.set_progress(5, 6, "Loading Collections", "Loading saved collections...")
		Logger.info("Initializing collection manager...")
		Logger.debug("About to call CollectionManager.init()...")

		CollectionManager.init()

		Logger.debug("CollectionManager.init() completed")
		Logger.info("CollectionManager initialized successfully")

		-- Step 6: Register scenes
		LoadingScene.set_progress(6, 6, "Finalizing", "Preparing interface...")
		Logger.info("Registering scenes...")
		Logger.debug("About to register scenes...")

		SceneManager.register("search", require("src.scenes.search_scene"))
		Logger.debug("Registered search_scene")

		SceneManager.register("create_collection", require("src.scenes.create_collection_scene"))
		Logger.debug("Registered create_collection_scene")

		SceneManager.register("menu", require("src.scenes.menu_scene"))
		Logger.debug("Registered menu_scene")

		SceneManager.register("browse", require("src.scenes.browse_scene"))
		Logger.debug("Registered browse_scene")

		SceneManager.register("loading", LoadingScene)
		Logger.debug("Registered loading_scene")

		Logger.info("All scenes registered successfully")

		-- Start with collections menu (default screen)
		Logger.info("Switching to menu scene...")
		Logger.debug("About to switch to menu scene...")

		SceneManager.switch("menu")

		Logger.debug("SceneManager.switch() completed")

		-- Mark loading as complete
		app.is_loading = false
		Logger.info("Application initialized successfully")
		Logger.debug("Initialization complete!")
	end) -- End of pcall

	if not success then
		Logger.error("Failed to initialize application:", err)
		Logger.error(debug.traceback())
		-- Show error on loading screen
		LoadingScene.set_progress(0, 1, "Error", tostring(err))
		app.is_loading = false
	end
end

-- Love2D: Update loop (60 FPS target)
function love.update(dt)
	-- If still loading, run initialization steps
	if app.is_loading then
		-- Update loading scene animation
		LoadingScene.update(dt)

		-- Run initialization on first update frame
		if app.loading_step == 0 then
			app.loading_step = 1
			complete_initialization()
		end
		return
	end

	Profiler.start_timer("frame_update")

	-- Update FPS counter
	app.fps_counter.frames = app.fps_counter.frames + 1
	app.fps_counter.elapsed = app.fps_counter.elapsed + dt

	if app.fps_counter.elapsed >= 1.0 then
		app.fps_counter.current_fps = app.fps_counter.frames
		app.fps_counter.frames = 0
		app.fps_counter.elapsed = 0

		-- Only warn on significant FPS drops (below 50 FPS)
		if app.fps_counter.current_fps < 50 then
			Logger.warn(string.format("FPS drop: %d (target: 60)", app.fps_counter.current_fps))
		end

		-- Update memory usage stats
		local mem_kb = collectgarbage("count")
		app.memory_usage.current_mb = mem_kb / 1024
		if app.memory_usage.current_mb > app.memory_usage.peak_mb then
			app.memory_usage.peak_mb = app.memory_usage.current_mb
		end

		-- Log memory warning if approaching limit (>200MB)
		if app.memory_usage.current_mb > 200 then
			Logger.warn(
				string.format(
					"Memory usage: %.2f MB (peak: %.2f MB)",
					app.memory_usage.current_mb,
					app.memory_usage.peak_mb
				)
			)
		end

		-- Check memory with profiler
		Profiler.check_memory(200)
	end

	-- Update input handler (for repeat)
	InputHandler.update(dt)

	-- Update scene manager
	SceneManager.update(dt)

	Profiler.end_timer("frame_update", 16) -- 60 FPS = 16.67ms threshold
end

-- Love2D: Draw loop
function love.draw()
	-- If still loading, show loading screen
	if app.is_loading then
		LoadingScene.draw()
		return
	end

	Profiler.start_timer("frame_draw")

	-- Clear with background color
	love.graphics.clear(DisplayConfig.COLORS.background)

	-- Draw current scene
	SceneManager.draw()

	-- Draw FPS counter and stats (debug)
	if Logger.current_level == Logger.LEVEL.DEBUG then
		love.graphics.setColor(DisplayConfig.COLORS.text)
		love.graphics.print(string.format("FPS: %d", app.fps_counter.current_fps), 10, 10)
		love.graphics.print(string.format("Games: %d", #GameLibrary.games), 10, 30)
		love.graphics.print(
			string.format("Memory: %.2f MB (peak: %.2f MB)", app.memory_usage.current_mb, app.memory_usage.peak_mb),
			10,
			50
		)
	end

	-- Reset color
	love.graphics.setColor(1, 1, 1, 1)

	Profiler.end_timer("frame_draw", 16) -- 60 FPS = 16.67ms threshold
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
			Profiler.set_enabled(false)
			Logger.info("Debug mode OFF")
		else
			Logger.set_level(Logger.LEVEL.DEBUG)
			Profiler.set_enabled(true)
			Logger.debug("Debug mode ON")
		end
		return
	end

	-- Print profiler summary
	if key == "f2" then
		Profiler.print_summary()
		return
	end

	-- Quit with SELECT+START (hold both buttons - common on handhelds)
	-- Check this before passing to input handler
	if InputHandler.is_down("filter") and InputHandler.is_down("menu") then
		Logger.info("Quit requested (SELECT+START held)")
		love.event.quit()
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
	return false -- Allow quit
end
