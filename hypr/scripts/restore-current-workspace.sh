#!/bin/bash
# Restore layout for the current active workspace

# Get current workspace ID
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Check if snapshot exists
SNAPSHOT_FILE="$HOME/.config/hypr/layout-workspace${CURRENT_WS}.json"

if [ ! -f "$SNAPSHOT_FILE" ]; then
    notify-send "Hyprland Layout" "No saved layout for workspace $CURRENT_WS" -t 2000 -u critical
    exit 1
fi

# Run the restore script for current workspace
~/.config/hypr/scripts/restore-layout.sh "$CURRENT_WS"

# Show notification
notify-send "Hyprland Layout" "Workspace $CURRENT_WS layout restored" -t 2000
