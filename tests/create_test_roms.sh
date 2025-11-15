#!/bin/bash
# Test script to verify Love2D app launches correctly
# Creates dummy ROM files for testing

TEST_DIR="/tmp/muos-test-roms"

echo "Creating test ROM directories..."
mkdir -p "$TEST_DIR/NES"
mkdir -p "$TEST_DIR/SNES"
mkdir -p "$TEST_DIR/GB"

echo "Creating dummy ROM files..."

# NES games
touch "$TEST_DIR/NES/Super Mario Bros (USA) (1985).nes"
touch "$TEST_DIR/NES/The Legend of Zelda (USA) (1986).nes"
touch "$TEST_DIR/NES/Mega Man (USA) (1987).nes"
touch "$TEST_DIR/NES/Contra (USA) (1988) [2P].nes"
touch "$TEST_DIR/NES/Final Fantasy (USA) (1990).nes"

# SNES games
touch "$TEST_DIR/SNES/Super Mario World (USA) (1990).sfc"
touch "$TEST_DIR/SNES/The Legend of Zelda - A Link to the Past (USA) (1991).sfc"
touch "$TEST_DIR/SNES/Super Metroid (USA) (1994).sfc"
touch "$TEST_DIR/SNES/Chrono Trigger (USA) (1995).sfc"
touch "$TEST_DIR/SNES/Street Fighter II (USA) (1992) [2P].sfc"

# Game Boy games
touch "$TEST_DIR/GB/Pokemon Red (USA) (1998).gb"
touch "$TEST_DIR/GB/Tetris (USA) (1989).gb"
touch "$TEST_DIR/GB/Super Mario Land (USA) (1989).gb"
touch "$TEST_DIR/GB/The Legend of Zelda - Link's Awakening (USA) (1993).gb"
touch "$TEST_DIR/GB/Kirby's Dream Land (USA) (1992).gb"

echo ""
echo "Test ROMs created in: $TEST_DIR"
echo "Total files: $(find "$TEST_DIR" -type f | wc -l)"
echo ""
echo "To test, run:"
echo "  cd $(pwd)"
echo "  MUOS_ROMS_PATH=$TEST_DIR love ."
echo ""
echo "Expected output:"
echo "  - Should load 15 games"
echo "  - Should show debug info with F1 key"
echo "  - Should display FPS counter"
echo "  - Press ESC to quit"
