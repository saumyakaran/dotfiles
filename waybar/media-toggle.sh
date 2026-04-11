#!/usr/bin/env bash
# Toggle the active media player's window/scratchpad

player=$(playerctl -l 2>/dev/null | head -1)

case "$player" in
    spotify*)
        swaymsg '[class=Spotify] scratchpad show' 2>/dev/null || spotify ;;
    *brave*|*chromium*|*chrome*)
        swaymsg '[app_id=brave-browser] focus' 2>/dev/null ;;
    *firefox*)
        swaymsg '[app_id=firefox] focus' 2>/dev/null ;;
    *stremio*)
        swaymsg '[class=Stremio] focus' 2>/dev/null ;;
    *)
        playerctl play-pause 2>/dev/null ;;
esac
