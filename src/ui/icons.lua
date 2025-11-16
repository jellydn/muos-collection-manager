-- Icons Module
-- Unicode-based icon system (open source, no external dependencies)

local Icons = {}

-- Icon definitions using Unicode characters
-- These are free to use and work across all platforms
Icons.symbols = {
    -- Navigation
    arrow_up = "▲",
    arrow_down = "▼",
    arrow_left = "◄",
    arrow_right = "►",
    
    -- Actions
    search = "🔍",
    star = "★",
    star_empty = "☆",
    heart = "♥",
    heart_empty = "♡",
    plus = "+",
    minus = "-",
    check = "✓",
    cross = "✗",
    
    -- System
    folder = "📁",
    file = "📄",
    settings = "⚙",
    menu = "≡",
    home = "🏠",
    
    -- Games
    controller = "🎮",
    trophy = "🏆",
    dice = "🎲",
    
    -- UI Elements
    box = "▢",
    box_filled = "■",
    circle = "○",
    circle_filled = "●",
    
    -- Status
    info = "ℹ",
    warning = "⚠",
    error = "✖",
    success = "✔",
}

-- Draw an icon at the specified position
-- @param icon_name string Name of the icon from Icons.symbols
-- @param x number X position
-- @param y number Y position
-- @param color table Optional color {r, g, b, a}
function Icons.draw(icon_name, x, y, color)
    local symbol = Icons.symbols[icon_name]
    if not symbol then
        return
    end
    
    if color then
        love.graphics.setColor(color)
    end
    
    love.graphics.print(symbol, x, y)
    
    if color then
        love.graphics.setColor(1, 1, 1, 1) -- Reset to white
    end
end

-- Get an icon symbol by name
-- @param icon_name string Name of the icon
-- @return string The unicode symbol
function Icons.get(icon_name)
    return Icons.symbols[icon_name] or ""
end

return Icons
