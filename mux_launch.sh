#!/bin/bash
# HELP: muOS Collection Manager
# ICON: muos-collection
# GRID: Collections

. /opt/muos/script/var/func.sh

echo app >/tmp/act_go

# Define paths and commands
LOVEDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/muOS-Collection"
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
LOGFILE="${LOGDIR}/muos-collection-launch.log"
echo "[DEBUG] Running as user: $(whoami)" >>"$LOGFILE"

# Start gptokeyb (gamepad to keyboard mapper)
$GPTOKEYB "love" &
GPTOKEYB_PID=$!

# Launch app and capture output
./love . --project-root="$LOVEDIR" >>"$LOGFILE" 2>&1

# Kill gptokeyb
kill -9 "$GPTOKEYB_PID"
