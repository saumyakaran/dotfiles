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

# Compute RGB decimal values for each color
declare -A colors_rgb_r colors_rgb_g colors_rgb_b
for key in "${!colors[@]}"; do
    hex="${colors[$key]}"
    colors_rgb_r[$key]=$((16#${hex:0:2}))
    colors_rgb_g[$key]=$((16#${hex:2:2}))
    colors_rgb_b[$key]=$((16#${hex:4:2}))
done

# Render a mustache template
render() {
    local template="$1"
    local output="$2"
    local content
    content=$(<"$template")
    for key in "${!colors[@]}"; do
        content="${content//\{\{${key}-hex\}\}/${colors[$key]}}"
        content="${content//\{\{${key}-rgb-r\}\}/${colors_rgb_r[$key]}}"
        content="${content//\{\{${key}-rgb-g\}\}/${colors_rgb_g[$key]}}"
        content="${content//\{\{${key}-rgb-b\}\}/${colors_rgb_b[$key]}}"
    done
    echo "$content" > "$output"
}

# Render all templates
render "$DOTFILES/theme/templates/sway-colors.mustache"           "$DOTFILES/sway/colors"
render "$DOTFILES/theme/templates/waybar-colors.mustache"         "$DOTFILES/waybar/colors.css"
render "$DOTFILES/theme/templates/kitty-colors.mustache"          "$DOTFILES/kitty/colors.conf"
render "$DOTFILES/theme/templates/mako.mustache"                  "$DOTFILES/mako/config"
render "$DOTFILES/theme/templates/swaylock.mustache"              "$DOTFILES/swaylock/config"
render "$DOTFILES/theme/templates/rofi-colors.mustache"           "$DOTFILES/rofi/colors.rasi"
render "$DOTFILES/theme/templates/rofi-powermenu-colors.mustache" "$DOTFILES/rofi/powermenu-colors.rasi"
render "$DOTFILES/theme/templates/theme-vars.mustache"            "$DOTFILES/theme/vars.sh"
mkdir -p "$DOTFILES/theme/brave-theme"
render "$DOTFILES/theme/templates/brave-theme.mustache"          "$DOTFILES/theme/brave-theme/manifest.json"

# Save current scheme
echo "$SCHEME" > "$DOTFILES/theme/current"

# Reload running apps
reload_apps() {
    # Kitty and mako first (before sway reload kills/restarts waybar)
    if pgrep -x kitty &>/dev/null; then
        kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null || true
    fi
    if pgrep -x mako &>/dev/null; then
        makoctl reload 2>/dev/null || true
    fi
    # Sway reload also restarts waybar (managed via swaybar_command)
    if pgrep -x sway &>/dev/null; then
        swaymsg reload 2>/dev/null || true
    fi
}

# GTK light/dark
update_gtk() {
    local hex="${colors[base00]}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    local luminance=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    local gtk_file="$DOTFILES/gtk/settings.ini"
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

# Wallpaper
apply_wallpaper() {
    local conf="$DOTFILES/theme/wallpapers.conf"
    local wallpaper=""

    if [[ -f "$conf" ]]; then
        while IFS='=' read -r key val; do
            key=$(echo "$key" | xargs)
            val=$(echo "$val" | xargs)
            [[ "$key" == "#"* || -z "$key" ]] && continue
            if [[ "$key" == "$SCHEME" ]]; then
                wallpaper="${val/#\~/$HOME}"
                break
            fi
        done < "$conf"
    fi

    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        if command -v magick &>/dev/null; then
            wallpaper="/tmp/theme-wallpaper.png"
            generate_palette_wallpaper "$wallpaper"
        else
            return 0
        fi
    fi

    # Write sway include file so wallpaper persists across reloads
    echo "output * bg $wallpaper fill" > "$DOTFILES/theme/sway-wallpaper"
}

generate_palette_wallpaper() {
    local output="$1"
    local width height
    read -r width height < <(swaymsg -t get_outputs 2>/dev/null | python3 -c "import sys,json; o=json.load(sys.stdin)[0]; m=o['current_mode']; print(m['width'], m['height'])" 2>/dev/null || echo "1920 1080")

    local bg="#${colors[base00]}"
    local accent_colors=(8 9 A B C D E F)
    local count=${#accent_colors[@]}
    local swatch_size=$(( height / 10 ))
    local gap=$(( swatch_size / 3 ))
    local total_width=$(( swatch_size * count + gap * (count - 1) ))
    local start_x=$(( (width - total_width) / 2 ))
    local start_y=$(( (height - swatch_size) / 2 ))

    local draw_cmds=""
    local x=$start_x
    for i in "${accent_colors[@]}"; do
        local color="#${colors[base0${i}]}"
        draw_cmds+=" -fill '${color}' -draw 'roundrectangle ${x},${start_y} $(( x + swatch_size )),$(( start_y + swatch_size )) 8,8'"
        x=$(( x + swatch_size + gap ))
    done

    eval magick -size "${width}x${height}" "xc:${bg}" $draw_cmds "$output"
}

# Brave theme notification
notify_brave() {
    if pgrep -f brave &>/dev/null; then
        notify-send -t 3000 "Theme" "Brave theme updated — restart Brave to apply" 2>/dev/null || true
    fi
}

# Spicetify
apply_spicetify() {
    command -v spicetify &>/dev/null || return 0
    local spicetify_theme_dir="$HOME/.config/spicetify/Themes/base16"
    mkdir -p "$spicetify_theme_dir"
    render "$DOTFILES/theme/templates/spicetify-color.mustache" "$spicetify_theme_dir/color.ini"
    spicetify config current_theme base16 2>/dev/null || true
    spicetify apply 2>/dev/null || true
}

reload_apps
update_gtk
apply_wallpaper
notify_brave
apply_spicetify
