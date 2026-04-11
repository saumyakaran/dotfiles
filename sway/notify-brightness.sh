#!/bin/bash
pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
filled=$((pct / 10))
empty=$((10 - filled))
bar=$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))
notify-send -t 1000 -c brightness -h string:x-canonical-private-synchronous:brightness "󰃟 $bar $pct%" ""
