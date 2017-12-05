# Define colors
black="\[$(tput setaf 0)\]" 
red="\[$(tput setaf 1)\]" 
green="\[$(tput setaf 2)\]" 
yellow="\[$(tput setaf 3)\]" 
blue="\[$(tput setaf 4)\]" 
magenta="\[$(tput setaf 5)\]" 
cyan="\[$(tput setaf 6)\]"
white="\[$(tput setaf 7)\]"
NO_COLOR='\e[0m'

# Bash prompt
export PS1="${titlebar}${red}#  ${blue}\W \[$NO_COLOR\]"