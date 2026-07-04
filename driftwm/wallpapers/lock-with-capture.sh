#!/usr/bin/env bash
# Lock with a capture of the CURRENT screen: hyprlock's background then shows
# exactly what you were looking at (windows, realm), blurred by hyprlock's
# own blur_passes. grim works on driftwm while the session is still unlocked;
# hyprlock's native `path = screenshot` grabs black here (captures too late).
# On grim failure the previous image stays: locking must never be blocked.
set -u
grim /home/rolle/Pictures/Wallpapers/lockscreen-bg.png 2>/dev/null || true
exec hyprlock
