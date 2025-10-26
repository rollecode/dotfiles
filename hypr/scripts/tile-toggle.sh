#!/bin/bash

# Tile toggle script for Hyprland
# Toggles all windows between tiled (equal distribution) and floating (saved positions)

STATE_FILE="/tmp/hypr-tile-state"
POSITIONS_FILE="/tmp/hypr-window-positions"

# Get current state (0 = floating, 1 = tiled)
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE")
else
    STATE=0
fi

if [ "$STATE" -eq 0 ]; then
    # Currently floating, switch to tiled
    echo "Switching to tiled mode..."

    # Save current window positions
    hyprctl clients -j | jq -r '.[] | "\(.address)|\(.at[0])|\(.at[1])|\(.size[0])|\(.size[1])"' > "$POSITIONS_FILE"

    # Get all window addresses and make them tiled
    hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
        hyprctl dispatch settiled "address:$addr"
    done

    echo "1" > "$STATE_FILE"

else
    # Currently tiled, switch to floating with saved positions
    echo "Switching to floating mode..."

    if [ -f "$POSITIONS_FILE" ]; then
        # Restore saved positions
        while IFS='|' read -r addr x y width height; do
            # Make window floating first
            hyprctl dispatch setfloating "address:$addr"
            # Move and resize to saved position
            hyprctl dispatch movewindowpixel "exact $x $y,address:$addr"
            hyprctl dispatch resizewindowpixel "exact $width $height,address:$addr"
        done < "$POSITIONS_FILE"
    else
        # No saved positions, just make everything floating
        hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
            hyprctl dispatch setfloating "address:$addr"
        done
    fi

    echo "0" > "$STATE_FILE"
fi
