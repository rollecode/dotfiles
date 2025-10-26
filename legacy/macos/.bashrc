#export PATH="$(brew --prefix php@7.2)/bin:$PATH"
#export PATH="$(brew --prefix php@7.3)/bin:$PATH"
export PATH="$(brew --prefix php@7.4)/bin:$PATH"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.

source $(dirname $(gem which colorls))/tab_complete.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin:/Users/rolle/.cargo/bin"

# added by travis gem
[ ! -s /Users/rolle/.travis/travis.sh ] || source /Users/rolle/.travis/travis.sh


