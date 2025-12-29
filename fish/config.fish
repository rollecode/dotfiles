# Fish shell configuration
# Ported from .bashrc

# If not running interactively, don't do anything
if not status is-interactive
    return
end

# Disable greeting
set -g fish_greeting

# Source secrets (not in git repo)
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# Environment variables
set -gx TERM xterm-256color
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx NINJAFLAGS "-j3"
set -gx CMAKE_BUILD_PARALLEL_LEVEL 3

# PATH modifications
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.spicetify

# NVM support for fish (using nvm.fish or bass)
set -gx NVM_DIR "$HOME/.nvm"

# Clipboard aliases (macOS style)
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

# Tool replacements
alias htop='btop'
alias nano='nvim'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias quota='df -B G'

# Git shortcuts
alias s='git status'
alias p='git push'
alias c='git commit -m'
alias a='git add --all'

# Initialize Oh My Posh
oh-my-posh init fish --config ~/.config/oh-my-posh/easy-term.omp.json | source

# Display system info on startup
fastfetch
echo
