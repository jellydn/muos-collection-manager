-- GameGrid component with virtual scrolling
-- Constitution: I. Performance-First (viewport culling for 60 FPS)

local Logger = require("src.lib.logger")
local DisplayConfig = require("src.config.display_config")

local GameGrid = {}
GameGrid.__index = GameGrid

-- Create a new GameGrid
function GameGrid.new(x, y, width, height)
    local self = setmetatable({}, GameGrid)

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- List configuration (vertical list, not grid)
    self.item_height = 50  -- Height of each list item
    self.padding = DisplayConfig.SIZES.padding
    self.cols = 1  -- List view - single column

    -- Virtual scrolling state
    self.scroll_offset = 0
    self.scroll_speed = 120  -- pixels per second
    self.items = {}
    self.selected_index = 1

    -- Performance optimization: Create canvas for offscreen rendering
    -- Only render visible items, cache the rest
    self.canvas = nil  -- Created on demand
    self.canvas_needs_update = true

    -- Font cache for text rendering
    self.font_cache = {}

    return self
end-- Set items to display
function GameGrid:set_items(items)
    self.items = items or {}
    self.selected_index = 1
    self.scroll_offset = 0
    self.canvas_needs_update = true  -- Invalidate cache
    Logger.debug("GameGrid items set:", #self.items)
end

-- Update grid
function GameGrid:update(dt)
    -- Smooth scrolling (animated)
    -- Target scroll position based on selected item
    if #self.items > 0 then
        local target_row = math.floor((self.selected_index - 1) / self.cols)
        local target_y = target_row * self.item_height

        -- Keep selected item in viewport
        local viewport_height = self.height
        local min_scroll = target_y - viewport_height + self.item_height + self.padding
        local max_scroll = target_y - self.padding

        if self.scroll_offset < min_scroll then
            self.scroll_offset = min_scroll
        elseif self.scroll_offset > max_scroll then
            self.scroll_offset = max_scroll
        end

        -- Clamp to valid range
        local max_offset = math.max(0, math.ceil(#self.items / self.cols) * self.item_height - viewport_height)
        self.scroll_offset = math.max(0, math.min(max_offset, self.scroll_offset))
    end
end

-- Draw list with virtual scrolling
function GameGrid:draw()
    -- Enable scissor (clip outside viewport)
    love.graphics.setScissor(self.x, self.y, self.width, self.height)

    if #self.items == 0 then
        -- Draw "no items" message
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
        local msg = "No games found"
        local msg_width = love.graphics.getFont():getWidth(msg)
        local msg_x = self.x + (self.width - msg_width) / 2
        local msg_y = self.y + self.height / 2
        love.graphics.print(msg, msg_x, msg_y)
        love.graphics.setScissor()
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Calculate visible range (viewport culling)
    local visible_start = math.max(1, math.floor(self.scroll_offset / self.item_height))
    local visible_end = math.min(#self.items, math.ceil((self.scroll_offset + self.height) / self.item_height) + 1)

    -- Draw each visible list item
    for i = visible_start, visible_end do
        local game = self.items[i]
        if game then
            local item_y = self.y + (i - 1) * self.item_height - self.scroll_offset
            local is_selected = (i == self.selected_index)

            -- Draw background bar
            if is_selected then
                love.graphics.setColor(DisplayConfig.COLORS.primary)
            else
                love.graphics.setColor(DisplayConfig.COLORS.surface)
            end
            love.graphics.rectangle("fill", self.x, item_y, self.width, self.item_height)

            -- Draw text content
            self:draw_list_item(game, item_y, is_selected)
        end
    end

    -- Disable scissor
    love.graphics.setScissor()

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end-- Draw a single list item
function GameGrid:draw_list_item(game, item_y, is_selected)
    local padding = 12
    local text_y = item_y + (self.item_height - DisplayConfig.SIZES.font_size_medium) / 2

    -- Set text color
    if is_selected then
        love.graphics.setColor(1, 1, 1)  -- White for selected
    else
        love.graphics.setColor(DisplayConfig.COLORS.text)
    end

    -- Game title (left side)
    local title = game.title or "Unknown"
    local max_title_width = self.width - 250  -- Leave space for system and year
    local font = love.graphics.getFont()

    -- Truncate title if too long
    if font:getWidth(title) > max_title_width then
        while font:getWidth(title .. "...") > max_title_width and #title > 0 do
            title = title:sub(1, -2)
        end
        title = title .. "..."
    end

    love.graphics.print(title, self.x + padding, text_y)

    -- System badge (right side)
    local system_text = (game.system or "unknown"):upper()
    local system_x = self.x + self.width - 180

    -- Dim color for system
    if is_selected then
        love.graphics.setColor(0.9, 0.9, 0.9)
    else
        love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    end
    love.graphics.print("[" .. system_text .. "]", system_x, text_y)

    -- Year (far right)
    if game.year then
        local year_text = tostring(game.year)
        local year_x = self.x + self.width - 80
        love.graphics.print(year_text, year_x, text_y)
    end
end-- Navigate list (up/down only for single column)
function GameGrid:move_up()
    if self.selected_index > 1 then
        self.selected_index = self.selected_index - 1
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

function GameGrid:move_down()
    if self.selected_index < #self.items then
        self.selected_index = self.selected_index + 1
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

function GameGrid:move_left()
    -- Not used in list view
end

function GameGrid:move_right()
    -- Not used in list view
end

-- Get selected game
function GameGrid:get_selected()
    if #self.items > 0 and self.selected_index <= #self.items then
        return self.items[self.selected_index]
    end
    return nil
end

return GameGrid
