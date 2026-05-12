#!/usr/bin/env bash
# Deploy the locally-built patched hyprbars.so to hyprpm's plugin cache and
# reload it live (without restarting Hyprland).
#
# The patch fixes an upstream m_bCancelledDown state leak in hyprbars that
# causes the next click after a bar-button-minimize+unminimize cycle to be
# treated as a drag. See
#   https://github.com/rollecode/dms-minimize#upstream-hyprbars-m_bcancelleddown-leak-patch-below
# for the full diagnosis. Re-apply after every `hyprpm update` (it rebuilds
# hyprbars from upstream and clobbers the patched .so).
#
# Inputs:
#   $HYPRBARS_PATCHED_SO  optional, defaults to ~/Projects/hyprbars-patch/hyprbars.so
#
# Exit codes:
#   0  patched and reloaded
#   1  precondition failed (file missing, no hyprctl, etc.)
#   2  hyprpm action failed

set -euo pipefail

PATCHED="${HYPRBARS_PATCHED_SO:-$HOME/Projects/hyprbars-patch/hyprbars.so}"
LIVE="/var/cache/hyprpm/$USER/hyprland-plugins/hyprbars.so"
BACKUP="$LIVE.pre-fix-backup"

log() { printf '[hyprbars-patch-deploy] %s\n' "$*"; }
die() { log "$*" >&2; exit "${2:-1}"; }

[ -r "$PATCHED" ] || die "Patched .so not found at $PATCHED (set HYPRBARS_PATCHED_SO to override)"
[ -r "$LIVE" ]    || die "Live hyprbars.so not found at $LIVE - is hyprbars installed via hyprpm?"
command -v hyprctl >/dev/null || die "hyprctl not on PATH"
command -v hyprpm  >/dev/null || die "hyprpm not on PATH"

if cmp -s "$PATCHED" "$LIVE"; then
    log "Live plugin is already byte-identical to the patched version. Nothing to do."
    exit 0
fi

if [ ! -e "$BACKUP" ]; then
    log "Creating backup at $BACKUP"
    sudo cp "$LIVE" "$BACKUP"
fi

log "Disabling hyprbars (unloads it from the running Hyprland)"
hyprpm disable hyprbars >/dev/null || die "hyprpm disable failed" 2

log "Installing patched .so into $LIVE"
sudo cp "$PATCHED" "$LIVE"

log "Re-enabling hyprbars (loads patched plugin into the running Hyprland)"
hyprpm enable hyprbars >/dev/null || die "hyprpm enable failed - rollback with: sudo cp $BACKUP $LIVE && hyprpm enable hyprbars" 2

if hyprctl version >/dev/null 2>&1; then
    log "Hyprland is alive. Done."
else
    die "Hyprland is not responding - check journal and consider rollback" 2
fi
