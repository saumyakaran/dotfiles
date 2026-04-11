#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

DOTFILES="$HOME/dotfiles"
APPLY="$DOTFILES/theme/apply-theme.sh"
CURRENT_FILE="$DOTFILES/theme/current"
PREV_THEME=$(cat "$CURRENT_FILE" 2>/dev/null || echo "base16-catppuccin-macchiato")
CURRENT_PREVIEW="$PREV_THEME"

# Cache scheme list once
SCHEMES=$(tinty list 2>/dev/null | grep '^base16-' | sort)
SELECTED_ROW=0

# Find the row index of the current theme
if [[ -n "$PREV_THEME" ]]; then
    idx=$(echo "$SCHEMES" | grep -n "^${PREV_THEME}$" | cut -d: -f1)
    [[ -n "$idx" ]] && SELECTED_ROW=$((idx - 1))
fi

while true; do
    result=$(echo "$SCHEMES" | rofi -dmenu \
        -p " Theme" \
        -i \
        -no-custom \
        -format 'i s' \
        -selected-row "$SELECTED_ROW" \
        -kb-accept-alt "" \
        -kb-remove-to-eol "" \
        -kb-row-down "Control+j,Down" \
        -kb-row-up "Control+k,Up" \
        -kb-accept-entry "Return" \
        -kb-cancel "Escape" \
        -mesg "C-j/k=nav | Enter=preview/confirm | Esc=revert" \
        -theme-str 'window {width: 400px;}' \
        -theme-str 'listview {lines: 12;}' \
        2>/dev/null) || {
        # Esc pressed — revert
        "$APPLY" "$PREV_THEME"
        exit 0
    }

    [[ -z "$result" ]] && continue

    # Parse index and scheme name from "idx scheme-name"
    SELECTED_ROW="${result%% *}"
    chosen="${result#* }"

    if [[ "$chosen" == "$CURRENT_PREVIEW" ]]; then
        # Same scheme selected twice — confirm
        exit 0
    fi

    # Preview this scheme
    CURRENT_PREVIEW="$chosen"
    "$APPLY" "$chosen"
done
