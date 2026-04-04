// Nilesoft Shell configuration
// Docs: https://nilesoft.org/docs
{
  "shell": {
    "theme": {
      // Catppuccin Macchiato
      "back": "#24273a",
      "border": "#363a4f",
      "text": "#cad3f5",
      "text.highlight": "#8aadf4",
      "back.highlight": "#363a4f",
      "separator": "#494d64",
      "radius": 6,
      "font.name": "Geist Mono",
      "font.size": 12,
      "shadow": true,
      "shadow.color": "#000000",
      "shadow.size": 8
    },

    "settings": {
      "show_default_items": true,
      "show_file_icon": true,
      "animation": true,
      "animation.duration": 120
    }
  },

  "menu": [
    // ── Custom items ────────────────────────────────────────
    {
      "title": "Open in Zed",
      "icon": "cmd",
      "cmd": "zed \"%path%\"",
      "show": "sel.isfile || sel.isfolder || back.isfolder",
      "sep": true
    },
    {
      "title": "Open Terminal Here",
      "icon": "cmd",
      "cmd": "wt -d \"%cd%\"",
      "show": "back.isfolder || sel.isfolder"
    },
    {
      "title": "Copy Path",
      "icon": "copy",
      "cmd": "clip \"%path%\"",
      "show": "sel.isfile || sel.isfolder"
    },
    {
      "sep": true
    }
  ]
}
