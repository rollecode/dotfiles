#!/bin/bash

# Move active window to next/prev workspace
# Usage: move-window-workspace.sh next|prev

DIRECTION=$1

# Get current workspace and window address
CURRENT=$(hyprctl activeworkspace -j | jq -r '.id')
WINDOW=$(hyprctl activewindow -j | jq -r '.address')

# Exit if no active window
if [ "$WINDOW" = "null" ] || [ -z "$WINDOW" ]; then
    exit 0
fi

# Special handling for workspace 99 (minimized)
if [ "$CURRENT" = "99" ]; then
    # From workspace 99, always move to workspace 1
    NEXT=1
elif [ "$DIRECTION" = "next" ]; then
    NEXT=$((CURRENT + 1))
    # Skip workspace 99 (reserved for minimized apps)
    if [ "$NEXT" = "99" ]; then
        NEXT=100
    fi
elif [ "$DIRECTION" = "prev" ]; then
    NEXT=$((CURRENT - 1))
    # Don't go below workspace 1
    if [ "$NEXT" -lt 1 ]; then
        NEXT=1
    fi
    # Skip workspace 99
    if [ "$NEXT" = "99" ]; then
        NEXT=98
    fi
else
    exit 1
fi

# Move window to workspace and follow it
hyprctl dispatch movetoworkspace "$NEXT,address:$WINDOW"
# Switch to the target workspace
hyprctl dispatch workspace "$NEXT"
