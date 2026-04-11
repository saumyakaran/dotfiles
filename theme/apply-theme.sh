#!/usr/bin/env bash
set -euo pipefail

SCHEME="${1:?Usage: apply-theme.sh <scheme-name>}"
DOTFILES="$HOME/dotfiles"
SCHEMES_DIR="$HOME/.local/share/tinted-theming/tinty/repos/schemes/base16"

# Strip base16- prefix for filename
scheme_file="${SCHEME#base16-}.yaml"
scheme_path="$SCHEMES_DIR/$scheme_file"

if [[ ! -f "$scheme_path" ]]; then
    echo "Scheme not found: $scheme_path" >&2
    exit 1
fi

# Parse hex values from YAML (strip # and quotes)
declare -A colors
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]+(base0[0-9A-Fa-f]):[[:space:]]*\"?\#?([0-9a-fA-F]{6})\"? ]]; then
        colors[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
    fi
done < "$scheme_path"

# Verify we got all 16
for i in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
    key="base0${i}"
    if [[ -z "${colors[$key]:-}" ]]; then
        echo "Missing color: $key" >&2
        exit 1
    fi
done

# Render a mustache template
render() {
    local template="$1"
    local output="$2"
    local content
    content=$(<"$template")
    for key in "${!colors[@]}"; do
        content="${content//\{\{${key}-hex\}\}/${colors[$key]}}"
    done
    echo "$content" > "$output"
}

# Render all templates
render "$DOTFILES/theme/templates/sway-colors.mustache"           "$DOTFILES/sway/colors"
render "$DOTFILES/theme/templates/i3-colors.mustache"             "$DOTFILES/i3/colors"
render "$DOTFILES/theme/templates/waybar-colors.mustache"         "$DOTFILES/waybar/colors.css"
render "$DOTFILES/theme/templates/polybar-colors.mustache"        "$DOTFILES/polybar/colors.ini"
render "$DOTFILES/theme/templates/kitty-colors.mustache"          "$DOTFILES/kitty/colors.conf"
render "$DOTFILES/theme/templates/mako.mustache"                  "$DOTFILES/mako/config"
render "$DOTFILES/theme/templates/dunst.mustache"                 "$DOTFILES/dunst/dunstrc"
render "$DOTFILES/theme/templates/swaylock.mustache"              "$DOTFILES/swaylock/config"
render "$DOTFILES/theme/templates/rofi-colors.mustache"           "$DOTFILES/rofi/colors.rasi"
render "$DOTFILES/theme/templates/rofi-powermenu-colors.mustache" "$DOTFILES/rofi/powermenu-colors.rasi"
render "$DOTFILES/theme/templates/theme-vars.mustache"            "$DOTFILES/theme/vars.sh"

# Save current scheme
echo "$SCHEME" > "$DOTFILES/theme/current"

# Reload running apps
reload_apps() {
    if pgrep -x sway &>/dev/null; then
        swaymsg reload 2>/dev/null || true
    fi
    if pgrep -x waybar &>/dev/null; then
        killall waybar 2>/dev/null
        waybar &>/dev/null &
        disown
    fi
    if pgrep -x kitty &>/dev/null; then
        kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null || true
    fi
    if pgrep -x mako &>/dev/null; then
        makoctl reload 2>/dev/null || true
    fi
}

# GTK light/dark
update_gtk() {
    local hex="${colors[base00]}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    local luminance=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    local gtk_file="$DOTFILES/gtk-3.0-settings.ini"
    if [[ -f "$gtk_file" ]]; then
        if (( luminance > 128 )); then
            sed -i 's/gtk-theme-name=.*/gtk-theme-name=Adwaita/' "$gtk_file"
            sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=false/' "$gtk_file"
        else
            sed -i 's/gtk-theme-name=.*/gtk-theme-name=Adwaita-dark/' "$gtk_file"
            sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=true/' "$gtk_file"
        fi
    fi
}

reload_apps
update_gtk
