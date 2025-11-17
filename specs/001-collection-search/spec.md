# Feature Specification: Dynamic Game Collections

**Feature Branch**: `001-collection-search`
**Created**: 2025-11-15
**Status**: Complete
**Input**: User description: "collection management by searching the game by name which is exactly https://knulli.org/configure/collections/#dynamic-collections"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Search Games by Name (Priority: P1)

Players can search for games by typing part of the game name and see matching results displayed in a filterable collection. The search is case-insensitive and supports partial matches (e.g., typing "mario" finds "Super Mario Bros", "Mario Kart", "Dr. Mario").

**Why this priority**: This is the core functionality that enables players to quickly find games in large libraries without scrolling through hundreds of titles. It's the foundation for all dynamic collection features.

**Independent Test**: Can be fully tested by launching the collection browser, typing a search term, and verifying matching games appear. Delivers immediate value by solving the "find my game" problem.

**Acceptance Scenarios**:

1. **Given** player has 100+ games in library, **When** player types "sonic" in search field, **Then** all games with "sonic" in the title are displayed
2. **Given** player types "MEGA", **When** search executes, **Then** results include "Mega Man", "mega drive games", etc. (case-insensitive)
3. **Given** player types "zel", **When** search executes, **Then** results include "The Legend of Zelda" (partial match)
4. **Given** player clears search field, **When** search is empty, **Then** all games are shown again

---

### User Story 2 - Create Custom Collections (Priority: P2)

Players can create named collections based on search criteria and save them for quick access. Collections persist across sessions and appear in the main menu alongside system collections.

**Why this priority**: After being able to search, players want to organize their favorite searches into permanent collections (e.g., "Platformers", "My Favorites", "Co-op Games").

**Independent Test**: Create a collection with search criteria "mario", name it "Mario Games", exit and restart - collection should still exist with saved games.

**Acceptance Scenarios**:

1. **Given** player has performed a search, **When** player selects "Save as Collection", **Then** system prompts for collection name
2. **Given** player names collection "Puzzle Games", **When** collection is saved, **Then** it appears in main collections menu
3. **Given** player opens saved collection, **When** viewing games, **Then** only games matching original search criteria appear
4. **Given** new games are added to library, **When** they match collection criteria, **Then** they automatically appear in the collection

---

### User Story 3 - muOS Integration (Priority: P3)

Players can view playtime statistics from muOS tracking and export collections to the native muOS launcher. Collections integrate seamlessly with the muOS ecosystem.

**Why this priority**: Integration with muOS enhances the user experience by showing playtime data and allowing collections to be used across both the custom launcher and native muOS.

**Independent Test**: Create a collection, export it to muOS, verify it appears in muOS Collections menu and launches games correctly.

**Acceptance Scenarios**:

1. **Given** player has launched games from muOS, **When** viewing game info panel, **Then** playtime statistics are displayed
2. **Given** player creates a custom collection, **When** exporting to muOS, **Then** collection appears in muOS Collections menu
3. **Given** player views Recently Played collection, **When** opening, **Then** games from muOS history are shown
4. **Given** player exports a collection, **When** export succeeds, **Then** success dialog shows with instructions

---

### User Story 4 - Browse Games by Platform (Priority: P2)

Players can browse their game library organized by gaming platform/system (GB, GBA, NES, SNES, PSP, etc.). Selecting a platform shows all games for that system, making it easy to find games for a specific console.

**Why this priority**: Players often want to browse games by platform (e.g., "show me all my Game Boy games"), especially when they have large multi-system libraries. This complements search-based discovery with category-based browsing.

**Independent Test**: Open "Browse by Platform" collection, select "GBA" platform, verify only Game Boy Advance games appear in the list.

**Acceptance Scenarios**:

1. **Given** player has games from multiple platforms, **When** player opens "Browse by Platform" collection, **Then** a list of all platforms with game counts is displayed
2. **Given** player selects "GB" platform, **When** viewing games, **Then** only Game Boy games are shown
3. **Given** player adds new PSP games to library, **When** returning to platform browser, **Then** "PSP" platform appears in the list with correct game count
4. **Given** player is viewing a platform's games, **When** pressing Back button, **Then** system returns to platform selection screen
5. **Given** platform has 0 games, **When** browsing platforms, **Then** that platform is not shown in the list

---

### Edge Cases

- What happens when search query matches zero games? (Display "No games found" message with suggestion to adjust filters)
- How does system handle special characters in game names? (Search should handle parentheses, hyphens, apostrophes, etc.)
- What happens when collection criteria match 500+ games? (Display with pagination or virtual scrolling to maintain 60 FPS)
- How does system handle corrupted collection data? (Load default "All Games" collection and log error)
- What happens when player creates collection with same name as existing? (Prompt to overwrite or rename)
- How does search perform with 10,000+ game library? (Search must complete within 500ms, use indexing if needed)
- How does system integrate with different muOS versions? (Auto-detect launcher paths and fall back gracefully)
- What happens on non-muOS devices (TrimUI)? (System operates as standalone launcher with native integration)
- What happens when deleting a ROM file that doesn't exist? (Show error dialog: "File not found or already deleted")
- What happens when box art image file is missing? (Display placeholder icon or text-only list item)
- What happens when exporting collection to read-only filesystem? (Show error dialog with permission issue message)

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST allow players to enter search text via on-screen keyboard or physical keyboard (if connected)
- **FR-002**: System MUST perform case-insensitive partial matching on game titles
- **FR-003**: System MUST update search results in real-time as player types (with debouncing to prevent lag)
- **FR-004**: System MUST display search results in scrollable grid or list format
- **FR-005**: System MUST allow players to save search criteria as named collections
- **FR-006**: System MUST persist collections between sessions (saved to file)
- **FR-007**: System MUST automatically update dynamic collections when new games are added to library
- **FR-008**: System MUST provide visual feedback during search operations (loading indicator shown when search execution exceeds 100ms, measured from last keystroke to results rendered)
- **FR-009**: System MUST allow players to delete custom collections (with confirmation prompt)
- **FR-010**: System MUST support name-based search filtering for creating collections
- **FR-011**: System MUST handle empty search results gracefully with informative message
- **FR-012**: System MUST read and display muOS playtime tracking data (launches, total time, average time)
- **FR-013**: System MUST use ASCII text labels instead of Unicode symbols for font compatibility
- **FR-014**: System MUST automatically clean log files when they exceed 1000 lines
- **FR-015**: System MUST export collections to muOS-compatible format for integration with native launcher
- **FR-016**: System MUST integrate with muOS muxcollect module for game launching (delegate to native system)
- **FR-017**: System MUST support both muOS and TrimUI device architectures with appropriate display scaling
- **FR-018**: System MUST allow players to delete individual games from library with confirmation dialog
- **FR-019**: System MUST permanently delete ROM files when player confirms game deletion
- **FR-020**: System MUST display box art thumbnails for games when available from muOS catalogue
- **FR-021**: System MUST use FileData fallback when direct image loading fails due to filesystem restrictions
- **FR-022**: System MUST show success/error dialogs after collection export with clear next-step instructions
- **FR-023**: System MUST convert ROM paths from /mnt/mmc/ROMS to /mnt/union/ROMS for muOS compatibility
- **FR-024**: System MUST read muOS history to populate "Recently Played" system collection
- **FR-025**: System MUST sync "Recently Played" with games launched from muOS History module
- **FR-026**: System MUST handle text overflow in search bar by scrolling to show recent characters
- **FR-027**: System MUST enforce minimum keyboard key size to prevent rendering crashes
- **FR-028**: System MUST provide "Browse by Platform" system collection to organize games by gaming platform
- **FR-029**: System MUST detect all unique platforms/systems in game library automatically
- **FR-030**: System MUST display platform list with game counts (e.g., "GB (42 games)", "PSP (15 games)")
- **FR-031**: System MUST support hierarchical navigation (platforms list → platform's games → back to platforms)
- **FR-032**: System MUST filter platforms with zero games from the platform browser

### Key Entities

- **Game**: Represents a game in the library with attributes: title (string), file path (string), genre tags (list), year (number), player count (number), metadata
- **Collection**: Represents a saved dynamic collection with attributes: name (string), search criteria (filters object), creation date (timestamp), is_system_collection (boolean)
- **SearchFilter**: Represents individual filter criteria with attributes: filter type (name/genre/year/players), operator (contains/equals/range), value (string/number)
- **SearchIndex**: In-memory structure for fast game lookups with attributes: indexed game titles, genre mappings, year ranges

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Players can find a specific game by typing 3+ characters in under 2 seconds (including search time and visual feedback)
- **SC-002**: Search results update within 100ms for libraries up to 1,000 games (maintains 60 FPS during typing)
- **SC-003**: Search results update within 500ms for libraries up to 10,000 games
- **SC-004**: Players can create and save a custom collection in under 30 seconds
- **SC-005**: Collections persist across application restarts with 100% accuracy
- **SC-006**: Players can delete games with confirmation in under 5 seconds
- **SC-007**: Exported collections appear in muOS muxcollect within 2 seconds of export
- **SC-008**: System displays box art thumbnails when available, improving visual browsing experience
- **SC-009**: UI scales correctly on both 4:3 (640x480) and 16:9 (1280x720) displays without distortion
- **SC-010**: System supports at least 50 custom collections without performance degradation
- **SC-011**: Memory usage for collection management stays under 10MB (part of 256MB total budget)
- **SC-012**: Zero frame drops when scrolling through search results (maintains 60 FPS)

## Assumptions

- Game metadata (title, genre, year, player count) is available from game database or ROM filename parsing
- Players are familiar with basic search functionality from other applications
- On-screen keyboard is available for text input on devices without physical keyboards
- File I/O for saving collections is fast enough (<50ms) to not require background threading
