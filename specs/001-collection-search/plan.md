# Implementation Plan: Dynamic Game Collections

**Branch**: `001-collection-search` | **Date**: 2025-11-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-collection-search/spec.md`

## Summary

Build a dynamic game collection management system for muOS using Love2D/Lua that allows players to search games by name with real-time filtering, create persistent custom collections, and apply multiple search filters (genre, year, player count). The system must maintain 60 FPS performance, support libraries up to 10,000 games, and use <10MB memory within the 256MB device constraint.

**Technical Approach**: Implement a scene-based architecture with optimized in-memory search indexing, Lua table-based data structures for collections, and JSON file persistence. Use Love2D's built-in input handling for keyboard/controller support and efficient rendering with batch drawing for game grids.

## Technical Context

**Language/Version**: Lua 5.1/5.2 (LuaJIT compatible) via Love2D 11.4+
**Primary Dependencies**: Love2D 11.4+ framework, json.lua for collection persistence, utf8 library for text handling
**Storage**: JSON files in muOS user data directory (`~/.config/muos/collections/`)
**Testing**: Manual testing on muOS hardware/emulation, busted for unit tests (optional), performance profiling with love.timer
**Target Platform**: muOS-compatible retro handhelds (RG35XX, Anbernic devices, etc.) - 320×240 to 640×480 displays
**Project Type**: Single Love2D application (standalone .love package)
**Performance Goals**: 60 FPS constant, <100ms search response for 1K games, <500ms for 10K games, <3s scene transitions
**Constraints**: <10MB memory for collection system, <256MB total app, <50ms file I/O, 60 FPS maintained during scrolling
**Scale/Scope**: Support 10,000+ games, 50+ custom collections, 5-10 scenes (menu, search, browse, create, settings)

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### I. Performance-First ✅ PASS

- **60 FPS Requirement**: Spec defines 60 FPS maintenance (SC-008), search response times <100-500ms (SC-002, SC-003)
- **Frame Budget**: <16.67ms per frame - search debouncing and incremental rendering planned
- **Profiling Plan**: Will use love.timer for frame time monitoring, identify bottlenecks in search/render loops

### II. Resource Efficiency ✅ PASS

- **Memory Budget**: <10MB for collection system (SC-007), well within 256MB total
- **Storage**: JSON files are compact, estimated <1MB for 50 collections
- **Battery**: No background processes, efficient Lua table operations, minimal file I/O
- **Optimization**: Case-insensitive search via lowercase indexing (one-time cost), reuse game objects

### III. Input Modularity ✅ PASS

- **Controller Abstraction**: Will use Love2D input mapping system, support muOS controller profiles
- **No Hard-coding**: Input actions defined in config table (up/down/confirm/back/search)
- **Multi-device**: Works with D-pad, analog stick, and physical keyboards via love.keypressed

### IV. Scene Independence ✅ PASS

- **Independent Scenes**: MenuScene, SearchScene, BrowseScene, CreateCollectionScene, SettingsScene
- **No Shared State**: Each scene manages own state, transitions via scene manager with explicit data passing
- **Testable**: Each scene can be loaded individually with mock data for testing

### V. Asset Management ✅ PASS

- **Organized Structure**: `assets/fonts/`, `assets/images/`, `assets/sounds/` directories
- **Centralized Loading**: AssetManager module loads all resources at startup with error handling
- **No Unused Assets**: Only essential UI elements (icons, fonts) - estimated <2MB total

**Constitution Compliance**: ✅ ALL PRINCIPLES SATISFIED - No violations to justify

## Project Structure

### Documentation (this feature)

```text
specs/001-collection-search/
├── plan.md              # This file (implementation plan)
├── research.md          # Phase 0 output (Love2D best practices)
├── data-model.md        # Phase 1 output (entities and relationships)
├── quickstart.md        # Phase 1 output (setup and run instructions)
├── checklists/
│   └── requirements.md  # Spec validation checklist
└── contracts/           # Phase 1 output (data schemas)
    ├── game-schema.json
    ├── collection-schema.json
    └── filter-schema.json
```

### Source Code (repository root)

```text
muos-collection-manager/      # Love2D application root
├── main.lua                  # Entry point (love.load, love.update, love.draw)
├── conf.lua                  # Love2D configuration (window, modules, identity)
├── game.conf                 # muOS-specific config
│
├── src/
│   ├── scenes/              # Scene management (IV. Scene Independence)
│   │   ├── scene_manager.lua     # Scene transitions and state
│   │   ├── menu_scene.lua        # Main menu
│   │   ├── search_scene.lua      # P1: Search by name
│   │   ├── browse_scene.lua      # Display filtered results
│   │   ├── create_scene.lua      # P2: Create/save collections
│   │   └── settings_scene.lua    # App settings
│   │
│   ├── models/              # Data structures (entities from spec)
│   │   ├── game.lua             # Game entity
│   │   ├── collection.lua       # Collection entity
│   │   ├── search_filter.lua    # Filter criteria
│   │   └── search_index.lua     # In-memory search index
│   │
│   ├── services/            # Business logic
│   │   ├── game_library.lua     # Load/parse game metadata
│   │   ├── search_engine.lua    # Search algorithm (P1)
│   │   ├── collection_manager.lua # CRUD operations (P2)
│   │   ├── filter_engine.lua    # Multi-criteria filtering (P3)
│   │   └── persistence.lua      # JSON save/load
│   │
│   ├── ui/                  # UI components
│   │   ├── input_handler.lua    # Controller/keyboard abstraction (III)
│   │   ├── keyboard.lua         # On-screen keyboard widget
│   │   ├── game_grid.lua        # Virtual scrolling grid renderer
│   │   ├── search_bar.lua       # Search input field
│   │   └── dialog.lua           # Confirmation/prompt dialogs
│   │
│   ├── lib/                 # Utilities and libraries
│   │   ├── json.lua             # JSON encoding/decoding
│   │   ├── utf8.lua             # UTF-8 string operations (if needed)
│   │   └── logger.lua           # Debug logging
│   │
│   └── config/              # Configuration
│       ├── input_config.lua     # Button mappings (III. Input Modularity)
│       ├── display_config.lua   # Resolution/aspect ratio handling
│       └── paths.lua            # File paths for muOS directories
│
├── assets/                  # Game assets (V. Asset Management)
│   ├── fonts/
│   │   └── monospace.ttf        # UI font (embedded or system)
│   ├── images/
│   │   ├── icons/               # UI icons (search, add, delete)
│   │   └── backgrounds/         # Optional scene backgrounds
│   └── sounds/
│       └── ui/                  # Button click, confirmation sounds
│
├── tests/                   # Testing (optional but recommended)
│   ├── unit/
│   │   ├── test_search_engine.lua
│   │   ├── test_filter_engine.lua
│   │   └── test_persistence.lua
│   └── integration/
│       └── test_collection_workflow.lua
│
└── README.md               # Installation for muOS
```

**Structure Decision**: Single Love2D application following standard Lua game architecture. This is a standalone utility app with all source in `src/` organized by layer (scenes, models, services, UI). Scenes are independent per principle IV, with explicit state management through the scene_manager. The structure supports the three priority levels: P1 (search_scene), P2 (create_scene, collection_manager), P3 (filter_engine).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected - this section remains empty per constitution compliance.
