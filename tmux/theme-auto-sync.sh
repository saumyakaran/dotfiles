#!/usr/bin/env sh

# Auto-sync tmux Catppuccin flavor with macOS appearance.
# This script is intentionally silent because it is called from status-right.

if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  desired_flavor="macchiato"
else
  desired_flavor="latte"
fi

current_flavor="$(tmux show -gv @catppuccin_flavor 2>/dev/null || true)"
if [ -z "$current_flavor" ] || [ "$current_flavor" = "$desired_flavor" ]; then
  exit 0
fi

mkdir -p "$HOME/.config/tmux"
printf 'set -g @catppuccin_flavor "%s"\n' "$desired_flavor" > "$HOME/.config/tmux/catppuccin-flavor.conf"
tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1

exit 0
