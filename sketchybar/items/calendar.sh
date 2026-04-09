#!/usr/bin/env sh

sketchybar --add item calendar right \
           --set calendar \
                 icon=􀉉 \
                 icon.font="$FONT:Bold:14.0" \
                 icon.color=$BLUE \
                 icon.padding_right=6 \
                 label.color=$WHITE \
                 label.font="$FONT:Semibold:12.0" \
                 label.padding_right=4 \
                 update_freq=30 \
                 script="$PLUGIN_DIR/clock.sh"
