export GOPATH=$HOME/golang
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

#export LC_ALL=fi_FI.UTF-8
#export LANG=fi_FI.UTF-8
#export LANGUAGE=fi_FI.UTF-8

EGREEN='\e[1;32m'
NO_COLOR='\e[0m'

#PS1='\e[1;32m\h\e[0m:\W \u \$ '
#PS1='\e[1;32mbliss\e[0m:\W \u \$ '

#PS1="[\t] \h:\e[1;37m\W\e[0m \u\e[1;33m$\e[0m "
#export PS1

# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\u@\h:\W\\$ "

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

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting