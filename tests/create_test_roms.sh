#!/bin/bash
# Test script to create comprehensive test ROM files
# Tests flexible directory scanning, archive detection, and all supported systems

TEST_DIR="/tmp/muos-test-roms"

echo "🎮 Creating comprehensive test ROM structure..."
echo ""

# Clean up old test data
rm -rf "$TEST_DIR"

# Nintendo Systems
echo "📁 Nintendo Systems..."
mkdir -p "$TEST_DIR/NES"
touch "$TEST_DIR/NES/Super Mario Bros (USA) (1985).nes"
touch "$TEST_DIR/NES/The Legend of Zelda (USA) (1986).nes"
touch "$TEST_DIR/NES/Mega Man (USA) (1987).nes"
touch "$TEST_DIR/NES/Contra (USA) (1988) [2P].nes"
touch "$TEST_DIR/NES/Metroid.zip"  # Archive test

mkdir -p "$TEST_DIR/SNES/Favorites"  # Nested directory test
touch "$TEST_DIR/SNES/Super Mario World (USA) (1990).sfc"
touch "$TEST_DIR/SNES/Favorites/Chrono Trigger (USA) (1995).sfc"
touch "$TEST_DIR/SNES/Favorites/Final Fantasy VI.7z"  # Archive in subdirectory

mkdir -p "$TEST_DIR/GB"
touch "$TEST_DIR/GB/Pokemon Red (USA) (1998).gb"
touch "$TEST_DIR/GB/Tetris (USA) (1989).gb"

mkdir -p "$TEST_DIR/GBC"
touch "$TEST_DIR/GBC/Pokemon Crystal (USA) (2000).gbc"

mkdir -p "$TEST_DIR/GBA"
touch "$TEST_DIR/GBA/Pokemon Emerald (USA) (2004).gba"
touch "$TEST_DIR/GBA/Metroid Fusion.rar"  # Archive test

mkdir -p "$TEST_DIR/N64"
touch "$TEST_DIR/N64/Super Mario 64 (USA) (1996).z64"
touch "$TEST_DIR/N64/The Legend of Zelda - Ocarina of Time (USA) (1998).n64"

mkdir -p "$TEST_DIR/NDS"
touch "$TEST_DIR/NDS/Mario Kart DS (USA).nds"
touch "$TEST_DIR/NDS/Pokemon Diamond.zip"

# Sony Systems
echo "📁 Sony Systems..."
mkdir -p "$TEST_DIR/PS"  # Test PS alias
touch "$TEST_DIR/PS/Final Fantasy VII (USA).cue"
touch "$TEST_DIR/PS/Metal Gear Solid.bin"
touch "$TEST_DIR/PS/Crash Bandicoot.zip"

mkdir -p "$TEST_DIR/PSP"
touch "$TEST_DIR/PSP/God of War.cso"
touch "$TEST_DIR/PSP/Final Fantasy VII Crisis Core.iso"

# Sega Systems
echo "📁 Sega Systems..."
mkdir -p "$TEST_DIR/MD"  # Test MD alias
touch "$TEST_DIR/MD/Sonic The Hedgehog (USA) (1991).md"
touch "$TEST_DIR/MD/Streets of Rage 2 [2P].gen"

mkdir -p "$TEST_DIR/MS"
touch "$TEST_DIR/MS/Alex Kidd.sms"

mkdir -p "$TEST_DIR/GG"
touch "$TEST_DIR/GG/Sonic.gg"

mkdir -p "$TEST_DIR/DC"
touch "$TEST_DIR/DC/Sonic Adventure.gdi"

# Arcade
echo "📁 Arcade..."
mkdir -p "$TEST_DIR/FBNEO"
touch "$TEST_DIR/FBNEO/mslug.zip"
touch "$TEST_DIR/FBNEO/kof98.zip"

# Ports
echo "📁 Ports..."
mkdir -p "$TEST_DIR/Ports"
touch "$TEST_DIR/Ports/doom.sh"

# Test flexible folder naming
echo "📁 Testing flexible folder names..."
mkdir -p "$TEST_DIR/Nintendo/Famicom"
touch "$TEST_DIR/Nintendo/Famicom/Dragon Quest (Japan).nes"

mkdir -p "$TEST_DIR/PlayStation/Classics"
touch "$TEST_DIR/PlayStation/Classics/Gran Turismo.cue"

mkdir -p "$TEST_DIR/Sega Genesis/Action"
touch "$TEST_DIR/Sega Genesis/Action/Golden Axe.md"

echo ""
echo "✅ Test ROM structure created!"
echo ""
echo "📊 Statistics:"
echo "  Location: $TEST_DIR"
echo "  Total files: $(find "$TEST_DIR" -type f | wc -l)"
echo "  Total directories: $(find "$TEST_DIR" -type d | wc -l)"
echo ""
echo "📁 Directory structure:"
find "$TEST_DIR" -type d | sed 's|/tmp/muos-test-roms|.|g' | sort
echo ""
echo "🎮 File types:"
find "$TEST_DIR" -type f -name "*.*" | sed 's/.*\.//' | sort | uniq -c | sort -rn
echo ""
echo "🚀 To test, run:"
echo "  ./run-test.sh"
echo ""
echo "✨ Expected results:"
echo "  • Should load 30+ games"
echo "  • Should detect all systems (NES, SNES, GB, GBC, GBA, N64, NDS, PS, PSP, MD, MS, GG, DC, FBNEO, Ports)"
echo "  • Should handle nested directories"
echo "  • Should detect archives (.zip, .7z, .rar)"
echo "  • Should work with flexible folder names"
echo ""
echo "⌨️  Controls:"
echo "  Arrow Keys  - Navigate"
echo "  Enter       - Select"
echo "  Tab         - Toggle keyboard"
echo "  L/R         - Filter by system"
echo "  F1          - Debug mode"
echo "  ESC         - Quit"
