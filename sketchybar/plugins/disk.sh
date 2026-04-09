#!/bin/sh

DISK_JSON=$(diskutil info -plist / | plutil -convert json -o - -)
TOTAL=$(osascript -e "tell application \"System Events\" to return (do shell script \"diskutil info / | grep 'Container Total Space' | awk '{print $4}'\")" 2>/dev/null)

# Fallback: use df with 1G blocks and available space to compute used
DISK_INFO=$(df -g / | tail -1)
TOTAL_G=$(echo "$DISK_INFO" | awk '{print $2}')
AVAIL_G=$(echo "$DISK_INFO" | awk '{print $4}')
USED_G=$(( TOTAL_G - AVAIL_G ))

sketchybar --set $NAME label="${USED_G}/${TOTAL_G}G"
