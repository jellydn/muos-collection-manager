-- Path configuration for muOS filesystem
-- Constitution: II. Resource Efficiency (organized file storage)

local Logger = require("src.lib.logger")
local Shell = require("src.lib.shell")
local Paths = {}

-- Environment variables
local home = os.getenv("HOME") or "~"

-- Helper function: Check if directory exists
local function dir_exists(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok
end

-- Detect ROM path: check environment variable first (set by launcher script)
-- TrimUI CrossMix OS uses /mnt/SDCARD/Roms
-- muOS uses /mnt/mmc/ROMS
local default_roms_path
if dir_exists("/mnt/SDCARD/Roms") then
    default_roms_path = "/mnt/SDCARD/Roms"
elseif dir_exists("/mnt/SDCARD/roms") then
    default_roms_path = "/mnt/SDCARD/roms"
else
    default_roms_path = "/mnt/mmc/ROMS"
end

local muos_roms = os.getenv("MUOS_ROMS_PATH") or default_roms_path

-- Detect if running on TrimUI
Paths.is_trimui = default_roms_path:match("/mnt/SDCARD") ~= nil

-- muOS user data directory (follows XDG Base Directory spec)
Paths.config_dir = home .. "/.config/muos/collections/"
Paths.data_dir = home .. "/.local/share/gamevault/"
Paths.cache_dir = home .. "/.cache/gamevault/"

-- Collection data files
Paths.collections_file = Paths.config_dir .. "collections.json"
Paths.metadata_cache_file = Paths.cache_dir .. "metadata_cache.json"
Paths.settings_file = Paths.config_dir .. "settings.json"

-- ROM directories (auto-detected for muOS or TrimUI)
Paths.roms_root = muos_roms
Paths.rom_root = muos_roms  -- Alias for compatibility

-- All supported ROM file extensions (flattened for flexible scanning)
-- Archive formats (.zip, .7z, .rar) are supported universally
Paths.all_rom_extensions = {
    -- NES/Famicom
    ".nes", ".unf", ".unif", ".fds",
    -- SNES/Super Famicom
    ".smc", ".sfc", ".swc", ".fig",
    -- Game Boy / Game Boy Color
    ".gb", ".gbc",
    -- Game Boy Advance
    ".gba",
    -- Nintendo 64
    ".n64", ".z64", ".v64",
    -- Nintendo DS
    ".nds",
    -- PlayStation 1
    ".cue", ".bin", ".chd", ".pbp", ".iso", ".img",
    -- PSP
    ".cso", ".dax",
    -- Genesis/Mega Drive
    ".md", ".gen", ".smd",
    -- Master System
    ".sms",
    -- Game Gear
    ".gg",
    -- Dreamcast
    ".cdi", ".gdi",
    -- Sega CD
    -- Ports (various executable formats)
    ".sh", ".appimage",
    -- Archive formats (universal)
    ".zip", ".7z", ".rar"
}

-- System detection patterns based on file extension
Paths.extension_to_system = {
    -- Nintendo
    [".nes"] = "nes", [".unf"] = "nes", [".unif"] = "nes", [".fds"] = "nes",
    [".smc"] = "snes", [".sfc"] = "snes", [".swc"] = "snes", [".fig"] = "snes",
    [".gb"] = "gb",
    [".gbc"] = "gbc",
    [".gba"] = "gba",
    [".n64"] = "n64", [".z64"] = "n64", [".v64"] = "n64",
    [".nds"] = "nds",
    -- Sony
    [".cue"] = "ps1", [".pbp"] = "ps1", [".iso"] = "ps1", [".img"] = "ps1",
    [".cso"] = "psp", [".dax"] = "psp",
    -- Sega
    [".md"] = "genesis", [".gen"] = "genesis", [".smd"] = "genesis",
    [".sms"] = "mastersystem",
    [".gg"] = "gamegear",
    [".cdi"] = "dreamcast", [".gdi"] = "dreamcast",
    -- Ports
    [".sh"] = "ports", [".appimage"] = "ports",
    -- Multi-system formats (context-dependent)
    [".bin"] = "unknown", -- Could be PS1, Genesis, etc.
    [".chd"] = "unknown"  -- Could be PS1, Dreamcast, Sega CD, etc.
}

-- Legacy: Supported ROM file extensions by system (kept for backward compatibility)
Paths.rom_extensions = {
    -- Nintendo
    NES = {".nes", ".unf", ".unif", ".fds", ".zip", ".7z", ".rar"},
    FC = {".nes", ".unf", ".unif", ".fds", ".zip", ".7z", ".rar"},
    SNES = {".smc", ".sfc", ".swc", ".fig", ".zip", ".7z", ".rar"},
    SFC = {".smc", ".sfc", ".swc", ".fig", ".zip", ".7z", ".rar"},
    GB = {".gb", ".zip", ".7z", ".rar"},
    GBC = {".gbc", ".zip", ".7z", ".rar"},
    GBA = {".gba", ".zip", ".7z", ".rar"},
    N64 = {".n64", ".z64", ".v64", ".zip", ".7z", ".rar"},
    NDS = {".nds", ".zip", ".7z", ".rar"},
    -- Sony
    PS = {".cue", ".bin", ".chd", ".pbp", ".iso", ".img", ".zip", ".7z", ".rar"},
    PS1 = {".cue", ".bin", ".chd", ".pbp", ".iso", ".img", ".zip", ".7z", ".rar"},
    PSP = {".cso", ".dax", ".iso", ".pbp", ".zip", ".7z", ".rar"},
    -- Sega
    GENESIS = {".md", ".bin", ".gen", ".smd", ".zip", ".7z", ".rar"},
    MD = {".md", ".bin", ".gen", ".smd", ".zip", ".7z", ".rar"},
    MS = {".sms", ".zip", ".7z", ".rar"},
    GG = {".gg", ".zip", ".7z", ".rar"},
    DC = {".cdi", ".gdi", ".chd", ".zip", ".7z", ".rar"},
    SEGACD = {".cue", ".bin", ".chd", ".zip", ".7z", ".rar"},
    -- Arcade
    ARCADE = {".zip", ".7z", ".rar"},
    FBNEO = {".zip", ".7z", ".rar"},
    -- Ports
    PORTS = {".sh", ".AppImage", ".zip", ".7z", ".rar"}
}

-- Initialize directories (create if don't exist)
function Paths.init()
    Shell.execute("mkdir -p %s", Paths.config_dir)
    Shell.execute("mkdir -p %s", Paths.data_dir)
    Shell.execute("mkdir -p %s", Paths.cache_dir)

    -- Log ROM path for debugging
    Logger.info("ROM root path:", Paths.roms_root)
end

-- Check if file exists
function Paths.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Check if directory exists
function Paths.dir_exists(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok
end

-- Get file extension
function Paths.get_extension(filename)
    return filename:match("^.+(%..+)$") or ""
end

-- Get system from ROM path
function Paths.get_system_from_path(file_path)
    for system, _ in pairs(Paths.rom_extensions) do
        if file_path:find("/" .. system .. "/", 1, true) then
            return system:lower()
        end
    end
    return "unknown"
end

-- Check if file is a valid ROM (any supported extension)
function Paths.is_rom_file(filename)
    local ext = Paths.get_extension(filename):lower()

    for _, valid_ext in ipairs(Paths.all_rom_extensions) do
        if ext == valid_ext then
            return true
        end
    end

    return false
end

-- Detect system from file extension or path
function Paths.detect_system_from_path(file_path)
    local filename = file_path:match("([^/]+)$") or file_path
    local ext = Paths.get_extension(filename):lower()

    -- Extract the system directory (the one containing ROM files)
    -- This should be the first directory after ROMS/
    -- Examples:
    --   /mnt/mmc/ROMS/SNES/game.sfc -> SNES
    --   /mnt/mmc/ROMS/SNES/Favorites/game.sfc -> SNES (skip subdirectories)
    --   /tmp/muos-test-roms/GBA/game.gba -> GBA
    local parent_dir = file_path:match("/ROMS/([^/]+)/") or file_path:match("/([^/]+)/[^/]+$")
    
    -- Debug logging for UNKNOWN detection
    local detected_system = "unknown"
    
    if parent_dir then
        local parent_upper = parent_dir:upper()
        
        -- Check exact match first
        if Paths.rom_extensions[parent_upper] then
            detected_system = parent_upper:lower()
        -- Check partial matches for common naming patterns
        -- Nintendo Systems
        elseif parent_upper:find("SNES") or parent_upper:find("SUPER.*FAMICOM") or parent_upper:find("SUPER.*NINTENDO") then detected_system = "snes"
        elseif parent_upper:find("SFC") then detected_system = "snes"
        elseif parent_upper:find("NES") or parent_upper:find("FAMICOM") then detected_system = "nes"
        elseif parent_upper:find("^FC$") then detected_system = "nes"
        elseif parent_upper:find("GBA") or parent_upper:find("GAMEBOY.*ADVANCE") then detected_system = "gba"
        elseif parent_upper:find("GBC") or parent_upper:find("GAMEBOY.*COLOR") then detected_system = "gbc"
        elseif parent_upper:find("GB") or parent_upper:find("GAMEBOY") then detected_system = "gb"
        elseif parent_upper:find("N64") or parent_upper:find("NINTENDO.*64") then detected_system = "n64"
        elseif parent_upper:find("NDS") or parent_upper:find("NINTENDO.*DS") or parent_upper:find("DS") then detected_system = "nds"
        -- Sony Systems (PSP must come before PS1!)
        elseif parent_upper:find("PSP") then detected_system = "psp"
        elseif parent_upper:find("PS1") or parent_upper:find("PSX") or parent_upper:find("^PS$") or parent_upper:find("PLAYSTATION") then detected_system = "ps1"
        -- Sega Systems
        elseif parent_upper:find("DREAMCAST") or parent_upper:find("^DC$") then detected_system = "dreamcast"
        elseif parent_upper:find("GENESIS") or parent_upper:find("MEGADRIVE") or parent_upper:find("MEGA.*DRIVE") then detected_system = "genesis"
        elseif parent_upper:find("^MD$") then detected_system = "genesis"
        elseif parent_upper:find("MASTER.*SYSTEM") or parent_upper:find("^MS$") then detected_system = "mastersystem"
        elseif parent_upper:find("GAME.*GEAR") or parent_upper:find("^GG$") then detected_system = "gamegear"
        elseif parent_upper:find("SEGACD") or parent_upper:find("SEGA.*CD") or parent_upper:find("MEGA.*CD") then detected_system = "segacd"
        -- Bandai
        elseif parent_upper:find("WONDERSWAN") or parent_upper:find("WSC") then detected_system = "wonderswan"
        -- Arcade
        elseif parent_upper:find("ARCADE") or parent_upper:find("MAME") or parent_upper:find("FBA") or parent_upper:find("FBNEO") then detected_system = "arcade"
        -- Ports
        elseif parent_upper:find("PORT") then detected_system = "ports"
        else
            -- Fall back to extension mapping
            detected_system = Paths.extension_to_system[ext] or "unknown"
        end
    else
        -- No parent directory, use extension only
        detected_system = Paths.extension_to_system[ext] or "unknown"
    end
    
    -- Log UNKNOWN detections for debugging
    if detected_system == "unknown" then
        local Logger = require("src.lib.logger")
        Logger.warn("UNKNOWN system detected - Path:", file_path, "Parent:", parent_dir or "none", "Ext:", ext)
    end
    
    return detected_system
end

return Paths
