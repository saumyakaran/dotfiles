#!/bin/sh

DISK_USAGE=$(df -H / | tail -1 | awk '{print $5}')
sketchybar --set $NAME label="$DISK_USAGE"
