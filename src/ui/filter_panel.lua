-- FilterPanel UI component for managing multiple filters
-- Constitution: IV. Scene Independence (self-contained UI)

local DisplayConfig = require("src.config.display_config")
local Logger = require("src.lib.logger")
local FilterEngine = require("src.services.filter_engine")
local SearchFilter = require("src.models.search_filter")

local FilterPanel = {}
FilterPanel.__index = FilterPanel

function FilterPanel.new(x, y, width, height, games)
    local self = setmetatable({}, FilterPanel)
    self.x = x or 0
    self.y = y or 0
    self.width = width or math.floor(DisplayConfig.width * 0.9)
    self.height = height or math.floor(DisplayConfig.height * 0.9)
    self.visible = false

    self.filters = {}
    self.mode = "AND"
    self.focus = 1  -- 1..#filters plus one extra row for "Add Filter"
    self.editing = false

    -- Cached option lists derived from games
    self.genres = FilterEngine.get_genres(games or {})
    self.min_year, self.max_year = FilterEngine.get_year_range(games or {})
    self.max_players = FilterEngine.get_max_players(games or {})

    if not self.min_year then
        -- Fallback range
        self.min_year, self.max_year = 1970, 2025
    end

    return self
end

function FilterPanel:is_visible()
    return self.visible
end

function FilterPanel:show(initial_filters, mode)
    self.visible = true
    self.filters = {}
    if initial_filters then
        for _, f in ipairs(initial_filters) do
            table.insert(self.filters, { filter_type = f.filter_type, operator = f.operator, value = f.value })
        end
    end
    self.mode = (mode == "OR") and "OR" or "AND"
    self.focus = math.max(1, #self.filters)
    self.editing = false
    Logger.info("FilterPanel opened with", #self.filters, "filters, mode", self.mode)
end

function FilterPanel:hide()
    self.visible = false
    self.editing = false
end

function FilterPanel:toggle()
    if self.visible then self:hide() else self:show(self.filters, self.mode) end
end

function FilterPanel:toggle_mode()
    self.mode = (self.mode == "AND") and "OR" or "AND"
end

function FilterPanel:get_filters()
    return self.filters
end

function FilterPanel:get_mode()
    return self.mode
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function FilterPanel:add_default_filter()
    -- Prefer adding Favorite=true first, then Genre if available
    if #self.genres > 0 then
        table.insert(self.filters, { filter_type = "genre", operator = "equals", value = self.genres[1] })
    else
        table.insert(self.filters, { filter_type = "favorite", operator = "equals", value = true })
    end
    self.focus = #self.filters
end

function FilterPanel:remove_focused()
    if self.focus >= 1 and self.focus <= #self.filters then
        table.remove(self.filters, self.focus)
        self.focus = clamp(self.focus, 1, math.max(1, #self.filters))
    end
end

-- Cycle filter_type for the focused filter
function FilterPanel:cycle_type(dir)
    if self.focus < 1 or self.focus > #self.filters then return end
    local order = { "genre", "year", "players", "favorite" }
    local idx_by = { genre = 1, year = 2, players = 3, favorite = 4 }
    local f = self.filters[self.focus]
    local i = idx_by[f.filter_type] or 1
    i = i + (dir or 1)
    if i < 1 then i = #order end
    if i > #order then i = 1 end
    f.filter_type = order[i]
    -- Reset operator/value defaults for new type
    if f.filter_type == "genre" then
        f.operator = "equals"
        f.value = self.genres[1] or "Unknown"
    elseif f.filter_type == "year" then
        f.operator = "equals"
        f.value = self.min_year
    elseif f.filter_type == "players" then
        f.operator = "equals"
        f.value = 1
    elseif f.filter_type == "favorite" then
        f.operator = "equals"
        f.value = true
    end
end

-- Cycle operator for current type
function FilterPanel:cycle_operator(dir)
    if self.focus < 1 or self.focus > #self.filters then return end
    local f = self.filters[self.focus]
    local ops_order = {
        genre = { "equals" },
        year = { "equals", "range", "gte", "lte" },
        players = { "equals", "gte", "lte" },
        favorite = { "equals" }
    }
    local list = ops_order[f.filter_type] or { "equals" }
    local index = 1
    for i, op in ipairs(list) do if op == f.operator then index = i break end end
    index = index + (dir or 1)
    if index < 1 then index = #list end
    if index > #list then index = 1 end
    f.operator = list[index]
    -- Adjust value defaults when switching operator
    if f.filter_type == "year" then
        if f.operator == "range" then
            f.value = { self.min_year, self.max_year }
        else
            f.value = self.min_year
        end
    elseif f.filter_type == "players" then
        f.value = 1
    end
end

-- Adjust value left/right
function FilterPanel:adjust_value(delta)
    if self.focus < 1 or self.focus > #self.filters then return end
    local f = self.filters[self.focus]
    if f.filter_type == "genre" then
        if #self.genres == 0 then return end
        local pos = 1
        for i, g in ipairs(self.genres) do if g == f.value then pos = i break end end
        pos = pos + delta
        if pos < 1 then pos = #self.genres end
        if pos > #self.genres then pos = 1 end
        f.value = self.genres[pos]
    elseif f.filter_type == "year" then
        if f.operator == "range" then
            local minv = clamp(f.value[1] + delta, self.min_year, f.value[2])
            local maxv = clamp(f.value[2] + delta, math.max(minv, self.min_year), self.max_year)
            f.value[1] = minv
            f.value[2] = maxv
        else
            f.value = clamp((f.value or self.min_year) + delta, self.min_year, self.max_year)
        end
    elseif f.filter_type == "players" then
        f.value = clamp((f.value or 1) + delta, 1, self.max_players)
    elseif f.filter_type == "favorite" then
        f.value = not f.value
    end
end

function FilterPanel:update(dt)
    -- no timers currently
end

function FilterPanel:draw()
    if not self.visible then return end
    local pad = DisplayConfig.SIZES.margin
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    local title = string.format("Filters (%s)", self.mode)
    love.graphics.print(title, self.x + pad, self.y + pad)

    local line_h = DisplayConfig.SIZES.font_size + 6
    local draw_y = self.y + pad * 2

    for i, f in ipairs(self.filters) do
        draw_y = draw_y + line_h
        if i == self.focus then
            love.graphics.setColor(0.2, 0.6, 1.0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        local desc
        local ok, filter_obj = pcall(SearchFilter.new, { filter_type = f.filter_type, operator = f.operator, value = f.value })
        if ok and filter_obj then
            desc = filter_obj:to_string()
        else
            desc = string.format("%s %s %s", tostring(f.filter_type), tostring(f.operator), tostring(f.value))
        end
        love.graphics.print(desc, self.x + pad, draw_y)
    end

    -- Add Filter row
    draw_y = draw_y + line_h
    if (#self.filters + 1) == self.focus then
        love.graphics.setColor(0.2, 0.6, 1.0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.print("+ Add Filter", self.x + pad, draw_y)

    -- Help
    love.graphics.setColor(DisplayConfig.COLORS.text_dim)
    local help = "A: Edit/Cycle  X: Delete  R: AND/OR  B/L: Close"
    love.graphics.print(help, self.x + pad, self.y + self.height - pad - DisplayConfig.SIZES.font_size_small)
end

-- Handle high-level actions from InputHandler
function FilterPanel:handle_action(action)
    if not self.visible then return end
    if action == "up" then
        self.focus = clamp(self.focus - 1, 1, #self.filters + 1)
    elseif action == "down" then
        self.focus = clamp(self.focus + 1, 1, #self.filters + 1)
    elseif action == "left" then
        if self.focus <= #self.filters then
            if self.editing then
                self:adjust_value(-1)
            else
                self:cycle_operator(-1)
            end
        end
    elseif action == "right" then
        if self.focus <= #self.filters then
            if self.editing then
                self:adjust_value(1)
            else
                self:cycle_operator(1)
            end
        end
    elseif action == "confirm" then
        if self.focus <= #self.filters then
            if not self.editing then
                -- First confirm toggles editing mode for value
                self.editing = true
            else
                -- While editing, cycle type for quick adjustments
                self:cycle_type(1)
            end
        else
            self:add_default_filter()
        end
    elseif action == "delete" then
        if self.focus <= #self.filters then
            self:remove_focused()
        end
    elseif action == "shoulder_r" then
        self:toggle_mode()
    elseif action == "cancel" or action == "shoulder_l" then
        self:hide()
    end
end

return FilterPanel
