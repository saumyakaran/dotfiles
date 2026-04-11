#!/usr/bin/env bash
# Cycle power profiles: Quiet → Balanced → Performance
# Shows notification with current profile

asusctl profile next 2>/dev/null

current=$(asusctl profile get 2>/dev/null | head -1 | sed 's/Active profile: //')

case "$current" in
    Quiet)       icon="󰌪" ;;
    Balanced)    icon="󰛲" ;;
    Performance) icon="󰓅" ;;
    *)           icon="󰌪" ;;
esac

notify-send -t 2000 -h string:x-canonical-private-synchronous:power "$icon Power" "$current"
