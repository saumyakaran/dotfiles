#!/usr/bin/env sh

sketchybar --add item memory right \
           --set memory \
                 icon=􀧖 \
                 icon.font="$FONT:Bold:14.0" \
                 icon.color=$BLUE \
                 label.font="$FONT:Semibold:12.0" \
                 label.color=$WHITE \
                 update_freq=5 \
                 script="$PLUGIN_DIR/memory.sh"
