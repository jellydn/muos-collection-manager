-- Dialog component for confirmation prompts
-- Constitution: Scene Independence (no shared global state)

local DisplayConfig = require("src.config.display_config")
local InputHandler = require("src.ui.input_handler")
local Logger = require("src.lib.logger")

local Dialog = {}
Dialog.__index = Dialog

-- Dialog types
Dialog.TYPE = {
    CONFIRM = "confirm",    -- Yes/No dialog
    INFO = "info",          -- OK dialog
    CHOICE = "choice"       -- Multiple options
}

-- Create new dialog
function Dialog.new(params)
    -- Validate required parameters (use error handling instead of assert)
    if not params or type(params) ~= "table" then
        Logger.error("Dialog.new: params must be a table")
        error("Dialog requires params table")
    end
    
    if not params.title or type(params.title) ~= "string" then
        Logger.error("Dialog.new: title is required and must be a string")
        error("Dialog requires title")
    end
    
    if not params.message or type(params.message) ~= "string" then
        Logger.error("Dialog.new: message is required and must be a string")
        error("Dialog requires message")
    end
    
    if not params.type or type(params.type) ~= "string" then
        Logger.error("Dialog.new: type is required and must be a string")
        error("Dialog requires type")
    end
    
    local self = setmetatable({}, Dialog)
    
    self.title = params.title
    self.message = params.message
    self.type = params.type or Dialog.TYPE.CONFIRM
    self.options = params.options or { "Yes", "No" }  -- For CHOICE type
    self.callback = params.callback or function() end
    self.is_open = false
    self.selected_index = 1
    
    -- Styling
    self.padding = 20
    self.width = math.min(DisplayConfig.width - 40, 400)
    self.height = 150
    self.x = (DisplayConfig.width - self.width) / 2
    self.y = (DisplayConfig.height - self.height) / 2
    self.corner_radius = 8
    
    return self
end

-- Open dialog
function Dialog:open()
    self.is_open = true
    self.selected_index = 1
    Logger.debug("Dialog opened:", self.title)
end

-- Close dialog
function Dialog:close()
    self.is_open = false
    Logger.debug("Dialog closed:", self.title)
end

-- Handle input
function Dialog:keypressed(key, scancode, isrepeat)
    if not self.is_open then return end
    
    -- Navigate options
    if InputHandler.is_pressed("left") then
        self.selected_index = math.max(1, self.selected_index - 1)
    elseif InputHandler.is_pressed("right") then
        self.selected_index = math.min(#self.options, self.selected_index + 1)
    end
    
    -- Select option
    if InputHandler.is_pressed("confirm") then
        self:confirm_selection()
    end
    
    -- Cancel (B button)
    if InputHandler.is_pressed("cancel") then
        self.selected_index = #self.options  -- Default to "No"/"Cancel"
        self:confirm_selection()
    end
end

-- Navigate options
function Dialog:move_left()
    if self.selected_index > 1 then
        self.selected_index = self.selected_index - 1
    end
end

function Dialog:move_right()
    if self.selected_index < #self.options then
        self.selected_index = self.selected_index + 1
    end
end

-- Select current option
function Dialog:select()
    self:confirm_selection()
end

-- Handle selection
function Dialog:confirm_selection()
    if self.type == Dialog.TYPE.CONFIRM then
        local result = self.selected_index == 1 and "yes" or "no"
        self.callback(result)
    elseif self.type == Dialog.TYPE.CHOICE then
        self.callback(self.options[self.selected_index])
    else
        self.callback(true)
    end
    self:close()
end

-- Draw dialog
function Dialog:draw()
    if not self.is_open then return end
    
    -- Semi-transparent backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, DisplayConfig.width, DisplayConfig.height)
    
    -- Dialog background
    love.graphics.setColor(DisplayConfig.COLORS.surface)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.corner_radius)
    
    -- Dialog border
    love.graphics.setColor(DisplayConfig.COLORS.primary)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.corner_radius)
    
    -- Title
    love.graphics.setColor(DisplayConfig.COLORS.text)
    love.graphics.printf(
        self.title,
        self.x + self.padding,
        self.y + self.padding,
        self.width - self.padding * 2,
        "center"
    )
    
    -- Message
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    love.graphics.printf(
        self.message,
        self.x + self.padding,
        self.y + self.padding + 30,
        self.width - self.padding * 2,
        "center"
    )
    
    -- Draw options as buttons
    local button_y = self.y + self.height - 40
    local button_width = (self.width - self.padding * 3) / #self.options
    
    for i, option in ipairs(self.options) do
        local button_x = self.x + self.padding + (i - 1) * (button_width + self.padding)
        
        -- Button background (highlighted if selected)
        if i == self.selected_index then
            love.graphics.setColor(DisplayConfig.COLORS.primary)
        else
            love.graphics.setColor(DisplayConfig.COLORS.secondary)
        end
        
        love.graphics.rectangle("fill", button_x, button_y, button_width, 30, 4)
        
        -- Button text
        love.graphics.setColor(DisplayConfig.COLORS.text)
        love.graphics.printf(
            option,
            button_x,
            button_y + 8,
            button_width,
            "center"
        )
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Dialog
