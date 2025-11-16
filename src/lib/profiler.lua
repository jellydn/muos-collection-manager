-- Performance Profiler
-- Constitution: I. Performance-First (monitoring and analysis)

local Logger = require("src.lib.logger")

local Profiler = {}

-- Profiler state
Profiler.enabled = false
Profiler.metrics = {}
Profiler.timers = {}

-- Enable/disable profiler
function Profiler.set_enabled(enabled)
    Profiler.enabled = enabled
    if enabled then
        Logger.info("Profiler enabled")
    else
        Logger.info("Profiler disabled")
    end
end

-- Start timing a named operation
function Profiler.start_timer(name)
    if not Profiler.enabled then return end
    Profiler.timers[name] = love.timer.getTime()
end

-- End timing and record metric
function Profiler.end_timer(name, threshold_ms)
    if not Profiler.enabled then return end
    
    local start_time = Profiler.timers[name]
    if not start_time then
        Logger.warn("Profiler: timer not started for:", name)
        return 0
    end
    
    local elapsed_ms = (love.timer.getTime() - start_time) * 1000
    
    if not Profiler.metrics[name] then
        Profiler.metrics[name] = {
            count = 0,
            total_ms = 0,
            min_ms = math.huge,
            max_ms = 0,
            last_ms = 0
        }
    end
    
    local metric = Profiler.metrics[name]
    metric.count = metric.count + 1
    metric.total_ms = metric.total_ms + elapsed_ms
    metric.min_ms = math.min(metric.min_ms, elapsed_ms)
    metric.max_ms = math.max(metric.max_ms, elapsed_ms)
    metric.last_ms = elapsed_ms
    
    -- Warn if exceeded threshold
    threshold_ms = threshold_ms or 16  -- 60 FPS = 16.67ms
    if elapsed_ms > threshold_ms then
        Logger.warn(string.format("Profiler: %s took %.2fms (threshold: %.0fms)",
            name, elapsed_ms, threshold_ms))
    end
    
    return elapsed_ms
end

-- Get metrics for a named operation
function Profiler.get_metric(name)
    return Profiler.metrics[name]
end

-- Get all metrics
function Profiler.get_all_metrics()
    return Profiler.metrics
end

-- Reset all metrics
function Profiler.reset()
    Profiler.metrics = {}
    Profiler.timers = {}
    Logger.info("Profiler metrics reset")
end

-- Print summary of all metrics
function Profiler.print_summary()
    if not Profiler.enabled then return end
    
    Logger.info("=== Performance Summary ===")
    
    for name, metric in pairs(Profiler.metrics) do
        local avg_ms = metric.total_ms / metric.count
        Logger.info(string.format(
            "%s: count=%d, avg=%.2fms, min=%.2fms, max=%.2fms",
            name, metric.count, avg_ms, metric.min_ms, metric.max_ms))
    end
    
    Logger.info("==========================")
end

-- Get memory usage in MB
function Profiler.get_memory_mb()
    local mem_kb = collectgarbage("count")
    return mem_kb / 1024
end

-- Log memory warning if approaching limit
function Profiler.check_memory(limit_mb)
    limit_mb = limit_mb or 200
    local current_mb = Profiler.get_memory_mb()
    
    if current_mb > limit_mb then
        Logger.warn(string.format("Memory usage high: %.2f MB (limit: %.0f MB)",
            current_mb, limit_mb))
        return false
    end
    
    return true
end

return Profiler
