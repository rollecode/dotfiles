#!/bin/bash

# Save window positions before locking (skip if restarted by monitor-watcher)
if [[ -z "$SKIP_SAVE" ]]; then
    hyprctl clients -j | jq -c '[.[] | {address, at, size, workspace: .workspace.id, floating}]' > /tmp/hypr-window-positions.json
fi

# Start monitor watcher in background
~/.config/hypr/scripts/monitor-watcher.sh &

# Run hyprlock (blocking)
hyprlock "$@"

# After unlock, wait for monitor to be ready
for i in $(seq 1 20); do
    if hyprctl monitors -j | jq -e '.[0].width > 0' >/dev/null 2>&1; then
        break
    fi
    sleep 0.25
done
sleep 0.5

# Get monitor dimensions
MON_W=$(hyprctl monitors -j | jq -r '.[0].width // 3440')
MON_H=$(hyprctl monitors -j | jq -r '.[0].height // 1440')

# Restore window positions, clamping to monitor bounds
if [[ -f /tmp/hypr-window-positions.json ]]; then
    jq -c '.[]' /tmp/hypr-window-positions.json | while read -r win; do
        addr=$(echo "$win" | jq -r '.address')
        x=$(echo "$win" | jq -r '.at[0]')
        y=$(echo "$win" | jq -r '.at[1]')
        w=$(echo "$win" | jq -r '.size[0]')
        h=$(echo "$win" | jq -r '.size[1]')
        ws=$(echo "$win" | jq -r '.workspace')
        floating=$(echo "$win" | jq -r '.floating')

        # Skip special workspaces (e.g. 99 = minimized)
        [[ "$ws" -lt 1 || "$ws" -gt 10 ]] && continue

        # Clamp position to monitor bounds
        max_x=$((MON_W - 50))
        max_y=$((MON_H - 50))
        [[ "$x" -lt 0 ]] && x=20
        [[ "$y" -lt 0 ]] && y=20
        [[ "$x" -gt "$max_x" ]] && x=$((MON_W - w - 20))
        [[ "$y" -gt "$max_y" ]] && y=$((MON_H - h - 20))
        # Final safety: still off-screen after clamping
        [[ "$x" -lt 0 ]] && x=20
        [[ "$y" -lt 0 ]] && y=20

        # Restore workspace, position and size
        hyprctl dispatch movetoworkspacesilent "$ws,address:$addr" 2>/dev/null
        if [[ "$floating" == "true" ]]; then
            hyprctl dispatch resizewindowpixel "exact $w $h,address:$addr" 2>/dev/null
            hyprctl dispatch movewindowpixel "exact $x $y,address:$addr" 2>/dev/null
        fi
    done
fi

# After unlock, restart DMS
dms restart
