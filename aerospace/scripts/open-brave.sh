#!/bin/bash

if pgrep -x "Brave Browser" > /dev/null; then
    osascript -e 'tell application "Brave Browser"' \
              -e 'make new window' \
              -e 'activate' \
              -e 'end tell'
    sleep 0.3
    osascript -e 'tell application "System Events" to keystroke "m" using {command down, shift down}'
else
    open -a '/Applications/Brave Browser.app'
fi
