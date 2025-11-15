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
    
    -- Grid configuration
    self.item_width = DisplayConfig.SIZES.grid_item_width
    self.item_height = DisplayConfig.SIZES.grid_item_height + DisplayConfig.SIZES.font_size_small + 4
    self.padding = DisplayConfig.SIZES.padding
    
    -- Calculate columns
    self.cols = math.floor((width - self.padding) / (self.item_width + self.padding))
    
    -- Virtual scrolling state
    self.scroll_offset = 0
    self.scroll_speed = 120  -- pixels per second
    self.items = {}
    self.selected_index = 1
    
    return self
end

-- Set items to display
function GameGrid:set_items(items)
    self.items = items or {}
    self.selected_index = 1
    self.scroll_offset = 0
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

-- Draw grid with virtual scrolling
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
        return
    end
    
    -- Calculate visible range (viewport culling)
    local visible_start_row = math.floor(self.scroll_offset / self.item_height)
    local visible_end_row = math.ceil((self.scroll_offset + self.height) / self.item_height)
    
    local start_index = visible_start_row * self.cols + 1
    local end_index = math.min(#self.items, (visible_end_row + 1) * self.cols)
    
    -- Draw only visible items
    for i = start_index, end_index do
        if self.items[i] then
            self:draw_item(i, self.items[i])
        end
    end
    
    -- Disable scissor
    love.graphics.setScissor()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a single grid item
function GameGrid:draw_item(index, game)
    local row = math.floor((index - 1) / self.cols)
    local col = (index - 1) % self.cols
    
    local item_x = self.x + self.padding + col * (self.item_width + self.padding)
    local item_y = self.y + self.padding + row * self.item_height - self.scroll_offset
    
    local is_selected = (index == self.selected_index)
    
    -- Draw item background
    if is_selected then
        love.graphics.setColor(DisplayConfig.COLORS.primary)
    else
        love.graphics.setColor(DisplayConfig.COLORS.surface)
    end
    love.graphics.rectangle("fill", item_x, item_y, self.item_width, self.item_width, 4, 4)
    
    -- Draw item border
    love.graphics.setColor(DisplayConfig.COLORS.secondary)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", item_x, item_y, self.item_width, self.item_width, 4, 4)
    
    -- Draw game title (truncated)
    if is_selected then
        love.graphics.setColor(DisplayConfig.COLORS.background)
    else
        love.graphics.setColor(DisplayConfig.COLORS.text)
    end
    
    local title = game.title
    local max_width = self.item_width - 8
    local font = love.graphics.getFont()
    
    -- Truncate title if too long
    if font:getWidth(title) > max_width then
        while font:getWidth(title .. "...") > max_width and #title > 0 do
            title = title:sub(1, -2)
        end
        title = title .. "..."
    end
    
    local text_y = item_y + self.item_width + 2
    love.graphics.print(title, item_x + 4, text_y)
end

-- Navigate grid
function GameGrid:move_up()
    if self.selected_index > self.cols then
        self.selected_index = self.selected_index - self.cols
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

function GameGrid:move_down()
    if self.selected_index + self.cols <= #self.items then
        self.selected_index = self.selected_index + self.cols
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

function GameGrid:move_left()
    if self.selected_index > 1 then
        self.selected_index = self.selected_index - 1
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

function GameGrid:move_right()
    if self.selected_index < #self.items then
        self.selected_index = self.selected_index + 1
        Logger.debug("GameGrid selection:", self.selected_index)
    end
end

-- Get selected game
function GameGrid:get_selected()
    if #self.items > 0 and self.selected_index <= #self.items then
        return self.items[self.selected_index]
    end
    return nil
end

return GameGrid
