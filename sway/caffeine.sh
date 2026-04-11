#!/usr/bin/env bash
# Toggle idle inhibit via a hidden kitty window
if swaymsg '[title="^caffeine-inhibitor$"] kill' 2>/dev/null | grep -q '"success": true'; then
    notify-send -t 2000 "󰅶 Caffeine" "Off — idle enabled"
else
    kitty --title caffeine-inhibitor sh -c 'sleep infinity' &
    disown
    notify-send -t 2000 "󰅶 Caffeine" "On — idle disabled"
fi
