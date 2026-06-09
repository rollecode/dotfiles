#!/bin/bash
# Remove orphan HEADLESS-* outputs left by crashed Moonlight/Sunshine sessions.
# Restarts hyprswitch so its cached monitor topology stays in sync.
# Runs once on Hyprland startup via exec-once.

set -u

# Wait for Hyprland's IPC to be ready (we're called from exec-once at login).
for _ in $(seq 1 30); do
    hyprctl monitors -j >/dev/null 2>&1 && break
    sleep 0.2
done

removed=0
while read -r name; do
    [ -z "$name" ] && continue
    case "$name" in
        HEADLESS-*)
            if hyprctl output remove "$name" >/dev/null 2>&1; then
                removed=$((removed + 1))
                logger -t cleanup-headless "Removed orphan output: $name"
            fi
            ;;
    esac
done < <(hyprctl monitors -j 2>/dev/null | jq -r '.[].name // empty')

if [ "$removed" -gt 0 ]; then
    # hyprswitch runs as a systemd user service; let systemd handle the lifecycle
    # (including ExecStartPre socket cleanup and memory cap).
    systemctl --user restart hyprswitch.service 2>/dev/null
    logger -t cleanup-headless "Removed $removed orphan output(s); restarted hyprswitch.service"
fi
