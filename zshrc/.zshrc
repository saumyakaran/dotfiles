### ── Prompt ──────────────────────────────────────────────────────────────────
# same look; add async-safe prompt escape if you ever enable RPROMPT/git info
PS1="%1~ → "

### ── Platform detection (fast & POSIXy) ──────────────────────────────────────
IS_MACOS=false
IS_LINUX=false
case "$OSTYPE" in
  darwin*) IS_MACOS=true ;;
  linux*)  IS_LINUX=true ;;
esac

### ── Theme mode (COLOR_MODE for Neovim/tmux; Ghostty follows system) ──────────
[ -f "$HOME/.config/theme-mode" ] && . "$HOME/.config/theme-mode"
# Write tmux Catppuccin flavor so status bar matches light/dark (sourced by tmux.conf).
_tmux_catppuccin_flavor_sync() {
  local mode="${COLOR_MODE:-}"
  if [ -z "$mode" ] && [ -f "$HOME/.config/theme-mode" ]; then
    . "$HOME/.config/theme-mode"
    mode="${COLOR_MODE:-}"
  fi
  if [ -z "$mode" ] && [ "$(uname -s)" = "Darwin" ]; then
    mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)
    [ "$mode" = "Dark" ] && mode=dark || mode=light
  fi
  [ -z "$mode" ] && mode=dark
  local flavor="macchiato"
  [ "$mode" = "light" ] && flavor="latte"
  mkdir -p "$HOME/.config/tmux"
  printf '%s\n' "set -g @catppuccin_flavor \"$flavor\"" > "$HOME/.config/tmux/catppuccin-flavor.conf"
}
_tmux_catppuccin_flavor_sync
unset -f _tmux_catppuccin_flavor_sync
theme() {
  local mode="${1:-}"
  case "$mode" in
    light|dark)
      mkdir -p "$HOME/.config"
      echo "export COLOR_MODE=$mode" > "$HOME/.config/theme-mode"
      export COLOR_MODE=$mode
      mkdir -p "$HOME/.config/tmux"
      if [ "$mode" = "light" ]; then
        printf '%s\n' 'set -g @catppuccin_flavor "latte"' > "$HOME/.config/tmux/catppuccin-flavor.conf"
      else
        printf '%s\n' 'set -g @catppuccin_flavor "macchiato"' > "$HOME/.config/tmux/catppuccin-flavor.conf"
      fi
      echo "Theme set to $mode (new shells and Neovim will use it; reload tmux with prefix+R for status bar)"
      ;;
    *)
      echo "Usage: theme light|dark" >&2
      return 1
      ;;
  esac
}

### ── Environment Variables ────────────────────────────────────────────────────
# Set default editor (prefer nvim, fallback to vim)
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
fi

### ── macOS-only: Homebrew, MongoDB, LLVM, Xcode SDK ─────────────────────────
if $IS_MACOS; then
  # Prefer Homebrew in PATH
  for p in /opt/homebrew/bin /usr/local/bin; do
    case ":$PATH:" in *":$p:"*) ;; *) PATH="$p:$PATH" ;; esac
  done
  export PATH

  if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix 2>/dev/null)"

    # zsh plugins via brew (if installed)
    [ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
      && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [ -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
      && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # LLVM (clang/clangd) via brew
    if [ -d "$BREW_PREFIX/opt/llvm" ]; then
      export LIBCLANG_PATH="$BREW_PREFIX/opt/llvm/lib"
      case ":$PATH:" in
        *":$BREW_PREFIX/opt/llvm/bin:"*) ;;
        *) PATH="$BREW_PREFIX/opt/llvm/bin:$PATH" ;;
      esac
    fi
  fi

  # zsh plugins via nix (check after brew so nix takes precedence if both present)
  for nix_profile in "$HOME/.local/state/nix/profiles/home-manager" "$HOME/.local/state/home-manager/gcroots/current-home" "/etc/profiles/per-user/$USER" "$HOME/.nix-profile"; do
    [ -r "$nix_profile/home-path/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
      && source "$nix_profile/home-path/share/zsh-autosuggestions/zsh-autosuggestions.zsh" && break
  done
  for nix_profile in "$HOME/.local/state/nix/profiles/home-manager" "$HOME/.local/state/home-manager/gcroots/current-home" "/etc/profiles/per-user/$USER" "$HOME/.nix-profile"; do
    [ -r "$nix_profile/home-path/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
      && source "$nix_profile/home-path/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" && break
  done

  # MongoDB (if installed via brew tap)
  for p in /opt/homebrew/opt/mongodb-community@4.4/bin; do
    [ -d "$p" ] && case ":$PATH:" in *":$p:"*) ;; *) PATH="$p:$PATH" ;; esac
  done

  # Xcode SDK (for bindgen, etc.)
  if command -v xcrun >/dev/null 2>&1; then
    SDK="$(xcrun --show-sdk-path 2>/dev/null)"
    if [ -n "$SDK" ]; then
      export SDKROOT="$SDK"
      export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$SDK"
    fi
  fi
fi

### ── Linux-only tweaks ───────────────────────────────────────────────────────
if $IS_LINUX; then
  # user-local bin
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac

  # optional: distro-provided zsh plugins
  [ -r "/etc/zsh/zsh-autosuggestions.zsh" ] && source "/etc/zsh/zsh-autosuggestions.zsh"
  [ -r "/etc/zsh/zsh-syntax-highlighting.zsh" ] && source "/etc/zsh/zsh-syntax-highlighting.zsh"
fi

### ── User-local tool bins (portable, no hardcoded username) ─────────────────
for p in "$HOME/.local/bin" "$HOME/.opencode/bin" "$HOME/.foundry/bin"; do
  [ -d "$p" ] && case ":$PATH:" in *":$p:"*) ;; *) PATH="$p:$PATH" ;; esac
done

### ── Optional host-local overrides (kept out of git) ────────────────────────
[ -r "$HOME/.zsh.local" ] && source "$HOME/.zsh.local"

export PATH

### ── Shared keybindings (only if widgets exist) ──────────────────────────────
# Define helpers to safely bind only when the target widget exists.
_bind_if_present() {
  local key="$1" widget="$2"
  zle -l | grep -qx -- "$widget" && bindkey "$key" "$widget"
}

# These widgets come from zsh-autosuggestions; bind only if loaded
_bind_if_present '^w' autosuggest-execute
_bind_if_present '^e' autosuggest-accept
_bind_if_present '^u' autosuggest-toggle

# Built-ins / vi-mode friendly
bindkey '^L' forward-word    # (vi-forward-word requires vi-mode; this is safer)
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search
# "jj" to escape to command mode (if using vi-mode)
zle -l | grep -qx vi-cmd-mode && bindkey -M viins 'jj' vi-cmd-mode

unset -f _bind_if_present

### ── pnpm (cross-platform) ───────────────────────────────────────────────────
# macOS default
if $IS_MACOS; then
  PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
else
  # linux default (matches pnpm docs)
  PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
fi
export PNPM_HOME
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) PATH="$PNPM_HOME:$PATH" ;; esac

### ── Rust env ────────────────────────────────────────────────────────────────
export RUSTC_WRAPPER="${RUSTC_WRAPPER:-sccache}"
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

### ── fzf init (works with brew, nix, or manual) ──────────────────────────────
# 1) Manual install default location
[ -r "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# 2) Nix profile hook (if present)
if [ -r "$HOME/.nix-profile/etc/profile.d/fzf.zsh" ]; then
  source "$HOME/.nix-profile/etc/profile.d/fzf.zsh"
fi

# 3) System-wide nix profile (less common but safe)
if [ -r "/etc/profile.d/fzf.zsh" ]; then
  source "/etc/profile.d/fzf.zsh"
fi

### ── Aliases ───────────────────────────────────────────────────────────────────
# lsd (modern ls replacement with icons)
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd -1 --group-dirs=first'                           # Single column
  alias la='lsd -1 -a --group-dirs=first'                        # Single column + hidden files
  alias lg='lsd --group-dirs=first'           # Grid layout, dirs first
  alias ll='lsd -l --group-dirs=first'        # Long format
  alias lla='lsd -la --group-dirs=first'      # Long format + hidden files
  alias lt='lsd --tree'                       # Tree view
fi

# yazi (file manager with cd on exit)
if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

# Cross-platform clipboard (copy to clipboard)
if command -v pbcopy >/dev/null 2>&1; then
  # macOS
  alias clip='pbcopy'
elif command -v xclip >/dev/null 2>&1; then
  # Linux (X11)
  alias clip='xclip -selection clipboard'
elif command -v wl-copy >/dev/null 2>&1; then
  # Linux (Wayland)
  alias clip='wl-copy'
fi

# YouTube TUI - much better than custom scripts!
if command -v youtube-tui >/dev/null 2>&1; then
  alias yt='youtube-tui'
fi

### ── zoxide (must be last) ──────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
