#!/bin/bash

# Workspace switcher that creates workspaces if they don't exist
# Usage: workspace-switcher.sh next|prev

DIRECTION=$1

# Get current workspace
CURRENT=$(hyprctl activeworkspace -j | jq -r '.id')

if [ "$DIRECTION" = "next" ]; then
    NEXT=$((CURRENT + 1))
elif [ "$DIRECTION" = "prev" ]; then
    NEXT=$((CURRENT - 1))
    # Don't go below workspace 1
    if [ "$NEXT" -lt 1 ]; then
        NEXT=1
    fi
else
    exit 1
fi

# Switch to workspace (creates if doesn't exist)
hyprctl dispatch workspace "$NEXT"
