#!/usr/bin/env sh

sketchybar --add item battery right \
           --set battery \
                 icon=􀛨 \
                 icon.font="$FONT:Bold:14.0" \
                 icon.color=$BLUE \
                 label.font="$FONT:Semibold:12.0" \
                 label.color=$WHITE \
                 update_freq=30 \
                 script="$PLUGIN_DIR/battery.sh"
