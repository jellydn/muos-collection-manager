#!/bin/bash
# HELP: muOS Collection Manager
# ICON: game-vault
# GRID: Collections

. /opt/muos/script/var/func.sh

echo app >/tmp/act_go

# Define paths and commands
LOVEDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/GameVault"
GPTOKEYB="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/gptokeyb/gptokeyb2.armhf"
CONFDIR="$LOVEDIR/data/"
LOGDIR="${CONFDIR}/log"

mkdir -p "$CONFDIR" "$LOGDIR"

# Export environment variables
SETUP_SDL_ENVIRONMENT
export XDG_DATA_HOME="$CONFDIR"

# Launcher
cd "$LOVEDIR" || exit
SET_VAR "system" "foreground_process" "love"
export LD_LIBRARY_PATH="$LOVEDIR/libs:$LD_LIBRARY_PATH"
LOGFILE="${LOGDIR}/game-vault-launch.log"
echo "[DEBUG] Running as user: $(whoami)" >>"$LOGFILE"

# Find Love2D binary (check multiple locations)
LOVE_BIN=""
if [ -f "/usr/bin/love" ]; then
    LOVE_BIN="/usr/bin/love"
elif [ -f "/usr/local/bin/love" ]; then
    LOVE_BIN="/usr/local/bin/love"
elif [ -f "$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/love2d/love" ]; then
    LOVE_BIN="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/love2d/love"
else
    echo "[ERROR] Love2D binary not found" >>"$LOGFILE"
    exit 1
fi

echo "[DEBUG] Using Love2D: $LOVE_BIN" >>"$LOGFILE"

# Start gptokeyb (gamepad to keyboard mapper)
$GPTOKEYB "love" &
GPTOKEYB_PID=$!

# Launch app and capture output
"$LOVE_BIN" "$LOVEDIR" >>"$LOGFILE" 2>&1

# Kill gptokeyb
kill -9 "$GPTOKEYB_PID"
