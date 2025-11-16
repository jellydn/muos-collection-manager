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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Features to Test:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Library scanning (/tmp/muos-test-roms)"
echo "  ✓ Search functionality"
echo "  ✓ Navigation & scrolling"
echo "  ✓ Creating collections"
echo "  ✓ Filter panel (system filters)"
echo "  ✓ AND/OR toggle for filters"
echo "  ✓ Favorites management"
echo "  ✓ Debug mode & FPS counter"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎮 Mac Keyboard Controls:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Navigation:"
echo "    ↑/↓/←/→        Navigate menus & lists"
echo ""
echo "  Primary Actions:"
echo "    ENTER/SPACE    Confirm selection (A button)"
echo "    ESC/B          Back/Cancel (B button)"
echo ""
echo "  Menu & Features:"
echo "    M              Open menu (START button)"
echo "    L/TAB          Toggle filter panel (L shoulder)"
echo "    R              Toggle AND/OR mode (R shoulder)"
echo "    F/Y            Toggle favorite (Y button)"
echo "    X/BACKSPACE    Delete/Remove (X button)"
echo ""
echo "  Quick Actions:"
echo "    1-5            Quick select items 1-5"
echo ""
echo "  Debug:"
echo "    F1             Toggle debug mode"
echo "    F2             Toggle FPS counter"
echo "    F5             Refresh game library"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Starting application..."
echo ""

# Run the application
MUOS_ROMS_PATH=/tmp/muos-test-roms love .
