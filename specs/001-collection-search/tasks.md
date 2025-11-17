# Tasks: Dynamic Game Collections

**Input**: Design documents from `/specs/001-collection-search/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `assets/`, `tests/` at repository root
- Love2D application structure with main.lua and conf.lua
- Paths assume Love2D conventions (see plan.md for full structure)

--# Start MVP implementation (29 tasks)
/speckit.implement

# Or convert to GitHub issues for tracking

/speckit.taskstoissues-

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Love2D configuration

- [x] T001 Create Love2D project structure with main.lua, conf.lua, src/, assets/, tests/
- [x] T002 Configure conf.lua with window settings for muOS (320×240 to 640×480 support)
- [x] T003 [P] Add json.lua library to src/lib/json.lua
- [x] T004 [P] Create logger.lua utility in src/lib/logger.lua
- [x] T005 [P] Create input_config.lua in src/config/input_config.lua (muOS D-pad mappings)
- [x] T006 [P] Create display_config.lua in src/config/display_config.lua (aspect ratio handling)
- [x] T007 [P] Create paths.lua in src/config/paths.lua (muOS directory paths)
- [x] T008 Create README.md with installation instructions for muOS

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T009 Create SceneManager in src/scenes/scene_manager.lua (scene transitions, state management)
- [x] T010 [P] Create Game model in src/models/game.lua (entity with validation)
- [x] T011 [P] Create GameLibrary service in src/services/game_library.lua (ROM scanning, metadata extraction)
- [x] T012 Create main.lua with love.load(), love.update(), love.draw() calling SceneManager
- [x] T013 [P] Create InputHandler in src/ui/input_handler.lua (controller abstraction, button mapping)
- [x] T014 [P] Create muOS directory structure creation in main.lua (~/.config/muos/collections/)
- [x] T015 Test: Verify app launches and scans test ROM directory (10-20 dummy files)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Search Games by Name (Priority: P1) 🎯 MVP

**Goal**: Players can search for games by typing part of the game name and see matching results displayed in real-time

**Independent Test**: Launch app, type "test" in search field, verify matching games appear with case-insensitive partial matching

### Implementation for User Story 1

- [x] T016 [P] [US1] Create SearchIndex model in src/models/search_index.lua (lowercase indexing)
- [x] T017 [P] [US1] Create SearchEngine service in src/services/search_engine.lua (case-insensitive partial matching)
- [x] T018 [US1] Implement SearchIndex.build() to create lowercase title index from game list
- [x] T019 [US1] Implement SearchEngine.query() with debouncing (150ms delay per research.md)
- [x] T020 [P] [US1] Create SearchBar UI component in src/ui/search_bar.lua (input field, debounce timer)
- [x] T021 [P] [US1] Create OnScreenKeyboard widget in src/ui/keyboard.lua (D-pad navigation)
- [x] T022 [P] [US1] Create GameGrid component in src/ui/game_grid.lua (virtual scrolling renderer)
- [x] T023 [US1] Create SearchScene in src/scenes/search_scene.lua (integrates SearchBar + GameGrid)
- [x] T024 [US1] Implement SearchScene:update() to call SearchEngine with debounced query
- [x] T025 [US1] Implement GameGrid virtual scrolling (viewport culling per research.md)
- [x] T026 [US1] Add "No games found" message handling in SearchScene
- [x] T027 [US1] Add loading indicator for searches >100ms (per FR-008)
- [x] T028 [US1] Handle special characters in search (parentheses, hyphens, apostrophes)
- [x] T029 [US1] Add logging for search operations (query, result count, time)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

**Test Scenarios**:

- Search for "sonic" → Shows all games with "sonic" in title
- Search for "MEGA" → Shows "Mega Man", "mega drive games" (case-insensitive)
- Search for "zel" → Shows "The Legend of Zelda" (partial match)
- Clear search → Shows all games again

---

## Phase 4: User Story 2 - Create Custom Collections (Priority: P2)

**Goal**: Players can save search criteria as named collections that persist across sessions

**Independent Test**: Search for "mario", save as "Mario Games" collection, restart app, verify collection exists and shows Mario games

### Implementation for User Story 2

- [x] T030 [P] [US2] Create Collection model in src/models/collection.lua (with validation rules)
- [x] T031 [P] [US2] Create Persistence service in src/services/persistence.lua (JSON save/load with atomic write)
- [x] T032 [P] [US2] Create CollectionManager service in src/services/collection_manager.lua (CRUD operations)
- [x] T033 [US2] Implement Collection validation (name length 1-50 chars, no duplicates)
- [x] T034 [US2] Implement Persistence.save() with atomic write pattern (temp file + rename per research.md) and version field ("1.0")
- [x] T035 [US2] Implement Persistence.load() with error handling for corrupted data and schema version migration (see data-model.md)
- [x] T036 [US2] Implement CollectionManager.create() to save collection with current search criteria
- [x] T037 [US2] Implement CollectionManager.delete() with confirmation (non-system collections only)
- [x] T038 [P] [US2] Create CreateCollectionScene in src/scenes/create_scene.lua (name input, save button)
- [x] T039 [P] [US2] Create MenuScene in src/scenes/menu_scene.lua (list collections, navigation)
- [x] T040 [P] [US2] Create BrowseScene in src/scenes/browse_scene.lua (display collection games)
- [x] T041 [US2] Add "Save as Collection" option to SearchScene (START button per quickstart.md)
- [x] T042 [US2] Implement MenuScene to load and display all collections (system + custom)
- [x] T043 [US2] Implement BrowseScene to query and display games matching collection filters
- [x] T044 [US2] Add duplicate collection name detection and prompt
- [x] T045 [US2] Create default system collections: "All Games", "Favorites", "Recently Played"
- [x] T046 [US2] Test collection persistence (save, restart, load)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently ✅

**Test Scenarios**:

- Perform search, click "Save as Collection", enter "Puzzle Games", verify saved
- Open saved collection, verify only matching games appear
- Add new games to library, verify they auto-appear in matching collections
- Try to delete system collection, verify blocked

---

## Phase 5: User Story 3 - Multiple Search Filters (Priority: P3)

**Goal**: Players can combine multiple search criteria (name, genre, year, player count) with AND/OR logic

**Independent Test**: Set filters "genre: platformer" AND "players: 2", verify only 2-player platformers appear

### Implementation for User Story 3

- [x] T047 [P] [US3] Create SearchFilter model in src/models/search_filter.lua (with validation per data-model.md)
- [x] T048 [P] [US3] Create FilterEngine service in src/services/filter_engine.lua (multi-criteria filtering)
- [x] T049 [US3] Implement SearchFilter validation (filter_type, operator, value combinations)
- [x] T050 [US3] Implement FilterEngine.applyFilters() with AND logic (intersection of results)
- [x] T051 [US3] Implement FilterEngine.applyFilters() with OR logic (union of results)
- [x] T052 [US3] Add genre filter support (equals operator)
- [x] T053 [US3] Add year filter support (equals, range, gte, lte operators)
- [x] T054 [US3] Add player count filter support (equals, gte, lte operators)
- [x] T055 [US3] Add favorite flag filter support (equals operator)
- [x] T056 [P] [US3] Create FilterPanel UI component in src/ui/filter_panel.lua (add/remove filters)
- [x] T057 [P] [US3] Add genre dropdown widget to FilterPanel
- [x] T058 [P] [US3] Add year range input widget to FilterPanel
- [x] T059 [P] [US3] Add player count input widget to FilterPanel
- [x] T060 [US3] Add AND/OR toggle button to FilterPanel (R button per quickstart.md)
- [x] T061 [US3] Integrate FilterPanel into SearchScene (L button to open per quickstart.md)
- [x] T062 [US3] Update SearchScene to combine name search with active filters
- [x] T063 [US3] Update CollectionManager to save multi-filter collections
- [x] T064 [US3] Handle edge case: 500+ matching games with virtual scrolling

**Checkpoint**: All user stories should now be independently functional

**Test Scenarios**:

- Add filter "genre: RPG" + name "final", verify only RPG games with "final" in title
- Set "year: 1985-1990", verify only games from that range
- Toggle AND/OR, verify results update correctly
- Save multi-filter collection, verify persistence

---

## Phase N: Polish & muOS Integration

**Purpose**: muOS collection export, box art display, and final polish

- [x] T065 [P] Add UI sound effects in assets/sounds/ui/ (button click, confirm)
- [x] T066 [P] Add UI icons in assets/images/icons/ (search, add, delete, filter)
- [x] T067 [P] Create Dialog component in src/ui/dialog.lua (confirmation prompts)
- [x] T068 [P] Add favorite toggle functionality (Y button per quickstart.md)
- [x] T069 [P] Add collection deletion with confirmation dialog
- [x] T070 [P] Add SettingsScene in src/scenes/settings_scene.lua (future settings)
- [x] T071 Implement muOS collection export (game_launcher.lua exports to /mnt/mmc/MUOS/info/collection/)
- [x] T072 Export format: Create folder per collection with .cfg files (3-line format: path, system, title)
- [x] T073 Handle path conversion (/mnt/mmc/ROMS → /mnt/union/ROMS for muOS)
- [x] T074 Update browse_scene.lua to export collections instead of launching games
- [x] T075 Add success/error dialog after export with instructions to open muOS > Collection
- [x] T076 Update search_scene.lua help text to reflect muOS integration
- [x] T077 Add TrimUI device detection and display scaling (720p baseline for 16:9)
- [x] T078 Add performance profiling with love.timer (log frame times, search times)
- [x] T079 Optimize: Verify 60 FPS maintained during scrolling and search
- [x] T080 Optimize: Verify search completes <100ms for 1K games, <500ms for 10K games
- [x] T081 Optimize: Verify memory usage stays <10MB for collection system
- [x] T082 Add error handling for missing ROM directories
- [x] T083 Add error handling for corrupted JSON collection files
- [x] T084 Add box art image loading from /mnt/mmc/MUOS/info/catalogue/<System>/box/
- [x] T085 Update GameGrid to display box art thumbnails instead of text-only list
- [x] T086 Add fallback placeholder image when box art not found
- [x] T087 Implement image caching to avoid reloading same images
- [x] T088 Add muOS history integration for "Recently Played" collection
- [x] T089 Read from /mnt/mmc/MUOS/info/history/ to populate recent games
- [x] T090 Parse muOS history format and match to Game Library
- [ ] T091 Test muOS collection export format on actual device
- [ ] T092 Verify exported collections appear in muOS muxcollect module
- [ ] T093 Test on actual muOS hardware (RG35XX or similar)
- [ ] T094 Verify muOS controller compatibility (D-pad, A/B/X/Y, L/R, START/SELECT)
- [x] T095 Update README.md with build and installation instructions
- [x] T096 Package as .muxapp file for muOS distribution
- [ ] T097 Run full quickstart.md validation on device

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US1 and US2 but independently testable

### Within Each User Story

- Models before services (T016-T017 before T018-T019 for US1)
- Services before UI components (T018-T019 before T020-T022 for US1)
- UI components before scenes (T020-T022 before T023 for US1)
- Scene integration last (T023-T024 for US1)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T003-T007)
- All Foundational tasks marked [P] can run in parallel (T010-T014)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Within each user story, tasks marked [P] can run in parallel:
  - US1: T016-T017, T020-T022 (models, UI components)
  - US2: T030-T032, T038-T040 (models, scenes)
  - US3: T047-T048, T056-T059 (model, UI widgets)

---

## Parallel Example: User Story 1

```bash
# Launch all models and UI components for US1 together:
Task: "Create SearchIndex model in src/models/search_index.lua"
Task: "Create SearchEngine service in src/services/search_engine.lua"
Task: "Create SearchBar UI component in src/ui/search_bar.lua"
Task: "Create OnScreenKeyboard widget in src/ui/keyboard.lua"
Task: "Create GameGrid component in src/ui/game_grid.lua"

# Then implement integration (sequential):
Task: "Create SearchScene in src/scenes/search_scene.lua"
Task: "Implement SearchScene:update() to call SearchEngine"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T015) - CRITICAL checkpoint
3. Complete Phase 3: User Story 1 (T016-T029)
4. **STOP and VALIDATE**: Test search independently with 100+ games
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Search) → Test independently → Deploy/Demo (MVP! 🎯)
3. Add User Story 2 (Collections) → Test independently → Deploy/Demo
4. Add User Story 3 (Filters) → Test independently → Deploy/Demo
5. Polish phase → Final release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T015)
2. Once Foundational is done:
   - Developer A: User Story 1 (T016-T029)
   - Developer B: User Story 2 (T030-T046)
   - Developer C: User Story 3 (T047-T064)
3. Stories complete and integrate independently

---

## Performance Checkpoints

Verify these metrics at completion of each phase:

### After US1 (Search)

- ✅ Search completes <100ms for 1,000 games
- ✅ Search completes <500ms for 10,000 games
- ✅ 60 FPS maintained during typing
- ✅ 60 FPS maintained during scroll
- ✅ Memory usage <5MB

### After US2 (Collections)

- ✅ Collection save <50ms
- ✅ Collection load <50ms for 50 collections
- ✅ Memory usage <8MB
- ✅ 60 FPS maintained in menu navigation

### After US3 (Filters)

- ✅ Multi-filter query <200ms for 1,000 games
- ✅ 60 FPS maintained with active filters
- ✅ Memory usage <10MB
- ✅ All constitution requirements met

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Total tasks: 97 (8 setup, 7 foundational, 14 US1, 17 US2, 18 US3, 33 polish + muOS integration + box art + history)
- Estimated MVP (US1 only): 29 tasks
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
