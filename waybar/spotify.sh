#!/usr/bin/env bash
# Spotify now-playing with smooth scrolling marquee

MAX=40
SPEED=0.3  # seconds per tick

while true; do
    text=$(playerctl -p spotify metadata --format '{{artist}} — {{title}}' 2>/dev/null)
    if [[ -z "$text" ]]; then
        echo ""
        sleep 2
        continue
    fi

    if (( ${#text} <= MAX )); then
        echo "$text"
        sleep 2
    else
        padded="$text   ·   "
        len=${#padded}
        offset=0
        # Scroll through once, then re-fetch metadata
        while (( offset < len )); do
            doubled="$padded$padded"
            echo "${doubled:$offset:$MAX}"
            (( offset++ ))
            sleep "$SPEED"
        done
    fi
done
