# dotfiles

A portable collection of my configs to bootstrap new machines.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## 🚀 Quick Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/hubertetcetera/dotfiles.git
   cd dotfiles
   ```

1. **Install GNU Stow**

   ```bash
   # macOS
   brew install stow
   # Debian/Ubuntu
   sudo apt install stow
   # Arch
   sudo pacman -S stow
   ```

1. **Deploy configs**

   ```bash
   stow .
   ```

This symlinks everything in the repo into the correct locations (under `~/.config`).

### macOS Ghostty bridge (one-time)

Ghostty looks for configs in:

```bash
~/Library/Application\ Support/com.mitchellh.ghostty/{config,themes}
```

Link that to your stowed config:

```bash
LIB="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$LIB" "$HOME/.config/ghostty/themes"

# backup any existing real files
[ -e "$LIB/config" ] && mv "$LIB/config" "$LIB/config.backup.$(date +%s)"
[ -d "$LIB/themes" ] && [ ! -L "$LIB/themes" ] && mv "$LIB/themes" "$LIB/themes.backup.$(date +%s)"

ln -snf "$HOME/.config/ghostty/config"  "$LIB/config"
ln -snf "$HOME/.config/ghostty/themes"  "$LIB/themes"
```

Verify:

```bash
ls -l "$LIB/config"     # -> ~/.config/ghostty/config
ls -ld "$LIB/themes"    # -> ~/.config/ghostty/themes
```

### Per-tool docs

- [tmux](tmux/README.md)
- [ghostty](ghostty/README.md)
- [lazygit](lazygit/README.md)
