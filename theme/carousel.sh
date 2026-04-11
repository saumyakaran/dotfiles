#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
APPLY="$DOTFILES/theme/apply-theme.sh"
CURRENT_FILE="$DOTFILES/theme/current"
PREV_THEME=$(cat "$CURRENT_FILE" 2>/dev/null || echo "base16-catppuccin-macchiato")
CURRENT_PREVIEW="$PREV_THEME"

# Get all base16 scheme names
schemes() {
    tinty list 2>/dev/null | grep '^base16-' | sort
}

# Build display list with current marked
build_list() {
    local current="$1"
    schemes | while read -r scheme; do
        if [[ "$scheme" == "$current" ]]; then
            echo "* $scheme"
        else
            echo "  $scheme"
        fi
    done
}

while true; do
    chosen=$(build_list "$CURRENT_PREVIEW" | rofi -dmenu \
        -p "Theme" \
        -i \
        -no-custom \
        -kb-accept-alt "" \
        -kb-row-down "j,Down" \
        -kb-row-up "k,Up" \
        -kb-accept-entry "Return" \
        -kb-cancel "Escape" \
        -mesg "Enter=preview/confirm | Esc=revert" \
        2>/dev/null) || {
        # Esc pressed — revert
        "$APPLY" "$PREV_THEME"
        exit 0
    }

    # Strip prefix
    chosen=$(echo "$chosen" | sed 's/^[* ] *//')
    [[ -z "$chosen" ]] && continue

    if [[ "$chosen" == "$CURRENT_PREVIEW" ]]; then
        # Same scheme selected twice — confirm
        exit 0
    fi

    # Preview this scheme
    CURRENT_PREVIEW="$chosen"
    "$APPLY" "$chosen" &
done
