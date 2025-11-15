-- Love2D Configuration for muOS Collection Manager
-- Constitution: I. Performance-First, II. Resource Efficiency

function love.conf(t)
    t.identity = "muos-collection-manager"
    t.version = "11.5"
    t.console = false
    t.accelerometerjoystick = false
    t.externalstorage = false
    t.gammacorrect = false

    t.audio.mic = false
    t.audio.mixwithsystem = true

    t.window.title = "muOS Collection Manager"
    t.window.icon = nil
    t.window.width = 640
    t.window.height = 480
    t.window.borderless = false
    t.window.resizable = false
    t.window.minwidth = 320
    t.window.minheight = 240
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    t.window.highdpi = false
    t.window.usedpiscale = true
    t.window.x = nil
    t.window.y = nil

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false  -- Not needed for UI app
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false   -- Keep simple, no threading
    t.modules.timer = true
    t.modules.touch = false    -- muOS devices use buttons
    t.modules.video = false    -- Not needed
    t.modules.window = true
end
