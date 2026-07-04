#!/usr/bin/env bash
# Refresh the hyprlock background with a fresh frame of the quantum realm,
# captured from a far empty region of the driftwm canvas. Run at login
# (autostart) so the lock screen always shows a recent moment of the realm.
# hyprlock's `screenshot` mode grabs black on driftwm, hence this capture.
set -euo pipefail
sleep "${1:-0}"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT
cd "$W"
# Pseudo-random far region: windows never live out here.
off=$(( ($(date +%s) % 30000) + 12000 ))
driftwm msg screenshot region "$off" "$(( off / 2 + 9000 ))" 3440 1440 >/dev/null
f="$(ls -t driftwm-screenshot-*.png | head -1)"
vips extract_band "$f" "$HOME/Pictures/Wallpapers/lockscreen-bg.png" 0 --n 3
