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

# Set colors
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM='gnome-256color';
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM='xterm-256color';
fi;

# Define colors
if tput setaf 1 &> /dev/null; then
    tput sgr0; # reset colors
    bold=$(tput bold);
    reset=$(tput sgr0);
    black=$(tput setaf 0);
    blue=$(tput setaf 33);
    cyan=$(tput setaf 37);
    green=$(tput setaf 64);
    orange=$(tput setaf 166);
    purple=$(tput setaf 125);
    red=$(tput setaf 124);
    violet=$(tput setaf 61);
    white=$(tput setaf 15);
    yellow=$(tput setaf 136);
    grey=$(tput setaf 7);
else
    bold='';
    reset="\e[0m";
    black="\e[1;30m";
    blue="\e[1;34m";
    cyan="\e[1;36m";
    green="\e[1;32m";
    orange="\e[1;33m";
    purple="\e[1;35m";
    red="\e[1;31m";
    violet="\e[1;35m";
    white="\e[1;37m";
    yellow="\e[1;33m";
fi;

# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
    userStyle="${red}";
else
    userStyle="${orange}";
fi;

# Highlight the hostname when connected via SSH.
if [[ "${SSH_TTY}" ]]; then
    hostStyle="${bold}${red}";
else
    hostStyle="${yellow}";
fi;

# Set the terminal title to the current working directory.
PS1="\[\033]0;\w\007\]";
PS1+="\[${bold}\]\n"; # newline
PS1+="\[${userStyle}\]\u"; # username
PS1+="\[${white}\] at ";
PS1+="\[${hostStyle}\]\h"; # host
PS1+="\[${white}\] in ";
PS1+="\[${green}\]\w"; # working directory
PS1+=" \[${grey}\]\$git_branch\[$txtred\]\$git_dirty\[$txtrst\] "
PS1+="\n";
PS1+="\[${white}\]\$ \[${reset}\]"; # `$` (and reset color)
export PS1;

PS2="\[${yellow}\]→ \[${reset}\]";
export PS2;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Add tab completion for many Bash commands
if which brew > /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
    source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion;
fi;

# Load other dotfiles
for file in ~/.{aliases_private, .bashrc}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
