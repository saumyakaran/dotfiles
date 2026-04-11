#!/usr/bin/env bash
# Clipboard history picker with preview pane
# Runs fzf in a floating kitty window

HIST="$HOME/.local/share/clipman.json"
[[ -f "$HIST" ]] || exit 0

if [[ "$1" == "--pick" ]]; then
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    # Write full content files, output "index<TAB>preview" lines
    python3 -c "
import json
with open('$HIST') as f:
    items = list(reversed(json.load(f)))
for i, item in enumerate(items):
    with open(f'$tmpdir/{i}', 'w') as out:
        out.write(item)
    preview = ' '.join(item.split())[:80]
    print(f'{i}\t{preview}')
" | fzf --no-multi --cycle --no-sort --layout=reverse \
        --prompt="clipboard › " \
        --header="enter pick · esc cancel" \
        --delimiter=$'\t' --with-nth=2 \
        --preview="cat '$tmpdir'/{1}" \
        --preview-window=right:50%:wrap \
    | cut -f1 > "$tmpdir/idx"

    idx=$(cat "$tmpdir/idx" 2>/dev/null)
    [[ -z "$idx" ]] && exit 0

    # Copy the full content
    cat "$tmpdir/$idx" | wl-copy
    exit 0
fi

exec kitty --app-id floating-popup \
    --title "Clipboard History" \
    bash "$0" --pick
