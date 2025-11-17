-- On-Screen Keyboard widget
-- Constitution: III. Input Modularity (D-pad navigation)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")

local OnScreenKeyboard = {}
OnScreenKeyboard.__index = OnScreenKeyboard

-- Keyboard layouts (Standard QWERTY)
local LAYOUT_LOWERCASE = {
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
    {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
    {"a", "s", "d", "f", "g", "h", "j", "k", "l", "-"},
    {"CAPS", "z", "x", "c", "v", "b", "n", "m", ".", "DEL"},
    {"@", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", ",", "?"}
}

local LAYOUT_UPPERCASE = {
    {"!", "@", "#", "$", "%", "^", "&", "*", "(", ")"},
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L", "_"},
    {"CAPS", "Z", "X", "C", "V", "B", "N", "M", ".", "DEL"},
    {"#", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", "SPACE", "!", "?"}
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

    -- Key size with minimum constraints
    local calculated_key_width = (width - (self.cols + 1) * 4) / self.cols
    local calculated_key_height = (height - (self.rows + 1) * 4) / self.rows

    -- Ensure minimum key size to prevent rendering issues
    self.key_width = math.max(20, calculated_key_width)
    self.key_height = math.max(20, calculated_key_height)

    if calculated_key_width < 20 or calculated_key_height < 20 then
        Logger.warn("Keyboard dimensions too small. Requested:", width, "x", height,
                    "Key size:", calculated_key_width, "x", calculated_key_height)
    end

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
        local col = 1
        while col <= #self.layout[row] do
            local key_x = self.x + 4 + (col - 1) * (self.key_width + 4)
            local key_y = self.y + 4 + (row - 1) * (self.key_height + 4)

            local key = self.layout[row][col]

            -- Check if this is a SPACE key and count consecutive SPACE keys
            local space_count = 0
            if key == "SPACE" then
                local check_col = col
                while check_col <= #self.layout[row] and self.layout[row][check_col] == "SPACE" do
                    space_count = space_count + 1
                    check_col = check_col + 1
                end
            end

            -- Check if any SPACE position in the span is selected
            local is_selected = false
            if space_count > 0 then
                for i = col, col + space_count - 1 do
                    if row == self.selected_row and i == self.selected_col then
                        is_selected = true
                        break
                    end
                end
            else
                is_selected = (row == self.selected_row and col == self.selected_col)
            end

            -- Calculate key width (SPACE bar spans multiple keys)
            local draw_width = self.key_width
            if space_count > 0 then
                draw_width = space_count * self.key_width + (space_count - 1) * 4
            end

            -- Draw key background
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.primary)
            else
                love.graphics.setColor(DisplayConfig.COLORS.background)
            end
            love.graphics.rectangle("fill", key_x, key_y, draw_width, self.key_height, 4, 4)

            -- Draw key border
            love.graphics.setColor(DisplayConfig.COLORS.secondary)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", key_x, key_y, draw_width, self.key_height, 4, 4)

            -- Draw key label
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.background)
            else
                love.graphics.setColor(DisplayConfig.COLORS.text)
            end

            local label = key

            local font = love.graphics.getFont()
            local text_width = font:getWidth(label)
            local text_height = font:getHeight()

            -- Ensure text fits within key bounds (clamp position to prevent overflow)
            local text_x = key_x + math.max(0, (draw_width - text_width) / 2)
            local text_y = key_y + math.max(0, (self.key_height - text_height) / 2)

            -- Only draw if text will fit reasonably within the key
            if text_width <= draw_width + 2 and text_height <= self.key_height + 2 then
                love.graphics.print(label, text_x, text_y)
            else
                -- Text too large, draw a placeholder
                love.graphics.print("•", key_x + draw_width / 2 - 2, key_y + self.key_height / 2 - font:getHeight() / 2)
            end

            -- Skip the remaining SPACE keys if we drew a wide SPACE bar
            if space_count > 0 then
                col = col + space_count
            else
                col = col + 1
            end
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
    local new_col = math.max(1, self.selected_col - 1)

    -- If we land on a SPACE, move to the first SPACE in the group
    if self.layout[self.selected_row][new_col] == "SPACE" then
        while new_col > 1 and self.layout[self.selected_row][new_col - 1] == "SPACE" do
            new_col = new_col - 1
        end
    end

    self.selected_col = new_col
end

function OnScreenKeyboard:move_right()
    local new_col = math.min(#self.layout[self.selected_row], self.selected_col + 1)

    -- If we're on a SPACE and moving right, skip to after all SPACE keys
    if self.layout[self.selected_row][self.selected_col] == "SPACE" then
        while new_col <= #self.layout[self.selected_row] and self.layout[self.selected_row][new_col] == "SPACE" do
            new_col = new_col + 1
        end
        new_col = math.min(#self.layout[self.selected_row], new_col)
    end

    self.selected_col = new_col
end

-- Clamp selection to valid key in current row
function OnScreenKeyboard:clamp_selection()
    local max_col = #self.layout[self.selected_row]
    if self.selected_col > max_col then
        self.selected_col = max_col
    end

    -- If we land on a SPACE (not the first one), move to the first SPACE
    if self.layout[self.selected_row][self.selected_col] == "SPACE" then
        while self.selected_col > 1 and self.layout[self.selected_row][self.selected_col - 1] == "SPACE" do
            self.selected_col = self.selected_col - 1
        end
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
