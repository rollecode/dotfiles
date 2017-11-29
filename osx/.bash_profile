# Paths
export PATH=~/.composer/vendor/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$PATH:~/Projects/phpcs/bin:$PATH
export PATH=$PATH:~/Projects/phpcs/scripts:$PATH
export PATH=$PATH:/usr/local:$PATH
export PATH=$PATH:/usr/local/sbin:$PATH
export PATH=$PATH:/usr/local/bin:$PATH
export PATH=$PATH:/usr/sbin:$PATH
export PATH=$PATH:/usr/bin:$PATH

# Other exports
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python2.7/site-packages

# Locales
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_CTYPE="fi_FI.UTF-8"
export LC_TIME="fi_FI.UTF-8"
export LESSCHARSET="utf-8"

# MacPorts Installer addition on 2015-05-05_at_15:14:32: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

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

# Dracula bash prompt for regular user - "➜  ~ (master) "
export PS1="${titlebar}${green}➜  ${blue}\W ${cyan}\$(git_branch)${clear_attributes}"

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Add tab completion for many Bash commands
if which brew > /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
    source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion;
fi;

# Load other dotfiles
for file in ~/.{aliases_private, .aliases, .bashrc}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
