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
    pkill -x hyprswitch 2>/dev/null
    sleep 0.5
    # pkill doesn't clean up hyprswitch's IPC socket; the next instance will
    # see it and refuse to start with "Daemon already running".
    rm -f "${XDG_RUNTIME_DIR}/hyprswitch.sock"
    nohup hyprswitch init --show-title --size-factor 8 \
        --custom-css "$HOME/.config/hypr/hyprswitch/style.css" \
        >/tmp/hyprswitch.log 2>&1 &
    disown
    logger -t cleanup-headless "Removed $removed orphan output(s); restarted hyprswitch"
fi
