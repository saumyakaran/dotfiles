#!/usr/bin/env python3
"""Patch Catppuccin Stylus import.json with current base16 theme colors."""

import json
import re
import sys
from pathlib import Path

DOTFILES = Path.home() / "dotfiles"
VARS_FILE = DOTFILES / "theme" / "vars.sh"
INPUT_FILE = Path.home() / "Downloads" / "import.json"
OUTPUT_FILE = DOTFILES / "theme" / "stylus-import.json"

# Base16 → Catppuccin color mapping
COLOR_MAP = {
    # Backgrounds (dark → light)
    "crust":    "BASE00",
    "mantle":   "BASE00",
    "base":     "BASE01",
    "surface0": "BASE02",
    "surface1": "BASE02",
    "surface2": "BASE03",
    # Overlays / muted
    "overlay0": "BASE03",
    "overlay1": "BASE04",
    "overlay2": "BASE04",
    # Text
    "subtext0": "BASE04",
    "subtext1": "BASE05",
    "text":     "BASE05",
    # Accent colors
    "rosewater": "BASE06",
    "flamingo":  "BASE09",
    "pink":      "BASE0E",
    "mauve":     "BASE0E",
    "red":       "BASE08",
    "maroon":    "BASE08",
    "peach":     "BASE09",
    "yellow":    "BASE0A",
    "green":     "BASE0B",
    "teal":      "BASE0C",
    "sky":       "BASE0C",
    "sapphire":  "BASE0D",
    "blue":      "BASE0D",
    "lavender":  "BASE07",
}


# All Catppuccin color names that may have -filter variants
ALL_CTP_COLORS = [
    "rosewater", "flamingo", "pink", "mauve", "red", "maroon",
    "peach", "yellow", "green", "teal", "sky", "sapphire", "blue",
    "lavender", "text", "subtext1", "subtext0", "overlay2", "overlay1",
    "overlay0", "surface2", "surface1", "surface0", "base", "mantle", "crust",
]


def hex_to_css_filter(hex_color):
    """Convert a hex color to a CSS filter that approximates it.

    Uses the approach: set to black via brightness(0) saturate(100%),
    then invert/sepia/hue-rotate/saturate to reach the target color.
    """
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0

    # Convert to HSL
    cmax = max(r, g, b)
    cmin = min(r, g, b)
    delta = cmax - cmin
    l = (cmax + cmin) / 2.0

    if delta == 0:
        h = 0
        s = 0
    else:
        s = delta / (1 - abs(2 * l - 1)) if (1 - abs(2 * l - 1)) > 0 else 0
        if cmax == r:
            h = 60 * (((g - b) / delta) % 6)
        elif cmax == g:
            h = 60 * ((b - r) / delta + 2)
        else:
            h = 60 * ((r - g) / delta + 4)

    # Build an approximate filter chain
    # Start from black, invert to get close to target lightness,
    # then adjust hue and saturation
    invert_pct = int(l * 100)
    sepia_pct = min(100, int(s * 100))
    hue_deg = int(h)
    sat_pct = max(100, int(s * 500))
    bright_pct = max(50, min(200, int(l * 200)))

    return (
        f"brightness(0) saturate(100%) "
        f"invert({invert_pct}%) sepia({sepia_pct}%) "
        f"saturate({sat_pct}%) hue-rotate({hue_deg}deg) "
        f"brightness({bright_pct}%) contrast(100%)"
    )


def read_base16_colors():
    colors = {}
    for line in VARS_FILE.read_text().splitlines():
        line = line.strip()
        if "=" in line and line.startswith("BASE0"):
            key, val = line.split("=", 1)
            colors[key] = val.lower()
    return colors


def build_color_defs(base16):
    """Build Less variable definitions that replace #lib.palette() entirely."""
    lines = []
    for ctp_name, b16_key in COLOR_MAP.items():
        hex_val = base16[b16_key]
        lines.append(f"    @{ctp_name}: #{hex_val};")
        # Also define the -filter variant
        lines.append(f"    @{ctp_name}-filter: {hex_to_css_filter(hex_val)};")
    lines.append(f"    @accent: #{base16['BASE0D']};")
    lines.append(f"    @accent-filter: {hex_to_css_filter(base16['BASE0D'])};")
    return "\n".join(lines) + "\n"


def patch_source(source, color_defs):
    # Replace #lib.palette(); with our direct color definitions.
    # This bypasses the Catppuccin palette lookup entirely.
    patched = source.replace(
        "#lib.palette();",
        "// #lib.palette(); — replaced by base16 colors\n" + color_defs
    )
    return patched


def main():
    input_file = Path(sys.argv[1]) if len(sys.argv) > 1 else INPUT_FILE
    if not input_file.exists():
        print(f"Input not found: {input_file}", file=sys.stderr)
        sys.exit(1)

    base16 = read_base16_colors()
    color_defs = build_color_defs(base16)

    with open(input_file) as f:
        data = json.load(f)

    patched = 0
    for item in data:
        src = item.get("sourceCode", "")
        if "#catppuccin(" in src and "#lib.palette()" in src:
            item["sourceCode"] = patch_source(src, color_defs)
            patched += 1

    with open(OUTPUT_FILE, "w") as f:
        json.dump(data, f)

    print(f"Patched {patched} styles → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
