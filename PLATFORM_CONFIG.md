# Platform Configuration

## Overview

The `platform_config.json` file allows you to customize how platform/system names are displayed in the muOS Game Vault application.

## Location

The config file should be placed in the root directory of the application:
```
muos-game-vault/
├── platform_config.json    ← Edit this file
├── main.lua
└── ...
```

## Format

```json
{
  "version": "1.0.0",
  "platform_names": {
    "system_key": "Display Name",
    ...
  }
}
```

### Fields

- **version**: Config file version (currently `1.0.0`)
- **platform_names**: Object mapping system keys to display names

### System Keys

System keys are detected from your ROM directory names. They are **case-insensitive** during detection.

**Examples:**
- Directory: `Nintendo Game Boy Advance` → Detected as: `gba`
- Directory: `Sony Playstation` → Detected as: `ps1`
- Directory: `Sega Mega CD - Sega CD` → Detected as: `segacd`

### Display Names

Display names are what appear in the UI (platform browser, game info, etc.).

**Important:** Display names should match muOS catalogue folder names from:
- `/mnt/mmc/MUOS/info/catalogue/`
- `catalogue=` values in `/mnt/mmc/MUOS/info/assign/<system>/global.ini`

This ensures box art and metadata load correctly.

## Customization Examples

### Example 1: Change "Sony Playstation" to "Sony PlayStation"

```json
{
  "platform_names": {
    "ps1": "Sony PlayStation",
    "ps": "Sony PlayStation",
    "psx": "Sony PlayStation"
  }
}
```

### Example 2: Add support for a new platform

```json
{
  "platform_names": {
    "3ds": "Nintendo 3DS",
    "wiiu": "Nintendo Wii U"
  }
}
```

### Example 3: Use different regional naming

```json
{
  "platform_names": {
    "genesis": "Sega Genesis",
    "md": "Sega Mega Drive"
  }
}
```

## Multiple Keys → Same Display Name

Multiple system keys can map to the same display name. This is useful for:

1. **Abbreviations**: `ps`, `ps1`, `psx` → "Sony Playstation"
2. **Regional variants**: `genesis`, `md` → "Sega Mega Drive-Genesis"
3. **Arcade systems**: `arcade`, `mame`, `fbneo`, `fba` → "Arcade"

## Default Mappings

If `platform_config.json` is missing or invalid, the application uses these defaults:

| System Key | Display Name |
|------------|--------------|
| `nes`, `fc` | Nintendo NES - Famicom |
| `snes`, `sfc` | Nintendo SNES - SFC |
| `gb` | Nintendo Game Boy |
| `gbc` | Nintendo Game Boy Color |
| `gba` | Nintendo Game Boy Advance |
| `n64` | Nintendo N64 |
| `nds` | Nintendo DS |
| `ps1`, `ps`, `psx` | Sony Playstation |
| `psp` | Sony Playstation Portable |
| `genesis`, `md` | Sega Mega Drive-Genesis |
| `mastersystem`, `ms`, `sms` | Sega Master System |
| `gamegear`, `gg` | Sega Game Gear |
| `dreamcast`, `dc` | Sega Dreamcast |
| `segacd` | Sega Mega CD - Sega CD |
| `wonderswan`, `wsc` | Bandai WonderSwan-Color |
| `arcade`, `mame`, `fbneo`, `fba` | Arcade |
| `atari2600` | Atari 2600 |
| `atari7800` | Atari 7800 |
| `lynx` | Atari Lynx |
| `ngp` | SNK Neo Geo Pocket |
| `pico8` | PICO-8 |
| `ports` | Ports |

## Troubleshooting

### Platform shows as "UNKNOWN" or uppercase system key

**Cause:** The system key is not in your `platform_config.json`

**Solution:** Add the system key to your config file:

```json
{
  "platform_names": {
    "yourkey": "Your Platform Name"
  }
}
```

### Config file not loading

**Cause:** JSON syntax error or file not in correct location

**Solution:**
1. Validate JSON syntax at [jsonlint.com](https://jsonlint.com)
2. Ensure file is in application root directory
3. Check application logs for parsing errors

### Box art not loading after changing display names

**Cause:** Display name doesn't match muOS catalogue folder

**Solution:** Use the exact folder name from `/mnt/mmc/MUOS/info/catalogue/`

## Platform Detection Reference

The application detects platforms using these patterns from ROM directory names:

| Directory Pattern | Detected Key |
|-------------------|--------------|
| Contains "NES" or "FAMICOM" | `nes` |
| Contains "SNES" or "SUPER NINTENDO" or "SFC" | `snes` |
| Contains "GAME BOY ADVANCE" or "GBA" | `gba` |
| Contains "GAME BOY COLOR" or "GBC" | `gbc` |
| Contains "GAME BOY" or "GB" | `gb` |
| Contains "N64" or "NINTENDO 64" | `n64` |
| Contains "NINTENDO DS" or "NDS" | `nds` |
| Contains "PLAYSTATION PORTABLE" or "PSP" | `psp` |
| Contains "PLAYSTATION" or "PS1" or "PSX" | `ps1` |
| Contains "SEGA CD" or "MEGA CD" | `segacd` |
| Contains "WONDERSWAN" or "WSC" | `wonderswan` |
| Contains "ARCADE" or "MAME" or "FBNEO" | `arcade` |
| Contains "PORT" | `ports` |

**Note:** Pattern matching is case-insensitive and checks most specific patterns first (e.g., "Game Boy Advance" before "Game Boy").
