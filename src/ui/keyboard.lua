-- On-Screen Keyboard widget
-- Constitution: III. Input Modularity (D-pad navigation)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")

local OnScreenKeyboard = {}
OnScreenKeyboard.__index = OnScreenKeyboard

-- Keyboard layouts
local LAYOUT_LOWERCASE = {
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
    {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
    {"a", "s", "d", "f", "g", "h", "j", "k", "l", "-"},
    {"⇧", "z", "x", "c", "v", "b", "n", "m", ".", "⌫"}  -- ⇧ = shift, ⌫ = backspace
}

local LAYOUT_UPPERCASE = {
    {"!", "@", "#", "$", "%", "^", "&", "*", "(", ")"},
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L", "_"},
    {"⇧", "Z", "X", "C", "V", "B", "N", "M", "?", "⌫"}  -- ⇧ = shift (returns to lowercase)
}

-- Create a new OnScreenKeyboard
function OnScreenKeyboard.new(x, y, width, height)
    local self = setmetatable({}, OnScreenKeyboard)

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.shift_mode = false  -- false = lowercase, true = uppercase
    self.layout = LAYOUT_LOWERCASE
    self.rows = #self.layout
    self.cols = #self.layout[1]

    -- Current selection
    self.selected_row = 1
    self.selected_col = 1

    -- Key size
    self.key_width = (width - (self.cols + 1) * 4) / self.cols
    self.key_height = (height - (self.rows + 1) * 4) / self.rows

    self.visible = false

    return self
end

-- Update keyboard
function OnScreenKeyboard:update(dt)
    -- No animation for now
end

-- Draw keyboard
function OnScreenKeyboard:draw()
    if not self.visible then
        return
    end

    -- Draw background
    love.graphics.setColor(DisplayConfig.COLORS.surface)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    -- Draw keys
    for row = 1, self.rows do
        for col = 1, #self.layout[row] do
            local key_x = self.x + 4 + (col - 1) * (self.key_width + 4)
            local key_y = self.y + 4 + (row - 1) * (self.key_height + 4)

            local key = self.layout[row][col]
            local is_selected = (row == self.selected_row and col == self.selected_col)

            -- Draw key background
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.primary)
            else
                love.graphics.setColor(DisplayConfig.COLORS.background)
            end
            love.graphics.rectangle("fill", key_x, key_y, self.key_width, self.key_height, 4, 4)

            -- Draw key border
            love.graphics.setColor(DisplayConfig.COLORS.secondary)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", key_x, key_y, self.key_width, self.key_height, 4, 4)

            -- Draw key label
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.background)
            else
                love.graphics.setColor(DisplayConfig.COLORS.text)
            end

            local label = key
            -- No need for SPACE label since we removed space key

            local text_width = love.graphics.getFont():getWidth(label)
            local text_height = love.graphics.getFont():getHeight()
            local text_x = key_x + (self.key_width - text_width) / 2
            local text_y = key_y + (self.key_height - text_height) / 2

            love.graphics.print(label, text_x, text_y)
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Move selection
function OnScreenKeyboard:move_up()
    self.selected_row = math.max(1, self.selected_row - 1)
    self:clamp_selection()
end

function OnScreenKeyboard:move_down()
    self.selected_row = math.min(self.rows, self.selected_row + 1)
    self:clamp_selection()
end

function OnScreenKeyboard:move_left()
    self.selected_col = math.max(1, self.selected_col - 1)
end

function OnScreenKeyboard:move_right()
    self.selected_col = math.min(#self.layout[self.selected_row], self.selected_col + 1)
end

-- Clamp selection to valid key in current row
function OnScreenKeyboard:clamp_selection()
    local max_col = #self.layout[self.selected_row]
    if self.selected_col > max_col then
        self.selected_col = max_col
    end
end

-- Get selected key
function OnScreenKeyboard:get_selected_key()
    return self.layout[self.selected_row][self.selected_col]
end

-- Toggle shift mode (lowercase <-> uppercase)
function OnScreenKeyboard:toggle_shift()
    self.shift_mode = not self.shift_mode
    if self.shift_mode then
        self.layout = LAYOUT_UPPERCASE
        Logger.debug("Keyboard: UPPERCASE mode")
    else
        self.layout = LAYOUT_LOWERCASE
        Logger.debug("Keyboard: lowercase mode")
    end
end

-- Show/hide keyboard
function OnScreenKeyboard:show()
    self.visible = true
    Logger.debug("On-screen keyboard shown")
end

function OnScreenKeyboard:hide()
    self.visible = false
    Logger.debug("On-screen keyboard hidden")
end

function OnScreenKeyboard:toggle()
    self.visible = not self.visible
    Logger.debug("On-screen keyboard toggled:", self.visible)
end

function OnScreenKeyboard:is_visible()
    return self.visible
end

return OnScreenKeyboard
