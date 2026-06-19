#!/bin/bash
# Hyprland-startup plugin bootstrap.
#
# Normal boot (Hyprland version unchanged): just `hyprpm reload`. We do NOT
# run `hyprpm update` on every login - it rebuilds every plugin from upstream
# and clobbers our locally-patched .so files (hymission fork patches, hyprbars
# m_bCancelledDown fix).
#
# Hyprland version changed (i.e. Hyprland was upgraded): the cached plugin
# .so files are ABI-stale and won't load. In that case we DO run
# `hyprpm update` (refreshes headers + rebuilds upstream plugins), then
# immediately re-apply our patched builds on top of the freshly-clobbered
# ones, so the patched plugins survive Hyprland upgrades automatically.
#
# Everything here only writes the plugin cache and then `hyprpm reload`s on
# this fresh Hyprland start. It never hyprpm-enables into an already-running
# session (that has hard-crashed the desktop repeatedly).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last-hyprland-version"
mkdir -p "$(dirname "$STAMP")"

current_ver="$(Hyprland --version 2>/dev/null | head -1)"
last_ver="$(cat "$STAMP" 2>/dev/null || true)"

if [ -n "$current_ver" ] && [ "$current_ver" != "$last_ver" ]; then
    logger -t hyprpm-ensure "Hyprland version changed ('$last_ver' -> '$current_ver'); updating + re-patching plugins"

    # Refresh headers and rebuild upstream plugins for the new Hyprland.
    hyprpm update --no-shallow 2>&1 | logger -t hyprpm-ensure

    # Re-apply our patched builds over the upstream ones hyprpm just built.
    if [ -x "$SCRIPT_DIR/hymission-rebuild.sh" ]; then
        "$SCRIPT_DIR/hymission-rebuild.sh" 2>&1 | logger -t hyprpm-ensure || \
            logger -t hyprpm-ensure "hymission-rebuild failed; upstream hymission left in place"
    fi
    if [ -x "$SCRIPT_DIR/hyprbars-patch-deploy.sh" ]; then
        "$SCRIPT_DIR/hyprbars-patch-deploy.sh" 2>&1 | logger -t hyprpm-ensure || \
            logger -t hyprpm-ensure "hyprbars-patch-deploy failed; upstream hyprbars left in place"
    fi

    # Write the stamp UNCONDITIONALLY after the rebuild block, even if some
    # patched-build script failed. Otherwise every login retries the heavy
    # `hyprpm update` chain, which (a) clobbers good plugin .so files and
    # (b) leaves the user with no plugins on screen if the rebuild and
    # reload race the IPC socket. The retry loop below ensures plugins
    # load even on partial-failure boots.
    printf '%s' "$current_ver" > "$STAMP"
fi

# Reload plugins into the running Hyprland — with retries, because on the
# very first session after login the Hyprland IPC socket can lag the moment
# this exec-once fires. Up to 30s of polling. Once `hyprctl plugins list`
# reports at least one loaded plugin, we're done.
for attempt in $(seq 1 15); do
    hyprpm reload -n 2>&1 | logger -t hyprpm-ensure
    if [ "$(hyprctl plugins list 2>/dev/null | grep -c '^Plugin ')" -gt 0 ]; then
        logger -t hyprpm-ensure "plugins loaded on attempt $attempt"
        exit 0
    fi
    sleep 2
done

logger -t hyprpm-ensure "WARNING: hyprpm reload completed but no plugins are loaded after 15 retries (30s)"
