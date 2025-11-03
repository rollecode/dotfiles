#!/bin/bash
# Monitor clipboard and show notification when content changes

# Exit on error
set -e

# Ensure cliphist is available
if ! command -v cliphist &> /dev/null; then
    echo "cliphist not found, exiting"
    exit 1
fi

# Function to show notification - reads from cliphist to avoid wl-paste deadlock
show_notification() {
    # Get the most recent clipboard entry from cliphist (avoids wl-paste deadlock)
    content=$(cliphist list | head -1 | cut -f2- 2>/dev/null || echo "")

    if [ -n "$content" ]; then
        # Check if it looks like an image (binary data)
        if echo "$content" | file - | grep -qi "image\|binary"; then
            notify-send "Copied to clipboard" "📷 Image copied" &
        else
            # Truncate to first 50 chars and sanitize
            preview="${content:0:50}"
            if [ ${#content} -gt 50 ]; then
                preview="${preview}..."
            fi
            # Use -- to prevent content from being interpreted as options
            notify-send "Copied to clipboard" -- "$preview" &
        fi
    fi
}

# Export function so it's available to subshells
export -f show_notification

# Loop with restart capability if wl-paste --watch crashes or gets stuck
while true; do
    # Use wl-paste --watch to detect clipboard changes, but read from cliphist
    timeout 1h wl-paste --watch bash -c 'show_notification' || {
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "wl-paste --watch timed out after 1 hour, restarting to prevent getting stuck..."
        else
            echo "wl-paste --watch crashed with exit code $exit_code, restarting in 2 seconds..."
            sleep 2
        fi
    }
done
