#!/bin/bash

# Tile toggle script - per workspace
# Toggles between floating (with saved positions) and tiled mode for current workspace only

# Get current workspace
CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')
STATE_FILE="/tmp/hypr-tile-state-ws${CURRENT_WORKSPACE}"
POSITIONS_FILE="/tmp/hypr-window-positions-ws${CURRENT_WORKSPACE}"

# Check if current workspace is in tiled mode
if [ -f "$STATE_FILE" ]; then
    # Switch back to floating mode with saved positions
    echo "Switching workspace $CURRENT_WORKSPACE to floating mode..."

    if [ -f "$POSITIONS_FILE" ]; then
        # First make windows on current workspace floating
        hyprctl clients -j | jq -r --arg ws "$CURRENT_WORKSPACE" '.[] | select(.workspace.id == ($ws | tonumber)) | .address' | while read -r addr; do
            hyprctl dispatch setfloating "address:$addr"
        done

        # Then restore saved positions
        while IFS='|' read -r address x y width height; do
            hyprctl dispatch movewindowpixel "exact $x $y,address:$address"
            hyprctl dispatch resizewindowpixel "exact $width $height,address:$address"
        done < "$POSITIONS_FILE"
    fi

    rm "$STATE_FILE"
    exit 0
fi

# Switch to tiled mode
echo "Switching workspace $CURRENT_WORKSPACE to tiled mode..."

# Save current window positions (only for current workspace)
hyprctl clients -j | jq -r --arg ws "$CURRENT_WORKSPACE" '.[] | select(.workspace.id == ($ws | tonumber) and .mapped == true and .hidden == false) | "\(.address)|\(.at[0])|\(.at[1])|\(.size[0])|\(.size[1])"' > "$POSITIONS_FILE"

# Make all windows on current workspace tiled
hyprctl clients -j | jq -r --arg ws "$CURRENT_WORKSPACE" '.[] | select(.workspace.id == ($ws | tonumber)) | .address' | while read -r addr; do
    hyprctl dispatch settiled "address:$addr"
done

# Mark that current workspace is in tiled mode
touch "$STATE_FILE"
