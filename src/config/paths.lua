-- Path configuration for muOS filesystem
-- Constitution: II. Resource Efficiency (organized file storage)

local Paths = {}

-- Environment variables
local home = os.getenv("HOME") or "~"
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
Paths.rom_dirs = {
    Paths.roms_root .. "/NES/",
    Paths.roms_root .. "/SNES/",
    Paths.roms_root .. "/GB/",
    Paths.roms_root .. "/GBC/",
    Paths.roms_root .. "/GBA/",
    Paths.roms_root .. "/N64/",
    Paths.roms_root .. "/PS1/",
    Paths.roms_root .. "/GENESIS/",
    Paths.roms_root .. "/SEGACD/",
    Paths.roms_root .. "/ARCADE/"
}

-- Supported ROM file extensions by system
Paths.rom_extensions = {
    NES = {".nes", ".unf", ".unif"},
    SNES = {".smc", ".sfc", ".swc", ".fig"},
    GB = {".gb"},
    GBC = {".gbc"},
    GBA = {".gba"},
    N64 = {".n64", ".z64", ".v64"},
    PS1 = {".cue", ".bin", ".chd", ".pbp"},
    GENESIS = {".md", ".bin", ".gen"},
    SEGACD = {".cue", ".chd"},
    ARCADE = {".zip"}
}

-- Initialize directories (create if don't exist)
function Paths.init()
    os.execute("mkdir -p " .. Paths.config_dir)
    os.execute("mkdir -p " .. Paths.data_dir)
    os.execute("mkdir -p " .. Paths.cache_dir)
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

-- Check if file is a valid ROM
function Paths.is_rom_file(filename, system)
    local ext = Paths.get_extension(filename):lower()
    local extensions = Paths.rom_extensions[system:upper()]

    if not extensions then
        return false
    end

    for _, valid_ext in ipairs(extensions) do
        if ext == valid_ext then
            return true
        end
    end

    return false
end

return Paths
