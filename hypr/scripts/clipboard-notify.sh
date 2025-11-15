#!/bin/bash
# Monitor clipboard and show notification when content changes

# Ensure cliphist is available
if ! command -v cliphist &> /dev/null; then
    echo "cliphist not found, exiting"
    exit 1
fi

# Function to show notification - reads from cliphist to avoid wl-paste deadlock
show_notification() {
    # Define hash file inside function so it's available in subshell
    local LAST_HASH_FILE="/tmp/clipboard-notify-last-hash-$USER"

    # Get the most recent clipboard entry from cliphist (avoids wl-paste deadlock)
    content=$(timeout 2 cliphist list | head -1 | cut -f2- 2>/dev/null || true)

    if [ -n "$content" ]; then
        # Calculate hash of content for deduplication
        current_hash=$(echo -n "$content" | md5sum | cut -d' ' -f1 2>/dev/null || true)

        # Read last hash
        last_hash=$(cat "$LAST_HASH_FILE" 2>/dev/null || true)

        # Only send notification if content is different from last time
        if [ -n "$current_hash" ] && [ "$current_hash" != "$last_hash" ]; then
            echo -n "$current_hash" > "$LAST_HASH_FILE" 2>/dev/null || true

            # Check if it looks like an image (binary data)
            if echo "$content" | file - 2>/dev/null | grep -qi "image\|binary"; then
                timeout 2 notify-send "Copied to clipboard" "📷 Image copied" 2>/dev/null || true
            else
                # Truncate to first 50 chars and sanitize
                preview="${content:0:50}"
                if [ ${#content} -gt 50 ]; then
                    preview="${preview}..."
                fi
                # Use -- to prevent content from being interpreted as options
                timeout 2 notify-send "Copied to clipboard" -- "$preview" 2>/dev/null || true
            fi
        fi
    fi
}

# Export function so it's available to subshells
export -f show_notification

# Loop with restart capability if wl-paste --watch crashes or gets stuck
while true; do
    # Use wl-paste --watch to detect clipboard changes, but read from cliphist
    # Don't exit on errors - keep the clipboard monitor running
    timeout 1h wl-paste --watch bash -c 'show_notification' 2>/dev/null || {
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "wl-paste --watch timed out after 1 hour, restarting..."
        elif [ $exit_code -ne 0 ]; then
            echo "wl-paste --watch exited with code $exit_code, restarting in 1 second..."
            sleep 1
        fi
    }
done
