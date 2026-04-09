#!/bin/bash

FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}')
FOCUSED_PID=$(aerospace list-windows --focused --format '%{app-pid}')

# Count all windows for this PID across all workspaces
WINDOW_COUNT=$(aerospace list-windows --all --format '%{app-pid}' | grep -cx "$FOCUSED_PID")

if [ "$WINDOW_COUNT" -le 1 ]; then
    osascript -e "tell application \"$FOCUSED_APP\" to quit"
else
    # Try AppleScript close first, fall back to cmd-w
    if ! osascript -e "tell application \"$FOCUSED_APP\" to close front window" 2>/dev/null; then
        osascript -e 'tell application "System Events" to keystroke "w" using command down'
    fi
fi
