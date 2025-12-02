# UI Sound Effects

This directory contains UI sound effects for the muOS Collection Manager.

## Placeholder Notes

For muOS deployment, sound effects should be small .wav or .ogg files:
- `click.wav` - Button press/navigation sound
- `confirm.wav` - Confirmation action sound
- `cancel.wav` - Cancel/back action sound
- `error.wav` - Error notification sound

Current implementation uses silent placeholders. For production:
1. Generate simple beep sounds (100-200ms each)
2. Convert to .ogg format for Love2D compatibility
3. Keep file sizes under 10KB each

## Integration

Sounds are loaded in `src/lib/asset_loader.lua` and played via `love.audio.play()`.
