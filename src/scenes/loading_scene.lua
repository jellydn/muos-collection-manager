-- Loading Scene
-- Constitution: IV. Scene Management (loading screen with progress)
-- Note: This scene must work before DisplayConfig is initialized

local LoadingScene = {}

-- Scene state
local state = {
	message = "Loading...",
	progress = 0,
	max_progress = 100,
	details = "",
	dots = "",
	dots_timer = 0,
	dots_interval = 0.3, -- Update every 300ms
}

-- Initialize scene
function LoadingScene.init()
	state.message = "Loading..."
	state.progress = 0
	state.max_progress = 100
	state.details = ""
	state.dots = ""
	state.dots_timer = 0
end

-- Update progress
function LoadingScene.set_progress(current, max, message, details)
	state.progress = current or state.progress
	state.max_progress = max or state.max_progress
	state.message = message or state.message
	state.details = details or ""
end

-- Update loop
function LoadingScene.update(dt)
	-- Animate dots
	state.dots_timer = state.dots_timer + dt
	if state.dots_timer >= state.dots_interval then
		state.dots_timer = 0
		local dot_count = #state.dots
		if dot_count >= 3 then
			state.dots = ""
		else
			state.dots = state.dots .. "."
		end
	end
end

-- Draw loop
function LoadingScene.draw()
	-- Use fallback values (DisplayConfig may not be initialized yet)
	local width, height = love.graphics.getDimensions()
	local font = love.graphics.getFont()

	-- Hardcoded colors (safe to use before DisplayConfig init)
	local COLORS = {
		background = {0.1, 0.1, 0.1, 1},
		text = {1, 1, 1, 1},
		text_dim = {0.6, 0.6, 0.6, 1},
		panel = {0.2, 0.2, 0.2, 1},
		accent = {0.3, 0.6, 0.9, 1}
	}

	-- Background
	love.graphics.setColor(unpack(COLORS.background))
	love.graphics.rectangle("fill", 0, 0, width, height)

	-- Title
	love.graphics.setColor(unpack(COLORS.text))
	local title = "Game Vault"
	local title_width = font:getWidth(title)
	love.graphics.print(title, (width - title_width) / 2, height / 2 - 60)

	-- Loading message with animated dots
	love.graphics.setColor(unpack(COLORS.text_dim))
	local message = state.message .. state.dots
	local msg_width = font:getWidth(message)
	love.graphics.print(message, (width - msg_width) / 2, height / 2 - 20)

	-- Progress bar
	if state.max_progress > 0 then
		local bar_width = 400
		local bar_height = 20
		local bar_x = (width - bar_width) / 2
		local bar_y = height / 2 + 20

		-- Background
		love.graphics.setColor(unpack(COLORS.panel))
		love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

		-- Progress fill
		local progress_ratio = math.min(state.progress / state.max_progress, 1.0)
		local fill_width = bar_width * progress_ratio
		love.graphics.setColor(unpack(COLORS.accent))
		love.graphics.rectangle("fill", bar_x, bar_y, fill_width, bar_height)

		-- Border
		love.graphics.setColor(unpack(COLORS.text_dim))
		love.graphics.rectangle("line", bar_x, bar_y, bar_width, bar_height)

		-- Progress text
		local progress_text = string.format("%d / %d", state.progress, state.max_progress)
		local progress_width = font:getWidth(progress_text)
		love.graphics.setColor(unpack(COLORS.text))
		love.graphics.print(progress_text, (width - progress_width) / 2, bar_y + bar_height + 10)
	end

	-- Details
	if state.details and #state.details > 0 then
		love.graphics.setColor(unpack(COLORS.text_dim))
		local details_width = font:getWidth(state.details)
		love.graphics.print(state.details, (width - details_width) / 2, height / 2 + 80)
	end

	-- Reset color
	love.graphics.setColor(1, 1, 1, 1)
end

-- Input handlers (no input during loading)
function LoadingScene.keypressed(key, scancode, isrepeat) end
function LoadingScene.keyreleased(key, scancode) end
function LoadingScene.gamepadpressed(joystick, button) end
function LoadingScene.gamepadreleased(joystick, button) end

return LoadingScene
