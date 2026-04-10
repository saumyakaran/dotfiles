#!/usr/bin/env python3
from i3ipc import Connection

def on_window_focus(i3, e):
    focused = i3.get_tree().find_focused()
    if not focused or focused.type != "con":
        return

    parent = focused.parent
    if not parent or parent.type == "workspace":
        # First window in workspace, split based on aspect ratio
        if focused.rect.width >= focused.rect.height:
            i3.command("split v")
        else:
            i3.command("split h")
        return

    # Alternate: if parent splits vertically, next should be horizontal
    if parent.layout in ("splitv", "stacked"):
        i3.command("split h")
    else:
        i3.command("split v")

i3 = Connection()
i3.on("window::focus", on_window_focus)
i3.main()
