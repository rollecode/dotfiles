#!/bin/bash
# Save current workspace layout snapshot

WORKSPACE=${1:-3}  # Default to workspace 3
SNAPSHOT_FILE="$HOME/.config/hypr/layout-workspace${WORKSPACE}.json"

echo "Saving layout for workspace ${WORKSPACE}..."
hyprctl clients -j | jq "[.[] | select(.workspace.id == ${WORKSPACE})]" > "$SNAPSHOT_FILE"

echo "Layout saved to: $SNAPSHOT_FILE"
echo "Windows captured:"
jq -r '.[] | "  - \(.class): \(.title)"' "$SNAPSHOT_FILE"
