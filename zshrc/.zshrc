### ── History ─────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

### ── Prompt ──────────────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' formats ' %F{#c6a0f6}(%b)%f'
zstyle ':vcs_info:*' actionformats ' %F{#c6a0f6}(%b|%a)%f'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PS1='%F{#8aadf4}%~%f${vcs_info_msg_0_} %(?.%F{#a6da95}.%F{#ed8796})$%f '

### ── Environment Variables ────────────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
fi

### ── PATH ────────────────────────────────────────────────────────────────────
for p in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
  [ -d "$p" ] && case ":$PATH:" in *":$p:"*) ;; *) PATH="$p:$PATH" ;; esac
done
export PATH

### ── HiDPI ───────────────────────────────────────────────────────────────────
export QT_AUTO_SCREEN_SCALE_FACTOR=1

### ── SSH agent ───────────────────────────────────────────────────────────────
unset SSH_ASKPASS
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

### ── Zsh plugins ─────────────────────────────────────────────────────────────
[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### ── Keybindings ─────────────────────────────────────────────────────────────
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search
bindkey '^L' forward-word

### ── Aliases ─────────────────────────────────────────────────────────────────
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd -1 --group-dirs=first'
  alias la='lsd -1 -a --group-dirs=first'
  alias lg='lsd --group-dirs=first'
  alias ll='lsd -l --group-dirs=first'
  alias lla='lsd -la --group-dirs=first'
  alias lt='lsd --tree'
fi

if command -v xclip >/dev/null 2>&1; then
  alias clip='xclip -selection clipboard'
fi

### ── yazi (cd on exit) ────────────────────────────────────────────────────────
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

### ── Rust env ────────────────────────────────────────────────────────────────
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

### ── fzf ─────────────────────────────────────────────────────────────────────
[ -r "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -r /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

### ── zoxide (must be last) ──────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
