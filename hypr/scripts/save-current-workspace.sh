#!/bin/bash
# Save layout for the current active workspace

# Get current workspace ID
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Run the save script for current workspace
~/.config/hypr/scripts/save-layout.sh "$CURRENT_WS"

# Show notification
notify-send "Hyprland Layout" "Workspace $CURRENT_WS layout saved" -t 2000
