#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.spicetify:$PATH"

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
render "$DOTFILES/theme/templates/gtk-colors.mustache"            "$HOME/.config/gtk-3.0/colors.css"
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
            wallpaper="$DOTFILES/theme/wallpaper.png"
            generate_palette_wallpaper "$wallpaper"
        else
            return 0
        fi
    fi

    # Write sway include file so wallpaper persists across reloads
    echo "output * bg $wallpaper fill" > "$DOTFILES/theme/sway-wallpaper"
    # Apply immediately
    if pgrep -x sway &>/dev/null; then
        swaymsg "output * bg $wallpaper fill" 2>/dev/null || true
    fi

    # Generate lockscreen (solid base01 with scheme name centered)
    generate_lockscreen
}

generate_lockscreen() {
    command -v python3 &>/dev/null || return 0
    local width height
    read -r width height < <(swaymsg -t get_outputs 2>/dev/null | python3 -c "import sys,json; o=json.load(sys.stdin)[0]; m=o['current_mode']; print(m['width'], m['height'])" 2>/dev/null || echo "1920 1080")
    python3 - "$DOTFILES/theme/lockscreen.png" "$width" "$height" \
        "${colors[base01]}" "${colors[base03]}" "${colors[base0D]}" "$SCHEME" <<'PYEOF'
import sys
from PIL import Image, ImageDraw, ImageFont

output, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
bg = f"#{sys.argv[4]}"
fg = f"#{sys.argv[5]}"
accent = f"#{sys.argv[6]}"
scheme = sys.argv[7].replace("base16-", "").replace("-", " ").title()

img = Image.new("RGB", (w, h), bg)
draw = ImageDraw.Draw(img)

font_path = "/home/void/.local/share/fonts/GeistMonoNerdFontPropo-Regular.otf"

try:
    icon_font = ImageFont.truetype(font_path, h // 8)
    label_font = ImageFont.truetype(font_path, h // 40)
except:
    icon_font = ImageFont.load_default()
    label_font = icon_font

# Lock icon centered
lock = "\uf023"  # nerd font lock icon
bbox = draw.textbbox((0, 0), lock, font=icon_font)
lw, lh = bbox[2] - bbox[0], bbox[3] - bbox[1]
draw.text(((w - lw) // 2, (h - lh) // 2 - h // 20), lock, fill=accent, font=icon_font)

# Theme name below the icon
bbox = draw.textbbox((0, 0), scheme, font=label_font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
draw.text(((w - tw) // 2, (h + lh) // 2 + h // 15), scheme, fill=fg, font=label_font)

img.save(output)
PYEOF
}

generate_palette_wallpaper() {
    local output="$1"
    local width height
    read -r width height < <(swaymsg -t get_outputs 2>/dev/null | python3 -c "import sys,json; o=json.load(sys.stdin)[0]; m=o['current_mode']; print(m['width'], m['height'])" 2>/dev/null || echo "1920 1080")

    python3 - "$output" "$width" "$height" \
        "${colors[base00]}" "${colors[base0A]}" \
        "${colors[base08]}" "${colors[base0B]}" "${colors[base0D]}" "${colors[base0E]}" <<'PYEOF'
import sys
from PIL import Image, ImageDraw

output, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
bg = f"#{sys.argv[4]}"
pac_color = f"#{sys.argv[5]}"
ghost_colors = [f"#{c}" for c in sys.argv[6:]]

img = Image.new("RGB", (w, h), bg)
draw = ImageDraw.Draw(img)

r = int(h / 22)  # ~20% smaller than h//18
skirt_h = r // 3  # ghost skirt extends below
gap = int(r * 1.2)
ng = len(ghost_colors)
total_w = r * 2 + ng * r * 2 + (ng) * gap
cx_start = (w - total_w) // 2 + r
# Ghost visual height = 2*r + skirt_h, center the whole scene using that
scene_h = 2 * r + skirt_h
cy = (h - scene_h) // 2 + r  # cy is the center of the dome circle

def draw_pacman(cx, cy, r, color, bg):
    # Pac-man is 2*r tall, ghosts are 2*r+skirt — offset pac-man down to align midpoints
    pac_cy = cy + skirt_h // 2
    draw.pieslice((cx - r, pac_cy - r, cx + r, pac_cy + r), start=35, end=325, fill=color)
    dot_r = r // 6
    draw.ellipse((cx + r + dot_r * 2, pac_cy - dot_r, cx + r + dot_r * 4, pac_cy + dot_r), fill=color)

def draw_ghost(cx, cy, r, color, bg):
    draw.pieslice((cx - r, cy - r, cx + r, cy + r), start=180, end=360, fill=color)
    draw.rectangle((cx - r, cy, cx + r, cy + r), fill=color)
    # Zigzag skirt
    bot = cy + r
    teeth = 3
    tw = (2 * r) / teeth
    th = r // 3
    pts = [(cx - r, bot)]
    for i in range(teeth):
        pts.append((int(cx - r + i * tw + tw / 2), bot + th))
        pts.append((int(cx - r + (i + 1) * tw), bot))
    draw.rectangle((cx - r, bot, cx + r, bot + th + 1), fill=bg)
    draw.polygon(pts, fill=color)
    # Eyes
    er = r // 4
    pr = er // 2
    for ex_off in (-r // 3, r // 3):
        ex = cx + ex_off
        ey = cy - r // 5
        draw.ellipse((ex - er, ey - er, ex + er, ey + er), fill="white")
        draw.ellipse((ex - pr + 2, ey - pr, ex + pr + 2, ey + pr), fill=bg)

x = cx_start
draw_pacman(x, cy, r, pac_color, bg)
x += r + gap + r
for gc in ghost_colors:
    draw_ghost(x, cy, r, gc, bg)
    x += r * 2 + gap

img.save(output)
PYEOF
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
    local spicetify_theme_dir="$HOME/.config/spicetify/Themes/text"
    [[ -d "$spicetify_theme_dir" ]] || return 0
    render "$DOTFILES/theme/templates/spicetify-color.mustache" "$spicetify_theme_dir/color.ini"
    spicetify config current_theme text color_scheme base16 2>/dev/null || true
    spicetify apply 2>/dev/null || true
}

reload_apps
update_gtk
apply_wallpaper
notify_brave
apply_spicetify
