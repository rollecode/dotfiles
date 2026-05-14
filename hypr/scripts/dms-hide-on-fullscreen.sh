#!/usr/bin/env bash
# Hide DMS bar + dock whenever the focused window is fullscreen.
# Restore otherwise. Tracks ONLY Hyprland's fullscreen state - no per-app
# config or game-class list to maintain. Covers OW, RDR2, Sims 4 (any game
# in fullscreen) automatically; leaves the bar visible for windowed games
# (BG3 windowed) and the normal desktop.
#
# Run as exec-once from hyprland.conf:
#   exec-once = ~/.config/hypr/scripts/dms-hide-on-fullscreen.sh &

set -u

SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

for i in $(seq 1 30); do
    [ -S "$SOCKET" ] && break
    sleep 1
done

[ -S "$SOCKET" ] || { echo "dms-hide-on-fullscreen: socket not found" >&2; exit 1; }

current="unknown"

apply() {
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

# Always start visible. If a fullscreen game is already focused, the next
# 'fullscreen>>1' event (or activewindow query below) will hide it again
# within a poll cycle. Never leaves the bar stuck hidden after a crash.
apply visible

# Re-sync with current Hyprland state in case we restarted while a game
# was already fullscreen.
if hyprctl activewindow -j 2>/dev/null | grep -q '"fullscreen":[[:space:]]*[12]'; then
    apply hidden
fi

socat -u "UNIX-CONNECT:$SOCKET" - | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>1) apply hidden ;;
        fullscreen\>\>0) apply visible ;;
    esac
done
