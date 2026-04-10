# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

# HiDPI scaling
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# SSH agent - ask passphrase once per session
unset SSH_ASKPASS
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent)
    ssh-add
fi
