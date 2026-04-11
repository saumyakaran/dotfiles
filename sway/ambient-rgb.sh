#!/usr/bin/env bash
# Ambient RGB - syncs keyboard color with screen content
# Toggle on/off with this script. Kills existing instance if running.

PIDFILE="/tmp/ambient-rgb.pid"

# If called directly (not from aura-cycle), toggle
if [[ "$1" != "--daemon" ]]; then
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
        source ~/dotfiles/theme/vars.sh
        asusctl aura effect static -c "$BASE0D" 2>/dev/null
        exit 0
    fi
fi

echo $$ > "$PIDFILE"
trap "rm -f $PIDFILE" EXIT

last_color=""
while true; do
    # Capture small screenshot for speed (scaled down)
    color=$(grim -t ppm -s 0.1 - 2>/dev/null | python3 -c "
import sys
data = sys.stdin.buffer.read()
# Skip PPM header (P6\nWxH\n255\n)
idx = 0
for _ in range(3):
    idx = data.index(b'\n', idx) + 1
pixels = data[idx:]
r = g = b = n = 0
# Sample every 30th pixel for speed
for i in range(0, len(pixels) - 2, 90):
    r += pixels[i]; g += pixels[i+1]; b += pixels[i+2]; n += 1
if n > 0:
    print(f'{r//n:02x}{g//n:02x}{b//n:02x}')
" 2>/dev/null)

    if [[ -n "$color" && "$color" != "$last_color" ]]; then
        asusctl aura effect static -c "$color" 2>/dev/null
        last_color="$color"
    fi
    sleep 0.1
done
