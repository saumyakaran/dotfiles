#!/bin/bash
vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no')
filled=$((vol / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))
if [ "$mute" = "yes" ]; then
    notify-send -t 1000 -c volume -h string:x-canonical-private-synchronous:volume "󰝟 $bar $vol%" ""
else
    notify-send -t 1000 -c volume -h string:x-canonical-private-synchronous:volume "󰕾 $bar $vol%" ""
fi
