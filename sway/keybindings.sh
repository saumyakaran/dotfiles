#!/usr/bin/env bash
# Sway keybindings cheatsheet — parses sway config, shows bindings in rofi

CONFIG="$HOME/dotfiles/sway/config"

awk '
    function pad(s, width,    p, n) {
        n = width - length(s)
        p = ""
        while (n-- > 0) p = p " "
        return p
    }
    /^mode "/ {
        match($0, /"[^"]+"/)
        current_mode = substr($0, RSTART+1, RLENGTH-2)
        next
    }
    /^}/ { current_mode = ""; next }
    /bindsym/ {
        keys = $2
        gsub(/\$mod/, "Super", keys)

        $1 = ""; $2 = ""
        action = $0
        sub(/^[ \t]+/, "", action)

        gsub(/&/,  "\\&amp;", action)
        gsub(/</,  "\\&lt;",  action)
        gsub(/>/,  "\\&gt;",  action)

        prefix = (current_mode != "") ? "[" current_mode "] " : ""
        printf "<b>%s</b>%s  %s%s\n", keys, pad(keys, 26), prefix, action
    }
' "$CONFIG" | rofi -dmenu -i -markup-rows -p "keys" \
    -theme "$HOME/dotfiles/rofi/keybindings.rasi" >/dev/null
