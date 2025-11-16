-- SearchBar UI component
-- Constitution: I. Performance-First (debounced input)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")

local SearchBar = {}
SearchBar.__index = SearchBar

-- Create a new SearchBar
function SearchBar.new(x, y, width)
    local self = setmetatable({}, SearchBar)

    self.x = x
    self.y = y
    self.width = width
    self.height = DisplayConfig.SIZES.font_size_large + DisplayConfig.SIZES.padding * 2

    self.query = ""
    self.cursor_visible = true
    self.cursor_blink_timer = 0
    self.cursor_blink_rate = 0.5  -- Blink every 500ms

    self.focused = false
    self.placeholder = "Type to search games..."

    return self
end

-- Update search bar
function SearchBar:update(dt)
    -- Blink cursor
    self.cursor_blink_timer = self.cursor_blink_timer + dt
    if self.cursor_blink_timer >= self.cursor_blink_rate then
        self.cursor_visible = not self.cursor_visible
        self.cursor_blink_timer = 0
    end
end

-- Draw search bar
function SearchBar:draw()
    -- Draw background
    love.graphics.setColor(DisplayConfig.COLORS.surface)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)

    -- Draw border
    if self.focused then
        love.graphics.setColor(DisplayConfig.COLORS.primary)
    else
        love.graphics.setColor(DisplayConfig.COLORS.secondary)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

    -- Draw text
    love.graphics.setColor(DisplayConfig.COLORS.text)
    local text_x = self.x + DisplayConfig.SIZES.padding
    local text_y = self.y + DisplayConfig.SIZES.padding

    if self.query == "" then
        -- Show placeholder
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        love.graphics.print(self.placeholder, text_x, text_y)
    else
        -- Show query with text overflow handling
        local font = love.graphics.getFont()
        local available_width = self.width - DisplayConfig.SIZES.padding * 2 - 10 -- Reserve space for cursor
        local text_width = font:getWidth(self.query)
        local display_text = self.query

        -- If text is too wide, scroll to show the end (where user is typing)
        if text_width > available_width then
            -- Start from the end and work backwards until we fit
            local chars = {}
            local current_width = 0
            for i = #self.query, 1, -1 do
                local char = self.query:sub(i, i)
                local char_width = font:getWidth(char)
                if current_width + char_width > available_width then
                    break
                end
                table.insert(chars, 1, char)
                current_width = current_width + char_width
            end
            display_text = table.concat(chars)
        end

        love.graphics.print(display_text, text_x, text_y)

        -- Draw cursor
        if self.focused and self.cursor_visible then
            local cursor_x = text_x + font:getWidth(display_text)
            love.graphics.setColor(DisplayConfig.COLORS.primary)
            love.graphics.rectangle("fill", cursor_x, text_y, 2, DisplayConfig.SIZES.font_size_large)
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Add character to query
function SearchBar:add_char(char)
    self.query = self.query .. char
    self.cursor_blink_timer = 0
    self.cursor_visible = true
    Logger.debug("SearchBar query:", self.query)
end

-- Remove last character
function SearchBar:backspace()
    if #self.query > 0 then
        self.query = self.query:sub(1, -2)
        self.cursor_blink_timer = 0
        self.cursor_visible = true
        Logger.debug("SearchBar query:", self.query)
    end
end

-- Clear query
function SearchBar:clear()
    self.query = ""
    self.cursor_blink_timer = 0
    self.cursor_visible = true
    Logger.debug("SearchBar cleared")
end

-- Get current query
function SearchBar:get_query()
    return self.query
end

-- Set focus
function SearchBar:set_focus(focused)
    self.focused = focused
    if focused then
        self.cursor_visible = true
        self.cursor_blink_timer = 0
    end
end

return SearchBar
