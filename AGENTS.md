# AGENTS.md - muOS Collection Manager

## Build & Test Commands

```bash
# Full test suite (comprehensive validation)
./run-test.sh

# Build distribution package (.muxapp)
make dist

# Clean build artifacts
make clean

# Deploy to device
make deploy DEVICE_IP=192.168.1.23

# Run unit tests (requires busted)
busted tests/unit/

# Run integration tests
busted tests/integration/

# Run app with test ROMs (manual testing)
MUOS_ROMS_PATH=/tmp/muos-test-roms love .
```

## Spec Kit Commands

```bash
# Create/update project governing principles and development guidelines
/speckit.constitution

# Define what you want to build (requirements and user stories)
/speckit.specify

# Create technical implementation plan with architecture and tech stack choices
/speckit.plan

# Generate actionable task lists from implementation plan
/speckit.tasks

# Execute all tasks to build the feature according to the plan
/speckit.implement

# Clarify underspecified areas (recommended before /speckit.plan)
/speckit.clarify

# Cross-artifact consistency & coverage analysis (run after /speckit.tasks)
/speckit.analyze

# Generate custom quality checklists for requirements validation
/speckit.checklist
```

## Architecture

**Love2D-based game UI framework** for muOS-compatible handhelds (RG35XX, TrimUI, Anbernic). Bundled with Love2D binary + liblove/libluajit libraries for self-contained deployment.

### Core Structure
- `main.lua` - Love2D entry point (load/update/draw/input handlers)
- `src/` - Application modules
  - `config/` - display_config, paths, game configurations
  - `lib/` - logger, utility functions
  - `models/` - data structures (Game, Collection, Filter)
  - `scenes/` - game UI states (search_scene, menu_scene, browse_scene, create_collection_scene)
  - `services/` - game_library, search_engine, collection_manager
  - `ui/` - input_handler, UI components
- `assets/` - icons, fonts, images
- `tests/` - unit and integration tests

### Key Services
- **GameLibrary** - scans ROM directories, parses game metadata
- **SearchEngine** - real-time search with AND/OR filter logic
- **CollectionManager** - persists user-created game collections to `~/.config/muos/collections/`

### File Locations
- Collections: `~/.config/muos/collections/collections.json`
- Metadata cache: `~/.cache/game-vault-manager/metadata_cache.json`
- ROM directories: `/mnt/mmc/ROMS/<SYSTEM>/`

## Code Style & Conventions

**Language**: Lua 5.1/LuaJIT (muOS compatible)

### Naming & Conventions
- Module names: snake_case (e.g., `search_engine.lua`)
- Local variables & functions: snake_case
- Global/module exports: PascalCase (e.g., `local SearchEngine = {}`)
- Constants: UPPER_SNAKE_CASE

### Architecture Principles (Constitution v1.0.0)
1. **Performance-First** - maintain 60 FPS on constrained devices (<16.67ms/frame)
2. **Resource Efficiency** - <256MB RAM, optimized assets, no memory leaks
3. **Input Modularity** - abstract button mappings, support multiple controller layouts
4. **Scene Independence** - independent testable states, no shared mutable globals
5. **Asset Management** - centralized loading, organized directory structure

### Error Handling
- Use `Logger.error()` for critical failures
- Wrap initialization in `pcall()` to catch startup errors
- Fallback UI rendering on error (display error message instead of crashing)
- Save error stack traces via `debug.traceback()`

### Performance Requirements
- Maintain 60 FPS during gameplay (target <16ms/frame)
- Scene transitions <3 seconds
- Support 10,000+ games with <10MB memory
- Benchmark on RG35XX (Cortex-A7 @ 1.5GHz, 256MB RAM)

### Testing
- Unit tests: `tests/unit/` (use busted framework)
- Integration tests: `tests/integration/`
- Manual testing on actual muOS hardware required before feature completion
