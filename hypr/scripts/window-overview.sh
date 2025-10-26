#!/bin/bash

STATE_FILE="/tmp/hyprland-overview-state"
POSITIONS_FILE="/tmp/hyprland-overview-positions"

# Check if we're in overview mode
if [ -f "$STATE_FILE" ]; then
    # Restore original positions
    while IFS='|' read -r address x y width height; do
        hyprctl dispatch movewindowpixel exact $x $y,address:$address
        hyprctl dispatch resizewindowpixel exact $width $height,address:$address
    done < "$POSITIONS_FILE"

    rm "$STATE_FILE" "$POSITIONS_FILE"
    exit 0
fi

# Save current positions and create grid overview
hyprctl clients -j | jq -r '.[] | select(.mapped == true and .hidden == false) | "\(.address)|\(.at[0])|\(.at[1])|\(.size[0])|\(.size[1])"' > "$POSITIONS_FILE"

# Get monitor info
MONITOR_WIDTH=$(hyprctl monitors -j | jq -r '.[0].width')
MONITOR_HEIGHT=$(hyprctl monitors -j | jq -r '.[0].height')

# Count windows
WINDOW_COUNT=$(wc -l < "$POSITIONS_FILE")

if [ "$WINDOW_COUNT" -eq 0 ]; then
    exit 0
fi

# Calculate grid dimensions (prefer more columns for wider layouts)
COLS=$(awk "BEGIN {print int(sqrt($WINDOW_COUNT) + 0.9)}")
ROWS=$(awk "BEGIN {print int(($WINDOW_COUNT + $COLS - 1) / $COLS)}")

# Calculate window size with gaps
GAP=20
TOP_BAR=60
WINDOW_WIDTH=$(awk "BEGIN {print int(($MONITOR_WIDTH - ($COLS + 1) * $GAP) / $COLS)}")
WINDOW_HEIGHT=$(awk "BEGIN {print int(($MONITOR_HEIGHT - ($ROWS + 1) * $GAP - $TOP_BAR) / $ROWS)}")

# Position windows in grid
INDEX=0
while IFS='|' read -r address x y width height; do
    ROW=$(awk "BEGIN {print int($INDEX / $COLS)}")
    COL=$(awk "BEGIN {print int($INDEX % $COLS)}")

    NEW_X=$(awk "BEGIN {print int(($COL + 1) * $GAP + $COL * $WINDOW_WIDTH)}")
    NEW_Y=$(awk "BEGIN {print int(($ROW + 1) * $GAP + $ROW * $WINDOW_HEIGHT + $TOP_BAR)}")

    hyprctl dispatch resizewindowpixel exact $WINDOW_WIDTH $WINDOW_HEIGHT,address:$address
    hyprctl dispatch movewindowpixel exact $NEW_X $NEW_Y,address:$address

    INDEX=$((INDEX + 1))
done < "$POSITIONS_FILE"

# Mark that we're in overview mode
touch "$STATE_FILE"
