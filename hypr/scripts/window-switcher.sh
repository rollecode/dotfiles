#!/bin/bash
# Fast window switcher using wofi + hyprctl

# Get all windows and format them nicely
windows=$(hyprctl clients -j | jq -r '.[] | "\(.address) | \(.class) - \(.title)"')

if [ -z "$windows" ]; then
    notify-send "No windows open"
    exit 0
fi

# Show in wofi and get selection
selected=$(echo "$windows" | wofi --dmenu --prompt "Switch to:" --insensitive --width 800 --height 400)

if [ -n "$selected" ]; then
    # Extract address (first field before |)
    address=$(echo "$selected" | cut -d'|' -f1 | tr -d ' ')
    hyprctl dispatch focuswindow "address:$address"
fi
