#!/usr/bin/env bash

STATEFILE="/tmp/polybar-stats-expanded"

if [ -f "$STATEFILE" ]; then
    rm "$STATEFILE"
else
    touch "$STATEFILE"
fi

polybar-msg action "#cpu-ipc.module_toggle" 2>/dev/null
polybar-msg action "#memory-ipc.module_toggle" 2>/dev/null
polybar-msg action "#filesystem-ipc.module_toggle" 2>/dev/null
