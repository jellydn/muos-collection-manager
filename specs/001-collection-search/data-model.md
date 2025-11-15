# Data Model: Dynamic Game Collections

**Phase**: 1 - Design & Contracts
**Created**: 2025-11-15
**Purpose**: Define entities, relationships, and validation rules for collection management

## Entity Definitions

### Game

Represents a single game in the library with metadata for searching and filtering.

**Attributes**:

- `id` (string): Unique identifier (UUID or hash of file path)
- `title` (string): Display name extracted from filename or scraper
- `file_path` (string): Absolute path to ROM file
- `system` (string): Console/platform (e.g., "nes", "snes", "gba")
- `genre` (list of strings): Genre tags (e.g., ["platformer", "action"])
- `year` (number|nil): Release year (extracted from filename or metadata)
- `player_count` (number): Maximum players (default: 1)
- `favorite` (boolean): User-marked favorite flag
- `play_count` (number): Number of times launched (for "recently played")
- `last_played` (number|nil): Unix timestamp of last launch

**Validation Rules**:

- `title` MUST NOT be empty
- `file_path` MUST be valid readable file
- `year` MUST be between 1970-2100 if present
- `player_count` MUST be 1-8
- `genre` defaults to `["Unknown"]` if empty

**Relationships**:

- One Game can appear in multiple Collections (many-to-many via search criteria)

**State Transitions**:

- Immutable after creation (metadata refresh rebuilds the game object)

---

### Collection

Represents a saved dynamic collection with filter criteria.

**Attributes**:

- `id` (string): Unique identifier (UUID)
- `name` (string): User-defined collection name
- `filters` (SearchFilter[]): Array of filter criteria (can be empty for "All Games")
- `filter_mode` (string): "AND" or "OR" logic for combining filters
- `created_at` (number): Unix timestamp of creation
- `is_system` (boolean): True for built-in collections (All Games, Favorites, Recent)
- `icon` (string|nil): Optional icon name for UI display
- `sort_order` (string): "title_asc", "title_desc", "year_asc", "year_desc", "recent"

**Validation Rules**:

- `name` MUST be 1-50 characters
- `name` MUST NOT conflict with existing collection names
- `filter_mode` MUST be "AND" or "OR"
- System collections (`is_system=true`) CANNOT be deleted or renamed
- `filters` can be empty array (matches all games)

**Relationships**:

- One Collection has many SearchFilters (composition - filters owned by collection)
- Collection dynamically matches multiple Games (query-based, not stored)

**State Transitions**:

- Created → Active (when saved)
- Active → Modified (when filters updated)
- Active → Deleted (user deletes, only if `is_system=false`)

---

### SearchFilter

Represents a single filter criterion within a collection.

**Attributes**:

- `filter_type` (string): Type of filter - "name", "genre", "year", "players", "favorite"
- `operator` (string): Comparison operator - "contains", "equals", "range", "gte", "lte"
- `value` (string|number|table): Filter value (depends on type)

**Valid Combinations**:

| filter_type | Valid operators         | value type      | Example              |
| ----------- | ----------------------- | --------------- | -------------------- |
| name        | contains                | string          | "mario"              |
| genre       | equals                  | string          | "platformer"         |
| year        | equals, range, gte, lte | number or table | 1985 or {1985, 1990} |
| players     | equals, gte, lte        | number          | 2                    |
| favorite    | equals                  | boolean         | true                 |

**Validation Rules**:

- `filter_type` MUST be one of: "name", "genre", "year", "players", "favorite"
- `operator` MUST be valid for the given `filter_type`
- `value` MUST match expected type for operator:
  - "contains" → string (case-insensitive)
  - "equals" → string|number|boolean
  - "range" → table with 2 numbers [min, max]
  - "gte"/"lte" → number
- Year ranges: min MUST be <= max

**Relationships**:

- Many SearchFilters belong to one Collection

---

### SearchIndex

In-memory structure for fast game lookups (not persisted).

**Attributes**:

- `title_index` (table): Map of lowercase title → Game array
- `genre_index` (table): Map of genre → Game array
- `year_index` (table): Map of year → Game array
- `players_index` (table): Map of player_count → Game array
- `all_games` (Game[]): Full game library array

**Operations**:

- `build(games[])`: Construct indexes from game list (called at startup)
- `query(filters[], mode)`: Execute search and return matching games
- `refresh()`: Rebuild indexes (when library changes)

**Performance Characteristics**:

- Build time: O(n × m) where n=games, m=avg genres per game (~50ms for 10K games)
- Query time: O(n) linear scan with early exit optimizations
- Memory: ~2-3MB for 10K games (4 indexes + game objects)

---

## Relationships Diagram

```
Collection (1) ─────────────── (N) SearchFilter
    │                                  │
    │ (query-based)                    │
    │                                  │
    └────────> Game (N) <──────────────┘
                  │
                  │
            SearchIndex
           (in-memory)
```

---

## Data Flow

### 1. Library Load (Startup)

```
ROM Directory Scan
    ↓
Parse Filenames → Extract Metadata
    ↓
Create Game Objects
    ↓
Build SearchIndex
    ↓
Load Saved Collections from JSON
```

### 2. Search Execution

```
User Types Query
    ↓
Create SearchFilter (name, contains, query)
    ↓
SearchIndex.query([filter], mode="AND")
    ↓
Filter games by lowercase title match
    ↓
Return Game[] results
    ↓
Render in GameGrid (virtual scrolling)
```

### 3. Collection Creation (P2)

```
User Performs Search
    ↓
Clicks "Save as Collection"
    ↓
Enter Collection Name
    ↓
Create Collection with current SearchFilters
    ↓
Save to collections.json (atomic write)
    ↓
Add to UI Collections Menu
```

### 4. Multi-Filter Search (P3)

```
User Opens Filter Panel
    ↓
Add Filter: genre = "RPG"
    ↓
Add Filter: year range 1990-1995
    ↓
Select mode: AND
    ↓
SearchIndex.query([genre_filter, year_filter], "AND")
    ↓
Return intersection of matching games
```

---

## File Format: collections.json

```json
{
  "version": "1.0", // Schema version for forward compatibility and migration
  "collections": [
    {
      "id": "all-games-system",
      "name": "All Games",
      "filters": [],
      "filter_mode": "AND",
      "created_at": 1700000000,
      "is_system": true,
      "sort_order": "title_asc"
    },
    {
      "id": "uuid-mario-collection",
      "name": "Mario Games",
      "filters": [
        {
          "filter_type": "name",
          "operator": "contains",
          "value": "mario"
        }
      ],
      "filter_mode": "AND",
      "created_at": 1700001234,
      "is_system": false,
      "sort_order": "title_asc"
    },
    {
      "id": "uuid-2player-platformers",
      "name": "2P Platformers",
      "filters": [
        {
          "filter_type": "genre",
          "operator": "equals",
          "value": "platformer"
        },
        {
          "filter_type": "players",
          "operator": "gte",
          "value": 2
        }
      ],
      "filter_mode": "AND",
      "created_at": 1700005678,
      "is_system": false,
      "sort_order": "year_desc"
    }
  ]
}
```

---

## Schema Versioning and Migration

**Version Strategy**: The `version` field in collections.json enables forward compatibility and safe upgrades.

**Migration Rules**:

- **Version 1.0 → 1.1**: Add default values for new optional fields (e.g., `icon`, `sort_order`)
- **Version 1.x → 2.0**: Breaking changes require explicit migration function with user confirmation
- **Unknown/Future Versions**: Reject file, create backup at `collections.json.backup`, log error, start fresh with default collections
- **Backwards Compatibility**: Always read older schema versions and upgrade in-memory before saving

**Implementation** (to be added in T034/T035):

```lua
function Persistence.load()
  local data = json.decode(file_content)

  if not data.version then
    -- Legacy format, migrate to 1.0
    data = migrate_to_v1_0(data)
  elseif data.version == "1.0" then
    -- Current version, no migration needed
  elseif data.version > "1.0" then
    -- Unknown future version, backup and reject
    create_backup(file_path)
    error("collections.json schema version " .. data.version .. " not supported")
  end

  return data.collections
end
```

**Rationale**: Prevents data loss during app updates and provides clear error handling for incompatible schema changes.

---

## Memory Budget Estimation

| Component                          | Estimated Size (10K games) |
| ---------------------------------- | -------------------------- |
| Game objects (10K × 500 bytes avg) | ~5 MB                      |
| SearchIndex (4 indexes)            | ~2 MB                      |
| Collections (50 × 2KB avg)         | ~100 KB                    |
| UI state and buffers               | ~1 MB                      |
| **Total**                          | **~8 MB**                  |

**Meets Constitution Requirement**: <10MB budget (SC-007) ✅

---

## Phase 1 Data Model Complete

All entities defined with clear validation rules and relationships. Ready to generate API contracts (JSON schemas) for serialization.
