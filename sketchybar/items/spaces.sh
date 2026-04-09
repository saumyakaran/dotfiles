#!/usr/bin/env sh

sketchybar --add event aerospace_workspace_change

WORKSPACES=($(aerospace list-workspaces --all))
LAST_IDX=$(( ${#WORKSPACES[@]} - 1 ))

for i in "${!WORKSPACES[@]}"; do
    sid="${WORKSPACES[$i]}"

    EXTRA_LEFT=0
    EXTRA_RIGHT=0
    if [ "$i" -eq 0 ]; then
        EXTRA_LEFT=4
    fi
    if [ "$i" -eq "$LAST_IDX" ]; then
        EXTRA_RIGHT=4
    fi

    sketchybar --add item "space.$sid" left \
        --subscribe "space.$sid" aerospace_workspace_change \
        --set "space.$sid" \
        label="$sid" \
        label.font="$FONT:Bold:13.0" \
        label.color=$SUBTEXT0 \
        label.highlight_color=$BLUE \
        label.width=30 \
        label.align=center \
        label.y_offset=1 \
        label.padding_left=2 \
        label.padding_right=2 \
        icon.drawing=off \
        background.color=$SURFACE0 \
        background.corner_radius=8 \
        background.height=26 \
        background.drawing=off \
        background.padding_left=$EXTRA_LEFT \
        background.padding_right=$EXTRA_RIGHT \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/aerospacer.sh $sid"
done
