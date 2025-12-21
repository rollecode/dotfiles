#!/bin/bash
# Watch hyprpaper.conf and sync wallpaper to hyprlock.conf (background only)

HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

sync_wallpaper() {
    WALLPAPER=$(grep "^wallpaper" "$HYPRPAPER_CONF" | sed 's/wallpaper = ,//')
    if [[ -n "$WALLPAPER" ]]; then
        # Only replace path in background section (line after "background {")
        awk -v wp="$WALLPAPER" '
            /^background \{/ { in_bg=1 }
            in_bg && /^    path = / { print "    path = " wp; in_bg=0; next }
            /^\}/ { in_bg=0 }
            { print }
        ' "$HYPRLOCK_CONF" > "${HYPRLOCK_CONF}.tmp" && mv "${HYPRLOCK_CONF}.tmp" "$HYPRLOCK_CONF"
    fi
}

# Initial sync
sync_wallpaper

# Watch for changes
inotifywait -m -e modify "$HYPRPAPER_CONF" 2>/dev/null | while read; do
    sync_wallpaper
done
