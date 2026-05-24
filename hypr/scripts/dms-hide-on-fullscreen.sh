#!/usr/bin/env bash
# Hide DMS bar + dock whenever a fullscreen window is focused, restore
# otherwise. Tracks Hyprland's fullscreen state - no per-app config or game
# class list to maintain. Covers any game that goes fullscreen automatically;
# leaves the bar visible for windowed apps and the normal desktop.
#
# Run as exec-once from hyprland.conf:
#   exec-once = ~/.config/hypr/scripts/dms-hide-on-fullscreen.sh &

set -u

# --- single instance guard -------------------------------------------------
# Multiple copies (re-exec, crash-respawn, or a stale session) fight each
# other: each caches its own visibility state, so one reveals while another
# thinks it already hid - leaving the bar/dock stuck on top of fullscreen.
# flock guarantees exactly one live instance; any extra invocation exits.
LOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dms-hide-on-fullscreen.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "dms-hide-on-fullscreen: another instance is already running, exiting" >&2
    exit 0
fi

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

# Re-issue the desired state ignoring the cached value. DMS can pop its own
# bar/dock back up on notifications, spotlight, or workspace changes while a
# game is fullscreen; this forces them hidden again.
reassert() {
    current="unknown"
    apply "$1"
}

is_fullscreen() {
    hyprctl activewindow -j 2>/dev/null | grep -q '"fullscreen":[[:space:]]*[12]'
}

# Always start visible, then re-sync from current Hyprland state so we never
# get stuck hidden after a crash, and immediately hide if a game is already
# fullscreen on startup.
apply visible
is_fullscreen && apply hidden

socat -u "UNIX-CONNECT:$SOCKET" - | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>1) apply hidden ;;
        fullscreen\>\>0) apply visible ;;
        # While something is fullscreen, DMS may pop its bar/dock back up on
        # focus/workspace events. Re-hide on active-window change so the
        # overlay can't linger on top of the game.
        activewindow\>\>*)
            if is_fullscreen; then
                reassert hidden
            fi
            ;;
    esac
done
