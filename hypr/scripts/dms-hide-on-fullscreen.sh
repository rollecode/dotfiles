#!/usr/bin/env bash
# Hide DMS bar + dock when a game window is focused, restore otherwise.
#
# Listens to Hyprland's event socket for both:
#   - fullscreen toggle (fullscreen>>1/0)  — covers OW etc. that go true fullscreen
#   - active-window change (activewindow>>CLASS,TITLE)  — covers BG3, Sims 4
#                                                          which user runs windowed
#
# Triggers `dms ipc bar hide|reveal index 0` and `dms ipc dock hide|reveal`
# only when state changes, to avoid spamming IPC.
#
# Game window classes/titles matched below. Add more as needed.
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

# Regex matching game window CLASS,TITLE strings from activewindow events.
# Anchored at start of line; titles can include commas so match before the comma.
GAME_RE='^(bg3|bg3_dx11|ts4_x64\.exe|Overwatch|battle\.net|steam_app_).*'

current="visible"
fullscreen=0
focused_is_game=0

apply() {
    local want
    if [ "$fullscreen" = "1" ] || [ "$focused_is_game" = "1" ]; then
        want="hidden"
    else
        want="visible"
    fi
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
        fullscreen\>\>1) fullscreen=1; apply ;;
        fullscreen\>\>0) fullscreen=0; apply ;;
        activewindow\>\>*)
            # activewindow>>CLASS,TITLE
            payload="${line#activewindow>>}"
            if [[ "$payload" =~ $GAME_RE ]]; then
                focused_is_game=1
            else
                focused_is_game=0
            fi
            apply
            ;;
    esac
done
