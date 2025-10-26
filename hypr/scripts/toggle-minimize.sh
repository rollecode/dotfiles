#!/bin/bash
# Toggle minimize for the active window
# If window is on workspace 99 (minimized), move it back to current workspace
# If window is on normal workspace, move it to workspace 99

# Get the active window info
ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address')
CURRENT_WORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.id')

# Check if window is valid
if [ "$ACTIVE_WINDOW" = "null" ] || [ -z "$ACTIVE_WINDOW" ]; then
    exit 0
fi

if [ "$CURRENT_WORKSPACE" = "99" ]; then
    # Window is minimized (on workspace 99), restore it to workspace 1
    hyprctl dispatch movetoworkspace "1,address:$ACTIVE_WINDOW"
    hyprctl dispatch workspace 1
else
    # Window is not minimized, minimize it to workspace 99
    hyprctl dispatch movetoworkspacesilent "99,address:$ACTIVE_WINDOW"
fi
