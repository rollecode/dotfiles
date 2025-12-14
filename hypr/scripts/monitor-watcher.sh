#!/bin/bash

# Watch for monitor disconnect/reconnect and restart hyprlock to fix black background

LAST_COUNT=$(hyprctl monitors -j | jq 'length')

while pidof hyprlock >/dev/null; do
    CURRENT_COUNT=$(hyprctl monitors -j | jq 'length')

    # If monitor was disconnected (0) and now reconnected (>0), restart hyprlock
    if [[ "$LAST_COUNT" == "0" && "$CURRENT_COUNT" != "0" ]]; then
        sleep 0.3
        pkill -9 -x hyprlock  # -x for exact match only
        sleep 0.2
        hyprlock &
    fi

    LAST_COUNT="$CURRENT_COUNT"
    sleep 0.5
done
