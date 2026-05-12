#!/usr/bin/env bash
# Hide DMS bar + dock whenever any window is in Hyprland-fullscreen state.
# Listens to Hyprland's event socket (.socket2.sock) and toggles via dms ipc.
#
# Run as exec-once from hyprland.conf:
#   exec-once = ~/.config/hypr/scripts/dms-hide-on-fullscreen.sh &

set -u

SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# Wait for Hyprland's socket to be available (early startup race).
for i in $(seq 1 30); do
    [ -S "$SOCKET" ] && break
    sleep 1
done

if [ ! -S "$SOCKET" ]; then
    echo "dms-hide-on-fullscreen: Hyprland event socket not found" >&2
    exit 1
fi

# Track current state to avoid spamming IPC.
current="visible"

set_state() {
    local want="$1"
    [ "$current" = "$want" ] && return
    if [ "$want" = "hidden" ]; then
        dms ipc bar  hide   index 0 >/dev/null 2>&1 || true
        dms ipc dock hide                       >/dev/null 2>&1 || true
    else
        dms ipc bar  reveal index 0 >/dev/null 2>&1 || true
        dms ipc dock reveal                     >/dev/null 2>&1 || true
    fi
    current="$want"
}

socat -u "UNIX-CONNECT:$SOCKET" - | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>1) set_state hidden ;;
        fullscreen\>\>0) set_state visible ;;
    esac
done
