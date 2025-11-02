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
hyprctl clients -j | jq -r '.[] | select(.mapped == true and .hidden == false and .workspace.id >= 0) | "\(.address)|\(.at[0])|\(.at[1])|\(.size[0])|\(.size[1])"' > "$POSITIONS_FILE"

# Get monitor info
MONITOR_WIDTH=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .width')
MONITOR_HEIGHT=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .height')

# Count windows
WINDOW_COUNT=$(wc -l < "$POSITIONS_FILE")

if [ "$WINDOW_COUNT" -eq 0 ]; then
    exit 0
fi

# Improved grid calculation - limit max columns to prevent tiny windows
MAX_COLS=5
COLS=$(awk "BEGIN {cols = int(sqrt($WINDOW_COUNT) + 0.9); print (cols > $MAX_COLS) ? $MAX_COLS : cols}")
ROWS=$(awk "BEGIN {print int(($WINDOW_COUNT + $COLS - 1) / $COLS)}")

# Optimized spacing - use more screen space
GAP=12
TOP_MARGIN=40
BOTTOM_MARGIN=40
SIDE_MARGIN=40

# Calculate available space
USABLE_WIDTH=$(awk "BEGIN {print $MONITOR_WIDTH - 2 * $SIDE_MARGIN - ($COLS - 1) * $GAP}")
USABLE_HEIGHT=$(awk "BEGIN {print $MONITOR_HEIGHT - $TOP_MARGIN - $BOTTOM_MARGIN - ($ROWS - 1) * $GAP}")

# Calculate window size
WINDOW_WIDTH=$(awk "BEGIN {print int($USABLE_WIDTH / $COLS)}")
WINDOW_HEIGHT=$(awk "BEGIN {print int($USABLE_HEIGHT / $ROWS)}")

# Set minimum window size to keep them readable
MIN_WIDTH=400
MIN_HEIGHT=300

if [ "$WINDOW_WIDTH" -lt "$MIN_WIDTH" ]; then
    WINDOW_WIDTH=$MIN_WIDTH
fi

if [ "$WINDOW_HEIGHT" -lt "$MIN_HEIGHT" ]; then
    WINDOW_HEIGHT=$MIN_HEIGHT
fi

# Position windows in grid
INDEX=0
while IFS='|' read -r address x y width height; do
    ROW=$(awk "BEGIN {print int($INDEX / $COLS)}")
    COL=$(awk "BEGIN {print int($INDEX % $COLS)}")

    NEW_X=$(awk "BEGIN {print int($SIDE_MARGIN + $COL * ($WINDOW_WIDTH + $GAP))}")
    NEW_Y=$(awk "BEGIN {print int($TOP_MARGIN + $ROW * ($WINDOW_HEIGHT + $GAP))}")

    hyprctl dispatch resizewindowpixel exact $WINDOW_WIDTH $WINDOW_HEIGHT,address:$address
    hyprctl dispatch movewindowpixel exact $NEW_X $NEW_Y,address:$address

    INDEX=$((INDEX + 1))
done < "$POSITIONS_FILE"

# Mark that we're in overview mode
touch "$STATE_FILE"
