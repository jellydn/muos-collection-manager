<!--
SYNC IMPACT REPORT - Constitution v1.0.0
========================================
Version Change: [NEW] → 1.0.0 (Initial ratification)
Ratification Date: 2025-11-15

Modified Principles:
- [NEW] I. Performance-First (Game Loop Optimization)
- [NEW] II. Resource Efficiency (Embedded Device Constraints)
- [NEW] III. Input Modularity (Universal Controller Support)
- [NEW] IV. Scene Independence (Testable Game States)
- [NEW] V. Asset Management (Organized Resources)

Added Sections:
- Technical Standards (Love2D, Lua, muOS requirements)
- Development Workflow (Testing and deployment for embedded devices)

Templates Requiring Updates:
✅ plan-template.md - Aligned with game project structure and performance constraints
✅ spec-template.md - User story format compatible with game features
✅ tasks-template.md - Task organization supports modular game development

Follow-up TODOs: None
-->

# muOS Love2D Game Collection Constitution

## Core Principles

### I. Performance-First

Every game feature MUST maintain stable 60 FPS on target muOS devices. Performance profiling is mandatory for new game loops, rendering systems, and physics calculations. Frame time budgets MUST be established and monitored (target: <16.67ms per frame).

**Rationale**: Retro handhelds have limited CPU/GPU resources. Smooth gameplay is non-negotiable for player experience and reflects the quality standards of classic games that inspired this platform.

### II. Resource Efficiency

Games MUST respect embedded device constraints: maximum 256MB RAM usage, minimal storage footprint, and efficient battery usage. All assets MUST be optimized (compressed textures, efficient audio formats). Memory leaks are strictly prohibited.

**Rationale**: muOS runs on constrained hardware. Games that consume excessive resources degrade system performance, drain batteries quickly, and may not run on all target devices.

### III. Input Modularity

Game input systems MUST support multiple controller layouts through abstraction. Hard-coded button mappings are prohibited. All games MUST implement a consistent input configuration system compatible with muOS controller profiles.

**Rationale**: muOS devices vary in button layouts (SNES-style, PlayStation-style, etc.). Players expect games to work seamlessly with their specific device without code changes.

### IV. Scene Independence

Each game scene/state (menu, gameplay, pause, game-over) MUST be independently loadable and testable. Scenes MUST NOT share mutable global state. State transitions MUST be explicit and traceable.

**Rationale**: Independent scenes enable isolated testing, faster iteration, easier debugging, and cleaner architecture. This prevents cascading bugs where issues in one scene affect others.

### V. Asset Management

All game assets (sprites, audio, fonts, maps) MUST be organized in a standardized directory structure. Asset loading MUST be centralized with clear error handling. Unused assets MUST be removed before release.

**Rationale**: Organized assets simplify collaboration, reduce storage waste, enable asset hot-reloading during development, and make games maintainable over time.

## Technical Standards

### Technology Stack

- **Engine**: Love2D 11.4+ (Lua 5.1/LuaJIT compatible)
- **Language**: Lua 5.1/5.2 (muOS compatibility)
- **Target Platform**: muOS-compatible retro handhelds (320×240 to 640×480 displays)
- **Audio**: OGG Vorbis for music, WAV for short SFX
- **Graphics**: PNG for sprites/tilesets, optimized for low-res displays

### Performance Requirements

- Maintain 60 FPS during normal gameplay
- Load times: <3 seconds for scene transitions
- Memory footprint: <256MB total
- Battery impact: Comparable to native muOS applications

### Compatibility Requirements

- Games MUST run on muOS firmware version 2405+ (Beans or later)
- MUST support 4:3 and 16:9 aspect ratios with letterboxing
- MUST handle both portrait and landscape orientations where applicable
- MUST gracefully handle missing or corrupted save data

## Development Workflow

### Testing Requirements

1. **Manual Testing**: All gameplay features MUST be tested on actual muOS hardware or accurate emulation
2. **Performance Testing**: Frame rate profiling MUST be conducted for each major feature
3. **Input Testing**: MUST verify controls work with multiple muOS device profiles
4. **Save/Load Testing**: MUST verify game state persistence across sessions

### Quality Gates

Before any feature is considered complete:

- Performance benchmarks passed (60 FPS maintained)
- No memory leaks detected in 30-minute play session
- Controls verified on at least 2 different controller layouts
- Assets properly compressed and organized
- Code follows Lua style guide (consistent indentation, meaningful names)

### Deployment Standards

- Games MUST include a `game.conf` file with proper Love2D configuration
- MUST provide installation instructions for muOS
- MUST include README with controls, objectives, and credits
- Save data MUST be stored in user-accessible locations per muOS conventions

## Governance

This constitution supersedes all other development practices. All feature specifications, plans, and tasks MUST comply with the Core Principles outlined above.

### Amendment Process

1. Proposed amendments MUST be documented with clear rationale
2. Amendments require validation that dependent templates remain consistent
3. Version number MUST be updated per semantic versioning:
   - MAJOR: Principle removals or incompatible changes
   - MINOR: New principles or expanded guidance
   - PATCH: Clarifications or non-semantic refinements

### Compliance

- All code reviews MUST verify adherence to performance and resource constraints
- Complexity that violates principles MUST be justified in implementation plans
- Developers MUST consult this constitution when making architectural decisions

**Version**: 1.0.0 | **Ratified**: 2025-11-15 | **Last Amended**: 2025-11-15
