#!/usr/bin/env bash
# Cycle aura modes: Theme → Ambient → Off
# State stored in /tmp/aura-mode

STATEFILE="/tmp/aura-mode"
AMBIENT_PID="/tmp/ambient-rgb.pid"

current=$(cat "$STATEFILE" 2>/dev/null || echo "off")

stop_ambient() {
    if [[ -f "$AMBIENT_PID" ]] && kill -0 "$(cat "$AMBIENT_PID")" 2>/dev/null; then
        kill "$(cat "$AMBIENT_PID")" 2>/dev/null
        rm -f "$AMBIENT_PID"
    fi
}

case "$current" in
    off)
        # → Theme color
        stop_ambient
        source ~/dotfiles/theme/vars.sh
        asusctl aura effect static -c "$BASE0D" 2>/dev/null
        echo "theme" > "$STATEFILE"
        notify-send -t 2000 -h string:x-canonical-private-synchronous:aura "󰌵 Aura" "Theme color"
        ;;
    theme)
        # → Ambient
        stop_ambient
        ~/dotfiles/sway/ambient-rgb.sh --daemon &disown
        echo "ambient" > "$STATEFILE"
        notify-send -t 2000 -h string:x-canonical-private-synchronous:aura "󰌵 Aura" "Ambient"
        ;;
    ambient)
        # → Off
        stop_ambient
        asusctl aura effect static -c "000000" 2>/dev/null
        echo "off" > "$STATEFILE"
        notify-send -t 2000 -h string:x-canonical-private-synchronous:aura "󰌵 Aura" "Off"
        ;;
esac
