# dotfiles

Gaming OS dotfiles for Windows 11.
Stack: GlazeWM · YASB · Brave · Zed · Windows Terminal · Oh My Posh · Flow Launcher · Spotify + Spicetify · Nilesoft Shell · Wallpaper Engine

Theme: Catppuccin throughout (Macchiato dark / Latte light, auto-switching via system preference)  
Font: Geist Mono  
Modifier: Alt

---

## Structure

```
dotfiles/
├── glazewm/
│   └── config.yaml
├── yasb/
│   ├── config.yaml
│   └── styles.css
├── windows-terminal/
│   └── settings.json
├── oh-my-posh/
│   └── saumya.omp.json
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1
├── zed/
│   └── settings.json
├── flow-launcher/
│   └── Settings.json
├── spicetify/
│   └── config-xpui.ini
├── nilesoft-shell/
│   └── shell.nss
└── wallpaper/
    └── catppuccin-macchiato.jpg   ← fallback wallpaper
```

---

## Symlink targets

These are where each app reads its config from. The install script handles all of this automatically.

| Config | Target path |
|---|---|
| GlazeWM | `%USERPROFILE%\.glaze-wm\config.yaml` |
| YASB | `%USERPROFILE%\.yasb\config.yaml` |
| YASB styles | `%USERPROFILE%\.yasb\styles.css` |
| Windows Terminal | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_...\LocalState\settings.json` |
| Oh My Posh | `%USERPROFILE%\.config\ohmyposh\saumya.omp.json` |
| PowerShell profile | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| Zed | `%APPDATA%\Zed\settings.json` |
| Flow Launcher | `%APPDATA%\FlowLauncher\Settings\Settings.json` |
| Spicetify | `%APPDATA%\spicetify\config-xpui.ini` |
| Nilesoft Shell | `C:\Program Files\Nilesoft Shell\shell.nss` |

---

## Manual steps after install

These can't be scripted cleanly:

1. **Wallpaper Engine** — install via Steam, subscribe to wallpapers via Workshop
2. **Brave** — install Catppuccin theme from Chrome Web Store, enable vertical tabs in sidebar settings
3. **7TSP** — run manually to apply Catppuccin Papirus icon pack
4. **SecureUxTheme** — run patcher, apply msstyle theme
5. **Windhawk** — install mods manually via the UI
6. **WinPaletter** — import Macchiato accent colors manually
7. **Files App** — set as default for folders via Windows Settings > Default Apps
8. **Windows Terminal** — update the PowerShell profile GUID in settings.json to match your install
9. **Geist Mono** — install font before launching anything

---

## Keybindings (GlazeWM)

| Action | Binding |
|---|---|
| Focus left/down/up/right | `Alt + H/J/K/L` |
| Move window left/down/up/right | `Alt + Shift + H/J/K/L` |
| Resize | `Alt + Ctrl + H/J/K/L` |
| Switch workspace | `Alt + 1/2/3/4` |
| Move window to workspace | `Alt + Shift + 1/2/3/4` |
| Toggle float | `Alt + Shift + F` |
| Toggle fullscreen | `Alt + F` |
| Close window | `Alt + Shift + Q` |
| Reload config | `Alt + Shift + R` |

## Workspaces

| # | Name | For |
|---|---|---|
| 1 | GAME | Steam, game launchers |
| 2 | WEB | Brave |
| 3 | MUSIC | Spotify |
| 4 | CODE | Zed, Terminal |
