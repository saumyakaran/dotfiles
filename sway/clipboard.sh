#!/usr/bin/env bash
# Clipboard history picker with preview pane
# Runs fzf in a floating kitty window

HIST="$HOME/.local/share/clipman.json"
[[ -f "$HIST" ]] || exit 0

if [[ "$1" == "--pick" ]]; then
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    # Write full content files and build the menu
    python3 -c "
import json, os, sys
with open('$HIST') as f:
    items = list(reversed(json.load(f)))
for i, item in enumerate(items):
    with open(f'$tmpdir/{i}', 'w') as out:
        out.write(item)
    preview = ' '.join(item.split())[:80]
    print(preview)
" | fzf --ansi --no-multi --cycle --no-sort --layout=reverse \
        --prompt="clipboard › " \
        --header="enter pick · esc cancel" \
        --preview="cat '$tmpdir'/{n}" \
        --preview-window=right:50%:wrap \
    > "$tmpdir/choice"

    [[ -s "$tmpdir/choice" ]] || exit 0

    # fzf output is the display line; find its index by matching
    python3 -c "
import json, subprocess
with open('$HIST') as f:
    items = list(reversed(json.load(f)))
with open('$tmpdir/choice') as f:
    choice = f.read().strip()
# Match by preview content
for i, item in enumerate(items):
    preview = ' '.join(item.split())[:72]
    if preview in choice:
        subprocess.run(['wl-copy', '--'], input=items[i].encode(), check=True)
        break
"
    exit 0
fi

# Launch floating terminal
exec kitty --app-id floating-popup \
    --title "Clipboard History" \
    bash "$0" --pick
