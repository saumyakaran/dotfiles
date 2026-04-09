#!/bin/bash

FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}')
FOCUSED_PID=$(aerospace list-windows --focused --format '%{app-pid}')
WINDOW_COUNT=$(aerospace list-windows --all --format '%{app-name}' | grep -cx "$FOCUSED_APP")

# Count how many distinct PIDs this app has
PID_COUNT=$(aerospace list-windows --all --format '%{app-name} %{app-pid}' | grep "^$FOCUSED_APP " | awk '{print $NF}' | sort -u | wc -l | tr -d ' ')

if [ "$WINDOW_COUNT" -le 1 ]; then
    osascript -e "tell application \"$FOCUSED_APP\" to quit"
elif [ "$PID_COUNT" -gt 1 ]; then
    # Multiple processes (e.g. open -na instances) — kill this specific one
    aerospace close
    kill "$FOCUSED_PID" 2>/dev/null
else
    # Single process, multiple windows — just close the window
    aerospace close
fi
