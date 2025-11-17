-- Display configuration for muOS devices
-- Constitution: II. Resource Efficiency (optimized for embedded displays)

local DisplayConfig = {}
-- Common muOS display resolutions
DisplayConfig.RESOLUTIONS = {
    RG35XX = {width = 640, height = 480, aspect = "4:3"},
    RG35XX_PLUS = {width = 640, height = 480, aspect = "4:3"},
    RG353P = {width = 640, height = 480, aspect = "4:3"},
    ANBERNIC_351V = {width = 640, height = 480, aspect = "4:3"},
    MIYOO_MINI = {width = 320, height = 240, aspect = "4:3"},
    TRIMUI_SMART_PRO = {width = 1280, height = 720, aspect = "16:9"},
    TRIMUI_BRICK = {width = 1280, height = 720, aspect = "16:9"}
}

-- Current display settings (detected at runtime)
DisplayConfig.width = 640
DisplayConfig.height = 480
DisplayConfig.scale = 1.0
DisplayConfig.aspect_ratio = "4:3"

-- Original sizes before scaling (preserved for re-initialization)
DisplayConfig.SIZES_ORIGINAL = {
    grid_item_width = 64,
    grid_item_height = 64,
    font_size_small = 12,
    font_size_medium = 16,
    font_size_large = 24,
    padding = 8,
    margin = 16
}

-- UI element sizes (scaled based on resolution)
DisplayConfig.SIZES = {}

-- Colors (palette optimized for low-res displays)
DisplayConfig.COLORS = {
    background = {0.1, 0.1, 0.1, 1.0},
    surface = {0.15, 0.15, 0.15, 1.0},
    primary = {0.2, 0.6, 1.0, 1.0},
    secondary = {0.4, 0.4, 0.4, 1.0},
    text = {1.0, 1.0, 1.0, 1.0},
    text_dim = {0.7, 0.7, 0.7, 1.0},
    success = {0.2, 0.8, 0.2, 1.0},
    warning = {1.0, 0.8, 0.0, 1.0},
    error = {1.0, 0.2, 0.2, 1.0}
}

-- Initialize display config from Love2D window
function DisplayConfig.init()
    DisplayConfig.width = love.graphics.getWidth()
    DisplayConfig.height = love.graphics.getHeight()

    -- Calculate aspect ratio
    local ratio = DisplayConfig.width / DisplayConfig.height
    if math.abs(ratio - 4/3) < 0.01 then
        DisplayConfig.aspect_ratio = "4:3"
    elseif math.abs(ratio - 16/9) < 0.01 then
        DisplayConfig.aspect_ratio = "16:9"
    else
        DisplayConfig.aspect_ratio = string.format("%.2f:1", ratio)
    end

    -- Calculate scale factor based on aspect ratio
    -- For 4:3 displays: scale based on width (baseline 640x480)
    -- For 16:9 displays: scale based on height (baseline 720p = 1280x720)
    if DisplayConfig.aspect_ratio == "16:9" then
        -- Scale based on height for widescreen displays (720p baseline)
        DisplayConfig.scale = DisplayConfig.height / 720
    else
        -- Scale based on width for 4:3 displays (640x480 baseline)
        DisplayConfig.scale = DisplayConfig.width / 640
    end

    -- Scale UI elements (use original sizes to prevent repeated scaling)
    for key, value in pairs(DisplayConfig.SIZES_ORIGINAL) do
        DisplayConfig.SIZES[key] = math.floor(value * DisplayConfig.scale)
    end
    
    -- Optional: log scale factor if logger is available
    if package.loaded["src.lib.logger"] then
        local Logger = require("src.lib.logger")
        Logger.info("Display scale factor:", string.format("%.2f", DisplayConfig.scale))
    end
end

-- Get safe area bounds (for letterboxing if needed)
function DisplayConfig.get_safe_area()
    return {
        x = 0,
        y = 0,
        width = DisplayConfig.width,
        height = DisplayConfig.height
    }
end

-- Convert logical coordinates to screen coordinates
function DisplayConfig.to_screen_x(logical_x)
    return logical_x * DisplayConfig.scale
end

function DisplayConfig.to_screen_y(logical_y)
    return logical_y * DisplayConfig.scale
end

return DisplayConfig
