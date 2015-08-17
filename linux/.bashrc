export JAVA_HOME=/opt/jdk1.7.0_79
export JRE_HOME=/opt/jdk1.7.0_79/jre
export PATH=$PATH:/opt/jdk1.7.0_79/bin:/opt/jdk1.7.0_79/jre/bin

# Disabling "You have mail...":
unset MAILCHECK

# Bitbucket:
SSH_ENV=$HOME/.ssh/environment
   
# start the ssh-agent
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add
}
   
if [ -f "${SSH_ENV}" ]; then
     . "${SSH_ENV}" > /dev/null
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

unset SSH_ASKPASS

#export PATH=${PATH}:/home/rolle/android-sdk/adt-bundle-linux-x86-20130717/sdk/tools:/home/rolle/android-sdk/adt-bundle-linux-x86-20130717/sdk/platform-tools

export LANG="en_US.UTF-8"
export LC_CTYPE="fi_FI.UTF-8"
export LC_TIME="fi_FI.UTF-8"
export LESSCHARSET="utf-8"

PROMPT_COMMAND='echo -ne "\033]0;${PWD/$HOME/~}\007"'
function title() { 
otsikko=$@
PROMPT_COMMAND='echo -ne "\033]0;"$otsikko"\007"'; 
}

PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
export PKG_CONFIG_PATH

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
    shopt -s "$option" 2> /dev/null;
done;

#xhost local:mpromber > /dev/null

# Autologin with SSH:
. $HOME/.ssh/ssh-login

# Ympäristömuuttujat:

export FIREFOX_DSP="aoss"
export G_FILENAME_ENCODING=UTF-8
export FLASH_FORCE_ALSA=1
export EDITOR=pico

# remind me, its important!
# usage: remindme <time> <text>
# e.g.: muistuta 10m "omg, the pizza"
function muistuta()
{
    sleep $1 && zenity --info --text "$2" &
}

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/home/rolle/.gvm/bin/gvm-init.sh" ]] && source "/home/rolle/.gvm/bin/gvm-init.sh"
