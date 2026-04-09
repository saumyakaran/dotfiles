#!/bin/bash

FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}')
WINDOW_COUNT=$(aerospace list-windows --all --format '%{app-name}' | grep -cx "$FOCUSED_APP")

if [ "$WINDOW_COUNT" -le 1 ]; then
    osascript -e "tell application \"$FOCUSED_APP\" to quit"
else
    # Just close the focused window via cmd-w
    osascript -e 'tell application "System Events" to keystroke "w" using command down'
fi
