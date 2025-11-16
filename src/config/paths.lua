-- Path configuration for muOS filesystem
-- Constitution: II. Resource Efficiency (organized file storage)

local Logger = require("src.lib.logger")
local Paths = {}

-- Environment variables
local home = os.getenv("HOME") or "~"

-- Detect ROM path: check environment variable first (set by launcher script)
-- Falls back to standard muOS path if not set
local muos_roms = os.getenv("MUOS_ROMS_PATH") or "/mnt/mmc/ROMS"

-- muOS user data directory (follows XDG Base Directory spec)
Paths.config_dir = home .. "/.config/muos/collections/"
Paths.data_dir = home .. "/.local/share/gamevault/"
Paths.cache_dir = home .. "/.cache/gamevault/"

-- Collection data files
Paths.collections_file = Paths.config_dir .. "collections.json"
Paths.metadata_cache_file = Paths.cache_dir .. "metadata_cache.json"
Paths.settings_file = Paths.config_dir .. "settings.json"

-- ROM directories (muOS standard paths)
Paths.roms_root = muos_roms

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
    ".sh", ".AppImage",
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
    [".sh"] = "ports", [".AppImage"] = "ports",
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
    os.execute("mkdir -p " .. Paths.config_dir)
    os.execute("mkdir -p " .. Paths.data_dir)
    os.execute("mkdir -p " .. Paths.cache_dir)

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

    -- Check if it's an archive format - need to detect from parent directory
    if ext == ".zip" or ext == ".7z" or ext == ".rar" then
        -- Extract parent directory name from path
        local parent_dir = file_path:match("/([^/]+)/[^/]+$")
        if parent_dir then
            -- Check if parent directory name matches a known system
            local parent_upper = parent_dir:upper()
            if Paths.rom_extensions[parent_upper] then
                return parent_upper:lower()
            end

            -- Try partial matches (e.g., "Nintendo64" -> "N64", "GameBoy" -> "GB")
            -- Check specific patterns first to avoid false matches
            -- Nintendo Systems
            if parent_upper:find("SNES") or parent_upper:find("SUPER.*FAMICOM") or parent_upper:find("SUPER.*NINTENDO") then return "snes"
            elseif parent_upper:find("SFC") then return "snes"
            elseif parent_upper:find("NES") or parent_upper:find("FAMICOM") then return "nes"
            elseif parent_upper:find("^FC$") then return "nes"
            elseif parent_upper:find("GBA") or parent_upper:find("GAMEBOY.*ADVANCE") then return "gba"
            elseif parent_upper:find("GBC") or parent_upper:find("GAMEBOY.*COLOR") then return "gbc"
            elseif parent_upper:find("GB") or parent_upper:find("GAMEBOY") then return "gb"
            elseif parent_upper:find("N64") or parent_upper:find("NINTENDO.*64") then return "n64"
            elseif parent_upper:find("NDS") or parent_upper:find("NINTENDO.*DS") or parent_upper:find("DS") then return "nds"
            -- Sony Systems
            elseif parent_upper:find("PSP") then return "psp"
            elseif parent_upper:find("PS1") or parent_upper:find("PSX") or parent_upper:find("^PS$") or parent_upper:find("PLAYSTATION") then return "ps1"
            -- Sega Systems
            elseif parent_upper:find("DREAMCAST") or parent_upper:find("^DC$") then return "dreamcast"
            elseif parent_upper:find("GENESIS") or parent_upper:find("MEGADRIVE") or parent_upper:find("MEGA.*DRIVE") then return "genesis"
            elseif parent_upper:find("^MD$") then return "genesis"
            elseif parent_upper:find("MASTER.*SYSTEM") or parent_upper:find("^MS$") then return "mastersystem"
            elseif parent_upper:find("GAME.*GEAR") or parent_upper:find("^GG$") then return "gamegear"
            elseif parent_upper:find("SEGACD") or parent_upper:find("SEGA.*CD") then return "segacd"
            -- Arcade
            elseif parent_upper:find("ARCADE") or parent_upper:find("MAME") or parent_upper:find("FBA") or parent_upper:find("FBNEO") then return "arcade"
            -- Ports
            elseif parent_upper:find("PORT") then return "ports"
            end
        end

        -- Default to arcade for unidentified archives
        return "arcade"
    end

    -- Look up in extension to system map
    return Paths.extension_to_system[ext] or "unknown"
end

return Paths
