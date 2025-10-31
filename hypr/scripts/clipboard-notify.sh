#!/bin/bash
# Monitor clipboard and show notification when content changes

# Exit on error
set -e

# Ensure wl-paste is available
if ! command -v wl-paste &> /dev/null; then
    echo "wl-paste not found, exiting"
    exit 1
fi

# Loop with restart capability if wl-paste --watch crashes
while true; do
    wl-paste --watch bash -c '
        # Check if clipboard contains an image
        if wl-paste --list-types 2>/dev/null | grep -q "^image/"; then
            notify-send "Copied to clipboard" "📷 Image copied" 2>/dev/null || true
        else
            # Only try to get text content if it'\''s not an image
            content=$(wl-paste 2>/dev/null || echo "")
            if [ -n "$content" ]; then
                # Truncate to first 50 chars
                preview="${content:0:50}"
                if [ ${#content} -gt 50 ]; then
                    preview="${preview}..."
                fi
                notify-send "Copied to clipboard" "$preview" 2>/dev/null || true
            fi
        fi
    ' || {
        echo "wl-paste --watch crashed, restarting in 2 seconds..."
        sleep 2
    }
done
