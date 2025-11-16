-- Input configuration for muOS devices
-- Constitution: III. Input Modularity (universal controller support)

local InputConfig = {}

-- Button mappings for muOS devices (SNES-style layout common on RG35XX, Anbernic)
-- These map Love2D joystick/keyboard inputs to logical actions
InputConfig.ACTIONS = {
    UP = "up",
    DOWN = "down",
    LEFT = "left",
    RIGHT = "right",
    CONFIRM = "confirm",      -- A button
    CANCEL = "cancel",        -- B button
    MENU = "menu",            -- START button
    FILTER = "filter",        -- SELECT button
    FAVORITE = "favorite",    -- Y button
    DELETE = "delete",        -- X button
    SHOULDER_L = "shoulder_l", -- L button
    SHOULDER_R = "shoulder_r"  -- R button
}

-- Keyboard mappings (for development/testing on Mac)
InputConfig.keyboard = {
    -- Arrow keys for navigation
    up = "up",
    down = "down",
    left = "left",
    right = "right",
    
    -- Primary actions
    ["return"] = "confirm",      -- Enter = A button (confirm)
    space = "confirm",           -- Space = A button (confirm alternative)
    escape = "cancel",           -- ESC = B button (back/cancel)
    b = "cancel",                -- B = B button (back/cancel alternative)
    
    -- Menu actions
    m = "menu",                  -- M = START button (menu)
    tab = "filter",              -- Tab = SELECT button (filter panel)
    l = "shoulder_l",            -- L = L shoulder (filter panel)
    r = "shoulder_r",            -- R = R shoulder (AND/OR toggle)
    
    -- Additional actions
    f = "favorite",              -- F = Y button (favorite)
    y = "favorite",              -- Y = Y button (favorite alternative)
    x = "delete",                -- X = X button (delete)
    backspace = "delete",        -- Backspace = delete alternative
    
    -- Number keys for quick selection (1-9)
    ["1"] = "quick_select_1",
    ["2"] = "quick_select_2",
    ["3"] = "quick_select_3",
    ["4"] = "quick_select_4",
    ["5"] = "quick_select_5",
    
    -- Debug/testing keys
    f1 = "debug_toggle",         -- F1 = toggle debug mode
    f2 = "fps_toggle",           -- F2 = toggle FPS counter
    f5 = "refresh",              -- F5 = refresh library
}

-- Gamepad button mappings (Xbox/PS controller layout)
-- Love2D uses SDL game controller mapping
InputConfig.gamepad = {
    dpup = "up",
    dpdown = "down",
    dpleft = "left",
    dpright = "right",
    a = "confirm",           -- A (Xbox) / X (PS)
    b = "cancel",            -- B (Xbox) / Circle (PS)
    start = "menu",
    back = "filter",         -- Back/Select
    y = "favorite",          -- Y (Xbox) / Triangle (PS)
    x = "delete",            -- X (Xbox) / Square (PS)
    leftshoulder = "shoulder_l",
    rightshoulder = "shoulder_r"
}

-- muOS specific button mappings (may vary by device)
-- This is a fallback for custom muOS button configurations
InputConfig.muos = {
    -- D-pad
    [0] = "up",
    [1] = "down",
    [2] = "left",
    [3] = "right",
    -- Face buttons (SNES layout: A/B/X/Y)
    [4] = "cancel",          -- B
    [5] = "confirm",         -- A
    [6] = "delete",          -- X
    [7] = "favorite",        -- Y
    -- Shoulders
    [8] = "shoulder_l",      -- L
    [9] = "shoulder_r",      -- R
    -- Start/Select
    [10] = "filter",         -- SELECT
    [11] = "menu"            -- START
}

-- Get action from keyboard key
function InputConfig.get_keyboard_action(key)
    return InputConfig.keyboard[key]
end

-- Get action from gamepad button
function InputConfig.get_gamepad_action(button)
    return InputConfig.gamepad[button]
end

-- Get action from muOS button index
function InputConfig.get_muos_action(button_index)
    return InputConfig.muos[button_index]
end

-- Check if action is directional
function InputConfig.is_directional(action)
    return action == "up" or action == "down" or action == "left" or action == "right"
end

return InputConfig
