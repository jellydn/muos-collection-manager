# UI Icons

This directory contains UI icons for the muOS Collection Manager.

## Required Icons (16x16 or 32x32 PNG)

- `search.png` - Search/magnifying glass icon
- `add.png` - Add collection icon (plus symbol)
- `delete.png` - Delete collection icon (trash/X symbol)
- `filter.png` - Filter icon (funnel shape)
- `favorite.png` - Favorite/star icon
- `back.png` - Back/return arrow
- `settings.png` - Settings/gear icon

## Current Implementation

Using text-based fallbacks in UI code. For production:
1. Create simple monochrome icons at 16x16 resolution
2. Export as PNG with transparency
3. Keep file sizes under 1KB each for performance

## Integration

Icons are loaded in `src/lib/asset_loader.lua` and drawn via `love.graphics.draw()`.
