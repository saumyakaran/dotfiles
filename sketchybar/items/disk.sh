#!/usr/bin/env sh

sketchybar --add item disk right \
           --set disk \
                 icon=􀨪 \
                 icon.font="$FONT:Bold:14.0" \
                 icon.color=$BLUE \
                 icon.padding_left=4 \
                 label.font="$FONT:Semibold:12.0" \
                 label.color=$WHITE \
                 update_freq=60 \
                 script="$PLUGIN_DIR/disk.sh"
