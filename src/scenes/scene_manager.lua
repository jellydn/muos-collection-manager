-- Scene Manager for Love2D
-- Constitution: IV. Scene Independence (independent testable states)

local Logger = require("src.lib.logger")

local SceneManager = {}

-- Current active scene
SceneManager.current_scene = nil
SceneManager.scenes = {}

-- Scene transition state
SceneManager.transition = {
    active = false,
    from_scene = nil,
    to_scene = nil,
    duration = 0.3,  -- 300ms transition
    elapsed = 0,
    fade_color = {0, 0, 0, 0}
}

-- Register a scene
function SceneManager.register(name, scene)
    SceneManager.scenes[name] = scene
    Logger.debug("Registered scene:", name)
end

-- Switch to a new scene
function SceneManager.switch(name, data)
    if not SceneManager.scenes[name] then
        Logger.error("Scene not found:", name)
        return false
    end

    Logger.info("Switching scene to:", name)

    -- Call exit on current scene
    if SceneManager.current_scene and SceneManager.current_scene.exit then
        SceneManager.current_scene:exit()
    end

    -- Set new scene
    SceneManager.current_scene = SceneManager.scenes[name]

    -- Call enter on new scene with optional data
    if SceneManager.current_scene.enter then
        SceneManager.current_scene:enter(data or {})
    end

    return true
end

-- Switch with fade transition
function SceneManager.switch_with_fade(name, data)
    if not SceneManager.scenes[name] then
        Logger.error("Scene not found:", name)
        return false
    end

    SceneManager.transition.active = true
    SceneManager.transition.from_scene = SceneManager.current_scene
    SceneManager.transition.to_scene = name
    SceneManager.transition.to_scene_data = data
    SceneManager.transition.elapsed = 0

    return true
end

-- Update current scene
function SceneManager.update(dt)
    -- Handle scene transition
    if SceneManager.transition.active then
        SceneManager.transition.elapsed = SceneManager.transition.elapsed + dt

        local progress = SceneManager.transition.elapsed / SceneManager.transition.duration

        if progress < 0.5 then
            -- Fade out
            local alpha = progress * 2
            SceneManager.transition.fade_color[4] = alpha
        else
            -- Switch scene at midpoint
            if SceneManager.transition.from_scene then
                SceneManager.switch(SceneManager.transition.to_scene, SceneManager.transition.to_scene_data)
                SceneManager.transition.from_scene = nil
            end

            -- Fade in
            local alpha = 1 - ((progress - 0.5) * 2)
            SceneManager.transition.fade_color[4] = alpha
        end

        if progress >= 1.0 then
            SceneManager.transition.active = false
            SceneManager.transition.fade_color[4] = 0
        end
    end

    -- Update current scene
    if SceneManager.current_scene and SceneManager.current_scene.update then
        SceneManager.current_scene.update(dt)
    end
end

-- Draw current scene
function SceneManager.draw()
    if SceneManager.current_scene and SceneManager.current_scene.draw then
        SceneManager.current_scene.draw()
    end

    -- Draw fade overlay if transitioning
    if SceneManager.transition.active and SceneManager.transition.fade_color[4] > 0 then
        love.graphics.setColor(SceneManager.transition.fade_color)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Forward input events to current scene
function SceneManager.keypressed(key, scancode, isrepeat)
    if SceneManager.current_scene and SceneManager.current_scene.keypressed then
        SceneManager.current_scene.keypressed(key, scancode, isrepeat)
    end
end

function SceneManager.keyreleased(key, scancode)
    if SceneManager.current_scene and SceneManager.current_scene.keyreleased then
        SceneManager.current_scene.keyreleased(key, scancode)
    end
end

function SceneManager.gamepadpressed(joystick, button)
    if SceneManager.current_scene and SceneManager.current_scene.gamepadpressed then
        SceneManager.current_scene.gamepadpressed(joystick, button)
    end
end

function SceneManager.gamepadreleased(joystick, button)
    if SceneManager.current_scene and SceneManager.current_scene.gamepadreleased then
        SceneManager.current_scene.gamepadreleased(joystick, button)
    end
end

return SceneManager
