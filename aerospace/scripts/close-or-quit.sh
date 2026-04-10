#!/bin/bash

FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}')
FOCUSED_PID=$(aerospace list-windows --focused --format '%{app-pid}')

# Count how many distinct PIDs this app has
PID_COUNT=$(aerospace list-windows --all --format '%{app-name} %{app-pid}' | grep "^$FOCUSED_APP " | awk '{print $NF}' | sort -u | wc -l | tr -d ' ')

# Count all windows for this app
WINDOW_COUNT=$(aerospace list-windows --all --format '%{app-name}' | grep -cx "$FOCUSED_APP")

if [ "$WINDOW_COUNT" -le 1 ]; then
    # Last window — quit the app
    kill "$FOCUSED_PID" 2>/dev/null
elif [ "$PID_COUNT" -gt 1 ]; then
    # Multiple processes (open -na instances) — kill this specific one
    kill "$FOCUSED_PID" 2>/dev/null
else
    # Single process, multiple windows — close front window or cmd-w
    if ! osascript -e "tell application \"$FOCUSED_APP\" to close front window" 2>/dev/null; then
        osascript -e 'tell application "System Events" to keystroke "w" using command down'
    fi
fi
