# Game Vault

**A dynamic game collection manager for muOS and TrimUI devices**

A dynamic game collection management system for muOS-compatible retro handhelds, built with Love2D.

## Features

- 🔍 **Search Games by Name** - Real-time case-insensitive search with partial matching
- 📁 **Custom Collections** - Create and save dynamic collections based on search criteria
- 🎯 **Multi-Filter Search** - Combine filters by genre, year, player count with AND/OR logic
- ⚡ **Performance Optimized** - Maintains 60 FPS with 10,000+ games, <10MB memory usage
- 🎮 **Universal Controller Support** - Works with all muOS device button layouts

## Installation

### Requirements

- muOS firmware version 2405+ (Beans or later)
- Supported devices: RG35XX, Anbernic handhelds, TrimUI devices
- ~10MB storage space for application

### Installation Steps

1. **Download** the latest release from [GitHub Releases](https://github.com/jellydn/muos-collection-manager/releases)

   - File: `game-vault-<version>.muxapp`

2. **Copy to SD Card**

   - Place the `.muxapp` file in the `/ARCHIVE` folder on your SD1 card

3. **Extract with Archive Manager**

   - On your device, open the muOS Archive Manager app
   - Navigate to the `.muxapp` file
   - Select it and choose "Extract"
   - The app will be installed to `/MUOS/application/GameVault/`

4. **Launch**
   - Find "muOS Collection Manager" in your Applications menu
   - Select to launch

### Building from Source (Advanced)

This app bundles Love2D binary and libraries (like BoxartBuddy) for maximum compatibility.

#### Build and Deploy

```bash
# Build .muxapp package
make dist

# Deploy to device over network
make deploy DEVICE_IP=192.168.1.23
```

The build process creates `dist/game-vault-<version>.muxapp` with everything bundled.

**Why bundle Love2D?**

- ✅ muOS does NOT include Love2D system-wide
- ✅ Self-contained - works on any muOS device
- ✅ No system dependencies required

## Usage

### First Run

On first launch, the app will:

1. Scan your ROM directories (`/mnt/mmc/ROMS/`)
2. Extract game metadata from filenames
3. Build search index (may take 10-30 seconds for large libraries)
4. Create default collections ("All Games", "Favorites", "Recently Played")

### Controls

| Button | Action                                |
| ------ | ------------------------------------- |
| D-Pad  | Navigate menus and lists              |
| A      | Confirm/Select                        |
| B      | Back/Cancel                           |
| X      | Delete collection (with confirmation) |
| Y      | Toggle favorite on selected game      |
| L      | Open filter panel (in search scene)   |
| R      | Toggle AND/OR filter mode             |
| START  | Open menu / Save as collection        |
| SELECT | Quick filter menu                     |

### Searching for Games

1. From main menu, select "Search Games"
2. Type game name using on-screen keyboard (or physical keyboard if connected)
3. Results update in real-time as you type
4. Press START to save current search as a collection

### Creating Collections

1. Perform a search with your desired criteria
2. Press START and select "Save as Collection"
3. Enter a name (1-50 characters)
4. Collection appears in main menu

### Using Filters (Advanced)

1. In Search scene, press L to open filter panel
2. Add filters: Genre, Year, Player Count, Favorite
3. Press R to toggle between AND/OR logic
4. Filters combine with name search automatically

## Platform Configuration

Game Vault automatically detects platforms from your ROM directory names. You can customize how platform names are displayed in the UI.

### Automatic Platform Detection

The app detects platforms by analyzing your ROM directory structure:

```
/mnt/mmc/ROMS/
├── Nintendo Game Boy Advance/  → Detected as: gba
├── Sony Playstation Portable/  → Detected as: psp
├── Sega Mega CD - Sega CD/     → Detected as: segacd
└── ...
```

**Detection is intelligent:**
- Case-insensitive pattern matching
- Handles full names ("Nintendo Game Boy Advance") and abbreviations ("GBA")
- Most specific patterns checked first (e.g., "Game Boy Advance" before "Game Boy")

### Customizing Platform Names

Edit `platform_config.json` in the application root to customize display names:

```json
{
  "version": "1.0.0",
  "platform_names": {
    "gba": "Nintendo Game Boy Advance",
    "ps1": "Sony PlayStation",
    "segacd": "Sega Mega CD - Sega CD"
  }
}
```

**Benefits:**
- Change capitalization (PlayStation vs Playstation)
- Regional preferences (Genesis vs Mega Drive)
- Add new platforms without code changes
- Match muOS catalogue names for box art compatibility

**📖 Full documentation:** See [PLATFORM_CONFIG.md](PLATFORM_CONFIG.md) for:
- Complete platform list
- Detection patterns reference
- Customization examples
- Troubleshooting guide

## File Locations

- **Collections**: `~/.config/muos/collections/collections.json`
- **Metadata Cache**: `~/.cache/muos-collection-manager/metadata_cache.json`
- **Settings**: `~/.config/muos/collections/settings.json`
- **Platform Names**: `platform_config.json` (in application root)
- **ROM Directories**: `/mnt/mmc/ROMS/<SYSTEM>/`

## Performance Benchmarks

Tested on RG35XX (ARM Cortex-A7 @ 1.5GHz, 256MB RAM):

| Library Size | Search Time | Memory Usage | FPS |
| ------------ | ----------- | ------------ | --- |
| 1,000 games  | <100ms      | ~5MB         | 60  |
| 5,000 games  | <300ms      | ~8MB         | 60  |
| 10,000 games | <500ms      | ~10MB        | 60  |

**Performance Monitoring:**

- Press F1 to toggle debug mode (shows FPS counter and memory usage)
- Press F2 to print profiler summary to console
- Performance logs are written to `game-vault-launch.log`

## Troubleshooting

### Common Issues

**App won't launch:**

- Check logs: `/mnt/mmc/MUOS/application/GameVault/data/log/game-vault-launch.log`
- Verify Love2D binary exists in package
- See TROUBLESHOOTING.md for detailed solutions

**No games found:**

- Verify ROM directories: `ls /mnt/mmc/ROMS/`
- Re-scan library from Settings menu

**For developers - Build fails:**

```bash
# Missing Love2D binary/libraries error
./get-love-from-device.sh YOUR_DEVICE_IP
make dist
```

## Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/jellydn/muos-collection-manager.git
cd muos-collection-manager

# Install dependencies (macOS)
brew install --cask love

# Run with Love2D
./run-test.sh

# Package for muOS
make dist

# Clean build artifacts
make clean
```

### Running Tests

```bash
# Install busted (optional, for unit tests)
luarocks install busted

# Run unit tests
busted tests/unit/

# Run integration tests
busted tests/integration/

# Run with test ROMs (macOS)
./run-test.sh
```

### Project Structure

```
.
├── main.lua                 # Love2D entry point
├── conf.lua                 # Love2D configuration
├── src/
│   ├── config/             # Configuration modules (paths, display, input)
│   ├── lib/                # Utilities (logger, json, profiler, error_handler)
│   ├── models/             # Data models (Game, Collection, Filter, SearchIndex)
│   ├── scenes/             # UI scenes (search, menu, browse, create_collection, settings)
│   ├── services/           # Business logic (GameLibrary, SearchEngine, CollectionManager, FilterEngine, Persistence, GameLauncher)
│   └── ui/                 # UI components (SearchBar, GameGrid, FilterPanel, Dialog, InputHandler, Keyboard)
├── assets/
│   ├── fonts/             # Font files
│   ├── images/            # Icons and sprites
│   └── sounds/            # UI sound effects
├── tests/
│   ├── unit/              # Unit tests
│   └── integration/       # Integration tests
├── specs/                 # Specification documents
└── docs/                  # Additional documentation
```

### Architecture Principles

See [.specify/memory/constitution.md](.specify/memory/constitution.md) for project governance principles.

### Performance & Testing

See [HARDWARE_TESTING.md](HARDWARE_TESTING.md) for device testing procedures and performance targets.

## License

MIT License - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please:

1. Follow the [Constitution](.specify/memory/constitution.md) principles
2. Maintain 60 FPS performance
3. Test on actual muOS hardware
4. Update documentation

## Support

- Issues: https://github.com/jellydn/muos-collection-manager/issues
- muOS Discord: https://muos.dev/
- Love2D Forums: https://love2d.org/forums/

## Credits

- Built with [Love2D](https://love2d.org/)
- JSON library: [rxi/json.lua](https://github.com/rxi/json.lua)
- Inspired by [Knulli Dynamic Collections](https://knulli.org/configure/collections/#dynamic-collections)
- Built for [muOS](https://muos.dev/)
