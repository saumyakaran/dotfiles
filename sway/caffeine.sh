#!/usr/bin/env bash
# Toggle idle inhibit. Uses a hidden kitty window with title "caffeine"
# that sway's for_window rule marks as inhibit_idle.
if swaymsg '[title="^caffeine-inhibitor$"] kill' 2>/dev/null | grep -q '"success": true'; then
    notify-send -t 2000 "Caffeine" "Off"
else
    kitty --title caffeine-inhibitor -o initial_window_width=1 -o initial_window_height=1 sh -c 'sleep infinity' &
    disown
    sleep 0.3
    swaymsg '[title="^caffeine-inhibitor$"] move scratchpad'
    notify-send -t 2000 "Caffeine" "On"
fi
