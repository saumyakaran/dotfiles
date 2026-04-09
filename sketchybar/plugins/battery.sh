#!/bin/sh

BATTERY_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATTERY_INFO" | grep -Eo "\d+%" | head -1)
CHARGING=$(echo "$BATTERY_INFO" | grep -c "AC Power")

if [ "$CHARGING" -gt 0 ]; then
    ICON="􀢋"
else
    BATT_NUM=${PERCENTAGE%%%}
    if [ "$BATT_NUM" -gt 75 ]; then
        ICON="􀛨"
    elif [ "$BATT_NUM" -gt 50 ]; then
        ICON="􀺸"
    elif [ "$BATT_NUM" -gt 25 ]; then
        ICON="􀺶"
    else
        ICON="􀛪"
    fi
fi

sketchybar --set $NAME icon="$ICON" label="$PERCENTAGE"
