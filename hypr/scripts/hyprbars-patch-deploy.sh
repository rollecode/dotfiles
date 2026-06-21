#!/usr/bin/env bash
# Rebuild hyprbars from upstream source with our m_bCancelledDown leak fix
# applied, and install the result into hyprpm's plugin cache.
#
# The fix: upstream hyprbars leaks m_bCancelledDown after a bar-button
# minimize+unminimize cycle, so the next click is treated as a drag. Full
# diagnosis + patch:
#   ~/Projects/hyprbars-patch/click-leak-fix.patch
#
# Why rebuild instead of copying a prebuilt .so: a prebuilt .so is tied to
# one Hyprland ABI. When Hyprland upgrades, a stale prebuilt won't load.
# Rebuilding from source against the CURRENT hyprpm headers keeps the patch
# working across Hyprland upgrades. hyprpm-ensure.sh calls this on a detected
# Hyprland version change, right after `hyprpm update`.
#
# This only writes the plugin cache; it does NOT hot-swap into a running
# compositor. The new .so loads on the next clean Hyprland start.
#
# Exit codes: 0 ok / 1 precondition failed / 2 build failed.

set -euo pipefail

PATCH="${HYPRBARS_PATCH:-$HOME/Projects/hyprbars-patch/click-leak-fix.patch}"
CACHE="/var/cache/hyprpm/$USER/hyprland-plugins/hyprbars.so"
WORK="$(mktemp -d /tmp/hyprbars-rebuild.XXXXXX)"
# Pin to the hyprbars commit hyprpm last built so source matches the ABI of
# the headers hyprpm fetched. Overridable if a newer pin is needed.
PIN="${HYPRBARS_PIN:-}"

log() { printf '[hyprbars-patch-deploy] %s\n' "$*"; }
die() { log "$*" >&2; rm -rf "$WORK"; exit "${2:-1}"; }
trap 'rm -rf "$WORK"' EXIT

[ -r "$PATCH" ] || die "patch not found at $PATCH"
[ -d "$(dirname "$CACHE")" ] || die "hyprbars not installed via hyprpm ($CACHE dir missing)"
command -v git >/dev/null || die "git not on PATH"
command -v make >/dev/null || die "make not on PATH"

log "clone hyprwm/hyprland-plugins"
git clone --depth=20 https://github.com/hyprwm/hyprland-plugins.git "$WORK/hp" >/dev/null 2>&1 \
    || die "clone failed" 1
cd "$WORK/hp"
[ -n "$PIN" ] && { log "checkout pin $PIN"; git checkout "$PIN" >/dev/null 2>&1 || die "pin checkout failed" 1; }

log "apply m_bCancelledDown patch"
if ! git apply --check "$PATCH" 2>/dev/null; then
    die "patch does not apply cleanly to current upstream - needs manual rebase" 2
fi
git apply "$PATCH"

log "build hyprbars"
cd hyprbars
if ! make 2>&1 | tail -1; then
    die "build failed - NOT touching the cache" 2
fi
[ -f hyprbars.so ] || die "build produced no hyprbars.so" 2

# Safety: never overwrite the cache while the plugin is mapped in a running
# Hyprland process. A live cache overwrite under a fully booted Hyprland has
# crashed the compositor (the kernel keeps the mapped inode alive, but
# something in the loader/watch chain reacts to the file change and that has
# taken Hyprland down). Stage instead; hyprpm-ensure.sh moves the staged .so
# into the cache at the next clean Hyprland start, before plugins load.
HYPR_PID="$(pgrep -x Hyprland | head -1)"
STAGED_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/staged-plugins"
if [ -n "$HYPR_PID" ] && grep -q '/hyprland-plugins/hyprbars\.so' "/proc/$HYPR_PID/maps" 2>/dev/null; then
    mkdir -p "$STAGED_DIR"
    cp hyprbars.so "$STAGED_DIR/hyprbars.so"
    cp hyprbars.so "$HOME/Projects/hyprbars-patch/hyprbars.so" 2>/dev/null || true
    log "Hyprland is running with hyprbars mapped - refusing live cache overwrite."
    log "Patched .so staged at $STAGED_DIR/hyprbars.so"
    log "hyprpm-ensure.sh will move it into the cache at next clean Hyprland start."
    exit 0
fi

log "install into hyprpm cache (sudo)"
sudo cp hyprbars.so "$CACHE"
# Keep a preserved copy for reference / emergency.
cp hyprbars.so "$HOME/Projects/hyprbars-patch/hyprbars.so" 2>/dev/null || true

log "done. Patched hyprbars staged - loads on the NEXT clean Hyprland start."
