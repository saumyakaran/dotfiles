#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

DOTFILES="$HOME/dotfiles"
APPLY="$DOTFILES/theme/apply-theme.sh"
CURRENT_FILE="$DOTFILES/theme/current"
SCHEMES_DIR="$HOME/.local/share/tinted-theming/tinty/repos/schemes/base16"
PREV_THEME=$(cat "$CURRENT_FILE" 2>/dev/null || echo "base16-catppuccin-macchiato")
CURRENT_PREVIEW="$PREV_THEME"

# Build display list: "slug\0display\x1ftrue\n" with pango markup
# Format: colored squares + pretty name, mapped to slug
build_cache() {
    local cache_file="/tmp/theme-carousel-cache"
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return
    fi
    local block=$'\u2588'
    for yaml in "$SCHEMES_DIR"/*.yaml; do
        local slug="base16-$(basename "$yaml" .yaml)"
        local name="" variant="" colors=()
        while IFS= read -r line; do
            if [[ "$line" =~ ^name:\ *\"?(.+?)\"?$ ]]; then
                name="${BASH_REMATCH[1]}"
                name="${name%\"}"
            elif [[ "$line" =~ ^variant:\ *\"?(light|dark)\"? ]]; then
                variant="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+(base0[89A-Fa-f]):[[:space:]]*\"?\#?([0-9a-fA-F]{6}) ]]; then
                colors+=("${BASH_REMATCH[2]}")
            fi
        done < "$yaml"
        [[ -z "$name" ]] && name="$slug"
        local icon="󰖔"
        [[ "$variant" == "light" ]] && icon="󰖨"
        local swatches=""
        for c in "${colors[@]}"; do
            swatches+="<span background='#${c}'>    </span>"
        done
        echo "${slug} ${icon}  ${name}   ${swatches}"
    done | sort -t' ' -k3 > "$cache_file"
    cat "$cache_file"
}

ENTRIES=$(build_cache)
SELECTED_ROW=0

# Find the row index of the current theme
if [[ -n "$PREV_THEME" ]]; then
    idx=$(echo "$ENTRIES" | grep -n "^${PREV_THEME} " | cut -d: -f1)
    [[ -n "$idx" ]] && SELECTED_ROW=$((idx - 1))
fi

# Display list (everything after the slug)
display_list() {
    echo "$ENTRIES" | while read -r slug rest; do
        echo "$rest"
    done
}

# Map display index back to slug
slug_at() {
    echo "$ENTRIES" | sed -n "$((${1} + 1))p" | cut -d' ' -f1
}

while true; do
    result=$(display_list | rofi -dmenu \
        -p " Theme" \
        -i \
        -no-custom \
        -markup-rows \
        -format 'i' \
        -selected-row "$SELECTED_ROW" \
        -kb-accept-alt "" \
        -kb-remove-to-eol "" \
        -kb-row-down "Control+j,Down" \
        -kb-row-up "Control+k,Up" \
        -kb-accept-entry "Return" \
        -kb-cancel "Escape" \
        -mesg "C-j/k=nav | Enter=preview/confirm | Esc=revert" \
        -theme ~/dotfiles/rofi/carousel.rasi \
        2>/dev/null) || {
        # Esc pressed — revert
        "$APPLY" "$PREV_THEME"
        exit 0
    }

    [[ -z "$result" ]] && continue
    SELECTED_ROW="$result"
    chosen=$(slug_at "$result")

    if [[ "$chosen" == "$CURRENT_PREVIEW" ]]; then
        # Same scheme selected twice — confirm
        exit 0
    fi

    # Preview this scheme
    CURRENT_PREVIEW="$chosen"
    "$APPLY" "$chosen"
done
