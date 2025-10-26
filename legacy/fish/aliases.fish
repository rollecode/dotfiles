alias svgo_all "for f in *.svg; do svgo "$f"; done"
alias shuffle "zomg -z /Volumes/Giant/levyt/*/*.mp3"





alias air "cd /Users/rolle/Projects/dudetest/content/themes/air"


alias dudetest "cd ~/Projects/dudetest"
alias composer "composer -vvv"



alias backup "wget --cache=off -U "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36" --cookies=on --glob=on --tries=3 --proxy=off -e robots=off -x -r --level=1 -p -H -k --quota=100m"
alias mmkisat "mpv "rtmp://tebeo.e-declic.tv/tebeo_live/santos99""
alias wpupdates "composer update && a && c "WP updates" && p && cap production deploy"
alias tag "echo git tag -a v0.0.2 -m "Release version 0.0.2""
alias mount_olohuone "sh /Users/rolle/mount_olohuone.sh"
alias php_errors "tail -f error.log | color -l "\[error\]","\[notice\]""


function imagesize() { convert "$@" -print "Size: %wx%h\n" /dev/null; }

alias rst "vagrant reload && vagrant provision"
alias passu "pwgen -ny 12 -1"
alias randomword "gshuf -n1  /usr/share/dict/words"
alias grep "grep --color"
alias s "git status"
alias a "git add --all"
alias c "git commit -m"
alias p "git push -u origin HEAD"
alias quota "df -l -k -H"

alias dnsreset "dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias grep "grep --color"
function deploy() { dandelion --config "$@".yml deploy; }
alias note "cat "/Users/rolle/Library/.Shae4aile0eishohshu7_dontremove" |grep -i"
alias tunnarit "pico -w "/Users/rolle/Library/.Shae4aile0eishohshu7_dontremove""
alias bashrc "pico -w ~/.bashrc"
alias testcommand "echo $1 $2"
alias updateversion "find ~/Projects/ -name composer.json -maxdepth 2 -exec sed -i "" "s/$1/$2/g" {} +"
alias wpversions "grep -R "johnpbloch/wordpress" ~/Projects/*/composer.json"
alias gitlog "git log --pretty=format:"%Cgreen✔%Creset %s %Cblue(%cr)" --abbrev-commit"
alias gitlog_notimes "git log --pretty=format:"%Cgreen✔%Creset %s" --abbrev-commit"
alias changehostname "sudo hostname -s"
#alias t "timetip"
alias publicip "curl ipecho.net/plain ; echo"
alias dnsreset "dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias grep "grep --color"
alias dudestarter "cd ~/Projects/dudetest/content/themes/dudestarter"
alias neckbeard "cd ~/Projects/dudetest/content/themes/neckbeard"

# Easier navigation: .., ..., ...., ....., ~ and -
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias ~ "cd ~" # `cd` is probably faster to type though
alias -- - "cd -"

# Shortcuts
alias d "cd ~/Documents/Dropbox"
alias dl "cd ~/Downloads"
alias dt "cd ~/Desktop"
alias g "git"
alias h "history"
alias j "jobs"

# List all files colorized in long format
alias l "ls -lF ${colorflag}"

# List all files colorized in long format, including dot files
alias la "ls -laF ${colorflag}"

# List only directories
alias lsd "ls -lF ${colorflag} | grep --color=never "^d""

# Always use color output for `ls`
alias ls "command ls ${colorflag}"
export LS_COLORS "no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:"

# Enable aliases to be sudo’ed
alias sudo "sudo "

# Get week number
alias week "date +%V"

# Stopwatch
alias timer "echo "Timer started. Stop with Ctrl-D." && date && time cat && date"

# Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update "sudo softwareupdate -i -a; brew update; brew upgrade --all; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update"

# IP addresses
alias ip "dig +short myip.opendns.com @resolver1.opendns.com"
alias localip "ipconfig getifaddr en0"
alias ips "ifconfig -a | grep -o "inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)" | awk "{ sub(/inet6? (addr:)? ?/, \"\"); print }""

# Flush Directory Service cache
alias flush "dscacheutil -flushcache && killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# View HTTP traffic
alias sniff "sudo ngrep -d "en1" -t "^(GET|POST) " "tcp and port 80""
alias httpdump "sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# URL-encode strings
alias urlencode "python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);""

# Merge PDF files
# Usage: `mergepdf -o output.pdf input{1,2,3}.pdf`
alias mergepdf "/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py"

# Disable Spotlight
alias spotoff "sudo mdutil -a -i off"
# Enable Spotlight
alias spoton "sudo mdutil -a -i on"

# PlistBuddy alias, because sometimes `defaults` just doesn’t cut it
alias plistbuddy "/usr/libexec/PlistBuddy"

# Ring the terminal bell, and put a badge on Terminal.app’s Dock icon
# (useful when executing time-consuming commands)
alias badge "tput bel"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map "xargs -n1"
