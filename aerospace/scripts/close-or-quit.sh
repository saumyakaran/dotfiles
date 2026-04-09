#!/bin/bash

FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}')
FOCUSED_PID=$(aerospace list-windows --focused --format '%{app-pid}')

# Count all windows for this app across all workspaces
WINDOW_COUNT=$(aerospace list-windows --all --format '%{app-pid}' | grep -cx "$FOCUSED_PID")

if [ "$WINDOW_COUNT" -le 1 ]; then
    osascript -e "tell application \"$FOCUSED_APP\" to quit"
else
    # Use AppleScript to close just the front window
    osascript -e "tell application \"$FOCUSED_APP\"" \
              -e 'close front window' \
              -e 'end tell'
fi
