#!/bin/bash

# Start monitor watcher in background
~/.config/hypr/scripts/monitor-watcher.sh &

# Run hyprlock (blocking)
hyprlock "$@"

# After unlock, restart DMS
dms restart
