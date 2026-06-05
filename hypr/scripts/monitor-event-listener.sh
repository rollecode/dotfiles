#!/bin/bash
# Listen to Hyprland IPC events and restart hyprswitch when monitor topology
# changes. hyprswitch's `init` daemon caches monitor geometry at startup, so
# without this it shows its UI on a stale (e.g. just-removed) output and you
# see nothing on Alt+Tab.
#
# Runs as exec-once. Exits cleanly when Hyprland's socket closes.

set -u

# Wait for Hyprland's socket2 (event socket) to appear.
sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
for _ in $(seq 1 30); do
    [ -S "$sock" ] && break
    sleep 0.2
done

if [ ! -S "$sock" ]; then
    logger -t monitor-event-listener "Socket not found, exiting: $sock"
    exit 1
fi

logger -t monitor-event-listener "Started, listening at $sock"

# Debounce so a rapid add+remove burst (e.g. stream tool tearing things up
# and down) doesn't restart hyprswitch a dozen times.
last_restart=0
restart_hyprswitch() {
    now=$(date +%s)
    [ $((now - last_restart)) -lt 1 ] && return
    last_restart=$now

    pkill -x hyprswitch 2>/dev/null
    sleep 0.3
    # pkill doesn't clean up hyprswitch's IPC socket; the next instance will
    # see it and refuse to start with "Daemon already running".
    rm -f "${XDG_RUNTIME_DIR}/hyprswitch.sock"
    nohup hyprswitch init --show-title --size-factor 8 \
        --custom-css "$HOME/.config/hypr/hyprswitch/style.css" \
        >/tmp/hyprswitch.log 2>&1 &
    disown
    logger -t monitor-event-listener "Monitor topology changed; restarted hyprswitch"
}

socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*|monitoraddedv2*|monitorremovedv2*)
            restart_hyprswitch
            ;;
    esac
done
