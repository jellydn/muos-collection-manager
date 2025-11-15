# muOS Collection Manager

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
   - File: `muos-collection-<version>.muxapp`

2. **Copy to SD Card**
   - Place the `.muxapp` file in the `/ARCHIVE` folder on your SD1 card

3. **Extract with Archive Manager**
   - On your device, open the muOS Archive Manager app
   - Navigate to the `.muxapp` file
   - Select it and choose "Extract"
   - The app will be installed to `/MUOS/application/muOS-Collection/`

4. **Launch**
   - Find "muOS Collection Manager" in your Applications menu
   - Select to launch

### Building from Source (Advanced)

```bash
# Clone repository
git clone https://github.com/jellydn/muos-collection-manager.git
cd muos-collection-manager

# Build .muxapp package
make dist

# Deploy to device over network (optional)
make deploy DEVICE_IP=192.168.1.100
```

The build process creates a `.muxapp` file in the `dist/` directory.

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

## File Locations

- **Collections**: `~/.config/muos/collections/collections.json`
- **Metadata Cache**: `~/.cache/muos-collection-manager/metadata_cache.json`
- **Settings**: `~/.config/muos/collections/settings.json`
- **ROM Directories**: `/mnt/mmc/ROMS/<SYSTEM>/`

## Performance Benchmarks

Tested on RG35XX (ARM Cortex-A7 @ 1.5GHz, 256MB RAM):

| Library Size | Search Time | Memory Usage | FPS |
| ------------ | ----------- | ------------ | --- |
| 1,000 games  | <100ms      | ~5MB         | 60  |
| 5,000 games  | <300ms      | ~8MB         | 60  |
| 10,000 games | <500ms      | ~10MB        | 60  |

## Troubleshooting

### App won't launch

- Verify muOS firmware is 2405+ (Beans or later)
- Check Love2D is installed: `love --version`
- Check file permissions: `chmod +x muos-collection-manager.love`

### No games found

- Verify ROM directories exist: `ls /mnt/mmc/ROMS/`
- Check ROM file extensions are supported (see File Locations)
- Re-scan library from Settings menu

### Search is slow

- First search builds index (one-time cost)
- Subsequent searches should be <100-500ms
- Check memory usage isn't hitting 256MB limit

### Collections not saving

- Check directory permissions: `~/.config/muos/collections/`
- Verify disk space available: `df -h`
- Check logs for JSON write errors

## Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/jellydn/muos-collection-manager.git
cd muos-collection-manager

# Run with Love2D
love .

# Package for muOS
zip -r muos-collection-manager.love . -x ".*" "tests/*" "specs/*"
```

### Running Tests

```bash
# Install busted (optional, for unit tests)
luarocks install busted

# Run unit tests
busted tests/unit/

# Run integration tests
busted tests/integration/
```

### Project Structure

See [specs/001-collection-search/plan.md](specs/001-collection-search/plan.md) for detailed architecture.

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
