# Node version manager
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# Silence Catalina zsh notification
export BASH_SILENCE_DEPRECATION_WARNING=1

# Gopath
export GOPATH=/usr/local/go

# Paths
export PATH=$PATH:$GOPATH/bin:/usr/local/bin:/Users/rolle/.rvm/gems/ruby-2.6.3/bin:$PATH

# Editor
export EDITOR=nano

# Title bar - "user@host: ~"
title="\u@\h: \w"
titlebar="\[\033]0;"$title"\007\]"

# Define colors
black="\[$(tput setaf 0)\]"
red="\[$(tput setaf 1)\]"
green="\[$(tput setaf 2)\]"
yellow="\[$(tput setaf 3)\]"
blue="\[$(tput setaf 4)\]"
magenta="\[$(tput setaf 5)\]"
cyan="\[$(tput setaf 6)\]"
white="\[$(tput setaf 7)\]"

# Git branch
git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)\ /';
}

# Clear attributes
clear_attributes="\[$(tput sgr0)\]"

# Dracula bash prompt for regular user
export PS1="${titlebar}${green}$ ${blue}\W ${cyan}\$(git_branch)${clear_attributes}"

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Load other dotfiles
source $HOME/.aliases_private
source $HOME/.aliases

source $HOME/bash-wakatime/bash-wakatime.sh
export PATH="/usr/local/opt/node@10/bin:$PATH"
PATH="$HOME/.composer/vendor/bin:$PATH"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export PATH="/usr/local/opt/bison/bin:$PATH"
export PATH="/usr/local/opt/gettext/bin:$PATH"

export PATH="/usr/local/opt/php@7.4/bin:$PATH"
export PATH="/usr/local/opt/php@7.4/sbin:$PATH"

