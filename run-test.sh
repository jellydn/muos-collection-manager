#!/bin/bash
# Quick test runner for muOS Collection Manager on macOS

set -e

echo "🎮 muOS Collection Manager - Test Runner"
echo "========================================"

# Check if Love2D is installed
if ! command -v love &> /dev/null; then
    echo "❌ Love2D not found!"
    echo ""
    echo "Install with: brew install --cask love"
    echo "Or download from: https://love2d.org/"
    exit 1
fi

echo "✅ Love2D found: $(love --version)"

# Create test ROMs if they don't exist
if [ ! -d "/tmp/muos-test-roms" ]; then
    echo "📦 Creating test ROM files..."
    ./tests/create_test_roms.sh
else
    echo "✅ Test ROMs already exist"
fi

echo ""
echo "🚀 Starting application..."
echo ""
echo "Controls:"
echo "  Arrow Keys  - Navigate"
echo "  Enter       - Select"
echo "  Tab         - Toggle keyboard"
echo "  Backspace   - Delete character"
echo "  F1          - Debug mode (FPS/Memory)"
echo "  ESC         - Quit"
echo ""

# Run the application
MUOS_ROMS_PATH=/tmp/muos-test-roms love .
