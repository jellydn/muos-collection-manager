#!/bin/bash
# HELP: muOS Collection Manager
# ICON: game-vault
# GRID: Collections

# Disable exit on error
set +e

# Source muOS functions
. /opt/muos/script/var/func.sh || exit 1

echo app >/tmp/act_go

# Define paths
MOUNT_PATH="$(GET_VAR "device" "storage/rom/mount")"
LOVEDIR="${MOUNT_PATH}/MUOS/application/GameVault"
GPTOKEYB="${MOUNT_PATH}/MUOS/emulator/gptokeyb/gptokeyb2.armhf"
CONFDIR="$LOVEDIR/data/"
LOGDIR="${CONFDIR}/log"

# Create directories
mkdir -p "$CONFDIR" "$LOGDIR"

LOGFILE="${LOGDIR}/game-vault-launch.log"

# Export environment variables
SETUP_SDL_ENVIRONMENT
export XDG_DATA_HOME="$CONFDIR"
export MUOS_ROMS_PATH="${MOUNT_PATH}/ROMS"

echo "[$(date)] Script started" >>"$LOGFILE"
echo "[DEBUG] ROM path: $MUOS_ROMS_PATH" >>"$LOGFILE"

# Change to app directory
cd "$LOVEDIR" || exit 1

SET_VAR "system" "foreground_process" "love" 2>/dev/null || true

# Detect system architecture
SYSTEM_ARCH=$(uname -m)
echo "[DEBUG] System architecture: $SYSTEM_ARCH" >>"$LOGFILE"

# Find Love2D binary
LOVE_BIN=""

# Check bundled binary first
if [ -f "$LOVEDIR/love" ]; then
    LOVE_BIN="$LOVEDIR/love"
    echo "[DEBUG] Using bundled binary" >>"$LOGFILE"
fi

# If no bundled binary, search for system Love2D
if [ -z "$LOVE_BIN" ]; then
    echo "[DEBUG] Searching for system Love2D..." >>"$LOGFILE"

    # Check muOS emulator directory
    if [ -f "$MOUNT_PATH/MUOS/emulator/love2d/love" ]; then
        LOVE_BIN="$MOUNT_PATH/MUOS/emulator/love2d/love"
    # Check system paths
    elif [ -f "/opt/muos/emulator/love2d/love" ]; then
        LOVE_BIN="/opt/muos/emulator/love2d/love"
    elif [ -f "/usr/bin/love" ]; then
        LOVE_BIN="/usr/bin/love"
    elif command -v love >/dev/null 2>&1; then
        LOVE_BIN="$(command -v love)"
    fi

    if [ -n "$LOVE_BIN" ]; then
        echo "[DEBUG] Found system Love2D: $LOVE_BIN" >>"$LOGFILE"
    else
        echo "[ERROR] Love2D binary not found" >>"$LOGFILE"
        echo "[ERROR] Please install Love2D or bundle a 64-bit ARM binary" >>"$LOGFILE"
        exit 1
    fi
fi

echo "[DEBUG] Binary selected, setting up paths..." >>"$LOGFILE"

# Set library path (BoxartBuddy approach - simple and works on FAT32)
export LD_LIBRARY_PATH="$LOVEDIR/libs:$LD_LIBRARY_PATH"

echo "[DEBUG] Using Love2D: $LOVE_BIN" >>"$LOGFILE"
echo "[DEBUG] LD_LIBRARY_PATH: $LD_LIBRARY_PATH" >>"$LOGFILE"

# Verify main.lua exists
if [ ! -f "$LOVEDIR/main.lua" ]; then
    echo "[ERROR] main.lua not found in $LOVEDIR" >>"$LOGFILE"
    exit 1
fi

# Test Love2D binary before launching app
echo "[DEBUG] Testing Love2D binary..." >>"$LOGFILE"
if ! "$LOVE_BIN" --version >>"$LOGFILE" 2>&1; then
    echo "[ERROR] Love2D binary test failed" >>"$LOGFILE"
    echo "[ERROR] This usually means missing shared libraries" >>"$LOGFILE"
    echo "[ERROR]" >>"$LOGFILE"
    echo "[ERROR] Solutions:" >>"$LOGFILE"
    echo "[ERROR] 1. Rebuild with Docker (includes libraries):" >>"$LOGFILE"
    echo "[ERROR]    make build-love2d && make dist" >>"$LOGFILE"
    echo "[ERROR] 2. Or use system Love2D (remove bundled binary):" >>"$LOGFILE"
    echo "[ERROR]    rm $LOVEDIR/love" >>"$LOGFILE"
    exit 127
fi
echo "[DEBUG] Love2D binary test passed" >>"$LOGFILE"

# Start gptokeyb (gamepad to keyboard mapper)
$GPTOKEYB "love" &
GPTOKEYB_PID=$!
echo "[DEBUG] gptokeyb started (PID: $GPTOKEYB_PID)" >>"$LOGFILE"

# Launch Love2D application
echo "[DEBUG] Launching Love2D..." >>"$LOGFILE"
"$LOVE_BIN" "$LOVEDIR" >>"$LOGFILE" 2>&1
EXIT_CODE=$?

# Cleanup
kill -9 "$GPTOKEYB_PID" 2>/dev/null || true

echo "[DEBUG] Love2D exited with code: $EXIT_CODE" >>"$LOGFILE"
exit $EXIT_CODE
