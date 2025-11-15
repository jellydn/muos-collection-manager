-- Input Handler
-- Constitution: III. Input Modularity (universal controller support)

local Logger = require("src.lib.logger")
local InputConfig = require("src.config.input_config")

local InputHandler = {}

-- Input state
InputHandler.actions = {}
InputHandler.repeat_delay = 0.3  -- seconds before first repeat
InputHandler.repeat_rate = 0.1   -- seconds between repeats
InputHandler.action_timers = {}

-- Initialize input handler
function InputHandler.init()
    for action, _ in pairs(InputConfig.ACTIONS) do
        InputHandler.actions[action] = false
        InputHandler.action_timers[action] = 0
    end
end

-- Update input state (for repeating actions)
function InputHandler.update(dt)
    for action, pressed in pairs(InputHandler.actions) do
        if pressed then
            InputHandler.action_timers[action] = InputHandler.action_timers[action] + dt
        end
    end
end

-- Check if action is pressed (fires once per press)
function InputHandler.is_pressed(action)
    return InputHandler.actions[action] and InputHandler.action_timers[action] == 0
end

-- Check if action is held down
function InputHandler.is_down(action)
    return InputHandler.actions[action] or false
end

-- Check if action is repeating (for held directional inputs)
function InputHandler.is_repeating(action)
    if not InputHandler.actions[action] then
        return false
    end

    local timer = InputHandler.action_timers[action]

    if timer > InputHandler.repeat_delay then
        -- After initial delay, check repeat rate
        local time_since_delay = timer - InputHandler.repeat_delay
        return (time_since_delay % InputHandler.repeat_rate) < 0.016  -- ~1 frame tolerance
    end

    return false
end

-- Handle keyboard press
function InputHandler.keypressed(key, scancode, isrepeat)
    local action = InputConfig.get_keyboard_action(key)

    if action then
        InputHandler.actions[action] = true
        InputHandler.action_timers[action] = 0
        Logger.debug("Key pressed:", key, "->", action)
        return action
    end

    return nil
end

-- Handle keyboard release
function InputHandler.keyreleased(key, scancode)
    local action = InputConfig.get_keyboard_action(key)

    if action then
        InputHandler.actions[action] = false
        InputHandler.action_timers[action] = 0
        Logger.debug("Key released:", key, "->", action)
        return action
    end

    return nil
end

-- Handle gamepad button press
function InputHandler.gamepadpressed(joystick, button)
    local action = InputConfig.get_gamepad_action(button)

    if action then
        InputHandler.actions[action] = true
        InputHandler.action_timers[action] = 0
        Logger.debug("Gamepad pressed:", button, "->", action)
        return action
    end

    return nil
end

-- Handle gamepad button release
function InputHandler.gamepadreleased(joystick, button)
    local action = InputConfig.get_gamepad_action(button)

    if action then
        InputHandler.actions[action] = false
        InputHandler.action_timers[action] = 0
        Logger.debug("Gamepad released:", button, "->", action)
        return action
    end

    return nil
end

-- Reset all input state
function InputHandler.reset()
    for action, _ in pairs(InputHandler.actions) do
        InputHandler.actions[action] = false
        InputHandler.action_timers[action] = 0
    end
end

return InputHandler
