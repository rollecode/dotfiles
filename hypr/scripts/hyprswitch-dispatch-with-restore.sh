#!/usr/bin/env bash
# Wraps `hyprswitch dispatch` to also restore minimized windows.
#
# hyprswitch on its own only does `focuswindow`. If the selected window is
# parked on the special:minimized workspace by dms-minimize, focusing it
# leaves it on that hidden workspace and the user sees nothing change.
# This wrapper checks the post-dispatch active window and, if it's on
# special:minimized, hands off to dms-minimize's restore script.

set -euo pipefail

hyprswitch dispatch || exit 0

ACTIVE=$(hyprctl activewindow -j 2>/dev/null || true)
[[ -z "$ACTIVE" ]] && exit 0

WS_NAME=$(echo "$ACTIVE" | jq -r '.workspace.name // empty')
ADDR=$(echo   "$ACTIVE" | jq -r '.address       // empty')

if [[ "$WS_NAME" == "special:minimized" ]] && [[ -n "$ADDR" ]]; then
    UNMIN=~/.local/bin/hypr-unminimize.sh
    [[ -x "$UNMIN" ]] || UNMIN=~/Projects/dms-minimize/scripts/hypr-unminimize.sh
    if [[ -x "$UNMIN" ]]; then
        "$UNMIN" "$ADDR"
    fi
fi
