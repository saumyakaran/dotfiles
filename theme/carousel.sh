#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
APPLY="$DOTFILES/theme/apply-theme.sh"
CURRENT_FILE="$DOTFILES/theme/current"
PREV_THEME=$(cat "$CURRENT_FILE" 2>/dev/null || echo "base16-catppuccin-macchiato")
CURRENT_PREVIEW="$PREV_THEME"

# Cache scheme list once
SCHEMES=$(tinty list 2>/dev/null | grep '^base16-' | sort)

while true; do
    chosen=$(echo "$SCHEMES" | rofi -dmenu \
        -p " Theme" \
        -i \
        -no-custom \
        -kb-accept-alt "" \
        -kb-row-down "j,Down" \
        -kb-row-up "k,Up" \
        -kb-accept-entry "Return" \
        -kb-cancel "Escape" \
        -mesg "Enter=preview/confirm | Esc=revert" \
        -theme-str 'window {width: 400px;}' \
        -theme-str 'listview {lines: 12;}' \
        2>/dev/null) || {
        # Esc pressed — revert
        "$APPLY" "$PREV_THEME"
        exit 0
    }

    [[ -z "$chosen" ]] && continue

    if [[ "$chosen" == "$CURRENT_PREVIEW" ]]; then
        # Same scheme selected twice — confirm
        exit 0
    fi

    # Preview this scheme
    CURRENT_PREVIEW="$chosen"
    "$APPLY" "$chosen"
done
