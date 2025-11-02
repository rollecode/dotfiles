#!/bin/bash
# Hot corner detection script for Hyprland
# Triggers DMS overview when cursor touches top-right corner

THRESHOLD=10  # Pixels from corner to trigger
TRIGGERED=false

while true; do
    # Get cursor position (format: "X, Y")
    cursor_pos=$(hyprctl cursorpos)
    cursor_x=$(echo "$cursor_pos" | cut -d',' -f1 | tr -d ' ')
    cursor_y=$(echo "$cursor_pos" | cut -d',' -f2 | tr -d ' ')

    # Get focused monitor dimensions (cache this to avoid repeated calls)
    if [ -z "$screen_width" ]; then
        monitor_info=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"')
        screen_width=$(echo "$monitor_info" | awk '{print $1}')
        screen_height=$(echo "$monitor_info" | awk '{print $2}')
    fi

    # Check if we have valid values
    if [ -n "$cursor_x" ] && [ -n "$cursor_y" ] && [ -n "$screen_width" ] && [ -n "$screen_height" ]; then
        # Check if cursor is in top-right corner
        if [ "$cursor_x" -ge $((screen_width - THRESHOLD)) ] && [ "$cursor_y" -le $THRESHOLD ]; then
            if [ "$TRIGGERED" = false ]; then
                ~/.config/hypr/scripts/window-overview.sh >/dev/null 2>&1
                TRIGGERED=true
            fi
        else
            # Reset trigger when cursor leaves corner
            TRIGGERED=false
        fi
    fi

    sleep 0.01  # Check every 10ms for instant response
done
