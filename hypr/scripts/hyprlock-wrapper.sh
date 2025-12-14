#!/bin/bash

# Start monitor watcher in background
~/.config/hypr/scripts/monitor-watcher.sh &
WATCHER_PID=$!

# Start hyprlock
hyprlock "$@" &
sleep 1

# Wait until no hyprlock is running (real unlock, not just restart)
while true; do
    sleep 1
    if ! pidof hyprlock >/dev/null; then
        sleep 0.5
        if ! pidof hyprlock >/dev/null; then
            break
        fi
    fi
done

# Cleanup and restart DMS
kill $WATCHER_PID 2>/dev/null
dms restart
